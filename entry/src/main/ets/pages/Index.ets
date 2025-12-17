import HomeHeader from '../components/HomeHeader';
import StackSlideCardList from "../components/StackSlideCardList";
import BottomNavBar from "../components/BottomNavBar";
import DiaryGenerationModal from '../components/DiaryGenerationModal';
import AddRecordModal from '../components/AddRecordModal';
import { AddRecordHandlers } from '../common/AddRecordHandlers';
import { DiaryGenHandlers } from '../common/DiaryGenHandlers';
import { RecordRepository } from '../data/RecordRepository'
import { SimpleDiaryRecord } from '../common/SimpleDiaryRecord'
import { DiaryConfig } from '../common/DiaryConfig';
import { AiDiaryRepository } from '../data/AiDiaryRepository';
import { GenerationService , GenerateAndSaveResult} from '../utils/GenerationService';

@Entry
@Component
struct MainPage {
  @State showGenerationModal: boolean = false;
  @State showAddRecordDialog: boolean = false

  @State generating: boolean = false;
  @State errorMsg: string = '';

  private bg: Resource = $r('app.media.bg');

  @State todayRecords: SimpleDiaryRecord[] = []
  private repo: RecordRepository = new RecordRepository();
  private aiRepo: AiDiaryRepository = new AiDiaryRepository();
  private service: GenerationService = new GenerationService(this.aiRepo, 'http://10.135.105.183:3000');

  aboutToAppear() {
    // 首次进入页面初始化 DB 并加载今日数据
    this.initDbAndLoadToday()
  }

  private async initDbAndLoadToday() {
    await this.refreshToday()
  }

  private todayDateStr(): string {
    const d = new Date()
    const pad = (n: number) => (n < 10 ? '0' + n : '' + n)
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
  }

  private async refreshToday() {
    this.todayRecords = await this.repo.queryToday(this.todayDateStr())
    console.info(`[DB] today count = ${this.todayRecords.length}`)
  }

  private modalHandlers(): AddRecordHandlers {
    return {
      onCancel: () => { this.showAddRecordDialog = false },
      onSave: async (rec: SimpleDiaryRecord) => {
        await this.repo.insert(rec)
        this.showAddRecordDialog = false
        await this.refreshToday()
      }
    }
  }

  private async generateFlow(config: DiaryConfig): Promise<void> {
    if (this.generating) return;
    this.generating = true;
    this.errorMsg = '';

    try {
      const date = this.todayDateStr();
      const GeneratedDestructObj_1: GenerateAndSaveResult =
        await this.service.generateAndSave(date, this.todayRecords, config);
      const diary = GeneratedDestructObj_1.diary;
      const error = GeneratedDestructObj_1.error;

      if (error || !diary) {
        this.errorMsg = error ?? '生成结果为空';
        console.error('[Gen] 失败：', this.errorMsg);
        return;
      }

      console.info('[Gen] 成功并入库：', date);
      // 可选：生成成功后关闭弹窗、刷新、跳转
      this.showGenerationModal = false;
      // await this.refreshToday(); // 如需刷新列表
      // TODO: 跳转到详情页或弹出“生成成功”提示
    } catch (e) {
      this.errorMsg = String(e);
      console.error('[Gen] 异常：', this.errorMsg);
    } finally {
      this.generating = false;
    }
  }
  private diaryGenHandlers(): DiaryGenHandlers {
    return {
      onClose: () => {
        this.showGenerationModal = false
      },
      onGenerate: (config: DiaryConfig) => {
        // 可选：无记录时给出提示
        if (this.todayRecords.length === 0) {
          this.errorMsg = '今天没有素材，请先添加一条记录';
          console.warn('[Gen] 空素材阻断');
          return;
        }
        this.generateFlow(config).then(() => {});
      }
    }
  }

  @Builder
  AddRecordButton() {
    Button() {
      Row() {
        Text('+')
          .fontSize(24)
          .fontColor('#5D5652')
          .fontWeight(FontWeight.Lighter)
          .margin({ right: 8 })

        Text('记一笔')
          .fontSize(16)
          .fontColor('#5D5652')
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: 20, right: 24, top: 12, bottom: 12 })
    }
    .backgroundColor('rgba(255, 255, 255, 0.65)')
    .backdropBlur(15)
    .borderRadius(30)
    .shadow({ radius: 10, color: 'rgba(166, 145, 129, 0.15)', offsetY: 4 })
    .margin({ bottom: 30 })
    .onClick(() => {
      console.info('[UI] AddRecordButton clicked')
      this.showAddRecordDialog = true
    })
  }

  build() {
    Stack() {
      Image(this.bg).width('100%').height('100%').objectFit(ImageFit.Cover)

      Column() {
        HomeHeader()

        if (!this.showAddRecordDialog) {
          StackSlideCardList({ records: this.todayRecords }).layoutWeight(1).margin({ top: 10 })
        } else {
          Blank().layoutWeight(1)
        }

        this.AddRecordButton()
        Blank().height(80)
      }
      .width('100%').height('100%')

      Column() {
        BottomNavBar({ showGenerationModal: $showGenerationModal })
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.End)
      .padding({ bottom: 20 })
      .hitTestBehavior(HitTestMode.Transparent)

      if (this.showGenerationModal) {
        DiaryGenerationModal({ isVisible: $showGenerationModal, handlers: this.diaryGenHandlers() })
      }

      if (this.showAddRecordDialog) {
        AddRecordModal({ isVisible: true, handlers: this.modalHandlers() })
      }
    }
    .width('100%').height('100%')
  }
}