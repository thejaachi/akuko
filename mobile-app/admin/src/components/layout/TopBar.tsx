import { LogOut, Menu } from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import { Button } from '@/components/ui/Button'

export function TopBar({ onMenuClick }: { onMenuClick: () => void }) {
  const { user, signOut } = useAuth()

  return (
    <header className="sticky top-0 z-30 flex h-14 items-center justify-between border-b border-outline bg-surface-elevated/95 px-4 backdrop-blur">
      <button
        type="button"
        className="rounded-lg p-2 text-on-surface-muted hover:bg-black/5 lg:hidden"
        onClick={onMenuClick}
        aria-label="Open menu"
      >
        <Menu className="h-5 w-5" />
      </button>
      <div className="hidden text-sm text-on-surface-muted lg:block">
        Operations console
      </div>
      <div className="flex items-center gap-3">
        <span className="hidden max-w-[200px] truncate text-sm text-on-surface-muted sm:inline">
          {user?.email}
        </span>
        <Button variant="ghost" onClick={() => void signOut()} className="!px-2">
          <LogOut className="h-4 w-4" />
          <span className="hidden sm:inline">Sign out</span>
        </Button>
      </div>
    </header>
  )
}
