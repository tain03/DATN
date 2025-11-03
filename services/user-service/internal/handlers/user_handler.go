package handlers

import (
	"math"
	"log"
	"net/http"
	"strconv"

	"github.com/bisosad1501/DATN/services/user-service/internal/models"
	"github.com/bisosad1501/DATN/services/user-service/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UserHandler struct {
	service *service.UserService
}

func NewUserHandler(service *service.UserService) *UserHandler {
	return &UserHandler{service: service}
}

// HealthCheck handles health check requests
func (h *UserHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"status":  "healthy",
			"service": "user-service",
		},
	})
}

// GetProfile gets current user's profile
func (h *UserHandler) GetProfile(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	profile, err := h.service.GetOrCreateProfile(userID)
	if err != nil {
		log.Printf("❌ Error getting profile: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve profile",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    profile,
	})
}

// GetPublicProfile gets another user's public profile
// GET /api/v1/users/:id/profile
func (h *UserHandler) GetPublicProfile(c *gin.Context) {
	targetUserIDStr := c.Param("id")
	targetUserID, err := uuid.Parse(targetUserIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	// Get requesting user ID (if authenticated)
	// Try to get from context first (if OptionalAuth set it)
	// Otherwise try from header (set by API Gateway)
	var requestingUserID *uuid.UUID
	if userIDStr, exists := c.Get("user_id"); exists {
		uid, err := uuid.Parse(userIDStr.(string))
		if err == nil {
			requestingUserID = &uid
		}
	} else if userIDHeader := c.GetHeader("X-User-ID"); userIDHeader != "" {
		// Try header (set by API Gateway OptionalAuth middleware)
		uid, err := uuid.Parse(userIDHeader)
		if err == nil {
			requestingUserID = &uid
		}
	}

	// Get public profile with visibility check
	profileData, err := h.service.GetPublicProfile(targetUserID, requestingUserID)
	if err != nil {
		if err.Error() == "profile not found" {
			c.JSON(http.StatusNotFound, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "PROFILE_NOT_FOUND",
					Message: "User profile not found",
				},
			})
			return
		}
		if err.Error() == "profile is private" || err.Error() == "profile is only visible to friends" {
			c.JSON(http.StatusForbidden, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "PROFILE_PRIVATE",
					Message: err.Error(),
				},
			})
			return
		}
		log.Printf("❌ Error getting public profile: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve profile",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    profileData,
	})
}

// UpdateProfile updates current user's profile
func (h *UserHandler) UpdateProfile(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "VALIDATION_ERROR",
				Message: "Invalid request data",
				Details: err.Error(),
			},
		})
		return
	}

	profile, err := h.service.UpdateProfile(userID, &req)
	if err != nil {
		log.Printf("❌ Error updating profile: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "UPDATE_FAILED",
				Message: "Failed to update profile",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Profile updated successfully",
		Data:    profile,
	})
}

// UpdateAvatar updates user's avatar
func (h *UserHandler) UpdateAvatar(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	var req struct {
		AvatarURL string `json:"avatar_url" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "VALIDATION_ERROR",
				Message: "Avatar URL is required",
			},
		})
		return
	}

	err = h.service.UpdateAvatar(userID, req.AvatarURL)
	if err != nil {
		log.Printf("❌ Error updating avatar: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "UPDATE_FAILED",
				Message: "Failed to update avatar",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Avatar updated successfully",
		Data: gin.H{
			"avatar_url": req.AvatarURL,
		},
	})
}

// GetProgress gets user's learning progress and statistics
func (h *UserHandler) GetProgress(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	stats, err := h.service.GetProgressStats(userID)
	if err != nil {
		log.Printf("❌ Error getting progress stats: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve progress statistics",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    stats,
	})
}

// StartSession starts a new study session
func (h *UserHandler) StartSession(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	var req models.StudySessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "VALIDATION_ERROR",
				Message: "Invalid request data",
				Details: err.Error(),
			},
		})
		return
	}

	// Get device type from user agent
	deviceType := c.GetHeader("User-Agent")

	session, err := h.service.StartStudySession(&req, userID, &deviceType)
	if err != nil {
		log.Printf("❌ Error starting session: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "SESSION_START_FAILED",
				Message: "Failed to start study session",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, models.Response{
		Success: true,
		Message: "Study session started",
		Data:    session,
	})
}

// EndSession ends an active study session
func (h *UserHandler) EndSession(c *gin.Context) {
	sessionIDStr := c.Param("id")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_SESSION_ID",
				Message: "Invalid session ID format",
			},
		})
		return
	}

	var req models.EndSessionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "VALIDATION_ERROR",
				Message: "Invalid request data",
				Details: err.Error(),
			},
		})
		return
	}

	err = h.service.EndStudySession(sessionID, &req)
	if err != nil {
		log.Printf("❌ Error ending session: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "SESSION_END_FAILED",
				Message: "Failed to end study session",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Study session ended successfully",
	})
}

// GetHistory gets study history with pagination
func (h *UserHandler) GetHistory(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	// Parse pagination params
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	// Support page_size as alternative
	if limitStr := c.Query("page_size"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}
	// Cap at 200 to prevent excessive queries
	if limit > 200 {
		limit = 200
	}

	sessions, total, err := h.service.GetStudyHistory(userID, page, limit)
	if err != nil {
		log.Printf("❌ Error getting study history: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve study history",
				Details: err.Error(),
			},
		})
		return
	}

	totalPages := int(math.Ceil(float64(total) / float64(limit)))
	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"sessions": sessions,
			"pagination": gin.H{
				"page":        page,
				"limit":       limit,
				"total":       total,
				"total_pages": totalPages,
			},
		},
	})
}

// ============= Study Goals Handlers =============

// CreateGoal creates a new study goal
func (h *UserHandler) CreateGoal(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	var req models.CreateGoalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	goal, err := h.service.CreateGoal(userID, &req)
	if err != nil {
		log.Printf("❌ Error creating goal: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to create goal",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, models.Response{
		Success: true,
		Data:    goal,
		Message: "Goal created successfully",
	})
}

// GetGoals retrieves all goals for the user
func (h *UserHandler) GetGoals(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	goals, err := h.service.GetUserGoals(userID)
	if err != nil {
		log.Printf("❌ Error getting goals: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve goals",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"goals": goals,
			"count": len(goals),
		},
	})
}

// GetGoalByID retrieves a specific goal
func (h *UserHandler) GetGoalByID(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_GOAL_ID",
				Message: "Invalid goal ID format",
			},
		})
		return
	}

	goal, err := h.service.GetGoalByID(goalID, userID)
	if err != nil {
		log.Printf("❌ Error getting goal: %v", err)
		c.JSON(http.StatusNotFound, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "NOT_FOUND",
				Message: "Goal not found",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    goal,
	})
}

// UpdateGoal updates a study goal
func (h *UserHandler) UpdateGoal(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_GOAL_ID",
				Message: "Invalid goal ID format",
			},
		})
		return
	}

	var req models.UpdateGoalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	goal, err := h.service.UpdateGoal(goalID, userID, &req)
	if err != nil {
		log.Printf("❌ Error updating goal: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to update goal",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    goal,
		Message: "Goal updated successfully",
	})
}

// CompleteGoal marks a goal as completed
func (h *UserHandler) CompleteGoal(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_GOAL_ID",
				Message: "Invalid goal ID format",
			},
		})
		return
	}

	err = h.service.CompleteGoal(goalID, userID)
	if err != nil {
		log.Printf("❌ Error completing goal: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to complete goal",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Goal completed successfully",
	})
}

// DeleteGoal deletes a study goal
func (h *UserHandler) DeleteGoal(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_GOAL_ID",
				Message: "Invalid goal ID format",
			},
		})
		return
	}

	err = h.service.DeleteGoal(goalID, userID)
	if err != nil {
		log.Printf("❌ Error deleting goal: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to delete goal",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Goal deleted successfully",
	})
}

// ============= Statistics Handlers =============

// GetStatistics retrieves comprehensive statistics
func (h *UserHandler) GetStatistics(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	stats, err := h.service.GetDetailedStatistics(userID)
	if err != nil {
		log.Printf("❌ Error getting statistics: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve statistics",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    stats,
	})
}

// GetSkillStatistics retrieves statistics for a specific skill
func (h *UserHandler) GetSkillStatistics(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	skillType := c.Param("skill")
	if skillType == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_SKILL",
				Message: "Skill type is required",
			},
		})
		return
	}

	stats, err := h.service.GetSkillStatistics(userID, skillType)
	if err != nil {
		log.Printf("❌ Error getting skill statistics: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve skill statistics",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    stats,
	})
}

// ============= Achievements Handlers =============

// GetAchievements retrieves all available achievements with progress
func (h *UserHandler) GetAchievements(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	achievements, err := h.service.GetAllAchievements(userID)
	if err != nil {
		log.Printf("❌ Error getting achievements: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve achievements",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"achievements": achievements,
			"count":        len(achievements),
		},
	})
}

// GetEarnedAchievements retrieves only user's earned achievements
func (h *UserHandler) GetEarnedAchievements(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	achievements, err := h.service.GetEarnedAchievements(userID)
	if err != nil {
		log.Printf("❌ Error getting earned achievements: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve earned achievements",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"achievements": achievements,
			"count":        len(achievements),
		},
	})
}

// ============= Preferences Handlers =============

// GetPreferences retrieves user preferences
func (h *UserHandler) GetPreferences(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	prefs, err := h.service.GetPreferences(userID)
	if err != nil {
		log.Printf("❌ Error getting preferences: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve preferences",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    prefs,
	})
}

// UpdatePreferences updates user preferences
func (h *UserHandler) UpdatePreferences(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	var req models.UpdatePreferencesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	prefs, err := h.service.UpdatePreferences(userID, &req)
	if err != nil {
		log.Printf("❌ Error updating preferences: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to update preferences",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    prefs,
		Message: "Preferences updated successfully",
	})
}

// ============= Reminders Handlers =============

// CreateReminder creates a new study reminder
func (h *UserHandler) CreateReminder(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	var req models.CreateReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	reminder, err := h.service.CreateReminder(userID, &req)
	if err != nil {
		log.Printf("❌ Error creating reminder: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to create reminder",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, models.Response{
		Success: true,
		Data:    reminder,
		Message: "Reminder created successfully",
	})
}

// GetReminders retrieves all reminders for the user
func (h *UserHandler) GetReminders(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	reminders, err := h.service.GetUserReminders(userID)
	if err != nil {
		log.Printf("❌ Error getting reminders: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve reminders",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"reminders": reminders,
			"count":     len(reminders),
		},
	})
}

// UpdateReminder updates a study reminder
func (h *UserHandler) UpdateReminder(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	reminderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REMINDER_ID",
				Message: "Invalid reminder ID format",
			},
		})
		return
	}

	var req models.UpdateReminderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	reminder, err := h.service.UpdateReminder(reminderID, userID, &req)
	if err != nil {
		log.Printf("❌ Error updating reminder: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to update reminder",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    reminder,
		Message: "Reminder updated successfully",
	})
}

// DeleteReminder deletes a study reminder
func (h *UserHandler) DeleteReminder(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	reminderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REMINDER_ID",
				Message: "Invalid reminder ID format",
			},
		})
		return
	}

	err = h.service.DeleteReminder(reminderID, userID)
	if err != nil {
		log.Printf("❌ Error deleting reminder: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to delete reminder",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Reminder deleted successfully",
	})
}

// ToggleReminder toggles the active status of a reminder
func (h *UserHandler) ToggleReminder(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	reminderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REMINDER_ID",
				Message: "Invalid reminder ID format",
			},
		})
		return
	}

	var req struct {
		IsActive bool `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	err = h.service.ToggleReminder(reminderID, userID, req.IsActive)
	if err != nil {
		log.Printf("❌ Error toggling reminder: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to toggle reminder",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Reminder toggled successfully",
	})
}

// ============= Leaderboard Handlers =============

// GetLeaderboard retrieves the leaderboard with period filtering and pagination
func (h *UserHandler) GetLeaderboard(c *gin.Context) {
	period := c.DefaultQuery("period", "all-time") // daily, weekly, monthly, all-time
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "50")
	
	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}
	
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 || limit > 100 {
		limit = 50
	}

	leaderboard, total, err := h.service.GetLeaderboard(period, page, limit)
	if err != nil {
		log.Printf("❌ Error getting leaderboard: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INTERNAL_ERROR",
				Message: "Failed to retrieve leaderboard",
				Details: err.Error(),
			},
		})
		return
	}

	totalPages := int(math.Ceil(float64(total) / float64(limit)))
	
	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"leaderboard": leaderboard,
			"pagination": gin.H{
				"total":       total,
				"page":        page,
				"limit":       limit,
				"total_pages": totalPages,
			},
		},
	})
}

// GetUserRank retrieves the rank of the current user
func (h *UserHandler) GetUserRank(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	rank, err := h.service.GetUserRank(userID)
	if err != nil {
		log.Printf("❌ Error getting user rank: %v", err)
		c.JSON(http.StatusNotFound, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "NOT_FOUND",
				Message: "User rank not found",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    rank,
	})
}

// FollowUser follows another user
// POST /api/v1/users/:id/follow
func (h *UserHandler) FollowUser(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "UNAUTHORIZED",
				Message: "Authentication required",
			},
		})
		return
	}

	followerID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	followingIDStr := c.Param("id")
	followingID, err := uuid.Parse(followingIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid target user ID format",
			},
		})
		return
	}

	err = h.service.FollowUser(followerID, followingID)
	if err != nil {
		if err.Error() == "cannot follow yourself" {
			c.JSON(http.StatusBadRequest, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "CANNOT_FOLLOW_SELF",
					Message: "You cannot follow yourself",
				},
			})
			return
		}
		if err.Error() == "cannot follow private profile" {
			c.JSON(http.StatusForbidden, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "CANNOT_FOLLOW_PRIVATE",
					Message: "Cannot follow a private profile",
				},
			})
			return
		}
		if err.Error() == "cannot follow friends-only profile" {
			c.JSON(http.StatusForbidden, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "CANNOT_FOLLOW_FRIENDS_ONLY",
					Message: "Cannot follow a friends-only profile",
				},
			})
			return
		}
		log.Printf("❌ Error following user: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "FOLLOW_FAILED",
				Message: "Failed to follow user",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "User followed successfully",
	})
}

// UnfollowUser unfollows another user
// DELETE /api/v1/users/:id/follow
func (h *UserHandler) UnfollowUser(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "UNAUTHORIZED",
				Message: "Authentication required",
			},
		})
		return
	}

	followerID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	followingIDStr := c.Param("id")
	followingID, err := uuid.Parse(followingIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid target user ID format",
			},
		})
		return
	}

	err = h.service.UnfollowUser(followerID, followingID)
	if err != nil {
		if err.Error() == "follow relationship not found" {
			c.JSON(http.StatusNotFound, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "NOT_FOLLOWING",
					Message: "You are not following this user",
				},
			})
			return
		}
		log.Printf("❌ Error unfollowing user: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "UNFOLLOW_FAILED",
				Message: "Failed to unfollow user",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "User unfollowed successfully",
	})
}

// RemoveFollower removes a follower from user's followers list
// DELETE /api/v1/user/followers/:id
func (h *UserHandler) RemoveFollower(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "UNAUTHORIZED",
				Message: "Authentication required",
			},
		})
		return
	}

	followingID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	followerIDStr := c.Param("id")
	followerID, err := uuid.Parse(followerIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid follower ID format",
			},
		})
		return
	}

	err = h.service.RemoveFollower(followingID, followerID)
	if err != nil {
		if err.Error() == "cannot remove yourself" {
			c.JSON(http.StatusBadRequest, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "CANNOT_REMOVE_SELF",
					Message: "You cannot remove yourself",
				},
			})
			return
		}
		if err.Error() == "follower relationship not found" {
			c.JSON(http.StatusNotFound, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "FOLLOWER_NOT_FOUND",
					Message: "This user is not following you",
				},
			})
			return
		}
		log.Printf("❌ Error removing follower: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "REMOVE_FOLLOWER_FAILED",
				Message: "Failed to remove follower",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Follower removed successfully",
	})
}

// GetFollowers gets the list of followers for a user
// GET /api/v1/users/:id/followers
func (h *UserHandler) GetFollowers(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	// Get requesting user ID (if authenticated)
	var requestingUserID *uuid.UUID
	if userIDStr, exists := c.Get("user_id"); exists {
		uid, err := uuid.Parse(userIDStr.(string))
		if err == nil {
			requestingUserID = &uid
		}
	} else if userIDHeader := c.GetHeader("X-User-ID"); userIDHeader != "" {
		uid, err := uuid.Parse(userIDHeader)
		if err == nil {
			requestingUserID = &uid
		}
	}

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("pageSize", "20")
	
	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}
	
	pageSize, err := strconv.Atoi(pageSizeStr)
	if err != nil || pageSize <= 0 || pageSize > 100 {
		pageSize = 20
	}

	followers, total, err := h.service.GetFollowers(userID, requestingUserID, page, pageSize)
	if err != nil {
		if err.Error() == "followers list is private" || err.Error() == "followers list is only visible to friends" {
			c.JSON(http.StatusForbidden, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "FOLLOWERS_LIST_PRIVATE",
					Message: err.Error(),
				},
			})
			return
		}
		log.Printf("❌ Error getting followers: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "GET_FOLLOWERS_FAILED",
				Message: "Failed to get followers",
				Details: err.Error(),
			},
		})
		return
	}

	totalPages := int(math.Ceil(float64(total) / float64(pageSize)))

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"followers": followers,
			"pagination": gin.H{
				"total":       total,
				"page":        page,
				"page_size":   pageSize,
				"total_pages": totalPages,
			},
		},
	})
}

// GetFollowing gets the list of users a user is following
// GET /api/v1/users/:id/following
func (h *UserHandler) GetFollowing(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	// Get requesting user ID (if authenticated)
	var requestingUserID *uuid.UUID
	if userIDStr, exists := c.Get("user_id"); exists {
		uid, err := uuid.Parse(userIDStr.(string))
		if err == nil {
			requestingUserID = &uid
		}
	} else if userIDHeader := c.GetHeader("X-User-ID"); userIDHeader != "" {
		uid, err := uuid.Parse(userIDHeader)
		if err == nil {
			requestingUserID = &uid
		}
	}

	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("pageSize", "20")
	
	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}
	
	pageSize, err := strconv.Atoi(pageSizeStr)
	if err != nil || pageSize <= 0 || pageSize > 100 {
		pageSize = 20
	}

	following, total, err := h.service.GetFollowing(userID, requestingUserID, page, pageSize)
	if err != nil {
		if err.Error() == "following list is private" || err.Error() == "following list is only visible to friends" {
			c.JSON(http.StatusForbidden, models.Response{
				Success: false,
				Error: &models.ErrorInfo{
					Code:    "FOLLOWING_LIST_PRIVATE",
					Message: err.Error(),
				},
			})
			return
		}
		log.Printf("❌ Error getting following: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "GET_FOLLOWING_FAILED",
				Message: "Failed to get following",
				Details: err.Error(),
			},
		})
		return
	}

	totalPages := int(math.Ceil(float64(total) / float64(pageSize)))

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data: gin.H{
			"following": following,
			"pagination": gin.H{
				"total":       total,
				"page":        page,
				"page_size":   pageSize,
				"total_pages": totalPages,
			},
		},
	})
}

// GetPublicAchievements gets achievements for a public user profile
// GET /api/v1/users/:id/achievements
func (h *UserHandler) GetPublicAchievements(c *gin.Context) {
	userIDStr := c.Param("id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "INVALID_USER_ID",
				Message: "Invalid user ID format",
			},
		})
		return
	}

	achievements, err := h.service.GetPublicAchievements(userID)
	if err != nil {
		log.Printf("❌ Error getting public achievements: %v", err)
		c.JSON(http.StatusInternalServerError, models.Response{
			Success: false,
			Error: &models.ErrorInfo{
				Code:    "GET_ACHIEVEMENTS_FAILED",
				Message: "Failed to get achievements",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Data:    achievements,
	})
}
