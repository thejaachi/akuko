import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Button } from '@/components/ui/Button'
import { Card, CardBody } from '@/components/ui/Card'
import { Alert } from '@/components/ui/Alert'
import { insertBook, listCategories } from '@/services/books'
import { uploadBookCover, uploadBookFile, inferFileType } from '@/services/storage'
import type { Category } from '@/types/database'

export function BookUploadPage() {
  const navigate = useNavigate()
  const [categories, setCategories] = useState<Category[]>([])
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [metadataOnly, setMetadataOnly] = useState(false)
  const [fastPublish, setFastPublish] = useState(false)

  const [title, setTitle] = useState('')
  const [author, setAuthor] = useState('')
  const [description, setDescription] = useState('')
  const [categoryId, setCategoryId] = useState('')
  const [coverUrl, setCoverUrl] = useState('')
  const [fileUrl, setFileUrl] = useState('')
  const [isPremium, setIsPremium] = useState(false)
  const [coverFile, setCoverFile] = useState<File | null>(null)
  const [bookFile, setBookFile] = useState<File | null>(null)

  useEffect(() => {
    listCategories()
      .then(setCategories)
      .catch(() => setCategories([]))
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setSuccess(null)
    setSubmitting(true)

    try {
      let resolvedCover = coverUrl.trim() || undefined
      let resolvedFile = fileUrl.trim() || undefined
      let fileType = resolvedFile ? inferFileType(resolvedFile) : null
      let fileSize: number | undefined

      if (!metadataOnly) {
        if (coverFile) resolvedCover = await uploadBookCover(coverFile)
        if (bookFile) {
          const uploaded = await uploadBookFile(bookFile)
          resolvedFile = uploaded.path
          fileSize = uploaded.size
          fileType = inferFileType(bookFile.name)
        }
      }

      if (!resolvedFile && !metadataOnly) {
        setError(
          'Provide a book file upload, a file path, or enable metadata-only mode. If Storage upload fails, upload files via Supabase Studio (service role) and paste paths here.',
        )
        setSubmitting(false)
        return
      }

      const book = await insertBook({
        title: title.trim(),
        author: author.trim(),
        description: description.trim() || undefined,
        category_id: categoryId || undefined,
        cover_url: resolvedCover,
        file_url: resolvedFile,
        file_type: fileType ?? undefined,
        file_size_bytes: fileSize,
        is_premium: isPremium,
        status: fastPublish ? 'published' : 'pending_review',
      })

      setSuccess(
        fastPublish
          ? `Book published immediately (status: ${book.status}).`
          : `Book submitted for review (status: ${book.status}). Approve it from the Books list.`,
      )
      setTimeout(() => navigate('/books'), 1500)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <AdminPage>
      <PageHeader
        title="Upload book"
        description="Uploads to Storage buckets book-covers and book-files (admin RLS), then inserts a books row."
        action={
          <Link to="/books">
            <Button variant="secondary">Back to list</Button>
          </Link>
        }
      />

      <Alert tone="info" title="Moderation workflow">
        New uploads default to <code className="text-xs">pending_review</code>. Use fast-publish
        only when you intend to skip the review queue. Approve or reject from the Books list.
      </Alert>

      <Card className="mt-4">
        <CardBody>
          <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4">
            {error ? <Alert tone="error">{error}</Alert> : null}
            {success ? <Alert tone="success">{success}</Alert> : null}

            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={metadataOnly}
                onChange={(e) => setMetadataOnly(e.target.checked)}
              />
              Metadata only (skip Storage upload — use manual paths below)
            </label>

            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={fastPublish}
                onChange={(e) => setFastPublish(e.target.checked)}
              />
              Fast-publish (set status to published immediately — skips review queue)
            </label>

            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="mb-1 block text-sm font-medium">Title *</label>
                <input
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Author *</label>
                <input
                  required
                  value={author}
                  onChange={(e) => setAuthor(e.target.value)}
                  className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
                />
              </div>
            </div>

            <div>
              <label className="mb-1 block text-sm font-medium">Description</label>
              <textarea
                rows={3}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
              />
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="mb-1 block text-sm font-medium">Category</label>
                <select
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
                >
                  <option value="">— None —</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>
              <label className="flex items-end gap-2 pb-2 text-sm">
                <input
                  type="checkbox"
                  checked={isPremium}
                  onChange={(e) => setIsPremium(e.target.checked)}
                />
                Premium book
              </label>
            </div>

            {!metadataOnly ? (
              <div className="grid gap-4 md:grid-cols-2">
                <div>
                  <label className="mb-1 block text-sm font-medium">Cover image</label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) => setCoverFile(e.target.files?.[0] ?? null)}
                    className="w-full text-sm"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium">Book file (EPUB/PDF)</label>
                  <input
                    type="file"
                    accept=".epub,.pdf,application/epub+zip,application/pdf"
                    onChange={(e) => setBookFile(e.target.files?.[0] ?? null)}
                    className="w-full text-sm"
                  />
                </div>
              </div>
            ) : null}

            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="mb-1 block text-sm font-medium">Cover path override</label>
                <input
                  placeholder="book-covers/my-cover.jpg"
                  value={coverUrl}
                  onChange={(e) => setCoverUrl(e.target.value)}
                  className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">File path override</label>
                <input
                  placeholder="book-files/my-book.epub"
                  value={fileUrl}
                  onChange={(e) => setFileUrl(e.target.value)}
                  className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
                />
              </div>
            </div>

            <Button type="submit" loading={submitting}>
              Create book
            </Button>
          </form>
        </CardBody>
      </Card>
    </AdminPage>
  )
}
