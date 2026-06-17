import { getSupabase } from '@/lib/supabase'
import type { AnalyticsEvent } from '@/types/database'

export async function listAnalyticsEvents(limit = 50): Promise<{
  events: AnalyticsEvent[]
  tableMissing: boolean
}> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('analytics_events')
    .select('id, event_type, user_id, book_id, payload, created_at')
    .order('created_at', { ascending: false })
    .limit(limit)
  if (error) {
    const msg = error.message.toLowerCase()
    if (msg.includes('does not exist') || msg.includes('relation') || error.code === 'PGRST205') {
      return { events: [], tableMissing: true }
    }
    throw error
  }
  return { events: (data ?? []) as AnalyticsEvent[], tableMissing: false }
}
