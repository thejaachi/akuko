import type { Metadata } from 'next'
import './globals.css'
import { AuthProvider } from '@/contexts/auth-provider'

export const metadata: Metadata = {
  title: 'Akuko Admin',
  description: 'Akuko operations console',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  )
}
