import { getSupabase } from '@/lib/supabase'
import type { PaymentTransaction } from '@/types/database'

export async function listPaymentTransactions(limit = 50): Promise<PaymentTransaction[]> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('payment_transactions')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit)
  if (error) {
    const msg = error.message.toLowerCase()
    if (msg.includes('does not exist') || msg.includes('relation') || error.code === 'PGRST205') {
      return []
    }
    throw error
  }
  return (data ?? []) as PaymentTransaction[]
}
