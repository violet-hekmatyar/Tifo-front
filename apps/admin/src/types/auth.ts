export type RoleType = 'ADMIN' | 'USER' | string

export interface AdminUser {
  readonly id: number
  readonly username: string
  readonly nickname?: string
  readonly avatarUrl?: string
  readonly roleType: RoleType
  readonly status: string
}

export interface LoginSession {
  readonly accessToken: string
  readonly tokenType: string
  readonly expiresIn: number
  readonly user: AdminUser
}
