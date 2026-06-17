import { useEffect, useState } from 'react'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { Alert } from '@/components/ui/Alert'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import { listAnalyticsEvents } from '@/services/analytics'
import type { AnalyticsEvent } from '@/types/database'

export function AnalyticsPage() {
  const [events, setEvents] = useState<AnalyticsEvent[]>([])
  const [tableMissing, setTableMissing] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    listAnalyticsEvents(50)
      .then(({ events: rows, tableMissing: missing }) => {
        setEvents(rows)
        setTableMissing(missing)
      })
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load analytics'))
      .finally(() => setLoading(false))
  }, [])

  return (
    <AdminPage>
      <PageHeader
        title="Analytics"
        description="Recent rows from public.analytics_events (admin read, migration 0008)."
      />

      {tableMissing ? (
        <Alert tone="warning" title="Requires 0008 deployed">
          The <code className="text-xs">analytics_events</code> table was not found. Run{' '}
          <code className="text-xs">supabase db push</code> with migrations 0007 + 0008 applied.
        </Alert>
      ) : null}

      {error ? <Alert tone="error">{error}</Alert> : null}

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardBody>
            <div className="flex h-48 items-center justify-center rounded-lg border border-dashed border-outline bg-surface text-sm text-on-surface-muted">
              Daily active readers (chart — Phase 2)
            </div>
          </CardBody>
        </Card>
        <Card>
          <CardBody>
            <div className="flex h-48 items-center justify-center rounded-lg border border-dashed border-outline bg-surface text-sm text-on-surface-muted">
              Revenue trend (chart — Phase 2)
            </div>
          </CardBody>
        </Card>
      </div>

      <Card className="mt-4">
        <CardHeader title="Recent events" subtitle="Last 50 rows" />
        {loading ? (
          <LoadingSpinner />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead>
                <tr className="border-b border-outline text-on-surface-muted">
                  <th className="px-5 py-3 font-medium">Type</th>
                  <th className="px-5 py-3 font-medium">User</th>
                  <th className="px-5 py-3 font-medium">Book</th>
                  <th className="px-5 py-3 font-medium">When</th>
                </tr>
              </thead>
              <tbody>
                {events.map((ev) => (
                  <tr key={ev.id} className="border-b border-outline last:border-0">
                    <td className="px-5 py-3 font-medium">{ev.event_type}</td>
                    <td className="px-5 py-3 font-mono text-xs text-on-surface-muted">
                      {ev.user_id ?? '—'}
                    </td>
                    <td className="px-5 py-3 font-mono text-xs text-on-surface-muted">
                      {ev.book_id ?? '—'}
                    </td>
                    <td className="px-5 py-3 text-on-surface-muted">
                      {new Date(ev.created_at).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!tableMissing && events.length === 0 ? (
              <CardBody>
                <p className="text-sm text-on-surface-muted">No events recorded yet.</p>
              </CardBody>
            ) : null}
          </div>
        )}
      </Card>
    </AdminPage>
  )
}
