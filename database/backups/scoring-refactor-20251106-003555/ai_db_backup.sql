--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13
-- Dumped by pg_dump version 15.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: calculate_speaking_band_score(numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: ielts_admin
--

CREATE FUNCTION public.calculate_speaking_band_score(fluency_coherence numeric, lexical_resource numeric, grammar_accuracy numeric, pronunciation numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN ROUND((fluency_coherence + lexical_resource + grammar_accuracy + pronunciation) / 4, 1);
END;
$$;


ALTER FUNCTION public.calculate_speaking_band_score(fluency_coherence numeric, lexical_resource numeric, grammar_accuracy numeric, pronunciation numeric) OWNER TO ielts_admin;

--
-- Name: calculate_writing_band_score(numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: ielts_admin
--

CREATE FUNCTION public.calculate_writing_band_score(task_achievement numeric, coherence_cohesion numeric, lexical_resource numeric, grammar_accuracy numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN ROUND((task_achievement + coherence_cohesion + lexical_resource + grammar_accuracy) / 4, 1);
END;
$$;


ALTER FUNCTION public.calculate_writing_band_score(task_achievement numeric, coherence_cohesion numeric, lexical_resource numeric, grammar_accuracy numeric) OWNER TO ielts_admin;

--
-- Name: create_ai_processing_task(); Type: FUNCTION; Schema: public; Owner: ielts_admin
--

CREATE FUNCTION public.create_ai_processing_task() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_TABLE_NAME = 'writing_submissions' THEN
        INSERT INTO ai_processing_queue (task_type, submission_id, submission_type)
        VALUES ('evaluate_writing', NEW.id, 'writing');
    ELSIF TG_TABLE_NAME = 'speaking_submissions' THEN
        -- First transcribe, then evaluate
        INSERT INTO ai_processing_queue (task_type, submission_id, submission_type, priority)
        VALUES ('transcribe_audio', NEW.id, 'speaking', 8);
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.create_ai_processing_task() OWNER TO ielts_admin;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: ielts_admin
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO ielts_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_model_versions; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.ai_model_versions (
    id integer NOT NULL,
    model_type character varying(50) NOT NULL,
    model_name character varying(100) NOT NULL,
    version character varying(50) NOT NULL,
    description text,
    average_accuracy numeric(5,2),
    average_processing_time_ms integer,
    is_active boolean DEFAULT true,
    is_default boolean DEFAULT false,
    deployed_at timestamp without time zone,
    deprecated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_model_versions OWNER TO ielts_admin;

--
-- Name: ai_model_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: ielts_admin
--

CREATE SEQUENCE public.ai_model_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ai_model_versions_id_seq OWNER TO ielts_admin;

--
-- Name: ai_model_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ielts_admin
--

ALTER SEQUENCE public.ai_model_versions_id_seq OWNED BY public.ai_model_versions.id;


--
-- Name: ai_processing_queue; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.ai_processing_queue (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    task_type character varying(50) NOT NULL,
    submission_id uuid NOT NULL,
    submission_type character varying(20) NOT NULL,
    priority integer DEFAULT 5,
    status character varying(20) DEFAULT 'queued'::character varying,
    retry_count integer DEFAULT 0,
    max_retries integer DEFAULT 3,
    error_message text,
    worker_id character varying(100),
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_processing_queue OWNER TO ielts_admin;

--
-- Name: TABLE ai_processing_queue; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.ai_processing_queue IS 'Hàng đợi xử lý AI';


--
-- Name: evaluation_feedback_ratings; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.evaluation_feedback_ratings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    evaluation_type character varying(20) NOT NULL,
    evaluation_id uuid NOT NULL,
    is_helpful boolean,
    accuracy_rating integer,
    feedback_text text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT evaluation_feedback_ratings_accuracy_rating_check CHECK (((accuracy_rating >= 1) AND (accuracy_rating <= 5)))
);


ALTER TABLE public.evaluation_feedback_ratings OWNER TO ielts_admin;

--
-- Name: grading_criteria; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.grading_criteria (
    id integer NOT NULL,
    skill_type character varying(20) NOT NULL,
    criterion_name character varying(100) NOT NULL,
    band_score numeric(2,1) NOT NULL,
    description text NOT NULL,
    key_features text[],
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.grading_criteria OWNER TO ielts_admin;

--
-- Name: grading_criteria_id_seq; Type: SEQUENCE; Schema: public; Owner: ielts_admin
--

CREATE SEQUENCE public.grading_criteria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.grading_criteria_id_seq OWNER TO ielts_admin;

--
-- Name: grading_criteria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ielts_admin
--

ALTER SEQUENCE public.grading_criteria_id_seq OWNED BY public.grading_criteria.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.schema_migrations (
    id integer NOT NULL,
    migration_file character varying(255) NOT NULL,
    applied_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    checksum character varying(64)
);


ALTER TABLE public.schema_migrations OWNER TO ielts_admin;

--
-- Name: schema_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: ielts_admin
--

CREATE SEQUENCE public.schema_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schema_migrations_id_seq OWNER TO ielts_admin;

--
-- Name: schema_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ielts_admin
--

ALTER SEQUENCE public.schema_migrations_id_seq OWNED BY public.schema_migrations.id;


--
-- Name: speaking_evaluations; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.speaking_evaluations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    submission_id uuid NOT NULL,
    overall_band_score numeric(2,1) NOT NULL,
    fluency_coherence_score numeric(2,1) NOT NULL,
    lexical_resource_score numeric(2,1) NOT NULL,
    grammar_accuracy_score numeric(2,1) NOT NULL,
    pronunciation_score numeric(2,1) NOT NULL,
    pronunciation_accuracy numeric(5,2),
    problematic_sounds jsonb,
    intonation_score numeric(3,2),
    stress_accuracy numeric(3,2),
    speech_rate_wpm integer,
    pause_frequency numeric(5,2),
    filler_words_count integer,
    filler_words_used text[],
    hesitation_count integer,
    vocabulary_level character varying(20),
    unique_words_count integer,
    advanced_words_used text[],
    vocabulary_suggestions jsonb,
    grammar_errors jsonb,
    grammar_error_count integer DEFAULT 0,
    sentence_complexity character varying(20),
    answers_question_directly boolean DEFAULT false,
    uses_linking_devices boolean DEFAULT false,
    coherence_feedback text,
    content_relevance_score numeric(3,2),
    idea_development_score numeric(3,2),
    content_feedback text,
    strengths text[],
    weaknesses text[],
    detailed_feedback text NOT NULL,
    improvement_suggestions text[],
    transcription_model character varying(100),
    evaluation_model character varying(100),
    model_version character varying(50),
    confidence_score numeric(3,2),
    transcription_time_ms integer,
    evaluation_time_ms integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.speaking_evaluations OWNER TO ielts_admin;

--
-- Name: TABLE speaking_evaluations; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.speaking_evaluations IS 'Kết quả đánh giá Speaking từ AI';


--
-- Name: speaking_prompts; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.speaking_prompts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    part_number integer NOT NULL,
    prompt_text text NOT NULL,
    cue_card_topic character varying(200),
    cue_card_points text[],
    preparation_time_seconds integer DEFAULT 60,
    speaking_time_seconds integer DEFAULT 120,
    follow_up_questions text[],
    topic_category character varying(100),
    difficulty character varying(20),
    has_sample_answer boolean DEFAULT false,
    sample_answer_text text,
    sample_answer_audio_url text,
    sample_answer_band_score numeric(2,1),
    times_used integer DEFAULT 0,
    average_score numeric(2,1),
    is_published boolean DEFAULT true,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.speaking_prompts OWNER TO ielts_admin;

--
-- Name: TABLE speaking_prompts; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.speaking_prompts IS 'Ngân hàng đề bài Speaking';


--
-- Name: speaking_submissions; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.speaking_submissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    part_number integer NOT NULL,
    task_prompt_id uuid,
    task_prompt_text text NOT NULL,
    audio_url text NOT NULL,
    audio_duration_seconds integer NOT NULL,
    audio_format character varying(20),
    audio_file_size_bytes bigint,
    transcript_text text,
    transcript_word_count integer,
    recorded_from character varying(20),
    status character varying(20) DEFAULT 'pending'::character varying,
    exercise_id uuid,
    course_id uuid,
    lesson_id uuid,
    submitted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    transcribed_at timestamp without time zone,
    evaluated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.speaking_submissions OWNER TO ielts_admin;

--
-- Name: TABLE speaking_submissions; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.speaking_submissions IS 'Bài nói Speaking được ghi âm để AI chấm điểm';


--
-- Name: writing_evaluations; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.writing_evaluations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    submission_id uuid NOT NULL,
    overall_band_score numeric(2,1) NOT NULL,
    task_achievement_score numeric(2,1) NOT NULL,
    coherence_cohesion_score numeric(2,1) NOT NULL,
    lexical_resource_score numeric(2,1) NOT NULL,
    grammar_accuracy_score numeric(2,1) NOT NULL,
    strengths text[],
    weaknesses text[],
    grammar_errors jsonb,
    grammar_error_count integer DEFAULT 0,
    vocabulary_level character varying(20),
    vocabulary_range_score numeric(3,2),
    vocabulary_suggestions jsonb,
    paragraph_count integer,
    has_introduction boolean DEFAULT false,
    has_conclusion boolean DEFAULT false,
    structure_feedback text,
    linking_words_used text[],
    coherence_feedback text,
    addresses_all_parts boolean DEFAULT false,
    task_response_feedback text,
    detailed_feedback text NOT NULL,
    improvement_suggestions text[],
    ai_model_name character varying(100),
    ai_model_version character varying(50),
    confidence_score numeric(3,2),
    processing_time_ms integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    detailed_feedback_json jsonb
);


ALTER TABLE public.writing_evaluations OWNER TO ielts_admin;

--
-- Name: TABLE writing_evaluations; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.writing_evaluations IS 'Kết quả đánh giá Writing từ AI';


--
-- Name: writing_prompts; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.writing_prompts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    task_type character varying(20) NOT NULL,
    prompt_text text NOT NULL,
    visual_type character varying(50),
    visual_url text,
    topic character varying(100),
    difficulty character varying(20),
    has_sample_answer boolean DEFAULT false,
    sample_answer_text text,
    sample_answer_band_score numeric(2,1),
    times_used integer DEFAULT 0,
    average_score numeric(2,1),
    is_published boolean DEFAULT true,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.writing_prompts OWNER TO ielts_admin;

--
-- Name: TABLE writing_prompts; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.writing_prompts IS 'Ngân hàng đề bài Writing';


--
-- Name: writing_submissions; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.writing_submissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    task_type character varying(20) NOT NULL,
    task_prompt_id uuid,
    task_prompt_text text NOT NULL,
    essay_text text NOT NULL,
    word_count integer NOT NULL,
    time_spent_seconds integer,
    submitted_from character varying(20),
    status character varying(20) DEFAULT 'pending'::character varying,
    exercise_id uuid,
    course_id uuid,
    lesson_id uuid,
    submitted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    evaluated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.writing_submissions OWNER TO ielts_admin;

--
-- Name: TABLE writing_submissions; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.writing_submissions IS 'Bài viết Writing được nộp để AI chấm điểm';


--
-- Name: ai_model_versions id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.ai_model_versions ALTER COLUMN id SET DEFAULT nextval('public.ai_model_versions_id_seq'::regclass);


--
-- Name: grading_criteria id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.grading_criteria ALTER COLUMN id SET DEFAULT nextval('public.grading_criteria_id_seq'::regclass);


--
-- Name: schema_migrations id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.schema_migrations ALTER COLUMN id SET DEFAULT nextval('public.schema_migrations_id_seq'::regclass);


--
-- Data for Name: ai_model_versions; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.ai_model_versions (id, model_type, model_name, version, description, average_accuracy, average_processing_time_ms, is_active, is_default, deployed_at, deprecated_at, created_at) FROM stdin;
1	transcription	Whisper	v1.0.0	OpenAI Whisper model for speech-to-text	95.50	2500	t	t	2025-10-05 13:50:30.234418	\N	2025-10-05 13:50:30.234418
2	writing_evaluation	IELTS Writing Evaluator	v2.1.0	Custom model for IELTS Writing Task 1 & 2 evaluation	87.30	3200	t	t	2025-10-20 13:50:30.234418	\N	2025-10-15 13:50:30.234418
3	speaking_evaluation	IELTS Speaking Evaluator	v2.0.0	Custom model for IELTS Speaking evaluation	85.80	4500	t	t	2025-10-15 13:50:30.234418	\N	2025-10-10 13:50:30.234418
\.


--
-- Data for Name: ai_processing_queue; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.ai_processing_queue (id, task_type, submission_id, submission_type, priority, status, retry_count, max_retries, error_message, worker_id, started_at, completed_at, created_at, updated_at) FROM stdin;
64a20655-7497-485a-8726-27ec7e87db42	evaluate_writing	b56ebe64-80ec-4cc3-9307-600695e0d73a	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
3f4745a4-2cfc-44d0-aff5-bcef86da7875	evaluate_writing	a45d3079-b7c6-4e19-83b7-c663dd13df86	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
d4a9211f-da2e-4d5c-b707-93ad67ba3160	evaluate_writing	876d8172-ddf8-4ee3-942d-bbcc484b81ee	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
a2f71fd3-d976-4052-8fbd-404317ad61a6	evaluate_writing	20b17b2b-1dc7-40b3-8ce1-1565ff0b4c51	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
7c733034-5de2-4526-9e16-d4d977c37267	evaluate_writing	868366d1-5e47-482e-91f0-cc43e9db6702	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
560a89c1-f8eb-43f4-a5e8-9551f2b26c3a	evaluate_writing	12c07299-ae35-43f0-b3e2-d8380ceccfb3	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
455c8a5a-34ae-49af-b1b0-72264a7a0bd0	evaluate_writing	4c49384f-b74c-4ee2-9d65-25403a43a283	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
42c43fbf-1711-406e-8955-debaef35e1ff	evaluate_writing	9f0408f1-62d9-47e3-a437-cbdd47b45398	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
fd24d521-b340-4484-b2c5-23cf75238c36	evaluate_writing	9011ca23-109e-4da4-8953-98e5427f6ec6	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
f1ee4a0e-6eb3-4a5d-8522-df65c02113a7	evaluate_writing	b006ba61-4ecd-4671-b294-8ec0236a6ec5	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
2484f118-356d-4897-9821-d04250457185	evaluate_writing	ff2447b1-eab2-499f-9ce3-70662506997a	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
2bc2508b-32af-4651-8495-1a8df9809d20	evaluate_writing	e6990f6f-f326-4d6e-8115-08ece88383b3	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
6be4a9ed-b927-41f3-9287-f3274216d679	evaluate_writing	33109d5a-a263-48a2-b7bf-d028e8c12298	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
558427fc-caaf-47c7-8fa8-89c90b7d3dcc	evaluate_writing	8771fac9-d05c-4552-a2d9-639d654b8777	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
a7e54d0f-edbc-4690-84e8-b03886428952	evaluate_writing	e33533f5-c7b2-42d1-8c46-743d5ed0e7fc	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
ed1f52a2-284f-48c4-a690-3887876fd0be	evaluate_writing	65067a9e-c7a3-434b-9f40-bcaa70836de1	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
5ae0a3fd-3a41-4352-93e2-90d84089a984	evaluate_writing	e9679626-7eb6-4d78-93e3-71d6ebaef360	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
4101cf47-ce95-4937-a525-9e4ff4eb55dc	evaluate_writing	e33575bd-49d5-405a-9bbc-6aba5419f81b	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
564b15a2-1986-439c-b31c-149355e79565	evaluate_writing	1527493f-9d60-4742-aee8-1479119e34dc	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
afd2e13d-8c02-48ef-a4e1-9787e21b6148	evaluate_writing	b71789c4-9f29-4469-8daf-4f295f54de96	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
ca745a6f-827b-4787-9a26-953871bfdf70	evaluate_writing	0aa801fc-2273-4c75-b619-80df32f2deba	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
290c2051-bd67-4d90-a1c6-68183b84d358	evaluate_writing	c06f04a7-a21f-4997-87b1-a7255fb7b9ce	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
1d9ce581-e7d3-4acb-a551-b5b09bab7a87	evaluate_writing	a5e1dfa3-9d20-4d36-9469-fba806afba22	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
ab30aa2d-0519-496e-a1bf-b513baa495e0	evaluate_writing	acae74e8-bc3f-45e3-881b-a50b9416a979	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
210ab575-c39a-42ba-aab7-c5b96af7f1c5	evaluate_writing	13e341b3-6b0e-42e4-ac0f-fcae4051bff4	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
40990fbd-8b63-4d7e-9836-761e487188c5	evaluate_writing	9ac46ecc-e9fe-4efa-8cad-dc3f2d2c7b9c	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
673838ba-374d-45cc-b222-7d303a1da694	evaluate_writing	9196efe4-7cd9-4369-9c4f-ffa2fac625c2	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
4eb07a26-c1ec-4424-b8c6-779e1d020b4f	evaluate_writing	1ff1564d-7f38-4667-9787-bd996b067a6e	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
4704945f-1716-44ce-9c22-18cc1cf69e1b	evaluate_writing	86c77596-fc9c-416c-a62c-e2512ffd6af4	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
67c6dab0-b529-4c94-831b-782ca86709f4	evaluate_writing	83f728fb-8650-4242-bb0a-2a9efca229d4	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
85e8bac0-1ef6-4370-bb6e-d2944582ec65	evaluate_writing	aa0b8d67-cdfd-4339-8def-5bb886119e84	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
a8e18679-b9d1-4894-b219-8732c657ce96	evaluate_writing	822d3a43-b9da-4f09-a4fb-b7c8f605106d	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
16cf6b1b-10c4-43e7-89e3-0908641bce87	evaluate_writing	7cc9c67d-9a39-408f-b205-5cffc90e6504	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
b6353528-e91a-4832-a11b-4987f599e10a	evaluate_writing	66ca3590-be90-4150-a818-17433a6c8bd1	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
bd0d14f0-ed19-4ec2-acde-93ff5c0c6ad8	evaluate_writing	a2dc05c3-cb91-4b72-ad75-cd25672b51a7	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
72a4ca1d-33b8-4022-be32-a735ef2cbe39	evaluate_writing	19b68d67-aaee-4fa8-8f4e-edbd9e4a5dc8	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
c11c00c4-47e9-45d1-8562-da9739076e83	evaluate_writing	53858c73-bd79-44a0-9525-80afec16df91	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
46656462-9292-4e86-9e8a-d9e0396f00cd	evaluate_writing	905247e4-636b-4f6b-9cf4-adedcbe982fe	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
9feb9c09-9cee-47f7-b98e-ab4a849e90d9	evaluate_writing	efd0f979-b8b2-4323-b9e3-ed8df41270c0	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
8f677af4-ff50-4b2a-85c9-f724162efb9f	evaluate_writing	3de41e4a-fb63-4b06-8bf0-08d0850705a6	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
7d101202-f31d-4a97-bd6f-2dd9f1e4ffd8	evaluate_writing	aecce938-f8b1-47a1-b580-d6fa5bc7c184	writing	5	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-04 19:19:47.21058
761c3f1c-3a2d-43a4-90bc-0d75f499c510	transcribe_audio	91097023-476e-44f1-9bfa-dd54f67df687	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
bd1195ed-1db8-4995-b330-94cb05c5e7d0	transcribe_audio	60d49598-2d9a-4d00-a985-5dbbd1384398	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
6cee8a33-e557-4f89-a256-5f5f8bfb14be	transcribe_audio	36f93bbd-4746-4a2c-99a2-ac41ab0c4c09	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
978c1098-ba42-4a89-a9af-cfda481198be	transcribe_audio	1ca54436-2cba-46c4-aec4-95f910e14c6e	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
d6a4cefd-19cc-4159-9dbf-06e353de34ae	transcribe_audio	36603805-ec4c-45b4-9a0d-5910ca8cccc8	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
92cf3b58-f03c-4f21-b919-a987f990de48	transcribe_audio	5d3a8835-b149-4092-88da-138c11504e02	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
714fbb46-b7be-4d0d-88ec-5652f7d1b219	transcribe_audio	caf8ee57-a21b-4a02-9add-3844ffc8092f	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
936af38f-f02b-4fd7-aeb2-614e0bb1b490	transcribe_audio	58fea851-0379-4aea-a65b-4e2a53528479	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
b7e8fa84-84dd-4fb2-8b8c-9db248145a5c	transcribe_audio	ed7888f1-a86c-4ba8-8967-020c8e1da9bd	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
f3caaaee-b8fa-422f-aa21-62acbedad11e	transcribe_audio	028a0fd5-f365-4eb6-bb8e-c6c08a1e5a03	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
9ec5a21c-4c92-46f4-8c1b-4213715929cf	transcribe_audio	d73728ef-f6e7-4790-9ba0-cbaeebeea907	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
e9fa2e88-25d1-4481-8c51-25379299b115	transcribe_audio	2f8e7329-6e3a-43c2-b2a6-ef1f6befd0a8	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
1bcabfea-4a95-4b29-887b-c874beab5055	transcribe_audio	234f4167-b33e-4eb8-a271-19a281208f98	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
d92d62e3-f67f-47bb-ac54-08a25af04d85	transcribe_audio	06e1ac62-43d9-4d3d-be70-6ee401edb775	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
ad015490-3d2d-478d-a201-c14bab6eeb0b	transcribe_audio	d543f120-5f9d-43bf-bae0-881db910cdc7	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
8bd7c381-a59d-4d8b-ab84-f7291ba8b9f8	transcribe_audio	7428648f-cc52-413e-84c1-d282445d322f	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
c01a3d09-6813-4171-9fb9-a9920fd38af9	transcribe_audio	f4b681a9-cf15-44e6-9411-2a76d8ebdb83	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
a7ab9888-8d4d-4c33-9213-60b5d2f92055	transcribe_audio	3b6e454b-dcd7-4ed0-ab32-f76398e0a791	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
5e214e3c-e9a9-43e2-9b1a-b0fb4300f819	transcribe_audio	92f7ee5b-3a4e-4214-82c6-e267f59a290e	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
336353e6-a355-4c3b-934c-efcaef489613	transcribe_audio	f38a8b08-f49f-4939-926c-28b2f623e8fb	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
6d398304-d771-4b75-973b-41b8b8f6acef	transcribe_audio	93e0c6ad-7e9f-4b05-92e3-99ff6bd6d442	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
c40c9cd4-b056-4ee1-b209-7cd4a86c326b	transcribe_audio	809bdf19-9ccb-4d7a-be83-962f63dffa19	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
d553d563-f194-495c-8682-1162a95f94eb	transcribe_audio	cff62ed9-deb2-49b9-b8d3-af356f0ade51	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
67e9348c-629a-4bdd-8ff9-35093530cb49	transcribe_audio	766f9f3d-54cc-4744-b4f8-d3d3b6d97273	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
99e51928-41eb-4a82-8438-56a92b926a9f	transcribe_audio	e82f5111-8571-4de9-9478-936970dd7c23	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
fa522105-4194-4cc9-a98d-6bb18ddffb0c	transcribe_audio	943c639d-d07b-4a76-aff0-8843877845f5	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
2e4c5296-291c-45ad-9963-ee7edc0920e8	transcribe_audio	b9e60dc1-6943-4961-9d1a-62d83cc43d83	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
70ffd026-b9f5-482e-8107-4e0da9933685	transcribe_audio	fd30d219-3974-4bcf-97f2-93ae829a03d8	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
f1e620e6-b6d3-433b-82eb-853aba4dcee0	transcribe_audio	a51db878-c741-4a65-b4ee-54d29e21f263	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
09151954-1c74-4a40-a40a-13bed90b517a	transcribe_audio	4ea83fb5-fc16-4f2a-beed-580069a832de	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
d095a591-f708-4ab0-acaa-3b0f561afcbc	transcribe_audio	22096d50-b23a-4b6f-83dd-6902b48e9a75	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
c56d77ea-17a6-4a72-831b-a1f35b419532	transcribe_audio	9e1b8319-ce9e-4f84-8276-c98f558c31f6	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
449fa321-34d8-44b8-9af8-154b9c788500	transcribe_audio	19b81924-6f4c-4786-8f4b-dff7b3c15b84	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
462af7b5-288d-439d-b758-1e7bc8651388	transcribe_audio	c74bea8c-cc9e-4f34-ad21-7370fc61adc2	speaking	8	queued	0	3	\N	\N	\N	\N	2025-11-04 19:19:47.226771	2025-11-04 19:19:47.226771
\.


--
-- Data for Name: evaluation_feedback_ratings; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.evaluation_feedback_ratings (id, user_id, evaluation_type, evaluation_id, is_helpful, accuracy_rating, feedback_text, created_at) FROM stdin;
e2444943-f602-4292-98b2-f6cc8e211eb0	f0000001-0000-0000-0000-000000000001	writing	dd8141c5-1f86-485e-a865-adba73fb461f	f	\N	Good feedback overall, but could be more specific in some areas.	2025-11-04 19:19:47.858396
99a78cd5-2b5e-4b26-b2ab-c3453d96be42	f0000011-0000-0000-0000-000000000011	writing	795dcc35-8770-4a1a-9be2-164f35e720ed	t	\N	\N	2025-11-04 19:19:47.858396
50296cf3-0a71-4a9b-91b5-809c86a3362f	f0000012-0000-0000-0000-000000000012	writing	7426f7b9-245c-4e48-ab98-71c4c3472a11	f	3	The evaluation was accurate and detailed.	2025-11-04 19:19:47.858396
21718677-66d9-4cb7-be65-98265f2655e6	f0000021-0000-0000-0000-000000000021	writing	2a3aaf7f-14d6-4ccc-a709-ed45f7b7c049	t	5	The evaluation was accurate and detailed.	2025-11-04 19:19:47.858396
d9a4eb51-8abd-425e-bfad-0b55138206c5	f0000023-0000-0000-0000-000000000023	writing	21ba63bf-fecf-4983-b660-b70fcaff1f1b	t	\N	\N	2025-11-04 19:19:47.858396
42ef3aeb-93cd-4b54-98ca-1e90c42be5cd	f0000026-0000-0000-0000-000000000026	writing	3d9eb793-5380-45f6-ae02-e4973e335264	t	\N	The evaluation was accurate and detailed.	2025-11-04 19:19:47.858396
82af40d5-2b41-453a-8e36-351fda6e3335	f0000028-0000-0000-0000-000000000028	writing	433fb19d-3957-49ee-a62a-6669a00e490e	t	2	Good feedback overall, but could be more specific in some areas.	2025-11-04 19:19:47.858396
b39e6902-189d-4243-bdce-ad8ef54168ea	f0000031-0000-0000-0000-000000000031	writing	d96a4c91-d12f-44b3-b9f4-730b0d7be42e	t	\N	Good feedback overall, but could be more specific in some areas.	2025-11-04 19:19:47.858396
f2abb219-e736-4738-a414-ed641949d9d5	f0000035-0000-0000-0000-000000000035	writing	af07dcaf-5ead-473c-80ee-f45043fbb278	f	2	Good feedback overall, but could be more specific in some areas.	2025-11-04 19:19:47.858396
87d79297-7516-4716-9711-8cbdd933142f	f0000038-0000-0000-0000-000000000038	writing	2ef4a8c1-2fa9-4951-9f58-b4ad7e523015	t	\N	\N	2025-11-04 19:19:47.858396
1898431e-2d78-42e6-bd03-2e2e0976d907	f0000040-0000-0000-0000-000000000040	writing	441c7c9a-da4f-4e4c-be8f-885f833154ab	t	5	\N	2025-11-04 19:19:47.858396
4f2ea3de-1e5c-4143-9d70-f7fbc7e2e13d	f0000002-0000-0000-0000-000000000002	speaking	d845d79f-f978-47da-85fd-1de52dcd9717	t	\N	Good overall, but the fluency score seems too low.	2025-11-04 19:19:47.862547
6d987b70-c6c7-4633-bc75-e4aeec4585b8	f0000005-0000-0000-0000-000000000005	speaking	c94660fd-d5fc-4b8f-aac6-597e76d7f3f2	f	\N	The evaluation helped me understand my weaknesses.	2025-11-04 19:19:47.862547
d242a3d6-2b4b-4261-9e91-ac9aa88c878f	f0000010-0000-0000-0000-000000000010	speaking	47dc3867-ea1d-4ae8-bf5f-8c59b56eb2ff	f	2	Good overall, but the fluency score seems too low.	2025-11-04 19:19:47.862547
e38a6d40-066a-4192-8afe-c4dbf2fb3415	f0000015-0000-0000-0000-000000000015	speaking	134a65e7-75f9-4233-9dde-e32a24bf05b6	f	\N	\N	2025-11-04 19:19:47.862547
d5dfe1ca-cddb-44a8-b33d-a3a5ddaa7b6c	f0000018-0000-0000-0000-000000000018	speaking	5d9e6161-1d90-46ad-bb90-b726a748fe47	t	4	Good overall, but the fluency score seems too low.	2025-11-04 19:19:47.862547
505a4248-3f1c-48b7-b375-a0e2267c127b	f0000026-0000-0000-0000-000000000026	speaking	b161c88c-5143-43db-828f-7560497e72ab	t	\N	The evaluation helped me understand my weaknesses.	2025-11-04 19:19:47.862547
c0731fe5-24ea-4bca-9d73-77cda0d90df0	f0000028-0000-0000-0000-000000000028	speaking	63a74dd5-3f2d-47e9-951e-ffe065a577a1	f	\N	Good overall, but the fluency score seems too low.	2025-11-04 19:19:47.862547
c960c35a-fef8-47e9-9f27-355e03d4facb	f0000032-0000-0000-0000-000000000032	speaking	d1dd2257-9ab2-4438-8462-b3c292ba9445	t	\N	The evaluation helped me understand my weaknesses.	2025-11-04 19:19:47.862547
\.


--
-- Data for Name: grading_criteria; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.grading_criteria (id, skill_type, criterion_name, band_score, description, key_features, created_at) FROM stdin;
1	writing	task_achievement	9.0	Band 9 Task Achievement	{"Fully addresses all parts","Presents fully developed position","Ideas are relevant, extended and supported"}	2025-10-30 18:58:53.796828
2	writing	task_achievement	7.0	Band 7 Task Achievement	{"Addresses all parts","Presents clear position","Main ideas are extended and supported"}	2025-10-30 18:58:53.796828
3	writing	coherence_cohesion	9.0	Band 9 Coherence and Cohesion	{"Uses cohesion seamlessly","Skillful paragraph management","No errors in cohesive devices"}	2025-10-30 18:58:53.796828
4	writing	lexical_resource	9.0	Band 9 Lexical Resource	{"Wide range of vocabulary","Natural and sophisticated usage","Rare minor errors"}	2025-10-30 18:58:53.796828
5	writing	grammar_accuracy	9.0	Band 9 Grammatical Range and Accuracy	{"Wide range of structures","Full flexibility and accuracy","Rare minor errors"}	2025-10-30 18:58:53.796828
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.schema_migrations (id, migration_file, applied_at, checksum) FROM stdin;
1	001_add_verification_codes.sql	2025-10-30 18:59:24.698306	\N
2	006_add_exercise_constraints.sql	2025-10-30 18:59:24.724749	\N
3	007_add_notification_constraints.sql	2025-10-30 18:59:24.757854	\N
4	007_add_performance_indexes.sql	2025-10-30 18:59:24.795506	\N
5	008_add_total_exercises_to_modules.sql	2025-10-30 18:59:24.822053	\N
6	008_separate_lessons_and_exercises.sql	2025-10-30 18:59:24.85448	\N
7	009_update_seed_data_exercises.sql	2025-10-30 18:59:24.881453	\N
8	010_reseed_with_new_structure.sql	2025-10-30 18:59:24.914272	\N
9	011_remove_video_watch_percentage.sql	2025-10-30 18:59:24.950068	\N
10	012_enable_dblink_for_cross_database_queries.sql	2025-10-30 18:59:24.981886	\N
11	013_remove_deprecated_study_time_fields.sql	2025-10-30 18:59:25.035806	\N
12	014_add_last_position_seconds.sql	2025-10-31 02:47:17.223603	\N
13	015_fix_submission_scores.sql	2025-10-31 08:15:26.611835	\N
14	016_add_leaderboard_indexes.sql	2025-10-31 08:15:26.647661	\N
15	013_add_locale_to_user_preferences.sql	2025-10-31 22:28:01.625043	\N
16	017_add_user_follows_table.sql	2025-11-01 08:48:54.794521	\N
17	018_add_detailed_feedback_json_to_writing_evaluations.sql	2025-11-03 18:47:27.056287	\N
18	019_add_ielts_test_type_to_exercises.sql	2025-11-04 05:32:57.38213	\N
\.


--
-- Data for Name: speaking_evaluations; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.speaking_evaluations (id, submission_id, overall_band_score, fluency_coherence_score, lexical_resource_score, grammar_accuracy_score, pronunciation_score, pronunciation_accuracy, problematic_sounds, intonation_score, stress_accuracy, speech_rate_wpm, pause_frequency, filler_words_count, filler_words_used, hesitation_count, vocabulary_level, unique_words_count, advanced_words_used, vocabulary_suggestions, grammar_errors, grammar_error_count, sentence_complexity, answers_question_directly, uses_linking_devices, coherence_feedback, content_relevance_score, idea_development_score, content_feedback, strengths, weaknesses, detailed_feedback, improvement_suggestions, transcription_model, evaluation_model, model_version, confidence_score, transcription_time_ms, evaluation_time_ms, created_at) FROM stdin;
ceb10687-3e8a-4b40-859d-03e077881beb	91097023-476e-44f1-9bfa-dd54f67df687	6.6	7.4	8.4	5.7	8.1	77.65	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.96	0.96	150	4.17	3	{um,uh,like}	2	advanced	76	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	complex	t	t	The response flows well with appropriate linking devices.	0.87	0.98	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.83	2071	4461	2025-11-04 19:19:47.230552
d845d79f-f978-47da-85fd-1de52dcd9717	60d49598-2d9a-4d00-a985-5dbbd1384398	7.7	6.3	8.0	5.5	6.2	77.90	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.93	0.91	157	2.29	2	{um,uh,like}	3	basic	98	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	complex	t	t	The response flows well with appropriate linking devices.	0.86	0.91	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.89	2601	4525	2025-11-04 19:19:47.230552
9c12d3c2-2a1b-4846-bb29-4c0bbfef2db3	36f93bbd-4746-4a2c-99a2-ac41ab0c4c09	7.2	5.8	7.3	6.6	6.0	71.72	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.88	0.76	132	4.61	4	{um,uh,like}	4	basic	88	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	1	complex	t	t	The response flows well with appropriate linking devices.	0.94	0.79	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.90	2906	6058	2025-11-04 19:19:47.230552
6e18c07c-6b2c-4df3-9736-c23644873c62	1ca54436-2cba-46c4-aec4-95f910e14c6e	6.7	8.4	7.9	7.8	8.1	83.37	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.76	0.71	143	4.53	5	{um,uh,like}	2	advanced	96	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	simple	f	t	The response flows well with appropriate linking devices.	0.75	0.81	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.87	2133	5923	2025-11-04 19:19:47.230552
c94660fd-d5fc-4b8f-aac6-597e76d7f3f2	36603805-ec4c-45b4-9a0d-5910ca8cccc8	7.8	8.2	6.7	5.8	5.6	71.50	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.78	0.79	132	3.17	3	{um,uh,like}	3	basic	82	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	1	complex	t	f	The response flows well with appropriate linking devices.	0.73	0.86	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.81	2421	6687	2025-11-04 19:19:47.230552
6703c631-1d3e-46c4-817e-2909023cbe63	5d3a8835-b149-4092-88da-138c11504e02	6.7	6.7	7.2	7.7	7.2	78.31	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.73	0.98	122	3.77	2	{um,uh,like}	4	advanced	72	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	1	complex	t	f	The response flows well with appropriate linking devices.	0.81	0.75	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.92	2299	4698	2025-11-04 19:19:47.230552
3531d332-ac75-451b-9a20-e2cc8af81422	caf8ee57-a21b-4a02-9add-3844ffc8092f	7.8	6.9	6.4	7.8	7.4	76.54	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.73	0.84	134	6.14	6	{um,uh,like}	1	intermediate	79	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	complex	t	t	The response flows well with appropriate linking devices.	0.99	0.85	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.84	2158	6209	2025-11-04 19:19:47.230552
18c3adf5-e056-4a96-9c8f-a9bcb7aa540d	ed7888f1-a86c-4ba8-8967-020c8e1da9bd	7.9	7.5	7.3	8.0	7.3	77.93	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.75	0.86	147	3.26	6	{um,uh,like}	1	basic	60	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	compound	f	t	The response flows well with appropriate linking devices.	0.77	0.97	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.82	2101	4036	2025-11-04 19:19:47.230552
47dc3867-ea1d-4ae8-bf5f-8c59b56eb2ff	028a0fd5-f365-4eb6-bb8e-c6c08a1e5a03	6.7	5.8	7.8	7.7	6.7	89.86	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.97	0.94	136	6.40	5	{um,uh,like}	2	basic	95	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	simple	t	f	The response flows well with appropriate linking devices.	0.91	0.84	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.86	2756	5443	2025-11-04 19:19:47.230552
a05acd68-93bb-454c-bbc4-0cbbf6084493	d73728ef-f6e7-4790-9ba0-cbaeebeea907	7.2	6.4	7.4	7.6	5.9	78.48	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	1.00	0.87	158	5.35	4	{um,uh,like}	2	basic	55	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	1	complex	t	t	The response flows well with appropriate linking devices.	0.98	0.85	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.95	2919	4060	2025-11-04 19:19:47.230552
134a65e7-75f9-4233-9dde-e32a24bf05b6	d543f120-5f9d-43bf-bae0-881db910cdc7	8.4	8.2	6.0	6.6	7.9	70.51	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.73	0.87	153	6.25	6	{um,uh,like}	2	basic	72	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	compound	t	t	The response flows well with appropriate linking devices.	0.80	0.76	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.86	2456	4334	2025-11-04 19:19:47.230552
91064e35-9078-4304-b074-eb6062f3921a	7428648f-cc52-413e-84c1-d282445d322f	5.6	8.0	5.6	6.3	5.6	76.80	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.85	0.89	132	6.21	5	{um,uh,like}	4	intermediate	67	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	compound	f	f	The response flows well with appropriate linking devices.	0.85	0.96	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.80	2240	4065	2025-11-04 19:19:47.230552
590f3eef-5c65-44a9-ac5a-28b71dec5256	f4b681a9-cf15-44e6-9411-2a76d8ebdb83	6.0	8.0	6.1	7.3	6.6	87.64	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.86	0.95	120	2.73	3	{um,uh,like}	4	intermediate	51	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	complex	t	t	The response flows well with appropriate linking devices.	0.95	0.93	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.82	2403	4914	2025-11-04 19:19:47.230552
5d9e6161-1d90-46ad-bb90-b726a748fe47	3b6e454b-dcd7-4ed0-ab32-f76398e0a791	6.9	7.8	8.4	6.6	8.0	75.40	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.75	0.97	126	2.16	3	{um,uh,like}	4	advanced	77	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	compound	t	t	The response flows well with appropriate linking devices.	0.84	0.96	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.91	2600	4559	2025-11-04 19:19:47.230552
c6a4eee2-b005-4dc4-b9c3-c0ebb0e628a6	92f7ee5b-3a4e-4214-82c6-e267f59a290e	7.7	7.1	7.2	8.5	6.8	88.20	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.82	0.77	153	6.38	6	{um,uh,like}	4	advanced	86	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	complex	t	t	The response flows well with appropriate linking devices.	0.94	0.76	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.91	2362	6354	2025-11-04 19:19:47.230552
d7d098b1-13c8-42e7-8b38-112e03f38197	f38a8b08-f49f-4939-926c-28b2f623e8fb	8.4	7.9	6.1	7.5	7.1	78.66	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.79	0.88	138	5.59	2	{um,uh,like}	1	advanced	54	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	4	compound	t	f	The response flows well with appropriate linking devices.	0.79	0.78	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.97	2808	6214	2025-11-04 19:19:47.230552
3262460d-c2d8-4504-850d-f93a588d5976	93e0c6ad-7e9f-4b05-92e3-99ff6bd6d442	7.2	5.7	7.7	6.7	6.7	81.21	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.72	0.80	140	3.69	4	{um,uh,like}	2	advanced	66	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	complex	t	t	The response flows well with appropriate linking devices.	0.76	0.84	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.98	2002	5394	2025-11-04 19:19:47.230552
74e1bd13-9c1f-4e4b-9c24-3836838b3f02	cff62ed9-deb2-49b9-b8d3-af356f0ade51	8.3	6.7	7.5	6.7	5.9	72.65	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.99	0.97	157	4.97	2	{um,uh,like}	2	advanced	92	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	complex	t	t	The response flows well with appropriate linking devices.	0.78	0.74	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.92	2465	6265	2025-11-04 19:19:47.230552
3361c34d-6e84-48de-a5c8-66f81b71698f	e82f5111-8571-4de9-9478-936970dd7c23	6.3	6.4	5.9	7.0	6.5	83.08	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.75	0.89	159	6.03	4	{um,uh,like}	3	basic	72	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	1	complex	t	t	The response flows well with appropriate linking devices.	0.98	0.82	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.93	2079	4084	2025-11-04 19:19:47.230552
b161c88c-5143-43db-828f-7560497e72ab	943c639d-d07b-4a76-aff0-8843877845f5	6.5	5.8	7.8	6.2	7.2	81.06	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.73	1.00	140	6.95	1	{um,uh,like}	2	advanced	60	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	1	simple	t	t	The response flows well with appropriate linking devices.	0.75	0.97	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.84	2841	4565	2025-11-04 19:19:47.230552
6fbb0dbc-173a-425e-98c5-ac414020b880	b9e60dc1-6943-4961-9d1a-62d83cc43d83	6.9	5.8	5.7	5.6	5.5	73.65	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.83	0.90	150	5.66	1	{um,uh,like}	1	intermediate	85	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	complex	t	t	The response flows well with appropriate linking devices.	0.77	0.76	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.86	2468	4867	2025-11-04 19:19:47.230552
63a74dd5-3f2d-47e9-951e-ffe065a577a1	fd30d219-3974-4bcf-97f2-93ae829a03d8	5.6	5.8	6.5	7.5	7.8	78.14	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.92	0.93	140	3.91	5	{um,uh,like}	3	advanced	63	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	compound	t	f	The response flows well with appropriate linking devices.	0.73	0.71	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.92	2672	6707	2025-11-04 19:19:47.230552
316eb244-ef42-4a29-8208-af74c5961137	a51db878-c741-4a65-b4ee-54d29e21f263	6.2	6.6	7.6	7.1	6.3	86.94	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.93	0.84	140	5.32	2	{um,uh,like}	3	intermediate	58	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	compound	t	t	The response flows well with appropriate linking devices.	1.00	0.72	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.83	2478	4507	2025-11-04 19:19:47.230552
e757391d-cfba-45a0-bce2-9e52036f9a6b	4ea83fb5-fc16-4f2a-beed-580069a832de	8.0	7.3	7.6	7.9	7.2	72.56	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.84	0.92	135	2.65	2	{um,uh,like}	4	advanced	63	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	complex	f	t	The response flows well with appropriate linking devices.	0.81	0.83	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.81	2429	6623	2025-11-04 19:19:47.230552
eb2c90e5-afe7-4e17-86d5-63a988e66da4	22096d50-b23a-4b6f-83dd-6902b48e9a75	6.5	7.7	8.1	6.6	7.4	87.08	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.82	0.72	128	5.75	4	{um,uh,like}	2	advanced	79	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	complex	t	t	The response flows well with appropriate linking devices.	0.74	0.79	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.86	2923	4574	2025-11-04 19:19:47.230552
d1dd2257-9ab2-4438-8462-b3c292ba9445	9e1b8319-ce9e-4f84-8276-c98f558c31f6	7.1	6.5	8.2	7.9	5.7	82.68	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.85	0.81	153	2.59	4	{um,uh,like}	3	basic	78	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	2	compound	f	t	The response flows well with appropriate linking devices.	0.82	0.99	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.80	2848	6206	2025-11-04 19:19:47.230552
cae5efef-2821-4004-9417-cd5098f78805	19b81924-6f4c-4786-8f4b-dff7b3c15b84	7.2	7.2	7.1	7.2	6.9	82.66	[{"word": "think", "issue": "Difficulty with th sound", "phoneme": "θ"}]	0.72	0.94	138	6.23	2	{um,uh,like}	3	advanced	89	{significant,substantial,considerable}	[{"word": "good", "suggestion": "excellent/outstanding"}]	[{"type": "tense consistency", "example": "...", "correction": "..."}]	3	compound	t	t	The response flows well with appropriate linking devices.	0.90	0.74	Content is relevant and well-developed.	{"Good pronunciation","Appropriate vocabulary","Clear ideas"}	{"Some hesitation","Could use more complex grammar","Work on intonation"}	Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.	{"Practice speaking more to improve fluency","Work on reducing hesitation","Try to use more complex sentence structures","Focus on pronunciation of difficult sounds"}	whisper-1	gpt-4	1.0	0.92	2820	4901	2025-11-04 19:19:47.230552
\.


--
-- Data for Name: speaking_prompts; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.speaking_prompts (id, part_number, prompt_text, cue_card_topic, cue_card_points, preparation_time_seconds, speaking_time_seconds, follow_up_questions, topic_category, difficulty, has_sample_answer, sample_answer_text, sample_answer_audio_url, sample_answer_band_score, times_used, average_score, is_published, created_by, created_at, updated_at) FROM stdin;
d1000001-0000-0000-0000-000000000001	1	Let's talk about your hometown. Where are you from?	\N	\N	\N	\N	\N	hometown	easy	t	I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a vibrant and bustling metropolis...	\N	6.5	78	6.4	t	b0000001-0000-0000-0000-000000000001	2025-11-04 19:19:47.208139	2025-11-04 19:19:47.208139
d1000002-0000-0000-0000-000000000002	1	Do you like reading? What kind of books do you prefer?	\N	\N	\N	\N	\N	hobbies	easy	t	Yes, I really enjoy reading. I particularly like fiction novels, especially science fiction and fantasy...	\N	7.0	65	6.8	t	b0000002-0000-0000-0000-000000000002	2025-11-04 19:19:47.208139	2025-11-04 19:19:47.208139
d2000001-0000-0000-0000-000000000003	2	Describe a memorable journey you have taken. You should say:\n- Where you went\n- When you went there\n- Who you went with\n- And explain why this journey was memorable for you.	A Memorable Journey	{"Where you went","When you went there","Who you went with","Why it was memorable"}	60	120	\N	travel	medium	t	I would like to describe a journey I took to Japan last summer. I went there with my family in July...	\N	7.5	52	7.2	t	b0000001-0000-0000-0000-000000000001	2025-11-04 19:19:47.208139	2025-11-04 19:19:47.208139
d2000002-0000-0000-0000-000000000004	2	Describe a person who has influenced you. You should say:\n- Who this person is\n- How you know them\n- What they have done\n- And explain why they have influenced you.	A Person Who Influenced You	{"Who the person is","How you know them","What they have done","Why they influenced you"}	60	120	\N	people	medium	t	I would like to talk about my high school English teacher, Ms. Nguyen. She has had a profound influence on my life...	\N	7.0	48	6.9	t	b0000002-0000-0000-0000-000000000002	2025-11-04 19:19:47.208139	2025-11-04 19:19:47.208139
d3000001-0000-0000-0000-000000000005	3	Let's discuss travel. Do you think travel is important for personal development?	\N	\N	\N	\N	\N	travel	hard	t	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures, customs, and ways of life...	\N	7.5	45	7.3	t	b0000001-0000-0000-0000-000000000001	2025-11-04 19:19:47.208139	2025-11-04 19:19:47.208139
d1000002-0000-0000-0000-000000000006	1	What kind of music do you like?	\N	\N	\N	\N	\N	hobbies	easy	f	\N	\N	\N	69	7.1	t	b0000004-0000-0000-0000-000000000004	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000003-0000-0000-0000-000000000007	1	Tell me about your family.	\N	\N	\N	\N	\N	technology	easy	f	\N	\N	\N	34	6.6	t	b0000013-0000-0000-0000-000000000005	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000004-0000-0000-0000-000000000008	1	What kind of music do you like?	\N	\N	\N	\N	\N	culture	easy	f	\N	\N	\N	62	5.7	t	b0000003-0000-0000-0000-000000000006	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000005-0000-0000-0000-000000000009	1	What kind of music do you like?	\N	\N	\N	\N	\N	work	easy	f	\N	\N	\N	76	6.2	t	b0000010-0000-0000-0000-000000000014	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000006-0000-0000-0000-000000000010	1	Do you enjoy cooking?	\N	\N	\N	\N	\N	technology	easy	f	\N	\N	\N	53	7.0	t	b0000008-0000-0000-0000-000000000003	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000007-0000-0000-0000-000000000011	1	Do you work or study?	\N	\N	\N	\N	\N	education	easy	f	\N	\N	\N	57	5.7	t	b0000012-0000-0000-0000-000000000011	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000008-0000-0000-0000-000000000012	1	What kind of music do you like?	\N	\N	\N	\N	\N	society	easy	f	\N	\N	\N	76	7.2	t	b0000009-0000-0000-0000-000000000009	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000009-0000-0000-0000-000000000013	1	Do you enjoy cooking?	\N	\N	\N	\N	\N	society	easy	f	\N	\N	\N	58	5.5	t	b0000008-0000-0000-0000-000000000002	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000010-0000-0000-0000-000000000014	1	What do you like to do in your free time?	\N	\N	\N	\N	\N	work	easy	f	\N	\N	\N	17	6.0	t	b0000002-0000-0000-0000-000000000010	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000011-0000-0000-0000-000000000015	1	Do you enjoy cooking?	\N	\N	\N	\N	\N	education	easy	f	\N	\N	\N	31	7.2	t	b0000005-0000-0000-0000-000000000007	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000012-0000-0000-0000-000000000016	1	Do you enjoy cooking?	\N	\N	\N	\N	\N	hobbies	easy	f	\N	\N	\N	21	7.3	t	b0000003-0000-0000-0000-000000000011	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000013-0000-0000-0000-000000000017	1	What kind of music do you like?	\N	\N	\N	\N	\N	technology	easy	f	\N	\N	\N	43	6.5	t	b0000008-0000-0000-0000-000000000007	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000014-0000-0000-0000-000000000018	1	Tell me about your family.	\N	\N	\N	\N	\N	work	easy	f	\N	\N	\N	15	6.0	t	b0000010-0000-0000-0000-000000000012	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000015-0000-0000-0000-000000000019	1	What kind of music do you like?	\N	\N	\N	\N	\N	work	easy	f	\N	\N	\N	22	7.2	t	b0000003-0000-0000-0000-000000000011	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d1000016-0000-0000-0000-000000000020	1	What kind of music do you like?	\N	\N	\N	\N	\N	technology	easy	f	\N	\N	\N	66	6.3	t	b0000007-0000-0000-0000-000000000002	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000017-0000-0000-0000-000000000021	2	Describe a skill you want to learn. You should say: what it is, when you encountered it, and why it is important to you.	A Book You Read	{"What it is","When you encountered it","Why it is important"}	60	120	\N	work	medium	f	\N	\N	\N	75	7.5	t	b0000008-0000-0000-0000-000000000007	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000018-0000-0000-0000-000000000022	2	Describe your favorite hobby. You should say: what it is, when you encountered it, and why it is important to you.	Your Favorite Hobby	{"What it is","When you encountered it","Why it is important"}	60	120	\N	travel	medium	f	\N	\N	\N	32	5.5	t	b0000013-0000-0000-0000-000000000001	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000019-0000-0000-0000-000000000023	2	Describe a book you recently read. You should say: what it is, when you encountered it, and why it is important to you.	Your Favorite Hobby	{"What it is","When you encountered it","Why it is important"}	60	120	\N	society	medium	f	\N	\N	\N	70	6.2	t	b0000011-0000-0000-0000-000000000015	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000020-0000-0000-0000-000000000024	2	Describe a memorable event. You should say: what it is, when you encountered it, and why it is important to you.	A Book You Read	{"What it is","When you encountered it","Why it is important"}	60	120	\N	travel	medium	f	\N	\N	\N	19	5.9	t	b0000007-0000-0000-0000-000000000007	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000021-0000-0000-0000-000000000025	2	Describe a skill you want to learn. You should say: what it is, when you encountered it, and why it is important to you.	A Book You Read	{"What it is","When you encountered it","Why it is important"}	60	120	\N	travel	medium	f	\N	\N	\N	39	6.9	t	b0000007-0000-0000-0000-000000000010	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000022-0000-0000-0000-000000000026	2	Describe your favorite hobby. You should say: what it is, when you encountered it, and why it is important to you.	A Place You Want to Visit	{"What it is","When you encountered it","Why it is important"}	60	120	\N	society	medium	f	\N	\N	\N	42	6.1	t	b0000003-0000-0000-0000-000000000003	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000023-0000-0000-0000-000000000027	2	Describe a place you would like to visit. You should say: what it is, when you encountered it, and why it is important to you.	Your Favorite Hobby	{"What it is","When you encountered it","Why it is important"}	60	120	\N	travel	medium	f	\N	\N	\N	43	5.5	t	b0000002-0000-0000-0000-000000000009	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000024-0000-0000-0000-000000000028	2	Describe a skill you want to learn. You should say: what it is, when you encountered it, and why it is important to you.	Your Favorite Hobby	{"What it is","When you encountered it","Why it is important"}	60	120	\N	society	medium	f	\N	\N	\N	22	7.0	t	b0000012-0000-0000-0000-000000000012	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000025-0000-0000-0000-000000000029	2	Describe a memorable event. You should say: what it is, when you encountered it, and why it is important to you.	A Memorable Event	{"What it is","When you encountered it","Why it is important"}	60	120	\N	family	medium	f	\N	\N	\N	25	7.2	t	b0000014-0000-0000-0000-000000000014	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000026-0000-0000-0000-000000000030	2	Describe your favorite hobby. You should say: what it is, when you encountered it, and why it is important to you.	A Place You Want to Visit	{"What it is","When you encountered it","Why it is important"}	60	120	\N	society	medium	f	\N	\N	\N	78	7.1	t	b0000007-0000-0000-0000-000000000009	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000027-0000-0000-0000-000000000031	2	Describe a memorable event. You should say: what it is, when you encountered it, and why it is important to you.	A Place You Want to Visit	{"What it is","When you encountered it","Why it is important"}	60	120	\N	education	medium	f	\N	\N	\N	54	7.2	t	b0000004-0000-0000-0000-000000000004	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000028-0000-0000-0000-000000000032	2	Describe a skill you want to learn. You should say: what it is, when you encountered it, and why it is important to you.	Your Favorite Hobby	{"What it is","When you encountered it","Why it is important"}	60	120	\N	society	medium	f	\N	\N	\N	57	5.9	t	b0000011-0000-0000-0000-000000000011	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000029-0000-0000-0000-000000000033	2	Describe a place you would like to visit. You should say: what it is, when you encountered it, and why it is important to you.	Your Favorite Hobby	{"What it is","When you encountered it","Why it is important"}	60	120	\N	society	medium	f	\N	\N	\N	41	6.1	t	b0000005-0000-0000-0000-000000000003	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000030-0000-0000-0000-000000000034	2	Describe a book you recently read. You should say: what it is, when you encountered it, and why it is important to you.	Your Favorite Hobby	{"What it is","When you encountered it","Why it is important"}	60	120	\N	hobbies	medium	f	\N	\N	\N	67	6.5	t	b0000011-0000-0000-0000-000000000002	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d2000031-0000-0000-0000-000000000035	2	Describe your favorite hobby. You should say: what it is, when you encountered it, and why it is important to you.	A Memorable Event	{"What it is","When you encountered it","Why it is important"}	60	120	\N	technology	medium	f	\N	\N	\N	11	6.9	t	b0000012-0000-0000-0000-000000000014	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000032-0000-0000-0000-000000000036	3	Let's discuss technology. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	society	hard	f	\N	\N	\N	27	6.6	t	b0000010-0000-0000-0000-000000000004	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000033-0000-0000-0000-000000000037	3	Let's discuss environment. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	culture	hard	f	\N	\N	\N	56	7.1	t	b0000003-0000-0000-0000-000000000015	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000034-0000-0000-0000-000000000038	3	Let's discuss work. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	education	hard	f	\N	\N	\N	58	6.7	t	b0000013-0000-0000-0000-000000000010	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000035-0000-0000-0000-000000000039	3	Let's discuss technology. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	family	hard	f	\N	\N	\N	57	7.4	t	b0000007-0000-0000-0000-000000000008	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000036-0000-0000-0000-000000000040	3	Let's discuss technology. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	society	hard	f	\N	\N	\N	38	6.1	t	b0000007-0000-0000-0000-000000000007	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000037-0000-0000-0000-000000000041	3	Let's discuss work. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	society	hard	f	\N	\N	\N	76	7.4	t	b0000009-0000-0000-0000-000000000009	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000038-0000-0000-0000-000000000042	3	Let's discuss technology. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	culture	hard	f	\N	\N	\N	51	5.5	t	b0000006-0000-0000-0000-000000000008	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000039-0000-0000-0000-000000000043	3	Let's discuss environment. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	travel	hard	f	\N	\N	\N	34	6.3	t	b0000014-0000-0000-0000-000000000007	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000040-0000-0000-0000-000000000044	3	Let's discuss technology. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	hobbies	hard	f	\N	\N	\N	16	6.6	t	b0000008-0000-0000-0000-000000000013	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000041-0000-0000-0000-000000000045	3	Let's discuss technology. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	technology	hard	f	\N	\N	\N	30	6.6	t	b0000002-0000-0000-0000-000000000006	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000042-0000-0000-0000-000000000046	3	Let's discuss work. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	work	hard	f	\N	\N	\N	26	7.0	t	b0000009-0000-0000-0000-000000000010	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000043-0000-0000-0000-000000000047	3	Let's discuss education. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	travel	hard	f	\N	\N	\N	32	6.7	t	b0000010-0000-0000-0000-000000000005	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000044-0000-0000-0000-000000000048	3	Let's discuss social media. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	travel	hard	f	\N	\N	\N	29	5.6	t	b0000004-0000-0000-0000-000000000008	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000045-0000-0000-0000-000000000049	3	Let's discuss social media. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	society	hard	f	\N	\N	\N	22	7.1	t	b0000002-0000-0000-0000-000000000015	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
d3000046-0000-0000-0000-000000000050	3	Let's discuss social media. Do you think [topic] is important in modern society?	\N	\N	\N	\N	\N	society	hard	f	\N	\N	\N	15	7.2	t	b0000001-0000-0000-0000-000000000004	2025-11-04 19:19:47.209042	2025-11-04 19:19:47.209042
\.


--
-- Data for Name: speaking_submissions; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.speaking_submissions (id, user_id, part_number, task_prompt_id, task_prompt_text, audio_url, audio_duration_seconds, audio_format, audio_file_size_bytes, transcript_text, transcript_word_count, recorded_from, status, exercise_id, course_id, lesson_id, submitted_at, transcribed_at, evaluated_at, created_at, updated_at) FROM stdin;
91097023-476e-44f1-9bfa-dd54f67df687	f0000001-0000-0000-0000-000000000001	1	d1000001-0000-0000-0000-000000000001	Let's talk about your hometown. Where are you from?	https://storage.example.com/audio/dc293254-1b4c-4a62-94be-128ec62af5df.mp3	56	mp3	528213	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	51	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-07 19:19:47.226771	2025-10-18 19:19:47.226771	2025-10-05 19:19:47.226771	2025-09-27 19:19:47.226771
60d49598-2d9a-4d00-a985-5dbbd1384398	f0000002-0000-0000-0000-000000000002	2	d2000002-0000-0000-0000-000000000004	Describe a person who has influenced you. You should say:\n- Who this person is\n- How you know them\n- What they have done\n- And explain why they have influenced you.	https://storage.example.com/audio/995776fe-ce36-4eb1-8724-de3c17684152.mp3	159	mp3	2188314	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	197	web	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-26 19:19:47.226771	2025-10-25 19:19:47.226771	2025-09-09 19:19:47.226771	2025-10-21 19:19:47.226771
36f93bbd-4746-4a2c-99a2-ac41ab0c4c09	f0000003-0000-0000-0000-000000000003	1	d1000002-0000-0000-0000-000000000006	What kind of music do you like?	https://storage.example.com/audio/48da696f-ab20-490c-828b-3f3d13cca819.mp3	43	mp3	2426899	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	89	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-15 19:19:47.226771	2025-10-18 19:19:47.226771	2025-09-21 19:19:47.226771	2025-10-16 19:19:47.226771
1ca54436-2cba-46c4-aec4-95f910e14c6e	f0000004-0000-0000-0000-000000000004	1	d1000009-0000-0000-0000-000000000013	Do you enjoy cooking?	https://storage.example.com/audio/6990fcc2-a6d8-4201-8da1-108b19c3c5f2.mp3	55	mp3	1372872	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	86	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-16 19:19:47.226771	2025-10-10 19:19:47.226771	2025-10-12 19:19:47.226771	2025-09-21 19:19:47.226771
36603805-ec4c-45b4-9a0d-5910ca8cccc8	f0000005-0000-0000-0000-000000000005	2	d2000023-0000-0000-0000-000000000027	Describe a place you would like to visit. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/f5c18110-1ff8-470b-8e8a-cc9b16066dfe.mp3	126	mp3	1019275	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	240	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-20 19:19:47.226771	2025-11-01 19:19:47.226771	2025-09-18 19:19:47.226771	2025-09-06 19:19:47.226771
5d3a8835-b149-4092-88da-138c11504e02	f0000006-0000-0000-0000-000000000006	2	d2000026-0000-0000-0000-000000000030	Describe your favorite hobby. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/eaece104-928c-493b-963a-0a57f1a923ee.mp3	149	mp3	2409678	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	255	web	completed	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	2025-10-26 19:19:47.226771	2025-10-22 19:19:47.226771	2025-10-17 19:19:47.226771	2025-09-23 19:19:47.226771
caf8ee57-a21b-4a02-9add-3844ffc8092f	f0000007-0000-0000-0000-000000000007	2	d2000029-0000-0000-0000-000000000033	Describe a place you would like to visit. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/bd9ae313-641f-4db9-9aab-e599a66bbeba.mp3	165	mp3	1327310	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	280	android	completed	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	2025-10-26 19:19:47.226771	2025-10-23 19:19:47.226771	2025-10-16 19:19:47.226771	2025-10-24 19:19:47.226771
58fea851-0379-4aea-a65b-4e2a53528479	f0000008-0000-0000-0000-000000000008	3	d3000035-0000-0000-0000-000000000039	Let's discuss technology. Do you think [topic] is important in modern society?	https://storage.example.com/audio/d2bd29f1-c56a-4a05-9b7b-edd8189e3875.mp3	138	mp3	652037	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	172	android	pending	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-27 19:19:47.226771	2025-10-13 19:19:47.226771	2025-09-19 19:19:47.226771	2025-10-10 19:19:47.226771
ed7888f1-a86c-4ba8-8967-020c8e1da9bd	f0000009-0000-0000-0000-000000000009	3	d3000036-0000-0000-0000-000000000040	Let's discuss technology. Do you think [topic] is important in modern society?	https://storage.example.com/audio/5297f660-e829-48a4-877f-eeadaf249907.mp3	130	mp3	2272249	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	143	android	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-27 19:19:47.226771	\N	2025-10-04 19:19:47.226771	2025-09-30 19:19:47.226771
028a0fd5-f365-4eb6-bb8e-c6c08a1e5a03	f0000010-0000-0000-0000-000000000010	3	d3000039-0000-0000-0000-000000000043	Let's discuss environment. Do you think [topic] is important in modern society?	https://storage.example.com/audio/d5f884dc-04be-4f8e-abff-4f25a23c3eee.mp3	169	mp3	1262551	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	159	ios	completed	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	2025-11-01 19:19:47.226771	2025-10-28 19:19:47.226771	2025-10-03 19:19:47.226771	2025-10-08 19:19:47.226771
d73728ef-f6e7-4790-9ba0-cbaeebeea907	f0000011-0000-0000-0000-000000000011	3	d3000040-0000-0000-0000-000000000044	Let's discuss technology. Do you think [topic] is important in modern society?	https://storage.example.com/audio/b0212e30-b5df-40fb-93ff-b90907b8b330.mp3	154	mp3	2422155	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	152	ios	completed	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	\N	2025-10-13 19:19:47.226771	2025-10-10 19:19:47.226771	2025-10-18 19:19:47.226771
2f8e7329-6e3a-43c2-b2a6-ef1f6befd0a8	f0000012-0000-0000-0000-000000000012	3	d3000041-0000-0000-0000-000000000045	Let's discuss technology. Do you think [topic] is important in modern society?	https://storage.example.com/audio/f582e4c9-41f7-4977-bcac-4c099c478d6f.mp3	156	mp3	998148	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	177	ios	pending	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	2025-10-31 19:19:47.226771	2025-10-11 19:19:47.226771	2025-10-31 19:19:47.226771	2025-10-06 19:19:47.226771
234f4167-b33e-4eb8-a271-19a281208f98	f0000013-0000-0000-0000-000000000013	3	d3000046-0000-0000-0000-000000000050	Let's discuss social media. Do you think [topic] is important in modern society?	https://storage.example.com/audio/df95a116-c31a-48e8-94db-b67f4ceeed10.mp3	125	mp3	1166053	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	116	ios	pending	\N	\N	\N	2025-11-04 19:19:47.226771	\N	\N	2025-10-16 19:19:47.226771	2025-09-11 19:19:47.226771
06e1ac62-43d9-4d3d-be70-6ee401edb775	f0000014-0000-0000-0000-000000000014	1	d1000002-0000-0000-0000-000000000006	What kind of music do you like?	https://storage.example.com/audio/d0f49dbf-6b46-4594-a092-3da735178863.mp3	48	mp3	2160966	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	59	ios	pending	\N	c4000001-0000-0000-0000-000000000010	\N	2025-11-04 19:19:47.226771	2025-10-30 19:19:47.226771	2025-10-26 19:19:47.226771	2025-09-18 19:19:47.226771	2025-09-13 19:19:47.226771
d543f120-5f9d-43bf-bae0-881db910cdc7	f0000015-0000-0000-0000-000000000015	1	d1000003-0000-0000-0000-000000000007	Tell me about your family.	https://storage.example.com/audio/9b8188df-53f0-4c2a-85aa-90b49ffde903.mp3	79	mp3	995802	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	77	ios	completed	\N	c4000001-0000-0000-0000-000000000010	\N	2025-11-04 19:19:47.226771	2025-10-24 19:19:47.226771	2025-10-11 19:19:47.226771	2025-09-30 19:19:47.226771	2025-10-06 19:19:47.226771
7428648f-cc52-413e-84c1-d282445d322f	f0000016-0000-0000-0000-000000000016	1	d1000009-0000-0000-0000-000000000013	Do you enjoy cooking?	https://storage.example.com/audio/4dc9c73a-49c0-415a-b71b-9ad99b970eb9.mp3	66	mp3	1278573	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	83	ios	completed	\N	c4000001-0000-0000-0000-000000000010	\N	2025-11-04 19:19:47.226771	2025-10-24 19:19:47.226771	2025-10-16 19:19:47.226771	2025-10-28 19:19:47.226771	2025-09-20 19:19:47.226771
f4b681a9-cf15-44e6-9411-2a76d8ebdb83	f0000017-0000-0000-0000-000000000017	1	d1000013-0000-0000-0000-000000000017	What kind of music do you like?	https://storage.example.com/audio/a03beed6-fe0a-48fb-94a8-344b16a65934.mp3	69	mp3	982832	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	75	ios	completed	\N	c4000001-0000-0000-0000-000000000010	\N	2025-11-04 19:19:47.226771	2025-10-05 19:19:47.226771	2025-10-17 19:19:47.226771	2025-10-19 19:19:47.226771	2025-09-09 19:19:47.226771
3b6e454b-dcd7-4ed0-ab32-f76398e0a791	f0000018-0000-0000-0000-000000000018	2	d2000021-0000-0000-0000-000000000025	Describe a skill you want to learn. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/670e9ae0-b3f7-44a0-a063-5eec1dd2d0dd.mp3	162	mp3	1437457	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	187	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-18 19:19:47.226771	2025-10-22 19:19:47.226771	2025-10-31 19:19:47.226771	2025-10-04 19:19:47.226771
92f7ee5b-3a4e-4214-82c6-e267f59a290e	f0000019-0000-0000-0000-000000000019	2	d2000023-0000-0000-0000-000000000027	Describe a place you would like to visit. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/f2425246-8244-40e8-ae50-29dec8513fb8.mp3	144	mp3	1808903	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	218	web	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-30 19:19:47.226771	2025-10-28 19:19:47.226771	2025-10-12 19:19:47.226771	2025-10-16 19:19:47.226771
f38a8b08-f49f-4939-926c-28b2f623e8fb	f0000020-0000-0000-0000-000000000020	2	d2000025-0000-0000-0000-000000000029	Describe a memorable event. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/3fdfa1f6-bc29-4997-a909-78c8a211c16b.mp3	130	mp3	1655743	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	196	android	completed	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	2025-10-28 19:19:47.226771	2025-10-31 19:19:47.226771	2025-10-21 19:19:47.226771	2025-10-03 19:19:47.226771
93e0c6ad-7e9f-4b05-92e3-99ff6bd6d442	f0000021-0000-0000-0000-000000000021	2	d2000026-0000-0000-0000-000000000030	Describe your favorite hobby. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/a2209511-18ba-4a65-9266-6704fc594863.mp3	161	mp3	1514410	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	199	android	completed	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	\N	\N	2025-09-30 19:19:47.226771	2025-10-17 19:19:47.226771
809bdf19-9ccb-4d7a-be83-962f63dffa19	f0000022-0000-0000-0000-000000000022	2	d2000027-0000-0000-0000-000000000031	Describe a memorable event. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/25ab4dcc-a183-4e5e-af93-35d63d55f60e.mp3	174	mp3	919127	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	196	ios	pending	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	2025-10-26 19:19:47.226771	2025-11-04 19:19:47.226771	2025-09-27 19:19:47.226771	2025-09-30 19:19:47.226771
cff62ed9-deb2-49b9-b8d3-af356f0ade51	f0000023-0000-0000-0000-000000000023	3	d3000035-0000-0000-0000-000000000039	Let's discuss technology. Do you think [topic] is important in modern society?	https://storage.example.com/audio/6a6ec744-d9f5-4062-8079-6a9ca4bbf1cc.mp3	124	mp3	1482689	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	113	web	completed	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	\N	2025-10-20 19:19:47.226771	2025-10-16 19:19:47.226771	2025-09-27 19:19:47.226771
766f9f3d-54cc-4744-b4f8-d3d3b6d97273	f0000024-0000-0000-0000-000000000024	3	d3000036-0000-0000-0000-000000000040	Let's discuss technology. Do you think [topic] is important in modern society?	https://storage.example.com/audio/f50e9545-aad5-404f-8826-c396d92bea62.mp3	166	mp3	588610	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	147	ios	pending	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-07 19:19:47.226771	2025-10-05 19:19:47.226771	2025-10-30 19:19:47.226771	2025-10-15 19:19:47.226771
e82f5111-8571-4de9-9478-936970dd7c23	f0000025-0000-0000-0000-000000000025	3	d3000039-0000-0000-0000-000000000043	Let's discuss environment. Do you think [topic] is important in modern society?	https://storage.example.com/audio/ff3f4d96-6aac-4856-a363-72ef3490803b.mp3	170	mp3	1834895	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	129	android	completed	\N	c4000002-0000-0000-0000-000000000011	\N	2025-11-04 19:19:47.226771	2025-10-20 19:19:47.226771	2025-10-27 19:19:47.226771	2025-10-31 19:19:47.226771	2025-09-07 19:19:47.226771
943c639d-d07b-4a76-aff0-8843877845f5	f0000026-0000-0000-0000-000000000026	3	d3000043-0000-0000-0000-000000000047	Let's discuss education. Do you think [topic] is important in modern society?	https://storage.example.com/audio/58310b5c-ad8c-46de-abaf-1da847700275.mp3	132	mp3	2349217	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	162	android	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-29 19:19:47.226771	2025-11-04 19:19:47.226771	2025-11-02 19:19:47.226771	2025-09-16 19:19:47.226771
b9e60dc1-6943-4961-9d1a-62d83cc43d83	f0000027-0000-0000-0000-000000000027	2	d2000002-0000-0000-0000-000000000004	Describe a person who has influenced you. You should say:\n- Who this person is\n- How you know them\n- What they have done\n- And explain why they have influenced you.	https://storage.example.com/audio/7ece735b-072b-44df-84c0-d5756ceb348e.mp3	137	mp3	1035091	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	260	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-17 19:19:47.226771	2025-10-23 19:19:47.226771	2025-10-16 19:19:47.226771	2025-09-09 19:19:47.226771
fd30d219-3974-4bcf-97f2-93ae829a03d8	f0000028-0000-0000-0000-000000000028	1	d1000005-0000-0000-0000-000000000009	What kind of music do you like?	https://storage.example.com/audio/2788a01e-53b4-4551-9014-b9e7f7d99b19.mp3	89	mp3	2132479	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	91	android	completed	\N	c4000001-0000-0000-0000-000000000010	\N	2025-11-04 19:19:47.226771	2025-11-01 19:19:47.226771	\N	2025-10-02 19:19:47.226771	2025-09-17 19:19:47.226771
a51db878-c741-4a65-b4ee-54d29e21f263	f0000029-0000-0000-0000-000000000029	1	d1000007-0000-0000-0000-000000000011	Do you work or study?	https://storage.example.com/audio/0cdb97cb-0238-43ca-867e-1e66f9229bc0.mp3	66	mp3	2472583	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	69	android	completed	\N	c4000001-0000-0000-0000-000000000010	\N	2025-11-04 19:19:47.226771	2025-10-26 19:19:47.226771	2025-10-20 19:19:47.226771	2025-09-12 19:19:47.226771	2025-10-25 19:19:47.226771
4ea83fb5-fc16-4f2a-beed-580069a832de	f0000030-0000-0000-0000-000000000030	1	d1000013-0000-0000-0000-000000000017	What kind of music do you like?	https://storage.example.com/audio/51228e59-7c93-4a1f-8e86-05b9d0f8ffe7.mp3	71	mp3	1073284	Well, I'm from Ho Chi Minh City, which is the largest city in Vietnam. It's a very vibrant and bustling city with lots of activities and opportunities...	86	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	\N	2025-11-03 19:19:47.226771	2025-10-17 19:19:47.226771	2025-11-02 19:19:47.226771
22096d50-b23a-4b6f-83dd-6902b48e9a75	f0000031-0000-0000-0000-000000000031	2	d2000018-0000-0000-0000-000000000022	Describe your favorite hobby. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/80ff0eee-faae-4b66-b6e7-ca67e648b248.mp3	137	mp3	699198	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	210	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	\N	\N	2025-11-02 19:19:47.226771	2025-10-21 19:19:47.226771
9e1b8319-ce9e-4f84-8276-c98f558c31f6	f0000032-0000-0000-0000-000000000032	2	d2000019-0000-0000-0000-000000000023	Describe a book you recently read. You should say: what it is, when you encountered it, and why it is important to you.	https://storage.example.com/audio/17e26abc-c1ad-418e-a6fa-36f174e93ab2.mp3	157	mp3	1352056	I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...	233	ios	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-16 19:19:47.226771	\N	2025-10-08 19:19:47.226771	2025-09-22 19:19:47.226771
19b81924-6f4c-4786-8f4b-dff7b3c15b84	f0000033-0000-0000-0000-000000000033	3	d3000040-0000-0000-0000-000000000044	Let's discuss technology. Do you think [topic] is important in modern society?	https://storage.example.com/audio/219163a8-c3e1-4a4c-b766-11ccdcced6bf.mp3	128	mp3	507804	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	199	web	completed	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-26 19:19:47.226771	2025-10-16 19:19:47.226771	2025-09-08 19:19:47.226771	2025-10-07 19:19:47.226771
c74bea8c-cc9e-4f34-ad21-7370fc61adc2	f0000034-0000-0000-0000-000000000034	3	d3000045-0000-0000-0000-000000000049	Let's discuss social media. Do you think [topic] is important in modern society?	https://storage.example.com/audio/0347c13c-d3a1-4e64-9a7a-3d63cf368172.mp3	158	mp3	2053816	Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...	108	android	pending	\N	\N	\N	2025-11-04 19:19:47.226771	2025-10-29 19:19:47.226771	2025-10-16 19:19:47.226771	2025-09-07 19:19:47.226771	2025-09-07 19:19:47.226771
\.


--
-- Data for Name: writing_evaluations; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.writing_evaluations (id, submission_id, overall_band_score, task_achievement_score, coherence_cohesion_score, lexical_resource_score, grammar_accuracy_score, strengths, weaknesses, grammar_errors, grammar_error_count, vocabulary_level, vocabulary_range_score, vocabulary_suggestions, paragraph_count, has_introduction, has_conclusion, structure_feedback, linking_words_used, coherence_feedback, addresses_all_parts, task_response_feedback, detailed_feedback, improvement_suggestions, ai_model_name, ai_model_version, confidence_score, processing_time_ms, created_at, detailed_feedback_json) FROM stdin;
dd8141c5-1f86-485e-a865-adba73fb461f	b56ebe64-80ec-4cc3-9307-600695e0d73a	7.9	7.6	7.0	8.1	8.0	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	3	advanced	0.84	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	f	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.97	3202	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
374ac3f1-d5b9-4319-b13a-3c9c54b32368	a45d3079-b7c6-4e19-83b7-c663dd13df86	7.0	8.0	7.3	7.3	6.3	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	intermediate	0.99	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.89	3565	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
c71dfe62-df33-41d9-8d0d-d6336d2b2e46	876d8172-ddf8-4ee3-942d-bbcc484b81ee	5.7	7.4	5.8	7.5	6.5	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	intermediate	0.72	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.80	4451	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
6e95b810-8bb9-41df-ac9b-562e81e61634	868366d1-5e47-482e-91f0-cc43e9db6702	7.2	8.1	7.6	6.7	6.1	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	1	advanced	0.68	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	Could address all parts of the task more completely.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.87	4343	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
aba0f41a-dc49-4b68-ba3f-2a345b85f79e	12c07299-ae35-43f0-b3e2-d8380ceccfb3	7.1	5.6	5.8	8.0	6.8	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	3	basic	0.91	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.95	3788	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
20fd3738-b52b-4c9c-a7ad-532b08f580f5	4c49384f-b74c-4ee2-9d65-25403a43a283	6.5	7.3	7.5	6.0	5.5	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	6	basic	0.61	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.91	3425	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
b5881a06-d7c2-44dc-bb58-04fff59f890f	9f0408f1-62d9-47e3-a437-cbdd47b45398	6.6	7.9	7.0	5.7	6.8	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	2	basic	0.66	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	Could address all parts of the task more completely.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.96	3411	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
3c13cbdd-1d02-4c7d-add4-6853a669efbd	9011ca23-109e-4da4-8953-98e5427f6ec6	6.9	6.3	6.2	6.5	6.4	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	1	advanced	0.91	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	1.00	3072	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
6777b033-6c22-41e1-a405-47dbb3deed93	b006ba61-4ecd-4671-b294-8ec0236a6ec5	7.5	6.4	6.4	6.9	5.7	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	2	basic	0.84	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.84	3931	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
795dcc35-8770-4a1a-9be2-164f35e720ed	ff2447b1-eab2-499f-9ce3-70662506997a	5.7	6.8	6.8	8.0	6.1	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	1	basic	0.62	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.89	3244	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
7426f7b9-245c-4e48-ab98-71c4c3472a11	e6990f6f-f326-4d6e-8115-08ece88383b3	7.1	8.4	6.1	5.8	5.9	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	2	advanced	0.97	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.85	4774	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
8c92ae77-2698-452f-a2f3-2af14fcfe1aa	33109d5a-a263-48a2-b7bf-d028e8c12298	7.4	8.0	6.8	8.0	8.0	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	5	basic	0.80	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.84	3574	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
14d076d5-3264-46e6-9590-111aefb959a9	8771fac9-d05c-4552-a2d9-639d654b8777	5.9	7.3	8.3	6.0	6.2	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	5	advanced	0.60	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	f	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.89	4326	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
f32de814-c55e-436c-ac18-6c3a8af3ea99	65067a9e-c7a3-434b-9f40-bcaa70836de1	8.0	7.1	8.2	7.6	7.1	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	basic	0.70	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.95	4988	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
2aaedf4d-35c8-43f6-95b1-078c24a6213d	e9679626-7eb6-4d78-93e3-71d6ebaef360	7.4	8.1	7.3	8.1	7.6	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	3	intermediate	0.94	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.86	4470	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
6fb86361-7822-4502-b679-2f071e5eb8c5	e33575bd-49d5-405a-9bbc-6aba5419f81b	8.5	7.7	5.7	6.0	7.6	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	basic	0.63	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	Could address all parts of the task more completely.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.90	3971	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
ccea25dc-042b-4e27-8293-1e414e566d35	b71789c4-9f29-4469-8daf-4f295f54de96	7.5	5.5	7.9	7.8	5.9	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	advanced	0.85	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	Could address all parts of the task more completely.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.95	3438	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
2a3aaf7f-14d6-4ccc-a709-ed45f7b7c049	0aa801fc-2273-4c75-b619-80df32f2deba	7.1	7.6	8.2	7.1	5.8	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	6	intermediate	0.75	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.94	4112	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
7fa6e320-27e8-4e06-94d7-c5ad7e01d43b	c06f04a7-a21f-4997-87b1-a7255fb7b9ce	7.8	7.8	5.7	7.2	8.4	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	3	advanced	0.97	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.82	3301	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
21ba63bf-fecf-4983-b660-b70fcaff1f1b	a5e1dfa3-9d20-4d36-9469-fba806afba22	6.4	6.8	5.8	7.8	6.5	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	advanced	0.63	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.93	3664	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
caed703b-1c64-4e88-bc04-869a836ebb4f	acae74e8-bc3f-45e3-881b-a50b9416a979	5.9	6.8	8.3	8.5	5.8	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	6	basic	0.79	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.83	3473	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
349fbbbd-4e51-46bd-aaa2-db2f53b30043	13e341b3-6b0e-42e4-ac0f-fcae4051bff4	8.0	7.7	6.8	5.6	7.8	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	5	advanced	0.95	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	f	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.87	3623	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
3d9eb793-5380-45f6-ae02-e4973e335264	9ac46ecc-e9fe-4efa-8cad-dc3f2d2c7b9c	6.6	8.4	7.3	8.0	7.4	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	5	advanced	0.88	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.93	4936	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
13eab076-dec6-4674-8f4a-ead3d175740d	9196efe4-7cd9-4369-9c4f-ffa2fac625c2	6.9	6.5	6.4	7.4	7.6	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	3	basic	0.62	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.93	3302	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
433fb19d-3957-49ee-a62a-6669a00e490e	1ff1564d-7f38-4667-9787-bd996b067a6e	6.2	7.4	6.1	7.7	7.1	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	3	advanced	0.81	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.92	4155	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
11b36022-5032-44e3-be7a-dddcc2aa3f95	86c77596-fc9c-416c-a62c-e2512ffd6af4	8.1	8.3	8.1	7.4	7.0	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	3	basic	0.96	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.94	4739	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
401663bc-16cc-49ce-8f8e-8613e806993a	83f728fb-8650-4242-bb0a-2a9efca229d4	8.2	6.1	8.0	7.7	5.7	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	basic	0.71	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	f	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.80	4981	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
d96a4c91-d12f-44b3-b9f4-730b0d7be42e	aa0b8d67-cdfd-4339-8def-5bb886119e84	8.4	5.9	6.2	7.0	7.6	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	5	intermediate	0.76	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.98	3936	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
e3fea26d-2259-4a42-ae4a-bfbcc98d14e7	822d3a43-b9da-4f09-a4fb-b7c8f605106d	6.8	8.0	7.7	6.5	6.2	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	5	basic	0.87	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	Could address all parts of the task more completely.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.88	4157	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
5c4f0a76-d868-46f1-9abc-6679824593f3	7cc9c67d-9a39-408f-b205-5cffc90e6504	6.1	8.4	6.6	6.7	7.2	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	basic	0.84	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.80	3413	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
320068f3-78d6-4daf-897c-44c7f91dfdf6	66ca3590-be90-4150-a818-17433a6c8bd1	6.6	7.7	7.8	5.5	5.6	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	6	basic	0.74	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.93	4856	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
af07dcaf-5ead-473c-80ee-f45043fbb278	a2dc05c3-cb91-4b72-ad75-cd25672b51a7	7.1	7.5	6.5	5.6	6.3	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	6	basic	0.97	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	f	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.97	3199	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
86deacaf-c221-4be0-86b2-2fd2da24218e	19b68d67-aaee-4fa8-8f4e-edbd9e4a5dc8	8.0	7.3	6.7	7.0	7.5	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	1	intermediate	0.84	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	3	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.85	3930	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
e9a22094-ef3f-4fba-a27e-3dc80a6352a0	53858c73-bd79-44a0-9525-80afec16df91	7.4	5.5	5.9	7.0	6.3	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	5	basic	0.80	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	1.00	3514	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
2ef4a8c1-2fa9-4951-9f58-b4ad7e523015	905247e4-636b-4f6b-9cf4-adedcbe982fe	7.3	8.2	7.2	6.4	7.4	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	5	basic	0.62	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.99	3374	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
568c5298-7706-43fe-a89b-e295a303c600	efd0f979-b8b2-4323-b9e3-ed8df41270c0	7.8	7.6	7.3	6.7	7.4	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	2	basic	0.61	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	The task has been addressed adequately.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.89	4509	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
441c7c9a-da4f-4e4c-be8f-885f833154ab	3de41e4a-fb63-4b06-8bf0-08d0850705a6	6.9	6.8	5.8	6.2	7.4	{"Good use of linking words","Clear paragraph structure","Appropriate vocabulary range","Mostly accurate grammar"}	{"Some spelling errors","Could use more complex sentence structures","Limited range of vocabulary in some areas"}	[{"type": "subject-verb agreement", "example": "The data shows...", "correction": "Correct"}, {"type": "article usage", "example": "...a university", "correction": "Correct"}]	4	basic	0.79	[{"word": "good", "suggestion": "excellent/outstanding"}, {"word": "big", "suggestion": "significant/substantial"}]	4	t	t	The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.	{however,moreover,therefore,furthermore}	The essay flows well with appropriate linking devices.	t	Could address all parts of the task more completely.	Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.	{"Try to use more complex sentence structures","Expand your vocabulary range","Pay attention to article usage","Practice writing more to improve fluency"}	gpt-4	1.0	0.93	4224	2025-11-04 19:19:47.217534	{"grammar_accuracy": {"en": "Grammar is mostly accurate with some minor errors.", "vi": "Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ."}, "lexical_resource": {"en": "Appropriate vocabulary usage but could be more varied.", "vi": "Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn."}, "task_achievement": {"en": "You have addressed the task requirements well.", "vi": "Bạn đã hoàn thành tốt yêu cầu của đề bài."}, "coherence_cohesion": {"en": "The essay has clear and logical structure.", "vi": "Bài viết có cấu trúc rõ ràng và logic."}}
\.


--
-- Data for Name: writing_prompts; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.writing_prompts (id, task_type, prompt_text, visual_type, visual_url, topic, difficulty, has_sample_answer, sample_answer_text, sample_answer_band_score, times_used, average_score, is_published, created_by, created_at, updated_at) FROM stdin;
c1000001-0000-0000-0000-000000000001	task1	The chart below shows the percentage of households in owned and rented accommodation in England and Wales between 1918 and 2011.\nSummarize the information by selecting and reporting the main features, and make comparisons where relevant.	bar_chart	https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop	housing	medium	t	The bar chart illustrates the changes in housing tenure in England and Wales from 1918 to 2011...	7.0	45	6.8	t	b0000001-0000-0000-0000-000000000001	2025-11-04 19:19:47.201261	2025-11-04 19:19:47.201261
c1000002-0000-0000-0000-000000000002	task1	The graph below shows the proportion of the population aged 65 and over between 1940 and 2040 in three different countries.\nSummarize the information by selecting and reporting the main features, and make comparisons where relevant.	line_graph	https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop	demographics	medium	t	The line graph compares the percentage of people aged 65 and over in Japan, Sweden, and the USA from 1940 to 2040...	7.5	38	7.1	t	b0000002-0000-0000-0000-000000000002	2025-11-04 19:19:47.201261	2025-11-04 19:19:47.201261
c1000003-0000-0000-0000-000000000003	task1	The diagram below shows the process of how rainwater is collected and converted to drinking water in an Australian town.\nSummarize the information by selecting and reporting the main features.	diagram	https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop	process	hard	t	The diagram illustrates the process of collecting rainwater and converting it into drinking water in an Australian town...	6.5	32	6.3	t	b0000001-0000-0000-0000-000000000001	2025-11-04 19:19:47.201261	2025-11-04 19:19:47.201261
c1000004-0000-0000-0000-000000000007	task1	The graph below shows educational achievements in different regions. Summarize the information by selecting and reporting the main features.	diagram	https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800&h=600&fit=crop	culture	hard	t	\N	\N	27	6.0	t	b0000005-0000-0000-0000-000000000003	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000005-0000-0000-0000-000000000008	task1	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	pie_chart	https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&h=600&fit=crop	culture	medium	t	\N	\N	22	5.8	t	b0000003-0000-0000-0000-000000000014	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000006-0000-0000-0000-000000000009	task1	The diagram below shows educational achievements in different regions. Summarize the information by selecting and reporting the main features.	table	https://images.unsplash.com/photo-1589903308904-1010c2294adc?w=800&h=600&fit=crop	politics	hard	t	\N	\N	47	5.7	t	b0000002-0000-0000-0000-000000000008	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000007-0000-0000-0000-000000000010	task1	The graph below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	table	https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&h=600&fit=crop	technology	medium	f	\N	\N	31	5.7	t	b0000008-0000-0000-0000-000000000005	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000008-0000-0000-0000-000000000011	task1	The diagram below shows employment rates in different regions. Summarize the information by selecting and reporting the main features.	line_graph	https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&h=600&fit=crop	technology	hard	t	\N	\N	68	6.0	t	b0000011-0000-0000-0000-000000000009	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000009-0000-0000-0000-000000000012	task1	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	diagram	https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&h=600&fit=crop	environment	hard	t	\N	\N	17	5.8	t	b0000005-0000-0000-0000-000000000006	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000010-0000-0000-0000-000000000013	task1	The graph below shows employment rates in different regions. Summarize the information by selecting and reporting the main features.	diagram	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=600&fit=crop	politics	medium	t	\N	\N	50	5.8	t	b0000004-0000-0000-0000-000000000008	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000011-0000-0000-0000-000000000014	task1	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	line_graph	https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&h=600&fit=crop	environment	hard	f	\N	\N	13	7.4	t	b0000008-0000-0000-0000-000000000012	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000012-0000-0000-0000-000000000015	task1	The chart below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	bar_chart	https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=800&h=600&fit=crop	economy	hard	t	\N	\N	15	6.1	t	b0000015-0000-0000-0000-000000000014	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c1000013-0000-0000-0000-000000000016	task1	The graph below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	bar_chart	https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=600&fit=crop	society	hard	t	\N	\N	67	7.0	t	b0000002-0000-0000-0000-000000000012	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000001-0000-0000-0000-000000000004	task2	Some people believe that it is better to study in a group, while others prefer to study alone. Discuss both views and give your own opinion.	\N	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop	education	medium	t	There are contrasting views on whether group study or individual study is more effective. While some argue that studying in groups enhances learning, others believe that studying alone is more productive...	7.5	52	7.2	t	b0000001-0000-0000-0000-000000000001	2025-11-04 19:19:47.201261	2025-11-04 19:19:47.201261
c2000002-0000-0000-0000-000000000005	task2	Some people think that the government should provide free healthcare for all citizens, while others believe that individuals should pay for their own medical care. Discuss both views and give your own opinion.	\N	https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&h=600&fit=crop	healthcare	medium	t	The debate over healthcare funding is a contentious issue in many countries. Some argue that healthcare should be provided free by the government, while others believe individuals should bear the cost...	7.0	48	6.9	t	b0000002-0000-0000-0000-000000000002	2025-11-04 19:19:47.201261	2025-11-04 19:19:47.201261
c2000003-0000-0000-0000-000000000006	task2	Many people believe that social media has a negative impact on society. To what extent do you agree or disagree?	\N	https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop	technology	easy	t	Social media has become an integral part of modern life, but its impact on society is a subject of debate. While some argue that social media has negative consequences, I believe its effects are more nuanced...	6.5	65	6.4	t	b0000003-0000-0000-0000-000000000003	2025-11-04 19:19:47.201261	2025-11-04 19:19:47.201261
c2000014-0000-0000-0000-000000000017	task2	Some people prefer to live in the countryside, while others prefer city life. Discuss both views and give your own opinion.	\N	https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop	politics	medium	f	\N	\N	32	5.6	t	b0000007-0000-0000-0000-000000000009	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000015-0000-0000-0000-000000000018	task2	Some argue that fast food has a negative impact on health. Do you agree or disagree?	\N	https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop	politics	easy	t	\N	\N	60	7.1	t	b0000002-0000-0000-0000-000000000002	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000016-0000-0000-0000-000000000019	task2	Some argue that fast food has a negative impact on health. Do you agree or disagree?	\N	https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop	education	medium	f	\N	\N	15	5.6	t	b0000003-0000-0000-0000-000000000008	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000017-0000-0000-0000-000000000020	task2	Many believe that climate change is the most serious problem facing the world today. To what extent do you agree or disagree?	\N	https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop	politics	hard	f	\N	\N	22	5.6	t	b0000007-0000-0000-0000-000000000006	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000018-0000-0000-0000-000000000021	task2	Some argue that fast food has a negative impact on health. Do you agree or disagree?	\N	https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop	technology	hard	f	\N	\N	35	7.2	t	b0000015-0000-0000-0000-000000000012	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000019-0000-0000-0000-000000000022	task2	Some people believe that technology makes our lives more complicated. To what extent do you agree or disagree?	\N	https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&h=600&fit=crop	technology	easy	t	\N	\N	47	6.7	t	b0000002-0000-0000-0000-000000000002	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000020-0000-0000-0000-000000000023	task2	Some argue that fast food has a negative impact on health. Do you agree or disagree?	\N	https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop	society	hard	t	\N	\N	68	6.9	t	b0000003-0000-0000-0000-000000000005	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000021-0000-0000-0000-000000000024	task2	Some people believe that technology makes our lives more complicated. To what extent do you agree or disagree?	\N	https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&h=600&fit=crop	environment	hard	t	\N	\N	59	6.5	t	b0000011-0000-0000-0000-000000000005	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000022-0000-0000-0000-000000000025	task2	Some argue that fast food has a negative impact on health. Do you agree or disagree?	\N	https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=600&fit=crop	technology	medium	f	\N	\N	58	6.7	t	b0000008-0000-0000-0000-000000000002	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
c2000023-0000-0000-0000-000000000026	task2	Many people think that university education should be free. Discuss both views and give your own opinion.	\N	https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop	education	medium	t	\N	\N	22	6.8	t	b0000004-0000-0000-0000-000000000008	2025-11-04 19:19:47.203156	2025-11-04 19:19:47.203156
\.


--
-- Data for Name: writing_submissions; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.writing_submissions (id, user_id, task_type, task_prompt_id, task_prompt_text, essay_text, word_count, time_spent_seconds, submitted_from, status, exercise_id, course_id, lesson_id, submitted_at, evaluated_at, created_at, updated_at) FROM stdin;
b56ebe64-80ec-4cc3-9307-600695e0d73a	f0000001-0000-0000-0000-000000000001	task1	c1000003-0000-0000-0000-000000000003	The diagram below shows the process of how rainwater is collected and converted to drinking water in an Australian town.\nSummarize the information by selecting and reporting the main features.	The chart illustrates the trends in process over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	162	1388	ios	completed	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	2025-10-10 19:19:47.21058	2025-09-18 19:19:47.21058	2025-09-15 19:19:47.21058
a45d3079-b7c6-4e19-83b7-c663dd13df86	f0000002-0000-0000-0000-000000000002	task1	c1000006-0000-0000-0000-000000000009	The diagram below shows educational achievements in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in politics over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	170	1216	ios	completed	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	2025-10-24 19:19:47.21058	2025-10-13 19:19:47.21058	2025-09-21 19:19:47.21058
876d8172-ddf8-4ee3-942d-bbcc484b81ee	f0000003-0000-0000-0000-000000000003	task1	c1000007-0000-0000-0000-000000000010	The graph below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in technology over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	178	1591	ios	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-07 19:19:47.21058	2025-09-13 19:19:47.21058	2025-09-09 19:19:47.21058
20b17b2b-1dc7-40b3-8ce1-1565ff0b4c51	f0000004-0000-0000-0000-000000000004	task1	c1000009-0000-0000-0000-000000000012	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in environment over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	161	1445	ios	pending	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	2025-10-24 19:19:47.21058	2025-10-15 19:19:47.21058	2025-09-13 19:19:47.21058
868366d1-5e47-482e-91f0-cc43e9db6702	f0000005-0000-0000-0000-000000000005	task1	c1000011-0000-0000-0000-000000000014	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in environment over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	159	1519	ios	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-25 19:19:47.21058	2025-09-20 19:19:47.21058	2025-09-11 19:19:47.21058
12c07299-ae35-43f0-b3e2-d8380ceccfb3	f0000006-0000-0000-0000-000000000006	task1	c1000012-0000-0000-0000-000000000015	The chart below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in economy over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	154	1370	web	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-29 19:19:47.21058	2025-10-10 19:19:47.21058	2025-09-28 19:19:47.21058
4c49384f-b74c-4ee2-9d65-25403a43a283	f0000007-0000-0000-0000-000000000007	task2	c2000002-0000-0000-0000-000000000005	Some people think that the government should provide free healthcare for all citizens, while others believe that individuals should pay for their own medical care. Discuss both views and give your own opinion.	In recent years, the topic of healthcare has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	263	2972	ios	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-29 19:19:47.21058	2025-11-01 19:19:47.21058	2025-11-04 19:19:47.21058
9f0408f1-62d9-47e3-a437-cbdd47b45398	f0000008-0000-0000-0000-000000000008	task2	c2000014-0000-0000-0000-000000000017	Some people prefer to live in the countryside, while others prefer city life. Discuss both views and give your own opinion.	In recent years, the topic of politics has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	253	2656	ios	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	\N	2025-10-22 19:19:47.21058	2025-11-04 19:19:47.21058
9011ca23-109e-4da4-8953-98e5427f6ec6	f0000009-0000-0000-0000-000000000009	task2	c2000017-0000-0000-0000-000000000020	Many believe that climate change is the most serious problem facing the world today. To what extent do you agree or disagree?	In recent years, the topic of politics has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	297	3336	ios	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-19 19:19:47.21058	2025-10-23 19:19:47.21058	2025-11-03 19:19:47.21058
b006ba61-4ecd-4671-b294-8ec0236a6ec5	f0000010-0000-0000-0000-000000000010	task2	c2000018-0000-0000-0000-000000000021	Some argue that fast food has a negative impact on health. Do you agree or disagree?	In recent years, the topic of technology has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	289	3306	web	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-11-03 19:19:47.21058	2025-10-15 19:19:47.21058	2025-09-17 19:19:47.21058
ff2447b1-eab2-499f-9ce3-70662506997a	f0000011-0000-0000-0000-000000000011	task2	c2000019-0000-0000-0000-000000000022	Some people believe that technology makes our lives more complicated. To what extent do you agree or disagree?	In recent years, the topic of technology has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	292	3593	web	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	\N	2025-09-26 19:19:47.21058	2025-09-30 19:19:47.21058
e6990f6f-f326-4d6e-8115-08ece88383b3	f0000012-0000-0000-0000-000000000012	task1	c1000002-0000-0000-0000-000000000002	The graph below shows the proportion of the population aged 65 and over between 1940 and 2040 in three different countries.\nSummarize the information by selecting and reporting the main features, and make comparisons where relevant.	The chart illustrates the trends in demographics over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	160	1514	ios	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-11-03 19:19:47.21058	2025-09-23 19:19:47.21058	2025-10-26 19:19:47.21058
33109d5a-a263-48a2-b7bf-d028e8c12298	f0000013-0000-0000-0000-000000000013	task1	c1000004-0000-0000-0000-000000000007	The graph below shows educational achievements in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in culture over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	155	1584	android	completed	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	2025-10-22 19:19:47.21058	2025-09-16 19:19:47.21058	2025-10-30 19:19:47.21058
8771fac9-d05c-4552-a2d9-639d654b8777	f0000014-0000-0000-0000-000000000014	task1	c1000008-0000-0000-0000-000000000011	The diagram below shows employment rates in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in technology over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	161	1206	ios	completed	\N	\N	\N	2025-11-04 19:19:47.21058	\N	2025-09-27 19:19:47.21058	2025-10-12 19:19:47.21058
e33533f5-c7b2-42d1-8c46-743d5ed0e7fc	f0000015-0000-0000-0000-000000000015	task1	c1000009-0000-0000-0000-000000000012	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in environment over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	158	1786	ios	pending	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	2025-11-03 19:19:47.21058	2025-09-28 19:19:47.21058	2025-09-11 19:19:47.21058
65067a9e-c7a3-434b-9f40-bcaa70836de1	f0000016-0000-0000-0000-000000000016	task1	c1000010-0000-0000-0000-000000000013	The graph below shows employment rates in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in politics over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	171	1384	ios	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-23 19:19:47.21058	2025-10-27 19:19:47.21058	2025-09-13 19:19:47.21058
e9679626-7eb6-4d78-93e3-71d6ebaef360	f0000017-0000-0000-0000-000000000017	task1	c1000011-0000-0000-0000-000000000014	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in environment over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	165	1263	web	completed	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	\N	2025-10-23 19:19:47.21058	2025-09-19 19:19:47.21058
e33575bd-49d5-405a-9bbc-6aba5419f81b	f0000018-0000-0000-0000-000000000018	task2	c2000020-0000-0000-0000-000000000023	Some argue that fast food has a negative impact on health. Do you agree or disagree?	In recent years, the topic of society has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	267	3515	web	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-14 19:19:47.21058	2025-10-23 19:19:47.21058	2025-10-05 19:19:47.21058
1527493f-9d60-4742-aee8-1479119e34dc	f0000019-0000-0000-0000-000000000019	task2	c2000021-0000-0000-0000-000000000024	Some people believe that technology makes our lives more complicated. To what extent do you agree or disagree?	In recent years, the topic of environment has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	287	3129	ios	pending	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-12 19:19:47.21058	2025-10-21 19:19:47.21058	2025-10-12 19:19:47.21058
b71789c4-9f29-4469-8daf-4f295f54de96	f0000020-0000-0000-0000-000000000020	task2	c2000023-0000-0000-0000-000000000026	Many people think that university education should be free. Discuss both views and give your own opinion.	In recent years, the topic of education has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	276	2941	android	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-10 19:19:47.21058	2025-09-30 19:19:47.21058	2025-11-04 19:19:47.21058
0aa801fc-2273-4c75-b619-80df32f2deba	f0000021-0000-0000-0000-000000000021	task1	c1000005-0000-0000-0000-000000000008	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in culture over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	160	1746	android	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-16 19:19:47.21058	2025-09-07 19:19:47.21058	2025-10-17 19:19:47.21058
c06f04a7-a21f-4997-87b1-a7255fb7b9ce	f0000022-0000-0000-0000-000000000022	task1	c1000008-0000-0000-0000-000000000011	The diagram below shows employment rates in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in technology over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	165	1549	ios	completed	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	2025-10-21 19:19:47.21058	2025-10-24 19:19:47.21058	2025-10-19 19:19:47.21058
a5e1dfa3-9d20-4d36-9469-fba806afba22	f0000023-0000-0000-0000-000000000023	task1	c1000009-0000-0000-0000-000000000012	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in environment over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	151	1364	web	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-09 19:19:47.21058	2025-10-25 19:19:47.21058	2025-11-03 19:19:47.21058
acae74e8-bc3f-45e3-881b-a50b9416a979	f0000024-0000-0000-0000-000000000024	task2	c2000002-0000-0000-0000-000000000005	Some people think that the government should provide free healthcare for all citizens, while others believe that individuals should pay for their own medical care. Discuss both views and give your own opinion.	In recent years, the topic of healthcare has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	277	2676	android	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-10 19:19:47.21058	2025-09-15 19:19:47.21058	2025-10-26 19:19:47.21058
13e341b3-6b0e-42e4-ac0f-fcae4051bff4	f0000025-0000-0000-0000-000000000025	task2	c2000003-0000-0000-0000-000000000006	Many people believe that social media has a negative impact on society. To what extent do you agree or disagree?	In recent years, the topic of technology has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	289	3401	web	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-13 19:19:47.21058	2025-09-14 19:19:47.21058	2025-09-16 19:19:47.21058
9ac46ecc-e9fe-4efa-8cad-dc3f2d2c7b9c	f0000026-0000-0000-0000-000000000026	task2	c2000015-0000-0000-0000-000000000018	Some argue that fast food has a negative impact on health. Do you agree or disagree?	In recent years, the topic of politics has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	288	2809	android	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-11-01 19:19:47.21058	2025-10-10 19:19:47.21058	2025-10-01 19:19:47.21058
9196efe4-7cd9-4369-9c4f-ffa2fac625c2	f0000027-0000-0000-0000-000000000027	task2	c2000018-0000-0000-0000-000000000021	Some argue that fast food has a negative impact on health. Do you agree or disagree?	In recent years, the topic of technology has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	259	2749	web	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-11 19:19:47.21058	2025-10-19 19:19:47.21058	2025-09-09 19:19:47.21058
1ff1564d-7f38-4667-9787-bd996b067a6e	f0000028-0000-0000-0000-000000000028	task2	c2000019-0000-0000-0000-000000000022	Some people believe that technology makes our lives more complicated. To what extent do you agree or disagree?	In recent years, the topic of technology has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	298	3315	android	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-07 19:19:47.21058	2025-09-15 19:19:47.21058	2025-09-10 19:19:47.21058
86c77596-fc9c-416c-a62c-e2512ffd6af4	f0000029-0000-0000-0000-000000000029	task1	c1000004-0000-0000-0000-000000000007	The graph below shows educational achievements in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in culture over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	167	1721	ios	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-20 19:19:47.21058	2025-09-29 19:19:47.21058	2025-09-20 19:19:47.21058
83f728fb-8650-4242-bb0a-2a9efca229d4	f0000030-0000-0000-0000-000000000030	task1	c1000009-0000-0000-0000-000000000012	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in environment over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	171	1241	android	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-21 19:19:47.21058	2025-11-02 19:19:47.21058	2025-10-20 19:19:47.21058
aa0b8d67-cdfd-4339-8def-5bb886119e84	f0000031-0000-0000-0000-000000000031	task2	c2000016-0000-0000-0000-000000000019	Some argue that fast food has a negative impact on health. Do you agree or disagree?	In recent years, the topic of education has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	268	2876	ios	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-22 19:19:47.21058	2025-10-30 19:19:47.21058	2025-11-01 19:19:47.21058
822d3a43-b9da-4f09-a4fb-b7c8f605106d	f0000032-0000-0000-0000-000000000032	task2	c2000020-0000-0000-0000-000000000023	Some argue that fast food has a negative impact on health. Do you agree or disagree?	In recent years, the topic of society has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	278	3262	ios	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-30 19:19:47.21058	2025-09-26 19:19:47.21058	2025-10-14 19:19:47.21058
7cc9c67d-9a39-408f-b205-5cffc90e6504	f0000033-0000-0000-0000-000000000033	task1	c1000004-0000-0000-0000-000000000007	The graph below shows educational achievements in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in culture over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	170	1247	android	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-24 19:19:47.21058	2025-10-11 19:19:47.21058	2025-09-07 19:19:47.21058
66ca3590-be90-4150-a818-17433a6c8bd1	f0000034-0000-0000-0000-000000000034	task1	c1000010-0000-0000-0000-000000000013	The graph below shows employment rates in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in politics over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	154	1239	ios	completed	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	2025-10-20 19:19:47.21058	2025-10-07 19:19:47.21058	2025-09-16 19:19:47.21058
a2dc05c3-cb91-4b72-ad75-cd25672b51a7	f0000035-0000-0000-0000-000000000035	task1	c1000011-0000-0000-0000-000000000014	The diagram below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in environment over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	152	1542	android	completed	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	\N	2025-09-24 19:19:47.21058	2025-10-04 19:19:47.21058
19b68d67-aaee-4fa8-8f4e-edbd9e4a5dc8	f0000036-0000-0000-0000-000000000036	task1	c1000012-0000-0000-0000-000000000015	The chart below shows energy consumption in different regions. Summarize the information by selecting and reporting the main features.	The chart illustrates the trends in economy over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...	177	1464	ios	completed	\N	c3000001-0000-0000-0000-000000000008	\N	2025-11-04 19:19:47.21058	2025-10-26 19:19:47.21058	2025-09-18 19:19:47.21058	2025-10-08 19:19:47.21058
53858c73-bd79-44a0-9525-80afec16df91	f0000037-0000-0000-0000-000000000037	task2	c2000003-0000-0000-0000-000000000006	Many people believe that social media has a negative impact on society. To what extent do you agree or disagree?	In recent years, the topic of technology has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	280	3134	ios	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-09 19:19:47.21058	2025-10-26 19:19:47.21058	2025-09-20 19:19:47.21058
905247e4-636b-4f6b-9cf4-adedcbe982fe	f0000038-0000-0000-0000-000000000038	task2	c2000014-0000-0000-0000-000000000017	Some people prefer to live in the countryside, while others prefer city life. Discuss both views and give your own opinion.	In recent years, the topic of politics has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	277	3035	android	completed	\N	\N	\N	2025-11-04 19:19:47.21058	2025-10-10 19:19:47.21058	2025-09-20 19:19:47.21058	2025-10-09 19:19:47.21058
efd0f979-b8b2-4323-b9e3-ed8df41270c0	f0000039-0000-0000-0000-000000000039	task2	c2000017-0000-0000-0000-000000000020	Many believe that climate change is the most serious problem facing the world today. To what extent do you agree or disagree?	In recent years, the topic of politics has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	256	2402	android	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-24 19:19:47.21058	2025-09-13 19:19:47.21058	2025-09-24 19:19:47.21058
3de41e4a-fb63-4b06-8bf0-08d0850705a6	f0000040-0000-0000-0000-000000000040	task2	c2000021-0000-0000-0000-000000000024	Some people believe that technology makes our lives more complicated. To what extent do you agree or disagree?	In recent years, the topic of environment has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	279	2654	ios	completed	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-10-24 19:19:47.21058	2025-09-17 19:19:47.21058	2025-09-10 19:19:47.21058
aecce938-f8b1-47a1-b580-d6fa5bc7c184	f0000041-0000-0000-0000-000000000041	task2	c2000023-0000-0000-0000-000000000026	Many people think that university education should be free. Discuss both views and give your own opinion.	In recent years, the topic of education has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...	272	3575	android	pending	\N	c3000002-0000-0000-0000-000000000009	\N	2025-11-04 19:19:47.21058	2025-11-01 19:19:47.21058	2025-09-18 19:19:47.21058	2025-09-22 19:19:47.21058
\.


--
-- Name: ai_model_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.ai_model_versions_id_seq', 3, true);


--
-- Name: grading_criteria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.grading_criteria_id_seq', 5, true);


--
-- Name: schema_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.schema_migrations_id_seq', 18, true);


--
-- Name: ai_model_versions ai_model_versions_model_type_model_name_version_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.ai_model_versions
    ADD CONSTRAINT ai_model_versions_model_type_model_name_version_key UNIQUE (model_type, model_name, version);


--
-- Name: ai_model_versions ai_model_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.ai_model_versions
    ADD CONSTRAINT ai_model_versions_pkey PRIMARY KEY (id);


--
-- Name: ai_processing_queue ai_processing_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.ai_processing_queue
    ADD CONSTRAINT ai_processing_queue_pkey PRIMARY KEY (id);


--
-- Name: evaluation_feedback_ratings evaluation_feedback_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.evaluation_feedback_ratings
    ADD CONSTRAINT evaluation_feedback_ratings_pkey PRIMARY KEY (id);


--
-- Name: grading_criteria grading_criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.grading_criteria
    ADD CONSTRAINT grading_criteria_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_migration_file_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_migration_file_key UNIQUE (migration_file);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (id);


--
-- Name: speaking_evaluations speaking_evaluations_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.speaking_evaluations
    ADD CONSTRAINT speaking_evaluations_pkey PRIMARY KEY (id);


--
-- Name: speaking_evaluations speaking_evaluations_submission_id_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.speaking_evaluations
    ADD CONSTRAINT speaking_evaluations_submission_id_key UNIQUE (submission_id);


--
-- Name: speaking_prompts speaking_prompts_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.speaking_prompts
    ADD CONSTRAINT speaking_prompts_pkey PRIMARY KEY (id);


--
-- Name: speaking_submissions speaking_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.speaking_submissions
    ADD CONSTRAINT speaking_submissions_pkey PRIMARY KEY (id);


--
-- Name: writing_evaluations writing_evaluations_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.writing_evaluations
    ADD CONSTRAINT writing_evaluations_pkey PRIMARY KEY (id);


--
-- Name: writing_evaluations writing_evaluations_submission_id_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.writing_evaluations
    ADD CONSTRAINT writing_evaluations_submission_id_key UNIQUE (submission_id);


--
-- Name: writing_prompts writing_prompts_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.writing_prompts
    ADD CONSTRAINT writing_prompts_pkey PRIMARY KEY (id);


--
-- Name: writing_submissions writing_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.writing_submissions
    ADD CONSTRAINT writing_submissions_pkey PRIMARY KEY (id);


--
-- Name: idx_ai_processing_queue_priority; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_ai_processing_queue_priority ON public.ai_processing_queue USING btree (priority DESC, created_at);


--
-- Name: idx_ai_processing_queue_status; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_ai_processing_queue_status ON public.ai_processing_queue USING btree (status);


--
-- Name: idx_ai_processing_queue_submission; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_ai_processing_queue_submission ON public.ai_processing_queue USING btree (submission_id, submission_type);


--
-- Name: idx_evaluation_feedback_evaluation_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_evaluation_feedback_evaluation_id ON public.evaluation_feedback_ratings USING btree (evaluation_id);


--
-- Name: idx_evaluation_feedback_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_evaluation_feedback_user_id ON public.evaluation_feedback_ratings USING btree (user_id);


--
-- Name: idx_speaking_evaluations_overall_band_score; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_evaluations_overall_band_score ON public.speaking_evaluations USING btree (overall_band_score);


--
-- Name: idx_speaking_evaluations_submission_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_evaluations_submission_id ON public.speaking_evaluations USING btree (submission_id);


--
-- Name: idx_speaking_prompts_difficulty; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_prompts_difficulty ON public.speaking_prompts USING btree (difficulty);


--
-- Name: idx_speaking_prompts_part_number; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_prompts_part_number ON public.speaking_prompts USING btree (part_number);


--
-- Name: idx_speaking_prompts_topic_category; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_prompts_topic_category ON public.speaking_prompts USING btree (topic_category);


--
-- Name: idx_speaking_submissions_part_number; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_submissions_part_number ON public.speaking_submissions USING btree (part_number);


--
-- Name: idx_speaking_submissions_status; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_submissions_status ON public.speaking_submissions USING btree (status);


--
-- Name: idx_speaking_submissions_submitted_at; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_submissions_submitted_at ON public.speaking_submissions USING btree (submitted_at);


--
-- Name: idx_speaking_submissions_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_speaking_submissions_user_id ON public.speaking_submissions USING btree (user_id);


--
-- Name: idx_writing_evaluations_detailed_feedback_json; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_evaluations_detailed_feedback_json ON public.writing_evaluations USING gin (detailed_feedback_json) WHERE (detailed_feedback_json IS NOT NULL);


--
-- Name: idx_writing_evaluations_overall_band_score; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_evaluations_overall_band_score ON public.writing_evaluations USING btree (overall_band_score);


--
-- Name: idx_writing_evaluations_submission_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_evaluations_submission_id ON public.writing_evaluations USING btree (submission_id);


--
-- Name: idx_writing_prompts_difficulty; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_prompts_difficulty ON public.writing_prompts USING btree (difficulty);


--
-- Name: idx_writing_prompts_task_type; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_prompts_task_type ON public.writing_prompts USING btree (task_type);


--
-- Name: idx_writing_prompts_topic; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_prompts_topic ON public.writing_prompts USING btree (topic);


--
-- Name: idx_writing_submissions_status; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_submissions_status ON public.writing_submissions USING btree (status);


--
-- Name: idx_writing_submissions_submitted_at; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_submissions_submitted_at ON public.writing_submissions USING btree (submitted_at);


--
-- Name: idx_writing_submissions_task_type; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_submissions_task_type ON public.writing_submissions USING btree (task_type);


--
-- Name: idx_writing_submissions_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_writing_submissions_user_id ON public.writing_submissions USING btree (user_id);


--
-- Name: speaking_submissions trigger_create_speaking_task; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER trigger_create_speaking_task AFTER INSERT ON public.speaking_submissions FOR EACH ROW EXECUTE FUNCTION public.create_ai_processing_task();


--
-- Name: writing_submissions trigger_create_writing_task; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER trigger_create_writing_task AFTER INSERT ON public.writing_submissions FOR EACH ROW EXECUTE FUNCTION public.create_ai_processing_task();


--
-- Name: ai_processing_queue update_ai_processing_queue_updated_at; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER update_ai_processing_queue_updated_at BEFORE UPDATE ON public.ai_processing_queue FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: speaking_submissions update_speaking_submissions_updated_at; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER update_speaking_submissions_updated_at BEFORE UPDATE ON public.speaking_submissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: writing_submissions update_writing_submissions_updated_at; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER update_writing_submissions_updated_at BEFORE UPDATE ON public.writing_submissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: speaking_evaluations speaking_evaluations_submission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.speaking_evaluations
    ADD CONSTRAINT speaking_evaluations_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.speaking_submissions(id) ON DELETE CASCADE;


--
-- Name: writing_evaluations writing_evaluations_submission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.writing_evaluations
    ADD CONSTRAINT writing_evaluations_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.writing_submissions(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

