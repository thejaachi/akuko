import { useEffect, useState } from 'react'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Alert } from '@/components/ui/Alert'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import { listPaymentTransactions } from '@/services/payments'
import { listSubscriptions } from '@/services/subscriptions'
import type { PaymentTransaction, Subscription } from '@/types/database'

export function PaymentsPage() {
  const [subs, setSubs] = useState<Subscription[]>([])
  const [txns, setTxns] = useState<PaymentTransaction[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    Promise.all([listSubscriptions(), listPaymentTransactions(50)])
      .then(([subResult, transactions]) => {
        setSubs(subResult.rows)
        setTxns(transactions)
      })
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load payments data'))
      .finally(() => setLoading(false))
  }, [])

  return (
    <AdminPage>
      <PageHeader
        title="Payments"
        description="Paystack ledger (payment_transactions) and subscriptions (0006)."
      />

      <Alert tone="warning" title="Subscriptions RLS">
        Migration 0008 does not add an admin SELECT policy on{' '}
        <code className="text-xs">subscriptions</code>. You may only see rows your admin user owns.
        Use Supabase Studio (service role) for full billing ops until an admin policy is added.
      </Alert>

      {error ? <Alert tone="error">{error}</Alert> : null}

      <Card className="mt-4">
        <CardHeader
          title="Payment transactions"
          subtitle="public.payment_transactions — admin read via RLS (0008)"
        />
        {loading ? (
          <LoadingSpinner />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead>
                <tr className="border-b border-outline text-on-surface-muted">
                  <th className="px-5 py-3 font-medium">Reference</th>
                  <th className="px-5 py-3 font-medium">User</th>
                  <th className="px-5 py-3 font-medium">Amount</th>
                  <th className="px-5 py-3 font-medium">Status</th>
                  <th className="px-5 py-3 font-medium">Created</th>
                </tr>
              </thead>
              <tbody>
                {txns.map((t) => (
                  <tr key={t.id} className="border-b border-outline last:border-0">
                    <td className="px-5 py-3 font-mono text-xs">{t.reference}</td>
                    <td className="px-5 py-3 font-mono text-xs">{t.user_id}</td>
                    <td className="px-5 py-3 tabular-nums">
                      {Number(t.amount).toFixed(2)} {t.currency}
                    </td>
                    <td className="px-5 py-3">
                      <Badge tone={t.status === 'success' ? 'success' : 'default'}>
                        {t.status}
                      </Badge>
                    </td>
                    <td className="px-5 py-3 text-on-surface-muted">
                      {new Date(t.created_at).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {txns.length === 0 ? (
              <CardBody>
                <p className="text-sm text-on-surface-muted">
                  No transactions visible. Apply migration 0008 or wait for Paystack webhooks to
                  insert rows.
                </p>
              </CardBody>
            ) : null}
          </div>
        )}
      </Card>

      <Card className="mt-4">
        <CardHeader title="Subscriptions" subtitle="Canonical table from 0006_subscriptions.sql" />
        {loading ? (
          <LoadingSpinner />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] text-left text-sm">
              <thead>
                <tr className="border-b border-outline text-on-surface-muted">
                  <th className="px-5 py-3 font-medium">User</th>
                  <th className="px-5 py-3 font-medium">Plan</th>
                  <th className="px-5 py-3 font-medium">Status</th>
                  <th className="px-5 py-3 font-medium">Period end</th>
                </tr>
              </thead>
              <tbody>
                {subs.map((s) => (
                  <tr key={s.id} className="border-b border-outline last:border-0">
                    <td className="px-5 py-3 font-mono text-xs">{s.user_id}</td>
                    <td className="px-5 py-3">
                      <Badge tone={s.plan === 'premium' ? 'primary' : 'default'}>{s.plan}</Badge>
                    </td>
                    <td className="px-5 py-3">{s.status}</td>
                    <td className="px-5 py-3 text-on-surface-muted">
                      {s.current_period_end
                        ? new Date(s.current_period_end).toLocaleString()
                        : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {subs.length === 0 ? (
              <CardBody>
                <p className="text-sm text-on-surface-muted">No subscription rows visible.</p>
              </CardBody>
            ) : null}
          </div>
        )}
      </Card>
    </AdminPage>
  )
}
