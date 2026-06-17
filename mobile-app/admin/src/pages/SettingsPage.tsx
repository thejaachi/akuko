import { useCallback, useEffect, useState } from 'react'
import { AdminPage } from '@/components/layout/AdminLayout'
import { PageHeader } from '@/components/ui/PageHeader'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { Alert } from '@/components/ui/Alert'
import { Button } from '@/components/ui/Button'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'
import {
  deleteFeatureFlag,
  fetchFeatureFlags,
  PROD_SENSITIVE_FLAG_KEYS,
  setFeatureFlag,
  upsertFeatureFlag,
} from '@/services/featureFlags'
import type { FeatureFlag } from '@/types/database'

export function SettingsPage() {
  const [flags, setFlags] = useState<FeatureFlag[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState<string | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [newKey, setNewKey] = useState('')
  const [newDesc, setNewDesc] = useState('')
  const [newPhase, setNewPhase] = useState(1)

  const load = useCallback(() => {
    setLoading(true)
    fetchFeatureFlags()
      .then(setFlags)
      .catch((e) => setError(e instanceof Error ? e.message : 'Failed to load flags'))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const toggle = async (key: string, enabled: boolean) => {
    const previous = flags
    setFlags((current) =>
      current.map((f) => (f.key === key ? { ...f, enabled } : f)),
    )
    setSaving(key)
    setError(null)
    try {
      await setFeatureFlag(key, enabled)
    } catch (e) {
      setFlags(previous)
      setError(e instanceof Error ? e.message : 'Update failed')
    } finally {
      setSaving(null)
    }
  }

  const createFlag = async () => {
    const key = newKey.trim()
    if (!key) {
      setError('Flag key is required.')
      return
    }
    setSaving('__create__')
    setError(null)
    try {
      await upsertFeatureFlag({
        key,
        enabled: false,
        description: newDesc.trim() || null,
        phase: newPhase,
      })
      setNewKey('')
      setNewDesc('')
      setNewPhase(1)
      setShowCreate(false)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Create failed')
    } finally {
      setSaving(null)
    }
  }

  const removeFlag = async (key: string) => {
    if (!window.confirm(`Delete feature flag "${key}"?`)) return
    setSaving(key)
    setError(null)
    try {
      await deleteFeatureFlag(key)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Delete failed')
    } finally {
      setSaving(null)
    }
  }

  return (
    <AdminPage>
      <PageHeader
        title="Settings"
        description="Live feature_flags CRUD (migration 0008). Admin write via is_admin() RLS."
      />

      {error ? <Alert tone="error">{error}</Alert> : null}

      <Card>
        <CardHeader
          title="Feature flags"
          subtitle="See akuko/docs/FEATURE_FLAGS.md for rollout mapping"
          action={
            <Button variant="secondary" className="!py-1.5 !text-sm" onClick={() => setShowCreate((v) => !v)}>
              {showCreate ? 'Cancel' : 'Add flag'}
            </Button>
          }
        />
        {loading ? (
          <LoadingSpinner />
        ) : (
          <CardBody className="space-y-3">
            {showCreate ? (
              <div className="rounded-lg border border-outline p-4 space-y-3">
                <div className="grid gap-3 md:grid-cols-3">
                  <div>
                    <label className="mb-1 block text-sm font-medium">Key *</label>
                    <input
                      value={newKey}
                      onChange={(e) => setNewKey(e.target.value)}
                      className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
                      placeholder="my_feature"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-sm font-medium">Phase (1–4)</label>
                    <input
                      type="number"
                      min={1}
                      max={4}
                      value={newPhase}
                      onChange={(e) => setNewPhase(Number(e.target.value))}
                      className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
                    />
                  </div>
                  <div className="flex items-end">
                    <Button loading={saving === '__create__'} onClick={() => void createFlag()}>
                      Create
                    </Button>
                  </div>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium">Description</label>
                  <input
                    value={newDesc}
                    onChange={(e) => setNewDesc(e.target.value)}
                    className="w-full rounded-lg border border-outline px-3 py-2 text-sm"
                  />
                </div>
              </div>
            ) : null}

            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] text-left text-sm">
                <thead>
                  <tr className="border-b border-outline text-on-surface-muted">
                    <th className="px-3 py-2 font-medium">Key</th>
                    <th className="px-3 py-2 font-medium">Phase</th>
                    <th className="px-3 py-2 font-medium">Description</th>
                    <th className="px-3 py-2 font-medium">Enabled</th>
                    <th className="px-3 py-2 font-medium" />
                  </tr>
                </thead>
                <tbody>
                  {flags.map((flag) => {
                    const sensitive = PROD_SENSITIVE_FLAG_KEYS.includes(
                      flag.key as (typeof PROD_SENSITIVE_FLAG_KEYS)[number],
                    )
                    return (
                      <tr key={flag.key} className="border-b border-outline last:border-0">
                        <td className="px-3 py-3 font-medium">
                          {flag.key}
                          {sensitive && !flag.enabled ? (
                            <p className="mt-1 text-xs text-amber-700">
                              Phase 4 — keep off in production until payouts/royalties are ready.
                            </p>
                          ) : null}
                        </td>
                        <td className="px-3 py-3 tabular-nums">{flag.phase}</td>
                        <td className="max-w-xs px-3 py-3 text-on-surface-muted">
                          {flag.description ?? '—'}
                        </td>
                        <td className="px-3 py-3">
                          <input
                            type="checkbox"
                            checked={flag.enabled}
                            disabled={saving === flag.key}
                            onChange={(e) => void toggle(flag.key, e.target.checked)}
                            className="h-5 w-5"
                          />
                        </td>
                        <td className="px-3 py-3">
                          <Button
                            variant="ghost"
                            className="!py-1 !text-xs"
                            disabled={saving === flag.key}
                            onClick={() => void removeFlag(flag.key)}
                          >
                            Delete
                          </Button>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
            {flags.length === 0 ? (
              <p className="text-sm text-on-surface-muted">
                No flags returned. Apply migration 0008_ecosystem.sql to your Supabase project.
              </p>
            ) : null}
          </CardBody>
        )}
      </Card>

      <Card className="mt-4">
        <CardHeader title="Documentation" />
        <CardBody className="text-sm text-on-surface-muted">
          <ul className="list-inside list-disc space-y-1">
            <li>
              <a href="../../docs/FEATURE_FLAGS.md" className="text-primary-600 underline">
                FEATURE_FLAGS.md
              </a>{' '}
              — flag inventory and client usage
            </li>
            <li>
              <a href="../../docs/SUPABASE_SETUP.md" className="text-primary-600 underline">
                SUPABASE_SETUP.md
              </a>{' '}
              — promote admins, buckets, migrations
            </li>
          </ul>
        </CardBody>
      </Card>
    </AdminPage>
  )
}
