'use client'

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { getSupabase } from '@/lib/supabase'
import { isSupabaseConfigured } from '@/lib/env'

type AuthState = {
  session: Session | null
  user: User | null
  isAdmin: boolean
  loading: boolean
  configured: boolean
  signIn: (email: string, password: string) => Promise<{ error: string | null }>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthState | null>(null)

async function fetchIsAdmin(userId: string): Promise<boolean> {
  const supabase = getSupabase()
  const { data, error } = await supabase
    .from('profiles')
    .select('is_admin')
    .eq('id', userId)
    .maybeSingle()
  if (error) throw error
  const row = data as { is_admin?: boolean } | null
  return row?.is_admin === true
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const configured = isSupabaseConfigured()
  const [session, setSession] = useState<Session | null>(null)
  const [user, setUser] = useState<User | null>(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [loading, setLoading] = useState(configured)

  useEffect(() => {
    if (!configured) {
      setLoading(false)
      return
    }
    const supabase = getSupabase()
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session)
      setUser(data.session?.user ?? null)
      setLoading(false)
    })
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
      setUser(nextSession?.user ?? null)
      setLoading(false)
    })
    return () => subscription.unsubscribe()
  }, [configured])

  useEffect(() => {
    if (!user) {
      setIsAdmin(false)
      return
    }
    void fetchIsAdmin(user.id)
      .then(setIsAdmin)
      .catch(() => setIsAdmin(false))
  }, [user])

  const signIn = useCallback(async (email: string, password: string) => {
    const supabase = getSupabase()
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) return { error: error.message }
    const {
      data: { user: signedInUser },
    } = await supabase.auth.getUser()
    if (!signedInUser) return { error: 'Sign-in succeeded but no user was returned.' }
    try {
      const admin = await fetchIsAdmin(signedInUser.id)
      if (!admin) {
        await supabase.auth.signOut()
        return {
          error:
            'Access denied. profiles.is_admin must be true for this dashboard.',
        }
      }
      setIsAdmin(true)
      return { error: null }
    } catch (e) {
      await supabase.auth.signOut()
      return { error: e instanceof Error ? e.message : 'Could not verify admin status.' }
    }
  }, [])

  const signOut = useCallback(async () => {
    const supabase = getSupabase()
    await supabase.auth.signOut()
    setIsAdmin(false)
  }, [])

  const value = useMemo(
    () => ({
      session,
      user,
      isAdmin,
      loading,
      configured,
      signIn,
      signOut,
    }),
    [session, user, isAdmin, loading, configured, signIn, signOut],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
