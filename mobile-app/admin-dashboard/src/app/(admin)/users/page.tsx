'use client'

import { useEffect, useState } from 'react'
import { Card } from '@/components/ui/card'
import { listProfilesForAdmin, updateProfileRole } from '@/services/profiles'
import type { Profile, ProfileRole } from '@/types/database'

export default function UsersPage() {
  const [profiles, setProfiles] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function reload() {
    try {
      setProfiles(await listProfilesForAdmin())
      setError(null)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load users')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void reload()
  }, [])

  return (
    <div>
      <h1 className="text-2xl font-semibold">Users</h1>
      <p className="text-sm text-slate-500">
        List profiles (admin RLS). Demote role to reader to restrict elevated access.
      </p>
      {error ? <p className="mt-4 text-sm text-red-600">{error}</p> : null}
      <Card className="mt-6 overflow-x-auto">
        {loading ? (
          <p className="p-6">Loading…</p>
        ) : (
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead>
              <tr className="border-b border-slate-200 text-slate-500">
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3">Role</th>
                <th className="px-4 py-3">Admin</th>
              </tr>
            </thead>
            <tbody>
              {profiles.map((p) => (
                <tr key={p.id} className="border-b border-slate-100">
                  <td className="px-4 py-3">{p.full_name ?? p.id.slice(0, 8)}</td>
                  <td className="px-4 py-3">
                    <select
                      value={p.role}
                      onChange={(e) =>
                        void updateProfileRole(p.id, e.target.value as ProfileRole).then(reload)
                      }
                      className="rounded border px-2 py-1"
                    >
                      {(['reader', 'author', 'publisher', 'admin'] as ProfileRole[]).map((r) => (
                        <option key={r} value={r}>
                          {r}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td className="px-4 py-3">{p.is_admin ? 'Yes' : 'No'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  )
}
