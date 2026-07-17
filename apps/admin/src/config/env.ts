import { ApiErrorKind, AppError } from '@/api/errors'
import type { AppEnvConfig, AppEnvironment, EnvironmentSource } from './env.types'

const environments = new Set<AppEnvironment>(['development', 'test', 'production'])

export function parseEnvironment(source: EnvironmentSource): AppEnvConfig {
  const rawEnvironment = (source.VITE_APP_ENV ?? 'development').trim().toLowerCase()
  if (!environments.has(rawEnvironment as AppEnvironment)) {
    throw new AppError(
      ApiErrorKind.Config,
      `VITE_APP_ENV must be development, test, or production; received "${source.VITE_APP_ENV}".`,
    )
  }

  const rawBaseUrl = source.VITE_API_BASE_URL?.trim()
  if (!rawBaseUrl) {
    return { environment: rawEnvironment as AppEnvironment }
  }
  let url: URL
  try {
    url = new URL(rawBaseUrl)
  } catch (cause) {
    throw new AppError(ApiErrorKind.Config, 'VITE_API_BASE_URL must be an absolute URL.', {
      cause,
    })
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new AppError(ApiErrorKind.Config, 'VITE_API_BASE_URL must use http or https.')
  }
  return {
    environment: rawEnvironment as AppEnvironment,
    apiBaseUrl: url.toString().replace(/\/$/, ''),
  }
}

export function readEnvironment(): AppEnvConfig {
  return parseEnvironment(import.meta.env)
}

export function requireApiBaseUrl(config: AppEnvConfig): string {
  if (!config.apiBaseUrl) {
    throw new AppError(
      ApiErrorKind.Config,
      'VITE_API_BASE_URL is required before an API request can be sent.',
    )
  }
  return config.apiBaseUrl
}
