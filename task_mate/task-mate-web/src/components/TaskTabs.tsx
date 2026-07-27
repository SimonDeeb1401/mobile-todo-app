import type { ReactNode } from 'react'
import { CheckCircleIcon, PeopleIcon, PendingIcon } from './icons'
import './TaskTabs.css'

// The tab strip owns its own key union; HomePage type-imports it. A type-only
// import is erased at build time, so this direction of dependency costs
// nothing at runtime. A union rather than an enum because tsconfig sets
// erasableSyntaxOnly.
export type TabKey = 'pending' | 'completed' | 'shared'

interface TaskTabsProps {
  activeTab: TabKey
  // Counts are computed once in HomePage alongside the filtered lists, so a
  // count can never disagree with the rows the user is looking at.
  pendingCount: number
  completedCount: number
  sharedCount: number
  onTabChange?: (tab: TabKey) => void
}

const TABS: { key: TabKey; label: string }[] = [
  { key: 'pending', label: 'Pending' },
  { key: 'completed', label: 'Completed' },
  { key: 'shared', label: 'Shared' },
]

function TaskTabs({
  activeTab,
  pendingCount,
  completedCount,
  sharedCount,
  onTabChange,
}: TaskTabsProps) {
  // Two lookups keep the map body flat and let the counts stay three separate
  // props rather than an object the parent has to allocate every render.
  const counts: Record<TabKey, number> = {
    pending: pendingCount,
    completed: completedCount,
    shared: sharedCount,
  }

  // Same three icons as the Flutter TabBar: pending_actions, check_circle,
  // people_alt_rounded.
  const icons: Record<TabKey, ReactNode> = {
    pending: <PendingIcon />,
    completed: <CheckCircleIcon />,
    shared: <PeopleIcon />,
  }

  return (
    <div className="task-tabs" role="tablist" aria-label="Task groups">
      {TABS.map((tab) => (
        <button
          key={tab.key}
          type="button"
          role="tab"
          aria-selected={tab.key === activeTab}
          className={
            tab.key === activeTab
              ? 'task-tabs-tab task-tabs-tab-active'
              : 'task-tabs-tab'
          }
          onClick={() => onTabChange?.(tab.key)}
        >
          <span className="task-tabs-icon">{icons[tab.key]}</span>
          {/* "Pending (3)" — the label shape the mobile TabBar uses. */}
          <span className="task-tabs-label">
            {tab.label} ({counts[tab.key]})
          </span>
        </button>
      ))}
    </div>
  )
}

export default TaskTabs
