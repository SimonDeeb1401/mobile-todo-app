import { useState } from 'react'
import type { FormEvent } from 'react'
import { ApiError, NetworkError, login } from '../services/api'
import './LoginPage.css'

interface LoginPageProps {
  // login() stores the token itself, so the parent only needs the signal.
  onLogin?: () => void
  onShowSignup?: () => void
}

function LoginPage({ onLogin, onShowSignup }: LoginPageProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (!email || !password) {
      setError('Please enter both email and password.')
      return
    }

    setError('')
    setSubmitting(true)

    try {
      await login(email, password)
      onLogin?.()
    } catch (err) {
      console.error('[login] sign-in failed:', err)
      // ApiError means the backend answered and its `error` field is already
      // user-readable ("Invalid credentials"); NetworkError means the request
      // never got there and carries the URL it tried. Anything else is a bug in
      // this client, and saying "could not reach the server" would misdirect.
      setError(
        err instanceof ApiError || err instanceof NetworkError
          ? err.message
          : 'Something went wrong signing in. Please try again.',
      )
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>Sign in</h1>
        <form onSubmit={handleSubmit} noValidate>
          <div className="login-field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
            />
          </div>
          <div className="login-field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
            />
          </div>
          {error && <p className="login-error">{error}</p>}
          <button type="submit" className="login-submit" disabled={submitting}>
            {submitting ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
        <p className="login-switch">
          Don't have an account?{' '}
          <button type="button" className="login-link" onClick={onShowSignup}>
            Sign up
          </button>
        </p>
      </div>
    </div>
  )
}

export default LoginPage
