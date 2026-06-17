import { getSupabase } from '@/lib/supabase'
import type { Author, AuthorApplication, AuthorWithStats, ProfileRole } from '@/types/database'

export async function listAuthorsWithStats(): Promise<AuthorWithStats[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('authors')
    .select('*, books(count)')
    .order('name', { ascending: true })

  if (error) throw error

  return (data ?? []).map((row) => {
    const books = row.books as { count: number }[] | { count: number } | null
    const count =
      Array.isArray(books) && books[0]?.count != null
        ? books[0].count
        : typeof books === 'object' && books !== null && 'count' in books
          ? (books as { count: number }).count
          : 0
    const { books: _b, ...author } = row as Author & { books: unknown }
    return { ...author, book_count: count }
  })
}

/** Profiles linked to an author row but not yet promoted to role=author (0008 has no authors.status). */
export async function listPendingAuthorApplications(): Promise<AuthorApplication[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('profiles')
    .select('id, full_name, author_id, created_at')
    .eq('role', 'reader')
    .not('author_id', 'is', null)
    .order('created_at', { ascending: false })

  if (error) throw error

  const rows = data ?? []
  if (rows.length === 0) return []

  const authorIds = [...new Set(rows.map((r) => r.author_id as string))]
  const { data: authorRows, error: authorError } = await supabase
    .from('authors')
    .select('id, name')
    .in('id', authorIds)

  if (authorError) throw authorError
  const nameById = new Map((authorRows ?? []).map((a) => [a.id as string, a.name as string]))

  return rows.map((row) => ({
    profile_id: row.id as string,
    full_name: row.full_name as string | null,
    author_id: row.author_id as string,
    author_name: nameById.get(row.author_id as string) ?? 'Unknown author',
    created_at: row.created_at as string,
  }))
}

export async function updateAuthor(
  id: string,
  patch: Partial<Pick<Author, 'name' | 'bio' | 'photo_url'>>,
): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase.from('authors').update(patch).eq('id', id)
  if (error) throw error
}

export async function setProfileRole(
  profileId: string,
  role: ProfileRole,
  authorId?: string | null,
): Promise<void> {
  const supabase = getSupabase()
  const patch: { role: ProfileRole; author_id?: string | null } = { role }
  if (authorId !== undefined) {
    patch.author_id = authorId
  }
  const { error } = await supabase.from('profiles').update(patch).eq('id', profileId)
  if (error) throw error
}

/** Promote linked profile(s) for this author to role=author. */
export async function approveAuthorPersona(authorId: string): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase
    .from('profiles')
    .update({ role: 'author', author_id: authorId })
    .eq('author_id', authorId)

  if (error) throw error
}

/** Revoke author persona: role=reader, clear author_id on linked profiles. */
export async function suspendAuthorPersona(authorId: string): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase
    .from('profiles')
    .update({ role: 'reader', author_id: null })
    .eq('author_id', authorId)

  if (error) throw error
}

export async function linkProfileToAuthor(profileId: string, authorId: string): Promise<void> {
  await setProfileRole(profileId, 'reader', authorId)
}
