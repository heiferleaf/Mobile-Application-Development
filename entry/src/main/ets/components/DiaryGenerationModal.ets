import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DiaryConfig, OutputOptions, DiaryOptionItem, ContentBlock, DiaryStyle, PRESET_CONTENT_BLOCKS, PRESET_DIARY_STYLES } from '../common/DiaryConfig'
import { StorageManager } from '../utils/StorageManager'
import { TagItemView } from './TagItemView'
import type { TagItemHandlers } from './TagItemView'
import { DiaryGenHandlers } from '../common/DiaryGenHandlers'
import { AiDiaryRepository } from '../data/AiDiaryRepository'
import { AiDiaryEntity } from '../utils/DiaryCodec'

class AppColors {
  static readonly Primary = '#6C5CE7'
  static readonly Secondary = '#00B894'
  static readonly TextPrimary = '#2D3436'
  static readonly TextSecondary = '#636E72'
  static readonly ActiveBg = 'rgba(108, 92, 231, 0.08)'
  static readonly ActiveBorder = 'rgba(108, 92, 231, 0.2)'
  static readonly Surface = '#F8F9FA'
}

// 生成服务返回类型（显式，避免 any/unknown）
interface GenOk { ok: true; entity: AiDiaryEntity }
interface GenErr { ok: false; message: string }
type GenResult = GenOk | GenErr

@Component
export default struct DiaryGenerationModal {
  @Link isVisible: boolean
  @Prop handlers: DiaryGenHandlers

  @State contentBlocks: DiaryOptionItem[] = []
  @State diaryStyles: DiaryOptionItem[] = []
  @State outputOptions: OutputOptions = { length: 'medium', showTitles: true }
  @State customInstructions: string = ''

  @State newContentBlockName: string = ''
  @State isAddingContent: boolean = false
  @State newDiaryStyleName: string = ''
  @State isAddingStyle: boolean = false

  private repo: AiDiaryRepository = new AiDiaryRepository()

  // 公开方法：父组件生成完成后调用，统一弹窗与跳首页
  public async notifyGenResult(res: GenResult): Promise<void> {
    if (res.ok) {
      await this.repo.upsert(res.entity)
      // 成功：Toast + 跳首页（不使用 showDialog 的 buttons，避免 color 类型报错）
      promptAction.showToast({ message: '日记已生成并保存', duration: 2000 })
      router.replaceUrl({ url: 'pages/MainPage' })
    } else {
      // 显式类型收窄后读取 message
      const err = res as GenErr
      const msg: string = err.message
      // 失败：Toast 提示错误信息（避免 showDialog buttons 类型要求）
      promptAction.showToast({ message: `生成失败：${msg}`, duration: 2500 })
    }
  }
  private defaultOutput(): OutputOptions {
    return { length: 'medium', showTitles: true }
  }

  private initDefaultConfig(): DiaryConfig {
    const cfg: DiaryConfig = {
      contentBlocks: PRESET_CONTENT_BLOCKS,
      diaryStyles: PRESET_DIARY_STYLES,
      outputOptions: this.defaultOutput(),
      customInstructions: ''
    }
    return cfg
  }

  private materializeStateFromConfig(cfg: DiaryConfig): void {
    this.contentBlocks = cfg.contentBlocks.map(i => new DiaryOptionItem(i.id, i.name, i.enabled, i.order))
    this.diaryStyles   = cfg.diaryStyles.map(i   => new DiaryOptionItem(i.id, i.name, i.enabled, i.order))
    this.outputOptions = cfg.outputOptions
    this.customInstructions = cfg.customInstructions
  }

  async aboutToAppear(): Promise<void> {
    try {
      let cfg = await StorageManager.loadConfig()
      if (!cfg) {
        cfg = this.initDefaultConfig()
        await StorageManager.saveConfig(cfg)
      }
      this.materializeStateFromConfig(cfg)
    } catch (e) {
      const def = this.initDefaultConfig()
      this.materializeStateFromConfig(def)
      console.error('加载配置失败:', e)
    }
  }

  private saveToStorage(): void {
    const config: DiaryConfig = {
      contentBlocks: this.contentBlocks.map(i => ({ id: i.id, name: i.name, enabled: i.enabled, order: i.order } as ContentBlock)),
      diaryStyles:   this.diaryStyles.map(i   => ({ id: i.id, name: i.name, enabled: i.enabled, order: i.order } as DiaryStyle)),
      outputOptions: this.outputOptions,
      customInstructions: this.customInstructions
    }
    StorageManager.saveConfig(config)
  }

  private toggleItem(item: DiaryOptionItem): void {
    item.enabled = !item.enabled
    this.saveToStorage()
    if (this.handlers && this.handlers.onToggleItem) { this.handlers.onToggleItem(item) }
  }

  private handlersContentEnabled(item: DiaryOptionItem): TagItemHandlers {
    return { onToggle: () => this.toggleItem(item) }
  }
  private handlersContentInactive(item: DiaryOptionItem): TagItemHandlers {
    return { onToggle: () => this.toggleItem(item), onDelete: () => this.deleteContentBlock(item.id) }
  }

  private handlersStyleEnabled(item: DiaryOptionItem): TagItemHandlers {
    return { onToggle: () => this.toggleItem(item) }
  }
  private handlersStyleInactive(item: DiaryOptionItem): TagItemHandlers {
    return { onToggle: () => this.toggleItem(item), onDelete: () => this.deleteDiaryStyle(item.id) }
  }

  private addCustomContentBlock(): void {
    const name = this.newContentBlockName.trim()
    if (!name) { return }
    const newBlock = new DiaryOptionItem(`custom_block_${Date.now()}`, name, true, this.contentBlocks.length)
    this.contentBlocks = [...this.contentBlocks, newBlock]
    this.newContentBlockName = ''
    this.isAddingContent = false
    this.saveToStorage()
    if (this.handlers && this.handlers.onAddContent) { this.handlers.onAddContent() }
  }
  private deleteContentBlock(id: string): void {
    this.contentBlocks = this.contentBlocks.filter(i => i.id !== id)
    this.saveToStorage()
    if (this.handlers && this.handlers.onDeleteItem) { this.handlers.onDeleteItem(id) }
  }

  private addCustomDiaryStyle(): void {
    const name = this.newDiaryStyleName.trim()
    if (!name) { return }
    const newStyle = new DiaryOptionItem(`custom_style_${Date.now()}`, name, true, this.diaryStyles.length)
    this.diaryStyles = [...this.diaryStyles, newStyle]
    this.newDiaryStyleName = ''
    this.isAddingStyle = false
    this.saveToStorage()
    if (this.handlers && this.handlers.onAddStyle) { this.handlers.onAddStyle() }
  }
  private deleteDiaryStyle(id: string): void {
    this.diaryStyles = this.diaryStyles.filter(i => i.id !== id)
    this.saveToStorage()
    if (this.handlers && this.handlers.onDeleteItem) { this.handlers.onDeleteItem(id) }
  }

  private updateOutputLength(len: 'short' | 'medium' | 'long'): void {
    this.outputOptions = { length: len, showTitles: this.outputOptions.showTitles }
    this.saveToStorage()
  }
  private updateShowTitles(show: boolean): void {
    this.outputOptions = { length: this.outputOptions.length, showTitles: show }
    this.saveToStorage()
  }

  @Builder
  buildHeader() {
    Row() {
      Column() {
        Text('AI 日记生成').fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.TextPrimary)
        Text('定制你的专属记忆').fontSize(13).fontColor(AppColors.TextSecondary).margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      Button({ type: ButtonType.Circle }) {
        Text('✕').fontSize(16).fontColor(AppColors.TextSecondary)
      }
      .width(28).height(28).backgroundColor('#F1F2F6')
      .onClick(() => {
        this.isVisible = false
        if (this.handlers && this.handlers.onClose) { this.handlers.onClose() }
      })
    }
    .width('100%').padding({ top: 24, left: 24, right: 24, bottom: 12 })
  }

  @Builder
  ContentBlocksSection() {
    Column() {
      Text('内容组成').fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.TextPrimary).margin({ bottom: 12, top: 4 })

      Column() {
        Text('已启用').fontSize(12).fontColor(AppColors.Secondary).margin({ bottom: 8 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.contentBlocks, (item: DiaryOptionItem) => {
            if (item.enabled) {
              TagItemView({ item: item, handlers: this.handlersContentEnabled(item) })
            }
          }, (item: DiaryOptionItem) => item.id)
        }
        .width('100%').padding(8).backgroundColor(AppColors.ActiveBg).borderRadius(16)
        .border({ width: 1, color: AppColors.ActiveBorder })
      }
      .alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 16 })

      Column() {
        Row() {
          Text('更多选项').fontSize(12).fontColor(AppColors.TextSecondary)
          Blank()
          if (!this.isAddingContent) {
            Text('+ 自定义').fontSize(12).fontColor(AppColors.Primary).fontWeight(FontWeight.Medium)
              .onClick(() => { this.isAddingContent = true })
          }
        }.width('100%').margin({ bottom: 8 })

        if (this.isAddingContent) {
          Row() {
            Stack() {
              TextInput()
                .height(36).layoutWeight(1).backgroundColor(AppColors.Surface).borderRadius(8)
                .onChange((val: string) => { this.newContentBlockName = val })
              if (!this.newContentBlockName.trim()) {
                Row() { Text('输入名称...').fontSize(12).fontColor('rgba(0,0,0,0.35)') }
                .align(Alignment.Start).padding({ left: 10 })
              }
            }

            Button('添加').height(36).fontSize(12).backgroundColor(AppColors.Primary).margin({ left: 8 })
              .onClick(() => this.addCustomContentBlock())

            Button('取消').height(36).fontSize(12).backgroundColor('#E0E0E0').fontColor('#666').margin({ left: 8 })
              .onClick(() => { this.isAddingContent = false; this.newContentBlockName = '' })
          }.margin({ bottom: 12 })
        }

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.contentBlocks, (item: DiaryOptionItem) => {
            if (!item.enabled) {
              TagItemView({ item: item, handlers: this.handlersContentInactive(item) })
            }
          }, (item: DiaryOptionItem) => item.id)
        }
      }
      .alignItems(HorizontalAlign.Start).width('100%')
    }
    .padding(16).backgroundColor('#FFFFFF').borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)' })
  }

  @Builder
  DiaryStylesSection() {
    Column() {
      Text('叙述风格').fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.TextPrimary).margin({ bottom: 12, top: 4 })

      Column() {
        Text('已启用').fontSize(12).fontColor(AppColors.Secondary).margin({ bottom: 8 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.diaryStyles, (item: DiaryOptionItem) => {
            if (item.enabled) {
              TagItemView({ item: item, handlers: this.handlersStyleEnabled(item) })
            }
          }, (item: DiaryOptionItem) => item.id)
        }
        .width('100%').padding(8).backgroundColor(AppColors.ActiveBg).borderRadius(16)
        .border({ width: 1, color: AppColors.ActiveBorder })
      }
      .alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 16 })

      Column() {
        Row() {
          Text('更多选项').fontSize(12).fontColor(AppColors.TextSecondary)
          Blank()
          if (!this.isAddingStyle) {
            Text('+ 自定义').fontSize(12).fontColor(AppColors.Primary).fontWeight(FontWeight.Medium)
              .onClick(() => { this.isAddingStyle = true })
          }
        }.width('100%').margin({ bottom: 8 })

        if (this.isAddingStyle) {
          Row() {
            Stack() {
              TextInput()
                .height(36).layoutWeight(1).backgroundColor(AppColors.Surface).borderRadius(8)
                .onChange((val: string) => { this.newDiaryStyleName = val })
              if (!this.newDiaryStyleName.trim()) {
                Row() { Text('输入名称...').fontSize(12).fontColor('rgba(0,0,0,0.35)') }
                .align(Alignment.Start).padding({ left: 10 })
              }
            }

            Button('添加').height(36).fontSize(12).backgroundColor(AppColors.Primary).margin({ left: 8 })
              .onClick(() => this.addCustomDiaryStyle())

            Button('取消').height(36).fontSize(12).backgroundColor('#E0E0E0').fontColor('#666').margin({ left: 8 })
              .onClick(() => { this.isAddingStyle = false; this.newDiaryStyleName = '' })
          }.margin({ bottom: 12 })
        }

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.diaryStyles, (item: DiaryOptionItem) => {
            if (!item.enabled) {
              TagItemView({ item: item, handlers: this.handlersStyleInactive(item) })
            }
          }, (item: DiaryOptionItem) => item.id)
        }
      }
      .alignItems(HorizontalAlign.Start).width('100%')
    }
    .padding(16).backgroundColor('#FFFFFF').borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)' })
  }

  @Builder
  buildOutputConfig() {
    Column() {
      Text('输出细节').fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.TextPrimary).margin({ bottom: 12, top: 4 })
      Row() {
        ForEach(['short', 'medium', 'long'], (len: string) => {
          Column() {
            Text(len === 'short' ? '精简' : len === 'medium' ? '适中' : '详尽')
              .fontSize(14)
              .fontWeight(this.outputOptions.length === len ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.outputOptions.length === len ? AppColors.Primary : AppColors.TextSecondary)
          }
          .layoutWeight(1).padding({ top: 12, bottom: 12 })
          .backgroundColor(this.outputOptions.length === len ? AppColors.ActiveBg : AppColors.Surface)
          .border({ width: 1, color: this.outputOptions.length === len ? AppColors.Primary : 'transparent' })
          .borderRadius(12).margin({ right: len !== 'long' ? 8 : 0 })
          .onClick(() => this.updateOutputLength(len as 'short' | 'medium' | 'long'))
        })
      }.width('100%').margin({ bottom: 16 })

      Row() {
        Column() {
          Text('智能小标题').fontSize(15).fontColor(AppColors.TextPrimary)
          Text('自动为段落生成概括性标题').fontSize(12).fontColor(AppColors.TextSecondary).margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.outputOptions.showTitles })
          .selectedColor(AppColors.Secondary)
          .onChange((val: boolean) => this.updateShowTitles(val))
      }
      .width('100%').padding(12).backgroundColor(AppColors.Surface).borderRadius(12)
    }
    .padding(16).backgroundColor('#FFFFFF').borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)' })
  }

  // 点击“立即生成”：保持原有回调与关闭逻辑
  private generateDiary(): void {
    const config: DiaryConfig = {
      contentBlocks: this.contentBlocks.map(i => ({ id: i.id, name: i.name, enabled: i.enabled, order: i.order } as ContentBlock)),
      diaryStyles:   this.diaryStyles.map(i   => ({ id: i.id, name: i.name, enabled: i.enabled, order: i.order } as DiaryStyle)),
      outputOptions: this.outputOptions,
      customInstructions: this.customInstructions
    }
    console.log('开始生成日记，配置:', JSON.stringify(config))
    if (this.handlers && this.handlers.onGenerate) { this.handlers.onGenerate(config) }
  }

  build() {
    if (this.isVisible) {
      Stack() {
        Rect().width('100%').height('100%').fill('rgba(0,0,0,0.4)').onClick(() => this.isVisible = false)

        Column() {
          this.buildHeader()

          Scroll() {
            Column({ space: 16 }) {
              this.ContentBlocksSection()
              this.DiaryStylesSection()
              this.buildOutputConfig()

              Column() {
                Text('给 AI 的悄悄话')
                  .fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.TextPrimary)
                  .margin({ bottom: 12, top: 4 })

                Stack() {
                  TextArea()
                    .height(100).backgroundColor(AppColors.Surface).borderRadius(12).fontSize(14).padding(12)
                    .onChange((val: string) => { this.customInstructions = val; this.saveToStorage() })

                  if (!this.customInstructions.trim()) {
                    Row() { Text('例如：今天很开心，多用点感叹号！').fontSize(12).fontColor('rgba(0,0,0,0.35)') }
                    .align(Alignment.TopStart).padding({ left: 18, top: 18 })
                  }
                }
              }
              .padding(16).backgroundColor('#FFFFFF').borderRadius(16)
              .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)' })
            }
            .padding({ left: 20, right: 20, bottom: 20 })
          }
          .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)

          Row({ space: 16 }) {
            Button('稍后再说')
              .layoutWeight(1).height(50).backgroundColor(AppColors.Surface).fontColor(AppColors.TextSecondary)
              .onClick(() => this.isVisible = false)

            Button('立即生成')
              .layoutWeight(2).height(50).backgroundColor(AppColors.Primary).fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold).shadow({ radius: 10, color: 'rgba(108, 92, 231, 0.4)', offsetY: 4 })
              .onClick(() => { this.generateDiary(); this.isVisible = false })
          }
          .padding({ left: 24, right: 24, bottom: 24, top: 16 }).backgroundColor('#FFFFFF')
        }
        .width('92%').height('85%').backgroundColor('#FAFAFA').borderRadius(24)
      }
      .width('100%').height('100%').alignContent(Alignment.Center)
    }
  }
}