import axios, { type AxiosInstance } from 'axios'
import type { AppEnvConfig } from '@/config/env.types'
import { installInterceptors, type RequestHeadersProvider } from './interceptors'

export function createHttpClient(
  config: AppEnvConfig,
  headersProvider: RequestHeadersProvider = () => ({}),
): AxiosInstance {
  const client = axios.create({
    baseURL: config.apiBaseUrl,
    timeout: 15_000,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
  })
  installInterceptors(client, headersProvider)
  return client
}
