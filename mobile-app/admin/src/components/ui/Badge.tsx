const tones: Record<string, string> = {
  default: 'bg-surface text-on-surface-muted border-outline',
  success: 'bg-green-50 text-success border-green-200',
  warning: 'bg-amber-50 text-amber-800 border-amber-200',
  error: 'bg-red-50 text-error border-red-200',
  primary: 'bg-primary-50 text-primary-700 border-primary-100',
}

export function Badge({
  children,
  tone = 'default',
}: {
  children: React.ReactNode
  tone?: keyof typeof tones
}) {
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${tones[tone]}`}
    >
      {children}
    </span>
  )
}
