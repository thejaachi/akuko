import { NavLink } from 'react-router-dom'
import {
  BarChart3,
  BookOpen,
  CreditCard,
  LayoutDashboard,
  PenLine,
  Settings,
  Store,
  Users,
  X,
} from 'lucide-react'

const nav = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/books', label: 'Books', icon: BookOpen },
  { to: '/authors', label: 'Authors', icon: PenLine },
  { to: '/publishers', label: 'Publishers', icon: Store },
  { to: '/users', label: 'Users', icon: Users },
  { to: '/payments', label: 'Payments', icon: CreditCard },
  { to: '/analytics', label: 'Analytics', icon: BarChart3 },
  { to: '/settings', label: 'Settings', icon: Settings },
]

export function Sidebar({ open, onClose }: { open: boolean; onClose: () => void }) {
  return (
    <>
      <div
        className={`fixed inset-0 z-40 bg-black/40 transition-opacity lg:hidden ${open ? 'opacity-100' : 'pointer-events-none opacity-0'}`}
        onClick={onClose}
        aria-hidden={!open}
      />
      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-64 flex-col border-r border-outline bg-surface-elevated transition-transform lg:static lg:translate-x-0 ${open ? 'translate-x-0' : '-translate-x-full'}`}
      >
        <div className="flex h-14 items-center justify-between border-b border-outline px-4">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-600 text-sm font-bold text-white">
              A
            </div>
            <span className="font-medium text-on-surface">Akuko Admin</span>
          </div>
          <button
            type="button"
            className="rounded-lg p-1 text-on-surface-muted hover:bg-black/5 lg:hidden"
            onClick={onClose}
            aria-label="Close menu"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <nav className="flex-1 space-y-1 overflow-y-auto p-3">
          {nav.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              onClick={onClose}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-primary-50 text-primary-700'
                    : 'text-on-surface-muted hover:bg-black/5 hover:text-on-surface'
                }`
              }
            >
              <Icon className="h-5 w-5 shrink-0" />
              {label}
            </NavLink>
          ))}
        </nav>
        <p className="border-t border-outline px-4 py-3 text-xs text-on-surface-muted">
          Phase 1 · Supabase RLS
        </p>
      </aside>
    </>
  )
}
