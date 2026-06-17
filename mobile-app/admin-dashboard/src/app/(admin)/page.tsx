'use client'

import { useEffect, useState } from 'react'
import { Card } from '@/components/ui/card'
import { listBooks } from '@/services/books'
import { listProfilesForAdmin } from '@/services/profiles'
import { listSubscriptions } from '@/services/subscriptions'

export default function DashboardPage() {
  const [stats, setStats] = useState({ books: 0, users: 0, premium: 0 })

  useEffect(() => {
    void (async () => {
      try {
        const [books, users, subs] = await Promise.all([
          listBooks(),
          listProfilesForAdmin(),
          listSubscriptions(),
        ])
        setStats({
          books: books.length,
          users: users.length,
          premium: subs.filter((s) => s.plan === 'premium').length,
        })
      } catch {
        /* dashboard is best-effort */
      }
    })()
  }, [])

  return (
    <div>
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      <p className="mt-1 text-sm text-slate-500">Akuko operations overview</p>
      <div className="mt-6 grid gap-4 sm:grid-cols-3">
        {[
          { label: 'Books', value: stats.books },
          { label: 'Users', value: stats.users },
          { label: 'Premium subs', value: stats.premium },
        ].map((s) => (
          <Card key={s.label} className="p-5">
            <p className="text-sm text-slate-500">{s.label}</p>
            <p className="mt-1 text-3xl font-semibold">{s.value}</p>
          </Card>
        ))}
      </div>
    </div>
  )
}
