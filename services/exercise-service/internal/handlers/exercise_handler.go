package handlers

import (
	"net/http"
	"strconv"

	"github.com/bisosad1501/ielts-platform/exercise-service/internal/models"
	"github.com/bisosad1501/ielts-platform/exercise-service/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ExerciseHandler struct {
	service *service.ExerciseService
}

type Response struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *ErrorInfo  `json:"error,omitempty"`
}

type ErrorInfo struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

func NewExerciseHandler(service *service.ExerciseService) *ExerciseHandler {
	return &ExerciseHandler{service: service}
}

// GetExercises handles GET /api/v1/exercises
func (h *ExerciseHandler) GetExercises(c *gin.Context) {
	query := &models.ExerciseListQuery{}

	// Parse query params
	query.Page, _ = strconv.Atoi(c.DefaultQuery("page", "1"))
	query.Limit, _ = strconv.Atoi(c.DefaultQuery("limit", "20"))
	
	// Support comma-separated values for OR logic (e.g., skill_type=listening,reading)
	skillTypeParam := c.Query("skill_type")
	if skillTypeParam != "" {
		query.SkillType = skillTypeParam // Will be parsed in repository
	}
	difficultyParam := c.Query("difficulty")
	if difficultyParam != "" {
		query.Difficulty = difficultyParam // Will be parsed in repository
	}
	exerciseTypeParam := c.Query("exercise_type")
	if exerciseTypeParam != "" {
		query.ExerciseType = exerciseTypeParam // Will be parsed in repository
	}
	query.Search = c.Query("search")

	if isFree := c.Query("is_free"); isFree != "" {
		isFreeVal := isFree == "true"
		query.IsFree = &isFreeVal
	}

	if courseID := c.Query("course_id"); courseID != "" {
		if id, err := uuid.Parse(courseID); err == nil {
			query.CourseID = &id
		}
	}

	if moduleID := c.Query("module_id"); moduleID != "" {
		if id, err := uuid.Parse(moduleID); err == nil {
			query.ModuleID = &id
		}
	}

	exercises, total, err := h.service.GetExercises(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "GET_EXERCISES_ERROR",
				Message: "Failed to get exercises",
				Details: err.Error(),
			},
		})
		return
	}

	totalPages := (total + query.Limit - 1) / query.Limit
	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"exercises": exercises,
			"pagination": gin.H{
				"page":        query.Page,
				"limit":      query.Limit,
				"total":      total,
				"total_pages": totalPages,
			},
		},
	})
}

// GetExerciseByID handles GET /api/v1/exercises/:id
func (h *ExerciseHandler) GetExerciseByID(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	exercise, err := h.service.GetExerciseByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "EXERCISE_NOT_FOUND",
				Message: "Exercise not found",
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    exercise,
	})
}

// StartExercise handles POST /api/v1/submissions
func (h *ExerciseHandler) StartExercise(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "UNAUTHORIZED",
				Message: "User not authenticated",
			},
		})
		return
	}

	var req struct {
		ExerciseID *uuid.UUID `json:"exercise_id" binding:"-"`
		DeviceType *string    `json:"device_type"` // web, android, ios
	}

	// Try to bind JSON body if present
	_ = c.ShouldBindJSON(&req)

	// If exercise_id not provided in body, try URL param
	if req.ExerciseID == nil {
		if idStr := c.Param("id"); idStr != "" {
			if id, err := uuid.Parse(idStr); err == nil {
				req.ExerciseID = &id
			}
		}
	}

	if req.ExerciseID == nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "exercise_id is required either in body or URL",
			},
		})
		return
	}

	userUUID, _ := uuid.Parse(userID.(string))
	submission, err := h.service.StartExercise(userUUID, *req.ExerciseID, req.DeviceType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "START_EXERCISE_ERROR",
				Message: "Failed to start exercise",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    submission,
	})
}

// SubmitAnswers handles PUT /api/v1/submissions/:id/answers
func (h *ExerciseHandler) SubmitAnswers(c *gin.Context) {
	submissionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid submission ID",
			},
		})
		return
	}

	var req models.SubmitAnswersRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	err = h.service.SubmitAnswers(submissionID, req.Answers)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "SUBMIT_ANSWERS_ERROR",
				Message: "Failed to submit answers",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Answers submitted and graded successfully",
		},
	})
}

// GetSubmissionResult handles GET /api/v1/submissions/:id/result
func (h *ExerciseHandler) GetSubmissionResult(c *gin.Context) {
	submissionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid submission ID",
			},
		})
		return
	}

	result, err := h.service.GetSubmissionResult(submissionID)
	if err != nil {
		c.JSON(http.StatusNotFound, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "RESULT_NOT_FOUND",
				Message: "Submission result not found",
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    result,
	})
}

// GetMySubmissions handles GET /api/v1/submissions/my
func (h *ExerciseHandler) GetMySubmissions(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "UNAUTHORIZED",
				Message: "User not authenticated",
			},
		})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	userUUID, _ := uuid.Parse(userID.(string))
	submissions, err := h.service.GetMySubmissions(userUUID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "GET_SUBMISSIONS_ERROR",
				Message: "Failed to get submissions",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    submissions,
	})
}

// CreateExercise handles POST /api/v1/admin/exercises
func (h *ExerciseHandler) CreateExercise(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "UNAUTHORIZED",
				Message: "User not authenticated",
			},
		})
		return
	}

	var req models.CreateExerciseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	userUUID, _ := uuid.Parse(userID.(string))
	exercise, err := h.service.CreateExercise(&req, userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "CREATE_EXERCISE_ERROR",
				Message: "Failed to create exercise",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    exercise,
	})
}

// UpdateExercise handles PUT /api/v1/admin/exercises/:id
func (h *ExerciseHandler) UpdateExercise(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	var req models.UpdateExerciseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	err = h.service.UpdateExercise(id, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "UPDATE_EXERCISE_ERROR",
				Message: "Failed to update exercise",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Exercise updated successfully",
		},
	})
}

// DeleteExercise handles DELETE /api/v1/admin/exercises/:id
func (h *ExerciseHandler) DeleteExercise(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	err = h.service.DeleteExercise(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "DELETE_EXERCISE_ERROR",
				Message: "Failed to delete exercise",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Exercise deleted successfully",
		},
	})
}

// CreateSection handles POST /api/v1/admin/exercises/:id/sections
func (h *ExerciseHandler) CreateSection(c *gin.Context) {
	exerciseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	var req models.CreateSectionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	section, err := h.service.CreateSection(exerciseID, &req, userUUID)
	if err != nil {
		statusCode := http.StatusInternalServerError
		if err.Error() == "exercise not found" {
			statusCode = http.StatusNotFound
		} else if err.Error() == "unauthorized: you don't own this exercise" {
			statusCode = http.StatusForbidden
		}
		c.JSON(statusCode, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "CREATE_SECTION_ERROR",
				Message: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    section,
	})
}

// CreateQuestion handles POST /api/v1/admin/questions
func (h *ExerciseHandler) CreateQuestion(c *gin.Context) {
	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	var req models.CreateQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	question, err := h.service.CreateQuestion(&req, userUUID)
	if err != nil {
		statusCode := http.StatusInternalServerError
		if err.Error() == "exercise not found" {
			statusCode = http.StatusNotFound
		} else if err.Error() == "unauthorized: you don't own this exercise" {
			statusCode = http.StatusForbidden
		}
		c.JSON(statusCode, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "CREATE_QUESTION_ERROR",
				Message: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    question,
	})
}

// CreateQuestionOption handles POST /api/v1/admin/questions/:id/options
func (h *ExerciseHandler) CreateQuestionOption(c *gin.Context) {
	questionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid question ID",
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	var req models.CreateQuestionOptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	option, err := h.service.CreateQuestionOption(questionID, &req, userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "CREATE_OPTION_ERROR",
				Message: "Failed to create option",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    option,
	})
}

// CreateQuestionAnswer handles POST /api/v1/admin/questions/:id/answer
func (h *ExerciseHandler) CreateQuestionAnswer(c *gin.Context) {
	questionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid question ID",
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	var req models.CreateQuestionAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	answer, err := h.service.CreateQuestionAnswer(questionID, &req, userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "CREATE_ANSWER_ERROR",
				Message: "Failed to create answer",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    answer,
	})
}

// PublishExercise handles POST /api/v1/admin/exercises/:id/publish
func (h *ExerciseHandler) PublishExercise(c *gin.Context) {
	exerciseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	if err := h.service.PublishExercise(exerciseID, userUUID); err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "PUBLISH_FAILED",
				Message: "Failed to publish exercise",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Exercise published successfully",
		},
	})
}

// UnpublishExercise handles POST /api/v1/admin/exercises/:id/unpublish
func (h *ExerciseHandler) UnpublishExercise(c *gin.Context) {
	exerciseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	if err := h.service.UnpublishExercise(exerciseID, userUUID); err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "UNPUBLISH_FAILED",
				Message: "Failed to unpublish exercise",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Exercise unpublished successfully",
		},
	})
}

// GetAllTags handles GET /api/v1/tags
func (h *ExerciseHandler) GetAllTags(c *gin.Context) {
	tags, err := h.service.GetAllTags()
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "FETCH_FAILED",
				Message: "Failed to fetch tags",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    tags,
	})
}

// GetExerciseTags handles GET /api/v1/exercises/:id/tags
func (h *ExerciseHandler) GetExerciseTags(c *gin.Context) {
	exerciseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	tags, err := h.service.GetExerciseTags(exerciseID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "FETCH_FAILED",
				Message: "Failed to fetch exercise tags",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    tags,
	})
}

// AddTagToExercise handles POST /api/v1/admin/exercises/:id/tags
func (h *ExerciseHandler) AddTagToExercise(c *gin.Context) {
	exerciseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	var req models.AddTagRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	if err := h.service.AddTagToExercise(exerciseID, req.TagID, userUUID); err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "ADD_TAG_FAILED",
				Message: "Failed to add tag to exercise",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Tag added successfully",
		},
	})
}

// RemoveTagFromExercise handles DELETE /api/v1/admin/exercises/:id/tags/:tag_id
func (h *ExerciseHandler) RemoveTagFromExercise(c *gin.Context) {
	exerciseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	tagID, err := strconv.Atoi(c.Param("tag_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_TAG_ID",
				Message: "Invalid tag ID",
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	if err := h.service.RemoveTagFromExercise(exerciseID, tagID, userUUID); err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "REMOVE_TAG_FAILED",
				Message: "Failed to remove tag from exercise",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Tag removed successfully",
		},
	})
}

// CreateTag handles POST /api/v1/admin/tags
func (h *ExerciseHandler) CreateTag(c *gin.Context) {
	var req models.CreateTagRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	tag, err := h.service.CreateTag(req.Name, req.Slug)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "CREATE_TAG_FAILED",
				Message: "Failed to create tag",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    tag,
	})
}

// GetBankQuestions handles GET /api/v1/admin/question-bank
func (h *ExerciseHandler) GetBankQuestions(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	skillType := c.Query("skill_type")
	questionType := c.Query("question_type")

	questions, total, err := h.service.GetBankQuestions(skillType, questionType, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "FETCH_FAILED",
				Message: "Failed to fetch question bank",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"questions":  questions,
			"total":      total,
			"page":       page,
			"limit":      limit,
			"totalPages": (total + limit - 1) / limit,
		},
	})
}

// CreateBankQuestion handles POST /api/v1/admin/question-bank
func (h *ExerciseHandler) CreateBankQuestion(c *gin.Context) {
	var req models.CreateBankQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	question, err := h.service.CreateBankQuestion(&req, userUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "CREATE_FAILED",
				Message: "Failed to create question",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, Response{
		Success: true,
		Data:    question,
	})
}

// UpdateBankQuestion handles PUT /api/v1/admin/question-bank/:id
func (h *ExerciseHandler) UpdateBankQuestion(c *gin.Context) {
	questionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid question ID",
			},
		})
		return
	}

	var req models.UpdateBankQuestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_REQUEST",
				Message: "Invalid request body",
				Details: err.Error(),
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	if err := h.service.UpdateBankQuestion(questionID, &req, userUUID); err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "UPDATE_FAILED",
				Message: "Failed to update question",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Question updated successfully",
		},
	})
}

// DeleteBankQuestion handles DELETE /api/v1/admin/question-bank/:id
func (h *ExerciseHandler) DeleteBankQuestion(c *gin.Context) {
	questionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid question ID",
			},
		})
		return
	}

	userID, _ := c.Get("user_id")
	userUUID, _ := uuid.Parse(userID.(string))

	if err := h.service.DeleteBankQuestion(questionID, userUUID); err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "DELETE_FAILED",
				Message: "Failed to delete question",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data: gin.H{
			"message": "Question deleted successfully",
		},
	})
}

// GetExerciseAnalytics handles GET /api/v1/admin/exercises/:id/analytics
func (h *ExerciseHandler) GetExerciseAnalytics(c *gin.Context) {
	exerciseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "INVALID_ID",
				Message: "Invalid exercise ID",
			},
		})
		return
	}

	analytics, err := h.service.GetExerciseAnalytics(exerciseID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Success: false,
			Error: &ErrorInfo{
				Code:    "FETCH_FAILED",
				Message: "Failed to fetch analytics",
				Details: err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Success: true,
		Data:    analytics,
	})
}

// HealthCheck handles GET /health
func (h *ExerciseHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "exercise-service",
	})
}
