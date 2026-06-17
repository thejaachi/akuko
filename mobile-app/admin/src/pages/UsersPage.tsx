import { useEffect, useState } from 'react'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Alert } from '@/components/ui/Alert'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import { listProfilesForAdmin, listPublicProfiles } from '@/services/profiles'
import type { Profile, PublicProfile } from '@/types/database'

export function UsersPage() {
  const [profiles, setProfiles] = useState<Profile[] | null>(null)
  const [publicProfiles, setPublicProfiles] = useState<PublicProfile[]>([])
  const [usingPublicView, setUsingPublicView] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void (async () => {
      try {
        const rows = await listProfilesForAdmin()
        setProfiles(rows)
        setUsingPublicView(false)
      } catch {
        try {
          setUsingPublicView(true)
          setPublicProfiles(await listPublicProfiles())
        } catch (e) {
          setError(e instanceof Error ? e.message : 'Failed to load users')
        }
      } finally {
        setLoading(false)
      }
    })()
  }, [])

  return (
    <AdminPage>
      <PageHeader
        title="Users"
        description="Profiles for operations. Admins read full profiles; fallback uses public_profiles view (0007)."
      />

      {usingPublicView ? (
        <Alert tone="warning" title="Limited view">
          Showing <code className="text-xs">public_profiles</code> only — admin flag hidden until
          you have <code className="text-xs">profiles.is_admin</code> and migration 0007 applied.
        </Alert>
      ) : null}

      {error ? <Alert tone="error">{error}</Alert> : null}

      {loading ? (
        <LoadingSpinner />
      ) : profiles ? (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[560px] text-left text-sm">
              <thead>
                <tr className="border-b border-outline text-on-surface-muted">
                  <th className="px-5 py-3 font-medium">Name</th>
                  <th className="px-5 py-3 font-medium">User ID</th>
                  <th className="px-5 py-3 font-medium">Role</th>
                  <th className="px-5 py-3 font-medium">Joined</th>
                </tr>
              </thead>
              <tbody>
                {profiles.map((p) => (
                  <tr key={p.id} className="border-b border-outline last:border-0">
                    <td className="px-5 py-3">{p.full_name ?? '—'}</td>
                    <td className="px-5 py-3 font-mono text-xs text-on-surface-muted">{p.id}</td>
                    <td className="px-5 py-3">
                      <div className="flex flex-wrap gap-1">
                        {p.is_admin ? <Badge tone="primary">Admin</Badge> : null}
                        <Badge>{p.role ?? 'reader'}</Badge>
                      </div>
                    </td>
                    <td className="px-5 py-3 text-on-surface-muted">
                      {new Date(p.created_at).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[480px] text-left text-sm">
              <thead>
                <tr className="border-b border-outline text-on-surface-muted">
                  <th className="px-5 py-3 font-medium">Name</th>
                  <th className="px-5 py-3 font-medium">User ID</th>
                </tr>
              </thead>
              <tbody>
                {publicProfiles.map((p) => (
                  <tr key={p.id} className="border-b border-outline last:border-0">
                    <td className="px-5 py-3">{p.full_name ?? '—'}</td>
                    <td className="px-5 py-3 font-mono text-xs text-on-surface-muted">{p.id}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </AdminPage>
  )
}
