import { ApiErrorKind, AppError } from './errors'

export interface ApiResponse<T> {
  readonly code: number
  readonly message: string
  readonly data: T
  readonly traceId?: string
}

export type DataDecoder<T> = (raw: unknown) => T

export function decodeApiResponse<T>(raw: unknown, decodeData: DataDecoder<T>): ApiResponse<T> {
  if (!isRecord(raw) || typeof raw.code !== 'number' || typeof raw.message !== 'string') {
    throw new AppError(
      ApiErrorKind.Parse,
      'API response requires numeric code and string message fields.',
    )
  }
  if (raw.traceId !== undefined && raw.traceId !== null && typeof raw.traceId !== 'string') {
    throw new AppError(ApiErrorKind.Parse, 'API response traceId must be a string.')
  }
  const traceId = typeof raw.traceId === 'string' ? raw.traceId : undefined
  if (raw.code !== 0) {
    throw new AppError(ApiErrorKind.Business, raw.message, {
      businessCode: raw.code,
      traceId,
    })
  }
  try {
    return {
      code: raw.code,
      message: raw.message,
      data: decodeData(raw.data),
      traceId,
    }
  } catch (cause) {
    if (cause instanceof AppError) throw cause
    throw new AppError(ApiErrorKind.Parse, 'Failed to decode API response data.', { cause })
  }
}

export function decodeVoid(_raw: unknown): void {}

export function decodeList<T>(raw: unknown, decodeItem: DataDecoder<T>): readonly T[] {
  if (!Array.isArray(raw)) {
    throw new AppError(ApiErrorKind.Parse, 'Expected a JSON array.')
  }
  return raw.map(decodeItem)
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}
