import { DiaryOptionItem } from '../common/DiaryConfig';

export interface TagItemHandlers {
  onToggle?: () => void
  onDelete?: () => void
}

@Component
export struct TagItemView {
  @ObjectLink item: DiaryOptionItem;
  @Prop handlers?: TagItemHandlers

  build() {
    Row() {
      Text(this.item.name)
        .fontSize(14)
        .fontColor(this.item.enabled ? '#FFFFFF' : '#2D3436')
        .fontWeight(this.item.enabled ? FontWeight.Medium : FontWeight.Regular)

      if (!this.item.enabled && this.handlers && this.handlers.onDelete) {
        Button({ type: ButtonType.Normal }) {
          Text('×').fontSize(18).fontColor('#636E72')
        }
        .backgroundColor(Color.Transparent)
        .width(20).height(20).margin({ left: 4 }).padding(0)
        .onClick(() => { if (this.handlers && this.handlers.onDelete) { this.handlers.onDelete() } })
      }
    }
    .padding({ left: 16, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.item.enabled ? '#6C5CE7' : '#F8F9FA')
    .borderRadius(20).margin(6)
    .shadow(this.item.enabled ? { radius: 8, color: 'rgba(108, 92, 231, 0.3)', offsetY: 4 } : { radius: 0 })
    .animation({ duration: 200 })
    .onClick(() => { if (this.handlers && this.handlers.onToggle) { this.handlers.onToggle() } })
  }
}