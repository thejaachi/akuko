'use client'

import { FormEvent, useEffect, useState } from 'react'
import { Card } from '@/components/ui/card'
import {
  createCategory,
  deleteCategory,
  listCategoriesAdmin,
  updateCategory,
} from '@/services/categories'
import type { Category } from '@/types/database'

export default function CategoriesPage() {
  const [rows, setRows] = useState<Category[]>([])
  const [name, setName] = useState('')

  async function reload() {
    setRows(await listCategoriesAdmin())
  }

  useEffect(() => {
    void reload()
  }, [])

  async function onCreate(e: FormEvent) {
    e.preventDefault()
    if (!name.trim()) return
    await createCategory(name)
    setName('')
    await reload()
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold">Categories</h1>
      <form onSubmit={onCreate} className="mt-4 flex gap-2">
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="New category name"
          className="rounded border px-3 py-2"
        />
        <button type="submit" className="rounded bg-blue-600 px-4 py-2 text-white">
          Add
        </button>
      </form>
      <Card className="mt-6">
        <ul className="divide-y">
          {rows.map((c) => (
            <li key={c.id} className="flex items-center justify-between px-4 py-3">
              <span>
                {c.name} <span className="text-xs text-slate-400">({c.slug})</span>
              </span>
              <div className="flex gap-2">
                <button
                  type="button"
                  className="text-sm text-blue-600"
                  onClick={() => {
                    const next = prompt('New name', c.name)
                    if (next) void updateCategory(c.id, { name: next }).then(reload)
                  }}
                >
                  Rename
                </button>
                <button
                  type="button"
                  className="text-sm text-red-600"
                  onClick={() => {
                    if (confirm('Delete category?')) void deleteCategory(c.id).then(reload)
                  }}
                >
                  Delete
                </button>
              </div>
            </li>
          ))}
        </ul>
      </Card>
    </div>
  )
}
