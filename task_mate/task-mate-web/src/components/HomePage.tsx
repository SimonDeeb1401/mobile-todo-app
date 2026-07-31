import { useCallback, useEffect, useMemo, useState } from 'react'
import type { Priority, SortPreference, Task } from '../services/api'
import { ApiError, NetworkError, getTasks, updateTask } from '../services/api'
import TopBar from './TopBar'
import TaskTabs from './TaskTabs'
import type { TabKey } from './TaskTabs'
import TaskList from './TaskList'
import AddTaskButton from './AddTaskButton'
import AddTaskPage from './AddTaskPage'
import ProfilePage from './ProfilePage'
import './HomePage.css'

interface HomePageProps {
  // App still owns the session flag; this only relays the signal up from
  // ProfilePage, the same contract LoginPage's onLogin uses.
  onSignOut?: () => void
}

const PRIORITY_RANK: Record<Priority, number> = { low: 1, medium: 2, high: 3 }

// Sorting is client-side. getTasks() does sort server-side, but from the
// sortPreference baked into the JWT at login, so it cannot reflect a change made
// this session (see the note on getTasks in services/api.ts).
function compareTasks(a: Task, b: Task, sort: SortPreference): number {
  let result: number

  switch (sort.mode) {
    case 'priority':
      result = PRIORITY_RANK[a.priority] - PRIORITY_RANK[b.priority]
      break
    case 'deadline':
      result = Date.parse(a.deadline) - Date.parse(b.deadline)
      break
    case 'createdAt':
      result = Date.parse(a.createdAt) - Date.parse(b.createdAt)
      break
    case 'manual':
      result = a.orderIndex - b.orderIndex
      break
  }

  return sort.order === 'asc' ? result : -result
}

// Per-tab empty lines from lib/screens/tasks_screen.dart, plus a search-specific
// one — "No pending tasks available." is misleading when a query is hiding them.
function emptyMessageFor(tab: TabKey, searching: boolean): string {
  if (searching) {
    return 'No tasks match your search.'
  }
  if (tab === 'pending') {
    return 'No pending tasks available.'
  }
  if (tab === 'completed') {
    return 'No completed tasks available.'
  }
  return 'No shared tasks available.'
}

function HomePage({ onSignOut }: HomePageProps) {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [view, setView] = useState<'tasks' | 'profile' | 'addTask'>('tasks')
  const [activeTab, setActiveTab] = useState<TabKey>('pending')
  // The mobile add-task screen confirms with a green SnackBar before popping.
  // This is that message; the effect below clears it.
  const [notice, setNotice] = useState('')
  // The applied query, already trimmed by TopBar — either '' or 2+ characters.
  const [search, setSearch] = useState('')
  // The mobile defaults, from UserProvider. Not persisted via
  // updateSortPreference() yet; that's a follow-up.
  const [sort, setSort] = useState<SortPreference>({ mode: 'createdAt', order: 'asc' })

  // A shared callback so the mount effect below and the error state's "Try
  // again" button run exactly one code path.
  //
  // A promise chain rather than the async/await + try/catch that LoginPage
  // uses: react-hooks/set-state-in-effect rejects any setState an effect can
  // reach synchronously, and moving the updates into .then/.catch callbacks is
  // the shape the rule asks for. `loading` and `error` are therefore armed by
  // their initial values on mount and by handleRetry afterwards.
  const loadTasks = useCallback(() => {
    getTasks()
      .then((data) => {
        // An empty 200 body resolves to null in handleResponse.
        setTasks(data ?? [])
        setError('')
      })
      .catch((err: unknown) => {
        console.error('[home] loading tasks failed:', err)
        // The JWT expires after an hour and there is no refresh endpoint, so a
        // 401 is a dead session. Bouncing to the login screen beats showing
        // "Unauthorized" behind a Try again button that can never succeed.
        if (err instanceof ApiError && err.status === 401) {
          onSignOut?.()
          return
        }
        // Same reasoning as LoginPage: an ApiError's message is the backend's
        // own user-readable `error` field, a NetworkError names the URL it
        // tried, and anything else is a bug here that "could not reach the
        // server" would misdescribe.
        setError(
          err instanceof ApiError || err instanceof NetworkError
            ? err.message
            : 'Something went wrong loading your tasks. Please try again.',
        )
      })
      .finally(() => setLoading(false))
  }, [onSignOut])

  useEffect(() => {
    loadTasks()
  }, [loadTasks])

  // SnackBarBehavior.floating auto-dismisses on mobile, so the web notice does
  // too. Keyed off the message rather than a boolean, so a second creation
  // restarts the countdown instead of inheriting the first one's remaining time.
  useEffect(() => {
    if (!notice) {
      return
    }
    const timer = setTimeout(() => setNotice(''), 4000)
    return () => clearTimeout(timer)
  }, [notice])

  const handleRetry = () => {
    setError('')
    setLoading(true)
    loadTasks()
  }

  // Search, sort and the three tab splits all happen here, once. Deriving the
  // counts and the visible rows from the same pass is what guarantees a tab
  // label can never disagree with what's under it.
  const { pending, completed, shared } = useMemo(() => {
    const query = search.toLowerCase()
    const matchesSearch = (task: Task) =>
      query === '' ||
      task.title.toLowerCase().includes(query) ||
      (task.description ?? '').toLowerCase().includes(query)

    // filter() already returns a copy, so sorting it in place is safe.
    const visible = tasks.filter(matchesSearch).sort((a, b) => compareTasks(a, b, sort))

    // Optional chaining despite the type saying string[]: a task missing the
    // array would otherwise throw mid-render, and the mobile code guards the
    // same field.
    const isShared = (task: Task) => (task.collaborators?.length ?? 0) > 0

    // The three predicates from bottom_navigation_bar.dart, verbatim in intent.
    // Note that Shared is collaborator-based regardless of completion, so a
    // finished shared task appears there and not under Completed.
    return {
      pending: visible.filter((task) => !task.completed && !isShared(task)),
      completed: visible.filter((task) => task.completed && !isShared(task)),
      shared: visible.filter(isShared),
    }
  }, [tasks, search, sort])

  const activeTasks =
    activeTab === 'pending' ? pending : activeTab === 'completed' ? completed : shared

  const handleAddTask = () => {
    setNotice('')
    setView('addTask')
  }

  // AddTaskPage hands back the row the API created, so the list is patched in
  // place rather than refetched — a GET here would also re-sort by the stale
  // sortPreference baked into the JWT (see getTasks in services/api.ts).
  const handleTaskCreated = (task: Task) => {
    setTasks((current) => [...current, task])
    // A new task is never completed, so it lands under Pending — unless it has
    // collaborators, which puts it under Shared regardless (the same split the
    // useMemo above applies). Following it means the user always sees the task
    // they just created instead of an unchanged list.
    setActiveTab((task.collaborators?.length ?? 0) > 0 ? 'shared' : 'pending')
    setNotice('Task created successfully!')
    setView('tasks')
  }

  const handleFilter = () => {
    // TODO: open the filter panel — multi-select priorities plus a deadline
    // preset, per TaskProvider.showFilterBottomSheet. Unlike mobile, it should
    // filter non-destructively rather than overwriting the task list.
  }

  const handleToggleComplete = async (task: Task) => {
    const next = !task.completed
    // Optimistic: a checkbox that waits on a round trip feels broken.
    setTasks((current) =>
      current.map((item) =>
        item._id === task._id ? { ...item, completed: next } : item,
      ),
    )

    try {
      const updated = await updateTask(task._id, { completed: next })
      // Take the server's row so any field it also touched lands too.
      setTasks((current) =>
        current.map((item) => (item._id === task._id ? updated : item)),
      )
    } catch (err) {
      console.error('[home] updating task completion failed:', err)
      // Put the old value back — leaving the optimistic tick in place would
      // claim a change the server rejected. updateTask is owner-only, so this
      // is the expected path for a shared task someone else owns.
      setTasks((current) =>
        current.map((item) =>
          item._id === task._id ? { ...item, completed: task.completed } : item,
        ),
      )
      setError(
        err instanceof ApiError || err instanceof NetworkError
          ? err.message
          : 'Something went wrong updating that task. Please try again.',
      )
    }
  }

  let body

  if (loading) {
    body = (
      <div className="home-status">
        <div className="home-spinner" />
        <p>Loading tasks...</p>
      </div>
    )
  } else if (error) {
    body = (
      <div className="home-error" role="alert">
        <p>{error}</p>
        <button type="button" className="home-retry" onClick={handleRetry}>
          Try again
        </button>
      </div>
    )
  } else if (tasks.length === 0) {
    body = <p className="home-empty">No tasks yet. Add your first task!</p>
  } else {
    body = (
      <TaskList
        tasks={activeTasks}
        emptyMessage={emptyMessageFor(activeTab, search !== '')}
        onToggleComplete={handleToggleComplete}
      />
    )
  }

  return (
    <div className="home-page">
      {/* The bar stays mounted across both views, like the Flutter Scaffold's
          persistent AppBar over a swapped body — otherwise the avatar that
          navigates to Profile would unmount with the tasks view. */}
      <TopBar
        showTaskActions={view === 'tasks'}
        profileActive={view === 'profile'}
        sort={sort}
        // Passed as the setter itself, not an inline arrow: useState setters are
        // referentially stable, which is what lets TopBar's debounce effect
        // depend on this without re-running every render.
        onSearchChange={setSearch}
        onSortChange={setSort}
        onFilter={handleFilter}
        // Written against `profile` rather than `tasks` so it matches the
        // avatar's own label, which reads "Profile" for every view but that one.
        // From the add-task form the avatar therefore leaves the form, exactly
        // as it says it will.
        onToggleView={() =>
          setView((current) => (current === 'profile' ? 'tasks' : 'profile'))
        }
      />

      {view === 'profile' ? (
        <ProfilePage onSignOut={onSignOut} />
      ) : view === 'addTask' ? (
        <AddTaskPage
          onCreated={handleTaskCreated}
          onCancel={() => setView('tasks')}
        />
      ) : (
        <>
          {/* Rendered through loading and error too, with zero counts, so the
              layout doesn't jump once the fetch lands. The bar itself is
              full-bleed white; the inner row shares .home-body's max width so
              the tabs line up with the task cards below them. */}
          <div className="home-toolbar">
            <div className="home-toolbar-inner">
              <TaskTabs
                activeTab={activeTab}
                pendingCount={pending.length}
                completedCount={completed.length}
                sharedCount={shared.length}
                onTabChange={setActiveTab}
              />
              <AddTaskButton onClick={handleAddTask} />
            </div>
          </div>
          <main className="home-body">{body}</main>

          {/* role="status" rather than "alert": this is a confirmation, so it
              should be announced without interrupting whatever the user is
              doing next. */}
          {notice && (
            <p className="home-notice" role="status">
              {notice}
            </p>
          )}
        </>
      )}
    </div>
  )
}

export default HomePage
