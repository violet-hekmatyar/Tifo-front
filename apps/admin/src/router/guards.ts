import type { NavigationGuard, RouteLocationNormalized } from 'vue-router'
import type { AuthStatus } from '@/stores/auth'

export interface AuthGuardStore {
  readonly status: AuthStatus
  readonly authenticated: boolean
  initialize(): Promise<void>
}

export function safeAdminRedirect(raw: unknown): string {
  if (typeof raw !== 'string' || !raw.startsWith('/admin/') || raw.startsWith('//')) {
    return '/admin/dashboard'
  }
  return raw
}

export function createAuthGuard(auth: AuthGuardStore): NavigationGuard {
  return async (to: RouteLocationNormalized) => {
    await auth.initialize()
    if (to.meta.requiresAdmin) {
      if (auth.authenticated) return true
      if (auth.status === 'forbidden') return { path: '/403', replace: true }
      if (auth.status === 'error') return { path: '/session-error', replace: true }
      return { path: '/login', query: { redirect: to.fullPath }, replace: true }
    }
    if (to.path === '/login' && auth.authenticated) {
      return { path: safeAdminRedirect(to.query.redirect), replace: true }
    }
    return true
  }
}
