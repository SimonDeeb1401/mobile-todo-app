// Web port of the Flutter client at task_mate/lib/services/api_service.dart.
// Request/response shapes are taken from the Express controllers in
// task_mate/crud_api/src/controllers/, not from the Dart client, which has
// drifted from the backend in a few places (see the notes on reorderAllTasks
// and getTasks below).

// VITE_API_URL already includes the /api prefix, e.g. http://localhost:4000/api
const BASE_URL = import.meta.env.VITE_API_URL

const TOKEN_KEY = 'jwt'

export type Priority = 'low' | 'medium' | 'high'
export type SortMode = 'createdAt' | 'deadline' | 'priority' | 'manual'
export type SortOrder = 'asc' | 'desc'

export interface TaskComment {
  _id: string
  user: string
  text: string
  createdAt: string
}

export interface Task {
  // Mongoose serialises `_id`; the schema has no toJSON transform and no
  // virtuals, so there is no `id` field.
  _id: string
  title: string
  // Absent from the JSON entirely when it was never set.
  description?: string
  priority: Priority
  deadline: string
  completed: boolean
  // Owner's user id (hex ObjectId).
  user: string
  // Read as hex ObjectIds, but WRITTEN as email addresses — createTask and
  // updateTask run the array through resolveCollaboratorIdsByEmail server-side.
  collaborators: string[]
  comments: TaskComment[]
  orderIndex: number
  createdAt: string
  updatedAt: string
  __v?: number
}

export interface SortPreference {
  mode: SortMode
  order: SortOrder
}

export interface UserProfile {
  name: string
  age: number
  occupation: string
  email: string
}

// Shape the backend populates for GET /tasks/:id/collaborators — only these
// four fields are selected.
export interface CollaboratorUser {
  _id: string
  email: string
  name: string
  occupation: string
}

export interface CreateTaskInput {
  title: string
  description?: string
  priority?: Priority
  // ISO 8601. Required by the Task schema even though the controller does not
  // validate it — omitting it yields a 500, not a 400.
  deadline: string
  completed?: boolean
  // Email addresses, not ids.
  collaborators?: string[]
}

// updateTask passes the whole request body to $set, so any Task field can be
// patched. Collaborators are emails here too.
export type UpdateTaskInput = Partial<CreateTaskInput> & {
  orderIndex?: number
}

export interface MoveTaskResult {
  success: boolean
  task: Task
  tasks: Task[]
}

export interface SortPreferenceResult {
  sortMode: SortMode
  sortOrder: SortOrder
  sortPreference: SortPreference
}

export interface UpdateSortPreferenceResult {
  message: string
  sortPreference: SortPreference
  tasks: Task[]
}

export interface CollaboratorsData {
  success: boolean
  user: CollaboratorUser
  collaborators: CollaboratorUser[]
}

// Thrown by every request helper on a non-2xx response. `status` lets callers
// special-case 401 (the JWT expires after an hour and there is no refresh
// endpoint); `details` carries the extra payload some errors add, e.g.
// { unknownEmails: [...] } on "Some collaborators were not found".
export class ApiError extends Error {
  status: number
  details?: unknown

  constructor(message: string, status: number, details?: unknown) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.details = details
  }
}

// Thrown when the request never produced a response at all: connection
// refused, DNS failure, CORS block, or a missing VITE_API_URL. Distinct from
// ApiError, which means the backend answered. The message is written to be
// shown to the user as-is, and names the URL so a wrong port or an API that
// isn't running is obvious from the screen alone.
export class NetworkError extends Error {
  url: string

  constructor(url: string, message?: string, cause?: unknown) {
    super(message ?? `Could not reach the server at ${url}. Is the API running?`)
    this.name = 'NetworkError'
    this.url = url
    this.cause = cause
  }
}

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

// The backend's extractToken requires exactly "Bearer <token>" — two
// space-separated parts, capital B. When there is no token we omit the header
// entirely rather than sending a literal "Bearer null" as the Dart client does.
function authHeaders(): Record<string, string> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' }
  const token = getToken()
  if (token) {
    headers.Authorization = `Bearer ${token}`
  }
  return headers
}

async function handleResponse<T>(res: Response): Promise<T> {
  const text = await res.text()

  let body: unknown = null
  if (text) {
    try {
      body = JSON.parse(text)
    } catch {
      body = null
    }
  }

  if (!res.ok) {
    // Every controller error is { error: string }, sometimes with `details`.
    const payload = body as { error?: string; details?: unknown } | null
    throw new ApiError(payload?.error ?? res.statusText, res.status, payload?.details)
  }

  // A 2xx carrying something other than JSON is a server or proxy problem, not
  // a network one — e.g. a dev-server HTML fallback. Throw rather than hand
  // back null, so callers don't dereference it and report an unreachable
  // server that in fact answered. An empty body (`text` falsy) is legitimate
  // and still resolves to null.
  if (text && body === null) {
    throw new ApiError('Unexpected response from the server', res.status, {
      url: res.url,
      contentType: res.headers.get('content-type'),
    })
  }

  return body as T
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  // Vite reads .env only at dev-server start, so a missing or misspelled
  // VITE_API_URL leaves BASE_URL undefined and would otherwise fetch
  // "undefined/auth/login" relative to the Vite origin — a 404 of HTML that
  // looks nothing like the real problem.
  if (!BASE_URL) {
    throw new NetworkError(
      path,
      'VITE_API_URL is not set. Add it to task-mate-web/.env and restart the dev server.',
    )
  }

  const url = `${BASE_URL}${path}`

  let res: Response
  try {
    res = await fetch(url, { ...init, headers: authHeaders() })
  } catch (cause) {
    // fetch rejects with a bare "Failed to fetch" that names neither the URL
    // nor the reason, so log the original before replacing it.
    console.error(`[api] request to ${url} never reached a server:`, cause)
    throw new NetworkError(url, undefined, cause)
  }

  return handleResponse<T>(res)
}

// --- Auth ---------------------------------------------------------------

// All five fields are required. Note `age` is validated with a falsy check
// server-side, so 0 is rejected. Signup does NOT log you in — there is no
// token in the response; call login() afterwards.
export async function signup(
  email: string,
  password: string,
  name: string,
  age: number,
  occupation: string,
): Promise<{ message: string }> {
  return request<{ message: string }>('/auth/signup', {
    method: 'POST',
    body: JSON.stringify({ email, password, name, age, occupation }),
  })
}

// Stores the token in localStorage and returns it.
export async function login(email: string, password: string): Promise<string> {
  const data = await request<{ token: string } | null>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  })

  // An empty 200 body resolves to null (see handleResponse), and dereferencing
  // it here would throw a TypeError that callers can only report as a generic
  // failure. The server answered, so this is an ApiError.
  if (!data?.token) {
    throw new ApiError('Login response contained no token', 200)
  }

  localStorage.setItem(TOKEN_KEY, data.token)
  return data.token
}

// Client-side only; the backend has no logout endpoint.
export function logout(): void {
  localStorage.removeItem(TOKEN_KEY)
}

export function isLoggedIn(): boolean {
  return getToken() !== null
}

// --- Tasks --------------------------------------------------------------

// Returns a bare array, not a { tasks } envelope. Sorting is driven by the
// sortPreference baked into the JWT at login time, so it will not reflect a
// PATCH /user/sortPreference until the user logs in again — use the `tasks`
// array that updateSortPreference returns instead.
//
// The Dart client sends `search` and `limit` query params. Neither works:
// `limit` is never read, and `search` is applied to a filter object that all
// three sort branches in getTasks discard. Omitted here deliberately.
export async function getTasks(): Promise<Task[]> {
  return request<Task[]>('/tasks')
}

export async function createTask(input: CreateTaskInput): Promise<Task> {
  return request<Task>('/tasks', {
    method: 'POST',
    body: JSON.stringify(input),
  })
}

// Owner-only: the query is { _id, user }, so collaborators get a 404.
// Replaces both updateTask and updateCompleteStatus from the Dart client —
// the controller $sets whatever body it receives, so `completed` is just
// another field in the patch.
export async function updateTask(id: string, patch: UpdateTaskInput): Promise<Task> {
  return request<Task>(`/tasks/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(patch),
  })
}

export async function deleteTask(id: string): Promise<{ message: string }> {
  return request<{ message: string }>(`/tasks/${id}`, { method: 'DELETE' })
}

// newIndex is a position in the user's sorted task list, not an orderIndex.
export async function moveTask(id: string, newIndex: number): Promise<MoveTaskResult> {
  return request<MoveTaskResult>(`/tasks/${id}/move`, {
    method: 'PATCH',
    body: JSON.stringify({ newIndex }),
  })
}

// The body key is `orderedTaskIds` — the Dart client sends { tasks }, which
// the controller cannot destructure and turns into a 500. The backend also
// throws on an empty array (bulkWrite([]) is invalid), so guard here.
export async function reorderAllTasks(orderedTaskIds: string[]): Promise<{ success: boolean }> {
  if (orderedTaskIds.length === 0) {
    return { success: true }
  }
  return request<{ success: boolean }>('/tasks/reorder', {
    method: 'POST',
    body: JSON.stringify({ orderedTaskIds }),
  })
}

export async function getCollaboratorsData(taskId: string): Promise<CollaboratorsData> {
  return request<CollaboratorsData>(`/tasks/${taskId}/collaborators`)
}

// --- User ---------------------------------------------------------------

// Reads from the database, so unlike getTasks it always reflects the latest
// update. Returns the same preference three ways.
export async function getSortPreference(): Promise<SortPreferenceResult> {
  return request<SortPreferenceResult>('/user/sortPreference')
}

// `mode` and `order` are two flat top-level fields, not one combined string
// and not nested under `sortPreference`. Also returns the re-sorted task list.
export async function updateSortPreference(
  mode: SortMode,
  order: SortOrder,
): Promise<UpdateSortPreferenceResult> {
  return request<UpdateSortPreferenceResult>('/user/sortPreference', {
    method: 'PATCH',
    body: JSON.stringify({ mode, order }),
  })
}

// Returns exactly { name, age, occupation, email } — no _id.
export async function getUserProfile(): Promise<UserProfile> {
  return request<UserProfile>('/user/profile')
}
