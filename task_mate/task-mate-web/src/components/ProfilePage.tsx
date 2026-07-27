import { useCallback, useEffect, useState } from 'react'
import type { UserProfile } from '../services/api'
import { ApiError, NetworkError, getUserProfile } from '../services/api'
import { LogoutIcon, PersonIcon } from './icons'
import './ProfilePage.css'

interface ProfilePageProps {
  // Sign-out lives here now rather than in the app shell, mirroring the mobile
  // profile screen. App is still the one that clears the token and flips the
  // session flag.
  onSignOut?: () => void
}

function ProfilePage({ onSignOut }: ProfilePageProps) {
  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // A promise chain rather than async/await for the same reason as HomePage's
  // loadTasks: react-hooks/set-state-in-effect rejects a setState the mount
  // effect can reach synchronously, so the updates live in callbacks.
  const loadProfile = useCallback(() => {
    getUserProfile()
      .then((data) => {
        setProfile(data)
        setError('')
      })
      .catch((err: unknown) => {
        console.error('[profile] loading profile failed:', err)
        setError(
          err instanceof ApiError || err instanceof NetworkError
            ? err.message
            : 'Something went wrong loading your profile. Please try again.',
        )
      })
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    loadProfile()
  }, [loadProfile])

  const handleRetry = () => {
    setError('')
    setLoading(true)
    loadProfile()
  }

  return (
    <section className="profile-page">
      <div className="profile-card">
        {loading ? (
          <p className="profile-status">Loading profile...</p>
        ) : error ? (
          <div className="profile-error" role="alert">
            <p>{error}</p>
            <button type="button" className="profile-retry" onClick={handleRetry}>
              Try again
            </button>
          </div>
        ) : (
          <>
            <div className="profile-avatar">
              <PersonIcon />
            </div>
            <h2 className="profile-name">{profile?.name}</h2>
            <dl className="profile-details">
              <div className="profile-row">
                <dt>Email</dt>
                <dd>{profile?.email}</dd>
              </div>
              <div className="profile-row">
                <dt>Age</dt>
                <dd>{profile?.age}</dd>
              </div>
              <div className="profile-row">
                <dt>Occupation</dt>
                <dd>{profile?.occupation}</dd>
              </div>
            </dl>
          </>
        )}

        {/* Outside the loading/error branch on purpose. An expired JWT fails
            getUserProfile(), and a sign-out hidden behind a successful fetch
            would leave the user stuck in a dead session with no way back to
            the login screen. */}
        <button type="button" className="profile-signout" onClick={onSignOut}>
          <LogoutIcon />
          Log Out
        </button>
      </div>
    </section>
  )
}

export default ProfilePage
