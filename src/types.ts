// 与前端合同保持一致（避免 any/unknown）
// 这些是后端内部使用的类型；与前端的 interface 字段对应

export interface ContentBlock {
    id: string
    name: string
    enabled: boolean
    order: number
  }
  
  export interface DiaryStyle {
    id: string
    name: string
    enabled: boolean
    order: number
  }
  
  export interface OutputOptions {
    length: 'short' | 'medium' | 'long'
    showTitles: boolean
  }
  
  export interface DiaryConfig {
    contentBlocks: ContentBlock[]
    diaryStyles: DiaryStyle[]
    outputOptions: OutputOptions
    customInstructions?: string
  }
  
  export interface SimpleDiaryRecord {
    id: string
    type: 'text' | 'image' | 'voice'
    time: string
    content: string
    imageUrl?: string
    location?: string
  }
  
  export interface MediaPolicy {
    includeImageContext: boolean
    uploadImages: boolean
  }
  
  export interface GenerateDiaryRequest {
    date: string // 'YYYY-MM-DD'
    records: SimpleDiaryRecord[]
    options: DiaryConfig
    mediaPolicy: MediaPolicy
  }
  
  export interface DiarySection {
    name: string
    text: string
  }
  
  export interface DiaryImagePlacement {
    recordId: string
    sectionIndex: number
    caption?: string
    anchorText?: string
    remoteUrl?: string
  }
  
  export interface DiaryPayload {
    date: string
    title: string
    sections: DiarySection[]
    content: string
    tags: string[]
    images: DiaryImagePlacement[]
    promptEcho: string
  }
  
  export interface GenerateDiaryMetrics {
    model: string
    latencyMs: number
    tokensInput?: number
    tokensOutput?: number
  }
  
  export interface GenerateDiaryError {
    code: string
    message: string
    retryable: boolean
  }
  
  export interface GenerateDiaryResponse {
    diary?: DiaryPayload
    metrics?: GenerateDiaryMetrics
    error?: GenerateDiaryError
  }