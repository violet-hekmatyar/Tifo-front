import { createHttpClient } from './client'
import { notifyAuthError } from './auth-events'
import { ApiClient } from './request'
import { readEnvironment } from '@/config/env'
import { readAccessToken } from '@/utils/auth-storage'

export const adminEnvironment = readEnvironment()

export const adminHttpClient = createHttpClient(
  adminEnvironment,
  (): Readonly<Record<string, string>> => {
    const token = readAccessToken()
    return token ? { Authorization: `Bearer ${token}` } : {}
  },
)

export const adminApiClient = new ApiClient(adminEnvironment, adminHttpClient, notifyAuthError)
