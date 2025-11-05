package ielts

import (
	"testing"
)

// TestConvertListeningScore tests listening score conversion
func TestConvertListeningScore(t *testing.T) {
	tests := []struct {
		name     string
		correct  int
		total    int
		expected float64
	}{
		// Official IELTS conversion table (40 questions)
		{"40/40 correct", 40, 40, 9.0},
		{"39/40 correct", 39, 40, 9.0},
		{"38/40 correct", 38, 40, 8.5},
		{"37/40 correct", 37, 40, 8.5},
		{"35/40 correct", 35, 40, 8.0},
		{"32/40 correct", 32, 40, 7.5},
		{"30/40 correct", 30, 40, 7.0},
		{"26/40 correct", 26, 40, 6.5},
		{"23/40 correct", 23, 40, 6.0},
		{"18/40 correct", 18, 40, 5.5},
		{"16/40 correct", 16, 40, 5.0},
		{"13/40 correct", 13, 40, 4.5},
		{"10/40 correct", 10, 40, 4.0},
		{"8/40 correct", 8, 40, 3.5},
		{"6/40 correct", 6, 40, 3.0},
		{"4/40 correct", 4, 40, 2.5},
		{"2/40 correct", 2, 40, 2.0},
		{"1/40 correct", 1, 40, 1.0},
		{"0/40 correct", 0, 40, 0.0},

		// Practice tests with different question counts (normalized)
		{"20/20 correct (100%)", 20, 20, 9.0}, // 40/40 normalized = 9.0
		{"15/20 correct (75%)", 15, 20, 7.0},  // 30/40 normalized = 7.0
		{"10/20 correct (50%)", 10, 20, 5.5},  // 20/40 normalized = 5.5
		{"12/15 correct (80%)", 12, 15, 7.5},  // 32/40 normalized = 7.5
		{"5/10 correct (50%)", 5, 10, 5.5},    // 20/40 normalized = 5.5

		// Edge cases
		{"zero total", 5, 0, 0.0},
		{"negative correct", -1, 40, 0.0},
		{"correct > total", 50, 40, 9.0}, // Clamped to 40
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ConvertListeningScore(tt.correct, tt.total)
			if result != tt.expected {
				t.Errorf("ConvertListeningScore(%d, %d) = %.1f; want %.1f",
					tt.correct, tt.total, result, tt.expected)
			}
		})
	}
}

// TestConvertReadingScoreAcademic tests reading score conversion for Academic module
func TestConvertReadingScoreAcademic(t *testing.T) {
	tests := []struct {
		name     string
		correct  int
		total    int
		expected float64
	}{
		// Official IELTS Academic conversion table
		{"40/40 correct", 40, 40, 9.0},
		{"39/40 correct", 39, 40, 9.0},
		{"37/40 correct", 37, 40, 8.5},
		{"35/40 correct", 35, 40, 8.0},
		{"33/40 correct", 33, 40, 7.5},
		{"30/40 correct", 30, 40, 7.0},
		{"27/40 correct", 27, 40, 6.5},
		{"23/40 correct", 23, 40, 6.0},
		{"19/40 correct", 19, 40, 5.5},
		{"15/40 correct", 15, 40, 5.0},
		{"13/40 correct", 13, 40, 4.5},
		{"10/40 correct", 10, 40, 4.0},
		{"8/40 correct", 8, 40, 3.5},
		{"6/40 correct", 6, 40, 3.0},
		{"4/40 correct", 4, 40, 2.5},
		{"2/40 correct", 2, 40, 2.0},
		{"1/40 correct", 1, 40, 1.0},
		{"0/40 correct", 0, 40, 0.0},

		// Practice tests normalized
		{"15/20 correct (75%)", 15, 20, 7.0}, // 30/40 normalized
		{"12/15 correct (80%)", 12, 15, 7.0}, // 32/40 normalized = 7.0
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ConvertReadingScore(tt.correct, tt.total, "academic")
			if result != tt.expected {
				t.Errorf("ConvertReadingScore(%d, %d, academic) = %.1f; want %.1f",
					tt.correct, tt.total, result, tt.expected)
			}
		})
	}
}

// TestConvertReadingScoreGeneral tests reading score conversion for General Training
func TestConvertReadingScoreGeneral(t *testing.T) {
	tests := []struct {
		name     string
		correct  int
		total    int
		expected float64
	}{
		// Official IELTS General Training conversion table
		{"40/40 correct", 40, 40, 9.0},
		{"39/40 correct", 39, 40, 8.5},
		{"37/40 correct", 37, 40, 8.0},
		{"36/40 correct", 36, 40, 7.5},
		{"34/40 correct", 34, 40, 7.0},
		{"32/40 correct", 32, 40, 6.5},
		{"30/40 correct", 30, 40, 6.0},
		{"27/40 correct", 27, 40, 5.5},
		{"23/40 correct", 23, 40, 5.0},
		{"19/40 correct", 19, 40, 4.5},
		{"15/40 correct", 15, 40, 4.0},
		{"12/40 correct", 12, 40, 3.5},
		{"9/40 correct", 9, 40, 3.0},
		{"6/40 correct", 6, 40, 2.5},
		{"4/40 correct", 4, 40, 2.0},
		{"2/40 correct", 2, 40, 1.0},
		{"0/40 correct", 0, 40, 0.0},

		// Test different test type variations
		{"general_training", 34, 40, 7.0},
		{"gt", 34, 40, 7.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ConvertReadingScore(tt.correct, tt.total, "general")
			if result != tt.expected {
				t.Errorf("ConvertReadingScore(%d, %d, general) = %.1f; want %.1f",
					tt.correct, tt.total, result, tt.expected)
			}
		})
	}
}

// TestCalculateWritingBand tests writing band calculation
func TestCalculateWritingBand(t *testing.T) {
	tests := []struct {
		name string
		ta   float64 // Task Achievement
		cc   float64 // Coherence & Cohesion
		lr   float64 // Lexical Resource
		gra  float64 // Grammatical Range & Accuracy
		want float64
	}{
		{"All 7.0", 7.0, 7.0, 7.0, 7.0, 7.0},
		{"All 6.5", 6.5, 6.5, 6.5, 6.5, 6.5},
		{"Mixed scores 1", 7.0, 6.5, 7.0, 6.5, 7.0}, // 6.75 → 7.0
		{"Mixed scores 2", 7.0, 6.5, 6.5, 6.0, 6.5}, // 6.5
		{"Mixed scores 3", 8.0, 7.5, 7.0, 7.5, 7.5}, // 7.5
		{"Mixed scores 4", 6.0, 6.0, 6.5, 6.5, 6.5}, // 6.25 → 6.5
		{"High scores", 8.5, 8.0, 8.5, 8.0, 8.5},    // 8.25 → 8.5
		{"Low scores", 5.0, 5.0, 5.5, 5.0, 5.0},

		// Edge cases
		{"All zeros", 0.0, 0.0, 0.0, 0.0, 0.0},
		{"Invalid negative", -1.0, 7.0, 7.0, 7.0, 0.0},
		{"Invalid > 9", 10.0, 7.0, 7.0, 7.0, 0.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := CalculateWritingBand(tt.ta, tt.cc, tt.lr, tt.gra)
			if result != tt.want {
				t.Errorf("CalculateWritingBand(%.1f, %.1f, %.1f, %.1f) = %.1f; want %.1f",
					tt.ta, tt.cc, tt.lr, tt.gra, result, tt.want)
			}
		})
	}
}

// TestCalculateSpeakingBand tests speaking band calculation
func TestCalculateSpeakingBand(t *testing.T) {
	tests := []struct {
		name string
		fc   float64 // Fluency & Coherence
		lr   float64 // Lexical Resource
		gra  float64 // Grammatical Range & Accuracy
		pr   float64 // Pronunciation
		want float64
	}{
		{"All 7.0", 7.0, 7.0, 7.0, 7.0, 7.0},
		{"All 6.5", 6.5, 6.5, 6.5, 6.5, 6.5},
		{"Mixed scores 1", 7.5, 7.0, 7.0, 7.5, 7.5}, // 7.25 → 7.5
		{"Mixed scores 2", 7.0, 6.5, 7.0, 6.5, 7.0}, // 6.75 → 7.0
		{"Mixed scores 3", 8.0, 8.0, 7.5, 7.5, 8.0}, // 7.75 → 8.0
		{"High scores", 8.5, 8.5, 8.0, 8.0, 8.5},    // 8.25 → 8.5
		{"Low scores", 5.0, 5.0, 5.5, 5.0, 5.0},

		// Edge cases
		{"All zeros", 0.0, 0.0, 0.0, 0.0, 0.0},
		{"Invalid negative", -1.0, 7.0, 7.0, 7.0, 0.0},
		{"Invalid > 9", 10.0, 7.0, 7.0, 7.0, 0.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := CalculateSpeakingBand(tt.fc, tt.lr, tt.gra, tt.pr)
			if result != tt.want {
				t.Errorf("CalculateSpeakingBand(%.1f, %.1f, %.1f, %.1f) = %.1f; want %.1f",
					tt.fc, tt.lr, tt.gra, tt.pr, result, tt.want)
			}
		})
	}
}

// TestCalculateOverallBand tests overall band calculation
func TestCalculateOverallBand(t *testing.T) {
	tests := []struct {
		name      string
		listening float64
		reading   float64
		writing   float64
		speaking  float64
		want      float64
	}{
		{"All 7.0", 7.0, 7.0, 7.0, 7.0, 7.0},
		{"All 6.5", 6.5, 6.5, 6.5, 6.5, 6.5},
		{"Mixed 1", 8.0, 7.0, 7.0, 7.5, 7.5},     // 7.375 → 7.5
		{"Mixed 2", 7.5, 6.5, 6.5, 7.0, 7.0},     // 6.875 → 7.0
		{"Mixed 3", 8.0, 7.5, 7.0, 7.0, 7.5},     // 7.375 → 7.5
		{"High scores", 8.5, 8.0, 8.0, 8.5, 8.5}, // 8.25 → 8.5
		{"Low scores", 5.0, 5.5, 5.0, 5.5, 5.5},  // 5.25 → 5.5

		// Partial scores (some skills not taken)
		{"Only L&R", 7.0, 7.0, 0.0, 0.0, 7.0},
		{"Only W&S", 0.0, 0.0, 7.5, 7.0, 7.5}, // 7.25 → 7.5
		{"3 skills", 7.0, 6.5, 7.0, 0.0, 7.0}, // 6.83 → 7.0

		// Edge cases
		{"All zeros", 0.0, 0.0, 0.0, 0.0, 0.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := CalculateOverallBand(tt.listening, tt.reading, tt.writing, tt.speaking)
			if result != tt.want {
				t.Errorf("CalculateOverallBand(%.1f, %.1f, %.1f, %.1f) = %.1f; want %.1f",
					tt.listening, tt.reading, tt.writing, tt.speaking, result, tt.want)
			}
		})
	}
}

// TestRoundToIELTSBand tests IELTS rounding rules
func TestRoundToIELTSBand(t *testing.T) {
	tests := []struct {
		name  string
		score float64
		want  float64
	}{
		// Official IELTS rounding rules
		{"6.125 rounds to 6.0", 6.125, 6.0},
		{"6.25 rounds to 6.5", 6.25, 6.5},
		{"6.375 rounds to 6.5", 6.375, 6.5},
		{"6.5 stays 6.5", 6.5, 6.5},
		{"6.625 rounds to 6.5", 6.625, 6.5},
		{"6.75 rounds to 7.0", 6.75, 7.0},
		{"6.875 rounds to 7.0", 6.875, 7.0},
		{"7.0 stays 7.0", 7.0, 7.0},

		// Edge cases
		{"0.0 stays 0.0", 0.0, 0.0},
		{"9.0 stays 9.0", 9.0, 9.0},
		{"Negative rounds to 0.0", -1.0, 0.0},
		{"Above 9 clamps to 9.0", 10.0, 9.0},

		// More examples
		{"5.1 rounds to 5.0", 5.1, 5.0},
		{"5.3 rounds to 5.5", 5.3, 5.5},
		{"5.7 rounds to 5.5", 5.7, 5.5},
		{"5.9 rounds to 6.0", 5.9, 6.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := RoundToIELTSBand(tt.score)
			if result != tt.want {
				t.Errorf("RoundToIELTSBand(%.3f) = %.1f; want %.1f",
					tt.score, result, tt.want)
			}
		})
	}
}

// TestValidateBandScore tests band score validation
func TestValidateBandScore(t *testing.T) {
	validScores := []float64{0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5,
		5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0}

	for _, score := range validScores {
		t.Run("valid score", func(t *testing.T) {
			if err := ValidateBandScore(score); err != nil {
				t.Errorf("ValidateBandScore(%.1f) should be valid, got error: %v", score, err)
			}
		})
	}

	invalidScores := []float64{-1.0, -0.5, 9.5, 10.0, 6.1, 6.3, 6.7, 6.9}

	for _, score := range invalidScores {
		t.Run("invalid score", func(t *testing.T) {
			if err := ValidateBandScore(score); err == nil {
				t.Errorf("ValidateBandScore(%.1f) should be invalid", score)
			}
		})
	}
}

// TestIsValidBandScore tests the boolean validation function
func TestIsValidBandScore(t *testing.T) {
	tests := []struct {
		score float64
		want  bool
	}{
		{7.0, true},
		{7.5, true},
		{0.0, true},
		{9.0, true},
		{7.3, false},
		{-1.0, false},
		{10.0, false},
	}

	for _, tt := range tests {
		t.Run("check validity", func(t *testing.T) {
			result := IsValidBandScore(tt.score)
			if result != tt.want {
				t.Errorf("IsValidBandScore(%.1f) = %v; want %v", tt.score, result, tt.want)
			}
		})
	}
}

// TestValidateRawScore tests raw score validation
func TestValidateRawScore(t *testing.T) {
	tests := []struct {
		name    string
		correct int
		total   int
		wantErr bool
	}{
		{"Valid 35/40", 35, 40, false},
		{"Valid 0/40", 0, 40, false},
		{"Valid 40/40", 40, 40, false},
		{"Invalid negative correct", -1, 40, true},
		{"Invalid zero total", 10, 0, true},
		{"Invalid correct > total", 45, 40, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateRawScore(tt.correct, tt.total)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateRawScore(%d, %d) error = %v; wantErr %v",
					tt.correct, tt.total, err, tt.wantErr)
			}
		})
	}
}
