import { getSupabase } from '@/lib/supabase'
import type { Subscription } from '@/types/database'

/** RLS only allows each user to read their own row until an admin policy lands in 0008. */
export async function listSubscriptions(): Promise<{
  rows: Subscription[]
  limitedByRls: boolean
}> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('subscriptions')
    .select('*')
    .order('updated_at', { ascending: false })

  if (error) throw error
  const rows = (data ?? []) as Subscription[]
  return { rows, limitedByRls: true }
}
