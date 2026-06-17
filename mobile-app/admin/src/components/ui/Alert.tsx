type Tone = 'info' | 'warning' | 'error' | 'success'

const toneClass: Record<Tone, string> = {
  info: 'border-primary-100 bg-primary-50 text-primary-700',
  warning: 'border-amber-200 bg-amber-50 text-amber-900',
  error: 'border-red-200 bg-red-50 text-error',
  success: 'border-green-200 bg-green-50 text-success',
}

export function Alert({
  tone = 'info',
  title,
  children,
  className = '',
}: {
  tone?: Tone
  title?: string
  children: React.ReactNode
  className?: string
}) {
  return (
    <div className={`rounded-lg border px-4 py-3 text-sm ${toneClass[tone]} ${className}`}>
      {title ? <p className="font-medium">{title}</p> : null}
      <div className={title ? 'mt-1' : ''}>{children}</div>
    </div>
  )
}
