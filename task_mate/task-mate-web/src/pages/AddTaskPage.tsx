import { useState } from 'react'
import type { FormEvent, KeyboardEvent } from 'react'
import type { CreateTaskInput, Priority, Task } from '../services/api'
import { ApiError, NetworkError, createTask } from '../services/api'
import {
  AddTaskIcon,
  ArrowBackIcon,
  CalendarIcon,
  CloseIcon,
  DescriptionIcon,
  FlagIcon,
  PersonAddIcon,
  PlusIcon,
  TitleIcon,
} from '../components/icons'
import './AddTaskPage.css'

// Web port of lib/screens/add_task.dart — same field order, same validation
// rules, same two-button footer. The two deliberate departures are both places
// where the mobile widget has no web equivalent: the tap-to-open showDatePicker
// becomes a native <input type="date">, and the Low/Medium/High DropdownButton
// becomes a native <select> whose flag icon carries the priority colour (an
// <option> cannot hold the coloured dot the mobile menu draws).

interface AddTaskPageProps {
  // Receives the created row so the parent can splice it into the list it
  // already holds instead of refetching. This is the web stand-in for
  // `Navigator.pop(context, true)`, except the task comes back with the signal.
  onCreated?: (task: Task) => void
  onCancel?: () => void
}

// Stored lowercase — the Priority union the API expects — and capitalised only
// for display. The mobile screen holds 'Medium' and lowercases at submit time.
const PRIORITIES: { value: Priority; label: string }[] = [
  { value: 'low', label: 'Low' },
  { value: 'medium', label: 'Medium' },
  { value: 'high', label: 'High' },
]

// _isValidEmail from add_task.dart, verbatim.
const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

const DEFAULT_DEADLINE_DAYS = 7
const MAX_DEADLINE_DAYS = 365

// <input type="date"> wants local calendar fields, and so does TaskList's
// formatDeadline. Going through toISOString() here would print the UTC date and
// offer the wrong first selectable day to anyone east of UTC after 00:00 local.
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

// The Task schema requires `deadline` and the controller does not validate it,
// so an omitted one is a 500 rather than a 400 (see CreateTaskInput). An empty
// field therefore falls back to a week out, exactly as the mobile screen does.
//
// The date is rebuilt through the local-midnight constructor rather than
// `new Date('2026-08-05')`, which the spec parses as UTC midnight — that lands
// on the previous day for anyone west of UTC once it is read back locally.
function deadlineToIso(value: string): string {
  if (!value) {
    return daysFromNow(DEFAULT_DEADLINE_DAYS).toISOString()
  }
  const [year, month, day] = value.split('-').map(Number)
  return new Date(year, month - 1, day).toISOString()
}

// createTask rejects unknown collaborator emails with a 400 whose message is
// just "Some collaborators were not found" — the addresses live in
// `details.unknownEmails`, so the bare message leaves the user guessing which
// chip to remove.
function messageFor(err: unknown): string {
  if (err instanceof ApiError) {
    const unknown = (err.details as { unknownEmails?: string[] } | undefined)?.unknownEmails
    return unknown?.length ? `${err.message}: ${unknown.join(', ')}` : err.message
  }
  if (err instanceof NetworkError) {
    return err.message
  }
  return 'Something went wrong creating your task. Please try again.'
}

function AddTaskPage({ onCreated, onCancel }: AddTaskPageProps) {
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState<Priority>('medium')
  const [deadline, setDeadline] = useState('')
  const [collaborators, setCollaborators] = useState<string[]>([])
  const [collaboratorInput, setCollaboratorInput] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  // firstDate / lastDate from the mobile showDatePicker call. Recomputed each
  // render rather than frozen in state, so a tab left open past midnight does
  // not keep offering yesterday.
  const minDeadline = toDateInputValue(new Date())
  const maxDeadline = toDateInputValue(daysFromNow(MAX_DEADLINE_DAYS))

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

    const input: CreateTaskInput = {
      title: trimmedTitle,
      priority,
      deadline: deadlineToIso(deadline),
      // New tasks are never complete. Sent explicitly to match the mobile call;
      // the controller would default it anyway.
      completed: false,
      // Emails, not ids — the controller runs them through
      // resolveCollaboratorIdsByEmail.
      collaborators,
    }

    // Left off entirely when blank rather than sent as '': the field is
    // optional, and an empty string would persist as one.
    const trimmedDescription = description.trim()
    if (trimmedDescription) {
      input.description = trimmedDescription
    }

    try {
      const task = await createTask(input)
      onCreated?.(task)
    } catch (err) {
      console.error('[add-task] creating task failed:', err)
      setError(messageFor(err))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <section className="add-task-page">
      {/* The Flutter route's own AppBar: circled back button on the left, title
          centred. A three-column grid rather than flex, so the title is centred
          on the page and not merely on the space the button leaves. */}
      <header className="add-task-header">
        <button
          type="button"
          className="add-task-back"
          aria-label="Back to tasks"
          onClick={onCancel}
        >
          <ArrowBackIcon />
        </button>
        <h2 className="add-task-heading">Add New Task</h2>
      </header>

      <form className="add-task-form" onSubmit={handleSubmit} noValidate>
        <div className="add-task-badge">
          <AddTaskIcon />
        </div>

        <div className="add-task-field">
          <label className="add-task-label" htmlFor="task-title">
            Task Title
          </label>
          <div className="add-task-input-shell">
            <span className="add-task-input-icon">
              <TitleIcon />
            </span>
            <input
              id="task-title"
              type="text"
              className="add-task-input"
              placeholder="Enter task title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              autoFocus
            />
          </div>
        </div>

        <div className="add-task-field">
          <label className="add-task-label" htmlFor="task-description">
            Description (Optional)
          </label>
          <div className="add-task-input-shell add-task-input-shell-multiline">
            <span className="add-task-input-icon">
              <DescriptionIcon />
            </span>
            <textarea
              id="task-description"
              className="add-task-input add-task-textarea"
              placeholder="Enter task description"
              rows={4}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>
        </div>

        <div className="add-task-field">
          <label className="add-task-label" htmlFor="task-priority">
            Priority
          </label>
          <div className="add-task-input-shell">
            {/* The colour is the whole signal here, since the native option list
                cannot carry the mobile menu's coloured dots. */}
            <span className={`add-task-input-icon add-task-flag-${priority}`}>
              <FlagIcon />
            </span>
            <select
              id="task-priority"
              className="add-task-input add-task-select"
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

        <div className="add-task-field">
          <label className="add-task-label" htmlFor="task-deadline">
            Deadline (Optional)
          </label>
          <div className="add-task-input-shell">
            <span className="add-task-input-icon">
              <CalendarIcon />
            </span>
            <input
              id="task-deadline"
              type="date"
              className="add-task-input add-task-date"
              value={deadline}
              min={minDeadline}
              max={maxDeadline}
              onChange={(e) => setDeadline(e.target.value)}
            />
          </div>
          <p className="add-task-hint">
            Defaults to a week from today when left empty.
          </p>
        </div>

        <div className="add-task-field">
          <label className="add-task-label" htmlFor="task-collaborator">
            Collaborators
          </label>
          <div className="add-task-input-shell add-task-input-shell-multiline">
            {collaborators.length > 0 && (
              <ul className="add-task-chips">
                {collaborators.map((email) => (
                  <li className="add-task-chip" key={email}>
                    {email}
                    <button
                      type="button"
                      className="add-task-chip-remove"
                      aria-label={`Remove ${email}`}
                      onClick={() => removeCollaborator(email)}
                    >
                      <CloseIcon />
                    </button>
                  </li>
                ))}
              </ul>
            )}
            <div className="add-task-collaborator-row">
              <span className="add-task-input-icon">
                <PersonAddIcon />
              </span>
              <input
                id="task-collaborator"
                type="email"
                className="add-task-input"
                placeholder="Type email and press Enter"
                value={collaboratorInput}
                onChange={(e) => setCollaboratorInput(e.target.value)}
                onKeyDown={handleCollaboratorKeyDown}
                autoComplete="off"
              />
              <button type="button" className="add-task-chip-add" onClick={addCollaborator}>
                Add
              </button>
            </div>
          </div>
        </div>

        {error && (
          <p className="add-task-error" role="alert">
            {error}
          </p>
        )}

        <button type="submit" className="add-task-submit" disabled={submitting}>
          {submitting ? (
            <>
              <span className="add-task-spinner" />
              Creating...
            </>
          ) : (
            <>
              <PlusIcon />
              Create Task
            </>
          )}
        </button>

        <button type="button" className="add-task-cancel" onClick={onCancel}>
          Cancel
        </button>
      </form>
    </section>
  )
}

export default AddTaskPage
