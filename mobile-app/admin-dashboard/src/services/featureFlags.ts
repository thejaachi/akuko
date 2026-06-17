import { getSupabase } from '@/lib/supabase'
import type { FeatureFlag } from '@/types/database'

export async function fetchFeatureFlags(): Promise<FeatureFlag[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('feature_flags')
    .select('key, enabled, description, phase, updated_at')
    .order('phase', { ascending: true })
    .order('key', { ascending: true })
  if (error) throw error
  return (data ?? []) as FeatureFlag[]
}

export async function setFeatureFlag(key: string, enabled: boolean): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase.from('feature_flags').update({ enabled }).eq('key', key)
  if (error) throw error
}
