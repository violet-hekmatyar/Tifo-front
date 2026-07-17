import { describe, expect, it } from 'vitest'
import { parseEnvironment, requireApiBaseUrl } from '@/config/env'
import { ApiErrorKind, AppError } from '@/api/errors'

describe('environment configuration', () => {
  it.each(['development', 'test', 'production'] as const)('supports %s', (environment) => {
    expect(parseEnvironment({ VITE_APP_ENV: environment }).environment).toBe(environment)
  })

  it('rejects an invalid environment', () => {
    expect(() => parseEnvironment({ VITE_APP_ENV: 'staging' })).toThrowError(AppError)
  })

  it('allows a missing base URL until a request needs it', () => {
    const config = parseEnvironment({ VITE_APP_ENV: 'development' })
    expect(config.apiBaseUrl).toBeUndefined()
    expect(() => requireApiBaseUrl(config)).toThrowError(
      expect.objectContaining({ kind: ApiErrorKind.Config }),
    )
  })

  it('rejects invalid and non-http base URLs', () => {
    expect(() => parseEnvironment({ VITE_API_BASE_URL: 'localhost:8080' })).toThrowError(
      expect.objectContaining({ kind: ApiErrorKind.Config }),
    )
    expect(() => parseEnvironment({ VITE_API_BASE_URL: 'file:///tmp/api' })).toThrowError(
      expect.objectContaining({ kind: ApiErrorKind.Config }),
    )
  })
})
