import { useEffect, useState } from 'react'
import { BookOpen, Crown, PenLine, Users } from 'lucide-react'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Card, CardBody } from '@/components/ui/Card'
import { Alert } from '@/components/ui/Alert'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import { fetchDashboardStats, type DashboardStats } from '@/services/dashboard'

function KpiCard({
  label,
  value,
  icon: Icon,
}: {
  label: string
  value: string
  icon: React.ComponentType<{ className?: string }>
}) {
  return (
    <Card>
      <CardBody className="flex items-start justify-between">
        <div>
          <p className="text-sm text-on-surface-muted">{label}</p>
          <p className="mt-2 text-3xl font-medium tabular-nums text-on-surface">{value}</p>
        </div>
        <div className="rounded-lg bg-primary-50 p-2 text-primary-600">
          <Icon className="h-5 w-5" />
        </div>
      </CardBody>
    </Card>
  )
}

export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchDashboardStats()
      .then(setStats)
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load stats'))
      .finally(() => setLoading(false))
  }, [])

  const fmt = (n: number | null) => (n === null ? '—' : n.toLocaleString())

  return (
    <AdminPage>
      <PageHeader
        title="Dashboard"
        description="Overview of catalogue and users. Counts come from Supabase when RLS allows."
      />

      {error ? <Alert tone="error">{error}</Alert> : null}

      {loading ? (
        <LoadingSpinner />
      ) : stats ? (
        <>
          {stats.errors.length > 0 ? (
            <Alert tone="warning" title="Partial data" className="mb-4">
              <ul className="list-inside list-disc">
                {stats.errors.map((e) => (
                  <li key={e}>{e}</li>
                ))}
              </ul>
            </Alert>
          ) : null}
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <KpiCard label="Books" value={fmt(stats.books)} icon={BookOpen} />
            <KpiCard label="Authors" value={fmt(stats.authors)} icon={PenLine} />
            <KpiCard label="Users" value={fmt(stats.users)} icon={Users} />
            <KpiCard
              label="Premium subs"
              value={fmt(stats.premiumSubscriptions)}
              icon={Crown}
            />
          </div>
          <Card className="mt-6">
            <CardBody>
              <p className="text-sm text-on-surface-muted">
                Premium subscription count may be understated until migration 0008 adds an
                admin SELECT policy on <code className="text-xs">subscriptions</code>. Payment
                transactions and analytics events are Phase 2+.
              </p>
            </CardBody>
          </Card>
        </>
      ) : null}
    </AdminPage>
  )
}
