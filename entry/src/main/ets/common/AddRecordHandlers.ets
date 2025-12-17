// 仅定义类型接口，不包含逻辑
import { SimpleDiaryRecord } from './SimpleDiaryRecord';

export interface AddRecordHandlers {
  onCancel?: () => void
  onSave?: (rec: SimpleDiaryRecord) => void
}