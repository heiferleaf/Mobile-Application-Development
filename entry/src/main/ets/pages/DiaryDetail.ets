import router from '@ohos.router'
import { DiaryHistoryRepository, GetEntityByDateResult } from '../data/DiaryHistoryRepository'
import { DiaryCodec, AiDiaryEntity } from '../utils/DiaryCodec'
import { SectionItem, ImageItem } from '../common/DiarySummary'

// 为路由参数提供显式接口，避免索引访问
interface RouterParams {
  date?: string
}

@Entry
@Component
export default struct DiaryDetail {
  @State date: string = ''
  @State loading: boolean = false
  @State errorMsg: string = ''

  @State title: string = ''
  @State modelName: string = ''
  @State latencyMs: number = 0

  @State sections: SectionItem[] = []
  @State tags: string[] = []
  @State images: ImageItem[] = []

  private repo: DiaryHistoryRepository = new DiaryHistoryRepository()

  aboutToAppear() {
    const params: RouterParams = router.getParams() as RouterParams
    const d: string = typeof params.date === 'string' ? (params.date as string) : ''
    this.date = d
    if (this.date.length === 0) {
      this.errorMsg = '参数缺失：date'
      return
    }
    this.load().then(() => {})
  }

  private async load(): Promise<void> {
    if (this.loading) return
    this.loading = true
    this.errorMsg = ''

    try {
      const r: GetEntityByDateResult = await this.repo.getEntityByDate(this.date)
      if (r.error) { this.errorMsg = r.error as string; return }
      if (!r.entity) { this.errorMsg = '未找到当日日记'; return }

      const model: AiDiaryEntity = r.entity as AiDiaryEntity

      this.title = (model.title && model.title.length > 0) ? model.title : '无标题'
      this.modelName = model.model ? (model.model as string) : ''
      this.latencyMs = typeof model.latencyMs === 'number' ? (model.latencyMs as number) : 0

      const tagObjs = DiaryCodec.parseTags(model.tagsJson)
      const secObjs = DiaryCodec.parseSections(model.sectionsJson)
      const imgObjs = DiaryCodec.parseImages(model.imagesJson)

      const tagNames: string[] = []
      for (let i = 0; i < tagObjs.length; i++) {
        const nm: string = typeof tagObjs[i].name === 'string' ? (tagObjs[i].name as string) : ''
        if (nm.length > 0) tagNames.push(nm)
      }
      this.tags = tagNames

      this.sections = secObjs
      this.images = imgObjs
    } catch (e) {
      this.errorMsg = typeof e === 'string' ? e : JSON.stringify(e)
    } finally {
      this.loading = false
    }
  }

  private goBack(): void {
    router.back()
  }

  @Builder
  TagChip(text: string) {
    Text(text)
      .fontSize(11)
      .fontColor('#5D5652')
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .backgroundColor('rgba(166,145,129,0.15)')
      .borderRadius(10)
      .margin({ right: 6, top: 8 })
  }

  @Builder
  SectionCardFrom(s: SectionItem) {
    Column() {
      if (typeof s.name === 'string' && (s.name as string).length > 0) {
        Text(s.name as string)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F2B28')
      }
      Text(typeof s.text === 'string' ? (s.text as string) : '')
        .fontSize(14)
        .fontColor('#5D5652')
        .margin({ top: 6 })
    }
    .padding(12)
    .borderRadius(12)
    .backgroundColor('rgba(255,255,255,0.7)')
    .backdropBlur(12)
    .margin({ top: 8 })
  }

  @Builder
  ImageThumbFrom(img: ImageItem) {
    // 顶部对齐用 FlexAlign.Start；横向居中用 HorizontalAlign.Center
    Column() {
      Text(
        (img.remoteUrl && (img.remoteUrl as string).length > 0)
          ? '图片(远端)'
          : ((img.localPath && (img.localPath as string).length > 0) ? '图片(本地)' : '图片')
      )
        .fontSize(12)
        .fontColor('#8B8079')
        .margin({ top: 30 })
    }
    .width(100)
    .height(100)
    .backgroundColor('rgba(0,0,0,0.06)')
    .borderRadius(12)
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 8, top: 8 })
  }

  build() {
    Column() {
      Row() {
        Button('< 返回')
          .backgroundColor('transparent')
          .fontColor('#5D5652')
          .onClick(() => this.goBack())
        Blank().layoutWeight(1)
        Text(this.date).fontSize(12).fontColor('#8B8079')
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })

      if (this.errorMsg) {
        Text(this.errorMsg).fontColor('#C00').margin({ top: 12 })
      } else if (this.loading) {
        Text('加载中...').fontColor('#8B8079').margin({ top: 12 })
      } else {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F2B28')
          .margin({ top: 6 })

        Row() {
          if (this.modelName && this.modelName.length > 0) {
            Text(this.modelName)
              .fontSize(11)
              .fontColor('#8B8079')
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(10)
          }
          if (this.latencyMs > 0) {
            Text(`${this.latencyMs}ms`)
              .fontSize(11)
              .fontColor('#8B8079')
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(10)
              .margin({ left: 6 })
          }
        }
        .margin({ top: 6 })

        if (this.tags.length > 0) {
          Row() {
            ForEach(this.tags, (t: string) => {
              this.TagChip(t)
            }, (t: string) => t)
          }
          .width('100%')
          .margin({ top: 6 })
        }

        if (this.images.length > 0) {
          Row() {
            ForEach(this.images, (img: ImageItem) => {
              this.ImageThumbFrom(img)
            }, (img: ImageItem) => {
              const keyRemote: string = (img.remoteUrl && (img.remoteUrl as string).length > 0) ? (img.remoteUrl as string) : ''
              const keyLocal: string = (img.localPath && (img.localPath as string).length > 0) ? (img.localPath as string) : ''
              return keyRemote.length > 0 ? keyRemote : keyLocal
            })
          }
          .width('100%')
          .margin({ top: 6 })
        }

        if (this.sections.length > 0) {
          ForEach(this.sections, (s: SectionItem) => {
            this.SectionCardFrom(s)
          }, (s: SectionItem) => {
            const nk: string = (typeof s.name === 'string') ? (s.name as string) : ''
            const tk: string = (typeof s.text === 'string') ? (s.text as string) : ''
            return `${nk}-${tk.length}`
          })
        }
      }

      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F7F4F1')
  }
}