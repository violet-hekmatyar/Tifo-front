export const ADMIN_ACCESS_TOKEN_KEY = 'tifo.admin.access-token'

let stagedAccessToken: string | null = null

function storage(): Storage | null {
  return typeof window === 'undefined' ? null : window.sessionStorage
}

export function readAccessToken(): string | null {
  return stagedAccessToken ?? storage()?.getItem(ADMIN_ACCESS_TOKEN_KEY) ?? null
}

export function stageAccessToken(token: string): void {
  stagedAccessToken = token
}

export function commitAccessToken(): void {
  if (stagedAccessToken) storage()?.setItem(ADMIN_ACCESS_TOKEN_KEY, stagedAccessToken)
  stagedAccessToken = null
}

export function clearAccessToken(): void {
  stagedAccessToken = null
  storage()?.removeItem(ADMIN_ACCESS_TOKEN_KEY)
}
