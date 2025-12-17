import OpenAI from 'openai'
import dotenv from 'dotenv'
import { GenerateDiaryRequest, GenerateDiaryResponse, DiaryPayload, DiarySection, DiaryImagePlacement, GenerateDiaryMetrics } from './types'

dotenv.config()

const apiKey: string = process.env.OPENAI_API_KEY || ''
const baseURL: string = process.env.OPENAI_BASE_URL || 'https://dashscope.aliyuncs.com/compatible-mode/v1'
const model: string = process.env.OPENAI_MODEL || 'qwen-plus'

if (!apiKey) { throw new Error('Missing OPENAI_API_KEY environment variable') }
if (!baseURL) { throw new Error('Missing OPENAI_BASE_URL environment variable') }

const client = new OpenAI({
  apiKey,
  baseURL,
  timeout: 60000
})

export async function generateWithAI(req: GenerateDiaryRequest): Promise<GenerateDiaryResponse> {
  const start = Date.now()
  const prompt = buildPrompt(req)
  const system = `
你是一个日记生成助手。根据用户当天的记录和配置，严格输出 JSON，不要输出其他文本：
{
  "date": "YYYY-MM-DD",
  "title": "string",
  "sections": [{"name":"string","text":"string"}],
  "content": "string",
  "tags": ["string", ...],
  "images": [{"recordId":"string","sectionIndex":0,"caption":"string","anchorText":"string"}],
  "promptEcho": "string"
}
约束：
- images[].recordId 必须来自当天 records 里 type="image" 的 id；
- sectionIndex 必须在 sections 的范围内；
- anchorText 必须是对应 section 的 text 中出现的词（若无则省略）。
`.trim()

  try {
    const completion = await client.chat.completions.create({
      model,
      temperature: 0.7,
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: prompt }
      ]
    })

    const text: string = completion.choices?.[0]?.message?.content ?? ''
    let diary: DiaryPayload | undefined
    try {
      diary = JSON.parse(text) as DiaryPayload
    } catch {
      return await generateWithRules(req, Date.now() - start, model, 'BadJSON')
    }

    if (!diary || !Array.isArray(diary.sections)) {
      return await generateWithRules(req, Date.now() - start, model, 'BadShape')
    }

    diary.images = sanitizeImages(diary.images, diary.sections, req)
    const metrics: GenerateDiaryMetrics = { model, latencyMs: Date.now() - start }
    return { diary, metrics }
  } catch (err: any) {
    // 将上游状态透传到路由层
    const status: number = typeof err?.status === 'number' ? err.status : 500
    const message: string = err?.message ? String(err.message) : JSON.stringify(err)
    throw { status, message }
  }
}

export async function generateWithRules(
  req: GenerateDiaryRequest,
  elapsed?: number,
  modelName?: string,
  reason?: string
): Promise<GenerateDiaryResponse> {
  const start = Date.now()
  const textRecords = req.records.filter(r => r.type === 'text')
  const imageRecords = req.records.filter(r => r.type === 'image')

  const title: string = textRecords.length > 0 ? trimTitle(textRecords[0].content) : '今日小记'

  const sections: DiarySection[] = []
  for (let i = 0; i < req.options.contentBlocks.length; i++) {
    const b = req.options.contentBlocks[i]
    if (!b.enabled) continue
    const t = pickText(textRecords, i)
    sections.push({ name: b.name, text: t })
  }
  if (sections.length === 0) {
    sections.push({ name: '今日', text: summarizeText(textRecords) })
  }

  const content: string = summarizeText(textRecords)
  const tags: string[] = req.options.diaryStyles.filter(s => s.enabled).slice(0, 5).map(s => s.name)

  const images: DiaryImagePlacement[] = []
  for (let j = 0; j < imageRecords.length; j++) {
    const img = imageRecords[j]
    const secIdx = j % Math.max(1, sections.length)
    const anchor = findAnchorIn(sections[secIdx].text)
    images.push({
      recordId: img.id,
      sectionIndex: secIdx,
      caption: buildCaption(img.content),
      anchorText: anchor
    })
  }

  const fixedImages: DiaryImagePlacement[] = sanitizeImages(images, sections, req)
  const diary: DiaryPayload = {
    date: req.date,
    title,
    sections,
    content,
    tags,
    images: fixedImages,
    promptEcho: buildPromptEcho(req) + (reason ? ` | fallback=${reason}` : '')
  }

  const metrics: GenerateDiaryMetrics = {
    model: modelName || (process.env.OPENAI_MODEL || 'mock-gpt'),
    latencyMs: elapsed ?? (Date.now() - start)
  }

  return { diary, metrics }
}

// ------------------ helpers ------------------

function buildPrompt(req: GenerateDiaryRequest): string {
  const blocks: string = req.options.contentBlocks.filter(b => b.enabled).map(b => b.name).join('、') || '今日'
  const styles: string = req.options.diaryStyles.filter(s => s.enabled).map(s => s.name).join('、') || '朴素'
  const texts: string = req.records.filter(r => r.type === 'text').map(r => `- ${r.time}: ${safe(r.content)}`).join('\n')
  const images: string = req.records.filter(r => r.type === 'image').map(r => `- ${r.id}: ${safe(r.content)}`).join('\n')

  return [
    `日期: ${req.date}`,
    `内容块: ${blocks}`,
    `风格: ${styles}`,
    `标题显示: ${req.options.outputOptions.showTitles ? '是' : '否'}`,
    req.options.customInstructions ? `自定义指令: ${req.options.customInstructions}` : '',
    '文本记录：',
    texts || '(无)',
    '图片记录（用于 images.recordId）：',
    images || '(无)'
  ].join('\n')
}

function trimTitle(s: string): string {
  const t = s.trim()
  if (t.length === 0) return '今日小记'
  return t.length > 24 ? t.slice(0, 24) : t
}

function pickText(texts: { content: string }[], i: number): string {
  if (texts.length === 0) return '今天过得很充实。'
  const idx = i % texts.length
  const t = texts[idx].content ? texts[idx].content.trim() : ''
  return t.length > 0 ? t : '今天过得很充实。'
}

function summarizeText(texts: { content: string }[]): string {
  if (texts.length === 0) return '今天较为平静，记录不多。'
  const joined = texts.map(t => t.content).join(' ')
  const s = joined.trim()
  return s.length > 160 ? s.slice(0, 160) + '…' : s
}

function findAnchorIn(text: string): string | undefined {
  const anchors: string[] = ['阳光', '午后', '傍晚', '朋友', '学习', '散步', '雨', '图书馆', '操场']
  for (let i = 0; i < anchors.length; i++) {
    if (text.indexOf(anchors[i]) >= 0) return anchors[i]
  }
  return undefined
}

function buildCaption(content: string): string {
  const t = content.trim()
  return t.length > 0 ? t : '今日瞬间'
}

function buildPromptEcho(req: GenerateDiaryRequest): string {
  return `blocks=${req.options.contentBlocks.length}, styles=${req.options.diaryStyles.length}, showTitles=${req.options.outputOptions.showTitles}`
}

function sanitizeImages(
  images: DiaryImagePlacement[] | undefined,
  sections: DiarySection[],
  req: GenerateDiaryRequest
): DiaryImagePlacement[] {
  if (!images || images.length === 0) return []
  const imageIds: Set<string> = new Set(req.records.filter(r => r.type === 'image').map(r => r.id))
  const maxIdx: number = sections.length - 1

  const out: DiaryImagePlacement[] = []
  for (let i = 0; i < images.length; i++) {
    const img = images[i]
    if (!img || !imageIds.has(img.recordId)) continue
    const sectionIndex: number = img.sectionIndex < 0 ? 0 : (img.sectionIndex > maxIdx ? maxIdx : img.sectionIndex)
    let anchorText: string | undefined = img.anchorText
    const secText: string = sections[sectionIndex]?.text || ''
    if (anchorText && secText.indexOf(anchorText) < 0) {
      anchorText = undefined
    }
    out.push({
      recordId: img.recordId,
      sectionIndex,
      caption: img.caption,
      anchorText
    })
  }
  return out
}

function safe(s: string | undefined): string {
  return (s || '').replace(/\s+/g, ' ').trim()
}