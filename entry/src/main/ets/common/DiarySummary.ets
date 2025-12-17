export interface Tag {
  name: string
}

export interface SectionItem {
  name?: string
  text?: string
}

export interface ImageItem {
  remoteUrl?: string
  localPath?: string
}

export interface DiarySummary {
  id: string
  date: string
  title: string
  snippet: string
  tags: string[]
  coverImageUrl?: string
  model?: string
  latencyMs?: number
  updatedAt: string
}