import { AxiosError, AxiosHeaders, CanceledError } from 'axios'
import MockAdapter from 'axios-mock-adapter'
import { beforeEach, describe, expect, it } from 'vitest'
import { createHttpClient } from '@/api/client'
import { ApiErrorKind, AppError, normalizeRequestError } from '@/api/errors'
import { decodePageResult } from '@/api/pagination'
import { ApiClient } from '@/api/request'
import { decodeList, decodeVoid, isRecord } from '@/api/response'
import type { AppEnvConfig } from '@/config/env.types'

interface User {
  readonly id: number
  readonly name: string
}

const config: AppEnvConfig = {
  environment: 'test',
  apiBaseUrl: 'https://api.example.test',
}

function decodeUser(raw: unknown): User {
  if (!isRecord(raw) || typeof raw.id !== 'number' || typeof raw.name !== 'string') {
    throw new TypeError('Invalid user JSON.')
  }
  return { id: raw.id, name: raw.name }
}

describe('API client', () => {
  let mock: MockAdapter
  let client: ApiClient

  beforeEach(() => {
    const http = createHttpClient(config)
    mock = new MockAdapter(http)
    client = new ApiClient(config, http)
  })

  it('decodes object, list, void, and page responses without leaking unknown', async () => {
    mock
      .onGet('/user')
      .reply(200, envelope({ id: 1, name: 'Tifo' }))
      .onGet('/users')
      .reply(200, envelope([{ id: 2, name: 'South Stand' }]))
      .onDelete('/user/1')
      .reply(200, envelope(null))
      .onGet('/users/page')
      .reply(
        200,
        envelope({
          records: [{ id: 3, name: 'Page User' }],
          total: 1,
          pageNum: 1,
          pageSize: 10,
          pages: 1,
        }),
      )

    const user = await client.get('/user', { decode: decodeUser })
    const users = await client.get('/users', {
      decode: (raw) => decodeList(raw, decodeUser),
    })
    await client.delete('/user/1', { decode: decodeVoid })
    const page = await client.get('/users/page', {
      decode: (raw) => decodePageResult(raw, decodeUser),
    })

    expect(user.name).toBe('Tifo')
    expect(users[0]?.name).toBe('South Stand')
    expect(page.records[0]?.name).toBe('Page User')
    expect(page.total).toBe(1)
  })

  it('supports POST, PUT, and PATCH with JSON bodies', async () => {
    const body = { name: 'Updated' }
    mock
      .onPost('/users', body)
      .reply(200, envelope({ id: 1, ...body }))
      .onPut('/users/1', body)
      .reply(200, envelope({ id: 1, ...body }))
      .onPatch('/users/1', body)
      .reply(200, envelope({ id: 1, ...body }))

    for (const action of [
      client.post('/users', { body, decode: decodeUser }),
      client.put('/users/1', { body, decode: decodeUser }),
      client.patch('/users/1', { body, decode: decodeUser }),
    ]) {
      expect((await action).name).toBe('Updated')
    }
  })

  it('maps business errors and malformed payloads', async () => {
    mock
      .onGet('/business')
      .reply(200, { code: 40001, message: 'bad input', data: null, traceId: 'business' })
      .onGet('/malformed')
      .reply(200, { unexpected: true })

    await expect(client.get('/business', { decode: decodeVoid })).rejects.toMatchObject({
      kind: ApiErrorKind.Business,
      businessCode: 40001,
      traceId: 'business',
    })
    await expect(client.get('/malformed', { decode: decodeVoid })).rejects.toMatchObject({
      kind: ApiErrorKind.Parse,
    })
  })

  it.each([401, 403])('normalizes HTTP %s without auth or router side effects', async (status) => {
    mock.onGet(`/http-${status}`).reply(status, {
      code: status === 401 ? 40101 : 40301,
      message: 'denied',
      data: null,
      traceId: `trace-${status}`,
    })

    await expect(client.get(`/http-${status}`, { decode: decodeVoid })).rejects.toMatchObject({
      kind: ApiErrorKind.Http,
      statusCode: status,
      traceId: `trace-${status}`,
    })
  })

  it('normalizes connection and timeout failures', async () => {
    mock.onGet('/network').networkError()
    mock.onGet('/timeout').timeout()

    await expect(client.get('/network', { decode: decodeVoid })).rejects.toMatchObject({
      kind: ApiErrorKind.Network,
    })
    await expect(client.get('/timeout', { decode: decodeVoid })).rejects.toMatchObject({
      kind: ApiErrorKind.Timeout,
    })
  })

  it('normalizes cancellation and unknown failures', () => {
    expect(normalizeRequestError(new CanceledError())).toMatchObject({
      kind: ApiErrorKind.Cancelled,
    })
    expect(normalizeRequestError(new Error('unexpected'))).toMatchObject({
      kind: ApiErrorKind.Unknown,
    })
  })

  it('does not expose AxiosError to callers', async () => {
    mock.onGet('/http-500').reply(500)
    const error: unknown = await client
      .get('/http-500', { decode: decodeVoid })
      .catch((caught: unknown) => caught)
    expect(error).toBeInstanceOf(AppError)
    expect(error).not.toBeInstanceOf(AxiosError)
  })

  it('fails before sending when the base URL is missing', async () => {
    const missingConfig: AppEnvConfig = { environment: 'test' }
    const missingHttp = createHttpClient(missingConfig)
    const missingMock = new MockAdapter(missingHttp)
    const missingClient = new ApiClient(missingConfig, missingHttp)

    await expect(missingClient.get('/never', { decode: decodeVoid })).rejects.toMatchObject({
      kind: ApiErrorKind.Config,
    })
    expect(missingMock.history.get).toHaveLength(0)
  })

  it('allows replacing the HTTP client and header provider in tests', async () => {
    const replacementHttp = createHttpClient(config, () => ({ 'X-Test-Header': 'replaced' }))
    const replacementMock = new MockAdapter(replacementHttp)
    const replacementClient = new ApiClient(config, replacementHttp)
    replacementMock.onGet('/replacement').reply(200, envelope(null))

    await replacementClient.get('/replacement', { decode: decodeVoid })
    const headers = replacementMock.history.get[0]?.headers as Record<string, unknown> | undefined
    expect(headers?.['X-Test-Header']).toBe('replaced')
  })
})

function envelope(data: unknown): Record<string, unknown> {
  return { code: 0, message: 'success', data, traceId: 'trace-test' }
}

describe('error mapper boundaries', () => {
  it('maps a raw Axios response failure', () => {
    const error = new AxiosError('denied', undefined, undefined, undefined, {
      data: null,
      status: 500,
      statusText: 'Error',
      headers: {},
      config: { headers: new AxiosHeaders() },
    })
    expect(normalizeRequestError(error).kind).toBe(ApiErrorKind.Http)
  })
})
