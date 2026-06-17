import { useCallback, useEffect, useState } from 'react'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Alert } from '@/components/ui/Alert'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import {
  approveAuthorPersona,
  listAuthorsWithStats,
  listPendingAuthorApplications,
  suspendAuthorPersona,
} from '@/services/authors'
import type { AuthorApplication, AuthorWithStats } from '@/types/database'

export function AuthorsPage() {
  const [authors, setAuthors] = useState<AuthorWithStats[]>([])
  const [pending, setPending] = useState<AuthorApplication[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)

  const load = useCallback(() => {
    setLoading(true)
    setError(null)
    Promise.all([listAuthorsWithStats(), listPendingAuthorApplications()])
      .then(([a, p]) => {
        setAuthors(a)
        setPending(p)
      })
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load authors'))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const run = async (id: string, fn: () => Promise<void>) => {
    setActionError(null)
    setBusyId(id)
    try {
      await fn()
      load()
    } catch (e) {
      setActionError(e instanceof Error ? e.message : 'Action failed')
    } finally {
      setBusyId(null)
    }
  }

  return (
    <AdminPage>
      <PageHeader
        title="Authors"
        description="authors table (0007) + profiles.role / author_id moderation (0008). No authors.status column — approve sets profiles.role = author."
      />

      {error ? <Alert tone="error">{error}</Alert> : null}
      {actionError ? <Alert tone="error">{actionError}</Alert> : null}

      <Alert tone="info" title="Moderation model">
        There is no <code className="text-xs">authors.status</code>. Approve promotes linked
        profiles to <code className="text-xs">role = author</code>; Suspend reverts to{' '}
        <code className="text-xs">reader</code> and clears <code className="text-xs">author_id</code>
        .
      </Alert>

      {loading ? (
        <LoadingSpinner />
      ) : (
        <>
          {pending.length > 0 ? (
            <Card className="mb-4">
              <CardHeader
                title="Pending author applications"
                subtitle="profiles.role = reader with author_id set (awaiting promotion)"
              />
              <div className="overflow-x-auto">
                <table className="w-full min-w-[560px] text-left text-sm">
                  <thead>
                    <tr className="border-b border-outline text-on-surface-muted">
                      <th className="px-5 py-3 font-medium">User</th>
                      <th className="px-5 py-3 font-medium">Author record</th>
                      <th className="px-5 py-3 font-medium">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pending.map((app) => (
                      <tr key={app.profile_id} className="border-b border-outline last:border-0">
                        <td className="px-5 py-3">
                          <p className="font-medium">{app.full_name ?? app.profile_id}</p>
                          <p className="font-mono text-xs text-on-surface-muted">{app.profile_id}</p>
                        </td>
                        <td className="px-5 py-3">{app.author_name}</td>
                        <td className="px-5 py-3">
                          <Button
                            variant="secondary"
                            className="!py-1 !text-xs"
                            disabled={busyId === app.profile_id}
                            onClick={() =>
                              void run(app.profile_id, () =>
                                approveAuthorPersona(app.author_id),
                              )
                            }
                          >
                            Approve
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          ) : null}

          <Card>
            <CardHeader title="Author catalogue" subtitle="From public.authors" />
            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] text-left text-sm">
                <thead>
                  <tr className="border-b border-outline text-on-surface-muted">
                    <th className="px-5 py-3 font-medium">Name</th>
                    <th className="px-5 py-3 font-medium">Bio</th>
                    <th className="px-5 py-3 font-medium">Books</th>
                    <th className="px-5 py-3 font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {authors.map((a) => (
                    <tr key={a.id} className="border-b border-outline last:border-0">
                      <td className="px-5 py-3 font-medium">{a.name}</td>
                      <td className="max-w-md truncate px-5 py-3 text-on-surface-muted">
                        {a.bio ?? '—'}
                      </td>
                      <td className="px-5 py-3 tabular-nums">
                        <Badge>{a.book_count}</Badge>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex flex-wrap gap-2">
                          <Button
                            variant="secondary"
                            className="!py-1 !text-xs"
                            disabled={busyId === a.id}
                            onClick={() => void run(a.id, () => approveAuthorPersona(a.id))}
                          >
                            Approve persona
                          </Button>
                          <Button
                            variant="ghost"
                            className="!py-1 !text-xs"
                            disabled={busyId === a.id}
                            onClick={() => void run(a.id, () => suspendAuthorPersona(a.id))}
                          >
                            Suspend
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {authors.length === 0 ? (
                <CardBody>
                  <p className="text-sm text-on-surface-muted">No authors yet.</p>
                </CardBody>
              ) : null}
            </div>
          </Card>
        </>
      )}
    </AdminPage>
  )
}
