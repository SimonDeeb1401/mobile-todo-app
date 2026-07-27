import { PlusIcon } from './icons'
import './AddTaskButton.css'

interface AddTaskButtonProps {
  onClick?: () => void
}

// One button, two appearances. On desktop it sits inline beside the tab strip
// as a "+ Add Task" pill; on narrow viewports CSS turns it into the fixed
// bottom-right circle from lib/screens/tasks_screen.dart's FloatingActionButton.
//
// The switch is a media query rather than matchMedia because the markup is
// identical either way — JS would only re-derive a class the browser already
// knows, and would flash the wrong variant on first paint before the effect
// runs. What makes a single DOM position work for both is `position: fixed`:
// in floating mode the button leaves normal flow, so its placement no longer
// depends on where it lives in the tree.
function AddTaskButton({ onClick }: AddTaskButtonProps) {
  return (
    // The label is display:none in floating mode, so the accessible name has
    // to come from the button itself or the FAB would announce as unlabelled.
    <button
      type="button"
      className="add-task-button"
      aria-label="Add task"
      onClick={onClick}
    >
      <span className="add-task-button-glyph">
        <PlusIcon />
      </span>
      <span className="add-task-button-label">Add Task</span>
    </button>
  )
}

export default AddTaskButton
