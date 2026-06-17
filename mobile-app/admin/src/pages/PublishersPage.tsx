import { useCallback, useEffect, useState } from 'react'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Card, CardBody } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { Alert } from '@/components/ui/Alert'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import { listPublishers, setPublisherStatus } from '@/services/publishers'
import type { PublisherStatus, PublisherWithMemberCount } from '@/types/database'

function statusTone(status: PublisherStatus): 'default' | 'success' | 'warning' | 'error' {
  switch (status) {
    case 'approved':
      return 'success'
    case 'pending':
      return 'warning'
    case 'suspended':
      return 'error'
    default:
      return 'default'
  }
}

export function PublishersPage() {
  const [rows, setRows] = useState<PublisherWithMemberCount[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)

  const load = useCallback(() => {
    setLoading(true)
    setError(null)
    listPublishers()
      .then(setRows)
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load publishers'))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const run = async (id: string, status: PublisherStatus) => {
    setActionError(null)
    setBusyId(id)
    try {
      await setPublisherStatus(id, status)
      load()
    } catch (e) {
      setActionError(e instanceof Error ? e.message : 'Update failed')
    } finally {
      setBusyId(null)
    }
  }

  return (
    <AdminPage>
      <PageHeader
        title="Publishers"
        description="Publishing orgs from migration 0008 (publishers.status: pending | approved | suspended)."
      />

      {error ? <Alert tone="error">{error}</Alert> : null}
      {actionError ? <Alert tone="error">{actionError}</Alert> : null}

      {loading ? (
        <LoadingSpinner />
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead>
                <tr className="border-b border-outline text-on-surface-muted">
                  <th className="px-5 py-3 font-medium">Name</th>
                  <th className="px-5 py-3 font-medium">Slug</th>
                  <th className="px-5 py-3 font-medium">Status</th>
                  <th className="px-5 py-3 font-medium">Members</th>
                  <th className="px-5 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((p) => (
                  <tr key={p.id} className="border-b border-outline last:border-0">
                    <td className="px-5 py-3 font-medium">{p.name}</td>
                    <td className="px-5 py-3 font-mono text-xs text-on-surface-muted">{p.slug}</td>
                    <td className="px-5 py-3">
                      <Badge tone={statusTone(p.status)}>{p.status}</Badge>
                    </td>
                    <td className="px-5 py-3 tabular-nums">{p.member_count}</td>
                    <td className="px-5 py-3">
                      <div className="flex flex-wrap gap-2">
                        {p.status !== 'approved' ? (
                          <Button
                            variant="secondary"
                            className="!py-1 !text-xs"
                            disabled={busyId === p.id}
                            onClick={() => void run(p.id, 'approved')}
                          >
                            Approve
                          </Button>
                        ) : null}
                        {p.status !== 'suspended' ? (
                          <Button
                            variant="ghost"
                            className="!py-1 !text-xs"
                            disabled={busyId === p.id}
                            onClick={() => void run(p.id, 'suspended')}
                          >
                            Suspend
                          </Button>
                        ) : null}
                        {p.status === 'suspended' ? (
                          <Button
                            variant="ghost"
                            className="!py-1 !text-xs"
                            disabled={busyId === p.id}
                            onClick={() => void run(p.id, 'pending')}
                          >
                            Re-open
                          </Button>
                        ) : null}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {rows.length === 0 ? (
              <CardBody>
                <p className="text-sm text-on-surface-muted">
                  No publisher rows yet. Requires migration 0008 applied.
                </p>
              </CardBody>
            ) : null}
          </div>
        </Card>
      )}
    </AdminPage>
  )
}
