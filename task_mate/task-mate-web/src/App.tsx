import { useState } from 'react'
import LoginPage from './pages/LoginPage'
import SignupPage from './pages/SignupPage'
import { isLoggedIn, logout } from './services/api'
import './App.css'

function App() {
  // Seeded from localStorage so a refresh keeps the session.
  const [loggedIn, setLoggedIn] = useState(isLoggedIn())
  const [authView, setAuthView] = useState<'login' | 'signup'>('login')

  const handleSignOut = () => {
    logout()
    setLoggedIn(false)
    setAuthView('login')
  }

  if (!loggedIn) {
    // SignupPage logs the new account in before calling onSignedUp, so the
    // token is already in localStorage by the time we flip this.
    return authView === 'login' ? (
      <LoginPage
        onLogin={() => setLoggedIn(true)}
        onShowSignup={() => setAuthView('signup')}
      />
    ) : (
      <SignupPage
        onSignedUp={() => setLoggedIn(true)}
        onShowLogin={() => setAuthView('login')}
      />
    )
  }

  return (
    <div className="app-shell">
      <h1>Task Mate</h1>
      <p>You're signed in.</p>
      <button className="app-signout" onClick={handleSignOut}>
        Sign out
      </button>
    </div>
  )
}

export default App
