import { getSupabase } from '@/lib/supabase'
import type { FeatureFlag } from '@/types/database'

export const PROD_SENSITIVE_FLAG_KEYS = ['payouts', 'royalties'] as const

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

export type FeatureFlagUpsert = {
  key: string
  enabled: boolean
  description?: string | null
  phase: number
}

export async function upsertFeatureFlag(input: FeatureFlagUpsert): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase.from('feature_flags').upsert({
    key: input.key,
    enabled: input.enabled,
    description: input.description ?? null,
    phase: input.phase,
  })
  if (error) throw error
}

export async function deleteFeatureFlag(key: string): Promise<void> {
  const supabase = getSupabase()
  const { error } = await supabase.from('feature_flags').delete().eq('key', key)
  if (error) throw error
}
