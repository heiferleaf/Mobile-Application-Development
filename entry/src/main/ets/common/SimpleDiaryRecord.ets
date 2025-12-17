import { DiaryConfig } from "./DiaryConfig"

export interface SimpleDiaryRecord {
  id: string
  type: 'text' | 'image' | 'voice'
  time: string
  location?: string
  content: string
  imageUrl?: string
}

export interface MediaPolicy {
  includeImageContext: boolean;
  uploadImages: boolean;
}

export interface GenerateDiaryRequest {
  date: string; // YYYY-MM-DD
  records: SimpleDiaryRecord[];
  options:DiaryConfig;
  mediaPolicy: MediaPolicy;
}

export interface DiarySection {
  name: string;
  text: string;
}

export interface DiaryImagePlacement {
  // 关联到本地图片记录（用于拿 imageUrl）
  recordId: string;
  // 图片插入到哪个段落（0 开始，对应 sections 下标）
  sectionIndex: number;
  // 图片说明文字（可选）
  caption?: string;
  // 段落中的某词/短语之后插入（可选）
  anchorText?: string;
  // 未来开启图片上传后，后端可返回远端图片地址（首期不使用）
  remoteUrl?: string;
}

export interface DiaryPayload {
  date: string;
  title: string;
  // 结构化段落；当不分段时可为空，改用 content
  sections: DiarySection[];
  // 完整正文；当不分段时使用，或为 sections 的拼接
  content: string;
  // 标签列表
  tags: string[];
  // 图片插入位置与说明
  images: DiaryImagePlacement[];
  // 提示词快照（便于排查生成质量）
  promptEcho: string;
}

export interface GenerateDiaryMetrics {
  model: string;
  latencyMs: number;
  tokensInput?: number;
  tokensOutput?: number;
}

export interface GenerateDiaryError {
  code: string;
  message: string;
  retryable: boolean;
}

export interface GenerateDiaryResponse {
  diary?: DiaryPayload;
  metrics?: GenerateDiaryMetrics;
  error?: GenerateDiaryError;
}

// 4)（可选）前端渲染计划：把图片插入段落的具体位置（用于 ArkUI 渲染）
export type RenderNodeType = 'text' | 'image' | 'caption';

export interface RenderNode {
  type: RenderNodeType;
  content?: string;         // 文本或说明
  imageUrl?: string;        // 本地/系统相册 URI（由 recordId 映射得到）
}

export interface SectionRenderPlan {
  title?: string;           // 小标题（当 showTitles=true）
  nodes: RenderNode[];      // 渲染节点序列：text -> image -> caption -> text ...
}