import { DiaryConfig, DiaryOptionItem } from './DiaryConfig';
import { SimpleDiaryRecord } from './SimpleDiaryRecord';

export interface DiaryGenHandlers {
  onClose?: () => void
  onToggleItem?: (item: DiaryOptionItem) => void
  onDeleteItem?: (id: string) => void
  onAddContent?: () => void
  onAddStyle?: () => void
  onToggleAddingContent?: () => void
  onToggleAddingStyle?: () => void
  onCustomInstructionsChange?: (val: string) => void
  onGenerate?: (config: DiaryConfig) => void
}