import { AxiosHeaders, type AxiosInstance } from 'axios'
import { normalizeRequestError } from './errors'

export type RequestHeadersProvider = () =>
  | Readonly<Record<string, string>>
  | Promise<Readonly<Record<string, string>>>

export function installInterceptors(
  client: AxiosInstance,
  headersProvider: RequestHeadersProvider,
): void {
  let sequence = 0
  client.interceptors.request.use(async (config) => {
    const extensionHeaders = await headersProvider()
    const headers = AxiosHeaders.from(config.headers)
    for (const [name, value] of Object.entries(extensionHeaders)) headers.set(name, value)
    if (!headers.has('X-Request-Id')) {
      headers.set('X-Request-Id', `admin-${Date.now()}-${sequence++}`)
    }
    config.headers = headers
    return config
  })
  client.interceptors.response.use(
    (response) => response,
    (error: unknown) => Promise.reject(normalizeRequestError(error)),
  )
}
