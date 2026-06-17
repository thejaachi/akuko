import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from '@/contexts/AuthContext'
import { AdminLayout } from '@/components/layout/AdminLayout'
import { ProtectedRoute } from '@/routes/ProtectedRoute'
import { LoginPage } from '@/pages/LoginPage'
import { DashboardPage } from '@/pages/DashboardPage'
import { BooksPage } from '@/pages/BooksPage'
import { BookUploadPage } from '@/pages/BookUploadPage'
import { AuthorsPage } from '@/pages/AuthorsPage'
import { PublishersPage } from '@/pages/PublishersPage'
import { UsersPage } from '@/pages/UsersPage'
import { PaymentsPage } from '@/pages/PaymentsPage'
import { AnalyticsPage } from '@/pages/AnalyticsPage'
import { SettingsPage } from '@/pages/SettingsPage'

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route element={<ProtectedRoute />}>
            <Route element={<AdminLayout />}>
              <Route index element={<DashboardPage />} />
              <Route path="books" element={<BooksPage />} />
              <Route path="books/upload" element={<BookUploadPage />} />
              <Route path="authors" element={<AuthorsPage />} />
              <Route path="publishers" element={<PublishersPage />} />
              <Route path="users" element={<UsersPage />} />
              <Route path="payments" element={<PaymentsPage />} />
              <Route path="analytics" element={<AnalyticsPage />} />
              <Route path="settings" element={<SettingsPage />} />
            </Route>
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
