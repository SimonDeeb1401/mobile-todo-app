import { useEffect, useRef, useState } from 'react'
// Aliased: React's synthetic FocusEvent/KeyboardEvent would otherwise shadow the
// DOM globals of the same name, which the document-level listeners below need.
import type {
  FocusEvent as ReactFocusEvent,
  KeyboardEvent as ReactKeyboardEvent,
} from 'react'
import type { SortMode, SortPreference } from '../services/api'
import {
  CheckCircleIcon,
  CloseIcon,
  FilterIcon,
  PersonIcon,
  SearchIcon,
  SortIcon,
} from './icons'
import './TopBar.css'

interface TopBarProps {
  // The Flutter AppBar drops its actions and its tab strip on the profile tab
  // (actions: _currentIndex == 0 ? [...] : null), so the bar stays mounted but
  // goes quiet.
  showTaskActions: boolean
  profileActive: boolean
  sort: SortPreference
  // Receives applied queries only — never raw keystrokes. See the debounce below.
  onSearchChange?: (query: string) => void
  onSortChange?: (sort: SortPreference) => void
  onFilter?: () => void
  onToggleView?: () => void
}

// The four modes from the mobile sort dialog, in its order.
const SORT_OPTIONS: { mode: SortMode; label: string }[] = [
  { mode: 'priority', label: 'Priority' },
  { mode: 'deadline', label: 'Deadline' },
  { mode: 'createdAt', label: 'Creation date' },
  { mode: 'manual', label: 'Manual order' },
]

function TopBar({
  showTaskActions,
  profileActive,
  sort,
  onSearchChange,
  onSortChange,
  onFilter,
  onToggleView,
}: TopBarProps) {
  const [searchOpen, setSearchOpen] = useState(false)
  const [searchText, setSearchText] = useState('')
  const [sortOpen, setSortOpen] = useState(false)
  const sortRef = useRef<HTMLDivElement>(null)

  // Dismissing the sort menu can't be driven off focus alone: Safari and Firefox
  // on macOS don't focus a button when you click it, so on those browsers focus
  // is still on <body> while the menu is open — a handler bound to the menu's
  // own subtree would never see the click or the keystroke. Both listeners go on
  // the document, and are attached only while the menu is open.
  useEffect(() => {
    if (!sortOpen) {
      return
    }

    const handlePointerDown = (event: PointerEvent) => {
      if (!sortRef.current?.contains(event.target as Node)) {
        setSortOpen(false)
      }
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setSortOpen(false)
      }
    }

    document.addEventListener('pointerdown', handlePointerDown)
    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('pointerdown', handlePointerDown)
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [sortOpen])

  // Searching is client-side because it has to be: api.ts documents that the
  // backend reads its `search` param into a filter object which all three sort
  // branches of getTasks then discard.
  //
  // The bar owns the keystrokes and only hands the parent a query worth acting
  // on, matching TaskProvider.applySearch on mobile: 300ms debounce, act at two
  // characters or more, reset at zero. One character deliberately changes
  // nothing — hence the else-if rather than a ternary.
  useEffect(() => {
    const timer = setTimeout(() => {
      const trimmed = searchText.trim()
      if (trimmed.length >= 2) {
        onSearchChange?.(trimmed)
      } else if (trimmed.length === 0) {
        onSearchChange?.('')
      }
    }, 300)

    return () => clearTimeout(timer)
  }, [searchText, onSearchChange])

  const handleCloseSearch = () => {
    setSearchOpen(false)
    setSearchText('')
    // Applied immediately rather than left to the debounce: leaving search mode
    // should restore the full list at once, not 300ms later.
    onSearchChange?.('')
  }

  const handleSearchKeyDown = (event: ReactKeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Escape') {
      handleCloseSearch()
    }
  }

  // Covers Tab-ing out of the menu, which a pointer listener can't see.
  const handleSortBlur = (event: ReactFocusEvent<HTMLDivElement>) => {
    if (!event.currentTarget.contains(event.relatedTarget)) {
      setSortOpen(false)
    }
  }

  const handleModeChange = (mode: SortMode) => {
    onSortChange?.({ mode, order: sort.order })
    setSortOpen(false)
  }

  const handleOrderToggle = () => {
    onSortChange?.({ mode: sort.mode, order: sort.order === 'asc' ? 'desc' : 'asc' })
  }

  return (
    <header className="top-bar">
      <div className="top-bar-lead">
        {searchOpen && showTaskActions ? (
          <div className="top-bar-search">
            <input
              className="top-bar-search-input"
              type="search"
              autoFocus
              placeholder="Search tasks..."
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              onKeyDown={handleSearchKeyDown}
              aria-label="Search tasks"
            />
            {/* The mobile TextField's cancel suffixIcon: empties the field but
                stays in search mode. Exiting search is the action-slot close. */}
            {searchText && (
              <button
                type="button"
                className="top-bar-search-clear"
                aria-label="Clear search"
                onClick={() => setSearchText('')}
              >
                <CloseIcon />
              </button>
            )}
          </div>
        ) : (
          <h1 className="top-bar-title">
            <span className="top-bar-mark">
              <CheckCircleIcon />
            </span>
            TaskMate
          </h1>
        )}
      </div>

      <div className="top-bar-actions">
        {showTaskActions && (
          <>
            <button
              type="button"
              className="top-bar-action"
              aria-label={searchOpen ? 'Close search' : 'Search tasks'}
              onClick={searchOpen ? handleCloseSearch : () => setSearchOpen(true)}
            >
              {searchOpen ? <CloseIcon /> : <SearchIcon />}
            </button>

            {/* Filtering is a follow-up: the mobile sheet has multi-select
                priority chips plus deadline presets, which belongs with the
                add-task form. The title keeps it from being a silent no-op. */}
            <button
              type="button"
              className="top-bar-action"
              aria-label="Filter tasks"
              title="Filters coming soon"
              onClick={onFilter}
            >
              <FilterIcon />
            </button>

            <div className="top-bar-sort" ref={sortRef} onBlur={handleSortBlur}>
              <button
                type="button"
                className="top-bar-action"
                aria-label="Sort tasks"
                aria-expanded={sortOpen}
                onClick={() => setSortOpen(!sortOpen)}
              >
                <SortIcon />
              </button>
              {sortOpen && (
                <div className="top-bar-menu" role="menu">
                  {SORT_OPTIONS.map((option) => (
                    <button
                      key={option.mode}
                      type="button"
                      role="menuitemradio"
                      aria-checked={sort.mode === option.mode}
                      className={
                        sort.mode === option.mode
                          ? 'top-bar-menu-item top-bar-menu-item-active'
                          : 'top-bar-menu-item'
                      }
                      onClick={() => handleModeChange(option.mode)}
                    >
                      {option.label}
                    </button>
                  ))}
                  <button
                    type="button"
                    className="top-bar-menu-order"
                    onClick={handleOrderToggle}
                  >
                    {sort.order === 'asc' ? 'Ascending' : 'Descending'}
                  </button>
                </div>
              )}
            </div>
          </>
        )}

        {/* With only two destinations, this is the whole navigation — no bottom
            bar, no sidebar. */}
        <button
          type="button"
          className={
            profileActive ? 'top-bar-avatar top-bar-avatar-active' : 'top-bar-avatar'
          }
          aria-label={profileActive ? 'Back to tasks' : 'Profile'}
          aria-pressed={profileActive}
          onClick={onToggleView}
        >
          <PersonIcon />
        </button>
      </div>
    </header>
  )
}

export default TopBar
