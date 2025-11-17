import axios from 'axios'

/**
 * Health check API service
 *
 * Provides methods to check health status of the application,
 * database, and GitHub API connectivity.
 */

// Create axios instance with baseURL from environment or default to '/api'
const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
})

/**
 * Health service object with async methods for health checks
 */
export const healthService = {
  /**
   * Check application health status
   *
   * @returns {Promise<Object>} Health status response
   * @throws {Error} Network or server errors
   */
  async checkHealth() {
    const response = await apiClient.get('/health')
    return response.data
  },

  /**
   * Check database connectivity
   *
   * @returns {Promise<Object>} Database health status response
   * @throws {Error} Network, server, or database connection errors
   */
  async checkDatabase() {
    const response = await apiClient.get('/health/db')
    return response.data
  },

  /**
   * Check GitHub API reachability
   *
   * @returns {Promise<Object>} GitHub API health status response
   * @throws {Error} Network, server, or GitHub API errors
   */
  async checkGitHub() {
    const response = await apiClient.get('/health/github')
    return response.data
  },
}
