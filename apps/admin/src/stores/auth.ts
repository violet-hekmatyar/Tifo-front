import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

import { authApi, type AuthApiContract } from '@/api/auth'
import { ApiErrorKind, type AppError } from '@/api/errors'
import type { AdminUser } from '@/types/auth'
import {
  clearAccessToken,
  commitAccessToken,
  readAccessToken,
  stageAccessToken,
} from '@/utils/auth-storage'
import { isAdmin } from '@/utils/role'

export type AuthStatus =
  | 'idle'
  | 'bootstrapping'
  | 'unauthenticated'
  | 'authenticated'
  | 'forbidden'
  | 'error'

export const useAuthStore = defineStore('auth', () => {
  const status = ref<AuthStatus>('idle')
  const user = ref<AdminUser | null>(null)
  const message = ref<string | null>(null)
  const submitting = ref(false)
  let initialized = false
  let accessFailureHandled = false
  let api: AuthApiContract = authApi

  const authenticated = computed(() => status.value === 'authenticated' && isAdmin(user.value))

  async function initialize(force = false): Promise<void> {
    if (initialized && !force) return
    initialized = true
    message.value = null
    if (!readAccessToken()) {
      status.value = 'unauthenticated'
      user.value = null
      return
    }
    status.value = 'bootstrapping'
    try {
      const current = await api.me()
      user.value = current
      status.value = isAdmin(current) ? 'authenticated' : 'forbidden'
      if (!isAdmin(current)) clearAccessToken()
    } catch (error) {
      handleBootstrapError(error)
    }
  }

  async function login(username: string, password: string): Promise<boolean> {
    if (submitting.value) return false
    submitting.value = true
    message.value = null
    clearAccessToken()
    accessFailureHandled = false
    try {
      const session = await api.login(username.trim(), password)
      stageAccessToken(session.accessToken)
      const current = await api.me()
      if (!isAdmin(current)) {
        clearAccessToken()
        user.value = current
        status.value = 'forbidden'
        message.value = '当前账号没有后台管理权限。'
        return false
      }
      commitAccessToken()
      user.value = current
      status.value = 'authenticated'
      return true
    } catch (error) {
      clearAccessToken()
      user.value = null
      status.value = 'unauthenticated'
      message.value = errorMessage(error)
      return false
    } finally {
      submitting.value = false
    }
  }

  function logout(): void {
    clearAccessToken()
    user.value = null
    message.value = null
    status.value = 'unauthenticated'
    accessFailureHandled = false
  }

  function handleApiError(error: AppError): 'login' | 'forbidden' | null {
    const unauthorized =
      error.statusCode === 401 || error.businessCode === 40101 || error.businessCode === 40102
    if (unauthorized) {
      if (accessFailureHandled) return null
      logout()
      accessFailureHandled = true
      return 'login'
    }
    if (error.statusCode === 403 || error.businessCode === 40301) return 'forbidden'
    return null
  }

  function handleBootstrapError(error: unknown): void {
    const appError = error as AppError
    if (
      appError.statusCode === 401 ||
      appError.businessCode === 40101 ||
      appError.businessCode === 40102
    ) {
      logout()
      return
    }
    if (appError.statusCode === 403 || appError.businessCode === 40301) {
      status.value = 'forbidden'
      return
    }
    status.value = 'error'
    message.value = errorMessage(error)
  }

  function retryBootstrap(): Promise<void> {
    initialized = false
    return initialize(true)
  }

  function setApiForTesting(next: AuthApiContract): void {
    api = next
    initialized = false
  }

  return {
    status,
    user,
    message,
    submitting,
    authenticated,
    initialize,
    retryBootstrap,
    login,
    logout,
    handleApiError,
    setApiForTesting,
  }
})

function errorMessage(error: unknown): string {
  const appError = error as AppError
  if (appError.businessCode === 40103) return '登录失败次数过多，请稍后再试。'
  if (appError.kind === ApiErrorKind.Network) return '网络连接失败，请检查后重试。'
  if (appError.kind === ApiErrorKind.Timeout) return '请求超时，请稍后重试。'
  if (appError.kind === ApiErrorKind.Business && appError.message) return appError.message
  return '请求失败，请稍后重试。'
}
