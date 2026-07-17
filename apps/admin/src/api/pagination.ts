import { ApiErrorKind, AppError } from './errors'
import type { DataDecoder } from './response'
import { isRecord } from './response'

export interface PageResult<T> {
  readonly records: readonly T[]
  readonly total: number
  readonly pageNum: number
  readonly pageSize: number
  readonly pages: number
}

export function decodePageResult<T>(raw: unknown, decodeItem: DataDecoder<T>): PageResult<T> {
  if (
    !isRecord(raw) ||
    !Array.isArray(raw.records) ||
    typeof raw.total !== 'number' ||
    typeof raw.pageNum !== 'number' ||
    typeof raw.pageSize !== 'number' ||
    typeof raw.pages !== 'number'
  ) {
    throw new AppError(ApiErrorKind.Parse, 'Page data has invalid fields.')
  }
  try {
    return {
      records: raw.records.map(decodeItem),
      total: raw.total,
      pageNum: raw.pageNum,
      pageSize: raw.pageSize,
      pages: raw.pages,
    }
  } catch (cause) {
    if (cause instanceof AppError) throw cause
    throw new AppError(ApiErrorKind.Parse, 'Failed to decode page records.', { cause })
  }
}
