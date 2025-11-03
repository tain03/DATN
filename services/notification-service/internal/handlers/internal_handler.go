package handlers

import (
	"log"
	"net/http"

	"github.com/bisosad1501/ielts-platform/notification-service/internal/models"
	"github.com/bisosad1501/ielts-platform/notification-service/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// InternalHandler handles internal service-to-service API calls
type InternalHandler struct {
	notificationService *service.NotificationService
}

// NewInternalHandler creates a new internal handler
func NewInternalHandler(notificationService *service.NotificationService) *InternalHandler {
	return &InternalHandler{
		notificationService: notificationService,
	}
}

// SendNotificationInternalRequest represents request to send notification from other services
type SendNotificationInternalRequest struct {
	UserID     uuid.UUID              `json:"user_id" binding:"required"`
	Title      string                 `json:"title" binding:"required"`
	Message    string                 `json:"message" binding:"required"`
	Type       string                 `json:"type" binding:"required,oneof=achievement reminder course_update exercise_graded system social"`
	Category   string                 `json:"category" binding:"required,oneof=info success warning alert"`
	ActionType *string                `json:"action_type,omitempty"`
	ActionData map[string]interface{} `json:"action_data,omitempty"`
	IconURL    *string                `json:"icon_url,omitempty"`
	ImageURL   *string                `json:"image_url,omitempty"`
}

// SendBulkNotificationInternalRequest represents request to send bulk notification
type SendBulkNotificationInternalRequest struct {
	UserIDs    []uuid.UUID            `json:"user_ids" binding:"required,min=1"`
	Title      string                 `json:"title" binding:"required"`
	Message    string                 `json:"message" binding:"required"`
	Type       string                 `json:"type" binding:"required,oneof=achievement reminder course_update exercise_graded system social"`
	Category   string                 `json:"category" binding:"required,oneof=info success warning alert"`
	ActionType *string                `json:"action_type,omitempty"`
	ActionData map[string]interface{} `json:"action_data,omitempty"`
	IconURL    *string                `json:"icon_url,omitempty"`
	ImageURL   *string                `json:"image_url,omitempty"`
}

// SendNotificationInternal sends a single notification (internal API)
// POST /internal/send
func (h *InternalHandler) SendNotificationInternal(c *gin.Context) {
	var req SendNotificationInternalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Internal] Send notification validation error: %v", err)
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Invalid request payload: " + err.Error(),
		})
		return
	}

	// Create notification request
	createReq := &models.CreateNotificationRequest{
		UserID:     req.UserID,
		Title:      req.Title,
		Message:    req.Message,
		Type:       req.Type,
		Category:   req.Category,
		ActionType: req.ActionType,
		ActionData: req.ActionData,
		IconURL:    req.IconURL,
		ImageURL:   req.ImageURL,
	}

	notification, err := h.notificationService.CreateNotification(createReq)
	if err != nil {
		// Check if error is due to user preferences blocking
		if err.Error() == "notification blocked by user preferences" {
			// Return 200 OK when blocked by preferences - this is expected behavior, not an error
			// Other services should treat this as success (notification not needed)
			log.Printf("[Internal] Notification blocked by user preferences for user %s (type: %s)", req.UserID, req.Type)
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"message": "Notification blocked by user preferences",
				"blocked": true,
			})
			return
		}
		log.Printf("[Internal] Failed to create notification for user %s: %v", req.UserID, err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "creation_failed",
			Message: "Failed to create notification: " + err.Error(),
		})
		return
	}

	log.Printf("[Internal] Successfully created notification %s for user %s (type: %s, category: %s)",
		notification.ID, req.UserID, req.Type, req.Category)

	c.JSON(http.StatusCreated, gin.H{
		"success":         true,
		"notification_id": notification.ID,
		"message":         "Notification sent successfully",
	})
}

// SendBulkNotificationInternal sends notifications to multiple users (internal API)
// POST /internal/bulk
func (h *InternalHandler) SendBulkNotificationInternal(c *gin.Context) {
	var req SendBulkNotificationInternalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Internal] Bulk notification validation error: %v", err)
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Invalid request payload: " + err.Error(),
		})
		return
	}

	successCount := 0
	failedCount := 0
	var errors []string

	// Send notification to each user
	for _, userID := range req.UserIDs {
		createReq := &models.CreateNotificationRequest{
			UserID:     userID,
			Title:      req.Title,
			Message:    req.Message,
			Type:       req.Type,
			Category:   req.Category,
			ActionType: req.ActionType,
			ActionData: req.ActionData,
			IconURL:    req.IconURL,
			ImageURL:   req.ImageURL,
		}

		if _, err := h.notificationService.CreateNotification(createReq); err != nil {
			failedCount++
			errMsg := "Failed to send to user " + userID.String()
			errors = append(errors, errMsg)
			log.Printf("[Internal] %s: %v", errMsg, err)
		} else {
			successCount++
		}
	}

	log.Printf("[Internal] Bulk notification complete: %d success, %d failed out of %d total",
		successCount, failedCount, len(req.UserIDs))

	response := gin.H{
		"success":       successCount > 0,
		"total":         len(req.UserIDs),
		"success_count": successCount,
		"failed_count":  failedCount,
	}

	if len(errors) > 0 {
		response["errors"] = errors
	}

	statusCode := http.StatusCreated
	if failedCount == len(req.UserIDs) {
		statusCode = http.StatusInternalServerError
	} else if failedCount > 0 {
		statusCode = http.StatusMultiStatus
	}

	c.JSON(statusCode, response)
}

// UpdatePreferencesInternalRequest represents request to update preferences (internal API)
type UpdatePreferencesInternalRequest struct {
	PushEnabled  *bool `json:"push_enabled,omitempty"`
	InAppEnabled *bool `json:"in_app_enabled,omitempty"`
}

// UpdatePreferencesInternal updates notification preferences for a specific user (internal API)
// PUT /api/v1/notifications/internal/preferences/:user_id
func (h *InternalHandler) UpdatePreferencesInternal(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		log.Printf("[Internal] Invalid user ID: %s", userIDStr)
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "invalid_user_id",
			Message: "Invalid user ID format",
		})
		return
	}

	var req UpdatePreferencesInternalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Internal] Update preferences validation error: %v", err)
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: "Invalid request payload: " + err.Error(),
		})
		return
	}

	// Convert to Notification Service UpdatePreferencesRequest
	updateReq := &models.UpdatePreferencesRequest{}
	if req.PushEnabled != nil {
		updateReq.PushEnabled = req.PushEnabled
	}
	if req.InAppEnabled != nil {
		updateReq.InAppEnabled = req.InAppEnabled
	}

	// Update preferences
	prefs, err := h.notificationService.UpdatePreferences(userID, updateReq)
	if err != nil {
		log.Printf("[Internal] Failed to update preferences for user %s: %v", userID, err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "update_failed",
			Message: "Failed to update preferences: " + err.Error(),
		})
		return
	}

	log.Printf("[Internal] Successfully updated preferences for user %s (push_enabled=%v, in_app_enabled=%v)",
		userID, prefs.PushEnabled, prefs.InAppEnabled)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Preferences updated successfully",
		"data": gin.H{
			"push_enabled":  prefs.PushEnabled,
			"in_app_enabled": prefs.InAppEnabled,
		},
	})
}
