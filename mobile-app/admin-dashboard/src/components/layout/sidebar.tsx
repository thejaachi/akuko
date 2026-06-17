'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  BarChart3,
  BookOpen,
  Flag,
  LayoutDashboard,
  LogOut,
  Tags,
  Users,
  Wallet,
} from 'lucide-react'
import { useAuth } from '@/contexts/auth-provider'

const nav = [
  { href: '/', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/books', label: 'Books', icon: BookOpen },
  { href: '/books/upload', label: 'Upload', icon: BookOpen },
  { href: '/users', label: 'Users', icon: Users },
  { href: '/subscriptions', label: 'Subscriptions', icon: Wallet },
  { href: '/analytics', label: 'Analytics', icon: BarChart3 },
  { href: '/categories', label: 'Categories', icon: Tags },
  { href: '/authors', label: 'Authors', icon: BookOpen, stub: true },
  { href: '/publishers', label: 'Publishers', icon: BookOpen, stub: true },
  { href: '/royalties', label: 'Royalties', icon: Wallet, stub: true },
  { href: '/withdrawals', label: 'Withdrawals', icon: Wallet, stub: true },
  { href: '/feature-flags', label: 'Feature flags', icon: Flag },
]

export function Sidebar() {
  const pathname = usePathname()
  const { signOut, user } = useAuth()

  return (
    <aside className="flex h-full w-56 flex-col border-r border-slate-200 bg-white">
      <div className="border-b border-slate-200 px-4 py-5">
        <p className="text-lg font-semibold text-slate-900">Akuko Admin</p>
        <p className="truncate text-xs text-slate-500">{user?.email}</p>
      </div>
      <nav className="flex-1 space-y-0.5 overflow-y-auto p-2">
        {nav.map(({ href, label, icon: Icon, stub }) => {
          const active = pathname === href || (href !== '/' && pathname.startsWith(href))
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-2 rounded-md px-3 py-2 text-sm ${
                active ? 'bg-blue-50 text-blue-700' : 'text-slate-700 hover:bg-slate-50'
              }`}
            >
              <Icon className="h-4 w-4 shrink-0" />
              <span>{label}</span>
              {stub ? (
                <span className="ml-auto rounded bg-slate-100 px-1.5 text-[10px] text-slate-500">
                  soon
                </span>
              ) : null}
            </Link>
          )
        })}
      </nav>
      <button
        type="button"
        onClick={() => void signOut()}
        className="m-2 flex items-center gap-2 rounded-md px-3 py-2 text-sm text-slate-600 hover:bg-slate-50"
      >
        <LogOut className="h-4 w-4" />
        Sign out
      </button>
    </aside>
  )
}
