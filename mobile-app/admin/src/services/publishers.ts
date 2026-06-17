import { getSupabase } from '@/lib/supabase'
import type { Publisher, PublisherStatus, PublisherWithMemberCount } from '@/types/database'

export async function listPublishers(): Promise<PublisherWithMemberCount[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('publishers')
    .select('*, publisher_members(count)')
    .order('created_at', { ascending: false })

  if (error) throw error

  return (data ?? []).map((row) => {
    const members = row.publisher_members as { count: number }[] | { count: number } | null
    const count =
      Array.isArray(members) && members[0]?.count != null
        ? members[0].count
        : typeof members === 'object' && members !== null && 'count' in members
          ? (members as { count: number }).count
          : 0
    const { publisher_members: _m, ...publisher } = row as Publisher & {
      publisher_members: unknown
    }
    return { ...publisher, member_count: count }
  })
}

export async function setPublisherStatus(id: string, status: PublisherStatus): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase.from('publishers').update({ status }).eq('id', id)
  if (error) throw error
}
