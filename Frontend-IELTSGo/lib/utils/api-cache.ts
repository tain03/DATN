/**
 * Simple in-memory cache for API responses
 * Implements stale-while-revalidate pattern
 */

interface CacheEntry<T> {
  data: T
  timestamp: number
  expiresAt: number
}

class ApiCache {
  private cache: Map<string, CacheEntry<any>> = new Map()

  // Default TTL: 60 seconds for dynamic data, 5 minutes for static data
  // Increased from 30s to reduce network requests during navigation
  private defaultTTL = 60000 // 60 seconds

  /**
   * Get cached data if available and not expired
   */
  get<T>(key: string): T | null {
    const entry = this.cache.get(key)
    if (!entry) return null

    const now = Date.now()
    if (now > entry.expiresAt) {
      // Expired, but return stale data if available (stale-while-revalidate)
      this.cache.delete(key)
      return null
    }

    return entry.data as T
  }

  /**
   * Check if cache entry exists and is valid
   */
  has(key: string): boolean {
    const entry = this.cache.get(key)
    if (!entry) return false

    const now = Date.now()
    if (now > entry.expiresAt) {
      this.cache.delete(key)
      return false
    }

    return true
  }

  /**
   * Set cache entry with TTL
   */
  set<T>(key: string, data: T, ttl: number = this.defaultTTL): void {
    const now = Date.now()
    this.cache.set(key, {
      data,
      timestamp: now,
      expiresAt: now + ttl,
    })
  }

  /**
   * Clear specific cache entry
   */
  delete(key: string): void {
    this.cache.delete(key)
  }

  /**
   * Clear all cache
   */
  clear(): void {
    this.cache.clear()
  }

  /**
   * Generate cache key from API endpoint and params
   */
  generateKey(endpoint: string, params?: Record<string, any>): string {
    const paramString = params
      ? Object.keys(params)
        .sort()
        .map(key => `${key}=${JSON.stringify(params[key])}`)
        .join('&')
      : ''
    return `${endpoint}${paramString ? `?${paramString}` : ''}`
  }
}

// Singleton instance
export const apiCache = new ApiCache()

/**
 * Cached API call wrapper
 * Returns cached data immediately if available, then fetches fresh data
 */
export async function cachedFetch<T>(
  cacheKey: string,
  fetchFn: () => Promise<T>,
  ttl: number = 30000 // 30 seconds default
): Promise<T> {
  // Return cached data immediately if available
  const cached = apiCache.get<T>(cacheKey)
  if (cached) {
    // Fetch fresh data in background (stale-while-revalidate)
    fetchFn()
      .then(data => apiCache.set(cacheKey, data, ttl))
      .catch(() => { }) // Silently fail, keep using stale data

    return cached
  }

  // No cache, fetch fresh data
  const data = await fetchFn()
  apiCache.set(cacheKey, data, ttl)
  return data
}

