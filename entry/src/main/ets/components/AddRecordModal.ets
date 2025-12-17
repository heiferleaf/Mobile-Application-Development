import { SimpleDiaryRecord } from '../common/SimpleDiaryRecord';
import { AddRecordHandlers } from '../common/AddRecordHandlers';

// 正确导包（API 20 可用）
import picker from '@ohos.file.picker'

// 运行时权限（Stage 模型）
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'
import common from '@ohos.app.ability.common'

// 轻提示
import promptAction from '@ohos.promptAction';

@Component
export default struct AddRecordModal {
  @Prop isVisible: boolean
  // V1：@Prop 不可为可选，父组件必须传入
  @Prop handlers: AddRecordHandlers

  @State recordType: 'text' | 'image' = 'text'
  @State content: string = ''
  @State imageUrl: string = ''
  @State imagePicked: boolean = false
  @State location: string = ''
  @State saving: boolean = false
  @State timeStr: string = ''  // 时间输入

  aboutToAppear() {
    this.timeStr = this.nowStr()
  }

  private genId(): string { return Date.now().toString() }
  private nowStr(): string {
    const d: Date = new Date()
    const pad = (n: number): string => (n < 10 ? '0' + n : '' + n)
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
  }
  private canSave(): boolean { return this.content.trim().length > 0 && !this.saving }

  // 非 UI：请求相册权限（API 20 推荐 READ_IMAGEVIDEO）
  private async ensurePhotoPermission() {
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()
      await atManager.requestPermissionsFromUser(ctx, ['ohos.permission.READ_IMAGEVIDEO'])
    } catch (e) {
      // 忽略异常，选图失败时再提示
    }
  }

  // 非 UI：系统选图（API 20 强类型）
  private async chooseImage() {
    try {
      await this.ensurePhotoPermission()
      const photoPicker: picker.PhotoViewPicker = new picker.PhotoViewPicker()
      const options: picker.PhotoSelectOptions = { maxSelectNumber: 1 }
      const result: picker.PhotoSelectResult = await photoPicker.select(options)

      const uris: string[] = result.photoUris ?? []
      const first: string = uris.length > 0 ? uris[0] : ''

      if (first.length > 0) {
        this.imageUrl = first
        this.imagePicked = true
      } else {
        promptAction.showToast({ message: '未选择图片', duration: 1500 })
      }
    } catch (e) {
      promptAction.showToast({ message: '选择图片失败', duration: 1800 })
    }
  }

  private clearImage() { this.imagePicked = false; this.imageUrl = '' }

  private doSave() {
    if (!this.canSave()) { return }
    this.saving = true
    const rec: SimpleDiaryRecord = {
      id: this.genId(),
      type: this.recordType,
      time: this.timeStr.trim().length > 0 ? this.timeStr.trim() : this.nowStr(),
      content: this.content.trim(),
      imageUrl: this.imageUrl ? this.imageUrl : undefined,
      location: this.location.trim() ? this.location.trim() : undefined
    }
    if (this.handlers && this.handlers.onSave) { this.handlers.onSave(rec) }
    this.saving = false
    if (this.handlers && this.handlers.onCancel) { this.handlers.onCancel() }
    // 复位
    this.recordType = 'text'
    this.content = ''
    this.imageUrl = ''
    this.imagePicked = false
    this.location = ''
    this.timeStr = this.nowStr()
  }

  // 顶部栏（资源图标）
  @Builder HeaderBar() {
    Row() {
      Text('记一笔')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#2C4A68')

      Blank().layoutWeight(1)

      Image($r('app.media.close_icon'))
        .width(28).height(28)
        .objectFit(ImageFit.Contain)
        .backgroundColor('rgba(255,255,255,0.35)')
        .borderRadius(16)
        .padding({ left: 6, right: 6, top: 6, bottom: 6 })
        .onClick(() => { if (this.handlers && this.handlers.onCancel) { this.handlers.onCancel() } })
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 6, right: 6 })
  }

  // 时间编辑
  @Builder TimeEditor() {
    Row() {
      Text('时间').fontSize(14).fontColor('#6F7885').margin({ right: 10 })
      TextInput()
        .fontSize(14).fontColor('#4A3F35')
        .backgroundColor('rgba(255,255,255,0.30)')
        .borderRadius(14)
        .height(36)
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
        .onChange((val: string) => { this.timeStr = val })
      Text('例如：2025-12-02 21:05')
        .fontSize(12).fontColor('rgba(79,79,79,0.45)')
        .margin({ left: 8 })
    }
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 12 })
  }

  // 类型切换
  @Builder TypeSwitcher() {
    Row() {
      Column() {
        Text('文本')
          .fontSize(15)
          .fontColor(this.recordType === 'text' ? '#4A3F35' : '#6F7885')
          .fontWeight(this.recordType === 'text' ? FontWeight.Bold : FontWeight.Normal)
      }
      .backgroundColor(this.recordType === 'text' ? 'rgba(255,255,255,0.55)' : 'rgba(255,255,255,0.25)')
      .backdropBlur(10).borderRadius(18)
      .padding({ left: 18, right: 18, top: 8, bottom: 8 })
      .shadow({ radius: this.recordType === 'text' ? 12 : 0, color: 'rgba(120,100,80,0.15)', offsetY: 4 })
      .onClick(() => { this.recordType = 'text' })

      Blank().width(14)

      Column() {
        Text('图片')
          .fontSize(15)
          .fontColor(this.recordType === 'image' ? '#4A3F35' : '#6F7885')
          .fontWeight(this.recordType === 'image' ? FontWeight.Bold : FontWeight.Normal)
      }
      .backgroundColor(this.recordType === 'image' ? 'rgba(255,255,255,0.55)' : 'rgba(255,255,255,0.25)')
      .backdropBlur(10).borderRadius(18)
      .padding({ left: 18, right: 18, top: 8, bottom: 8 })
      .shadow({ radius: this.recordType === 'image' ? 12 : 0, color: 'rgba(120,100,80,0.15)', offsetY: 4 })
      .onClick(() => { this.recordType = 'image' })
    }
    .align(Alignment.Center)
    .margin({ top: 6, bottom: 4 })
  }

  // 内容输入
  @Builder ContentEditor() {
    Stack() {
      TextArea()
        .fontSize(16).fontColor('#4A3F35')
        .backgroundColor('rgba(255,255,255,0.30)')
        .backdropBlur(14).borderRadius(20)
        .height(140).padding(16)
        .onChange((val: string) => { this.content = val })

      if (this.content.trim().length === 0) {
        Row() {
          Text('记录当下的一瞬念想…')
            .fontSize(14).fontColor('rgba(79,79,79,0.45)')
        }
        .align(Alignment.TopStart)
        .padding({ left: 22, top: 20 })
      }
    }
    .margin({ bottom: 10 })
  }

  // 图片选择区
  @Builder ImagePickerArea() {
    if (this.recordType === 'image') {
      if (this.imagePicked && this.imageUrl.length > 0) {
        Stack() {
          Image(this.imageUrl)
            .width(160).height(120).objectFit(ImageFit.Cover).borderRadius(20)

          Image($r('app.media.close_icon'))
            .width(24).height(24).objectFit(ImageFit.Contain)
            .backgroundColor('rgba(0,0,0,0.35)')
            .borderRadius(14)
            .position({ x: 132, y: 6 })
            .onClick(() => { this.clearImage() })
        }
        .margin({ bottom: 12 })
      } else {
        Column() {
          Image($r('app.media.image_placeholder'))
            .width(100).height(100)
            .objectFit(ImageFit.Contain)
            .opacity(0.95)

          Image($r('app.media.plus_icon'))
            .width(28).height(28)
            .objectFit(ImageFit.Contain)
            .margin({ top: -66 })
        }
        .backgroundColor('rgba(255,255,255,0.30)')
        .backdropBlur(14).borderRadius(24)
        .padding({ left: 24, right: 24, top: 18, bottom: 18 })
        .onClick(() => { this.chooseImage() })
        .margin({ bottom: 12 })
      }
    }
  }

  // 地点输入
  @Builder LocationField() {
    Stack() {
      Row() {
        TextInput()
          .fontSize(14).fontColor('#4A3F35')
          .backgroundColor('rgba(255,255,255,0.30)')
          .backdropBlur(10).borderRadius(16)
          .height(40).padding({ left: 14, right: 14 })
          .layoutWeight(1)
          .onChange((val: string) => { this.location = val })
      }
      if (this.location.trim().length === 0) {
        Row() {
          Text('📍 添加地点（可选）')
            .fontSize(14).fontColor('rgba(79,79,79,0.45)')
            .margin({ left: 10 })
        }
        .align(Alignment.Top)
        .padding({ left: 14 })
      }
    }
    .margin({ bottom: 14 })
  }

  // 底部操作
  @Builder ActionBar() {
    Row() {
      Button() {
        Text('取消').fontSize(15).fontColor('#6F7885')
      }
      .backgroundColor('rgba(255,255,255,0.28)').backdropBlur(8)
      .borderRadius(24).padding({ left: 24, right: 24, top: 10, bottom: 10 })
      .onClick(() => { if (this.handlers && this.handlers.onCancel) { this.handlers.onCancel() } })

      Blank().width(18)

      Button() {
        Text(this.saving ? '保存中…' : '保存')
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
      }
      .backgroundColor('#FF9A76') // 预览更稳；如需可改回图片背景
      .borderRadius(28).opacity(this.canSave() ? 1 : 0.5)
      .padding({ left: 30, right: 30, top: 12, bottom: 12 })
      .onClick(() => { this.doSave() })
    }
    .align(Alignment.Center)
    .margin({ top: 4 })
  }

  build() {
    if (this.isVisible) {
      Stack() {
        Row() {}  // 遮罩：阻断穿透，不自动关闭
        .width('100%').height('100%')
        .backgroundColor('rgba(255,255,255,0.18)')
        .hitTestBehavior(HitTestMode.Block)

        Column() {  // 面板
          this.HeaderBar()
          this.TimeEditor()
          this.TypeSwitcher()
          this.ContentEditor()
          this.ImagePickerArea()
          this.LocationField()
          this.ActionBar()
        }
        .width('86%')
        .backgroundColor('rgba(255,255,255,0.42)')
        .borderRadius(32)
        .padding({ left: 24, right: 24, top: 16, bottom: 24 })
        .shadow({ radius: 26, color: 'rgba(120,100,80,0.16)', offsetY: 8 })
        .align(Alignment.Center)
      }
      .width('100%').height('100%')
    } else {
      Column() {}.width(0).height(0)
    }
  }
}