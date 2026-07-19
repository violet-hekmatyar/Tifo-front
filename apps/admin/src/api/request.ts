import type { AxiosInstance } from 'axios'
import { requireApiBaseUrl } from '@/config/env'
import type { AppEnvConfig } from '@/config/env.types'
import { decodeApiResponse, type DataDecoder } from './response'
import { AppError } from './errors'

export type ApiErrorObserver = (error: AppError) => void

export interface RequestOptions<T> {
  readonly params?: Readonly<Record<string, unknown>>
  readonly body?: unknown
  readonly decode: DataDecoder<T>
}

export class ApiClient {
  constructor(
    private readonly config: AppEnvConfig,
    private readonly http: AxiosInstance,
    private readonly errorObserver?: ApiErrorObserver,
  ) {}

  get<T>(path: string, options: RequestOptions<T>): Promise<T> {
    return this.request('GET', path, options)
  }

  post<T>(path: string, options: RequestOptions<T>): Promise<T> {
    return this.request('POST', path, options)
  }

  put<T>(path: string, options: RequestOptions<T>): Promise<T> {
    return this.request('PUT', path, options)
  }

  patch<T>(path: string, options: RequestOptions<T>): Promise<T> {
    return this.request('PATCH', path, options)
  }

  delete<T>(path: string, options: RequestOptions<T>): Promise<T> {
    return this.request('DELETE', path, options)
  }

  private async request<T>(
    method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE',
    path: string,
    options: RequestOptions<T>,
  ): Promise<T> {
    requireApiBaseUrl(this.config)
    try {
      const response = await this.http.request<unknown>({
        method,
        url: path,
        params: options.params,
        data: options.body,
      })
      return decodeApiResponse(response.data, options.decode).data
    } catch (error) {
      if (error instanceof AppError) this.errorObserver?.(error)
      throw error
    }
  }
}
