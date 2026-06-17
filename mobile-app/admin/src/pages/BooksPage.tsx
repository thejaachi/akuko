import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Button } from '@/components/ui/Button'
import { Card, CardBody } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Alert } from '@/components/ui/Alert'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import { Modal } from '@/components/ui/Modal'
import {
  approveBook,
  formatBookStatus,
  listBooks,
  rejectBook,
  setBookStatus,
  statusBadgeTone,
  type BookStatusFilter,
} from '@/services/books'
import type { Book, BookStatus } from '@/types/database'

const TABS: { id: BookStatusFilter; label: string }[] = [
  { id: 'all', label: 'All' },
  { id: 'pending_review', label: 'Pending review' },
  { id: 'published', label: 'Published' },
  { id: 'rejected', label: 'Rejected' },
]

export function BooksPage() {
  const [tab, setTab] = useState<BookStatusFilter>('all')
  const [books, setBooks] = useState<Book[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [rejectTarget, setRejectTarget] = useState<Book | null>(null)
  const [rejectReason, setRejectReason] = useState('')

  const load = useCallback(() => {
    setLoading(true)
    setError(null)
    listBooks(tab)
      .then(setBooks)
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load books'))
      .finally(() => setLoading(false))
  }, [tab])

  useEffect(() => {
    load()
  }, [load])

  const runAction = async (id: string, fn: () => Promise<void>) => {
    setActionError(null)
    setBusyId(id)
    try {
      await fn()
      load()
    } catch (e) {
      setActionError(e instanceof Error ? e.message : 'Action failed')
    } finally {
      setBusyId(null)
    }
  }

  const confirmReject = async () => {
    if (!rejectTarget) return
    if (!rejectReason.trim()) {
      setActionError('Rejection reason is required.')
      return
    }
    await runAction(rejectTarget.id, () => rejectBook(rejectTarget.id, rejectReason))
    setRejectTarget(null)
    setRejectReason('')
  }

  return (
    <AdminPage>
      <PageHeader
        title="Books"
        description="Catalogue workflow: pending_review → published or rejected (migration 0008)."
        action={
          <Link to="/books/upload">
            <Button>
              <Plus className="h-4 w-4" />
              Upload book
            </Button>
          </Link>
        }
      />

      {error ? <Alert tone="error">{error}</Alert> : null}
      {actionError ? <Alert tone="error">{actionError}</Alert> : null}

      <div className="mb-4 flex flex-wrap gap-2">
        {TABS.map((t) => (
          <Button
            key={t.id}
            variant={tab === t.id ? 'primary' : 'secondary'}
            className="!py-1.5 !text-sm"
            onClick={() => setTab(t.id)}
          >
            {t.label}
          </Button>
        ))}
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[900px] text-left text-sm">
              <thead>
                <tr className="border-b border-outline text-on-surface-muted">
                  <th className="px-5 py-3 font-medium">Title</th>
                  <th className="px-5 py-3 font-medium">Author</th>
                  <th className="px-5 py-3 font-medium">Status</th>
                  <th className="px-5 py-3 font-medium">Type</th>
                  <th className="px-5 py-3 font-medium">Flags</th>
                  <th className="px-5 py-3 font-medium">Price</th>
                  <th className="px-5 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {books.map((book) => {
                  const status = (book.status ?? 'published') as BookStatus
                  const busy = busyId === book.id
                  return (
                    <tr key={book.id} className="border-b border-outline last:border-0">
                      <td className="px-5 py-3 font-medium text-on-surface">
                        {book.title}
                        {book.rejection_reason ? (
                          <p className="mt-1 text-xs text-error" title={book.rejection_reason}>
                            {book.rejection_reason}
                          </p>
                        ) : null}
                      </td>
                      <td className="px-5 py-3 text-on-surface-muted">{book.author}</td>
                      <td className="px-5 py-3">
                        <Badge tone={statusBadgeTone(status)}>{formatBookStatus(status)}</Badge>
                      </td>
                      <td className="px-5 py-3 uppercase text-on-surface-muted">
                        {book.file_type ?? '—'}
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex flex-wrap gap-1">
                          {book.is_premium ? <Badge tone="primary">Premium</Badge> : null}
                          {book.is_featured ? <Badge>Featured</Badge> : null}
                          {book.is_new_release ? <Badge tone="success">New</Badge> : null}
                        </div>
                      </td>
                      <td className="px-5 py-3 tabular-nums">{Number(book.price).toFixed(2)}</td>
                      <td className="px-5 py-3">
                        <div className="flex flex-wrap gap-1">
                          {status === 'pending_review' || status === 'draft' ? (
                            <Button
                              variant="secondary"
                              className="!py-1 !text-xs"
                              disabled={busy}
                              onClick={() => void runAction(book.id, () => approveBook(book.id))}
                            >
                              Approve
                            </Button>
                          ) : null}
                          {status === 'pending_review' || status === 'published' ? (
                            <Button
                              variant="ghost"
                              className="!py-1 !text-xs"
                              disabled={busy}
                              onClick={() => {
                                setRejectTarget(book)
                                setRejectReason('')
                              }}
                            >
                              Reject
                            </Button>
                          ) : null}
                          {status !== 'pending_review' ? (
                            <Button
                              variant="ghost"
                              className="!py-1 !text-xs"
                              disabled={busy}
                              onClick={() =>
                                void runAction(book.id, () =>
                                  setBookStatus(book.id, 'pending_review'),
                                )
                              }
                            >
                              Re-queue
                            </Button>
                          ) : null}
                          {status !== 'archived' ? (
                            <Button
                              variant="ghost"
                              className="!py-1 !text-xs"
                              disabled={busy}
                              onClick={() =>
                                void runAction(book.id, () => setBookStatus(book.id, 'archived'))
                              }
                            >
                              Archive
                            </Button>
                          ) : null}
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
            {books.length === 0 ? (
              <CardBody>
                <p className="text-sm text-on-surface-muted">No books in this filter.</p>
              </CardBody>
            ) : null}
          </div>
        </Card>
      )}

      <Modal
        open={rejectTarget !== null}
        title="Reject book"
        onClose={() => setRejectTarget(null)}
        footer={
          <div className="flex justify-end gap-2">
            <Button variant="secondary" onClick={() => setRejectTarget(null)}>
              Cancel
            </Button>
            <Button
              variant="primary"
              loading={busyId === rejectTarget?.id}
              onClick={() => void confirmReject()}
            >
              Reject
            </Button>
          </div>
        }
      >
        <p className="mb-3 text-sm text-on-surface-muted">
          {rejectTarget ? `Reject “${rejectTarget.title}” and hide from the public catalogue.` : ''}
        </p>
        <label className="mb-1 block text-sm font-medium">Rejection reason *</label>
        <textarea
          rows={3}
          value={rejectReason}
          onChange={(e) => setRejectReason(e.target.value)}
          className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
          placeholder="Explain why this title was rejected…"
        />
      </Modal>
    </AdminPage>
  )
}
