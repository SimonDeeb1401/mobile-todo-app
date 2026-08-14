// Hand-drawn replacements for the Material icons the Flutter app uses. There
// is no icon dependency in this project, and public/icons.svg only holds the
// Vite template's social logos, so these are the app's icon set.
//
// Every glyph is stroked with `currentColor` and carries no explicit size, so
// a call site controls both with plain CSS (`color` and `.parent svg { width }`).
// They are all aria-hidden: an icon here is always inside a button that
// already has an aria-label, and announcing it twice is worse than not at all.

// The shared wrapper props. Everything is a 24x24 stroked outline so the icons
// look like one family rather than a scrapbook.
const base = {
  viewBox: '0 0 24 24',
  width: '20',
  height: '20',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 2,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
  'aria-hidden': true,
}

// Icons.search — magnifier.
export function SearchIcon() {
  return (
    <svg {...base}>
      <circle cx="11" cy="11" r="7" />
      <line x1="16.2" y1="16.2" x2="21" y2="21" />
    </svg>
  )
}

// Icons.close / Icons.cancel — also the in-field search clear.
export function CloseIcon() {
  return (
    <svg {...base}>
      <line x1="5" y1="5" x2="19" y2="19" />
      <line x1="19" y1="5" x2="5" y2="19" />
    </svg>
  )
}

// Icons.tune — three sliders with offset handles.
export function FilterIcon() {
  return (
    <svg {...base}>
      <line x1="3" y1="7" x2="21" y2="7" />
      <line x1="3" y1="12" x2="21" y2="12" />
      <line x1="3" y1="17" x2="21" y2="17" />
      <circle cx="8" cy="7" r="2" fill="currentColor" stroke="none" />
      <circle cx="15" cy="12" r="2" fill="currentColor" stroke="none" />
      <circle cx="10" cy="17" r="2" fill="currentColor" stroke="none" />
    </svg>
  )
}

// Icons.swap_vert — two arrows pointing opposite ways.
export function SortIcon() {
  return (
    <svg {...base}>
      <path d="M8 4v16" />
      <path d="M4 8l4-4 4 4" />
      <path d="M16 20V4" />
      <path d="M12 16l4 4 4-4" />
    </svg>
  )
}

// Icons.person — head and shoulders.
export function PersonIcon() {
  return (
    <svg {...base}>
      <circle cx="12" cy="8" r="4" />
      <path d="M5 21c0-3.9 3.1-7 7-7s7 3.1 7 7" />
    </svg>
  )
}

// Icons.pending_actions — the Pending tab. A clock reads as "not yet done"
// more clearly at 20px than the Material clipboard-and-clock does.
export function PendingIcon() {
  return (
    <svg {...base}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3.5 2" />
    </svg>
  )
}

// Icons.check_circle — the Completed tab, and the TaskMate wordmark's glyph.
export function CheckCircleIcon() {
  return (
    <svg {...base}>
      <circle cx="12" cy="12" r="9" />
      <path d="M8 12.5l2.6 2.6L16 9.5" />
    </svg>
  )
}

// Icons.people_alt_rounded — the Shared tab. Two overlapping figures.
export function PeopleIcon() {
  return (
    <svg {...base}>
      <circle cx="9" cy="8" r="3.5" />
      <path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6" />
      <path d="M16 5.2a3.5 3.5 0 0 1 0 6.6" />
      <path d="M17.5 14.4c2.1.9 3.5 2.9 3.5 5.6" />
    </svg>
  )
}

// Icons.add — the add-task trigger.
export function PlusIcon() {
  return (
    <svg {...base}>
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  )
}

// Icons.logout — an arrow leaving an open-sided box.
export function LogoutIcon() {
  return (
    <svg {...base}>
      <path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3" />
      <path d="M10 8l-4 4 4 4" />
      <line x1="6" y1="12" x2="15" y2="12" />
    </svg>
  )
}

// Icons.arrow_back — the add-task screen's AppBar leading button.
export function ArrowBackIcon() {
  return (
    <svg {...base}>
      <line x1="20" y1="12" x2="5" y2="12" />
      <path d="M11 5l-6 7 6 7" />
    </svg>
  )
}

// Icons.add_task — the 80px header glyph on the add-task form. A list with a
// plus reads more clearly at that size than Material's clipboard-and-tick.
export function AddTaskIcon() {
  return (
    <svg {...base}>
      <line x1="4" y1="6" x2="16" y2="6" />
      <line x1="4" y1="11" x2="13" y2="11" />
      <line x1="4" y1="16" x2="10" y2="16" />
      <line x1="17" y1="12" x2="17" y2="20" />
      <line x1="13" y1="16" x2="21" y2="16" />
    </svg>
  )
}

// Icons.edit — the pencil that opens the edit screen from a task card.
export function EditIcon() {
  return (
    <svg {...base}>
      <path d="M4 20h4l10-10a2.8 2.8 0 0 0-4-4L4 16z" />
      <line x1="14" y1="6" x2="18" y2="10" />
    </svg>
  )
}

// Icons.edit_note — the 80px header glyph on the edit form. The same list the
// add-task glyph draws, with a pencil instead of a plus.
export function EditNoteIcon() {
  return (
    <svg {...base}>
      <line x1="4" y1="6" x2="16" y2="6" />
      <line x1="4" y1="11" x2="12" y2="11" />
      <line x1="4" y1="16" x2="9" y2="16" />
      <path d="M13 20h3l6-6a2.1 2.1 0 0 0-3-3l-6 6z" />
    </svg>
  )
}

// Icons.save — the floppy disk on the edit form's submit button.
export function SaveIcon() {
  return (
    <svg {...base}>
      <path d="M5 3h11l3 3v15H5z" />
      <path d="M8 3v6h7V3" />
      <rect x="8" y="13" width="8" height="6" />
    </svg>
  )
}

// Icons.title — a capital T, for the task title field.
export function TitleIcon() {
  return (
    <svg {...base}>
      <line x1="5" y1="6" x2="19" y2="6" />
      <line x1="12" y1="6" x2="12" y2="19" />
    </svg>
  )
}

// Icons.description — a folded document with two text lines.
export function DescriptionIcon() {
  return (
    <svg {...base}>
      <path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z" />
      <path d="M14 3v5h5" />
      <line x1="9" y1="13" x2="15" y2="13" />
      <line x1="9" y1="17" x2="15" y2="17" />
    </svg>
  )
}

// Icons.flag — the priority marker. Left unfilled so the call site can tint it
// with `color` alone, the way the mobile screen recolours the flag per priority.
export function FlagIcon() {
  return (
    <svg {...base}>
      <line x1="5" y1="21" x2="5" y2="4" />
      <path d="M5 4h13l-2.5 4.5L18 13H5" />
    </svg>
  )
}

// Icons.calendar_today — the deadline field.
export function CalendarIcon() {
  return (
    <svg {...base}>
      <rect x="3" y="5" width="18" height="16" rx="2" />
      <line x1="3" y1="10" x2="21" y2="10" />
      <line x1="8" y1="3" x2="8" y2="7" />
      <line x1="16" y1="3" x2="16" y2="7" />
    </svg>
  )
}

// Icons.person_add_alt_1 — the collaborator email field.
export function PersonAddIcon() {
  return (
    <svg {...base}>
      <circle cx="9" cy="8" r="3.5" />
      <path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6" />
      <line x1="18" y1="7" x2="18" y2="13" />
      <line x1="15" y1="10" x2="21" y2="10" />
    </svg>
  )
}
