import http from '@ohos.net.http'
import {
  SimpleDiaryRecord,
  GenerateDiaryRequest,
  GenerateDiaryResponse,
  DiaryPayload,
  MediaPolicy
} from '../common/SimpleDiaryRecord'
import { DiaryConfig } from '../common/DiaryConfig'
import { AiDiaryRepository } from '../data/AiDiaryRepository'

// 显式声明返回类型，避免 Promise<{ ... }> 的内联对象类型写法
export interface GenerateAndSaveResult {
  diary?: DiaryPayload
  error?: string
}

export class GenerationService {
  private repo: AiDiaryRepository
  private baseUrl: string

  constructor(repo: AiDiaryRepository, baseUrl: string) {
    this.repo = repo
    this.baseUrl = baseUrl
  }

  buildRequest(date: string, records: SimpleDiaryRecord[], options: DiaryConfig): GenerateDiaryRequest {
    // 不使用内联类型注解，直接对象赋值
    const mediaPolicy : MediaPolicy = {
      includeImageContext: true,
      uploadImages: false
    }
    const req: GenerateDiaryRequest = {
      date: date,
      records: records,
      options: options,
      mediaPolicy: mediaPolicy
    }
    return req
  }

  async callGenerate(req: GenerateDiaryRequest): Promise<GenerateDiaryResponse> {
    const client = http.createHttp()
    try {
      const url: string = `${this.baseUrl}/api/diary/generate`

      // 添加调试日志
      console.log(`[HTTP] 发送请求到: ${url}`)
      console.log(`[HTTP] 请求数据: ${JSON.stringify(req)}`)

      const response = await client.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        extraData: JSON.stringify(req),
        connectTimeout: 15000, // 增加连接超时时间
        readTimeout: 30000     // 增加读取超时时间
      })

      console.log(`[HTTP] 响应状态: ${response.responseCode}`)
      console.log(`[HTTP] 响应数据: ${JSON.stringify(response.result)}`)

      const raw = response.result
      const text: string = typeof raw === 'string' ? raw : (raw?.toString?.() ?? '')

      if (!text) {
        const emptyResp: GenerateDiaryResponse = {
          error: { code: 'EmptyResponse', message: '服务器返回空响应', retryable: true }
        }
        return emptyResp
      }

      let json: GenerateDiaryResponse
      try {
        json = JSON.parse(text) as GenerateDiaryResponse
      } catch (parseError) {
        console.error(`[HTTP] 解析JSON失败: ${parseError}, 原始数据: ${text}`)
        const parseErrResp: GenerateDiaryResponse = {
          error: { code: 'ParseError', message: `JSON解析失败: ${parseError}`, retryable: false }
        }
        return parseErrResp
      }

      const hasAny = !!(json && (json.diary || json.error || json.metrics))
      if (!hasAny) {
        const bad: GenerateDiaryResponse = {
          error: { code: 'BadResponse', message: '响应格式不正确', retryable: false }
        }
        return bad
      }

      console.log(`[HTTP] 成功解析响应: ${JSON.stringify(json)}`)
      return json
    } catch (e) {
      console.error(`[HTTP] 请求失败: ${e}`)
      const msg: string = typeof e === 'object' ? JSON.stringify(e) : String(e)
      const errResp: GenerateDiaryResponse = {
        error: { code: 'NetworkError', message: `网络请求失败: ${msg}`, retryable: true }
      }
      return errResp
    } finally {
      client.destroy()
    }
  }

  async generateAndSave(
    date: string,
    records: SimpleDiaryRecord[],
    options: DiaryConfig
  ): Promise<GenerateAndSaveResult> {
    try {
      console.log(`[GenService] 开始生成日记，日期: ${date}, 记录数: ${records.length}`)
      const req: GenerateDiaryRequest = this.buildRequest(date, records, options)
      console.log(`[GenService] 构建请求完成: ${JSON.stringify(req)}`)

      const resp: GenerateDiaryResponse = await this.callGenerate(req)
      console.log(`[GenService] 收到响应: ${JSON.stringify(resp)}`)

      if (resp.error) {
        console.error(`[GenService] 生成失败: ${resp.error.code}: ${resp.error.message}`)
        const result: GenerateAndSaveResult = { error: `${resp.error.code}: ${resp.error.message}` }
        return result
      }
      if (!resp.diary) {
        console.error('[GenService] 生成结果为空')
        const result: GenerateAndSaveResult = { error: '生成结果为空' }
        return result
      }

      console.log('[GenService] 日记生成成功，准备保存')
      const model: string | undefined = resp.metrics ? resp.metrics.model : undefined
      const latency: number | undefined = resp.metrics ? resp.metrics.latencyMs : undefined

      const entity = this.repo.toEntity(date, resp.diary, model, latency)
      await this.repo.upsert(entity)
      console.log('[GenService] 日记已保存')

      const ok: GenerateAndSaveResult = { diary: resp.diary }
      return ok
    } catch (e) {
      console.error(`[GenService] 生成和保存过程中发生错误: ${e}`)
      const msg: string = typeof e === 'object' ? JSON.stringify(e) : String(e)
      const err: GenerateAndSaveResult = { error: msg }
      return err
    }
  }
}



