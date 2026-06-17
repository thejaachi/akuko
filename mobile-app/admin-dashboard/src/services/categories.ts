import { getSupabase } from '@/lib/supabase'
import type { Category } from '@/types/database'

function slugify(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
}

export async function listCategoriesAdmin(): Promise<Category[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .order('sort_order', { ascending: true })
  if (error) throw error
  return (data ?? []) as Category[]
}

export async function createCategory(name: string, sortOrder = 0): Promise<Category> {
  const supabase = getSupabase()
  const slug = slugify(name)
  const { data, error } = await supabase
    .from('categories')
    .insert({ name: name.trim(), slug, sort_order: sortOrder })
    .select()
    .single()
  if (error) throw error
  return data as Category
}

export async function updateCategory(
  id: string,
  patch: { name?: string; sort_order?: number },
): Promise<void> {
  const supabase = getSupabase()
  const update: Record<string, unknown> = { ...patch }
  if (patch.name) update.slug = slugify(patch.name)
  const { error } = await supabase.from('categories').update(update).eq('id', id)
  if (error) throw error
}

export async function deleteCategory(id: string): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase.from('categories').delete().eq('id', id)
  if (error) throw error
}
