import { adminApiClient } from './runtime'
import { ApiErrorKind, AppError } from './errors'
import { isRecord } from './response'
import type { AdminUser, LoginSession } from '@/types/auth'

export interface AuthApiContract {
  login(username: string, password: string): Promise<LoginSession>
  me(): Promise<AdminUser>
}

export class AuthApi implements AuthApiContract {
  login(username: string, password: string): Promise<LoginSession> {
    return adminApiClient.post('/api/auth/login', {
      body: { username, password },
      decode: decodeLoginSession,
    })
  }

  me(): Promise<AdminUser> {
    return adminApiClient.get('/api/auth/me', { decode: decodeAdminUser })
  }
}

export const authApi: AuthApiContract = new AuthApi()

export function decodeAdminUser(raw: unknown): AdminUser {
  if (
    !isRecord(raw) ||
    typeof raw.id !== 'number' ||
    typeof raw.username !== 'string' ||
    typeof raw.roleType !== 'string' ||
    typeof raw.status !== 'string'
  ) {
    throw new AppError(ApiErrorKind.Parse, 'Invalid authenticated user response.')
  }
  return {
    id: raw.id,
    username: raw.username,
    nickname: typeof raw.nickname === 'string' && raw.nickname ? raw.nickname : undefined,
    avatarUrl: typeof raw.avatarUrl === 'string' && raw.avatarUrl ? raw.avatarUrl : undefined,
    roleType: raw.roleType,
    status: raw.status,
  }
}

function decodeLoginSession(raw: unknown): LoginSession {
  if (
    !isRecord(raw) ||
    typeof raw.accessToken !== 'string' ||
    !raw.accessToken ||
    typeof raw.tokenType !== 'string' ||
    typeof raw.expiresIn !== 'number'
  ) {
    throw new AppError(ApiErrorKind.Parse, 'Invalid login response.')
  }
  return {
    accessToken: raw.accessToken,
    tokenType: raw.tokenType,
    expiresIn: raw.expiresIn,
    user: decodeAdminUser(raw.user),
  }
}
