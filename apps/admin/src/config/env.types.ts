export type AppEnvironment = 'development' | 'test' | 'production'

export interface AppEnvConfig {
  readonly environment: AppEnvironment
  readonly apiBaseUrl?: string
}

export type EnvironmentSource = Readonly<{
  VITE_APP_ENV?: string
  VITE_API_BASE_URL?: string
}>
