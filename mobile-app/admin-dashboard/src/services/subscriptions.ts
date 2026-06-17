import { getSupabase } from '@/lib/supabase'
import type { Subscription } from '@/types/database'

export async function listSubscriptions(): Promise<Subscription[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('subscriptions')
    .select('*')
    .order('updated_at', { ascending: false })
  if (error) throw error
  return (data ?? []) as Subscription[]
}
