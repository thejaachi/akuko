import { getSupabase } from '@/lib/supabase'

const COVER_BUCKET = 'book-covers'
const FILE_BUCKET = 'book-files'

function sanitizeFilename(name: string): string {
  return name.replace(/[^a-zA-Z0-9._-]/g, '-').toLowerCase()
}

export async function uploadBookCover(file: File): Promise<string> {
  const supabase = getSupabase()
  const path = `${crypto.randomUUID()}/${sanitizeFilename(file.name)}`
  const { error } = await supabase.storage.from(COVER_BUCKET).upload(path, file, {
    upsert: false,
    contentType: file.type || undefined,
  })
  if (error) throw error
  return `${COVER_BUCKET}/${path}`
}

export async function uploadBookFile(file: File): Promise<{ path: string; size: number }> {
  const supabase = getSupabase()
  const path = `${crypto.randomUUID()}/${sanitizeFilename(file.name)}`
  const { error } = await supabase.storage.from(FILE_BUCKET).upload(path, file, {
    upsert: false,
    contentType: file.type || undefined,
  })
  if (error) throw error
  return { path: `${FILE_BUCKET}/${path}`, size: file.size }
}

export function inferFileType(filename: string): 'epub' | 'pdf' | null {
  const ext = filename.split('.').pop()?.toLowerCase()
  if (ext === 'epub') return 'epub'
  if (ext === 'pdf') return 'pdf'
  return null
}
