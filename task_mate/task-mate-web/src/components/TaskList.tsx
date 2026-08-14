import type { Task } from '../services/api'
import { EditIcon } from './icons'
import './TaskList.css'

interface TaskListProps {
  // Already filtered to the active tab and sorted by HomePage — this component
  // never decides which tasks belong where.
  tasks: Task[]
  // Which "nothing here" line to show. The wording depends on the active tab
  // and on whether a search is running, both of which only HomePage knows.
  emptyMessage: string
  onToggleComplete?: (task: Task) => void
  // Opens the edit form for one card. Shown on every task: PATCH /tasks/:id is
  // owner-only, but nothing in the task JSON identifies the current user, so
  // the form reports the 404 rather than the card hiding a button it cannot
  // know is unusable.
  onEditTask?: (task: Task) => void
}

// The only date formatting in the app. The mobile app renders
// DateTime.parse(deadline).toLocal() and splits off the date, so this has to
// read the local calendar fields: toISOString() would print the UTC date and
// show the wrong day to anyone west of UTC for most of the afternoon.
function formatDeadline(deadline: string): string {
  const date = new Date(deadline)
  if (Number.isNaN(date.getTime())) {
    return 'No deadline'
  }
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  const day = `${date.getDate()}`.padStart(2, '0')
  return `${date.getFullYear()}-${month}-${day}`
}

function TaskList({ tasks, emptyMessage, onToggleComplete, onEditTask }: TaskListProps) {
  if (tasks.length === 0) {
    return <p className="task-list-empty">{emptyMessage}</p>
  }

  return (
    <ul className="task-list">
      {tasks.map((task) => (
        // Mongoose serialises `_id` and adds no `id` virtual, so `_id` is the
        // only stable key available.
        <li className="task-list-item" key={task._id}>
          <input
            className="task-list-check"
            type="checkbox"
            checked={task.completed}
            aria-label={`Mark ${task.title} complete`}
            onChange={() => onToggleComplete?.(task)}
          />
          {/* Title and description share one column so the badges stay on the
              card's first line rather than being pushed down by a description. */}
          <div className="task-list-main">
            <span
              className={
                task.completed
                  ? 'task-list-title task-list-title-done'
                  : 'task-list-title'
              }
            >
              {task.title}
            </span>
            {/* Guarded on the trimmed value, not just on presence: the field is
                absent from the JSON when it was never set, but a task created
                before the add-task form trimmed its input can still hold ''. */}
            {task.description?.trim() && (
              <p className="task-list-description">{task.description}</p>
            )}
          </div>
          {/* `priority` is the Priority union, so this interpolates to one of
              exactly three classes defined in TaskList.css. */}
          <span className={`task-list-priority task-list-priority-${task.priority}`}>
            {task.priority}
          </span>
          <span className="task-list-deadline">{formatDeadline(task.deadline)}</span>
          {/* Last in the row so the card still reads title → priority →
              deadline, with the one action anchored at its trailing edge. */}
          <button
            type="button"
            className="task-list-edit"
            aria-label={`Edit ${task.title}`}
            onClick={() => onEditTask?.(task)}
          >
            <EditIcon />
          </button>
        </li>
      ))}
    </ul>
  )
}

export default TaskList
