package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"time"
)

// StorageServiceClient handles communication with Storage Service
type StorageServiceClient struct {
	baseURL    string
	httpClient *http.Client
}

// NewStorageServiceClient creates a new storage service client
func NewStorageServiceClient(baseURL string) *StorageServiceClient {
	return &StorageServiceClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// UploadURLRequest represents request to get presigned upload URL (DEPRECATED - use UploadAudio instead)
type UploadURLRequest struct {
	UserID        string `json:"user_id"`
	FileExtension string `json:"file_extension"`
	ContentType   string `json:"content_type"`
}

// UploadURLResponse represents response from storage service (DEPRECATED)
type UploadURLResponse struct {
	Success bool `json:"success"`
	Data    struct {
		UploadURL   string `json:"upload_url"`
		AudioURL    string `json:"audio_url"`
		ObjectName  string `json:"object_name"`
		ExpiresAt   int64  `json:"expires_at"`
		ContentType string `json:"content_type"`
	} `json:"data"`
	Error string `json:"error,omitempty"`
}

// AudioInfoResponse represents audio file metadata
type AudioInfoResponse struct {
	Success bool `json:"success"`
	Data    struct {
		ObjectName   string `json:"object_name"`
		Size         int64  `json:"size"`
		ContentType  string `json:"content_type"`
		LastModified int64  `json:"last_modified"`
	} `json:"data"`
	Error string `json:"error,omitempty"`
}

// UploadAudioResponse represents upload response
type UploadAudioResponse struct {
	Success bool `json:"success"`
	Data    struct {
		AudioURL         string `json:"audio_url"`          // Presigned URL (for frontend) or internal URL
		PublicAudioURL   string `json:"public_audio_url"`   // Presigned URL (for frontend)
		InternalAudioURL string `json:"internal_audio_url"` // Internal URL (for backend/AI service)
		ObjectName       string `json:"object_name"`
		ContentType      string `json:"content_type"`
		Size             int64  `json:"size"`
	} `json:"data"`
	Error string `json:"error,omitempty"`
}

// GetAudioInfo gets audio file metadata
func (c *StorageServiceClient) GetAudioInfo(objectName string) (*AudioInfoResponse, error) {
	url := fmt.Sprintf("%s/api/v1/storage/audio/info/%s", c.baseURL, objectName)

	resp, err := c.httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to call storage service: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var result AudioInfoResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if !result.Success {
		return nil, fmt.Errorf("storage service error: %s", result.Error)
	}

	return &result, nil
}

// PresignedURLResponse represents presigned URL response
type PresignedURLResponse struct {
	Success bool `json:"success"`
	Data    struct {
		PresignedURL string `json:"presigned_url"`
		ObjectName   string `json:"object_name"`
		ExpiresIn    int    `json:"expires_in"` // seconds
	} `json:"data"`
	Error string `json:"error,omitempty"`
}

// GetPresignedURL gets a presigned URL for an audio file
func (c *StorageServiceClient) GetPresignedURL(objectName string, expiryDays int) (*PresignedURLResponse, error) {
	url := fmt.Sprintf("%s/api/v1/storage/audio/presigned-url/%s?expiry_days=%d", c.baseURL, objectName, expiryDays)

	resp, err := c.httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to call storage service: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var result PresignedURLResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if !result.Success {
		return nil, fmt.Errorf("storage service error: %s", result.Error)
	}

	return &result, nil
}

// UploadAudio uploads audio file to storage service
func (c *StorageServiceClient) UploadAudio(userID string, file io.Reader, header *multipart.FileHeader) (*UploadAudioResponse, error) {
	url := fmt.Sprintf("%s/api/v1/storage/audio/upload", c.baseURL)

	// Create multipart form
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// Add user_id field
	if err := writer.WriteField("user_id", userID); err != nil {
		return nil, fmt.Errorf("failed to write user_id field: %w", err)
	}

	// Add file field
	part, err := writer.CreateFormFile("file", header.Filename)
	if err != nil {
		return nil, fmt.Errorf("failed to create form file: %w", err)
	}

	if _, err := io.Copy(part, file); err != nil {
		return nil, fmt.Errorf("failed to copy file: %w", err)
	}

	if err := writer.Close(); err != nil {
		return nil, fmt.Errorf("failed to close writer: %w", err)
	}

	// Send request
	resp, err := c.httpClient.Post(url, writer.FormDataContentType(), body)
	if err != nil {
		return nil, fmt.Errorf("failed to call storage service: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var result UploadAudioResponse
	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if !result.Success {
		return nil, fmt.Errorf("storage service error: %s", result.Error)
	}

	return &result, nil
}

// DeleteAudio deletes audio file
func (c *StorageServiceClient) DeleteAudio(objectName string) error {
	url := fmt.Sprintf("%s/api/v1/storage/audio/%s", c.baseURL, objectName)

	req, err := http.NewRequest(http.MethodDelete, url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to call storage service: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("storage service returned status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}
