import router from '@ohos.router'

@Component
export default struct BottomNavBar {
  @Link showGenerationModal: boolean
  @State curIndex: number = 0 // 0=首页, 2=历史

  build() {
    Row() {
      this.NavItem('首页', 0)
      this.GenerateButton()
      this.NavItem('历史', 2)
    }
    .width('90%')
    .height(70)
    .backgroundColor('rgba(255, 255, 255, 0.75)')
    .backdropBlur(25)
    .borderRadius(35)
    .shadow({ radius: 20, color: 'rgba(44, 74, 104, 0.08)', offsetY: 8 })
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  NavItem(text: string, index: number) {
    Column() {
      Text(text)
        .fontSize(16)
        .fontWeight(this.curIndex === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.curIndex === index ? '#2C4A68' : '#8A959F')
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 切换高亮
      this.curIndex = index
      // 路由跳转
      if (index === 0) {
        router.pushUrl({ url: 'pages/Index' })
      } else if (index === 2) {
        router.pushUrl({ url: 'pages/HistoryCalendarPage' })
      }
    })
    .padding({ left: 20, right: 20 })
  }

  @Builder
  GenerateButton() {
    Button() {
      Row() {
        Text('✨').fontSize(18).margin({ right: 4 })
        Text('生成日记').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    }
    .linearGradient({ angle: 135, colors: [[0xFF9A76, 0.0], [0xFFC698, 1.0]] })
    .borderRadius(24)
    .shadow({ radius: 10, color: 'rgba(255, 154, 118, 0.4)', offsetY: 4 })
    .onClick(() => {
      this.showGenerationModal = true
    })
    .offset({ y: -20 })
  }
}