export type BookFileType = 'epub' | 'pdf'

export type BookStatus =
  | 'draft'
  | 'pending_review'
  | 'published'
  | 'rejected'
  | 'archived'

export type BookPricingModel = 'free' | 'paid' | 'subscription_only'

export interface Book {
  id: string
  title: string
  author: string
  description: string | null
  cover_url: string | null
  file_url: string | null
  file_type: BookFileType | null
  file_size_bytes: number | null
  category_id: string | null
  isbn: string | null
  language: string
  page_count: number | null
  publisher: string | null
  published_date: string | null
  price: number
  is_premium: boolean
  is_featured: boolean
  is_trending: boolean
  is_new_release: boolean
  rating_avg: number
  rating_count: number
  download_count: number
  author_id: string | null
  created_at: string
  updated_at: string
  status: BookStatus
  uploaded_by: string | null
  approved_by: string | null
  approved_at: string | null
  rejection_reason: string | null
  pricing_model: BookPricingModel
  publisher_id: string | null
}

export type ProfileRole = 'reader' | 'author' | 'publisher' | 'admin'

export interface Profile {
  id: string
  full_name: string | null
  avatar_url: string | null
  bio: string | null
  is_admin: boolean
  role: ProfileRole
  author_id: string | null
  publisher_id: string | null
  created_at: string
  updated_at: string
}

export interface Category {
  id: string
  name: string
  slug: string
  description?: string | null
  sort_order?: number
}

export interface Subscription {
  id: string
  user_id: string
  plan: 'free' | 'premium'
  status: string
  paystack_customer_code: string | null
  paystack_subscription_code: string | null
  current_period_start: string | null
  current_period_end: string | null
  created_at: string
  updated_at: string
}

export type PaymentTransactionStatus =
  | 'pending'
  | 'success'
  | 'failed'
  | 'abandoned'
  | 'reversed'

export interface PaymentTransaction {
  id: string
  user_id: string
  reference: string
  amount: number
  currency: string
  status: PaymentTransactionStatus
  paystack_event: string | null
  metadata: Record<string, unknown>
  created_at: string
}

export interface FeatureFlag {
  key: string
  enabled: boolean
  description: string | null
  phase: number
  updated_at: string
}

export interface AnalyticsEvent {
  id: string
  event_type: string
  user_id: string | null
  book_id: string | null
  payload: Record<string, unknown>
  created_at: string
}
