import { getSupabase } from '@/lib/supabase'

export type DashboardStats = {
  books: number | null
  authors: number | null
  users: number | null
  premiumSubscriptions: number | null
  errors: string[]
}

export async function fetchDashboardStats(): Promise<DashboardStats> {
  const supabase = getSupabase()
  const errors: string[] = []

  const countTable = async (
    table: 'books' | 'authors' | 'profiles' | 'subscriptions',
    filter?: { column: string; value: string },
  ) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let query = supabase.from(table).select('*', { count: 'exact', head: true }) as any
    if (filter) query = query.eq(filter.column, filter.value)
    const { count, error } = await query
    if (error) {
      errors.push(`${table}: ${error.message}`)
      return null
    }
    return count ?? 0
  }

  const [books, authors, users, premiumSubscriptions] = await Promise.all([
    countTable('books'),
    countTable('authors'),
    countTable('profiles'),
    countTable('subscriptions', { column: 'plan', value: 'premium' }),
  ])

  return { books, authors, users, premiumSubscriptions, errors }
}
