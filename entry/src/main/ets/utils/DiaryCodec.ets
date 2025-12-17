import { DiarySummary, SectionItem, Tag, ImageItem } from '../common/DiarySummary'

// 写库使用的接口（保持不变）
export interface AiDiaryEntity {
  id: string
  date: string
  title: string
  content: string
  sectionsJson: string
  tagsJson: string
  imagesJson: string
  promptEcho: string
  model?: string
  latencyMs?: number
  createdAt: string
  updatedAt: string
}

// 构造类用的入参类型：避免内联对象类型声明
export interface AiDiaryEntityCtorArgs {
  id: string
  date: string
  title: string
  content: string
  sectionsJson: string
  tagsJson: string
  imagesJson: string
  promptEcho: string
  model?: string
  latencyMs?: number
  createdAt: string
  updatedAt: string
}

// 读库/解析使用的名义类型，避免结构类型
export class AiDiaryEntityModel {
  id: string
  date: string
  title: string
  content: string
  sectionsJson: string
  tagsJson: string
  imagesJson: string
  promptEcho: string
  model?: string
  latencyMs?: number
  createdAt: string
  updatedAt: string

  constructor(args: AiDiaryEntityCtorArgs) {
    this.id = args.id
    this.date = args.date
    this.title = args.title
    this.content = args.content
    this.sectionsJson = args.sectionsJson
    this.tagsJson = args.tagsJson
    this.imagesJson = args.imagesJson
    this.promptEcho = args.promptEcho
    this.model = args.model
    this.latencyMs = args.latencyMs
    this.createdAt = args.createdAt
    this.updatedAt = args.updatedAt
  }

  static fromInterface(src: AiDiaryEntity): AiDiaryEntityModel {
    return new AiDiaryEntityModel({
      id: src.id,
      date: src.date,
      title: src.title,
      content: src.content,
      sectionsJson: src.sectionsJson,
      tagsJson: src.tagsJson,
      imagesJson: src.imagesJson,
      promptEcho: src.promptEcho,
      model: src.model,
      latencyMs: src.latencyMs,
      createdAt: src.createdAt,
      updatedAt: src.updatedAt
    })
  }
}

export class DiaryCodec {
  // 主实现：接收类实例，杜绝结构类型
  static toSummary(e: AiDiaryEntityModel): DiarySummary {
    const tagsArr: Tag[] = DiaryCodec.parseTags(e.tagsJson)
    const sectionsArr: SectionItem[] = DiaryCodec.parseSections(e.sectionsJson)
    const imagesArr: ImageItem[] = DiaryCodec.parseImages(e.imagesJson)

    const firstSectionText: string =
      sectionsArr.length > 0 && typeof sectionsArr[0].text === 'string'
        ? (sectionsArr[0].text as string)
        : ''
    const snippetSrc: string = (firstSectionText.length > 0 ? firstSectionText : e.content)
    const text: string = (snippetSrc || '').replace(/\s+/g, ' ').trim()
    const snippet: string = text.length > 110 ? text.slice(0, 110) + '…' : text

    const cover: string | undefined = DiaryCodec.pickCoverUrl(imagesArr)

    const out: DiarySummary = {
      id: e.id,
      date: e.date,
      title: e.title && e.title.length > 0 ? e.title : '无标题',
      snippet,
      tags: tagsArr.slice(0, 3).map((t: Tag) => t.name).filter((s: string) => s.length > 0),
      coverImageUrl: cover,
      model: e.model,
      latencyMs: e.latencyMs,
      updatedAt: e.updatedAt
    }
    return out
  }

  // 兼容入口：如手头是接口对象，可用此方法适配
  static toSummaryFromInterface(src: AiDiaryEntity): DiarySummary {
    return DiaryCodec.toSummary(AiDiaryEntityModel.fromInterface(src))
  }

  // 以下解析函数均使用显式接口，不含 any/unknown 与内联对象类型
  static parseTags(json: string): Tag[] {
    try {
      const arr = JSON.parse(json) as (string | Tag)[]
      if (!Array.isArray(arr)) return []
      const out: Tag[] = []
      for (let i = 0; i < arr.length; i++) {
        const item = arr[i]
        if (typeof item === 'string') {
          out.push({ name: item })
        } else {
          const name: string = typeof item.name === 'string' ? item.name : ''
          if (name.length > 0) out.push({ name })
        }
      }
      return out
    } catch {
      return []
    }
  }

  static parseSections(json: string): SectionItem[] {
    try {
      const arr = JSON.parse(json) as SectionItem[]
      if (!Array.isArray(arr)) return []
      const out: SectionItem[] = []
      for (let i = 0; i < arr.length; i++) {
        const item = arr[i]
        const name: string = typeof item.name === 'string' ? (item.name as string) : ''
        const text: string = typeof item.text === 'string' ? (item.text as string) : ''
        out.push({ name, text })
      }
      return out
    } catch {
      return []
    }
  }

  static parseImages(json: string): ImageItem[] {
    try {
      const arr = JSON.parse(json) as ImageItem[]
      if (!Array.isArray(arr)) return []
      const out: ImageItem[] = []
      for (let i = 0; i < arr.length; i++) {
        const item = arr[i]
        const remoteUrl: string | undefined = typeof item.remoteUrl === 'string' ? (item.remoteUrl as string) : undefined
        const localPath: string | undefined = typeof item.localPath === 'string' ? (item.localPath as string) : undefined
        out.push({ remoteUrl, localPath })
      }
      return out
    } catch {
      return []
    }
  }

  private static pickCoverUrl(images: ImageItem[]): string | undefined {
    for (let i = 0; i < images.length; i++) {
      const u: string | undefined = images[i].remoteUrl
      if (u && u.length > 0) return u
    }
    return undefined
  }
}