import { getSupabase } from '@/lib/supabase'
import type { Profile, ProfileRole } from '@/types/database'

export async function listProfilesForAdmin(): Promise<Profile[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('profiles')
    .select(
      'id, full_name, avatar_url, bio, is_admin, role, author_id, publisher_id, created_at, updated_at',
    )
    .order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []) as Profile[]
}

export async function updateProfileRole(id: string, role: ProfileRole): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase.from('profiles').update({ role }).eq('id', id)
  if (error) throw error
}
