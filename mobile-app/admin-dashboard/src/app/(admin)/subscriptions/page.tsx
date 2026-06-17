'use client'

import { useEffect, useState } from 'react'
import { Card } from '@/components/ui/card'
import { listPaymentTransactions } from '@/services/payments'
import { listSubscriptions } from '@/services/subscriptions'
import type { PaymentTransaction, Subscription } from '@/types/database'

export default function SubscriptionsPage() {
  const [subs, setSubs] = useState<Subscription[]>([])
  const [txns, setTxns] = useState<PaymentTransaction[]>([])

  useEffect(() => {
    void (async () => {
      try {
        setSubs(await listSubscriptions())
      } catch {
        setSubs([])
      }
      setTxns(await listPaymentTransactions())
    })()
  }, [])

  return (
    <div>
      <h1 className="text-2xl font-semibold">Subscriptions & payments</h1>
      <p className="text-sm text-slate-500">
        subscriptions (0006) + payment_transactions ledger (0008). Admin read via RLS.
      </p>
      <Card className="mt-6 overflow-x-auto">
        <h2 className="border-b px-4 py-3 font-medium">Subscriptions</h2>
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b text-slate-500">
              <th className="px-4 py-2">User</th>
              <th className="px-4 py-2">Plan</th>
              <th className="px-4 py-2">Status</th>
            </tr>
          </thead>
          <tbody>
            {subs.map((s) => (
              <tr key={s.id} className="border-b border-slate-100">
                <td className="px-4 py-2 font-mono text-xs">{s.user_id}</td>
                <td className="px-4 py-2">{s.plan}</td>
                <td className="px-4 py-2">{s.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
      <Card className="mt-6 overflow-x-auto">
        <h2 className="border-b px-4 py-3 font-medium">Payment transactions</h2>
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b text-slate-500">
              <th className="px-4 py-2">Reference</th>
              <th className="px-4 py-2">Amount</th>
              <th className="px-4 py-2">Status</th>
              <th className="px-4 py-2">Event</th>
            </tr>
          </thead>
          <tbody>
            {txns.map((t) => (
              <tr key={t.id} className="border-b border-slate-100">
                <td className="px-4 py-2 font-mono text-xs">{t.reference}</td>
                <td className="px-4 py-2">
                  {t.currency} {t.amount}
                </td>
                <td className="px-4 py-2">{t.status}</td>
                <td className="px-4 py-2">{t.paystack_event ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  )
}
