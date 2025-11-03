package validation

import (
	"fmt"
	"mime"
	"strings"
)

// Audio validation constants
const (
	MaxAudioFileSizeMB    = 50
	MaxAudioFileSizeBytes = 50 * 1024 * 1024 // 50 MB
	MaxAudioDurationSeconds = 300             // 5 minutes
	MaxEssayLength        = 50000             // 50,000 characters
)

// Allowed audio formats
var AllowedAudioFormats = []string{
	"audio/mpeg",    // mp3
	"audio/mp3",
	"audio/wav",
	"audio/wave",
	"audio/x-wav",
	"audio/mp4",     // m4a
	"audio/x-m4a",
	"audio/ogg",
	"audio/vorbis",
}

// Allowed file extensions (lowercase)
var AllowedExtensions = []string{
	".mp3",
	".wav",
	".m4a",
	".ogg",
}

// Writing validation constants
const (
	MinWordCountTask1 = 150 // IELTS Writing Task 1 minimum
	MinWordCountTask2 = 250 // IELTS Writing Task 2 minimum
	MaxWordCount      = 10000 // Maximum to prevent spam
)

// ValidateAudioFile validates audio file size, duration, and format
func ValidateAudioFile(fileSizeBytes int64, durationSeconds int, fileName string, mimeType string) error {
	// Validate file size
	if fileSizeBytes > MaxAudioFileSizeBytes {
		return fmt.Errorf("audio file size (%d MB) exceeds maximum allowed size (%d MB)", 
			fileSizeBytes/(1024*1024), MaxAudioFileSizeMB)
	}

	// Validate duration
	if durationSeconds > MaxAudioDurationSeconds {
		return fmt.Errorf("audio duration (%d seconds) exceeds maximum allowed duration (%d seconds)", 
			durationSeconds, MaxAudioDurationSeconds)
	}

	// Validate MIME type
	if mimeType != "" {
		if !isAllowedMimeType(mimeType) {
			return fmt.Errorf("audio format '%s' is not allowed. Allowed formats: mp3, wav, m4a, ogg", mimeType)
		}
	}

	// Validate file extension
	if fileName != "" {
		ext := strings.ToLower(fileName)
		if !hasAllowedExtension(ext) {
			return fmt.Errorf("file extension not allowed. Allowed extensions: .mp3, .wav, .m4a, .ogg")
		}
	}

	return nil
}

// ValidateWritingSubmission validates writing submission text and word count
func ValidateWritingSubmission(taskType string, essayText string) error {
	// Validate essay length
	if len(essayText) > MaxEssayLength {
		return fmt.Errorf("essay text length (%d characters) exceeds maximum allowed length (%d characters)", 
			len(essayText), MaxEssayLength)
	}

	// Calculate word count
	words := strings.Fields(essayText)
	wordCount := len(words)

	// Validate word count based on task type
	var minWords int
	switch taskType {
	case "task1":
		minWords = MinWordCountTask1
	case "task2":
		minWords = MinWordCountTask2
	default:
		return fmt.Errorf("invalid task type: %s. Must be 'task1' or 'task2'", taskType)
	}

	if wordCount < minWords {
		return fmt.Errorf("essay word count (%d) is below minimum required for %s (%d words)", 
			wordCount, taskType, minWords)
	}

	if wordCount > MaxWordCount {
		return fmt.Errorf("essay word count (%d) exceeds maximum allowed (%d words)", 
			wordCount, MaxWordCount)
	}

	return nil
}

// isAllowedMimeType checks if MIME type is in allowed list
func isAllowedMimeType(mimeType string) bool {
	// Check exact match
	for _, allowed := range AllowedAudioFormats {
		if mimeType == allowed {
			return true
		}
	}

	// Try parsing and checking base type
	mediaType, _, err := mime.ParseMediaType(mimeType)
	if err != nil {
		return false
	}

	for _, allowed := range AllowedAudioFormats {
		allowedMediaType, _, _ := mime.ParseMediaType(allowed)
		if mediaType == allowedMediaType {
			return true
		}
	}

	return false
}

// hasAllowedExtension checks if file extension is allowed
func hasAllowedExtension(fileName string) bool {
	fileName = strings.ToLower(fileName)
	for _, ext := range AllowedExtensions {
		if strings.HasSuffix(fileName, ext) {
			return true
		}
	}
	return false
}

