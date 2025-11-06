package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/bisosad1501/DATN/services/ai-service/internal/config"
	"github.com/bisosad1501/DATN/services/ai-service/internal/database"
)

type AIRepository struct {
	db     *database.Database
	config *config.Config
}

func NewAIRepository(db *database.Database, cfg *config.Config) *AIRepository {
	return &AIRepository{db: db, config: cfg}
}

// ========== CACHE METHODS (Phase 5.3) ==========

// CacheEntry for storing evaluation results
type CacheEntry struct {
	Hash      string // Using content_hash from ai_evaluation_cache
	Content   string // Serialized JSON from detailed_scores + feedback
	ExpiresAt sql.NullTime
}

// GetCachedEvaluation retrieves cached evaluation by content_hash
func (r *AIRepository) GetCachedEvaluation(hash string) (*CacheEntry, error) {
	query := `
        SELECT 
            content_hash,
            COALESCE(
                jsonb_build_object(
                    'overall_band', overall_band_score,
                    'criteria_scores', detailed_scores,
                    'detailed_feedback', feedback,
                    'examiner_feedback', feedback->>'examiner_feedback',
                    'strengths', feedback->'strengths',
                    'areas_for_improvement', feedback->'areas_for_improvement'
                )::text,
                '{}'
            ) as content,
            expires_at
        FROM ai_evaluation_cache 
        WHERE content_hash = $1 AND (expires_at IS NULL OR expires_at > NOW())
        LIMIT 1
    `

	var entry CacheEntry
	err := r.db.DB.QueryRow(query, hash).Scan(&entry.Hash, &entry.Content, &entry.ExpiresAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	// Update hit_count and last_hit_at
	go func() {
		updateQuery := `UPDATE ai_evaluation_cache SET hit_count = hit_count + 1, last_hit_at = NOW() WHERE content_hash = $1`
		r.db.DB.Exec(updateQuery, hash)
	}()

	return &entry, nil
}

// SaveCachedEvaluation saves evaluation result to cache
func (r *AIRepository) SaveCachedEvaluation(hash, content string, expiresAt interface{}) error {
	// Parse content to extract fields for ai_evaluation_cache schema
	var evalData map[string]interface{}
	if err := json.Unmarshal([]byte(content), &evalData); err != nil {
		return fmt.Errorf("failed to parse evaluation content: %w", err)
	}

	// Extract fields
	overallBand, _ := evalData["overall_band"].(float64)
	criteriaScores, _ := json.Marshal(evalData["criteria_scores"])
	feedback, _ := json.Marshal(evalData)

	// Determine skill_type from criteria_scores structure
	skillType := "writing"
	if criteriaScoresMap, ok := evalData["criteria_scores"].(map[string]interface{}); ok {
		if _, hasTC := criteriaScoresMap["task_achievement"]; hasTC {
			skillType = "writing"
		} else if _, hasFC := criteriaScoresMap["fluency_coherence"]; hasFC {
			skillType = "speaking"
		}
	}

	query := `
        INSERT INTO ai_evaluation_cache (
            content_hash, skill_type, task_type, overall_band_score,
            detailed_scores, feedback, expires_at, created_at
        )
        VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, $7, NOW())
        ON CONFLICT (content_hash) 
        DO UPDATE SET 
            overall_band_score = $4,
            detailed_scores = $5::jsonb,
            feedback = $6::jsonb,
            expires_at = $7,
            hit_count = ai_evaluation_cache.hit_count + 1,
            last_hit_at = NOW()
    `
	_, err := r.db.DB.Exec(query, hash, skillType, "task2", overallBand, string(criteriaScores), string(feedback), expiresAt)
	return err
}

// DeleteCachedEvaluation removes cached entry
func (r *AIRepository) DeleteCachedEvaluation(hash string) error {
	query := `DELETE FROM ai_evaluation_cache WHERE content_hash = $1`
	_, err := r.db.DB.Exec(query, hash)
	return err
}

// GetCacheStatistics returns cache statistics
func (r *AIRepository) GetCacheStatistics() (map[string]interface{}, error) {
	query := `
        SELECT 
            COUNT(*) as total_entries,
            COUNT(*) FILTER (WHERE expires_at < NOW()) as expired_entries,
            COUNT(*) FILTER (WHERE expires_at >= NOW() OR expires_at IS NULL) as valid_entries,
            SUM(hit_count) as total_hits,
            AVG(hit_count) as avg_hits_per_entry,
            COUNT(*) FILTER (WHERE skill_type = 'writing') as writing_entries,
            COUNT(*) FILTER (WHERE skill_type = 'speaking') as speaking_entries,
            ROUND(pg_total_relation_size('ai_evaluation_cache')::numeric / 1024 / 1024, 2) as cache_size_mb
        FROM ai_evaluation_cache
    `

	var total, expired, valid, totalHits, writingEntries, speakingEntries int
	var avgHits, sizeMB float64
	err := r.db.DB.QueryRow(query).Scan(&total, &expired, &valid, &totalHits, &avgHits, &writingEntries, &speakingEntries, &sizeMB)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"total_entries":      total,
		"expired_entries":    expired,
		"valid_entries":      valid,
		"total_hits":         totalHits,
		"avg_hits_per_entry": avgHits,
		"writing_entries":    writingEntries,
		"speaking_entries":   speakingEntries,
		"cache_size_mb":      sizeMB,
	}, nil
}
