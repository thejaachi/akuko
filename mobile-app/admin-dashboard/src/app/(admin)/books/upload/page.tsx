'use client'

import { FormEvent, useEffect, useState } from 'react'
import { insertBook, listCategories } from '@/services/books'
import { inferFileType, uploadBookCover, uploadBookFile } from '@/services/storage'
import type { Category } from '@/types/database'

export default function BookUploadPage() {
  const [categories, setCategories] = useState<Category[]>([])
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  useEffect(() => {
    void listCategories()
      .then(setCategories)
      .catch(() => setCategories([]))
  }, [])

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setBusy(true)
    setMessage(null)
    const fd = new FormData(e.currentTarget)
    const title = String(fd.get('title') ?? '')
    const author = String(fd.get('author') ?? '')
    const cover = fd.get('cover') as File | null
    const file = fd.get('file') as File | null
    try {
      let cover_url: string | undefined
      let file_url: string | undefined
      let file_type: 'epub' | 'pdf' | undefined
      let file_size_bytes: number | undefined
      if (cover?.size) cover_url = await uploadBookCover(cover)
      if (file?.size) {
        const uploaded = await uploadBookFile(file)
        file_url = uploaded.path
        file_size_bytes = uploaded.size
        file_type = inferFileType(file.name) ?? undefined
      }
      await insertBook({
        title,
        author,
        description: String(fd.get('description') ?? '') || undefined,
        category_id: String(fd.get('category_id') ?? '') || undefined,
        cover_url,
        file_url,
        file_type,
        file_size_bytes,
        status: 'pending_review',
      })
      setMessage('Book submitted for review.')
      e.currentTarget.reset()
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Upload failed')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold">Upload book</h1>
      <p className="text-sm text-slate-500">EPUB or PDF to Storage + metadata (pending review)</p>
      {message ? <p className="mt-4 text-sm text-slate-700">{message}</p> : null}
      <form onSubmit={onSubmit} className="mt-6 max-w-lg space-y-4">
        <input name="title" required placeholder="Title" className="w-full rounded border px-3 py-2" />
        <input name="author" required placeholder="Author" className="w-full rounded border px-3 py-2" />
        <textarea name="description" placeholder="Description" className="w-full rounded border px-3 py-2" />
        <select name="category_id" className="w-full rounded border px-3 py-2">
          <option value="">Category (optional)</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <label className="block text-sm">
          Cover image
          <input name="cover" type="file" accept="image/*" className="mt-1 block w-full" />
        </label>
        <label className="block text-sm">
          Book file (EPUB/PDF)
          <input name="file" type="file" accept=".epub,.pdf" className="mt-1 block w-full" />
        </label>
        <button
          type="submit"
          disabled={busy}
          className="rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-50"
        >
          {busy ? 'Uploading…' : 'Submit'}
        </button>
      </form>
    </div>
  )
}
