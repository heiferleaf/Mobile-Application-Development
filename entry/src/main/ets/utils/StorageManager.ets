import { DiaryConfig, PRESET_CONTENT_BLOCKS, PRESET_DIARY_STYLES } from '../common/DiaryConfig';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class StorageManager {
  private static readonly FILE_NAME = 'diary_config';
  private static readonly KEY_CONFIG = 'diary_generation_config';
  private static ctx: common.UIAbilityContext | null = null;

  // 统一入口：在 EntryAbility 里调用一次
  static setContext(ctx: common.UIAbilityContext): void {
    StorageManager.ctx = ctx;
    console.info('[SM] context set');
  }

  static getDefaultConfig(): DiaryConfig {
    return {
      contentBlocks: [...PRESET_CONTENT_BLOCKS],
      diaryStyles: [...PRESET_DIARY_STYLES],
      outputOptions: { length: 'medium', showTitles: true },
      customInstructions: ''
    };
  }

  // 读取：无数据则返回 null（由调用者决定是否写入默认）
  static async loadConfig(): Promise<DiaryConfig | null> {
    if (!StorageManager.ctx) {
      console.warn('[SM] loadConfig: context is null');
      return null;
    }
    const pref = await preferences.getPreferences(StorageManager.ctx, StorageManager.FILE_NAME);
    const raw = await pref.get(StorageManager.KEY_CONFIG, '') as string;
    if (!raw) {
      console.info('[SM] loadConfig: empty, return null');
      return null;
    }
    try {
      const cfg = JSON.parse(raw) as DiaryConfig;
      console.info(`[SM] loadConfig: ok, blocks=${cfg.contentBlocks.length}, styles=${cfg.diaryStyles.length}`);
      return cfg;
    } catch (e) {
      console.error('[SM] loadConfig: parse error, return null', e);
      return null;
    }
  }

  // 保存：调用方确保对象正确
  static async saveConfig(cfg: DiaryConfig): Promise<void> {
    if (!StorageManager.ctx) {
      console.warn('[SM] saveConfig: context is null, skip');
      return;
    }
    const pref = await preferences.getPreferences(StorageManager.ctx, StorageManager.FILE_NAME);
    const raw = JSON.stringify(cfg);
    await pref.put(StorageManager.KEY_CONFIG, raw);
    await pref.flush();
    console.info('[SM] saveConfig: ok');
  }

  // 工具：读取或初始化（无则写入默认并返回默认）
  static async loadOrInitDefault(): Promise<DiaryConfig> {
    const loaded = await StorageManager.loadConfig();
    if (loaded) {
      return loaded;
    }
    const def = StorageManager.getDefaultConfig();
    await StorageManager.saveConfig(def);
    console.info('[SM] init default and saved');
    return def;
  }
}