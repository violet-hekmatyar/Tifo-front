import type { AdminUser } from '@/types/auth'

export function isAdmin(user: AdminUser | null | undefined): boolean {
  return user?.roleType === 'ADMIN'
}
