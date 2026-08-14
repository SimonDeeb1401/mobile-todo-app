import { useEffect, useState } from 'react'
import type { FormEvent, KeyboardEvent } from 'react'
import type { Priority, Task, UpdateTaskInput } from '../services/api'
import {
  ApiError,
  NetworkError,
  getCollaboratorsData,
  updateTask,
} from '../services/api'
import {
  ArrowBackIcon,
  CalendarIcon,
  CloseIcon,
  DescriptionIcon,
  EditNoteIcon,
  FlagIcon,
  PersonAddIcon,
  SaveIcon,
  TitleIcon,
} from './icons'
import './EditTaskPage.css'

// Web port of lib/screens/edit_tasks.dart — same field order, same validation
// rules, same Save/Cancel footer, and the same edit_note badge over the form.
// It shares AddTaskPage's two web-vs-mobile departures (a native <input
// type="date"> for showDatePicker, a native <select> for the priority
// DropdownButton) and adds one of its own: the mobile screen reads the
// collaborator emails out of TaskProvider's cached snapshot, which the web
// client has no equivalent of, so they are fetched here from
// GET /tasks/:id/collaborators.

interface EditTaskPageProps {
  // The row as the list already holds it. Every field except the collaborator
  // emails can be prefilled straight from this.
  task: Task
  // Receives the server's updated row so the parent can patch the list in place
  // instead of refetching — the web stand-in for `Navigator.pop(context, ...)`.
  onSaved?: (task: Task) => void
  onCancel?: () => void
}

const PRIORITIES: { value: Priority; label: string }[] = [
  { value: 'low', label: 'Low' },
  { value: 'medium', label: 'Medium' },
  { value: 'high', label: 'High' },
]

// _isValidEmail from edit_tasks.dart, verbatim.
const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

const MAX_DEADLINE_DAYS = 365

// Local calendar fields, not toISOString(): the UTC date is a day off for
// anyone west of UTC in the evening, which would prefill the wrong deadline and
// offer the wrong first selectable day. Same helper as AddTaskPage.
function toDateInputValue(date: Date): string {
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  const day = `${date.getDate()}`.padStart(2, '0')
  return `${date.getFullYear()}-${month}-${day}`
}

function daysFromNow(days: number): Date {
  const date = new Date()
  date.setDate(date.getDate() + days)
  return date
}

// The stored deadline as a date-input value. Tasks predating the add-task form
// can carry an unparseable one, which would otherwise render as a blank field
// that silently means "leave unchanged".
function deadlineToInputValue(deadline: string): string {
  const date = new Date(deadline)
  return Number.isNaN(date.getTime()) ? '' : toDateInputValue(date)
}

// Rebuilt through the local-midnight constructor rather than
// `new Date('2026-08-05')`, which the spec parses as UTC midnight — that lands
// on the previous day once it is read back locally west of UTC.
function deadlineToIso(value: string): string {
  const [year, month, day] = value.split('-').map(Number)
  return new Date(year, month - 1, day).toISOString()
}

// updateTask rejects unknown collaborator emails with a 400 whose message is
// just "Some collaborators were not found" — the addresses live in
// `details.unknownEmails`, so the bare message leaves the user guessing which
// chip to remove.
function messageFor(err: unknown): string {
  if (err instanceof ApiError) {
    const unknown = (err.details as { unknownEmails?: string[] } | undefined)?.unknownEmails
    if (unknown?.length) {
      return `${err.message}: ${unknown.join(', ')}`
    }
    // The controller's query is { _id, user }, so a collaborator editing
    // someone else's task gets a 404 that "Task not found" describes
    // misleadingly — the task exists, it just isn't theirs to change.
    if (err.status === 404) {
      return 'Only the task owner can edit this task.'
    }
    return err.message
  }
  if (err instanceof NetworkError) {
    return err.message
  }
  return 'Something went wrong saving your task. Please try again.'
}

function EditTaskPage({ task, onSaved, onCancel }: EditTaskPageProps) {
  const [title, setTitle] = useState(task.title)
  const [description, setDescription] = useState(task.description ?? '')
  const [priority, setPriority] = useState<Priority>(task.priority)
  const [deadline, setDeadline] = useState(() => deadlineToInputValue(task.deadline))
  const [collaborators, setCollaborators] = useState<string[]>([])
  // `task.collaborators` holds ids, but updateTask writes emails, so the chips
  // can only be filled from the collaborators endpoint. Until that lands the
  // array below is not the task's real collaborator set, and submitting it
  // would clear the list — every write of the field is gated on this flag.
  // Optional chaining despite the type saying string[], the same guard HomePage
  // applies: a row missing the array would otherwise throw during render.
  const collaboratorCount = task.collaborators?.length ?? 0
  const [collaboratorsLoaded, setCollaboratorsLoaded] = useState(collaboratorCount === 0)
  const [collaboratorsError, setCollaboratorsError] = useState('')
  const [collaboratorInput, setCollaboratorInput] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  // lastDate from the mobile showDatePicker call. firstDate is DateTime.now()
  // there, but an existing task can already be overdue, and a `min` above its
  // own stored value would mark the prefilled field invalid before the user has
  // touched anything — so a past deadline widens the floor to itself.
  const today = toDateInputValue(new Date())
  const minDeadline = deadline && deadline < today ? deadline : today
  const maxDeadline = toDateInputValue(daysFromNow(MAX_DEADLINE_DAYS))

  // initState's collaborator load, minus the provider cache. Runs once per task
  // id; the endpoint is owner-or-collaborator readable, so it succeeds wherever
  // the edit form is reachable at all.
  useEffect(() => {
    if (collaboratorCount === 0) {
      return
    }

    let active = true

    getCollaboratorsData(task._id)
      .then((data) => {
        if (!active) {
          return
        }
        // Deduplicated because the mobile screen does the same: the array is
        // populated from ids, and a task written before the add-task form
        // rejected duplicates can hold the same user twice.
        const emails = (data?.collaborators ?? []).map((c) => c.email.toLowerCase())
        setCollaborators([...new Set(emails)])
        setCollaboratorsError('')
        setCollaboratorsLoaded(true)
      })
      .catch((err: unknown) => {
        if (!active) {
          return
        }
        console.error('[edit-task] loading collaborators failed:', err)
        setCollaboratorsError(
          'Could not load this task’s collaborators, so they will be left unchanged.',
        )
      })

    return () => {
      active = false
    }
  }, [task._id, collaboratorCount])

  // _addCollaboratorFromInput: validate, reject duplicates, store lowercase.
  const addCollaborator = () => {
    const raw = collaboratorInput.trim()
    if (!raw) {
      return
    }
    if (!EMAIL_PATTERN.test(raw)) {
      setError('Please enter a valid email address.')
      return
    }
    if (collaborators.includes(raw.toLowerCase())) {
      setError('This collaborator is already added.')
      return
    }

    setError('')
    setCollaborators((current) => [...current, raw.toLowerCase()])
    setCollaboratorInput('')
  }

  const handleCollaboratorKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter') {
      // A text input inside a <form> submits it on Enter. Here Enter means "add
      // this chip", which is what onSubmitted does on mobile.
      event.preventDefault()
      addCollaborator()
    }
  }

  const removeCollaborator = (email: string) => {
    setCollaborators((current) => current.filter((item) => item !== email))
  }

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    // The two title rules from the mobile validator. `noValidate` on the form
    // keeps the browser from pre-empting them with its own bubble.
    const trimmedTitle = title.trim()
    if (!trimmedTitle) {
      setError('Please enter a task title')
      return
    }
    if (trimmedTitle.length < 3) {
      setError('Title must be at least 3 characters')
      return
    }

    setError('')
    setSubmitting(true)

    // updateTask $sets whatever it is given, so the patch carries only what this
    // form owns — `completed` and `orderIndex` are left to the checkbox and the
    // reorder endpoint.
    const patch: UpdateTaskInput = {
      title: trimmedTitle,
      priority,
      // Always sent, unlike the create call: an emptied box has to be able to
      // remove a description that is already stored, and omitting the key would
      // silently keep the old text.
      description: description.trim(),
    }

    // `deadline` is required by the schema. Clearing the field therefore means
    // "leave the stored one alone" rather than "unset it" — $set: null would
    // slip past findOneAndUpdate, which does not run validators, and leave a
    // task the list can only render as "No deadline".
    if (deadline) {
      patch.deadline = deadlineToIso(deadline)
    }

    // Emails, not ids — the controller runs them through
    // resolveCollaboratorIdsByEmail. Omitted while the fetch is unresolved, so
    // a failed load cannot wipe the collaborator list.
    if (collaboratorsLoaded) {
      patch.collaborators = collaborators
    }

    try {
      const updated = await updateTask(task._id, patch)
      onSaved?.(updated)
    } catch (err) {
      console.error('[edit-task] updating task failed:', err)
      setError(messageFor(err))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <section className="edit-task-page">
      {/* The Flutter route's own AppBar: circled back button on the left, title
          centred. A three-column grid rather than flex, so the title is centred
          on the page and not merely on the space the button leaves. */}
      <header className="edit-task-header">
        <button
          type="button"
          className="edit-task-back"
          aria-label="Back to tasks"
          onClick={onCancel}
        >
          <ArrowBackIcon />
        </button>
        <h2 className="edit-task-heading">Edit Task</h2>
      </header>

      <form className="edit-task-form" onSubmit={handleSubmit} noValidate>
        <div className="edit-task-badge">
          <EditNoteIcon />
        </div>

        <div className="edit-task-field">
          <label className="edit-task-label" htmlFor="edit-task-title">
            Task Title
          </label>
          <div className="edit-task-input-shell">
            <span className="edit-task-input-icon">
              <TitleIcon />
            </span>
            <input
              id="edit-task-title"
              type="text"
              className="edit-task-input"
              placeholder="Enter task title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              autoFocus
            />
          </div>
        </div>

        <div className="edit-task-field">
          <label className="edit-task-label" htmlFor="edit-task-description">
            Description (Optional)
          </label>
          <div className="edit-task-input-shell edit-task-input-shell-multiline">
            <span className="edit-task-input-icon">
              <DescriptionIcon />
            </span>
            <textarea
              id="edit-task-description"
              className="edit-task-input edit-task-textarea"
              placeholder="Enter task description"
              rows={4}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>
        </div>

        <div className="edit-task-field">
          <label className="edit-task-label" htmlFor="edit-task-priority">
            Priority
          </label>
          <div className="edit-task-input-shell">
            {/* The colour is the whole signal here, since the native option list
                cannot carry the mobile menu's coloured dots. */}
            <span className={`edit-task-input-icon edit-task-flag-${priority}`}>
              <FlagIcon />
            </span>
            <select
              id="edit-task-priority"
              className="edit-task-input edit-task-select"
              value={priority}
              onChange={(e) => setPriority(e.target.value as Priority)}
            >
              {PRIORITIES.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="edit-task-field">
          <label className="edit-task-label" htmlFor="edit-task-deadline">
            Deadline (Optional)
          </label>
          <div className="edit-task-input-shell">
            <span className="edit-task-input-icon">
              <CalendarIcon />
            </span>
            <input
              id="edit-task-deadline"
              type="date"
              className="edit-task-input edit-task-date"
              value={deadline}
              min={minDeadline}
              max={maxDeadline}
              onChange={(e) => setDeadline(e.target.value)}
            />
          </div>
          <p className="edit-task-hint">
            Clearing this keeps the deadline the task already has.
          </p>
        </div>

        <div className="edit-task-field">
          <label className="edit-task-label" htmlFor="edit-task-collaborator">
            Collaborators
          </label>
          <div className="edit-task-input-shell edit-task-input-shell-multiline">
            {collaborators.length > 0 && (
              <ul className="edit-task-chips">
                {collaborators.map((email) => (
                  <li className="edit-task-chip" key={email}>
                    {email}
                    <button
                      type="button"
                      className="edit-task-chip-remove"
                      aria-label={`Remove ${email}`}
                      onClick={() => removeCollaborator(email)}
                    >
                      <CloseIcon />
                    </button>
                  </li>
                ))}
              </ul>
            )}
            <div className="edit-task-collaborator-row">
              <span className="edit-task-input-icon">
                <PersonAddIcon />
              </span>
              <input
                id="edit-task-collaborator"
                type="email"
                className="edit-task-input"
                placeholder="Type email and press Enter"
                value={collaboratorInput}
                onChange={(e) => setCollaboratorInput(e.target.value)}
                onKeyDown={handleCollaboratorKeyDown}
                autoComplete="off"
              />
              <button type="button" className="edit-task-chip-add" onClick={addCollaborator}>
                Add
              </button>
            </div>
          </div>
          {/* Three states, only ever one at a time: still fetching, fetch
              failed, or loaded and editable with nothing to say. */}
          {!collaboratorsLoaded && !collaboratorsError && (
            <p className="edit-task-hint">Loading current collaborators...</p>
          )}
          {collaboratorsError && (
            <p className="edit-task-hint edit-task-hint-warning">{collaboratorsError}</p>
          )}
        </div>

        {error && (
          <p className="edit-task-error" role="alert">
            {error}
          </p>
        )}

        <button type="submit" className="edit-task-submit" disabled={submitting}>
          {submitting ? (
            <>
              <span className="edit-task-spinner" />
              Saving...
            </>
          ) : (
            <>
              <SaveIcon />
              Save Changes
            </>
          )}
        </button>

        <button type="button" className="edit-task-cancel" onClick={onCancel}>
          Cancel
        </button>
      </form>
    </section>
  )
}

export default EditTaskPage
