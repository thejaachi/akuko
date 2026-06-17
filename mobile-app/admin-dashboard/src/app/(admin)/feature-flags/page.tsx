'use client'

import { useEffect, useState } from 'react'
import { Card } from '@/components/ui/card'
import { fetchFeatureFlags, setFeatureFlag } from '@/services/featureFlags'
import type { FeatureFlag } from '@/types/database'

export default function FeatureFlagsPage() {
  const [flags, setFlags] = useState<FeatureFlag[]>([])

  async function reload() {
    setFlags(await fetchFeatureFlags())
  }

  useEffect(() => {
    void reload()
  }, [])

  return (
    <div>
      <h1 className="text-2xl font-semibold">Feature flags</h1>
      <p className="text-sm text-slate-500">Wire to public.feature_flags (0008)</p>
      <Card className="mt-6 divide-y">
        {flags.map((f) => (
          <label key={f.key} className="flex items-center justify-between px-4 py-3">
            <span>
              <span className="font-medium">{f.key}</span>
              {f.description ? (
                <span className="ml-2 text-xs text-slate-500">{f.description}</span>
              ) : null}
            </span>
            <input
              type="checkbox"
              checked={f.enabled}
              onChange={(e) => void setFeatureFlag(f.key, e.target.checked).then(reload)}
            />
          </label>
        ))}
      </Card>
    </div>
  )
}
