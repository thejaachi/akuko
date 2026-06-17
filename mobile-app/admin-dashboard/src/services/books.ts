import { getSupabase } from '@/lib/supabase'
import type { Book, BookFileType, BookStatus, Category } from '@/types/database'

export type BookStatusFilter = 'all' | BookStatus

export async function listBooks(statusFilter: BookStatusFilter = 'all'): Promise<Book[]> {
  const supabase = getSupabase()
  let query = supabase.from('books').select('*').order('created_at', { ascending: false })
  if (statusFilter !== 'all') query = query.eq('status', statusFilter)
  const { data, error } = await query
  if (error) throw error
  return (data ?? []) as Book[]
}

export async function listCategories(): Promise<Category[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('categories')
    .select('id, name, slug, description, sort_order')
    .order('sort_order', { ascending: true })
  if (error) throw error
  return (data ?? []) as Category[]
}

export type BookInsertInput = {
  title: string
  author: string
  description?: string
  cover_url?: string
  file_url?: string
  file_type?: BookFileType
  file_size_bytes?: number
  category_id?: string
  is_premium?: boolean
  is_featured?: boolean
  status?: BookStatus
}

export async function insertBook(input: BookInsertInput): Promise<Book> {
  const supabase = getSupabase()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  const status = input.status ?? 'pending_review'
  const { data, error } = await supabase
    .from('books')
    .insert({
      title: input.title,
      author: input.author,
      description: input.description ?? null,
      cover_url: input.cover_url ?? null,
      file_url: input.file_url ?? null,
      file_type: input.file_type ?? null,
      file_size_bytes: input.file_size_bytes ?? null,
      category_id: input.category_id ?? null,
      is_premium: input.is_premium ?? false,
      is_featured: input.is_featured ?? false,
      status,
      uploaded_by: user?.id ?? null,
      ...(status === 'published'
        ? {
            approved_by: user?.id ?? null,
            approved_at: new Date().toISOString(),
            rejection_reason: null,
          }
        : {}),
    })
    .select()
    .single()
  if (error) throw error
  return data as Book
}

export async function approveBook(id: string): Promise<void> {
  const supabase = getSupabase()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')
  const { error } = await supabase
    .from('books')
    .update({
      status: 'published',
      approved_by: user.id,
      approved_at: new Date().toISOString(),
      rejection_reason: null,
    })
    .eq('id', id)
  if (error) throw error
}

export async function rejectBook(id: string, rejectionReason: string): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase
    .from('books')
    .update({
      status: 'rejected',
      rejection_reason: rejectionReason.trim() || null,
    })
    .eq('id', id)
  if (error) throw error
}

export async function setBookFeatured(id: string, isFeatured: boolean): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase.from('books').update({ is_featured: isFeatured }).eq('id', id)
  if (error) throw error
}
