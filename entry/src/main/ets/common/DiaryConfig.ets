
// 【修复核心】统一使用一个具体的类，避免 @ObjectLink 的继承问题
@Observed
export class DiaryOptionItem {
  id: string;
  name: string;
  enabled: boolean;
  order: number;

  constructor(id: string, name: string, enabled: boolean, order: number) {
    this.id = id;
    this.name = name;
    this.enabled = enabled;
    this.order = order;
  }
}

// 以下接口用于 StorageManager 的数据传输（保持不变）
export interface ContentBlock {
  id: string;
  name: string;
  enabled: boolean;
  order: number;
}

export interface DiaryStyle {
  id: string;
  name: string;
  enabled: boolean;
  order: number;
}

export interface OutputOptions {
  length: 'short' | 'medium' | 'long';
  showTitles: boolean;
}

export interface DiaryConfig {
  contentBlocks: ContentBlock[];
  diaryStyles: DiaryStyle[];
  outputOptions: OutputOptions;
  customInstructions: string;
}

// 预设数据
export const PRESET_CONTENT_BLOCKS: ContentBlock[] = [
  { id: 'life', name: '生活记录', enabled: true, order: 0 },
  { id: 'study', name: '学习内容', enabled: true, order: 1 },
  { id: 'work', name: '工作总结', enabled: true, order: 2 },
  { id: 'emotion', name: '情绪分析', enabled: true, order: 3 },
  { id: 'plan', name: '明日计划', enabled: true, order: 4 },
  { id: 'growth', name: '成长反思', enabled: true, order: 5 }
];

export const PRESET_DIARY_STYLES: DiaryStyle[] = [
  { id: 'humor', name: '幽默风趣', enabled: true, order: 0 },
  { id: 'objective', name: '客观理性', enabled: true, order: 1 },
  { id: 'warm', name: '暖心细腻', enabled: true, order: 2 },
  { id: 'concise', name: '简洁提要', enabled: true, order: 3 },
  { id: 'inspiring', name: '激励鸡汤', enabled: true, order: 4 },
  { id: 'poetic', name: '诗意浪漫', enabled: true, order: 5 }
];