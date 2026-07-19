import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import MockAdapter from 'axios-mock-adapter'

import type { AuthApiContract } from '@/api/auth'
import { createHttpClient } from '@/api/client'
import { ApiErrorKind, AppError } from '@/api/errors'
import { createAuthGuard, safeAdminRedirect } from '@/router/guards'
import { useAuthStore } from '@/stores/auth'
import type { AdminUser, LoginSession } from '@/types/auth'
import { ADMIN_ACCESS_TOKEN_KEY, clearAccessToken, readAccessToken } from '@/utils/auth-storage'

const admin: AdminUser = {
  id: 1,
  username: 'admin_user',
  nickname: '管理员',
  roleType: 'ADMIN',
  status: 'ACTIVE',
}
const user: AdminUser = { id: 2, username: 'normal_user', roleType: 'USER', status: 'ACTIVE' }

describe('F08 auth store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    clearAccessToken()
    sessionStorage.clear()
  })

  it('validates ADMIN with /auth/me before committing token', async () => {
    const store = useAuthStore()
    store.setApiForTesting(api({ loginUser: admin, meUser: admin }))
    expect(await store.login('admin_user', 'secret-value')).toBe(true)
    expect(store.authenticated).toBe(true)
    expect(sessionStorage.getItem(ADMIN_ACCESS_TOKEN_KEY)).toBe('test-access-token')
    expect(JSON.stringify(sessionStorage)).not.toContain('secret-value')
  })

  it('rejects USER and never persists its access token', async () => {
    const store = useAuthStore()
    store.setApiForTesting(api({ loginUser: user, meUser: user }))
    expect(await store.login('normal_user', 'secret-value')).toBe(false)
    expect(store.status).toBe('forbidden')
    expect(store.message).toContain('没有后台管理权限')
    expect(sessionStorage.getItem(ADMIN_ACCESS_TOKEN_KEY)).toBeNull()
  })

  it('bootstraps no token, ADMIN, USER, 401 and network errors correctly', async () => {
    const empty = useAuthStore()
    empty.setApiForTesting(api({ meUser: admin }))
    await empty.initialize()
    expect(empty.status).toBe('unauthenticated')

    for (const [current, expected] of [
      [admin, 'authenticated'],
      [user, 'forbidden'],
    ] as const) {
      setActivePinia(createPinia())
      sessionStorage.setItem(ADMIN_ACCESS_TOKEN_KEY, 'stored')
      const store = useAuthStore()
      store.setApiForTesting(api({ meUser: current }))
      await store.initialize()
      expect(store.status).toBe(expected)
    }

    setActivePinia(createPinia())
    sessionStorage.setItem(ADMIN_ACCESS_TOKEN_KEY, 'stored')
    const expired = useAuthStore()
    expired.setApiForTesting(
      api({ meError: new AppError(ApiErrorKind.Business, 'expired', { businessCode: 40101 }) }),
    )
    await expired.initialize()
    expect(expired.status).toBe('unauthenticated')
    expect(sessionStorage.getItem(ADMIN_ACCESS_TOKEN_KEY)).toBeNull()

    setActivePinia(createPinia())
    sessionStorage.setItem(ADMIN_ACCESS_TOKEN_KEY, 'stored')
    const offline = useAuthStore()
    offline.setApiForTesting(api({ meError: new AppError(ApiErrorKind.Network, 'offline') }))
    await offline.initialize()
    expect(offline.status).toBe('error')
    expect(sessionStorage.getItem(ADMIN_ACCESS_TOKEN_KEY)).toBe('stored')
  })

  it('prevents duplicate login and clears state on logout', async () => {
    let resolveLogin: ((session: LoginSession) => void) | undefined
    const pending = new Promise<LoginSession>((resolve) => {
      resolveLogin = resolve
    })
    const store = useAuthStore()
    store.setApiForTesting({
      login: vi.fn<AuthApiContract['login']>(() => pending),
      me: vi.fn<AuthApiContract['me']>(async () => admin),
    })
    const first = store.login('admin_user', 'secret')
    expect(await store.login('admin_user', 'secret')).toBe(false)
    resolveLogin?.(session(admin))
    expect(await first).toBe(true)
    store.logout()
    expect(store.status).toBe('unauthenticated')
    expect(sessionStorage.getItem(ADMIN_ACCESS_TOKEN_KEY)).toBeNull()
  })

  it('injects a non-empty Bearer only and deduplicates 401 handling', async () => {
    const http = createHttpClient(
      { environment: 'test', apiBaseUrl: 'https://api.example.test' },
      (): Readonly<Record<string, string>> => {
        const token = readAccessToken()
        return token ? { Authorization: `Bearer ${token}` } : {}
      },
    )
    const mock = new MockAdapter(http)
    mock.onGet('/first').reply(200, { code: 0, message: 'ok', data: null })
    await http.get('/first')
    const firstHeaders = mock.history.get[0]?.headers as Record<string, unknown> | undefined
    expect(firstHeaders?.Authorization).toBeUndefined()
    sessionStorage.setItem(ADMIN_ACCESS_TOKEN_KEY, 'stored')
    await http.get('/first')
    const secondHeaders = mock.history.get[1]?.headers as Record<string, unknown> | undefined
    expect(secondHeaders?.Authorization).toBe('Bearer stored')

    const store = useAuthStore()
    const unauthorized = new AppError(ApiErrorKind.Business, 'expired', { businessCode: 40101 })
    expect(store.handleApiError(unauthorized)).toBe('login')
    expect(store.handleApiError(unauthorized)).toBeNull()
    expect(sessionStorage.getItem(ADMIN_ACCESS_TOKEN_KEY)).toBeNull()
    sessionStorage.setItem(ADMIN_ACCESS_TOKEN_KEY, 'preserved')
    expect(
      store.handleApiError(new AppError(ApiErrorKind.Business, 'denied', { businessCode: 40301 })),
    ).toBe('forbidden')
    expect(sessionStorage.getItem(ADMIN_ACCESS_TOKEN_KEY)).toBe('preserved')
  })
})

describe('F08 route guard', () => {
  it('routes unauthenticated, USER and ADMIN without loops', async () => {
    const route = (path: string, requiresAdmin = true) =>
      ({ path, fullPath: path, meta: { requiresAdmin }, query: {} }) as never
    const unauthenticated = {
      status: 'unauthenticated',
      authenticated: false,
      initialize: vi.fn<() => Promise<void>>(async () => {}),
    } as const
    expect(
      await createAuthGuard(unauthenticated)(route('/admin/users'), route('/'), vi.fn()),
    ).toMatchObject({ path: '/login' })
    const forbidden = {
      status: 'forbidden',
      authenticated: false,
      initialize: vi.fn<() => Promise<void>>(async () => {}),
    } as const
    expect(
      await createAuthGuard(forbidden)(route('/admin/users'), route('/'), vi.fn()),
    ).toMatchObject({ path: '/403' })
    const allowed = {
      status: 'authenticated',
      authenticated: true,
      initialize: vi.fn<() => Promise<void>>(async () => {}),
    } as const
    expect(await createAuthGuard(allowed)(route('/admin/users'), route('/'), vi.fn())).toBe(true)
  })

  it('allows only internal admin redirect paths', () => {
    expect(safeAdminRedirect('/admin/users')).toBe('/admin/users')
    expect(safeAdminRedirect('https://evil.example')).toBe('/admin/dashboard')
    expect(safeAdminRedirect('//evil.example/admin/users')).toBe('/admin/dashboard')
  })
})

function api(options: {
  loginUser?: AdminUser
  meUser?: AdminUser
  meError?: AppError
}): AuthApiContract {
  return {
    login: vi.fn<AuthApiContract['login']>(async () => session(options.loginUser ?? admin)),
    me: vi.fn<AuthApiContract['me']>(async () => {
      if (options.meError) throw options.meError
      return options.meUser ?? admin
    }),
  }
}

function session(current: AdminUser): LoginSession {
  return { accessToken: 'test-access-token', tokenType: 'Bearer', expiresIn: 3600, user: current }
}
