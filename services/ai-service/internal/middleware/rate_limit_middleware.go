package middleware

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	limiter "github.com/ulule/limiter/v3"
	"github.com/ulule/limiter/v3/drivers/store/memory"
)

// RateLimitMiddleware provides rate limiting for AI Service
type RateLimitMiddleware struct {
	// User-specific rate limiters (per user ID)
	userLimiters map[string]*limiter.Limiter
	// Global rate limiter
	globalLimiter *limiter.Limiter
	// Submission limiters (per user, for submissions)
	submissionLimiters map[string]*limiter.Limiter
}

// Rate limit configurations
const (
	// Global rate limit: 100 requests per minute
	GlobalRateLimit = "100-M"
	
	// User rate limit: 50 submissions per day
	UserSubmissionLimitPerDay = "50-D"
	
	// User rate limit: 10 submissions per hour
	UserSubmissionLimitPerHour = "10-H"
)

// NewRateLimitMiddleware creates a new rate limit middleware
func NewRateLimitMiddleware() *RateLimitMiddleware {
	// Global store (in-memory)
	store := memory.NewStore()
	
	// Global rate limiter (100 requests per minute)
	globalLimit, _ := limiter.NewRateFromFormatted(GlobalRateLimit)
	globalLimiter := limiter.New(store, globalLimit)

	// User submission limiters (will be created on-demand)
	userLimiters := make(map[string]*limiter.Limiter)
	submissionLimiters := make(map[string]*limiter.Limiter)

	return &RateLimitMiddleware{
		userLimiters:       userLimiters,
		globalLimiter:      globalLimiter,
		submissionLimiters: submissionLimiters,
	}
}

// GlobalRateLimit applies global rate limiting (100 req/min)
func (r *RateLimitMiddleware) GlobalRateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get client identifier (IP address as fallback)
		identifier := c.ClientIP()
		if userID, exists := c.Get("user_id"); exists {
			if userIDStr, ok := userID.(string); ok {
				identifier = userIDStr
			}
		}

		// Check global rate limit
		context, err := r.globalLimiter.Get(c, identifier)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "rate limit check failed"})
			c.Abort()
			return
		}

		// Set rate limit headers
		c.Header("X-RateLimit-Limit", strconv.FormatInt(context.Limit, 10))
		c.Header("X-RateLimit-Remaining", strconv.FormatInt(context.Remaining, 10))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(context.Reset, 10))

		// Check if limit exceeded
		if context.Reached {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "rate limit exceeded",
				"message": "Too many requests. Please try again later.",
				"retry_after": time.Until(time.Unix(context.Reset, 0)).Seconds(),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// SubmissionRateLimit applies rate limiting for submissions (10/hour, 50/day per user)
func (r *RateLimitMiddleware) SubmissionRateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from context
		userIDStr, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found"})
			c.Abort()
			return
		}

		userIDVal, ok := userIDStr.(string)
		if !ok {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user_id type"})
			c.Abort()
			return
		}

		userID, err := uuid.Parse(userIDVal)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user_id format"})
			c.Abort()
			return
		}

		userIDKey := userID.String()

		// Get or create submission limiter for this user (hourly limit)
		hourlyLimiter, exists := r.submissionLimiters[userIDKey+"_hour"]
		if !exists {
			store := memory.NewStore()
			hourlyLimit, _ := limiter.NewRateFromFormatted(UserSubmissionLimitPerHour)
			hourlyLimiter = limiter.New(store, hourlyLimit)
			r.submissionLimiters[userIDKey+"_hour"] = hourlyLimiter
		}

		// Check hourly limit
		hourlyContext, err := hourlyLimiter.Get(c, userIDKey)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "rate limit check failed"})
			c.Abort()
			return
		}

		// Check daily limit
		dailyLimiter, exists := r.submissionLimiters[userIDKey+"_day"]
		if !exists {
			store := memory.NewStore()
			dailyLimit, _ := limiter.NewRateFromFormatted(UserSubmissionLimitPerDay)
			dailyLimiter = limiter.New(store, dailyLimit)
			r.submissionLimiters[userIDKey+"_day"] = dailyLimiter
		}

		dailyContext, err := dailyLimiter.Get(c, userIDKey)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "rate limit check failed"})
			c.Abort()
			return
		}

		// Set rate limit headers
		c.Header("X-RateLimit-Limit-Hour", strconv.FormatInt(hourlyContext.Limit, 10))
		c.Header("X-RateLimit-Remaining-Hour", strconv.FormatInt(hourlyContext.Remaining, 10))
		c.Header("X-RateLimit-Reset-Hour", strconv.FormatInt(hourlyContext.Reset, 10))
		c.Header("X-RateLimit-Limit-Day", strconv.FormatInt(dailyContext.Limit, 10))
		c.Header("X-RateLimit-Remaining-Day", strconv.FormatInt(dailyContext.Remaining, 10))
		c.Header("X-RateLimit-Reset-Day", strconv.FormatInt(dailyContext.Reset, 10))

		// Check if limits exceeded
		if hourlyContext.Reached {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "submission rate limit exceeded",
				"message": "You have exceeded the maximum number of submissions per hour (10). Please try again later.",
				"retry_after": time.Until(time.Unix(hourlyContext.Reset, 0)).Seconds(),
			})
			c.Abort()
			return
		}

		if dailyContext.Reached {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "submission rate limit exceeded",
				"message": "You have exceeded the maximum number of submissions per day (50). Please try again tomorrow.",
				"retry_after": time.Until(time.Unix(dailyContext.Reset, 0)).Seconds(),
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

