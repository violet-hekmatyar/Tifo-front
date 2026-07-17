import axios from 'axios'

export enum ApiErrorKind {
  Config = 'config',
  Network = 'network',
  Timeout = 'timeout',
  Cancelled = 'cancelled',
  Http = 'http',
  Business = 'business',
  Parse = 'parse',
  Unknown = 'unknown',
}

export interface AppErrorOptions {
  readonly cause?: unknown
  readonly statusCode?: number
  readonly businessCode?: number
  readonly traceId?: string
}

export class AppError extends Error {
  readonly kind: ApiErrorKind
  readonly statusCode?: number
  readonly businessCode?: number
  readonly traceId?: string
  readonly cause?: unknown

  constructor(kind: ApiErrorKind, message: string, options: AppErrorOptions = {}) {
    super(message)
    this.name = 'AppError'
    this.kind = kind
    this.statusCode = options.statusCode
    this.businessCode = options.businessCode
    this.traceId = options.traceId
    this.cause = options.cause
  }
}

export function normalizeRequestError(error: unknown): AppError {
  if (error instanceof AppError) return error
  if (!axios.isAxiosError(error)) {
    return new AppError(ApiErrorKind.Unknown, 'An unexpected API error occurred.', {
      cause: error,
    })
  }
  if (axios.isCancel(error) || error.code === 'ERR_CANCELED') {
    return new AppError(ApiErrorKind.Cancelled, 'The request was cancelled.', { cause: error })
  }
  if (
    error.code === 'ECONNABORTED' ||
    error.code === 'ETIMEDOUT' ||
    error.code === 'ERR_NETWORK_TIMEOUT'
  ) {
    return new AppError(ApiErrorKind.Timeout, 'The request timed out.', { cause: error })
  }
  if (error.response) {
    const raw = error.response.data as unknown
    const traceId =
      typeof raw === 'object' && raw !== null && 'traceId' in raw && typeof raw.traceId === 'string'
        ? raw.traceId
        : undefined
    return new AppError(ApiErrorKind.Http, `The server returned HTTP ${error.response.status}.`, {
      cause: error,
      statusCode: error.response.status,
      traceId,
    })
  }
  if (error.request || error.code === 'ERR_NETWORK' || error.message === 'Network Error') {
    return new AppError(ApiErrorKind.Network, 'Unable to connect to the server.', { cause: error })
  }
  return new AppError(ApiErrorKind.Unknown, 'An unexpected request error occurred.', {
    cause: error,
  })
}
