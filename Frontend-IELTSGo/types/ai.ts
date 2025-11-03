// AI Service Types

// Writing Submission
export interface WritingSubmissionRequest {
  task_type: "task1" | "task2"
  task_prompt_id?: string
  task_prompt_text: string
  essay_text: string
  time_spent_seconds?: number
  exercise_id?: string
  course_id?: string
  lesson_id?: string
}

export interface WritingSubmission {
  id: string
  user_id: string
  task_type: "task1" | "task2"
  task_prompt_id?: string
  task_prompt_text: string
  essay_text: string
  word_count: number
  time_spent_seconds?: number
  submitted_from: string
  status: "pending" | "processing" | "completed" | "failed"
  exercise_id?: string
  course_id?: string
  lesson_id?: string
  submitted_at: string
  created_at: string
  updated_at: string
}

export interface WritingEvaluation {
  id: string
  submission_id: string
  overall_band_score: number
  task_achievement: number
  coherence_cohesion: number
  lexical_resource: number
  grammatical_range: number
  detailed_feedback: string
  strengths: string[]
  areas_for_improvement: string[]
  created_at: string
  updated_at: string
}

export interface WritingSubmissionResponse {
  submission: WritingSubmission
  evaluation?: WritingEvaluation
}

// Speaking Submission
export interface SpeakingSubmissionRequest {
  part_number: 1 | 2 | 3
  task_prompt_id?: string
  task_prompt_text: string
  audio_url?: string
  audio_duration_seconds: number
  audio_format?: string
  audio_file_size_bytes?: number
  exercise_id?: string
  course_id?: string
  lesson_id?: string
}

export interface SpeakingSubmission {
  id: string
  user_id: string
  part_number: number
  task_prompt_id?: string
  task_prompt_text: string
  audio_url: string
  audio_duration_seconds: number
  audio_format?: string
  audio_file_size_bytes?: number
  transcript_text?: string
  transcript_word_count?: number
  recorded_from: string
  status: "pending" | "transcribing" | "processing" | "completed" | "failed"
  exercise_id?: string
  course_id?: string
  lesson_id?: string
  submitted_at: string
  created_at: string
  updated_at: string
}

export interface SpeakingEvaluation {
  id: string
  submission_id: string
  overall_band_score: number
  fluency_coherence: number
  lexical_resource: number
  grammatical_range: number
  pronunciation: number
  detailed_feedback: {
    fluency_coherence: {
      score: number
      analysis: string
    }
    lexical_resource: {
      score: number
      analysis: string
    }
    grammatical_range: {
      score: number
      analysis: string
    }
    pronunciation: {
      score: number
      analysis: string
    }
  }
  examiner_feedback: string
  strengths: string[]
  areas_for_improvement: string[]
  speech_rate_wpm?: number
  pause_frequency?: number
  filler_words_count?: number
  hesitation_count?: number
  vocabulary_level?: string
  created_at: string
  updated_at: string
}

export interface SpeakingSubmissionResponse {
  submission: SpeakingSubmission
  evaluation?: SpeakingEvaluation
}

// Writing Prompt
export interface WritingPrompt {
  id: string
  task_type: "task1" | "task2"
  prompt_text: string
  visual_type?: string
  visual_url?: string
  topic?: string
  difficulty?: "easy" | "medium" | "hard"
  has_sample_answer: boolean
  sample_answer_text?: string
  sample_answer_band_score?: number
  times_used: number
  average_score?: number
  is_published: boolean
  created_by?: string
  created_at: string
  updated_at: string
}

// Speaking Prompt
export interface SpeakingPrompt {
  id: string
  part_number: number
  prompt_text: string
  cue_card_topic?: string
  cue_card_points?: string[]
  preparation_time_seconds?: number
  speaking_time_seconds?: number
  follow_up_questions?: string[]
  topic_category?: string
  difficulty?: "easy" | "medium" | "hard"
  has_sample_answer: boolean
  sample_answer_text?: string
  sample_answer_audio_url?: string
  sample_answer_band_score?: number
  times_used: number
  average_score?: number
  is_published: boolean
  created_by?: string
  created_at: string
  updated_at: string
}

// API Request/Response Types
export interface WritingPromptsResponse {
  prompts: WritingPrompt[]
  total: number
}

export interface SpeakingPromptsResponse {
  prompts: SpeakingPrompt[]
  total: number
}

export interface WritingSubmissionsResponse {
  submissions: WritingSubmission[]
  total: number
}

export interface SpeakingSubmissionsResponse {
  submissions: SpeakingSubmission[]
  total: number
}

// Admin Request Types
export interface CreateWritingPromptRequest {
  task_type: "task1" | "task2"
  prompt_text: string
  visual_type?: string
  visual_url?: string
  topic?: string
  difficulty?: "easy" | "medium" | "hard"
  has_sample_answer?: boolean
  sample_answer_text?: string
  sample_answer_band_score?: number
  is_published?: boolean
}

export interface UpdateWritingPromptRequest {
  task_type?: "task1" | "task2"
  prompt_text?: string
  visual_type?: string
  visual_url?: string
  topic?: string
  difficulty?: "easy" | "medium" | "hard"
  has_sample_answer?: boolean
  sample_answer_text?: string
  sample_answer_band_score?: number
  is_published?: boolean
}

export interface CreateSpeakingPromptRequest {
  part_number: number
  prompt_text: string
  cue_card_topic?: string
  cue_card_points?: string[]
  preparation_time_seconds?: number
  speaking_time_seconds?: number
  follow_up_questions?: string[]
  topic_category?: string
  difficulty?: "easy" | "medium" | "hard"
  has_sample_answer?: boolean
  sample_answer_text?: string
  sample_answer_audio_url?: string
  sample_answer_band_score?: number
  is_published?: boolean
}

export interface UpdateSpeakingPromptRequest {
  part_number?: number
  prompt_text?: string
  cue_card_topic?: string
  cue_card_points?: string[]
  preparation_time_seconds?: number
  speaking_time_seconds?: number
  follow_up_questions?: string[]
  topic_category?: string
  difficulty?: "easy" | "medium" | "hard"
  has_sample_answer?: boolean
  sample_answer_text?: string
  sample_answer_audio_url?: string
  sample_answer_band_score?: number
  is_published?: boolean
}

