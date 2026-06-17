'use client'

import { useRouter } from 'next/navigation'
import { useEffect, type ReactNode } from 'react'
import { useAuth } from '@/contexts/auth-provider'
import { Sidebar } from './sidebar'

export function AdminGuard({ children }: { children: ReactNode }) {
  const { loading, isAdmin, configured, session } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!configured) return
    if (!loading && !session) router.replace('/login')
    if (!loading && session && !isAdmin) router.replace('/login')
  }, [loading, session, isAdmin, configured, router])

  if (!configured) {
    return (
      <div className="flex min-h-screen items-center justify-center p-8">
        <p className="max-w-md text-center text-slate-600">
          Supabase is not configured. Copy <code>.env.example</code> to{' '}
          <code>.env.local</code> and set NEXT_PUBLIC_SUPABASE_URL and
          NEXT_PUBLIC_SUPABASE_ANON_KEY.
        </p>
      </div>
    )
  }

  if (loading || !session || !isAdmin) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-slate-500">Loading…</p>
      </div>
    )
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 overflow-auto bg-slate-50 p-6">{children}</main>
    </div>
  )
}
