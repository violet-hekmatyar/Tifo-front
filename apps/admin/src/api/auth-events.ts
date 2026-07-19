import type { AppError } from './errors'

export type AuthErrorHandler = (error: AppError) => void

let handler: AuthErrorHandler | undefined

export function setAuthErrorHandler(next: AuthErrorHandler | undefined): void {
  handler = next
}

export function notifyAuthError(error: AppError): void {
  handler?.(error)
}
