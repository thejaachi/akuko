'use client'

import { useEffect, useState } from 'react'
import { Card } from '@/components/ui/card'
import { listAnalyticsEvents } from '@/services/analytics'
import type { AnalyticsEvent } from '@/types/database'

export default function AnalyticsPage() {
  const [events, setEvents] = useState<AnalyticsEvent[]>([])
  const [tableMissing, setTableMissing] = useState(false)

  useEffect(() => {
    void listAnalyticsEvents().then(({ events: ev, tableMissing: missing }) => {
      setEvents(ev)
      setTableMissing(missing)
    })
  }, [])

  return (
    <div>
      <h1 className="text-2xl font-semibold">Analytics</h1>
      <p className="text-sm text-slate-500">analytics_events + revenue placeholders (wire Paystack reports later)</p>
      <div className="mt-4 grid gap-4 sm:grid-cols-2">
        <Card className="p-4">
          <p className="text-sm text-slate-500">MRR (placeholder)</p>
          <p className="text-2xl font-semibold">—</p>
        </Card>
        <Card className="p-4">
          <p className="text-sm text-slate-500">Events (last 50)</p>
          <p className="text-2xl font-semibold">{events.length}</p>
        </Card>
      </div>
      {tableMissing ? (
        <p className="mt-4 text-sm text-amber-700">analytics_events table not deployed (0008).</p>
      ) : null}
      <Card className="mt-6 overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead>
            <tr className="border-b text-slate-500">
              <th className="px-4 py-2">Type</th>
              <th className="px-4 py-2">User</th>
              <th className="px-4 py-2">When</th>
            </tr>
          </thead>
          <tbody>
            {events.map((e) => (
              <tr key={e.id} className="border-b border-slate-100">
                <td className="px-4 py-2">{e.event_type}</td>
                <td className="px-4 py-2 font-mono text-xs">{e.user_id ?? '—'}</td>
                <td className="px-4 py-2">{new Date(e.created_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  )
}
