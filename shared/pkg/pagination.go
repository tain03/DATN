package pkg

// PaginationResponse represents standardized pagination metadata
type PaginationResponse struct {
	Page       int `json:"page"`
	Limit      int `json:"limit"`
	TotalItems int `json:"total_items"`
	TotalPages int `json:"total_pages"`
}

// PaginatedResponse represents a standardized paginated response
type PaginatedResponse struct {
	Data       interface{}        `json:"data"`
	Pagination PaginationResponse `json:"pagination"`
}

// CalculateTotalPages calculates total pages from total items and limit
func CalculateTotalPages(totalItems, limit int) int {
	if limit <= 0 {
		return 1
	}
	return (totalItems + limit - 1) / limit
}

// ValidatePaginationParams validates and normalizes pagination parameters
func ValidatePaginationParams(page, limit, maxLimit, defaultLimit int) (validatedPage, validatedLimit int) {
	// Validate page
	if page < 1 {
		page = 1
	}

	// Validate limit
	if limit < 1 {
		limit = defaultLimit
	}
	if limit > maxLimit {
		limit = maxLimit
	}

	return page, limit
}

