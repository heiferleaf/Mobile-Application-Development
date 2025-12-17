import express, { Request, Response } from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import { generateWithAI, generateWithRules } from './generator'
import { GenerateDiaryRequest } from './types'

dotenv.config()

const app = express()
app.use(express.json())

// CORS（开发用 *，生产建议白名单）
app.use(cors({
  origin: process.env.ALLOW_ORIGIN || '*'
}))

app.post('/api/diary/generate', async (req: Request, res: Response) => {
  const body = req.body as GenerateDiaryRequest
  try {
    const out = await generateWithAI(body)
    // 成功：前端期望 { diary, metrics }
    res.status(200).json(out)
  } catch (e: any) {
    // 透传上游状态码，不要统一 500 包404
    const status: number = typeof e?.status === 'number' ? e.status : 500
    const message: string = e?.message ? String(e.message) : 'ServerError'
    // 可选：降级为规则生成（仅当 5xx 可重试）
    if (status >= 500) {
      const fallback = await generateWithRules(body, undefined, process.env.OPENAI_MODEL || 'qwen-plus', 'UpstreamError')
      res.status(200).json(fallback)
      return
    }
    res.status(status).json({ error: { code: 'UpstreamError', message, retryable: status >= 500 } })
  }
})

const port = Number(process.env.PORT || 3000)
app.listen(port, () => {
  console.log(`server on http://0.0.0.0:${port}`)
})