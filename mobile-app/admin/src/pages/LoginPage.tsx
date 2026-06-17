import { useState } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '@/contexts/AuthContext'
import { Button } from '@/components/ui/Button'
import { Alert } from '@/components/ui/Alert'
export function LoginPage() {
  const { session, isAdmin, loading, signIn, configured } = useAuth()
  const location = useLocation()
  const denied = (location.state as { denied?: boolean } | null)?.denied

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  if (!loading && session && isAdmin) {
    return <Navigate to="/" replace />
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    const result = await signIn(email.trim(), password)
    setSubmitting(false)
    if (result.error) setError(result.error)
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-surface p-4">
      <div className="w-full max-w-md rounded-2xl border border-outline bg-surface-elevated p-8 shadow-sm">
        <div className="mb-6 text-center">
          <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-primary-600 text-lg font-bold text-white">
            A
          </div>
          <h1 className="text-xl font-medium text-on-surface">Akuko Admin</h1>
          <p className="mt-1 text-sm text-on-surface-muted">
            Sign in with an account where <code className="text-xs">profiles.is_admin</code> is
            true.
          </p>
        </div>

        {!configured ? (
          <Alert tone="warning" title="Supabase not configured">
            Copy <code className="text-xs">.env.example</code> to <code className="text-xs">.env.local</code>{' '}
            and set <code className="text-xs">VITE_SUPABASE_URL</code> and{' '}
            <code className="text-xs">VITE_SUPABASE_ANON_KEY</code>.
          </Alert>
        ) : (
          <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4">
            {denied ? (
              <Alert tone="error">Your account is not authorized for the admin dashboard.</Alert>
            ) : null}
            {error ? <Alert tone="error">{error}</Alert> : null}
            <div>
              <label htmlFor="email" className="mb-1 block text-sm font-medium text-on-surface">
                Email
              </label>
              <input
                id="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-lg border border-outline px-3 py-2 text-sm outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-50"
              />
            </div>
            <div>
              <label htmlFor="password" className="mb-1 block text-sm font-medium text-on-surface">
                Password
              </label>
              <input
                id="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full rounded-lg border border-outline px-3 py-2 text-sm outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-50"
              />
            </div>
            <Button type="submit" className="w-full" loading={submitting} disabled={!configured}>
              Sign in
            </Button>
          </form>
        )}

        <p className="mt-6 text-center text-xs text-on-surface-muted">
          Promote admins via SQL:{' '}
          <code className="block mt-1 break-all text-[10px]">
            update profiles set is_admin = true where id = &apos;&lt;uuid&gt;&apos;;
          </code>
        </p>
      </div>
    </div>
  )
}
