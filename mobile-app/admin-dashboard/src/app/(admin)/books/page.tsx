'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Card } from '@/components/ui/card'
import { approveBook, listBooks, rejectBook, setBookFeatured } from '@/services/books'
import type { Book } from '@/types/database'

export default function BooksPage() {
  const [books, setBooks] = useState<Book[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function reload() {
    setLoading(true)
    try {
      setBooks(await listBooks())
      setError(null)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load books')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void reload()
  }, [])

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Books</h1>
          <p className="text-sm text-slate-500">Approve, reject, and feature books</p>
        </div>
        <Link
          href="/books/upload"
          className="rounded bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700"
        >
          Upload
        </Link>
      </div>
      {error ? <p className="mt-4 text-sm text-red-600">{error}</p> : null}
      <Card className="mt-6 overflow-x-auto">
        {loading ? (
          <p className="p-6 text-slate-500">Loading…</p>
        ) : (
          <table className="w-full min-w-[720px] text-left text-sm">
            <thead>
              <tr className="border-b border-slate-200 text-slate-500">
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Featured</th>
                <th className="px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody>
              {books.map((b) => (
                <tr key={b.id} className="border-b border-slate-100">
                  <td className="px-4 py-3">{b.title}</td>
                  <td className="px-4 py-3">{b.status}</td>
                  <td className="px-4 py-3">
                    <button
                      type="button"
                      className="text-blue-600"
                      onClick={() =>
                        void setBookFeatured(b.id, !b.is_featured).then(reload)
                      }
                    >
                      {b.is_featured ? 'Yes' : 'No'}
                    </button>
                  </td>
                  <td className="px-4 py-3 space-x-2">
                    {b.status === 'pending_review' ? (
                      <>
                        <button
                          type="button"
                          className="text-green-700"
                          onClick={() => void approveBook(b.id).then(reload)}
                        >
                          Approve
                        </button>
                        <button
                          type="button"
                          className="text-red-600"
                          onClick={() => void rejectBook(b.id, 'Rejected by admin').then(reload)}
                        >
                          Reject
                        </button>
                      </>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  )
}
