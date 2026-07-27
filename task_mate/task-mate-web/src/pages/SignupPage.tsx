import { useState } from 'react'
import type { FormEvent } from 'react'
import { ApiError, NetworkError, login, signup } from '../services/api'
import './SignupPage.css'

interface SignupPageProps {
  // The page signs the new account in itself, so the parent only needs the
  // signal — same contract as LoginPage's onLogin.
  onSignedUp?: () => void
  onShowLogin?: () => void
}

function SignupPage({ onSignedUp, onShowLogin }: SignupPageProps) {
  const [name, setName] = useState('')
  const [age, setAge] = useState('')
  const [occupation, setOccupation] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    const trimmedName = name.trim()
    const trimmedOccupation = occupation.trim()
    const trimmedEmail = email.trim()

    if (!trimmedName || !age || !trimmedOccupation || !trimmedEmail || !password) {
      setError('Please fill in every field.')
      return
    }

    // The backend guards age with a plain falsy check, so it rejects 0, and a
    // non-numeric age reaches Mongoose as a CastError and comes back as a bare
    // 500 "Server error". Catch both here instead.
    const parsedAge = Number(age)
    if (!Number.isInteger(parsedAge) || parsedAge < 1 || parsedAge > 120) {
      setError('Please enter a valid age.')
      return
    }

    setError('')
    setSubmitting(true)

    // Signup returns no token, so the session comes from the login() that
    // follows. If that second call fails the account still exists, and telling
    // the user to retry signup would only earn them "User already exists".
    let created = false

    try {
      await signup(trimmedEmail, password, trimmedName, parsedAge, trimmedOccupation)
      created = true
      await login(trimmedEmail, password)
      onSignedUp?.()
    } catch (err) {
      console.error(created ? '[signup] sign-in after signup failed:' : '[signup] failed:', err)
      if (created) {
        setError('Account created, but sign-in failed. Please sign in.')
      } else {
        // ApiError means the backend answered and its `error` field is already
        // user-readable ("User already exists"); NetworkError means the request
        // never got there and carries the URL it tried. Anything else is a bug
        // in this client, and saying "could not reach the server" would
        // misdirect.
        setError(
          err instanceof ApiError || err instanceof NetworkError
            ? err.message
            : 'Something went wrong creating your account. Please try again.',
        )
      }
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="signup-page">
      <div className="signup-card">
        <h1>Create account</h1>
        <form onSubmit={handleSubmit} noValidate>
          <div className="signup-field">
            <label htmlFor="name">Name</label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoComplete="name"
            />
          </div>
          <div className="signup-field">
            <label htmlFor="age">Age</label>
            <input
              id="age"
              type="number"
              inputMode="numeric"
              min="1"
              value={age}
              onChange={(e) => setAge(e.target.value)}
            />
          </div>
          <div className="signup-field">
            <label htmlFor="occupation">Occupation</label>
            <input
              id="occupation"
              type="text"
              value={occupation}
              onChange={(e) => setOccupation(e.target.value)}
              autoComplete="organization-title"
            />
          </div>
          <div className="signup-field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
            />
          </div>
          <div className="signup-field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="new-password"
            />
          </div>
          {error && <p className="signup-error">{error}</p>}
          <button type="submit" className="signup-submit" disabled={submitting}>
            {submitting ? 'Creating account...' : 'Create account'}
          </button>
        </form>
        <p className="signup-switch">
          Already have an account?{' '}
          <button type="button" className="signup-link" onClick={onShowLogin}>
            Sign in
          </button>
        </p>
      </div>
    </div>
  )
}

export default SignupPage
