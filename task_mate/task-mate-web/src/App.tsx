import { useState } from 'react'
import LoginPage from './pages/LoginPage'
import { isLoggedIn, logout } from './services/api'
import './App.css'

function App() {
  // Seeded from localStorage so a refresh keeps the session.
  const [loggedIn, setLoggedIn] = useState(isLoggedIn())

  const handleSignOut = () => {
    logout()
    setLoggedIn(false)
  }

  if (!loggedIn) {
    return <LoginPage onLogin={() => setLoggedIn(true)} />
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
