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

export interface Author {
  id: string
  name: string
  bio: string | null
  photo_url: string | null
  created_at: string
}

export interface AuthorWithStats extends Author {
  book_count: number
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

export interface AuthorApplication {
  profile_id: string
  full_name: string | null
  author_id: string
  author_name: string
  created_at: string
}

export interface Category {
  id: string
  name: string
  slug: string
}

export interface PublicProfile {
  id: string
  full_name: string | null
  avatar_url: string | null
  bio: string | null
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

export type PublisherStatus = 'pending' | 'approved' | 'suspended'

export interface Publisher {
  id: string
  name: string
  slug: string
  logo_url: string | null
  bio: string | null
  status: PublisherStatus
  created_at: string
  updated_at: string
}

export interface PublisherWithMemberCount extends Publisher {
  member_count: number
}

export interface FeatureFlag {
  key: string
  enabled: boolean
  description: string | null
  phase: number
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

export interface AnalyticsEvent {
  id: string
  event_type: string
  user_id: string | null
  book_id: string | null
  payload: Record<string, unknown>
  created_at: string
}

export type Database = {
  public: {
    Tables: {
      books: { Row: Book; Insert: Partial<Book>; Update: Partial<Book> }
      authors: { Row: Author; Insert: Partial<Author>; Update: Partial<Author> }
      profiles: { Row: Profile; Insert: Partial<Profile>; Update: Partial<Profile> }
      categories: { Row: Category; Insert: Partial<Category>; Update: Partial<Category> }
      subscriptions: { Row: Subscription; Insert: Partial<Subscription>; Update: Partial<Subscription> }
      feature_flags: { Row: FeatureFlag; Insert: Partial<FeatureFlag>; Update: Partial<FeatureFlag> }
      publishers: { Row: Publisher; Insert: Partial<Publisher>; Update: Partial<Publisher> }
      payment_transactions: {
        Row: PaymentTransaction
        Insert: Partial<PaymentTransaction>
        Update: Partial<PaymentTransaction>
      }
      analytics_events: {
        Row: AnalyticsEvent
        Insert: Partial<AnalyticsEvent>
        Update: Partial<AnalyticsEvent>
      }
    }
    Views: {
      public_profiles: { Row: PublicProfile }
    }
  }
}
