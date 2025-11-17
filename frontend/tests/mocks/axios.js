import { vi } from 'vitest'

/**
 * Complete axios mock for testing
 *
 * Mocks both the default axios instance (axios.get(), axios.post(), etc.)
 * and the factory method (axios.create())
 */

const mockAxiosGet = vi.fn()
const mockAxiosPost = vi.fn()
const mockAxiosPut = vi.fn()
const mockAxiosDelete = vi.fn()
const mockAxiosPatch = vi.fn()
const mockAxiosRequest = vi.fn()

const mockAxiosInstance = {
  get: mockAxiosGet,
  post: mockAxiosPost,
  put: mockAxiosPut,
  delete: mockAxiosDelete,
  patch: mockAxiosPatch,
  request: mockAxiosRequest,
  defaults: {
    headers: {
      common: {},
    },
  },
}

const mockAxios = {
  get: mockAxiosGet,
  post: mockAxiosPost,
  put: mockAxiosPut,
  delete: mockAxiosDelete,
  patch: mockAxiosPatch,
  request: mockAxiosRequest,
  create: vi.fn(() => mockAxiosInstance),
  defaults: {
    headers: {
      common: {},
    },
  },
}

export default mockAxios

export {
  mockAxiosInstance,
  mockAxiosGet,
  mockAxiosPost,
  mockAxiosPut,
  mockAxiosDelete,
  mockAxiosPatch,
  mockAxiosRequest,
}
