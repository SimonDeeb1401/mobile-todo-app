import { useState } from 'react'
import HomePage from './components/HomePage'
import LoginPage from './pages/LoginPage'
import SignupPage from './pages/SignupPage'
import { isLoggedIn, logout } from './services/api'

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

  // HomePage is the authenticated shell and owns the Tasks/Profile toggle. The
  // sign-out control lives in its ProfilePage now, so this only hands down the
  // handler that clears the token.
  return <HomePage onSignOut={handleSignOut} />
}

export default App
