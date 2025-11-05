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
-- Name: calculate_overall_score(numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: ielts_admin
--

CREATE FUNCTION public.calculate_overall_score(listening numeric, reading numeric, writing numeric, speaking numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN ROUND((listening + reading + writing + speaking) / 4, 1);
END;
$$;


ALTER FUNCTION public.calculate_overall_score(listening numeric, reading numeric, writing numeric, speaking numeric) OWNER TO ielts_admin;

--
-- Name: update_study_streak(uuid); Type: FUNCTION; Schema: public; Owner: ielts_admin
--

CREATE FUNCTION public.update_study_streak(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_last_study_date DATE;
    v_current_streak INT;
BEGIN
    SELECT last_study_date, current_streak_days 
    INTO v_last_study_date, v_current_streak
    FROM learning_progress
    WHERE user_id = p_user_id;
    
    -- If studied today, no need to update
    IF v_last_study_date = CURRENT_DATE THEN
        RETURN;
    END IF;
    
    -- If studied yesterday, increment streak
    IF v_last_study_date = CURRENT_DATE - INTERVAL '1 day' THEN
        UPDATE learning_progress
        SET current_streak_days = current_streak_days + 1,
            longest_streak_days = GREATEST(longest_streak_days, current_streak_days + 1),
            last_study_date = CURRENT_DATE
        WHERE user_id = p_user_id;
    ELSE
        -- Streak broken, reset to 1
        UPDATE learning_progress
        SET current_streak_days = 1,
            last_study_date = CURRENT_DATE
        WHERE user_id = p_user_id;
    END IF;
END;
$$;


ALTER FUNCTION public.update_study_streak(p_user_id uuid) OWNER TO ielts_admin;

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
-- Name: achievements; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.achievements (
    id integer NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    criteria_type character varying(50) NOT NULL,
    criteria_value integer NOT NULL,
    icon_url text,
    badge_color character varying(20),
    points integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.achievements OWNER TO ielts_admin;

--
-- Name: TABLE achievements; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.achievements IS 'Danh sách thành tựu có thể đạt được';


--
-- Name: achievements_id_seq; Type: SEQUENCE; Schema: public; Owner: ielts_admin
--

CREATE SEQUENCE public.achievements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.achievements_id_seq OWNER TO ielts_admin;

--
-- Name: achievements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ielts_admin
--

ALTER SEQUENCE public.achievements_id_seq OWNED BY public.achievements.id;


--
-- Name: learning_progress; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.learning_progress (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    total_lessons_completed integer DEFAULT 0,
    total_exercises_completed integer DEFAULT 0,
    listening_progress numeric(5,2) DEFAULT 0,
    reading_progress numeric(5,2) DEFAULT 0,
    writing_progress numeric(5,2) DEFAULT 0,
    speaking_progress numeric(5,2) DEFAULT 0,
    listening_score numeric(2,1),
    reading_score numeric(2,1),
    writing_score numeric(2,1),
    speaking_score numeric(2,1),
    overall_score numeric(2,1),
    current_streak_days integer DEFAULT 0,
    longest_streak_days integer DEFAULT 0,
    last_study_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.learning_progress OWNER TO ielts_admin;

--
-- Name: TABLE learning_progress; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.learning_progress IS 'Theo dõi tiến trình học tổng thể';


--
-- Name: learning_progress_id_seq; Type: SEQUENCE; Schema: public; Owner: ielts_admin
--

CREATE SEQUENCE public.learning_progress_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.learning_progress_id_seq OWNER TO ielts_admin;

--
-- Name: learning_progress_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ielts_admin
--

ALTER SEQUENCE public.learning_progress_id_seq OWNED BY public.learning_progress.id;


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
-- Name: skill_statistics; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.skill_statistics (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    skill_type character varying(20) NOT NULL,
    total_practices integer DEFAULT 0,
    completed_practices integer DEFAULT 0,
    average_score numeric(5,2),
    best_score numeric(5,2),
    total_time_minutes integer DEFAULT 0,
    last_practice_date timestamp without time zone,
    last_practice_score numeric(5,2),
    score_trend jsonb,
    weak_areas jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.skill_statistics OWNER TO ielts_admin;

--
-- Name: TABLE skill_statistics; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.skill_statistics IS 'Thống kê chi tiết cho từng kỹ năng';


--
-- Name: skill_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: ielts_admin
--

CREATE SEQUENCE public.skill_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skill_statistics_id_seq OWNER TO ielts_admin;

--
-- Name: skill_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ielts_admin
--

ALTER SEQUENCE public.skill_statistics_id_seq OWNED BY public.skill_statistics.id;


--
-- Name: study_goals; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.study_goals (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    goal_type character varying(50) NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    target_value integer NOT NULL,
    target_unit character varying(20) NOT NULL,
    current_value integer DEFAULT 0,
    skill_type character varying(20),
    start_date date NOT NULL,
    end_date date NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    completed_at timestamp without time zone,
    reminder_enabled boolean DEFAULT true,
    reminder_time time without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.study_goals OWNER TO ielts_admin;

--
-- Name: TABLE study_goals; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.study_goals IS 'Mục tiêu học tập người dùng tự đặt';


--
-- Name: study_reminders; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.study_reminders (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    title character varying(200) NOT NULL,
    message text,
    reminder_type character varying(20) NOT NULL,
    reminder_time time without time zone NOT NULL,
    days_of_week integer[],
    is_active boolean DEFAULT true,
    last_sent_at timestamp without time zone,
    next_send_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.study_reminders OWNER TO ielts_admin;

--
-- Name: study_sessions; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.study_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    session_type character varying(50) NOT NULL,
    skill_type character varying(20),
    resource_id uuid,
    resource_type character varying(50),
    started_at timestamp without time zone NOT NULL,
    ended_at timestamp without time zone,
    duration_minutes integer,
    is_completed boolean DEFAULT false,
    completion_percentage numeric(5,2),
    score numeric(5,2),
    device_type character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.study_sessions OWNER TO ielts_admin;

--
-- Name: TABLE study_sessions; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.study_sessions IS 'Lịch sử các session học tập';


--
-- Name: user_achievements; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.user_achievements (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    achievement_id integer NOT NULL,
    earned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_achievements OWNER TO ielts_admin;

--
-- Name: TABLE user_achievements; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.user_achievements IS 'Thành tựu người dùng đã đạt được';


--
-- Name: user_achievements_id_seq; Type: SEQUENCE; Schema: public; Owner: ielts_admin
--

CREATE SEQUENCE public.user_achievements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_achievements_id_seq OWNER TO ielts_admin;

--
-- Name: user_achievements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ielts_admin
--

ALTER SEQUENCE public.user_achievements_id_seq OWNED BY public.user_achievements.id;


--
-- Name: user_follows; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.user_follows (
    id bigint NOT NULL,
    follower_id uuid NOT NULL,
    following_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_no_self_follow CHECK ((follower_id <> following_id))
);


ALTER TABLE public.user_follows OWNER TO ielts_admin;

--
-- Name: TABLE user_follows; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.user_follows IS 'Tracks user follow relationships for social features';


--
-- Name: COLUMN user_follows.follower_id; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON COLUMN public.user_follows.follower_id IS 'User who is following';


--
-- Name: COLUMN user_follows.following_id; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON COLUMN public.user_follows.following_id IS 'User being followed';


--
-- Name: CONSTRAINT check_no_self_follow ON user_follows; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON CONSTRAINT check_no_self_follow ON public.user_follows IS 'Prevents users from following themselves';


--
-- Name: user_follows_id_seq; Type: SEQUENCE; Schema: public; Owner: ielts_admin
--

CREATE SEQUENCE public.user_follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_follows_id_seq OWNER TO ielts_admin;

--
-- Name: user_follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ielts_admin
--

ALTER SEQUENCE public.user_follows_id_seq OWNED BY public.user_follows.id;


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.user_preferences (
    user_id uuid NOT NULL,
    email_notifications boolean DEFAULT true,
    push_notifications boolean DEFAULT true,
    study_reminders boolean DEFAULT true,
    weekly_report boolean DEFAULT true,
    theme character varying(20) DEFAULT 'light'::character varying,
    font_size character varying(20) DEFAULT 'medium'::character varying,
    auto_play_next_lesson boolean DEFAULT true,
    show_answer_explanation boolean DEFAULT true,
    playback_speed numeric(3,2) DEFAULT 1.0,
    profile_visibility character varying(20) DEFAULT 'private'::character varying,
    show_study_stats boolean DEFAULT true,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    locale character varying(10) DEFAULT 'vi'::character varying
);


ALTER TABLE public.user_preferences OWNER TO ielts_admin;

--
-- Name: COLUMN user_preferences.locale; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON COLUMN public.user_preferences.locale IS 'User interface language: vi (Vietnamese), en (English)';


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: ielts_admin
--

CREATE TABLE public.user_profiles (
    user_id uuid NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    full_name character varying(200),
    date_of_birth date,
    gender character varying(20),
    phone character varying(20),
    address text,
    city character varying(100),
    country character varying(100),
    timezone character varying(50) DEFAULT 'Asia/Ho_Chi_Minh'::character varying,
    avatar_url text,
    cover_image_url text,
    current_level character varying(20),
    target_band_score numeric(2,1),
    target_exam_date date,
    bio text,
    learning_preferences jsonb,
    language_preference character varying(10) DEFAULT 'vi'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone
);


ALTER TABLE public.user_profiles OWNER TO ielts_admin;

--
-- Name: TABLE user_profiles; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON TABLE public.user_profiles IS 'Thông tin chi tiết profile người dùng';


--
-- Name: achievements id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.achievements ALTER COLUMN id SET DEFAULT nextval('public.achievements_id_seq'::regclass);


--
-- Name: learning_progress id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.learning_progress ALTER COLUMN id SET DEFAULT nextval('public.learning_progress_id_seq'::regclass);


--
-- Name: schema_migrations id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.schema_migrations ALTER COLUMN id SET DEFAULT nextval('public.schema_migrations_id_seq'::regclass);


--
-- Name: skill_statistics id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.skill_statistics ALTER COLUMN id SET DEFAULT nextval('public.skill_statistics_id_seq'::regclass);


--
-- Name: user_achievements id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_achievements ALTER COLUMN id SET DEFAULT nextval('public.user_achievements_id_seq'::regclass);


--
-- Name: user_follows id; Type: DEFAULT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_follows ALTER COLUMN id SET DEFAULT nextval('public.user_follows_id_seq'::regclass);


--
-- Data for Name: achievements; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.achievements (id, code, name, description, criteria_type, criteria_value, icon_url, badge_color, points, created_at) FROM stdin;
1	first_lesson	Bài học đầu tiên	Hoàn thành bài học đầu tiên	completion	1	\N	\N	10	2025-10-30 18:58:53.488039
2	streak_7	7 ngày liên tiếp	Học 7 ngày liên tiếp	streak	7	\N	\N	50	2025-10-30 18:58:53.488039
3	streak_30	30 ngày liên tiếp	Học 30 ngày liên tiếp	streak	30	\N	\N	200	2025-10-30 18:58:53.488039
4	band_6	IELTS 6.0	Đạt band 6.0 trong bài test	score	60	\N	\N	100	2025-10-30 18:58:53.488039
5	band_7	IELTS 7.0	Đạt band 7.0 trong bài test	score	70	\N	\N	150	2025-10-30 18:58:53.488039
6	listening_master	Listening Master	Hoàn thành 100 bài listening	completion	100	\N	\N	100	2025-10-30 18:58:53.488039
\.


--
-- Data for Name: learning_progress; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.learning_progress (id, user_id, total_lessons_completed, total_exercises_completed, listening_progress, reading_progress, writing_progress, speaking_progress, listening_score, reading_score, writing_score, speaking_score, overall_score, current_streak_days, longest_streak_days, last_study_date, created_at, updated_at) FROM stdin;
2911	a0000001-0000-0000-0000-000000000001	49	31	3.68	95.72	56.64	2.81	8.4	6.1	4.4	\N	8.4	10	32	2025-10-28	2024-11-04 19:19:45.823143	2025-11-04 19:19:45.832615
2912	a0000002-0000-0000-0000-000000000002	34	150	11.65	92.95	71.51	27.78	\N	8.9	\N	4.2	4.2	28	40	2025-11-01	2025-01-08 19:19:45.823143	2025-11-04 19:19:45.832615
2913	b0000001-0000-0000-0000-000000000001	52	150	7.52	63.96	94.65	75.42	4.3	5.2	5.5	4.4	\N	29	49	2025-11-03	2025-05-08 19:19:45.823143	2025-11-04 19:19:45.832615
2914	b0000002-0000-0000-0000-000000000002	18	17	69.17	66.37	96.74	51.75	6.6	7.9	8.0	\N	8.5	16	47	2025-10-29	2025-05-13 19:19:45.823143	2025-11-04 19:19:45.832615
2915	b0000003-0000-0000-0000-000000000003	87	84	82.69	86.21	3.48	98.22	9.0	8.8	\N	\N	8.9	18	15	2025-11-01	2025-05-18 19:19:45.823143	2025-11-04 19:19:45.832615
2916	b0000004-0000-0000-0000-000000000004	91	45	87.57	47.91	1.10	13.17	5.9	5.8	\N	\N	8.0	22	34	2025-11-03	2025-05-23 19:19:45.823143	2025-11-04 19:19:45.832615
2917	f0000001-0000-0000-0000-000000000001	95	131	38.63	85.17	78.74	25.31	8.9	6.3	5.5	8.1	7.7	16	69	2025-10-31	2025-07-27 19:19:45.823143	2025-11-04 19:19:45.832615
2918	f0000002-0000-0000-0000-000000000002	49	62	78.18	32.96	15.18	92.80	5.1	\N	4.6	\N	5.5	14	58	2025-10-28	2025-08-01 19:19:45.823143	2025-11-04 19:19:45.832615
2920	f0000004-0000-0000-0000-000000000004	31	81	87.93	66.11	16.07	16.82	5.4	4.1	6.2	\N	\N	8	65	2025-11-02	2025-08-11 19:19:45.823143	2025-11-04 19:19:45.832615
2921	f0000005-0000-0000-0000-000000000005	23	130	0.91	91.62	41.81	29.66	8.0	\N	\N	\N	6.0	8	52	2025-11-02	2025-08-16 19:19:45.823143	2025-11-04 19:19:45.832615
2922	f0000006-0000-0000-0000-000000000006	18	56	72.18	56.69	88.79	90.37	\N	5.4	7.6	\N	7.3	7	26	2025-11-02	2025-08-21 19:19:45.823143	2025-11-04 19:19:45.832615
2923	f0000007-0000-0000-0000-000000000007	87	147	56.41	26.72	61.63	54.61	7.3	8.8	6.5	\N	\N	21	67	2025-10-31	2025-08-26 19:19:45.823143	2025-11-04 19:19:45.832615
2924	f0000008-0000-0000-0000-000000000008	28	133	85.25	75.57	73.14	91.62	4.3	\N	5.5	5.6	5.4	9	42	2025-11-03	2025-08-31 19:19:45.823143	2025-11-04 19:19:45.832615
2925	f0000009-0000-0000-0000-000000000009	87	132	2.23	2.81	6.78	3.81	4.1	8.5	\N	\N	4.1	16	69	2025-10-29	2025-09-05 19:19:45.823143	2025-11-04 19:19:45.832615
2926	f0000010-0000-0000-0000-000000000010	87	79	66.58	74.57	59.79	75.68	4.6	7.6	8.5	5.4	6.8	13	37	2025-10-31	2025-09-10 19:19:45.823143	2025-11-04 19:19:45.832615
2927	f0000011-0000-0000-0000-000000000011	92	74	31.96	53.74	24.48	72.07	4.6	4.8	7.9	5.2	5.2	15	63	2025-10-28	2025-07-29 19:19:45.82703	2025-11-04 19:19:45.832615
2928	f0000012-0000-0000-0000-000000000012	10	59	7.79	93.07	6.86	30.43	\N	4.9	5.2	8.4	\N	15	37	2025-11-01	2025-07-31 19:19:45.82703	2025-11-04 19:19:45.832615
2929	f0000013-0000-0000-0000-000000000013	63	26	33.04	7.87	84.27	58.36	8.9	\N	7.0	\N	\N	11	65	2025-11-04	2025-08-02 19:19:45.82703	2025-11-04 19:19:45.832615
2930	f0000014-0000-0000-0000-000000000014	27	152	1.90	65.44	60.38	77.11	\N	\N	4.5	8.0	5.5	28	44	2025-11-03	2025-08-04 19:19:45.82703	2025-11-04 19:19:45.832615
2931	f0000015-0000-0000-0000-000000000015	47	152	33.21	76.43	63.10	10.17	\N	\N	\N	4.3	4.6	15	35	2025-10-31	2025-08-06 19:19:45.82703	2025-11-04 19:19:45.832615
2932	f0000016-0000-0000-0000-000000000016	20	93	30.69	18.92	7.42	32.51	\N	\N	8.2	\N	7.8	5	18	2025-10-29	2025-08-08 19:19:45.82703	2025-11-04 19:19:45.832615
2933	f0000017-0000-0000-0000-000000000017	10	68	3.26	46.37	19.43	45.96	7.4	4.9	\N	4.5	8.2	14	38	2025-11-01	2025-08-10 19:19:45.82703	2025-11-04 19:19:45.832615
2934	f0000018-0000-0000-0000-000000000018	24	20	22.59	79.05	61.02	61.86	\N	8.2	\N	\N	6.6	8	58	2025-11-01	2025-08-12 19:19:45.82703	2025-11-04 19:19:45.832615
2935	f0000019-0000-0000-0000-000000000019	89	155	36.57	38.26	83.41	80.10	5.0	\N	5.4	7.7	\N	9	55	2025-11-01	2025-08-14 19:19:45.82703	2025-11-04 19:19:45.832615
2936	f0000020-0000-0000-0000-000000000020	46	95	8.47	10.57	77.13	30.04	4.2	8.4	4.5	4.4	7.2	24	12	2025-10-28	2025-08-16 19:19:45.82703	2025-11-04 19:19:45.832615
2937	f0000021-0000-0000-0000-000000000021	46	55	14.88	4.02	66.75	97.67	\N	6.3	4.1	7.4	8.7	21	35	2025-11-02	2025-08-18 19:19:45.82703	2025-11-04 19:19:45.832615
2938	f0000022-0000-0000-0000-000000000022	97	155	21.99	10.39	15.97	25.74	\N	8.6	7.7	8.5	7.3	23	66	2025-11-03	2025-08-20 19:19:45.82703	2025-11-04 19:19:45.832615
2939	f0000023-0000-0000-0000-000000000023	45	34	1.12	10.82	71.12	76.09	7.9	6.1	4.1	4.7	8.3	27	45	2025-10-30	2025-08-22 19:19:45.82703	2025-11-04 19:19:45.832615
2940	f0000024-0000-0000-0000-000000000024	67	113	32.24	69.86	31.64	5.01	5.4	6.4	\N	4.5	\N	5	41	2025-11-04	2025-08-24 19:19:45.82703	2025-11-04 19:19:45.832615
2941	f0000025-0000-0000-0000-000000000025	94	48	41.42	9.98	65.79	97.30	7.3	4.9	7.4	6.9	\N	10	48	2025-10-29	2025-08-26 19:19:45.82703	2025-11-04 19:19:45.832615
2942	f0000026-0000-0000-0000-000000000026	66	139	93.58	10.67	14.33	99.81	\N	5.1	\N	6.0	\N	18	20	2025-11-03	2025-08-28 19:19:45.82703	2025-11-04 19:19:45.832615
2943	f0000027-0000-0000-0000-000000000027	53	37	82.78	51.16	29.78	52.53	8.2	\N	5.3	\N	4.5	17	50	2025-11-02	2025-08-30 19:19:45.82703	2025-11-04 19:19:45.832615
2944	f0000028-0000-0000-0000-000000000028	45	83	3.98	80.36	20.53	92.97	\N	\N	\N	7.4	\N	27	43	2025-11-03	2025-09-01 19:19:45.82703	2025-11-04 19:19:45.832615
2945	f0000029-0000-0000-0000-000000000029	66	55	33.38	90.10	16.61	9.89	4.5	4.5	\N	8.0	7.1	29	68	2025-11-02	2025-09-03 19:19:45.82703	2025-11-04 19:19:45.832615
2946	f0000030-0000-0000-0000-000000000030	36	92	30.65	39.80	65.60	70.35	8.5	7.1	8.6	5.5	\N	4	67	2025-11-02	2025-09-05 19:19:45.82703	2025-11-04 19:19:45.832615
2947	f0000031-0000-0000-0000-000000000031	98	45	73.35	4.60	14.26	78.40	4.5	5.3	\N	\N	7.5	3	16	2025-11-01	2025-09-07 19:19:45.82703	2025-11-04 19:19:45.832615
2948	f0000032-0000-0000-0000-000000000032	27	95	10.42	77.39	10.57	27.96	7.4	5.4	7.2	\N	7.0	6	21	2025-10-30	2025-09-09 19:19:45.82703	2025-11-04 19:19:45.832615
2949	f0000033-0000-0000-0000-000000000033	97	54	8.28	45.61	62.98	63.65	4.0	6.8	7.6	8.1	\N	28	28	2025-11-03	2025-09-11 19:19:45.82703	2025-11-04 19:19:45.832615
2950	f0000034-0000-0000-0000-000000000034	51	40	37.18	61.59	92.99	92.53	\N	7.3	\N	4.6	5.0	23	70	2025-11-02	2025-09-13 19:19:45.82703	2025-11-04 19:19:45.832615
2951	f0000035-0000-0000-0000-000000000035	83	94	78.25	31.58	51.24	68.44	\N	4.0	8.2	4.8	\N	13	54	2025-10-31	2025-09-15 19:19:45.82703	2025-11-04 19:19:45.832615
2952	f0000036-0000-0000-0000-000000000036	86	41	86.77	94.48	70.08	94.63	6.9	8.6	\N	\N	8.0	18	14	2025-11-01	2025-09-17 19:19:45.82703	2025-11-04 19:19:45.832615
2953	f0000037-0000-0000-0000-000000000037	57	101	13.74	15.07	44.69	98.49	6.9	6.8	\N	\N	5.6	21	59	2025-10-29	2025-09-19 19:19:45.82703	2025-11-04 19:19:45.832615
2954	f0000038-0000-0000-0000-000000000038	72	89	64.36	74.69	96.23	31.84	\N	8.5	8.9	\N	5.3	9	66	2025-10-29	2025-09-21 19:19:45.82703	2025-11-04 19:19:45.832615
2955	f0000039-0000-0000-0000-000000000039	48	129	18.00	49.67	60.37	44.00	7.0	4.5	8.5	\N	8.4	0	13	2025-11-03	2025-09-23 19:19:45.82703	2025-11-04 19:19:45.832615
2956	f0000040-0000-0000-0000-000000000040	82	160	0.47	25.72	79.45	44.89	4.1	\N	\N	\N	6.0	18	31	2025-11-03	2025-09-25 19:19:45.82703	2025-11-04 19:19:45.832615
2957	f0000041-0000-0000-0000-000000000041	24	13	62.27	84.96	64.23	52.50	8.7	\N	5.2	\N	8.8	10	26	2025-10-30	2025-09-27 19:19:45.82703	2025-11-04 19:19:45.832615
2958	f0000042-0000-0000-0000-000000000042	30	22	59.26	96.24	54.39	44.07	8.5	\N	8.1	6.4	6.5	22	13	2025-10-29	2025-09-29 19:19:45.82703	2025-11-04 19:19:45.832615
2959	f0000043-0000-0000-0000-000000000043	41	58	79.88	40.21	43.13	4.45	4.5	\N	7.7	\N	6.0	15	63	2025-10-30	2025-10-01 19:19:45.82703	2025-11-04 19:19:45.832615
2960	f0000044-0000-0000-0000-000000000044	53	145	14.53	86.83	80.42	62.83	\N	\N	\N	8.5	6.3	17	20	2025-11-04	2025-10-03 19:19:45.82703	2025-11-04 19:19:45.832615
2961	f0000045-0000-0000-0000-000000000045	75	32	34.81	92.87	27.36	37.96	5.2	\N	4.6	7.8	5.3	22	68	2025-10-29	2025-10-05 19:19:45.82703	2025-11-04 19:19:45.832615
2962	f0000046-0000-0000-0000-000000000046	65	84	27.76	91.71	76.70	98.05	5.9	6.7	8.9	\N	5.9	25	25	2025-10-31	2025-10-07 19:19:45.82703	2025-11-04 19:19:45.832615
2963	f0000047-0000-0000-0000-000000000047	97	114	64.56	74.69	49.42	23.46	8.8	8.9	5.2	\N	4.9	9	54	2025-10-30	2025-10-09 19:19:45.82703	2025-11-04 19:19:45.832615
2964	f0000048-0000-0000-0000-000000000048	18	50	37.74	8.95	11.58	84.24	\N	7.2	4.6	\N	7.0	14	66	2025-11-01	2025-10-11 19:19:45.82703	2025-11-04 19:19:45.832615
2965	f0000049-0000-0000-0000-000000000049	17	112	59.16	64.02	52.77	49.24	6.9	\N	\N	\N	4.6	13	14	2025-11-01	2025-10-13 19:19:45.82703	2025-11-04 19:19:45.832615
2966	f0000050-0000-0000-0000-000000000050	65	103	83.95	75.49	77.29	84.32	\N	5.5	\N	8.1	5.8	29	25	2025-11-02	2025-10-15 19:19:45.82703	2025-11-04 19:19:45.832615
2967	f0000051-0000-0000-0000-000000000051	56	125	3.05	96.09	72.06	30.42	\N	\N	\N	6.9	\N	13	14	2025-11-04	2025-10-17 19:19:45.82703	2025-11-04 19:19:45.832615
2968	f0000052-0000-0000-0000-000000000052	11	73	74.19	71.79	27.42	47.91	8.1	\N	5.5	4.2	8.3	22	39	2025-10-28	2025-10-19 19:19:45.82703	2025-11-04 19:19:45.832615
2969	f0000053-0000-0000-0000-000000000053	73	95	53.40	69.62	27.33	45.67	6.1	\N	\N	6.1	4.2	25	40	2025-10-30	2025-10-21 19:19:45.82703	2025-11-04 19:19:45.832615
2970	f0000054-0000-0000-0000-000000000054	18	30	57.26	48.97	67.06	2.80	5.9	5.0	\N	7.8	8.6	26	49	2025-11-01	2025-10-23 19:19:45.82703	2025-11-04 19:19:45.832615
2971	f0000055-0000-0000-0000-000000000055	9	85	62.27	42.57	3.56	45.21	\N	6.2	7.3	4.4	8.5	19	47	2025-11-01	2025-10-25 19:19:45.82703	2025-11-04 19:19:45.832615
2972	f0000056-0000-0000-0000-000000000056	56	142	72.66	33.89	57.97	13.24	\N	4.0	6.7	7.9	6.7	3	68	2025-11-03	2025-10-27 19:19:45.82703	2025-11-04 19:19:45.832615
2973	f0000057-0000-0000-0000-000000000057	39	47	16.65	36.47	79.73	52.96	6.7	6.4	7.9	\N	4.4	15	66	2025-11-02	2025-10-29 19:19:45.82703	2025-11-04 19:19:45.832615
2974	f0000058-0000-0000-0000-000000000058	102	154	78.88	15.43	92.95	59.14	6.2	5.1	4.3	\N	4.1	21	43	2025-11-02	2025-10-31 19:19:45.82703	2025-11-04 19:19:45.832615
2975	f0000059-0000-0000-0000-000000000059	79	62	27.22	97.44	2.27	72.73	\N	\N	8.6	6.3	6.8	21	68	2025-11-01	2025-11-02 19:19:45.82703	2025-11-04 19:19:45.832615
2976	f0000060-0000-0000-0000-000000000060	77	113	54.14	20.17	97.20	18.70	7.0	4.5	\N	\N	7.4	4	42	2025-11-03	2025-11-04 19:19:45.82703	2025-11-04 19:19:45.832615
2977	f0000061-0000-0000-0000-000000000061	45	97	3.92	26.57	80.98	20.85	8.3	7.5	\N	6.8	6.6	19	64	2025-10-28	2025-11-06 19:19:45.82703	2025-11-04 19:19:45.832615
2919	f0000003-0000-0000-0000-000000000003	81	133	14.12	79.10	46.46	76.32	2.0	\N	8.4	6.1	5.5	2	16	2025-11-05	2025-08-06 19:19:45.823143	2025-11-05 06:14:59.292093
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.schema_migrations (id, migration_file, applied_at, checksum) FROM stdin;
1	001_add_verification_codes.sql	2025-10-30 18:59:22.779056	\N
2	006_add_exercise_constraints.sql	2025-10-30 18:59:22.804117	\N
3	007_add_notification_constraints.sql	2025-10-30 18:59:22.837882	\N
4	007_add_performance_indexes.sql	2025-10-30 18:59:22.873305	\N
5	008_add_total_exercises_to_modules.sql	2025-10-30 18:59:22.898634	\N
6	008_separate_lessons_and_exercises.sql	2025-10-30 18:59:22.931153	\N
7	009_update_seed_data_exercises.sql	2025-10-30 18:59:22.957926	\N
8	010_reseed_with_new_structure.sql	2025-10-30 18:59:22.991603	\N
9	011_remove_video_watch_percentage.sql	2025-10-30 18:59:23.02977	\N
10	012_enable_dblink_for_cross_database_queries.sql	2025-10-30 18:59:23.061943	\N
11	013_remove_deprecated_study_time_fields.sql	2025-10-30 18:59:23.119512	\N
12	014_add_last_position_seconds.sql	2025-10-31 02:47:15.751117	\N
13	015_fix_submission_scores.sql	2025-10-31 08:15:24.84575	\N
14	016_add_leaderboard_indexes.sql	2025-10-31 08:15:24.906182	\N
15	013_add_locale_to_user_preferences.sql	2025-10-31 22:27:59.975465	\N
16	017_add_user_follows_table.sql	2025-11-01 08:48:53.311167	\N
17	018_add_detailed_feedback_json_to_writing_evaluations.sql	2025-11-03 18:47:23.915879	\N
18	019_add_ielts_test_type_to_exercises.sql	2025-11-04 05:32:53.595064	\N
\.


--
-- Data for Name: skill_statistics; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.skill_statistics (id, user_id, skill_type, total_practices, completed_practices, average_score, best_score, total_time_minutes, last_practice_date, last_practice_score, score_trend, weak_areas, created_at, updated_at) FROM stdin;
9046	a0000001-0000-0000-0000-000000000001	listening	35	25	82.31	93.37	1128	2025-10-16 19:19:45.836382	93.35	[{"date": "2025-10-05", "score": 68.62}, {"date": "2025-10-15", "score": 64.38}, {"date": "2025-10-25", "score": 50.50}, {"date": "2025-11-04", "score": 80.34}]	[{"topic": "Multiple Choice", "accuracy": 88.93}, {"topic": "Note Completion", "accuracy": 81.93}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9047	a0000002-0000-0000-0000-000000000002	listening	35	4	82.31	86.41	334	2025-10-20 19:19:45.836382	77.05	[{"date": "2025-10-05", "score": 54.44}, {"date": "2025-10-15", "score": 76.69}, {"date": "2025-10-25", "score": 52.29}, {"date": "2025-11-04", "score": 57.49}]	[{"topic": "Multiple Choice", "accuracy": 86.99}, {"topic": "Note Completion", "accuracy": 67.92}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9048	b0000001-0000-0000-0000-000000000001	listening	35	35	82.31	97.81	610	2025-10-09 19:19:45.836382	67.60	[{"date": "2025-10-05", "score": 71.90}, {"date": "2025-10-15", "score": 50.03}, {"date": "2025-10-25", "score": 61.68}, {"date": "2025-11-04", "score": 88.50}]	[{"topic": "Multiple Choice", "accuracy": 67.19}, {"topic": "Note Completion", "accuracy": 71.83}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9049	b0000002-0000-0000-0000-000000000002	listening	35	35	82.31	94.31	948	2025-10-18 19:19:45.836382	94.30	[{"date": "2025-10-05", "score": 61.48}, {"date": "2025-10-15", "score": 68.92}, {"date": "2025-10-25", "score": 54.39}, {"date": "2025-11-04", "score": 50.32}]	[{"topic": "Multiple Choice", "accuracy": 62.46}, {"topic": "Note Completion", "accuracy": 84.30}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9050	b0000003-0000-0000-0000-000000000003	listening	35	7	82.31	82.31	372	2025-10-09 19:19:45.836382	52.71	[{"date": "2025-10-05", "score": 76.06}, {"date": "2025-10-15", "score": 73.66}, {"date": "2025-10-25", "score": 78.13}, {"date": "2025-11-04", "score": 84.81}]	[{"topic": "Multiple Choice", "accuracy": 78.22}, {"topic": "Note Completion", "accuracy": 60.41}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9051	b0000004-0000-0000-0000-000000000004	listening	35	32	82.31	82.31	1208	2025-10-29 19:19:45.836382	76.02	[{"date": "2025-10-05", "score": 51.77}, {"date": "2025-10-15", "score": 71.62}, {"date": "2025-10-25", "score": 80.69}, {"date": "2025-11-04", "score": 72.22}]	[{"topic": "Multiple Choice", "accuracy": 69.75}, {"topic": "Note Completion", "accuracy": 78.77}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9052	f0000001-0000-0000-0000-000000000001	listening	35	18	82.31	82.31	246	2025-10-20 19:19:45.836382	97.37	[{"date": "2025-10-05", "score": 61.87}, {"date": "2025-10-15", "score": 60.90}, {"date": "2025-10-25", "score": 62.48}, {"date": "2025-11-04", "score": 66.21}]	[{"topic": "Multiple Choice", "accuracy": 63.95}, {"topic": "Note Completion", "accuracy": 83.14}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9053	f0000002-0000-0000-0000-000000000002	listening	35	28	82.31	82.31	506	2025-10-27 19:19:45.836382	78.98	[{"date": "2025-10-05", "score": 82.70}, {"date": "2025-10-15", "score": 76.95}, {"date": "2025-10-25", "score": 77.73}, {"date": "2025-11-04", "score": 74.17}]	[{"topic": "Multiple Choice", "accuracy": 76.43}, {"topic": "Note Completion", "accuracy": 65.39}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9055	f0000004-0000-0000-0000-000000000004	listening	35	17	82.31	82.31	1128	2025-10-19 19:19:45.836382	80.46	[{"date": "2025-10-05", "score": 68.18}, {"date": "2025-10-15", "score": 73.94}, {"date": "2025-10-25", "score": 70.70}, {"date": "2025-11-04", "score": 78.06}]	[{"topic": "Multiple Choice", "accuracy": 88.01}, {"topic": "Note Completion", "accuracy": 69.89}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9056	f0000005-0000-0000-0000-000000000005	listening	35	3	82.31	98.77	891	2025-10-21 19:19:45.836382	58.54	[{"date": "2025-10-05", "score": 50.17}, {"date": "2025-10-15", "score": 57.13}, {"date": "2025-10-25", "score": 52.87}, {"date": "2025-11-04", "score": 68.10}]	[{"topic": "Multiple Choice", "accuracy": 79.43}, {"topic": "Note Completion", "accuracy": 65.70}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9057	f0000006-0000-0000-0000-000000000006	listening	35	17	82.31	91.55	918	2025-10-25 19:19:45.836382	62.97	[{"date": "2025-10-05", "score": 73.70}, {"date": "2025-10-15", "score": 74.64}, {"date": "2025-10-25", "score": 83.99}, {"date": "2025-11-04", "score": 80.20}]	[{"topic": "Multiple Choice", "accuracy": 84.94}, {"topic": "Note Completion", "accuracy": 85.28}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9058	f0000007-0000-0000-0000-000000000007	listening	35	5	82.31	82.31	263	2025-10-29 19:19:45.836382	64.19	[{"date": "2025-10-05", "score": 84.05}, {"date": "2025-10-15", "score": 59.61}, {"date": "2025-10-25", "score": 71.16}, {"date": "2025-11-04", "score": 82.20}]	[{"topic": "Multiple Choice", "accuracy": 82.62}, {"topic": "Note Completion", "accuracy": 70.54}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9059	f0000008-0000-0000-0000-000000000008	listening	35	15	82.31	99.96	172	2025-10-21 19:19:45.836382	51.82	[{"date": "2025-10-05", "score": 67.44}, {"date": "2025-10-15", "score": 65.09}, {"date": "2025-10-25", "score": 71.50}, {"date": "2025-11-04", "score": 85.11}]	[{"topic": "Multiple Choice", "accuracy": 77.56}, {"topic": "Note Completion", "accuracy": 88.27}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9060	f0000009-0000-0000-0000-000000000009	listening	35	35	82.31	97.21	1189	2025-10-30 19:19:45.836382	65.83	[{"date": "2025-10-05", "score": 67.05}, {"date": "2025-10-15", "score": 88.14}, {"date": "2025-10-25", "score": 76.84}, {"date": "2025-11-04", "score": 78.87}]	[{"topic": "Multiple Choice", "accuracy": 61.46}, {"topic": "Note Completion", "accuracy": 68.14}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9061	f0000010-0000-0000-0000-000000000010	listening	35	24	82.31	85.34	257	2025-11-03 19:19:45.836382	65.06	[{"date": "2025-10-05", "score": 82.74}, {"date": "2025-10-15", "score": 68.08}, {"date": "2025-10-25", "score": 74.60}, {"date": "2025-11-04", "score": 65.93}]	[{"topic": "Multiple Choice", "accuracy": 66.84}, {"topic": "Note Completion", "accuracy": 88.54}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9062	f0000011-0000-0000-0000-000000000011	listening	35	28	82.31	82.31	419	2025-10-25 19:19:45.836382	52.03	[{"date": "2025-10-05", "score": 74.85}, {"date": "2025-10-15", "score": 65.98}, {"date": "2025-10-25", "score": 75.45}, {"date": "2025-11-04", "score": 52.27}]	[{"topic": "Multiple Choice", "accuracy": 89.04}, {"topic": "Note Completion", "accuracy": 60.76}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9063	f0000012-0000-0000-0000-000000000012	listening	35	5	82.31	82.31	105	2025-10-16 19:19:45.836382	92.64	[{"date": "2025-10-05", "score": 64.98}, {"date": "2025-10-15", "score": 57.47}, {"date": "2025-10-25", "score": 62.68}, {"date": "2025-11-04", "score": 58.14}]	[{"topic": "Multiple Choice", "accuracy": 87.47}, {"topic": "Note Completion", "accuracy": 72.71}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9064	f0000013-0000-0000-0000-000000000013	listening	35	35	82.31	82.31	567	2025-10-30 19:19:45.836382	84.87	[{"date": "2025-10-05", "score": 50.63}, {"date": "2025-10-15", "score": 63.55}, {"date": "2025-10-25", "score": 74.02}, {"date": "2025-11-04", "score": 85.12}]	[{"topic": "Multiple Choice", "accuracy": 89.51}, {"topic": "Note Completion", "accuracy": 72.21}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9065	f0000014-0000-0000-0000-000000000014	listening	35	4	82.31	90.26	310	2025-10-21 19:19:45.836382	76.70	[{"date": "2025-10-05", "score": 52.31}, {"date": "2025-10-15", "score": 89.92}, {"date": "2025-10-25", "score": 77.50}, {"date": "2025-11-04", "score": 82.62}]	[{"topic": "Multiple Choice", "accuracy": 88.70}, {"topic": "Note Completion", "accuracy": 88.27}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9066	f0000015-0000-0000-0000-000000000015	listening	35	29	82.31	82.31	694	2025-10-23 19:19:45.836382	57.16	[{"date": "2025-10-05", "score": 68.84}, {"date": "2025-10-15", "score": 51.01}, {"date": "2025-10-25", "score": 76.37}, {"date": "2025-11-04", "score": 70.20}]	[{"topic": "Multiple Choice", "accuracy": 71.11}, {"topic": "Note Completion", "accuracy": 61.74}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9067	f0000016-0000-0000-0000-000000000016	listening	35	32	82.31	82.31	168	2025-10-29 19:19:45.836382	62.77	[{"date": "2025-10-05", "score": 64.50}, {"date": "2025-10-15", "score": 73.57}, {"date": "2025-10-25", "score": 76.84}, {"date": "2025-11-04", "score": 86.83}]	[{"topic": "Multiple Choice", "accuracy": 87.52}, {"topic": "Note Completion", "accuracy": 75.24}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9068	f0000017-0000-0000-0000-000000000017	listening	35	26	82.31	99.19	1122	2025-10-31 19:19:45.836382	52.02	[{"date": "2025-10-05", "score": 50.92}, {"date": "2025-10-15", "score": 67.92}, {"date": "2025-10-25", "score": 77.05}, {"date": "2025-11-04", "score": 83.79}]	[{"topic": "Multiple Choice", "accuracy": 65.08}, {"topic": "Note Completion", "accuracy": 84.73}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9069	f0000018-0000-0000-0000-000000000018	listening	35	16	82.31	95.21	222	2025-10-31 19:19:45.836382	56.44	[{"date": "2025-10-05", "score": 70.64}, {"date": "2025-10-15", "score": 69.23}, {"date": "2025-10-25", "score": 52.50}, {"date": "2025-11-04", "score": 82.31}]	[{"topic": "Multiple Choice", "accuracy": 69.53}, {"topic": "Note Completion", "accuracy": 61.95}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9070	f0000019-0000-0000-0000-000000000019	listening	35	27	82.31	97.85	947	2025-10-22 19:19:45.836382	71.07	[{"date": "2025-10-05", "score": 87.33}, {"date": "2025-10-15", "score": 83.00}, {"date": "2025-10-25", "score": 79.68}, {"date": "2025-11-04", "score": 64.91}]	[{"topic": "Multiple Choice", "accuracy": 76.45}, {"topic": "Note Completion", "accuracy": 83.63}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9071	f0000020-0000-0000-0000-000000000020	listening	35	35	82.31	85.47	975	2025-10-10 19:19:45.836382	61.57	[{"date": "2025-10-05", "score": 67.75}, {"date": "2025-10-15", "score": 83.40}, {"date": "2025-10-25", "score": 79.55}, {"date": "2025-11-04", "score": 84.89}]	[{"topic": "Multiple Choice", "accuracy": 87.11}, {"topic": "Note Completion", "accuracy": 74.39}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9072	f0000021-0000-0000-0000-000000000021	listening	35	11	82.31	82.31	593	2025-10-07 19:19:45.836382	80.52	[{"date": "2025-10-05", "score": 56.38}, {"date": "2025-10-15", "score": 56.86}, {"date": "2025-10-25", "score": 77.50}, {"date": "2025-11-04", "score": 50.68}]	[{"topic": "Multiple Choice", "accuracy": 81.07}, {"topic": "Note Completion", "accuracy": 80.90}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9073	f0000022-0000-0000-0000-000000000022	listening	35	18	82.31	82.31	144	2025-10-08 19:19:45.836382	86.27	[{"date": "2025-10-05", "score": 60.59}, {"date": "2025-10-15", "score": 78.76}, {"date": "2025-10-25", "score": 56.81}, {"date": "2025-11-04", "score": 73.74}]	[{"topic": "Multiple Choice", "accuracy": 88.20}, {"topic": "Note Completion", "accuracy": 78.86}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9074	f0000023-0000-0000-0000-000000000023	listening	35	35	82.31	82.31	209	2025-10-13 19:19:45.836382	67.93	[{"date": "2025-10-05", "score": 67.47}, {"date": "2025-10-15", "score": 88.58}, {"date": "2025-10-25", "score": 59.48}, {"date": "2025-11-04", "score": 53.01}]	[{"topic": "Multiple Choice", "accuracy": 86.05}, {"topic": "Note Completion", "accuracy": 65.47}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9075	f0000024-0000-0000-0000-000000000024	listening	35	33	82.31	82.31	1218	2025-10-25 19:19:45.836382	59.74	[{"date": "2025-10-05", "score": 68.77}, {"date": "2025-10-15", "score": 71.85}, {"date": "2025-10-25", "score": 88.12}, {"date": "2025-11-04", "score": 65.91}]	[{"topic": "Multiple Choice", "accuracy": 76.25}, {"topic": "Note Completion", "accuracy": 79.71}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9076	f0000025-0000-0000-0000-000000000025	listening	35	35	82.31	91.98	84	2025-10-20 19:19:45.836382	62.28	[{"date": "2025-10-05", "score": 89.61}, {"date": "2025-10-15", "score": 75.05}, {"date": "2025-10-25", "score": 51.08}, {"date": "2025-11-04", "score": 54.82}]	[{"topic": "Multiple Choice", "accuracy": 87.25}, {"topic": "Note Completion", "accuracy": 65.56}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9077	f0000026-0000-0000-0000-000000000026	listening	35	23	82.31	99.35	1157	2025-10-15 19:19:45.836382	69.11	[{"date": "2025-10-05", "score": 73.61}, {"date": "2025-10-15", "score": 80.77}, {"date": "2025-10-25", "score": 84.59}, {"date": "2025-11-04", "score": 65.04}]	[{"topic": "Multiple Choice", "accuracy": 60.24}, {"topic": "Note Completion", "accuracy": 71.26}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9078	f0000027-0000-0000-0000-000000000027	listening	35	35	82.31	94.00	609	2025-10-18 19:19:45.836382	70.72	[{"date": "2025-10-05", "score": 81.42}, {"date": "2025-10-15", "score": 81.60}, {"date": "2025-10-25", "score": 83.21}, {"date": "2025-11-04", "score": 60.90}]	[{"topic": "Multiple Choice", "accuracy": 61.13}, {"topic": "Note Completion", "accuracy": 79.85}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9079	f0000028-0000-0000-0000-000000000028	listening	35	18	82.31	82.31	591	2025-10-09 19:19:45.836382	85.04	[{"date": "2025-10-05", "score": 79.21}, {"date": "2025-10-15", "score": 65.83}, {"date": "2025-10-25", "score": 87.14}, {"date": "2025-11-04", "score": 65.49}]	[{"topic": "Multiple Choice", "accuracy": 67.87}, {"topic": "Note Completion", "accuracy": 87.01}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9080	f0000029-0000-0000-0000-000000000029	listening	35	21	82.31	82.31	871	2025-10-15 19:19:45.836382	63.81	[{"date": "2025-10-05", "score": 54.76}, {"date": "2025-10-15", "score": 86.61}, {"date": "2025-10-25", "score": 60.13}, {"date": "2025-11-04", "score": 80.17}]	[{"topic": "Multiple Choice", "accuracy": 74.95}, {"topic": "Note Completion", "accuracy": 63.43}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9081	f0000030-0000-0000-0000-000000000030	listening	35	6	82.31	96.81	613	2025-10-29 19:19:45.836382	55.43	[{"date": "2025-10-05", "score": 72.56}, {"date": "2025-10-15", "score": 56.56}, {"date": "2025-10-25", "score": 87.32}, {"date": "2025-11-04", "score": 53.97}]	[{"topic": "Multiple Choice", "accuracy": 80.16}, {"topic": "Note Completion", "accuracy": 83.86}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9082	f0000031-0000-0000-0000-000000000031	listening	35	12	82.31	82.31	1087	2025-10-11 19:19:45.836382	72.65	[{"date": "2025-10-05", "score": 72.02}, {"date": "2025-10-15", "score": 73.64}, {"date": "2025-10-25", "score": 80.99}, {"date": "2025-11-04", "score": 76.77}]	[{"topic": "Multiple Choice", "accuracy": 82.55}, {"topic": "Note Completion", "accuracy": 66.28}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9083	f0000032-0000-0000-0000-000000000032	listening	35	34	82.31	97.21	758	2025-10-30 19:19:45.836382	54.44	[{"date": "2025-10-05", "score": 70.49}, {"date": "2025-10-15", "score": 55.47}, {"date": "2025-10-25", "score": 70.32}, {"date": "2025-11-04", "score": 78.83}]	[{"topic": "Multiple Choice", "accuracy": 77.48}, {"topic": "Note Completion", "accuracy": 60.16}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9084	f0000033-0000-0000-0000-000000000033	listening	35	35	82.31	82.31	646	2025-10-07 19:19:45.836382	69.68	[{"date": "2025-10-05", "score": 57.15}, {"date": "2025-10-15", "score": 83.40}, {"date": "2025-10-25", "score": 70.58}, {"date": "2025-11-04", "score": 70.88}]	[{"topic": "Multiple Choice", "accuracy": 76.63}, {"topic": "Note Completion", "accuracy": 77.65}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9085	f0000034-0000-0000-0000-000000000034	listening	35	35	82.31	96.35	116	2025-10-28 19:19:45.836382	79.22	[{"date": "2025-10-05", "score": 65.66}, {"date": "2025-10-15", "score": 84.36}, {"date": "2025-10-25", "score": 62.38}, {"date": "2025-11-04", "score": 57.77}]	[{"topic": "Multiple Choice", "accuracy": 83.00}, {"topic": "Note Completion", "accuracy": 79.54}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9086	f0000035-0000-0000-0000-000000000035	listening	35	9	82.31	94.82	972	2025-10-17 19:19:45.836382	95.94	[{"date": "2025-10-05", "score": 84.90}, {"date": "2025-10-15", "score": 81.29}, {"date": "2025-10-25", "score": 56.98}, {"date": "2025-11-04", "score": 63.04}]	[{"topic": "Multiple Choice", "accuracy": 85.56}, {"topic": "Note Completion", "accuracy": 85.02}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9087	f0000036-0000-0000-0000-000000000036	listening	35	28	82.31	86.86	1215	2025-10-09 19:19:45.836382	64.15	[{"date": "2025-10-05", "score": 71.90}, {"date": "2025-10-15", "score": 76.44}, {"date": "2025-10-25", "score": 85.65}, {"date": "2025-11-04", "score": 58.90}]	[{"topic": "Multiple Choice", "accuracy": 80.00}, {"topic": "Note Completion", "accuracy": 80.13}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9088	f0000037-0000-0000-0000-000000000037	listening	35	35	82.31	82.31	1050	2025-10-16 19:19:45.836382	78.69	[{"date": "2025-10-05", "score": 59.87}, {"date": "2025-10-15", "score": 50.70}, {"date": "2025-10-25", "score": 83.90}, {"date": "2025-11-04", "score": 82.45}]	[{"topic": "Multiple Choice", "accuracy": 89.64}, {"topic": "Note Completion", "accuracy": 85.83}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9089	f0000038-0000-0000-0000-000000000038	listening	35	35	82.31	82.31	224	2025-10-11 19:19:45.836382	84.97	[{"date": "2025-10-05", "score": 71.78}, {"date": "2025-10-15", "score": 88.69}, {"date": "2025-10-25", "score": 54.30}, {"date": "2025-11-04", "score": 85.23}]	[{"topic": "Multiple Choice", "accuracy": 73.23}, {"topic": "Note Completion", "accuracy": 67.28}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9090	f0000039-0000-0000-0000-000000000039	listening	35	12	82.31	96.01	623	2025-10-13 19:19:45.836382	76.41	[{"date": "2025-10-05", "score": 50.69}, {"date": "2025-10-15", "score": 70.52}, {"date": "2025-10-25", "score": 79.56}, {"date": "2025-11-04", "score": 54.40}]	[{"topic": "Multiple Choice", "accuracy": 62.68}, {"topic": "Note Completion", "accuracy": 62.57}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9091	f0000040-0000-0000-0000-000000000040	listening	35	14	82.31	87.71	291	2025-10-10 19:19:45.836382	50.30	[{"date": "2025-10-05", "score": 72.10}, {"date": "2025-10-15", "score": 89.08}, {"date": "2025-10-25", "score": 79.92}, {"date": "2025-11-04", "score": 52.21}]	[{"topic": "Multiple Choice", "accuracy": 85.51}, {"topic": "Note Completion", "accuracy": 89.16}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9092	f0000041-0000-0000-0000-000000000041	listening	35	35	82.31	82.31	976	2025-10-05 19:19:45.836382	83.92	[{"date": "2025-10-05", "score": 80.06}, {"date": "2025-10-15", "score": 61.04}, {"date": "2025-10-25", "score": 75.04}, {"date": "2025-11-04", "score": 78.00}]	[{"topic": "Multiple Choice", "accuracy": 78.20}, {"topic": "Note Completion", "accuracy": 65.28}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9093	f0000042-0000-0000-0000-000000000042	listening	35	31	82.31	90.48	517	2025-10-06 19:19:45.836382	90.07	[{"date": "2025-10-05", "score": 79.55}, {"date": "2025-10-15", "score": 55.24}, {"date": "2025-10-25", "score": 88.05}, {"date": "2025-11-04", "score": 65.04}]	[{"topic": "Multiple Choice", "accuracy": 61.82}, {"topic": "Note Completion", "accuracy": 70.32}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9094	f0000043-0000-0000-0000-000000000043	listening	35	35	82.31	99.05	106	2025-11-03 19:19:45.836382	73.05	[{"date": "2025-10-05", "score": 80.20}, {"date": "2025-10-15", "score": 63.34}, {"date": "2025-10-25", "score": 52.41}, {"date": "2025-11-04", "score": 68.59}]	[{"topic": "Multiple Choice", "accuracy": 79.81}, {"topic": "Note Completion", "accuracy": 69.45}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9095	f0000044-0000-0000-0000-000000000044	listening	35	22	82.31	87.22	697	2025-10-27 19:19:45.836382	55.67	[{"date": "2025-10-05", "score": 58.96}, {"date": "2025-10-15", "score": 84.25}, {"date": "2025-10-25", "score": 67.93}, {"date": "2025-11-04", "score": 65.63}]	[{"topic": "Multiple Choice", "accuracy": 89.08}, {"topic": "Note Completion", "accuracy": 71.36}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9096	f0000045-0000-0000-0000-000000000045	listening	35	35	82.31	95.15	1107	2025-10-14 19:19:45.836382	57.33	[{"date": "2025-10-05", "score": 58.14}, {"date": "2025-10-15", "score": 69.62}, {"date": "2025-10-25", "score": 66.91}, {"date": "2025-11-04", "score": 64.29}]	[{"topic": "Multiple Choice", "accuracy": 67.87}, {"topic": "Note Completion", "accuracy": 74.67}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9097	f0000046-0000-0000-0000-000000000046	listening	35	17	82.31	96.03	279	2025-10-06 19:19:45.836382	76.71	[{"date": "2025-10-05", "score": 89.29}, {"date": "2025-10-15", "score": 75.19}, {"date": "2025-10-25", "score": 68.00}, {"date": "2025-11-04", "score": 59.68}]	[{"topic": "Multiple Choice", "accuracy": 63.42}, {"topic": "Note Completion", "accuracy": 87.31}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9098	f0000047-0000-0000-0000-000000000047	listening	35	35	82.31	82.31	131	2025-10-30 19:19:45.836382	80.93	[{"date": "2025-10-05", "score": 62.24}, {"date": "2025-10-15", "score": 77.41}, {"date": "2025-10-25", "score": 67.23}, {"date": "2025-11-04", "score": 81.65}]	[{"topic": "Multiple Choice", "accuracy": 77.40}, {"topic": "Note Completion", "accuracy": 85.87}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9099	f0000048-0000-0000-0000-000000000048	listening	35	35	82.31	98.22	494	2025-11-02 19:19:45.836382	87.56	[{"date": "2025-10-05", "score": 83.00}, {"date": "2025-10-15", "score": 72.72}, {"date": "2025-10-25", "score": 85.15}, {"date": "2025-11-04", "score": 52.10}]	[{"topic": "Multiple Choice", "accuracy": 78.09}, {"topic": "Note Completion", "accuracy": 86.34}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9100	f0000049-0000-0000-0000-000000000049	listening	35	35	82.31	82.31	1191	2025-10-11 19:19:45.836382	58.51	[{"date": "2025-10-05", "score": 63.02}, {"date": "2025-10-15", "score": 85.15}, {"date": "2025-10-25", "score": 62.70}, {"date": "2025-11-04", "score": 67.58}]	[{"topic": "Multiple Choice", "accuracy": 77.23}, {"topic": "Note Completion", "accuracy": 72.78}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9101	f0000050-0000-0000-0000-000000000050	listening	35	8	82.31	83.59	665	2025-10-23 19:19:45.836382	72.15	[{"date": "2025-10-05", "score": 87.24}, {"date": "2025-10-15", "score": 77.90}, {"date": "2025-10-25", "score": 71.47}, {"date": "2025-11-04", "score": 68.28}]	[{"topic": "Multiple Choice", "accuracy": 74.47}, {"topic": "Note Completion", "accuracy": 71.13}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9102	f0000051-0000-0000-0000-000000000051	listening	35	33	82.31	82.31	761	2025-10-27 19:19:45.836382	71.84	[{"date": "2025-10-05", "score": 81.74}, {"date": "2025-10-15", "score": 86.40}, {"date": "2025-10-25", "score": 88.99}, {"date": "2025-11-04", "score": 80.62}]	[{"topic": "Multiple Choice", "accuracy": 86.75}, {"topic": "Note Completion", "accuracy": 85.65}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9103	f0000052-0000-0000-0000-000000000052	listening	35	31	82.31	82.31	362	2025-10-22 19:19:45.836382	69.84	[{"date": "2025-10-05", "score": 78.15}, {"date": "2025-10-15", "score": 65.86}, {"date": "2025-10-25", "score": 74.29}, {"date": "2025-11-04", "score": 88.53}]	[{"topic": "Multiple Choice", "accuracy": 64.01}, {"topic": "Note Completion", "accuracy": 82.43}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9104	f0000053-0000-0000-0000-000000000053	listening	35	35	82.31	82.31	745	2025-10-18 19:19:45.836382	72.19	[{"date": "2025-10-05", "score": 89.01}, {"date": "2025-10-15", "score": 75.06}, {"date": "2025-10-25", "score": 72.27}, {"date": "2025-11-04", "score": 69.83}]	[{"topic": "Multiple Choice", "accuracy": 78.05}, {"topic": "Note Completion", "accuracy": 69.53}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9105	f0000054-0000-0000-0000-000000000054	listening	35	20	82.31	82.31	894	2025-10-30 19:19:45.836382	88.49	[{"date": "2025-10-05", "score": 82.87}, {"date": "2025-10-15", "score": 55.09}, {"date": "2025-10-25", "score": 81.95}, {"date": "2025-11-04", "score": 74.13}]	[{"topic": "Multiple Choice", "accuracy": 88.11}, {"topic": "Note Completion", "accuracy": 75.62}]	2025-11-04 19:19:45.836382	2025-11-04 19:19:45.836382
9106	a0000001-0000-0000-0000-000000000001	reading	52	11	89.98	89.98	1092	2025-11-02 19:19:45.83964	94.31	[{"date": "2025-10-05", "score": 62.62}, {"date": "2025-10-15", "score": 84.96}, {"date": "2025-10-25", "score": 58.92}, {"date": "2025-11-04", "score": 53.25}]	[{"topic": "True/False/Not Given", "accuracy": 87.29}, {"topic": "Matching Headings", "accuracy": 65.68}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9107	a0000002-0000-0000-0000-000000000002	reading	52	37	89.98	89.98	387	2025-10-06 19:19:45.83964	83.35	[{"date": "2025-10-05", "score": 79.06}, {"date": "2025-10-15", "score": 63.03}, {"date": "2025-10-25", "score": 76.29}, {"date": "2025-11-04", "score": 76.18}]	[{"topic": "True/False/Not Given", "accuracy": 88.60}, {"topic": "Matching Headings", "accuracy": 87.38}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9108	b0000001-0000-0000-0000-000000000001	reading	52	28	89.98	89.98	1461	2025-10-24 19:19:45.83964	53.90	[{"date": "2025-10-05", "score": 86.23}, {"date": "2025-10-15", "score": 80.35}, {"date": "2025-10-25", "score": 67.24}, {"date": "2025-11-04", "score": 78.86}]	[{"topic": "True/False/Not Given", "accuracy": 87.68}, {"topic": "Matching Headings", "accuracy": 89.82}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9109	b0000002-0000-0000-0000-000000000002	reading	52	6	89.98	89.98	456	2025-10-11 19:19:45.83964	60.47	[{"date": "2025-10-05", "score": 53.34}, {"date": "2025-10-15", "score": 50.46}, {"date": "2025-10-25", "score": 66.27}, {"date": "2025-11-04", "score": 53.57}]	[{"topic": "True/False/Not Given", "accuracy": 60.15}, {"topic": "Matching Headings", "accuracy": 78.76}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9110	b0000003-0000-0000-0000-000000000003	reading	52	22	89.98	89.98	523	2025-10-06 19:19:45.83964	56.44	[{"date": "2025-10-05", "score": 61.94}, {"date": "2025-10-15", "score": 59.88}, {"date": "2025-10-25", "score": 76.09}, {"date": "2025-11-04", "score": 55.15}]	[{"topic": "True/False/Not Given", "accuracy": 75.33}, {"topic": "Matching Headings", "accuracy": 80.01}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9111	b0000004-0000-0000-0000-000000000004	reading	52	13	89.98	89.98	578	2025-10-12 19:19:45.83964	82.50	[{"date": "2025-10-05", "score": 81.11}, {"date": "2025-10-15", "score": 71.98}, {"date": "2025-10-25", "score": 56.82}, {"date": "2025-11-04", "score": 88.83}]	[{"topic": "True/False/Not Given", "accuracy": 80.96}, {"topic": "Matching Headings", "accuracy": 88.21}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9112	f0000001-0000-0000-0000-000000000001	reading	52	8	89.98	89.98	899	2025-11-02 19:19:45.83964	56.24	[{"date": "2025-10-05", "score": 88.13}, {"date": "2025-10-15", "score": 68.05}, {"date": "2025-10-25", "score": 73.83}, {"date": "2025-11-04", "score": 79.40}]	[{"topic": "True/False/Not Given", "accuracy": 69.57}, {"topic": "Matching Headings", "accuracy": 63.70}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9113	f0000002-0000-0000-0000-000000000002	reading	52	22	89.98	89.98	1399	2025-10-23 19:19:45.83964	81.81	[{"date": "2025-10-05", "score": 77.46}, {"date": "2025-10-15", "score": 61.23}, {"date": "2025-10-25", "score": 86.77}, {"date": "2025-11-04", "score": 77.56}]	[{"topic": "True/False/Not Given", "accuracy": 71.84}, {"topic": "Matching Headings", "accuracy": 63.32}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9114	f0000003-0000-0000-0000-000000000003	reading	52	21	89.98	89.98	833	2025-11-03 19:19:45.83964	80.98	[{"date": "2025-10-05", "score": 70.82}, {"date": "2025-10-15", "score": 63.68}, {"date": "2025-10-25", "score": 68.47}, {"date": "2025-11-04", "score": 58.39}]	[{"topic": "True/False/Not Given", "accuracy": 79.16}, {"topic": "Matching Headings", "accuracy": 70.15}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9115	f0000004-0000-0000-0000-000000000004	reading	52	14	89.98	89.98	591	2025-10-13 19:19:45.83964	66.09	[{"date": "2025-10-05", "score": 80.42}, {"date": "2025-10-15", "score": 72.77}, {"date": "2025-10-25", "score": 68.01}, {"date": "2025-11-04", "score": 73.39}]	[{"topic": "True/False/Not Given", "accuracy": 75.80}, {"topic": "Matching Headings", "accuracy": 84.89}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9116	f0000005-0000-0000-0000-000000000005	reading	52	11	89.98	89.98	1140	2025-10-11 19:19:45.83964	72.15	[{"date": "2025-10-05", "score": 57.57}, {"date": "2025-10-15", "score": 75.57}, {"date": "2025-10-25", "score": 69.90}, {"date": "2025-11-04", "score": 78.47}]	[{"topic": "True/False/Not Given", "accuracy": 60.34}, {"topic": "Matching Headings", "accuracy": 74.59}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9117	f0000006-0000-0000-0000-000000000006	reading	52	9	89.98	89.98	1116	2025-11-03 19:19:45.83964	85.59	[{"date": "2025-10-05", "score": 50.51}, {"date": "2025-10-15", "score": 55.57}, {"date": "2025-10-25", "score": 88.16}, {"date": "2025-11-04", "score": 67.71}]	[{"topic": "True/False/Not Given", "accuracy": 81.21}, {"topic": "Matching Headings", "accuracy": 75.82}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9118	f0000007-0000-0000-0000-000000000007	reading	52	39	89.98	95.94	141	2025-10-08 19:19:45.83964	66.48	[{"date": "2025-10-05", "score": 89.66}, {"date": "2025-10-15", "score": 70.08}, {"date": "2025-10-25", "score": 86.97}, {"date": "2025-11-04", "score": 61.97}]	[{"topic": "True/False/Not Given", "accuracy": 74.01}, {"topic": "Matching Headings", "accuracy": 79.87}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9119	f0000008-0000-0000-0000-000000000008	reading	52	30	89.98	95.82	1502	2025-10-15 19:19:45.83964	51.53	[{"date": "2025-10-05", "score": 77.08}, {"date": "2025-10-15", "score": 89.51}, {"date": "2025-10-25", "score": 89.88}, {"date": "2025-11-04", "score": 79.42}]	[{"topic": "True/False/Not Given", "accuracy": 70.18}, {"topic": "Matching Headings", "accuracy": 70.01}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9120	f0000009-0000-0000-0000-000000000009	reading	52	29	89.98	90.41	123	2025-10-07 19:19:45.83964	82.29	[{"date": "2025-10-05", "score": 59.53}, {"date": "2025-10-15", "score": 83.17}, {"date": "2025-10-25", "score": 84.90}, {"date": "2025-11-04", "score": 76.43}]	[{"topic": "True/False/Not Given", "accuracy": 78.30}, {"topic": "Matching Headings", "accuracy": 85.83}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9121	f0000010-0000-0000-0000-000000000010	reading	52	29	89.98	89.98	626	2025-10-16 19:19:45.83964	90.91	[{"date": "2025-10-05", "score": 83.16}, {"date": "2025-10-15", "score": 56.19}, {"date": "2025-10-25", "score": 88.40}, {"date": "2025-11-04", "score": 71.27}]	[{"topic": "True/False/Not Given", "accuracy": 74.07}, {"topic": "Matching Headings", "accuracy": 80.31}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9122	f0000011-0000-0000-0000-000000000011	reading	52	8	89.98	89.98	1276	2025-10-14 19:19:45.83964	88.62	[{"date": "2025-10-05", "score": 62.63}, {"date": "2025-10-15", "score": 70.80}, {"date": "2025-10-25", "score": 60.57}, {"date": "2025-11-04", "score": 80.02}]	[{"topic": "True/False/Not Given", "accuracy": 61.21}, {"topic": "Matching Headings", "accuracy": 86.99}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9123	f0000012-0000-0000-0000-000000000012	reading	52	30	89.98	89.98	1510	2025-10-28 19:19:45.83964	72.89	[{"date": "2025-10-05", "score": 51.68}, {"date": "2025-10-15", "score": 51.35}, {"date": "2025-10-25", "score": 57.43}, {"date": "2025-11-04", "score": 82.42}]	[{"topic": "True/False/Not Given", "accuracy": 79.96}, {"topic": "Matching Headings", "accuracy": 65.93}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9124	f0000013-0000-0000-0000-000000000013	reading	52	11	89.98	89.98	676	2025-10-25 19:19:45.83964	96.59	[{"date": "2025-10-05", "score": 88.71}, {"date": "2025-10-15", "score": 67.85}, {"date": "2025-10-25", "score": 88.49}, {"date": "2025-11-04", "score": 85.50}]	[{"topic": "True/False/Not Given", "accuracy": 82.30}, {"topic": "Matching Headings", "accuracy": 61.69}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9125	f0000014-0000-0000-0000-000000000014	reading	52	33	89.98	89.98	675	2025-10-09 19:19:45.83964	52.56	[{"date": "2025-10-05", "score": 85.32}, {"date": "2025-10-15", "score": 56.87}, {"date": "2025-10-25", "score": 76.20}, {"date": "2025-11-04", "score": 52.93}]	[{"topic": "True/False/Not Given", "accuracy": 74.38}, {"topic": "Matching Headings", "accuracy": 71.54}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9126	f0000015-0000-0000-0000-000000000015	reading	52	36	89.98	89.98	1367	2025-10-23 19:19:45.83964	54.91	[{"date": "2025-10-05", "score": 60.07}, {"date": "2025-10-15", "score": 67.89}, {"date": "2025-10-25", "score": 72.52}, {"date": "2025-11-04", "score": 87.34}]	[{"topic": "True/False/Not Given", "accuracy": 83.40}, {"topic": "Matching Headings", "accuracy": 81.46}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9127	f0000016-0000-0000-0000-000000000016	reading	52	45	89.98	93.52	1345	2025-10-05 19:19:45.83964	78.75	[{"date": "2025-10-05", "score": 65.48}, {"date": "2025-10-15", "score": 59.07}, {"date": "2025-10-25", "score": 62.74}, {"date": "2025-11-04", "score": 74.37}]	[{"topic": "True/False/Not Given", "accuracy": 82.43}, {"topic": "Matching Headings", "accuracy": 63.87}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9128	f0000017-0000-0000-0000-000000000017	reading	52	21	89.98	94.12	1580	2025-10-13 19:19:45.83964	61.34	[{"date": "2025-10-05", "score": 83.54}, {"date": "2025-10-15", "score": 71.47}, {"date": "2025-10-25", "score": 54.84}, {"date": "2025-11-04", "score": 84.71}]	[{"topic": "True/False/Not Given", "accuracy": 73.02}, {"topic": "Matching Headings", "accuracy": 84.44}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9129	f0000018-0000-0000-0000-000000000018	reading	52	6	89.98	89.98	943	2025-10-25 19:19:45.83964	73.66	[{"date": "2025-10-05", "score": 65.73}, {"date": "2025-10-15", "score": 73.79}, {"date": "2025-10-25", "score": 57.13}, {"date": "2025-11-04", "score": 88.86}]	[{"topic": "True/False/Not Given", "accuracy": 84.50}, {"topic": "Matching Headings", "accuracy": 87.29}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9130	f0000019-0000-0000-0000-000000000019	reading	52	46	89.98	89.98	405	2025-11-02 19:19:45.83964	63.28	[{"date": "2025-10-05", "score": 53.35}, {"date": "2025-10-15", "score": 75.60}, {"date": "2025-10-25", "score": 87.01}, {"date": "2025-11-04", "score": 67.09}]	[{"topic": "True/False/Not Given", "accuracy": 86.74}, {"topic": "Matching Headings", "accuracy": 83.65}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9131	f0000020-0000-0000-0000-000000000020	reading	52	17	89.98	89.98	911	2025-10-29 19:19:45.83964	64.31	[{"date": "2025-10-05", "score": 74.17}, {"date": "2025-10-15", "score": 64.92}, {"date": "2025-10-25", "score": 89.91}, {"date": "2025-11-04", "score": 75.72}]	[{"topic": "True/False/Not Given", "accuracy": 69.70}, {"topic": "Matching Headings", "accuracy": 60.69}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9132	f0000021-0000-0000-0000-000000000021	reading	52	9	89.98	89.98	128	2025-10-27 19:19:45.83964	79.88	[{"date": "2025-10-05", "score": 89.98}, {"date": "2025-10-15", "score": 57.79}, {"date": "2025-10-25", "score": 58.56}, {"date": "2025-11-04", "score": 67.69}]	[{"topic": "True/False/Not Given", "accuracy": 82.91}, {"topic": "Matching Headings", "accuracy": 67.69}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9133	f0000022-0000-0000-0000-000000000022	reading	52	22	89.98	89.98	548	2025-10-20 19:19:45.83964	88.24	[{"date": "2025-10-05", "score": 70.26}, {"date": "2025-10-15", "score": 77.93}, {"date": "2025-10-25", "score": 77.73}, {"date": "2025-11-04", "score": 85.38}]	[{"topic": "True/False/Not Given", "accuracy": 65.92}, {"topic": "Matching Headings", "accuracy": 60.86}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9134	f0000023-0000-0000-0000-000000000023	reading	52	18	89.98	89.98	448	2025-10-23 19:19:45.83964	56.77	[{"date": "2025-10-05", "score": 79.95}, {"date": "2025-10-15", "score": 64.64}, {"date": "2025-10-25", "score": 74.20}, {"date": "2025-11-04", "score": 76.73}]	[{"topic": "True/False/Not Given", "accuracy": 81.47}, {"topic": "Matching Headings", "accuracy": 87.47}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9135	f0000024-0000-0000-0000-000000000024	reading	52	5	89.98	89.98	699	2025-10-20 19:19:45.83964	91.57	[{"date": "2025-10-05", "score": 86.39}, {"date": "2025-10-15", "score": 70.62}, {"date": "2025-10-25", "score": 56.13}, {"date": "2025-11-04", "score": 82.70}]	[{"topic": "True/False/Not Given", "accuracy": 78.60}, {"topic": "Matching Headings", "accuracy": 76.20}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9136	f0000025-0000-0000-0000-000000000025	reading	52	17	89.98	89.98	361	2025-10-09 19:19:45.83964	92.28	[{"date": "2025-10-05", "score": 82.21}, {"date": "2025-10-15", "score": 75.08}, {"date": "2025-10-25", "score": 65.89}, {"date": "2025-11-04", "score": 79.12}]	[{"topic": "True/False/Not Given", "accuracy": 84.11}, {"topic": "Matching Headings", "accuracy": 80.51}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9137	f0000026-0000-0000-0000-000000000026	reading	52	48	89.98	89.98	1326	2025-10-06 19:19:45.83964	83.01	[{"date": "2025-10-05", "score": 77.88}, {"date": "2025-10-15", "score": 60.00}, {"date": "2025-10-25", "score": 51.17}, {"date": "2025-11-04", "score": 89.03}]	[{"topic": "True/False/Not Given", "accuracy": 64.34}, {"topic": "Matching Headings", "accuracy": 72.86}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9138	f0000027-0000-0000-0000-000000000027	reading	52	28	89.98	89.98	976	2025-10-31 19:19:45.83964	68.72	[{"date": "2025-10-05", "score": 62.88}, {"date": "2025-10-15", "score": 89.72}, {"date": "2025-10-25", "score": 50.48}, {"date": "2025-11-04", "score": 52.35}]	[{"topic": "True/False/Not Given", "accuracy": 67.23}, {"topic": "Matching Headings", "accuracy": 65.03}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9139	f0000028-0000-0000-0000-000000000028	reading	52	15	89.98	89.98	790	2025-10-26 19:19:45.83964	58.66	[{"date": "2025-10-05", "score": 73.23}, {"date": "2025-10-15", "score": 53.17}, {"date": "2025-10-25", "score": 56.01}, {"date": "2025-11-04", "score": 54.98}]	[{"topic": "True/False/Not Given", "accuracy": 88.33}, {"topic": "Matching Headings", "accuracy": 71.47}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9140	f0000029-0000-0000-0000-000000000029	reading	52	12	89.98	89.98	779	2025-10-19 19:19:45.83964	96.19	[{"date": "2025-10-05", "score": 70.37}, {"date": "2025-10-15", "score": 55.49}, {"date": "2025-10-25", "score": 75.70}, {"date": "2025-11-04", "score": 84.03}]	[{"topic": "True/False/Not Given", "accuracy": 63.44}, {"topic": "Matching Headings", "accuracy": 73.75}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9141	f0000030-0000-0000-0000-000000000030	reading	52	26	89.98	92.68	1405	2025-11-03 19:19:45.83964	67.43	[{"date": "2025-10-05", "score": 85.89}, {"date": "2025-10-15", "score": 50.08}, {"date": "2025-10-25", "score": 81.97}, {"date": "2025-11-04", "score": 64.75}]	[{"topic": "True/False/Not Given", "accuracy": 76.34}, {"topic": "Matching Headings", "accuracy": 60.86}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9142	f0000031-0000-0000-0000-000000000031	reading	52	29	89.98	91.86	1588	2025-10-21 19:19:45.83964	93.50	[{"date": "2025-10-05", "score": 69.70}, {"date": "2025-10-15", "score": 56.42}, {"date": "2025-10-25", "score": 63.72}, {"date": "2025-11-04", "score": 88.89}]	[{"topic": "True/False/Not Given", "accuracy": 67.81}, {"topic": "Matching Headings", "accuracy": 72.17}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9143	f0000032-0000-0000-0000-000000000032	reading	52	4	89.98	94.22	256	2025-10-11 19:19:45.83964	55.21	[{"date": "2025-10-05", "score": 72.38}, {"date": "2025-10-15", "score": 63.32}, {"date": "2025-10-25", "score": 69.52}, {"date": "2025-11-04", "score": 70.89}]	[{"topic": "True/False/Not Given", "accuracy": 76.33}, {"topic": "Matching Headings", "accuracy": 64.49}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9144	f0000033-0000-0000-0000-000000000033	reading	52	28	89.98	90.18	238	2025-10-22 19:19:45.83964	56.36	[{"date": "2025-10-05", "score": 85.81}, {"date": "2025-10-15", "score": 86.10}, {"date": "2025-10-25", "score": 52.59}, {"date": "2025-11-04", "score": 88.32}]	[{"topic": "True/False/Not Given", "accuracy": 60.46}, {"topic": "Matching Headings", "accuracy": 67.46}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9145	f0000034-0000-0000-0000-000000000034	reading	52	5	89.98	90.77	420	2025-10-25 19:19:45.83964	93.50	[{"date": "2025-10-05", "score": 71.94}, {"date": "2025-10-15", "score": 64.54}, {"date": "2025-10-25", "score": 84.53}, {"date": "2025-11-04", "score": 52.25}]	[{"topic": "True/False/Not Given", "accuracy": 82.81}, {"topic": "Matching Headings", "accuracy": 61.13}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9146	f0000035-0000-0000-0000-000000000035	reading	52	13	89.98	97.94	567	2025-10-27 19:19:45.83964	83.99	[{"date": "2025-10-05", "score": 83.25}, {"date": "2025-10-15", "score": 79.59}, {"date": "2025-10-25", "score": 80.35}, {"date": "2025-11-04", "score": 51.62}]	[{"topic": "True/False/Not Given", "accuracy": 67.93}, {"topic": "Matching Headings", "accuracy": 89.51}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9147	f0000036-0000-0000-0000-000000000036	reading	52	39	89.98	89.98	282	2025-11-02 19:19:45.83964	96.91	[{"date": "2025-10-05", "score": 58.88}, {"date": "2025-10-15", "score": 54.69}, {"date": "2025-10-25", "score": 81.20}, {"date": "2025-11-04", "score": 89.58}]	[{"topic": "True/False/Not Given", "accuracy": 89.46}, {"topic": "Matching Headings", "accuracy": 88.67}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9148	f0000037-0000-0000-0000-000000000037	reading	52	7	89.98	89.98	487	2025-10-23 19:19:45.83964	80.76	[{"date": "2025-10-05", "score": 55.36}, {"date": "2025-10-15", "score": 76.33}, {"date": "2025-10-25", "score": 78.82}, {"date": "2025-11-04", "score": 61.16}]	[{"topic": "True/False/Not Given", "accuracy": 70.75}, {"topic": "Matching Headings", "accuracy": 66.08}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9149	f0000038-0000-0000-0000-000000000038	reading	52	48	89.98	89.98	330	2025-10-20 19:19:45.83964	98.39	[{"date": "2025-10-05", "score": 63.51}, {"date": "2025-10-15", "score": 63.18}, {"date": "2025-10-25", "score": 87.43}, {"date": "2025-11-04", "score": 84.31}]	[{"topic": "True/False/Not Given", "accuracy": 73.61}, {"topic": "Matching Headings", "accuracy": 67.22}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9150	f0000039-0000-0000-0000-000000000039	reading	52	38	89.98	89.98	1061	2025-10-11 19:19:45.83964	70.98	[{"date": "2025-10-05", "score": 70.34}, {"date": "2025-10-15", "score": 87.13}, {"date": "2025-10-25", "score": 69.73}, {"date": "2025-11-04", "score": 78.25}]	[{"topic": "True/False/Not Given", "accuracy": 85.04}, {"topic": "Matching Headings", "accuracy": 68.84}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9151	f0000040-0000-0000-0000-000000000040	reading	52	44	89.98	91.25	888	2025-10-12 19:19:45.83964	52.05	[{"date": "2025-10-05", "score": 67.16}, {"date": "2025-10-15", "score": 52.35}, {"date": "2025-10-25", "score": 68.12}, {"date": "2025-11-04", "score": 71.88}]	[{"topic": "True/False/Not Given", "accuracy": 63.81}, {"topic": "Matching Headings", "accuracy": 86.24}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9152	f0000041-0000-0000-0000-000000000041	reading	52	29	89.98	89.98	948	2025-11-01 19:19:45.83964	61.05	[{"date": "2025-10-05", "score": 52.00}, {"date": "2025-10-15", "score": 54.03}, {"date": "2025-10-25", "score": 69.45}, {"date": "2025-11-04", "score": 78.60}]	[{"topic": "True/False/Not Given", "accuracy": 61.34}, {"topic": "Matching Headings", "accuracy": 65.53}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9153	f0000042-0000-0000-0000-000000000042	reading	52	28	89.98	89.98	1287	2025-10-25 19:19:45.83964	76.70	[{"date": "2025-10-05", "score": 58.29}, {"date": "2025-10-15", "score": 73.39}, {"date": "2025-10-25", "score": 60.89}, {"date": "2025-11-04", "score": 64.23}]	[{"topic": "True/False/Not Given", "accuracy": 77.56}, {"topic": "Matching Headings", "accuracy": 81.15}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9154	f0000043-0000-0000-0000-000000000043	reading	52	44	89.98	94.76	444	2025-10-30 19:19:45.83964	60.40	[{"date": "2025-10-05", "score": 57.57}, {"date": "2025-10-15", "score": 50.36}, {"date": "2025-10-25", "score": 76.67}, {"date": "2025-11-04", "score": 75.73}]	[{"topic": "True/False/Not Given", "accuracy": 66.55}, {"topic": "Matching Headings", "accuracy": 65.34}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9155	f0000044-0000-0000-0000-000000000044	reading	52	11	89.98	89.98	314	2025-11-04 19:19:45.83964	77.44	[{"date": "2025-10-05", "score": 86.59}, {"date": "2025-10-15", "score": 54.90}, {"date": "2025-10-25", "score": 82.68}, {"date": "2025-11-04", "score": 80.50}]	[{"topic": "True/False/Not Given", "accuracy": 65.98}, {"topic": "Matching Headings", "accuracy": 63.87}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9156	f0000045-0000-0000-0000-000000000045	reading	52	7	89.98	89.98	1115	2025-10-16 19:19:45.83964	90.95	[{"date": "2025-10-05", "score": 88.03}, {"date": "2025-10-15", "score": 71.99}, {"date": "2025-10-25", "score": 64.30}, {"date": "2025-11-04", "score": 87.36}]	[{"topic": "True/False/Not Given", "accuracy": 62.23}, {"topic": "Matching Headings", "accuracy": 82.46}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9157	f0000046-0000-0000-0000-000000000046	reading	52	46	89.98	89.98	674	2025-10-26 19:19:45.83964	51.33	[{"date": "2025-10-05", "score": 86.78}, {"date": "2025-10-15", "score": 59.23}, {"date": "2025-10-25", "score": 61.05}, {"date": "2025-11-04", "score": 84.73}]	[{"topic": "True/False/Not Given", "accuracy": 85.16}, {"topic": "Matching Headings", "accuracy": 84.69}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9158	f0000047-0000-0000-0000-000000000047	reading	52	11	89.98	89.98	673	2025-10-26 19:19:45.83964	81.76	[{"date": "2025-10-05", "score": 56.23}, {"date": "2025-10-15", "score": 61.83}, {"date": "2025-10-25", "score": 58.86}, {"date": "2025-11-04", "score": 54.73}]	[{"topic": "True/False/Not Given", "accuracy": 76.30}, {"topic": "Matching Headings", "accuracy": 87.55}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9159	f0000048-0000-0000-0000-000000000048	reading	52	33	89.98	89.98	1270	2025-10-11 19:19:45.83964	85.33	[{"date": "2025-10-05", "score": 62.54}, {"date": "2025-10-15", "score": 89.10}, {"date": "2025-10-25", "score": 88.33}, {"date": "2025-11-04", "score": 58.23}]	[{"topic": "True/False/Not Given", "accuracy": 78.66}, {"topic": "Matching Headings", "accuracy": 83.91}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9160	f0000049-0000-0000-0000-000000000049	reading	52	13	89.98	89.98	1306	2025-10-22 19:19:45.83964	65.09	[{"date": "2025-10-05", "score": 70.82}, {"date": "2025-10-15", "score": 54.07}, {"date": "2025-10-25", "score": 77.68}, {"date": "2025-11-04", "score": 68.02}]	[{"topic": "True/False/Not Given", "accuracy": 63.92}, {"topic": "Matching Headings", "accuracy": 79.08}]	2025-11-04 19:19:45.83964	2025-11-04 19:19:45.83964
9161	a0000001-0000-0000-0000-000000000001	writing	43	30	82.18	82.18	695	2025-10-15 19:19:45.841796	95.72	[{"date": "2025-10-05", "score": 63.71}, {"date": "2025-10-15", "score": 66.75}, {"date": "2025-10-25", "score": 88.95}, {"date": "2025-11-04", "score": 65.39}]	[{"topic": "Task Achievement", "accuracy": 77.31}, {"topic": "Grammar", "accuracy": 88.56}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9162	a0000002-0000-0000-0000-000000000002	writing	43	5	82.18	82.18	736	2025-10-19 19:19:45.841796	51.91	[{"date": "2025-10-05", "score": 63.17}, {"date": "2025-10-15", "score": 73.44}, {"date": "2025-10-25", "score": 69.13}, {"date": "2025-11-04", "score": 80.06}]	[{"topic": "Task Achievement", "accuracy": 75.00}, {"topic": "Grammar", "accuracy": 80.07}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9163	b0000001-0000-0000-0000-000000000001	writing	43	26	82.18	85.67	916	2025-10-20 19:19:45.841796	93.53	[{"date": "2025-10-05", "score": 62.88}, {"date": "2025-10-15", "score": 58.28}, {"date": "2025-10-25", "score": 87.10}, {"date": "2025-11-04", "score": 73.40}]	[{"topic": "Task Achievement", "accuracy": 62.24}, {"topic": "Grammar", "accuracy": 67.18}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9164	b0000002-0000-0000-0000-000000000002	writing	43	9	82.18	82.18	820	2025-10-27 19:19:45.841796	69.73	[{"date": "2025-10-05", "score": 74.67}, {"date": "2025-10-15", "score": 50.26}, {"date": "2025-10-25", "score": 79.85}, {"date": "2025-11-04", "score": 82.23}]	[{"topic": "Task Achievement", "accuracy": 88.44}, {"topic": "Grammar", "accuracy": 66.84}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9165	b0000003-0000-0000-0000-000000000003	writing	43	2	82.18	82.18	326	2025-10-19 19:19:45.841796	80.41	[{"date": "2025-10-05", "score": 68.74}, {"date": "2025-10-15", "score": 66.38}, {"date": "2025-10-25", "score": 62.05}, {"date": "2025-11-04", "score": 70.91}]	[{"topic": "Task Achievement", "accuracy": 89.37}, {"topic": "Grammar", "accuracy": 68.96}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9166	b0000004-0000-0000-0000-000000000004	writing	43	16	82.18	82.18	241	2025-10-31 19:19:45.841796	71.07	[{"date": "2025-10-05", "score": 63.18}, {"date": "2025-10-15", "score": 72.50}, {"date": "2025-10-25", "score": 76.82}, {"date": "2025-11-04", "score": 57.57}]	[{"topic": "Task Achievement", "accuracy": 76.78}, {"topic": "Grammar", "accuracy": 60.54}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9167	f0000001-0000-0000-0000-000000000001	writing	43	12	82.18	83.78	798	2025-10-24 19:19:45.841796	87.05	[{"date": "2025-10-05", "score": 55.22}, {"date": "2025-10-15", "score": 63.78}, {"date": "2025-10-25", "score": 55.71}, {"date": "2025-11-04", "score": 89.92}]	[{"topic": "Task Achievement", "accuracy": 74.86}, {"topic": "Grammar", "accuracy": 79.93}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9168	f0000002-0000-0000-0000-000000000002	writing	43	18	82.18	85.96	744	2025-10-23 19:19:45.841796	64.78	[{"date": "2025-10-05", "score": 72.15}, {"date": "2025-10-15", "score": 73.19}, {"date": "2025-10-25", "score": 68.11}, {"date": "2025-11-04", "score": 67.58}]	[{"topic": "Task Achievement", "accuracy": 80.74}, {"topic": "Grammar", "accuracy": 71.93}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9169	f0000003-0000-0000-0000-000000000003	writing	43	9	82.18	82.18	376	2025-10-05 19:19:45.841796	55.87	[{"date": "2025-10-05", "score": 82.05}, {"date": "2025-10-15", "score": 70.56}, {"date": "2025-10-25", "score": 61.80}, {"date": "2025-11-04", "score": 52.41}]	[{"topic": "Task Achievement", "accuracy": 63.73}, {"topic": "Grammar", "accuracy": 88.38}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9170	f0000004-0000-0000-0000-000000000004	writing	43	5	82.18	82.18	501	2025-10-10 19:19:45.841796	83.28	[{"date": "2025-10-05", "score": 65.47}, {"date": "2025-10-15", "score": 66.47}, {"date": "2025-10-25", "score": 58.15}, {"date": "2025-11-04", "score": 51.25}]	[{"topic": "Task Achievement", "accuracy": 62.82}, {"topic": "Grammar", "accuracy": 63.59}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9171	f0000005-0000-0000-0000-000000000005	writing	43	30	82.18	94.26	254	2025-10-28 19:19:45.841796	69.52	[{"date": "2025-10-05", "score": 64.46}, {"date": "2025-10-15", "score": 84.52}, {"date": "2025-10-25", "score": 61.63}, {"date": "2025-11-04", "score": 62.10}]	[{"topic": "Task Achievement", "accuracy": 75.70}, {"topic": "Grammar", "accuracy": 80.09}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9172	f0000006-0000-0000-0000-000000000006	writing	43	22	82.18	89.32	845	2025-10-16 19:19:45.841796	54.33	[{"date": "2025-10-05", "score": 82.65}, {"date": "2025-10-15", "score": 66.30}, {"date": "2025-10-25", "score": 83.54}, {"date": "2025-11-04", "score": 68.60}]	[{"topic": "Task Achievement", "accuracy": 76.11}, {"topic": "Grammar", "accuracy": 89.04}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9173	f0000007-0000-0000-0000-000000000007	writing	43	8	82.18	82.18	300	2025-10-18 19:19:45.841796	56.59	[{"date": "2025-10-05", "score": 52.05}, {"date": "2025-10-15", "score": 57.77}, {"date": "2025-10-25", "score": 66.06}, {"date": "2025-11-04", "score": 60.76}]	[{"topic": "Task Achievement", "accuracy": 82.97}, {"topic": "Grammar", "accuracy": 87.03}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9174	f0000008-0000-0000-0000-000000000008	writing	43	24	82.18	82.18	742	2025-11-01 19:19:45.841796	72.04	[{"date": "2025-10-05", "score": 51.66}, {"date": "2025-10-15", "score": 86.81}, {"date": "2025-10-25", "score": 88.19}, {"date": "2025-11-04", "score": 50.44}]	[{"topic": "Task Achievement", "accuracy": 65.69}, {"topic": "Grammar", "accuracy": 62.47}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9175	f0000009-0000-0000-0000-000000000009	writing	43	19	82.18	82.18	866	2025-10-12 19:19:45.841796	63.47	[{"date": "2025-10-05", "score": 55.39}, {"date": "2025-10-15", "score": 65.76}, {"date": "2025-10-25", "score": 67.97}, {"date": "2025-11-04", "score": 81.59}]	[{"topic": "Task Achievement", "accuracy": 84.74}, {"topic": "Grammar", "accuracy": 67.23}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9176	f0000010-0000-0000-0000-000000000010	writing	43	15	82.18	82.18	293	2025-10-16 19:19:45.841796	76.12	[{"date": "2025-10-05", "score": 80.47}, {"date": "2025-10-15", "score": 51.77}, {"date": "2025-10-25", "score": 83.94}, {"date": "2025-11-04", "score": 88.29}]	[{"topic": "Task Achievement", "accuracy": 85.81}, {"topic": "Grammar", "accuracy": 69.00}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9177	f0000011-0000-0000-0000-000000000011	writing	43	29	82.18	82.80	606	2025-10-28 19:19:45.841796	54.36	[{"date": "2025-10-05", "score": 62.87}, {"date": "2025-10-15", "score": 76.20}, {"date": "2025-10-25", "score": 89.67}, {"date": "2025-11-04", "score": 83.50}]	[{"topic": "Task Achievement", "accuracy": 61.13}, {"topic": "Grammar", "accuracy": 65.88}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9178	f0000012-0000-0000-0000-000000000012	writing	43	30	82.18	82.18	808	2025-10-23 19:19:45.841796	84.42	[{"date": "2025-10-05", "score": 63.57}, {"date": "2025-10-15", "score": 80.66}, {"date": "2025-10-25", "score": 72.20}, {"date": "2025-11-04", "score": 75.70}]	[{"topic": "Task Achievement", "accuracy": 76.59}, {"topic": "Grammar", "accuracy": 71.00}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9179	f0000013-0000-0000-0000-000000000013	writing	43	6	82.18	99.41	355	2025-10-30 19:19:45.841796	83.11	[{"date": "2025-10-05", "score": 50.21}, {"date": "2025-10-15", "score": 68.61}, {"date": "2025-10-25", "score": 88.07}, {"date": "2025-11-04", "score": 56.82}]	[{"topic": "Task Achievement", "accuracy": 82.46}, {"topic": "Grammar", "accuracy": 75.37}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9180	f0000014-0000-0000-0000-000000000014	writing	43	20	82.18	82.18	162	2025-10-27 19:19:45.841796	55.66	[{"date": "2025-10-05", "score": 78.15}, {"date": "2025-10-15", "score": 88.90}, {"date": "2025-10-25", "score": 54.36}, {"date": "2025-11-04", "score": 85.30}]	[{"topic": "Task Achievement", "accuracy": 66.36}, {"topic": "Grammar", "accuracy": 63.53}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9181	f0000015-0000-0000-0000-000000000015	writing	43	27	82.18	82.18	900	2025-11-04 19:19:45.841796	94.18	[{"date": "2025-10-05", "score": 72.20}, {"date": "2025-10-15", "score": 75.50}, {"date": "2025-10-25", "score": 57.04}, {"date": "2025-11-04", "score": 79.56}]	[{"topic": "Task Achievement", "accuracy": 83.99}, {"topic": "Grammar", "accuracy": 78.58}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9182	f0000016-0000-0000-0000-000000000016	writing	43	19	82.18	82.18	377	2025-10-25 19:19:45.841796	94.13	[{"date": "2025-10-05", "score": 70.90}, {"date": "2025-10-15", "score": 57.01}, {"date": "2025-10-25", "score": 71.48}, {"date": "2025-11-04", "score": 57.27}]	[{"topic": "Task Achievement", "accuracy": 76.45}, {"topic": "Grammar", "accuracy": 77.62}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9183	f0000017-0000-0000-0000-000000000017	writing	43	8	82.18	86.09	199	2025-10-13 19:19:45.841796	81.77	[{"date": "2025-10-05", "score": 70.21}, {"date": "2025-10-15", "score": 55.50}, {"date": "2025-10-25", "score": 80.15}, {"date": "2025-11-04", "score": 68.00}]	[{"topic": "Task Achievement", "accuracy": 72.52}, {"topic": "Grammar", "accuracy": 65.91}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9184	f0000018-0000-0000-0000-000000000018	writing	43	26	82.18	82.18	429	2025-10-21 19:19:45.841796	50.20	[{"date": "2025-10-05", "score": 64.35}, {"date": "2025-10-15", "score": 74.92}, {"date": "2025-10-25", "score": 68.98}, {"date": "2025-11-04", "score": 73.54}]	[{"topic": "Task Achievement", "accuracy": 78.26}, {"topic": "Grammar", "accuracy": 66.76}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9185	f0000019-0000-0000-0000-000000000019	writing	43	30	82.18	82.18	391	2025-10-06 19:19:45.841796	96.39	[{"date": "2025-10-05", "score": 54.61}, {"date": "2025-10-15", "score": 51.94}, {"date": "2025-10-25", "score": 74.01}, {"date": "2025-11-04", "score": 50.17}]	[{"topic": "Task Achievement", "accuracy": 80.86}, {"topic": "Grammar", "accuracy": 85.60}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9186	f0000020-0000-0000-0000-000000000020	writing	43	19	82.18	82.18	696	2025-10-17 19:19:45.841796	63.88	[{"date": "2025-10-05", "score": 63.40}, {"date": "2025-10-15", "score": 73.71}, {"date": "2025-10-25", "score": 53.30}, {"date": "2025-11-04", "score": 75.95}]	[{"topic": "Task Achievement", "accuracy": 84.83}, {"topic": "Grammar", "accuracy": 78.88}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9187	f0000021-0000-0000-0000-000000000021	writing	43	36	82.18	82.18	232	2025-10-25 19:19:45.841796	96.61	[{"date": "2025-10-05", "score": 82.19}, {"date": "2025-10-15", "score": 62.81}, {"date": "2025-10-25", "score": 61.97}, {"date": "2025-11-04", "score": 52.80}]	[{"topic": "Task Achievement", "accuracy": 81.30}, {"topic": "Grammar", "accuracy": 89.28}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9188	f0000022-0000-0000-0000-000000000022	writing	43	22	82.18	82.18	310	2025-10-21 19:19:45.841796	66.04	[{"date": "2025-10-05", "score": 69.71}, {"date": "2025-10-15", "score": 76.70}, {"date": "2025-10-25", "score": 64.64}, {"date": "2025-11-04", "score": 50.27}]	[{"topic": "Task Achievement", "accuracy": 85.08}, {"topic": "Grammar", "accuracy": 73.12}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9189	f0000023-0000-0000-0000-000000000023	writing	43	28	82.18	96.34	817	2025-10-19 19:19:45.841796	95.21	[{"date": "2025-10-05", "score": 72.67}, {"date": "2025-10-15", "score": 63.62}, {"date": "2025-10-25", "score": 82.78}, {"date": "2025-11-04", "score": 64.20}]	[{"topic": "Task Achievement", "accuracy": 89.34}, {"topic": "Grammar", "accuracy": 82.57}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9190	f0000024-0000-0000-0000-000000000024	writing	43	31	82.18	82.18	191	2025-10-15 19:19:45.841796	74.69	[{"date": "2025-10-05", "score": 67.79}, {"date": "2025-10-15", "score": 82.44}, {"date": "2025-10-25", "score": 61.40}, {"date": "2025-11-04", "score": 50.94}]	[{"topic": "Task Achievement", "accuracy": 85.14}, {"topic": "Grammar", "accuracy": 63.57}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9191	f0000025-0000-0000-0000-000000000025	writing	43	30	82.18	82.18	674	2025-10-16 19:19:45.841796	60.56	[{"date": "2025-10-05", "score": 71.13}, {"date": "2025-10-15", "score": 70.89}, {"date": "2025-10-25", "score": 89.86}, {"date": "2025-11-04", "score": 60.82}]	[{"topic": "Task Achievement", "accuracy": 80.93}, {"topic": "Grammar", "accuracy": 78.71}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9192	f0000026-0000-0000-0000-000000000026	writing	43	10	82.18	82.18	159	2025-10-22 19:19:45.841796	63.16	[{"date": "2025-10-05", "score": 87.48}, {"date": "2025-10-15", "score": 50.92}, {"date": "2025-10-25", "score": 77.72}, {"date": "2025-11-04", "score": 52.09}]	[{"topic": "Task Achievement", "accuracy": 67.17}, {"topic": "Grammar", "accuracy": 79.22}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9193	f0000027-0000-0000-0000-000000000027	writing	43	24	82.18	82.18	676	2025-10-26 19:19:45.841796	94.21	[{"date": "2025-10-05", "score": 55.36}, {"date": "2025-10-15", "score": 77.83}, {"date": "2025-10-25", "score": 71.73}, {"date": "2025-11-04", "score": 80.28}]	[{"topic": "Task Achievement", "accuracy": 62.91}, {"topic": "Grammar", "accuracy": 78.65}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9194	f0000028-0000-0000-0000-000000000028	writing	43	32	82.18	84.66	472	2025-10-30 19:19:45.841796	63.07	[{"date": "2025-10-05", "score": 74.13}, {"date": "2025-10-15", "score": 87.66}, {"date": "2025-10-25", "score": 79.81}, {"date": "2025-11-04", "score": 81.89}]	[{"topic": "Task Achievement", "accuracy": 64.39}, {"topic": "Grammar", "accuracy": 74.50}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9195	f0000029-0000-0000-0000-000000000029	writing	43	8	82.18	82.18	833	2025-10-24 19:19:45.841796	94.80	[{"date": "2025-10-05", "score": 58.17}, {"date": "2025-10-15", "score": 72.51}, {"date": "2025-10-25", "score": 57.35}, {"date": "2025-11-04", "score": 66.49}]	[{"topic": "Task Achievement", "accuracy": 84.76}, {"topic": "Grammar", "accuracy": 88.22}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9196	f0000030-0000-0000-0000-000000000030	writing	43	9	82.18	82.18	544	2025-10-16 19:19:45.841796	90.78	[{"date": "2025-10-05", "score": 65.95}, {"date": "2025-10-15", "score": 77.34}, {"date": "2025-10-25", "score": 89.02}, {"date": "2025-11-04", "score": 83.85}]	[{"topic": "Task Achievement", "accuracy": 60.47}, {"topic": "Grammar", "accuracy": 85.52}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9197	f0000031-0000-0000-0000-000000000031	writing	43	18	82.18	96.69	214	2025-10-30 19:19:45.841796	87.55	[{"date": "2025-10-05", "score": 63.06}, {"date": "2025-10-15", "score": 59.10}, {"date": "2025-10-25", "score": 56.05}, {"date": "2025-11-04", "score": 52.64}]	[{"topic": "Task Achievement", "accuracy": 80.31}, {"topic": "Grammar", "accuracy": 84.54}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9198	f0000032-0000-0000-0000-000000000032	writing	43	5	82.18	82.18	334	2025-10-23 19:19:45.841796	78.36	[{"date": "2025-10-05", "score": 63.33}, {"date": "2025-10-15", "score": 82.56}, {"date": "2025-10-25", "score": 66.37}, {"date": "2025-11-04", "score": 85.48}]	[{"topic": "Task Achievement", "accuracy": 73.78}, {"topic": "Grammar", "accuracy": 84.44}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9199	f0000033-0000-0000-0000-000000000033	writing	43	24	82.18	82.18	648	2025-10-13 19:19:45.841796	58.44	[{"date": "2025-10-05", "score": 74.36}, {"date": "2025-10-15", "score": 55.76}, {"date": "2025-10-25", "score": 54.66}, {"date": "2025-11-04", "score": 67.44}]	[{"topic": "Task Achievement", "accuracy": 84.21}, {"topic": "Grammar", "accuracy": 76.84}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9200	f0000034-0000-0000-0000-000000000034	writing	43	33	82.18	98.32	145	2025-11-03 19:19:45.841796	72.10	[{"date": "2025-10-05", "score": 60.15}, {"date": "2025-10-15", "score": 71.34}, {"date": "2025-10-25", "score": 70.55}, {"date": "2025-11-04", "score": 87.88}]	[{"topic": "Task Achievement", "accuracy": 75.86}, {"topic": "Grammar", "accuracy": 67.92}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9201	f0000035-0000-0000-0000-000000000035	writing	43	25	82.18	82.18	461	2025-10-27 19:19:45.841796	78.52	[{"date": "2025-10-05", "score": 76.65}, {"date": "2025-10-15", "score": 89.95}, {"date": "2025-10-25", "score": 53.13}, {"date": "2025-11-04", "score": 57.67}]	[{"topic": "Task Achievement", "accuracy": 80.41}, {"topic": "Grammar", "accuracy": 60.31}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9202	f0000036-0000-0000-0000-000000000036	writing	43	33	82.18	90.03	536	2025-10-26 19:19:45.841796	78.08	[{"date": "2025-10-05", "score": 83.24}, {"date": "2025-10-15", "score": 82.30}, {"date": "2025-10-25", "score": 73.45}, {"date": "2025-11-04", "score": 65.44}]	[{"topic": "Task Achievement", "accuracy": 82.27}, {"topic": "Grammar", "accuracy": 80.37}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9203	f0000037-0000-0000-0000-000000000037	writing	43	5	82.18	82.18	858	2025-10-09 19:19:45.841796	90.34	[{"date": "2025-10-05", "score": 68.80}, {"date": "2025-10-15", "score": 50.19}, {"date": "2025-10-25", "score": 71.51}, {"date": "2025-11-04", "score": 54.44}]	[{"topic": "Task Achievement", "accuracy": 89.21}, {"topic": "Grammar", "accuracy": 69.27}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9204	f0000038-0000-0000-0000-000000000038	writing	43	13	82.18	88.33	798	2025-10-24 19:19:45.841796	87.52	[{"date": "2025-10-05", "score": 53.41}, {"date": "2025-10-15", "score": 89.37}, {"date": "2025-10-25", "score": 80.20}, {"date": "2025-11-04", "score": 84.94}]	[{"topic": "Task Achievement", "accuracy": 69.34}, {"topic": "Grammar", "accuracy": 75.78}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9205	f0000039-0000-0000-0000-000000000039	writing	43	18	82.18	88.92	439	2025-10-26 19:19:45.841796	58.96	[{"date": "2025-10-05", "score": 84.43}, {"date": "2025-10-15", "score": 82.56}, {"date": "2025-10-25", "score": 51.58}, {"date": "2025-11-04", "score": 68.48}]	[{"topic": "Task Achievement", "accuracy": 73.99}, {"topic": "Grammar", "accuracy": 80.96}]	2025-11-04 19:19:45.841796	2025-11-04 19:19:45.841796
9206	a0000001-0000-0000-0000-000000000001	speaking	2	2	76.84	76.84	550	2025-10-14 19:19:45.843321	82.36	[{"date": "2025-10-05", "score": 74.38}, {"date": "2025-10-15", "score": 87.78}, {"date": "2025-10-25", "score": 58.48}, {"date": "2025-11-04", "score": 53.19}]	[{"topic": "Pronunciation", "accuracy": 84.13}, {"topic": "Fluency", "accuracy": 68.03}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9207	a0000002-0000-0000-0000-000000000002	speaking	2	2	76.84	86.10	357	2025-10-19 19:19:45.843321	50.11	[{"date": "2025-10-05", "score": 65.90}, {"date": "2025-10-15", "score": 59.95}, {"date": "2025-10-25", "score": 57.98}, {"date": "2025-11-04", "score": 80.62}]	[{"topic": "Pronunciation", "accuracy": 73.91}, {"topic": "Fluency", "accuracy": 76.55}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9208	b0000001-0000-0000-0000-000000000001	speaking	2	2	76.84	76.84	686	2025-10-07 19:19:45.843321	79.18	[{"date": "2025-10-05", "score": 59.25}, {"date": "2025-10-15", "score": 87.82}, {"date": "2025-10-25", "score": 63.37}, {"date": "2025-11-04", "score": 52.42}]	[{"topic": "Pronunciation", "accuracy": 60.01}, {"topic": "Fluency", "accuracy": 80.65}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9209	b0000002-0000-0000-0000-000000000002	speaking	2	2	76.84	88.84	244	2025-10-13 19:19:45.843321	89.93	[{"date": "2025-10-05", "score": 77.77}, {"date": "2025-10-15", "score": 88.66}, {"date": "2025-10-25", "score": 67.24}, {"date": "2025-11-04", "score": 62.55}]	[{"topic": "Pronunciation", "accuracy": 81.16}, {"topic": "Fluency", "accuracy": 66.40}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9210	b0000003-0000-0000-0000-000000000003	speaking	2	2	76.84	99.40	291	2025-10-20 19:19:45.843321	64.96	[{"date": "2025-10-05", "score": 64.46}, {"date": "2025-10-15", "score": 88.31}, {"date": "2025-10-25", "score": 89.73}, {"date": "2025-11-04", "score": 75.43}]	[{"topic": "Pronunciation", "accuracy": 66.46}, {"topic": "Fluency", "accuracy": 70.85}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9211	b0000004-0000-0000-0000-000000000004	speaking	2	2	76.84	97.08	267	2025-10-07 19:19:45.843321	88.76	[{"date": "2025-10-05", "score": 85.02}, {"date": "2025-10-15", "score": 52.25}, {"date": "2025-10-25", "score": 55.90}, {"date": "2025-11-04", "score": 88.59}]	[{"topic": "Pronunciation", "accuracy": 89.20}, {"topic": "Fluency", "accuracy": 80.33}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9212	f0000001-0000-0000-0000-000000000001	speaking	2	2	76.84	84.57	144	2025-10-25 19:19:45.843321	96.69	[{"date": "2025-10-05", "score": 60.70}, {"date": "2025-10-15", "score": 60.01}, {"date": "2025-10-25", "score": 68.77}, {"date": "2025-11-04", "score": 56.69}]	[{"topic": "Pronunciation", "accuracy": 89.11}, {"topic": "Fluency", "accuracy": 84.03}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9213	f0000002-0000-0000-0000-000000000002	speaking	2	2	76.84	87.68	297	2025-10-21 19:19:45.843321	67.51	[{"date": "2025-10-05", "score": 80.95}, {"date": "2025-10-15", "score": 86.87}, {"date": "2025-10-25", "score": 82.35}, {"date": "2025-11-04", "score": 88.35}]	[{"topic": "Pronunciation", "accuracy": 65.36}, {"topic": "Fluency", "accuracy": 86.44}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9214	f0000003-0000-0000-0000-000000000003	speaking	2	2	76.84	89.07	187	2025-11-01 19:19:45.843321	97.43	[{"date": "2025-10-05", "score": 83.08}, {"date": "2025-10-15", "score": 73.88}, {"date": "2025-10-25", "score": 50.31}, {"date": "2025-11-04", "score": 79.56}]	[{"topic": "Pronunciation", "accuracy": 69.61}, {"topic": "Fluency", "accuracy": 61.06}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9215	f0000004-0000-0000-0000-000000000004	speaking	2	2	76.84	88.41	425	2025-10-24 19:19:45.843321	71.23	[{"date": "2025-10-05", "score": 79.10}, {"date": "2025-10-15", "score": 72.12}, {"date": "2025-10-25", "score": 53.06}, {"date": "2025-11-04", "score": 52.45}]	[{"topic": "Pronunciation", "accuracy": 80.30}, {"topic": "Fluency", "accuracy": 66.80}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9216	f0000005-0000-0000-0000-000000000005	speaking	2	2	76.84	76.84	377	2025-10-09 19:19:45.843321	98.89	[{"date": "2025-10-05", "score": 71.54}, {"date": "2025-10-15", "score": 55.02}, {"date": "2025-10-25", "score": 63.86}, {"date": "2025-11-04", "score": 65.19}]	[{"topic": "Pronunciation", "accuracy": 88.42}, {"topic": "Fluency", "accuracy": 77.63}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9217	f0000006-0000-0000-0000-000000000006	speaking	2	2	76.84	76.84	177	2025-10-09 19:19:45.843321	62.40	[{"date": "2025-10-05", "score": 86.61}, {"date": "2025-10-15", "score": 50.59}, {"date": "2025-10-25", "score": 51.33}, {"date": "2025-11-04", "score": 55.99}]	[{"topic": "Pronunciation", "accuracy": 81.68}, {"topic": "Fluency", "accuracy": 64.31}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9218	f0000007-0000-0000-0000-000000000007	speaking	2	2	76.84	83.93	377	2025-10-16 19:19:45.843321	84.49	[{"date": "2025-10-05", "score": 64.74}, {"date": "2025-10-15", "score": 64.87}, {"date": "2025-10-25", "score": 58.02}, {"date": "2025-11-04", "score": 88.26}]	[{"topic": "Pronunciation", "accuracy": 69.11}, {"topic": "Fluency", "accuracy": 70.76}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9219	f0000008-0000-0000-0000-000000000008	speaking	2	2	76.84	86.20	170	2025-10-11 19:19:45.843321	99.11	[{"date": "2025-10-05", "score": 76.42}, {"date": "2025-10-15", "score": 82.00}, {"date": "2025-10-25", "score": 65.09}, {"date": "2025-11-04", "score": 62.51}]	[{"topic": "Pronunciation", "accuracy": 72.92}, {"topic": "Fluency", "accuracy": 66.19}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9220	f0000009-0000-0000-0000-000000000009	speaking	2	2	76.84	85.33	184	2025-10-30 19:19:45.843321	50.25	[{"date": "2025-10-05", "score": 89.41}, {"date": "2025-10-15", "score": 75.48}, {"date": "2025-10-25", "score": 53.11}, {"date": "2025-11-04", "score": 75.28}]	[{"topic": "Pronunciation", "accuracy": 75.13}, {"topic": "Fluency", "accuracy": 76.09}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9221	f0000010-0000-0000-0000-000000000010	speaking	2	2	76.84	76.84	274	2025-10-28 19:19:45.843321	91.41	[{"date": "2025-10-05", "score": 75.92}, {"date": "2025-10-15", "score": 60.25}, {"date": "2025-10-25", "score": 65.06}, {"date": "2025-11-04", "score": 87.50}]	[{"topic": "Pronunciation", "accuracy": 84.29}, {"topic": "Fluency", "accuracy": 77.91}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9222	f0000011-0000-0000-0000-000000000011	speaking	2	2	76.84	77.77	379	2025-10-07 19:19:45.843321	71.74	[{"date": "2025-10-05", "score": 70.08}, {"date": "2025-10-15", "score": 89.16}, {"date": "2025-10-25", "score": 73.04}, {"date": "2025-11-04", "score": 78.47}]	[{"topic": "Pronunciation", "accuracy": 83.33}, {"topic": "Fluency", "accuracy": 74.90}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9223	f0000012-0000-0000-0000-000000000012	speaking	2	2	76.84	99.18	239	2025-11-02 19:19:45.843321	85.13	[{"date": "2025-10-05", "score": 74.52}, {"date": "2025-10-15", "score": 52.80}, {"date": "2025-10-25", "score": 87.91}, {"date": "2025-11-04", "score": 59.11}]	[{"topic": "Pronunciation", "accuracy": 76.60}, {"topic": "Fluency", "accuracy": 63.68}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9224	f0000013-0000-0000-0000-000000000013	speaking	2	2	76.84	81.37	667	2025-10-31 19:19:45.843321	76.65	[{"date": "2025-10-05", "score": 64.05}, {"date": "2025-10-15", "score": 89.44}, {"date": "2025-10-25", "score": 82.38}, {"date": "2025-11-04", "score": 84.49}]	[{"topic": "Pronunciation", "accuracy": 63.80}, {"topic": "Fluency", "accuracy": 61.14}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9225	f0000014-0000-0000-0000-000000000014	speaking	2	2	76.84	88.99	172	2025-10-13 19:19:45.843321	69.70	[{"date": "2025-10-05", "score": 75.75}, {"date": "2025-10-15", "score": 84.66}, {"date": "2025-10-25", "score": 71.38}, {"date": "2025-11-04", "score": 80.19}]	[{"topic": "Pronunciation", "accuracy": 70.68}, {"topic": "Fluency", "accuracy": 67.91}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9226	f0000015-0000-0000-0000-000000000015	speaking	2	2	76.84	76.84	300	2025-10-29 19:19:45.843321	61.79	[{"date": "2025-10-05", "score": 56.95}, {"date": "2025-10-15", "score": 87.01}, {"date": "2025-10-25", "score": 69.72}, {"date": "2025-11-04", "score": 73.33}]	[{"topic": "Pronunciation", "accuracy": 77.92}, {"topic": "Fluency", "accuracy": 65.21}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9227	f0000016-0000-0000-0000-000000000016	speaking	2	2	76.84	99.67	618	2025-10-27 19:19:45.843321	50.52	[{"date": "2025-10-05", "score": 54.11}, {"date": "2025-10-15", "score": 82.17}, {"date": "2025-10-25", "score": 75.30}, {"date": "2025-11-04", "score": 69.58}]	[{"topic": "Pronunciation", "accuracy": 69.78}, {"topic": "Fluency", "accuracy": 88.17}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9228	f0000017-0000-0000-0000-000000000017	speaking	2	2	76.84	87.53	383	2025-10-24 19:19:45.843321	75.76	[{"date": "2025-10-05", "score": 65.42}, {"date": "2025-10-15", "score": 53.34}, {"date": "2025-10-25", "score": 83.57}, {"date": "2025-11-04", "score": 81.68}]	[{"topic": "Pronunciation", "accuracy": 80.13}, {"topic": "Fluency", "accuracy": 69.56}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9229	f0000018-0000-0000-0000-000000000018	speaking	2	2	76.84	76.84	599	2025-11-02 19:19:45.843321	50.25	[{"date": "2025-10-05", "score": 75.12}, {"date": "2025-10-15", "score": 63.41}, {"date": "2025-10-25", "score": 50.27}, {"date": "2025-11-04", "score": 53.35}]	[{"topic": "Pronunciation", "accuracy": 81.86}, {"topic": "Fluency", "accuracy": 63.65}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9230	f0000019-0000-0000-0000-000000000019	speaking	2	2	76.84	88.69	570	2025-10-18 19:19:45.843321	71.91	[{"date": "2025-10-05", "score": 50.88}, {"date": "2025-10-15", "score": 56.23}, {"date": "2025-10-25", "score": 61.51}, {"date": "2025-11-04", "score": 85.51}]	[{"topic": "Pronunciation", "accuracy": 68.89}, {"topic": "Fluency", "accuracy": 75.70}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9231	f0000020-0000-0000-0000-000000000020	speaking	2	2	76.84	76.84	392	2025-10-17 19:19:45.843321	58.36	[{"date": "2025-10-05", "score": 82.72}, {"date": "2025-10-15", "score": 53.99}, {"date": "2025-10-25", "score": 76.18}, {"date": "2025-11-04", "score": 61.84}]	[{"topic": "Pronunciation", "accuracy": 80.11}, {"topic": "Fluency", "accuracy": 67.91}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9232	f0000021-0000-0000-0000-000000000021	speaking	2	2	76.84	98.47	234	2025-11-01 19:19:45.843321	52.61	[{"date": "2025-10-05", "score": 86.78}, {"date": "2025-10-15", "score": 76.38}, {"date": "2025-10-25", "score": 65.42}, {"date": "2025-11-04", "score": 70.32}]	[{"topic": "Pronunciation", "accuracy": 74.75}, {"topic": "Fluency", "accuracy": 70.90}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9233	f0000022-0000-0000-0000-000000000022	speaking	2	2	76.84	91.05	582	2025-10-11 19:19:45.843321	53.36	[{"date": "2025-10-05", "score": 78.99}, {"date": "2025-10-15", "score": 87.32}, {"date": "2025-10-25", "score": 86.65}, {"date": "2025-11-04", "score": 65.63}]	[{"topic": "Pronunciation", "accuracy": 73.21}, {"topic": "Fluency", "accuracy": 66.62}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9234	f0000023-0000-0000-0000-000000000023	speaking	2	2	76.84	76.84	203	2025-10-25 19:19:45.843321	67.25	[{"date": "2025-10-05", "score": 57.24}, {"date": "2025-10-15", "score": 61.15}, {"date": "2025-10-25", "score": 70.77}, {"date": "2025-11-04", "score": 79.03}]	[{"topic": "Pronunciation", "accuracy": 71.25}, {"topic": "Fluency", "accuracy": 83.86}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9235	f0000024-0000-0000-0000-000000000024	speaking	2	2	76.84	76.84	275	2025-10-31 19:19:45.843321	75.67	[{"date": "2025-10-05", "score": 80.51}, {"date": "2025-10-15", "score": 74.11}, {"date": "2025-10-25", "score": 62.19}, {"date": "2025-11-04", "score": 56.17}]	[{"topic": "Pronunciation", "accuracy": 62.24}, {"topic": "Fluency", "accuracy": 73.36}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9236	f0000025-0000-0000-0000-000000000025	speaking	2	2	76.84	89.53	127	2025-10-18 19:19:45.843321	80.40	[{"date": "2025-10-05", "score": 74.01}, {"date": "2025-10-15", "score": 59.26}, {"date": "2025-10-25", "score": 78.18}, {"date": "2025-11-04", "score": 56.25}]	[{"topic": "Pronunciation", "accuracy": 66.26}, {"topic": "Fluency", "accuracy": 70.90}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9237	f0000026-0000-0000-0000-000000000026	speaking	2	2	76.84	83.44	307	2025-10-22 19:19:45.843321	99.68	[{"date": "2025-10-05", "score": 66.58}, {"date": "2025-10-15", "score": 58.70}, {"date": "2025-10-25", "score": 70.36}, {"date": "2025-11-04", "score": 64.30}]	[{"topic": "Pronunciation", "accuracy": 64.08}, {"topic": "Fluency", "accuracy": 70.14}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9238	f0000027-0000-0000-0000-000000000027	speaking	2	2	76.84	76.84	97	2025-10-19 19:19:45.843321	51.33	[{"date": "2025-10-05", "score": 53.00}, {"date": "2025-10-15", "score": 53.48}, {"date": "2025-10-25", "score": 58.53}, {"date": "2025-11-04", "score": 74.21}]	[{"topic": "Pronunciation", "accuracy": 70.07}, {"topic": "Fluency", "accuracy": 78.61}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9239	f0000028-0000-0000-0000-000000000028	speaking	2	2	76.84	76.84	636	2025-10-17 19:19:45.843321	75.64	[{"date": "2025-10-05", "score": 56.12}, {"date": "2025-10-15", "score": 57.78}, {"date": "2025-10-25", "score": 77.30}, {"date": "2025-11-04", "score": 69.66}]	[{"topic": "Pronunciation", "accuracy": 64.36}, {"topic": "Fluency", "accuracy": 68.78}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9240	f0000029-0000-0000-0000-000000000029	speaking	2	2	76.84	90.94	262	2025-10-12 19:19:45.843321	54.13	[{"date": "2025-10-05", "score": 61.70}, {"date": "2025-10-15", "score": 51.88}, {"date": "2025-10-25", "score": 79.75}, {"date": "2025-11-04", "score": 55.20}]	[{"topic": "Pronunciation", "accuracy": 74.49}, {"topic": "Fluency", "accuracy": 78.94}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9241	f0000030-0000-0000-0000-000000000030	speaking	2	2	76.84	87.26	620	2025-10-12 19:19:45.843321	83.22	[{"date": "2025-10-05", "score": 56.54}, {"date": "2025-10-15", "score": 72.90}, {"date": "2025-10-25", "score": 51.42}, {"date": "2025-11-04", "score": 53.98}]	[{"topic": "Pronunciation", "accuracy": 63.45}, {"topic": "Fluency", "accuracy": 88.43}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9242	f0000031-0000-0000-0000-000000000031	speaking	2	2	76.84	76.84	414	2025-10-06 19:19:45.843321	74.00	[{"date": "2025-10-05", "score": 70.34}, {"date": "2025-10-15", "score": 57.43}, {"date": "2025-10-25", "score": 68.02}, {"date": "2025-11-04", "score": 52.72}]	[{"topic": "Pronunciation", "accuracy": 70.46}, {"topic": "Fluency", "accuracy": 85.01}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9243	f0000032-0000-0000-0000-000000000032	speaking	2	2	76.84	99.15	641	2025-10-12 19:19:45.843321	50.95	[{"date": "2025-10-05", "score": 58.65}, {"date": "2025-10-15", "score": 68.38}, {"date": "2025-10-25", "score": 79.03}, {"date": "2025-11-04", "score": 74.88}]	[{"topic": "Pronunciation", "accuracy": 70.97}, {"topic": "Fluency", "accuracy": 85.78}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9244	f0000033-0000-0000-0000-000000000033	speaking	2	2	76.84	80.38	359	2025-10-29 19:19:45.843321	58.08	[{"date": "2025-10-05", "score": 75.06}, {"date": "2025-10-15", "score": 53.71}, {"date": "2025-10-25", "score": 55.05}, {"date": "2025-11-04", "score": 67.59}]	[{"topic": "Pronunciation", "accuracy": 66.49}, {"topic": "Fluency", "accuracy": 69.64}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9245	f0000034-0000-0000-0000-000000000034	speaking	2	2	76.84	96.94	366	2025-11-01 19:19:45.843321	90.33	[{"date": "2025-10-05", "score": 71.02}, {"date": "2025-10-15", "score": 81.56}, {"date": "2025-10-25", "score": 63.17}, {"date": "2025-11-04", "score": 53.90}]	[{"topic": "Pronunciation", "accuracy": 65.16}, {"topic": "Fluency", "accuracy": 87.15}]	2025-11-04 19:19:45.843321	2025-11-04 19:19:45.843321
9054	f0000003-0000-0000-0000-000000000003	listening	38	38	75.97	82.31	223	2025-11-05 06:14:59.284886	2.00	[{"date": "2025-10-05", "score": 65.86}, {"date": "2025-10-15", "score": 87.23}, {"date": "2025-10-25", "score": 86.35}, {"date": "2025-11-04", "score": 67.76}]	[{"topic": "Multiple Choice", "accuracy": 76.99}, {"topic": "Note Completion", "accuracy": 85.43}]	2025-11-04 19:19:45.836382	2025-11-05 06:14:59.285192
\.


--
-- Data for Name: study_goals; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.study_goals (id, user_id, goal_type, title, description, target_value, target_unit, current_value, skill_type, start_date, end_date, status, completed_at, reminder_enabled, reminder_time, created_at, updated_at) FROM stdin;
f06e3a29-c875-4f0b-aac8-a5b2af188ae1	f0000001-0000-0000-0000-000000000001	daily	Complete 3 lessons this week	Personal study goal to improve IELTS skills	11	minutes	0	reading	2025-10-16	2026-01-01	completed	\N	f	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
ffdceca7-022c-4f56-907b-0f3905436245	f0000002-0000-0000-0000-000000000002	weekly	Achieve Band 8.0 in Reading	Personal study goal to improve IELTS skills	13	minutes	0	speaking	2025-10-12	2026-01-10	expired	\N	t	09:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
8e1742d1-7be1-4d14-9418-f22f592c95b0	f0000003-0000-0000-0000-000000000003	daily	Complete 12 exercises	Personal study goal to improve IELTS skills	14	minutes	0	writing	2025-10-05	2025-12-22	expired	\N	f	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
be434aa8-d259-48b3-bb79-dd2277cf7b65	f0000004-0000-0000-0000-000000000004	monthly	Complete 11 exercises	Personal study goal to improve IELTS skills	88	lessons	0	\N	2025-10-25	2026-02-01	completed	\N	t	10:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
4cadaac1-58e5-47df-b54b-7476a80e26cd	f0000005-0000-0000-0000-000000000005	monthly	Complete 1 lessons this week	Personal study goal to improve IELTS skills	6	lessons	0	\N	2025-10-27	2025-12-29	completed	\N	t	19:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
a6020651-e074-444d-81fb-6296f4638035	f0000006-0000-0000-0000-000000000006	daily	Complete 12 exercises	Personal study goal to improve IELTS skills	7	lessons	0	\N	2025-10-24	2026-01-05	expired	\N	t	20:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
d56576be-79d7-4d35-bcea-b774aa0d79c0	f0000007-0000-0000-0000-000000000007	monthly	Complete 6 exercises	Personal study goal to improve IELTS skills	7	minutes	0	\N	2025-10-14	2025-12-16	completed	\N	t	15:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
6c133ab7-6ff6-495a-a86c-6ce54fac04e2	f0000008-0000-0000-0000-000000000008	monthly	Achieve Band 7.0 in Speaking	Personal study goal to improve IELTS skills	7	lessons	0	speaking	2025-10-25	2026-01-27	expired	\N	t	09:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
96518733-3604-49f1-ab37-c68746d7fc85	f0000009-0000-0000-0000-000000000009	monthly	Complete 15 exercises	Personal study goal to improve IELTS skills	7	minutes	0	\N	2025-10-10	2026-01-06	expired	\N	t	08:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
be23d611-351f-4ae7-b11d-31e6bd691e08	f0000010-0000-0000-0000-000000000010	monthly	Complete 9 exercises	Personal study goal to improve IELTS skills	10	lessons	0	\N	2025-10-19	2026-01-26	expired	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
5165f6e9-78de-4810-89e3-af980dd44b2d	f0000011-0000-0000-0000-000000000011	weekly	Study 35 minutes daily	Personal study goal to improve IELTS skills	11	minutes	0	\N	2025-10-09	2026-01-20	expired	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
6adf021e-bb56-4251-853b-631ab9129628	f0000012-0000-0000-0000-000000000012	weekly	Achieve Band 6.0 in Reading	Personal study goal to improve IELTS skills	85	minutes	0	listening	2025-10-21	2025-12-18	active	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
1470a8f0-7ffa-47ff-8626-b91bf4717c93	f0000013-0000-0000-0000-000000000013	weekly	Study 67 minutes daily	Personal study goal to improve IELTS skills	15	lessons	0	reading	2025-10-19	2025-12-22	expired	\N	f	19:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
f3f88589-3b95-44f8-b6f0-f9aa255eb437	f0000014-0000-0000-0000-000000000014	weekly	Complete 8 exercises	Personal study goal to improve IELTS skills	65	lessons	0	\N	2025-10-30	2026-01-31	completed	\N	t	13:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
4f6f45b2-0061-4864-98b2-7319620e31a6	f0000015-0000-0000-0000-000000000015	weekly	Achieve Band 5.0 in Listening	Personal study goal to improve IELTS skills	12	lessons	0	\N	2025-10-25	2025-12-29	completed	\N	t	13:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
b90aebd0-e639-4ead-9f9a-1b31cb54cb00	f0000016-0000-0000-0000-000000000016	weekly	Study 68 minutes daily	Personal study goal to improve IELTS skills	12	lessons	0	reading	2025-10-15	2026-01-22	completed	\N	t	12:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
50b877de-5d46-4865-8531-d0aa43e0623e	f0000017-0000-0000-0000-000000000017	weekly	Study 39 minutes daily	Personal study goal to improve IELTS skills	13	lessons	0	listening	2025-10-19	2025-12-20	completed	\N	t	18:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
593602bb-0f49-441d-9739-b520ff24f72a	f0000018-0000-0000-0000-000000000018	daily	Achieve Band 9.0 in Writing	Personal study goal to improve IELTS skills	8	lessons	0	speaking	2025-10-26	2026-01-05	active	\N	t	10:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
958c9609-e06a-47f5-9cbc-635e40c36c56	f0000019-0000-0000-0000-000000000019	weekly	Study 59 minutes daily	Personal study goal to improve IELTS skills	10	minutes	0	writing	2025-10-27	2025-12-06	completed	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
ddc15673-2806-4b43-91ef-f77e8c9aebeb	f0000020-0000-0000-0000-000000000020	monthly	Study 41 minutes daily	Personal study goal to improve IELTS skills	11	lessons	0	\N	2025-10-26	2026-01-07	completed	\N	t	08:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
51de6096-9bf4-48a5-811d-e6dbb2aa64cc	f0000021-0000-0000-0000-000000000021	daily	Complete 11 exercises	Personal study goal to improve IELTS skills	9	lessons	0	\N	2025-10-23	2026-02-01	completed	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
ce43c23e-9ef8-401f-be13-11cbdbd9980e	f0000022-0000-0000-0000-000000000022	monthly	Complete 4 lessons this week	Personal study goal to improve IELTS skills	90	lessons	0	\N	2025-10-08	2025-12-08	expired	\N	t	19:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
e28dbba3-984e-47e5-a6d9-f08cb89c6ebf	f0000023-0000-0000-0000-000000000023	weekly	Complete 9 exercises	Personal study goal to improve IELTS skills	90	lessons	0	\N	2025-11-03	2025-12-09	completed	\N	t	11:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
9952d606-9329-4000-9276-f4d102551d7b	f0000024-0000-0000-0000-000000000024	monthly	Achieve Band 7.0 in Speaking	Personal study goal to improve IELTS skills	15	lessons	0	writing	2025-10-28	2025-12-31	completed	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
038282a3-ba1d-4e24-8c00-0a935e0a3479	f0000025-0000-0000-0000-000000000025	weekly	Study 80 minutes daily	Personal study goal to improve IELTS skills	11	lessons	0	listening	2025-10-18	2026-01-17	completed	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
4a2a6657-b144-4660-a2f6-34c2551d76bc	f0000026-0000-0000-0000-000000000026	daily	Study 52 minutes daily	Personal study goal to improve IELTS skills	11	lessons	0	\N	2025-10-20	2025-12-11	active	\N	t	10:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
e59d3903-2a7a-45dd-8b32-4dc9b94c1d75	f0000027-0000-0000-0000-000000000027	weekly	Achieve Band 6.0 in Listening	Personal study goal to improve IELTS skills	12	lessons	0	reading	2025-11-01	2025-12-15	active	\N	f	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
afa63c3c-d4da-478b-9a73-8175e0dd8ac2	f0000028-0000-0000-0000-000000000028	weekly	Study 31 minutes daily	Personal study goal to improve IELTS skills	11	lessons	0	\N	2025-10-11	2025-12-07	active	\N	t	10:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
f07a3b6d-c05d-4728-9287-a44748649b0c	f0000029-0000-0000-0000-000000000029	weekly	Achieve Band 7.0 in Speaking	Personal study goal to improve IELTS skills	59	lessons	0	\N	2025-10-16	2025-12-23	active	\N	t	13:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
82613875-09d0-49a9-80d2-a61bddc859b2	f0000030-0000-0000-0000-000000000030	monthly	Study 39 minutes daily	Personal study goal to improve IELTS skills	14	minutes	0	\N	2025-10-13	2025-12-08	expired	\N	t	15:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
c7891289-983b-473c-bae0-69c6e5f07ba5	f0000031-0000-0000-0000-000000000031	daily	Complete 3 lessons this week	Personal study goal to improve IELTS skills	9	lessons	0	speaking	2025-10-27	2025-12-23	expired	\N	f	18:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
32019543-a7d1-41fc-a379-accc89e19b61	f0000032-0000-0000-0000-000000000032	weekly	Complete 15 exercises	Personal study goal to improve IELTS skills	66	lessons	0	\N	2025-10-31	2025-12-12	active	\N	t	17:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
5c57b603-6fcb-48ed-a7e6-38597d057ddb	f0000033-0000-0000-0000-000000000033	monthly	Study 66 minutes daily	Personal study goal to improve IELTS skills	14	lessons	0	\N	2025-10-12	2025-12-29	expired	\N	f	19:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
c0396298-3fec-4852-8a2e-d1864276cf74	f0000034-0000-0000-0000-000000000034	monthly	Study 56 minutes daily	Personal study goal to improve IELTS skills	14	lessons	0	speaking	2025-10-29	2026-01-17	expired	\N	f	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
0bfbbe75-3ce9-4575-9580-70d0f65ac873	f0000035-0000-0000-0000-000000000035	monthly	Study 50 minutes daily	Personal study goal to improve IELTS skills	31	lessons	0	\N	2025-10-23	2026-01-01	expired	\N	t	18:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
9123c2a7-e248-4703-943a-5dd271b5e5c3	f0000036-0000-0000-0000-000000000036	monthly	Achieve Band 7.0 in Reading	Personal study goal to improve IELTS skills	10	lessons	0	writing	2025-11-03	2025-12-15	completed	\N	t	19:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
03d5141b-c8b1-438b-a84f-b21b027aa5e9	f0000037-0000-0000-0000-000000000037	weekly	Study 43 minutes daily	Personal study goal to improve IELTS skills	15	lessons	0	listening	2025-10-06	2025-12-14	expired	\N	t	14:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
78cced74-2727-4c61-a004-83f366ecc863	f0000038-0000-0000-0000-000000000038	monthly	Complete 13 exercises	Personal study goal to improve IELTS skills	75	lessons	0	\N	2025-10-16	2025-12-19	expired	\N	t	12:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
51c3c7ad-b39e-40b6-afd7-18c6bb0aeec1	f0000039-0000-0000-0000-000000000039	weekly	Complete 10 exercises	Personal study goal to improve IELTS skills	30	lessons	0	writing	2025-10-15	2026-01-28	expired	\N	t	13:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
724f3796-b75a-489d-b103-fc44c89e5a62	f0000040-0000-0000-0000-000000000040	daily	Study 52 minutes daily	Personal study goal to improve IELTS skills	57	lessons	0	reading	2025-10-24	2025-12-16	completed	\N	t	11:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
5843917f-4031-47b1-8763-9abc431c1ace	f0000041-0000-0000-0000-000000000041	monthly	Achieve Band 7.0 in Reading	Personal study goal to improve IELTS skills	11	minutes	0	speaking	2025-10-13	2026-01-13	completed	\N	t	18:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
7154167d-89c3-484c-8c07-1293c7edf85d	f0000042-0000-0000-0000-000000000042	monthly	Achieve Band 8.0 in Reading	Personal study goal to improve IELTS skills	12	lessons	0	speaking	2025-10-06	2026-01-03	expired	\N	f	09:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
b51ea79e-0f12-4940-835e-c88be9774fae	f0000043-0000-0000-0000-000000000043	daily	Complete 9 exercises	Personal study goal to improve IELTS skills	46	lessons	0	writing	2025-10-17	2026-01-17	expired	\N	f	09:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
ff670f6e-fcd8-4128-a433-8b98c6a94906	f0000044-0000-0000-0000-000000000044	monthly	Achieve Band 7.0 in Reading	Personal study goal to improve IELTS skills	11	lessons	0	speaking	2025-10-28	2026-01-21	expired	\N	t	11:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
4a7c8b3e-f384-46d1-a7b0-15a215b9f126	f0000045-0000-0000-0000-000000000045	weekly	Complete 9 exercises	Personal study goal to improve IELTS skills	65	minutes	0	\N	2025-10-31	2026-01-21	expired	\N	t	12:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
026cdbf9-c51d-4993-bd3e-1d109cfca9a2	f0000046-0000-0000-0000-000000000046	monthly	Complete 9 exercises	Personal study goal to improve IELTS skills	13	lessons	0	\N	2025-10-08	2026-01-02	active	\N	f	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
3fb26140-aaa6-4f0e-8b11-d4674a99604c	f0000047-0000-0000-0000-000000000047	weekly	Achieve Band 9.0 in Listening	Personal study goal to improve IELTS skills	10	lessons	0	\N	2025-11-02	2026-01-26	active	\N	f	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
b5fb9884-641c-47a7-9521-b26469bce7d7	f0000048-0000-0000-0000-000000000048	monthly	Achieve Band 6.0 in Speaking	Personal study goal to improve IELTS skills	5	lessons	0	writing	2025-10-09	2025-12-10	completed	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
84b50c3d-e0ff-484f-b3ee-debaa894e438	f0000049-0000-0000-0000-000000000049	weekly	Achieve Band 9.0 in Writing	Personal study goal to improve IELTS skills	8	minutes	0	\N	2025-10-22	2025-12-25	active	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
044d56d5-9237-418b-ace7-75d21d5080a8	f0000050-0000-0000-0000-000000000050	monthly	Complete 4 lessons this week	Personal study goal to improve IELTS skills	69	lessons	0	\N	2025-11-02	2026-01-02	completed	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
863edcc3-d3c9-48d0-ae5e-99b389d8afa6	f0000051-0000-0000-0000-000000000051	daily	Complete 11 exercises	Personal study goal to improve IELTS skills	5	minutes	0	writing	2025-11-01	2026-01-06	expired	\N	f	15:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
b3dbabc1-3f2d-4895-85a1-721b5598adba	f0000052-0000-0000-0000-000000000052	weekly	Study 88 minutes daily	Personal study goal to improve IELTS skills	13	lessons	0	\N	2025-10-31	2026-01-30	completed	\N	f	12:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
60ddc499-2060-4e2f-9187-58725fa5553d	f0000053-0000-0000-0000-000000000053	daily	Achieve Band 6.0 in Writing	Personal study goal to improve IELTS skills	89	lessons	0	\N	2025-10-06	2026-01-06	expired	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
319fae72-f04b-4272-ad95-fe735a694a85	f0000054-0000-0000-0000-000000000054	weekly	Study 79 minutes daily	Personal study goal to improve IELTS skills	6	lessons	0	reading	2025-10-25	2025-12-16	expired	\N	f	13:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
70db83db-2b5d-48ad-b7d3-28f3fbefe232	f0000055-0000-0000-0000-000000000055	weekly	Achieve Band 8.0 in Listening	Personal study goal to improve IELTS skills	15	lessons	0	reading	2025-10-20	2026-01-14	active	\N	t	16:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
268e71a6-65fb-42e5-a4ab-bbb0ef393d1e	f0000056-0000-0000-0000-000000000056	monthly	Achieve Band 9.0 in Speaking	Personal study goal to improve IELTS skills	6	lessons	0	reading	2025-10-23	2025-12-19	active	\N	f	18:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
7ada8124-13e3-4a5e-845f-c472b7095419	f0000057-0000-0000-0000-000000000057	monthly	Achieve Band 7.0 in Speaking	Personal study goal to improve IELTS skills	12	lessons	0	writing	2025-10-06	2026-01-11	completed	\N	f	08:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
f0dd680a-9d9e-44cb-a1f2-7c3834d498a8	f0000058-0000-0000-0000-000000000058	weekly	Achieve Band 7.0 in Reading	Personal study goal to improve IELTS skills	7	lessons	0	speaking	2025-10-22	2026-01-22	expired	\N	f	12:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
8e6edc73-de3e-4200-8635-2b7cdb7669ea	f0000059-0000-0000-0000-000000000059	monthly	Achieve Band 8.0 in Listening	Personal study goal to improve IELTS skills	11	lessons	0	writing	2025-10-29	2026-01-28	expired	\N	t	\N	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
cdc526ac-95ea-46d9-948a-7a14034ea41d	f0000060-0000-0000-0000-000000000060	weekly	Achieve Band 9.0 in Speaking	Personal study goal to improve IELTS skills	13	lessons	0	reading	2025-11-02	2026-01-20	expired	\N	t	09:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
61d62f8f-7193-4432-85b7-50344ee8b335	f0000061-0000-0000-0000-000000000061	weekly	Complete 13 exercises	Personal study goal to improve IELTS skills	12	minutes	0	listening	2025-10-17	2025-12-25	active	\N	t	09:00:00	2025-11-04 19:19:45.851151	2025-11-04 19:19:45.851151
17f2b978-2f20-4143-b0fa-46f404869df9	f0000003-0000-0000-0000-000000000003	monthly	1	1	10	exercises	0	\N	2025-11-05	2025-12-05	not_started	\N	f	\N	2025-11-05 14:19:12.682029	2025-11-05 14:19:12.682029
94cbac62-0325-481f-a7dd-3f96517ae69c	f0000003-0000-0000-0000-000000000003	weekly	1	1	10	exercises	0	\N	2025-11-05	2025-11-12	not_started	\N	f	\N	2025-11-05 14:19:49.616344	2025-11-05 14:19:49.616344
96279348-ea10-40e1-b033-30264ce406cd	f0000003-0000-0000-0000-000000000003	weekly	1	1	10	exercises	0	\N	2025-11-05	2025-11-12	not_started	\N	f	\N	2025-11-05 14:23:23.490071	2025-11-05 14:23:23.490071
d4c66088-3986-4d65-bef0-1877e2a732bb	f0000003-0000-0000-0000-000000000003	weekly	1	1	10	exercises	0	\N	2025-11-05	2025-11-12	not_started	\N	f	\N	2025-11-05 14:23:48.191356	2025-11-05 14:23:48.191356
a1a99020-e046-4907-92e9-b2cb85947656	f0000003-0000-0000-0000-000000000003	weekly	1	1	10	exercises	0	\N	2025-11-05	2025-11-12	not_started	\N	f	\N	2025-11-05 14:26:09.59077	2025-11-05 14:26:09.59077
fdf27b98-4704-4231-8afb-80bba6cdc77d	f0000003-0000-0000-0000-000000000003	weekly	1	1	10	exercises	0	\N	2025-11-05	2025-11-12	active	\N	f	\N	2025-11-05 14:38:01.880859	2025-11-05 14:38:01.880859
\.


--
-- Data for Name: study_reminders; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.study_reminders (id, user_id, title, message, reminder_type, reminder_time, days_of_week, is_active, last_sent_at, next_send_at, created_at, updated_at) FROM stdin;
006e73b3-f67e-4523-a5fc-4bce3b7e7f34	f0000001-0000-0000-0000-000000000001	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	12:00:00	{1,2,3,4,5}	t	2025-10-30 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
e901f77d-cfa8-46fd-a355-42405d20239c	f0000002-0000-0000-0000-000000000002	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	14:00:00	{0,1,2,3,4,5,6}	t	2025-11-02 19:19:45.86193	2025-11-05 05:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
b0683f34-1df7-4fe1-b9f4-e75f65e5533d	f0000004-0000-0000-0000-000000000004	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	17:00:00	{1,2,3,4,5}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
08cd827a-5f81-4b6b-b6e9-04e0aca85cd5	f0000005-0000-0000-0000-000000000005	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	09:00:00	{0,1,2,3,4,5,6}	t	\N	2025-11-05 19:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
0266aa0f-1634-46e4-91ab-663510816250	f0000006-0000-0000-0000-000000000006	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	15:00:00	{0,1,2,3,4,5,6}	f	2025-10-28 19:19:45.86193	2025-11-05 04:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
d027d0b9-817f-4fba-91b6-24532a879f2f	f0000007-0000-0000-0000-000000000007	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	20:00:00	{1,2,3,4,5}	f	2025-11-04 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
fc1ecf4d-9a56-4956-91cb-1641bf97ba4e	f0000008-0000-0000-0000-000000000008	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	13:00:00	{1,2,3,4,5}	t	2025-10-28 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
eaec555d-955d-4b3c-a0d6-584fbbc8a311	f0000009-0000-0000-0000-000000000009	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	08:00:00	{0,1,2,3,4,5,6}	t	2025-11-03 19:19:45.86193	2025-11-05 18:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
2d040619-36ee-4efd-a882-8f72b1ccf952	f0000010-0000-0000-0000-000000000010	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	10:00:00	{1,2,3,4,5}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
06d60dbb-8b2c-4718-93aa-f07b09121914	f0000011-0000-0000-0000-000000000011	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	19:00:00	{1,2,3,4,5}	f	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
00a1c398-2e07-4447-8f39-9fac5fd32297	f0000012-0000-0000-0000-000000000012	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	10:00:00	{0,1,2,3,4,5,6}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
b7c71b07-4be6-4967-86cc-72220be0b499	f0000013-0000-0000-0000-000000000013	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	09:00:00	{0,1,2,3,4,5,6}	f	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
cec8576d-259f-4343-a294-76f8188edcf7	f0000014-0000-0000-0000-000000000014	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	17:00:00	{1,2,3,4,5}	t	2025-10-29 19:19:45.86193	2025-11-05 09:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
b6fcf685-05d6-4cac-a1a9-4551b145c25a	f0000015-0000-0000-0000-000000000015	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	13:00:00	{0,1,2,3,4,5,6}	t	\N	2025-11-04 23:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
38847f30-3c41-4cd4-aed2-d542d76af7d2	f0000016-0000-0000-0000-000000000016	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	07:00:00	{0,1,2,3,4,5,6}	t	2025-10-29 19:19:45.86193	2025-11-05 03:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
802bbf0f-7716-4262-80ff-1fa7de1693c5	f0000017-0000-0000-0000-000000000017	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	10:00:00	{0,1,2,3,4,5,6}	t	2025-11-01 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
8997aaa6-f7fe-43e2-b306-9ca5c44db8bc	f0000018-0000-0000-0000-000000000018	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	16:00:00	{0,1,2,3,4,5,6}	t	\N	2025-11-05 07:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
90e2d6f5-f359-4bf5-bf21-b3bbd33da2f4	f0000019-0000-0000-0000-000000000019	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	18:00:00	{0,1,2,3,4,5,6}	t	2025-11-03 19:19:45.86193	2025-11-04 21:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
4d333abc-42c5-44d7-ac89-e08d2d96db03	f0000020-0000-0000-0000-000000000020	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	12:00:00	{0,1,2,3,4,5,6}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
ac144469-f0c5-4051-8bd6-430dc9da4010	f0000021-0000-0000-0000-000000000021	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	08:00:00	{0,1,2,3,4,5,6}	t	2025-11-01 19:19:45.86193	2025-11-05 14:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
b6ad1d48-81b1-4990-983f-cfadb5b554b2	f0000022-0000-0000-0000-000000000022	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	18:00:00	{0,1,2,3,4,5,6}	t	2025-11-04 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
9ae91496-78a1-429f-906e-f3868e8c5134	f0000023-0000-0000-0000-000000000023	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	15:00:00	{0,1,2,3,4,5,6}	t	\N	2025-11-04 23:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
0ea3e0e3-4fc0-46f9-be0a-79fa2d0b5415	f0000024-0000-0000-0000-000000000024	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	20:00:00	{0,1,2,3,4,5,6}	t	2025-11-01 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
2f3f7d3a-ee17-461f-b686-c70922fdcea6	f0000025-0000-0000-0000-000000000025	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	15:00:00	{1,2,3,4,5}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
9b95ff25-5fcd-4bef-ac2b-2b435cfc84a9	f0000026-0000-0000-0000-000000000026	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	13:00:00	{0,1,2,3,4,5,6}	t	\N	2025-11-05 13:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
231525a0-d782-4a01-b8e0-a50a864a9c87	f0000027-0000-0000-0000-000000000027	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	14:00:00	{0,1,2,3,4,5,6}	f	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
f6349d0a-a3fd-4b7c-94d8-9620d21b2782	f0000028-0000-0000-0000-000000000028	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	18:00:00	{1,2,3,4,5}	t	\N	2025-11-05 06:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
d9c12c44-bee4-4eea-b3ac-9b385a18ab5f	f0000029-0000-0000-0000-000000000029	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	13:00:00	{0,1,2,3,4,5,6}	t	\N	2025-11-05 10:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
3e9826d7-6695-44bc-bf0c-d35010fc3bcb	f0000030-0000-0000-0000-000000000030	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	20:00:00	{1,2,3,4,5}	t	\N	2025-11-04 22:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
b6802705-4620-45bc-9fea-a8a70bdc3ee1	f0000031-0000-0000-0000-000000000031	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	17:00:00	{0,1,2,3,4,5,6}	f	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
e78ace1c-4e82-4ccd-a3bd-2e4dc1c8a3e1	f0000032-0000-0000-0000-000000000032	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	19:00:00	{0,1,2,3,4,5,6}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
3dfb7851-2a41-4167-a7fa-361a97ef6bc0	f0000033-0000-0000-0000-000000000033	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	09:00:00	{0,1,2,3,4,5,6}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
52737702-b3f6-4687-bd33-82b78285af2c	f0000034-0000-0000-0000-000000000034	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	14:00:00	{0,1,2,3,4,5,6}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
1ff3d1e4-d4d6-47e5-88ad-8029638b3526	f0000035-0000-0000-0000-000000000035	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	08:00:00	{0,1,2,3,4,5,6}	t	\N	2025-11-05 02:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
17394f5e-e979-46f3-81b7-12cba5141ce1	f0000036-0000-0000-0000-000000000036	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	13:00:00	{1,2,3,4,5}	f	2025-10-29 19:19:45.86193	2025-11-04 21:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
28e136fe-8490-432b-b7b1-d37357e0c0fd	f0000037-0000-0000-0000-000000000037	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	13:00:00	{0,1,2,3,4,5,6}	t	2025-11-01 19:19:45.86193	2025-11-05 11:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
8a5eeb2a-e8f3-479f-8997-7eaf1ed95112	f0000038-0000-0000-0000-000000000038	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	09:00:00	{0,1,2,3,4,5,6}	t	2025-10-29 19:19:45.86193	2025-11-05 12:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
aa7ee165-0bea-4684-8e8d-b0904d8e78f1	f0000039-0000-0000-0000-000000000039	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	21:00:00	{0,1,2,3,4,5,6}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
8d08f25d-3599-4304-99f1-bd3f49f3998a	f0000040-0000-0000-0000-000000000040	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	09:00:00	{1,2,3,4,5}	t	2025-10-30 19:19:45.86193	2025-11-05 03:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
e18d2868-0768-4b60-a2e7-f3b9cde61cc8	f0000041-0000-0000-0000-000000000041	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	20:00:00	{1,2,3,4,5}	t	\N	2025-11-04 23:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
8ff098f5-0d19-45b7-8ff8-4cbbae09c8a0	f0000042-0000-0000-0000-000000000042	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	09:00:00	{1,2,3,4,5}	f	\N	2025-11-05 00:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
27b5d670-cf9c-40e9-b764-ee635554d714	f0000043-0000-0000-0000-000000000043	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	12:00:00	{0,1,2,3,4,5,6}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
f395f85a-4cab-48d2-aa79-466c2511ea1e	f0000044-0000-0000-0000-000000000044	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	11:00:00	{1,2,3,4,5}	f	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
672a0390-cc99-42ff-a83e-f5d9361fe5e3	f0000045-0000-0000-0000-000000000045	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	12:00:00	{0,1,2,3,4,5,6}	f	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
20e99f93-9a84-48e3-afe4-b5fb37c45969	f0000046-0000-0000-0000-000000000046	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	14:00:00	{1,2,3,4,5}	t	2025-10-28 19:19:45.86193	2025-11-05 18:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
b4ad1110-140f-4697-bab3-79e0f403f4fe	f0000047-0000-0000-0000-000000000047	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	16:00:00	{1,2,3,4,5}	t	2025-11-02 19:19:45.86193	2025-11-05 00:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
83df96a4-eb4e-42a3-9128-14488a0f91ce	f0000048-0000-0000-0000-000000000048	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	07:00:00	{0,1,2,3,4,5,6}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
28f80e0a-2337-44f5-97e9-f39f95f063a7	f0000049-0000-0000-0000-000000000049	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	21:00:00	{1,2,3,4,5}	t	\N	2025-11-04 22:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
8fefa588-3281-403e-9d1b-edd1b7e55168	f0000050-0000-0000-0000-000000000050	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	20:00:00	{1,2,3,4,5}	f	2025-10-28 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
2f574131-51b2-4e5a-b346-982d794b0658	f0000051-0000-0000-0000-000000000051	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	08:00:00	{0,1,2,3,4,5,6}	t	2025-11-01 19:19:45.86193	2025-11-05 00:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
3ead941c-4dbc-4903-bd8e-e965ac1408fe	f0000052-0000-0000-0000-000000000052	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	08:00:00	{0,1,2,3,4,5,6}	t	2025-11-01 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
0915280b-7c4d-4c56-9e7f-c75ff7b47346	f0000053-0000-0000-0000-000000000053	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	09:00:00	{0,1,2,3,4,5,6}	t	2025-10-29 19:19:45.86193	2025-11-05 13:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
54d5fcce-bb40-47eb-a964-85ce74327dc6	f0000054-0000-0000-0000-000000000054	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	17:00:00	{0,1,2,3,4,5,6}	t	2025-11-01 19:19:45.86193	2025-11-05 00:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
05196a8e-bf12-4de6-ba54-531baf1bc826	f0000055-0000-0000-0000-000000000055	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	20:00:00	{1,2,3,4,5}	t	2025-10-31 19:19:45.86193	2025-11-05 12:19:45.86193	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
ee1f5f8c-5e27-49dc-9124-656c5a707f88	f0000056-0000-0000-0000-000000000056	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	12:00:00	{0,1,2,3,4,5,6}	t	2025-11-03 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
fb5a23cf-0921-411a-a93c-7645ff6eea11	f0000057-0000-0000-0000-000000000057	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	10:00:00	{0,1,2,3,4,5,6}	t	2025-10-31 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
d82bbec9-9c4a-4c2f-8af8-80d5a78a79ee	f0000058-0000-0000-0000-000000000058	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	07:00:00	{0,1,2,3,4,5,6}	t	2025-11-03 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
a79655c1-902b-4f6c-80ef-89f789755ff1	f0000059-0000-0000-0000-000000000059	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	15:00:00	{1,2,3,4,5}	t	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
0bb9a9ee-3eb9-409a-9ae4-d6f84c1e29a5	f0000060-0000-0000-0000-000000000060	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	daily	17:00:00	{0,1,2,3,4,5,6}	t	2025-10-31 19:19:45.86193	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
74fcc6f5-28eb-4400-bb8b-0ae6f7bba5f1	f0000061-0000-0000-0000-000000000061	Daily Study Reminder	Time to practice IELTS! Complete your daily goals.	weekly	16:00:00	{1,2,3,4,5}	f	\N	\N	2025-11-04 19:19:45.86193	2025-11-04 19:19:45.86193
08eea072-457e-4bce-b9bd-7cbe75797d05	f0000003-0000-0000-0000-000000000003	Morning 	Leanring Speaking	daily	09:00:00	\N	t	\N	\N	2025-11-05 15:18:59.473196	2025-11-05 15:18:59.473196
24f73a30-7660-441e-b49a-34a6c4fe2ab2	f0000003-0000-0000-0000-000000000003	1	1	daily	09:00:00	\N	f	\N	\N	2025-11-05 15:07:03.741343	2025-11-05 15:20:42.659663
a6d2de10-2c15-4a77-8940-a3adf5e7eef9	f0000003-0000-0000-0000-000000000003	3	2	daily	23:00:00	\N	f	\N	\N	2025-11-05 15:08:29.965118	2025-11-05 15:20:50.395883
\.


--
-- Data for Name: study_sessions; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.study_sessions (id, user_id, session_type, skill_type, resource_id, resource_type, started_at, ended_at, duration_minutes, is_completed, completion_percentage, score, device_type, created_at) FROM stdin;
af64026d-9500-4419-baa9-7a185234da1a	f0000001-0000-0000-0000-000000000001	exercise	writing	f3e16d5d-4950-40ec-85b7-720fb4ef1663	exercise	2025-10-17 01:19:45.844725	2025-10-17 02:12:45.844725	53	t	73.83	67.15	web	2025-11-04 19:19:45.844725
d52563dc-b4f4-44d6-b28b-023ba2969dca	f0000001-0000-0000-0000-000000000001	exercise	writing	e214de58-651f-41b4-9f00-10eefdf5b0ba	lesson	2025-10-17 01:19:45.844725	2025-10-17 02:12:45.844725	53	t	98.88	72.86	ios	2025-11-04 19:19:45.844725
6390df8f-dd9e-4970-af52-a9ee9a1dcaf3	f0000001-0000-0000-0000-000000000001	exercise	speaking	dba9d2b0-0442-4c02-b30f-5b543a28305a	lesson	2025-10-17 01:19:45.844725	2025-10-17 02:12:45.844725	53	t	91.76	61.69	ios	2025-11-04 19:19:45.844725
9d3438ea-80a3-47c1-b803-7e0414a805ba	f0000001-0000-0000-0000-000000000001	practice_test	speaking	e9bcd478-59ca-4ba8-8df7-24570e7e7b1f	exercise	2025-10-17 01:19:45.844725	2025-10-17 02:12:45.844725	53	t	70.05	90.49	android	2025-11-04 19:19:45.844725
851280aa-39bb-4e36-913c-3a2a5ba2ca19	f0000001-0000-0000-0000-000000000001	practice_test	speaking	516650a7-9964-496d-a145-027d72b2a6d2	exercise	2025-10-17 01:19:45.844725	2025-10-17 02:12:45.844725	53	f	88.22	83.71	ios	2025-11-04 19:19:45.844725
164428d8-8780-4826-a837-0b30943a8439	f0000002-0000-0000-0000-000000000002	exercise	speaking	f60bea29-2c7a-43a9-bd60-839eeab1a7fe	exercise	2025-10-09 12:19:45.844725	2025-10-09 14:26:45.844725	127	t	71.54	70.21	web	2025-11-04 19:19:45.844725
0bb2dd83-8535-4d0d-94bb-5c96c6cdd902	f0000002-0000-0000-0000-000000000002	exercise	speaking	124033e0-8359-4a50-b65c-c332b4f1c61d	exercise	2025-10-09 12:19:45.844725	2025-10-09 14:26:45.844725	127	f	71.07	\N	ios	2025-11-04 19:19:45.844725
7f9aa9e0-2f3c-47a4-b422-67bcb32a90d7	f0000002-0000-0000-0000-000000000002	practice_test	writing	758a64fa-4099-4405-86d7-1f7483bca6d5	exercise	2025-10-09 12:19:45.844725	2025-10-09 14:26:45.844725	127	f	24.28	95.92	ios	2025-11-04 19:19:45.844725
6e8bb40a-a583-4371-818e-267b09278759	f0000002-0000-0000-0000-000000000002	practice_test	reading	e47652dd-b9d4-464f-822f-cb7bfc73561b	exercise	2025-10-09 12:19:45.844725	2025-10-09 14:26:45.844725	127	t	53.75	97.77	web	2025-11-04 19:19:45.844725
9981eb65-005d-4a77-a92d-46935e5ba44e	f0000002-0000-0000-0000-000000000002	practice_test	reading	87ba9d9f-048b-48b8-a222-5d311572df2b	lesson	2025-10-09 12:19:45.844725	2025-10-09 14:26:45.844725	127	t	94.74	\N	web	2025-11-04 19:19:45.844725
3f7dbc0e-ff29-4e5c-8875-a698c77b5cf5	f0000003-0000-0000-0000-000000000003	practice_test	speaking	70dd9628-83ae-4f90-bde9-ea08e4f420e1	lesson	2025-10-31 00:19:45.844725	2025-10-31 01:59:45.844725	100	t	75.52	73.20	ios	2025-11-04 19:19:45.844725
68097bcc-a850-4b01-933e-941b5e7dcd34	f0000003-0000-0000-0000-000000000003	exercise	writing	5ed7fda6-b562-4bb5-b037-420a05486d17	exercise	2025-10-31 00:19:45.844725	2025-10-31 01:59:45.844725	100	f	96.99	81.86	android	2025-11-04 19:19:45.844725
cbca13c5-61e8-44c0-b1b8-63dc234f968d	f0000003-0000-0000-0000-000000000003	practice_test	reading	a6377e32-3ebe-4876-8aa2-232249b1793a	exercise	2025-10-31 00:19:45.844725	2025-10-31 01:59:45.844725	100	f	75.59	71.85	web	2025-11-04 19:19:45.844725
2076e82b-219a-4119-8f3d-87f755e70fd7	f0000003-0000-0000-0000-000000000003	practice_test	speaking	6d6f05ac-d365-425d-976c-81d177857927	exercise	2025-10-31 00:19:45.844725	2025-10-31 01:59:45.844725	100	t	26.14	\N	web	2025-11-04 19:19:45.844725
3c4eb705-878f-4d8f-b383-ae71a3bb5b80	f0000003-0000-0000-0000-000000000003	practice_test	speaking	62409dfd-dd15-4490-b18c-f33afee8dcf9	lesson	2025-10-31 00:19:45.844725	2025-10-31 01:59:45.844725	100	t	75.74	77.92	ios	2025-11-04 19:19:45.844725
d7e3e59c-10b4-4fd7-88b8-f420eb443cef	f0000004-0000-0000-0000-000000000004	practice_test	writing	c952daab-950d-46fa-a39d-cd38cd5dc64f	exercise	2025-10-10 23:19:45.844725	2025-10-10 23:38:45.844725	19	t	30.68	90.85	android	2025-11-04 19:19:45.844725
7e4ed175-2c84-49df-a4d9-ec820ecd698e	f0000004-0000-0000-0000-000000000004	exercise	speaking	6ee807e1-a5a8-43c1-b4ef-1541e2d58fc0	exercise	2025-10-10 23:19:45.844725	2025-10-10 23:38:45.844725	19	t	70.86	85.03	ios	2025-11-04 19:19:45.844725
da683b4a-5e4b-425f-a0d9-a23de82af70c	f0000004-0000-0000-0000-000000000004	practice_test	speaking	6f37126c-0ae5-4e4a-b82b-5ec861209798	exercise	2025-10-10 23:19:45.844725	2025-10-10 23:38:45.844725	19	t	71.56	94.42	ios	2025-11-04 19:19:45.844725
2d0153b4-9153-449c-bb15-a0efb931c6fc	f0000004-0000-0000-0000-000000000004	exercise	reading	06b8b5dd-fb87-4946-bf86-44e4c09e470a	exercise	2025-10-10 23:19:45.844725	2025-10-10 23:38:45.844725	19	t	89.01	\N	ios	2025-11-04 19:19:45.844725
19e34a9d-a09d-4d7a-81d5-e63ab49636d7	f0000004-0000-0000-0000-000000000004	practice_test	reading	7d48719f-1507-4d09-8409-8adf87c8c9b4	exercise	2025-10-10 23:19:45.844725	2025-10-10 23:38:45.844725	19	t	70.45	\N	ios	2025-11-04 19:19:45.844725
c6b683c9-b406-4ee9-b9c8-48c4a7418535	f0000005-0000-0000-0000-000000000005	lesson	listening	c12dbd20-f7fb-4b15-8330-33d31c561b34	exercise	2025-10-23 15:19:45.844725	2025-10-23 16:38:45.844725	79	t	72.64	69.65	web	2025-11-04 19:19:45.844725
ddc806f7-4c35-4cb2-a1de-153ef9146f38	f0000005-0000-0000-0000-000000000005	practice_test	writing	ec124f46-25e5-4df9-92ba-6f0368ab3986	exercise	2025-10-23 15:19:45.844725	2025-10-23 16:38:45.844725	79	t	90.19	80.90	ios	2025-11-04 19:19:45.844725
a91d37db-5274-422b-b612-a68a26461857	f0000005-0000-0000-0000-000000000005	lesson	writing	885a2413-f2b0-479f-8bd0-dee02d87b38a	exercise	2025-10-23 15:19:45.844725	2025-10-23 16:38:45.844725	79	t	77.99	94.22	web	2025-11-04 19:19:45.844725
5df38051-995d-4a63-bf57-66e143f87c53	f0000005-0000-0000-0000-000000000005	exercise	reading	a04e8a4f-d17a-416a-b2fc-7359f6fae342	exercise	2025-10-23 15:19:45.844725	2025-10-23 16:38:45.844725	79	f	77.41	\N	web	2025-11-04 19:19:45.844725
f70ef317-d9f2-43cc-bb43-7172509d661c	f0000005-0000-0000-0000-000000000005	exercise	reading	87033be6-d084-4acb-94f5-b03d516dade6	exercise	2025-10-23 15:19:45.844725	2025-10-23 16:38:45.844725	79	t	81.64	72.69	ios	2025-11-04 19:19:45.844725
95b6396d-24f9-4960-b96f-c475657b2b46	f0000006-0000-0000-0000-000000000006	lesson	speaking	7331cbb1-adaa-4158-b374-dacf7a0195bd	exercise	2025-10-24 17:19:45.844725	2025-10-24 19:06:45.844725	107	f	9.99	71.23	ios	2025-11-04 19:19:45.844725
eab7e853-5b7b-4ddf-8fd1-15990a583add	f0000006-0000-0000-0000-000000000006	practice_test	listening	82f48723-33c3-4d37-8a50-63d877288cd6	exercise	2025-10-24 17:19:45.844725	2025-10-24 19:06:45.844725	107	t	79.86	95.52	ios	2025-11-04 19:19:45.844725
db4e5cf6-37dd-4a2c-800a-039efe292c0e	f0000006-0000-0000-0000-000000000006	lesson	speaking	22ca71b9-9f96-42dc-b7ea-83447d5d8121	lesson	2025-10-24 17:19:45.844725	2025-10-24 19:06:45.844725	107	t	99.17	82.89	web	2025-11-04 19:19:45.844725
7c8d829e-b582-4916-9408-8d330ed9972b	f0000006-0000-0000-0000-000000000006	practice_test	reading	12454b15-6a26-40ca-af54-f920c2f47a64	exercise	2025-10-24 17:19:45.844725	2025-10-24 19:06:45.844725	107	t	92.07	79.62	android	2025-11-04 19:19:45.844725
1c484850-2ad8-475c-b8a1-74af6e2485ec	f0000006-0000-0000-0000-000000000006	practice_test	writing	57b8080d-6687-4ca9-ab7e-42ec35723694	exercise	2025-10-24 17:19:45.844725	2025-10-24 19:06:45.844725	107	f	21.05	92.70	ios	2025-11-04 19:19:45.844725
b8f11a97-f835-4f4f-9dba-f55ac7ef4d38	f0000007-0000-0000-0000-000000000007	practice_test	reading	814bcfc2-5d00-418b-a973-89cc611c562e	exercise	2025-10-19 02:19:45.844725	2025-10-19 04:16:45.844725	117	t	99.20	65.85	ios	2025-11-04 19:19:45.844725
7ce23021-e263-489b-bad5-8ba16cb82db5	f0000007-0000-0000-0000-000000000007	exercise	speaking	f9142c8a-8dbb-4ca3-8ed4-4d411fc3d89c	exercise	2025-10-19 02:19:45.844725	2025-10-19 04:16:45.844725	117	t	99.35	82.24	android	2025-11-04 19:19:45.844725
337a3065-20dc-46ad-9d09-c6d2bc85d817	f0000007-0000-0000-0000-000000000007	practice_test	speaking	e7877994-34ad-4707-9074-b404cec6640f	exercise	2025-10-19 02:19:45.844725	2025-10-19 04:16:45.844725	117	t	89.90	98.05	ios	2025-11-04 19:19:45.844725
0f523233-9dea-46f0-b66a-369a7381bb1b	f0000007-0000-0000-0000-000000000007	practice_test	speaking	36808dd7-87af-4107-8782-b89bac62b312	exercise	2025-10-19 02:19:45.844725	2025-10-19 04:16:45.844725	117	t	94.76	86.63	web	2025-11-04 19:19:45.844725
c3ba7149-9f91-4197-b825-43370b78e711	f0000007-0000-0000-0000-000000000007	lesson	reading	6c2abffa-8a20-40af-a725-44e3d25196ef	lesson	2025-10-19 02:19:45.844725	2025-10-19 04:16:45.844725	117	t	8.57	94.02	android	2025-11-04 19:19:45.844725
d1fadf7a-ef0b-40b7-92cd-4dd6eb4cbcb9	f0000008-0000-0000-0000-000000000008	lesson	speaking	57cc5e13-7032-42e2-85fb-c28032c1dcc8	exercise	2025-10-08 05:19:45.844725	2025-10-08 06:34:45.844725	75	t	72.71	93.02	web	2025-11-04 19:19:45.844725
89952135-9bbc-43fe-92bb-6a0da65c6e75	f0000008-0000-0000-0000-000000000008	practice_test	writing	2a46baf2-ae5b-4b94-b714-e09e7416b22c	exercise	2025-10-08 05:19:45.844725	2025-10-08 06:34:45.844725	75	t	76.81	84.53	android	2025-11-04 19:19:45.844725
f183647c-08ff-4da2-b07c-13d5ca7407b0	f0000008-0000-0000-0000-000000000008	exercise	listening	49918303-23a1-4882-b633-b6e243c6778d	lesson	2025-10-08 05:19:45.844725	2025-10-08 06:34:45.844725	75	t	76.78	\N	android	2025-11-04 19:19:45.844725
57af1135-05b1-4977-82e5-d6d1895cbd42	f0000008-0000-0000-0000-000000000008	practice_test	speaking	af66e492-7e76-411b-85ae-598d0b6853ec	exercise	2025-10-08 05:19:45.844725	2025-10-08 06:34:45.844725	75	t	95.69	\N	ios	2025-11-04 19:19:45.844725
07dccb05-c96c-4524-b0d2-a56d059fa365	f0000008-0000-0000-0000-000000000008	lesson	speaking	ad8ca7f8-cbd2-4663-89c0-a69d1862ec52	exercise	2025-10-08 05:19:45.844725	2025-10-08 06:34:45.844725	75	t	77.46	98.40	ios	2025-11-04 19:19:45.844725
581da313-0e36-4922-8740-77ac7fb90eb9	f0000009-0000-0000-0000-000000000009	exercise	writing	37d7b6b6-4704-4af7-b4a5-2c7793770bf3	exercise	2025-10-30 04:19:45.844725	2025-10-30 05:46:45.844725	87	f	85.85	83.39	ios	2025-11-04 19:19:45.844725
6c9c3442-0549-48f9-abcf-60bdf7ff649d	f0000009-0000-0000-0000-000000000009	lesson	reading	139f9b91-d31d-454a-8ffa-e3aca2355026	lesson	2025-10-30 04:19:45.844725	2025-10-30 05:46:45.844725	87	t	25.89	79.23	ios	2025-11-04 19:19:45.844725
b17ae783-6d94-47d7-89dc-02ea1a978979	f0000009-0000-0000-0000-000000000009	practice_test	speaking	edfada9a-6782-4519-b86a-de434e086e5a	exercise	2025-10-30 04:19:45.844725	2025-10-30 05:46:45.844725	87	t	97.13	94.90	android	2025-11-04 19:19:45.844725
310a038a-6150-4ef2-abff-ceeb9dccf4de	f0000009-0000-0000-0000-000000000009	exercise	listening	e41c2230-7b23-4c66-9ca0-3d863d58d5ac	lesson	2025-10-30 04:19:45.844725	2025-10-30 05:46:45.844725	87	f	4.37	\N	ios	2025-11-04 19:19:45.844725
595b45e2-4a04-4010-aede-2f9e5db14155	f0000009-0000-0000-0000-000000000009	practice_test	reading	4f19178e-0c74-4003-a17f-fa0f25c3d17a	lesson	2025-10-30 04:19:45.844725	2025-10-30 05:46:45.844725	87	t	73.43	\N	android	2025-11-04 19:19:45.844725
ac53fb9e-be6d-4a31-8654-e449a0967ee6	f0000010-0000-0000-0000-000000000010	lesson	writing	76eb6f56-0445-4e2b-8070-e3178cae8f76	exercise	2025-10-09 02:19:45.844725	2025-10-09 03:56:45.844725	97	t	77.30	\N	ios	2025-11-04 19:19:45.844725
7cb49f54-f5a2-43f7-97b0-4aafcb75cb63	f0000010-0000-0000-0000-000000000010	practice_test	writing	c22419f2-c36c-4767-9b5b-3456cd71273b	lesson	2025-10-09 02:19:45.844725	2025-10-09 03:56:45.844725	97	t	94.85	\N	web	2025-11-04 19:19:45.844725
ab9b3cfc-503d-41cf-9010-05bed0babede	f0000010-0000-0000-0000-000000000010	exercise	writing	6e854a04-9577-484b-9aec-dbe9eab309a5	lesson	2025-10-09 02:19:45.844725	2025-10-09 03:56:45.844725	97	t	76.30	93.70	ios	2025-11-04 19:19:45.844725
5bba6527-75a5-479c-a016-0aebe9a90ada	f0000010-0000-0000-0000-000000000010	practice_test	writing	a6d7185f-d4c9-4218-af09-86f981549973	exercise	2025-10-09 02:19:45.844725	2025-10-09 03:56:45.844725	97	t	91.60	60.33	ios	2025-11-04 19:19:45.844725
cecfdce4-8d61-4d81-a30d-a1ac5cb183d2	f0000010-0000-0000-0000-000000000010	practice_test	writing	4ddbf944-bcaf-457b-a9fa-f5237917e75e	lesson	2025-10-09 02:19:45.844725	2025-10-09 03:56:45.844725	97	t	87.06	\N	ios	2025-11-04 19:19:45.844725
e80069b9-ab1c-437b-a6c0-4de3d95838d8	f0000011-0000-0000-0000-000000000011	practice_test	reading	5cfd01f0-078b-4018-9c35-678749306f67	exercise	2025-10-07 14:19:45.844725	2025-10-07 15:41:45.844725	82	t	14.65	\N	android	2025-11-04 19:19:45.844725
ddcb3efa-962a-437c-817e-51d44a68c741	f0000011-0000-0000-0000-000000000011	practice_test	speaking	09ea5ae5-b7b6-4042-a14d-8699b63e7bfc	lesson	2025-10-07 14:19:45.844725	2025-10-07 15:41:45.844725	82	t	71.24	75.66	web	2025-11-04 19:19:45.844725
090372ff-9c27-406b-bce0-8521fd59b272	f0000011-0000-0000-0000-000000000011	practice_test	writing	ba7ac4d6-9f1f-401f-a923-48ce372de343	exercise	2025-10-07 14:19:45.844725	2025-10-07 15:41:45.844725	82	t	96.19	65.57	android	2025-11-04 19:19:45.844725
fbebdfb1-55dc-468b-b0e9-bfc835617643	f0000011-0000-0000-0000-000000000011	practice_test	reading	c6b561b9-4613-48c7-8743-5efb11bd8afa	exercise	2025-10-07 14:19:45.844725	2025-10-07 15:41:45.844725	82	f	81.97	69.77	ios	2025-11-04 19:19:45.844725
7148dc26-943e-41ef-843b-ae95bfe597b6	f0000011-0000-0000-0000-000000000011	exercise	reading	c3238855-7338-4c03-9d07-e32729552ba6	exercise	2025-10-07 14:19:45.844725	2025-10-07 15:41:45.844725	82	t	79.93	85.71	ios	2025-11-04 19:19:45.844725
44d29fa2-84e9-4f9f-8823-f2a630a6c219	f0000012-0000-0000-0000-000000000012	practice_test	listening	ca3bac8d-f456-4d0b-805e-b1d325eaff25	exercise	2025-10-14 14:19:45.844725	2025-10-14 15:21:45.844725	62	t	71.81	88.16	ios	2025-11-04 19:19:45.844725
b34d4c36-bdc8-46d4-bdfc-213efd2b7757	f0000012-0000-0000-0000-000000000012	practice_test	speaking	6a3a7c78-4f4e-4193-86e8-59a5380e7437	exercise	2025-10-14 14:19:45.844725	2025-10-14 15:21:45.844725	62	t	72.73	93.78	ios	2025-11-04 19:19:45.844725
fac34fd5-46a4-4778-b1b6-991714f3265a	f0000012-0000-0000-0000-000000000012	practice_test	reading	c4283615-1648-420a-8a0c-a94462926a9f	exercise	2025-10-14 14:19:45.844725	2025-10-14 15:21:45.844725	62	t	97.35	60.04	android	2025-11-04 19:19:45.844725
47e8fd2b-c1ee-4524-b5f8-1d542b7c633a	f0000012-0000-0000-0000-000000000012	practice_test	reading	6f20e0ff-888d-4363-8d3f-9c81ba5167de	exercise	2025-10-14 14:19:45.844725	2025-10-14 15:21:45.844725	62	t	94.28	97.91	android	2025-11-04 19:19:45.844725
a2bb07fa-383e-40c6-ba7b-8871064d6904	f0000012-0000-0000-0000-000000000012	practice_test	writing	4f2a5fa3-8af1-4c8d-beae-8a6bb9bd193a	exercise	2025-10-14 14:19:45.844725	2025-10-14 15:21:45.844725	62	t	95.09	69.65	ios	2025-11-04 19:19:45.844725
13acedcf-8e9e-4011-88bb-792ed008bf1c	f0000013-0000-0000-0000-000000000013	practice_test	speaking	ed81f7fe-2722-442c-8eac-34236decb152	lesson	2025-10-18 18:19:45.844725	2025-10-18 18:59:45.844725	40	t	76.53	89.33	ios	2025-11-04 19:19:45.844725
ce646024-cc0d-4b4f-93d2-b5e3483fc144	f0000013-0000-0000-0000-000000000013	exercise	writing	081440e5-a78d-4289-b31f-16720650ea4b	lesson	2025-10-18 18:19:45.844725	2025-10-18 18:59:45.844725	40	t	85.60	78.76	ios	2025-11-04 19:19:45.844725
f26e8027-2aff-4b60-81cf-b9597dff1a25	f0000013-0000-0000-0000-000000000013	practice_test	speaking	e86da002-3b06-455e-a442-8bf547d987d6	exercise	2025-10-18 18:19:45.844725	2025-10-18 18:59:45.844725	40	t	80.49	67.60	ios	2025-11-04 19:19:45.844725
065968d0-0188-4a03-88d6-77c7005cf679	f0000013-0000-0000-0000-000000000013	lesson	reading	ac2e1422-3450-45fe-a7a0-9b59186add4e	lesson	2025-10-18 18:19:45.844725	2025-10-18 18:59:45.844725	40	t	91.73	\N	web	2025-11-04 19:19:45.844725
c93727c7-f663-40ee-8915-d9b9e01aeb0e	f0000013-0000-0000-0000-000000000013	lesson	reading	817d3e96-ddfd-4bc5-89bc-432c473cc4da	exercise	2025-10-18 18:19:45.844725	2025-10-18 18:59:45.844725	40	t	71.93	\N	ios	2025-11-04 19:19:45.844725
fb9e6aa9-85cf-4a37-a923-d1802b9744ee	f0000014-0000-0000-0000-000000000014	practice_test	reading	c519293b-0edc-48f4-99f5-9e18b9440153	exercise	2025-10-09 17:19:45.844725	2025-10-09 18:04:45.844725	45	t	82.67	\N	web	2025-11-04 19:19:45.844725
afb54140-82ac-49bd-a635-130cfa00eda6	f0000014-0000-0000-0000-000000000014	practice_test	writing	82429844-d897-4a63-83e9-af94bd9a9f94	exercise	2025-10-09 17:19:45.844725	2025-10-09 18:04:45.844725	45	t	76.41	76.02	ios	2025-11-04 19:19:45.844725
3a75ae43-e6fc-43ce-8875-f9c5e172afe5	f0000014-0000-0000-0000-000000000014	practice_test	speaking	c99eae95-bd98-4c4b-b773-f5a03cf3c706	exercise	2025-10-09 17:19:45.844725	2025-10-09 18:04:45.844725	45	t	80.21	69.56	ios	2025-11-04 19:19:45.844725
89595ba9-138c-4090-aa0a-27872b3d3811	f0000014-0000-0000-0000-000000000014	practice_test	speaking	122c28d3-a939-4f67-a457-b168214c110a	exercise	2025-10-09 17:19:45.844725	2025-10-09 18:04:45.844725	45	t	27.92	61.11	web	2025-11-04 19:19:45.844725
01155761-6cac-4d82-9f01-b47b7db0f1e6	f0000014-0000-0000-0000-000000000014	exercise	reading	990b97f3-ea44-44d8-a4d7-7515f35789c4	exercise	2025-10-09 17:19:45.844725	2025-10-09 18:04:45.844725	45	t	46.60	65.73	ios	2025-11-04 19:19:45.844725
b6f6b7cc-1257-4220-94e7-e984acd20d01	f0000015-0000-0000-0000-000000000015	exercise	reading	d25181f8-e235-4300-b8e7-f8d85ab533f3	exercise	2025-10-19 10:19:45.844725	2025-10-19 11:19:45.844725	60	t	84.21	\N	android	2025-11-04 19:19:45.844725
6132e305-1561-4033-9875-6434bb02bb8c	f0000015-0000-0000-0000-000000000015	lesson	writing	3cfb9ae7-d5d7-4092-971b-24f642d0516c	exercise	2025-10-19 10:19:45.844725	2025-10-19 11:19:45.844725	60	f	3.80	68.42	ios	2025-11-04 19:19:45.844725
a3cd2d95-599c-4542-9ed1-e7b9ef6033d8	f0000015-0000-0000-0000-000000000015	practice_test	writing	9fa05873-ee4f-4cee-9358-6acb959f73f0	lesson	2025-10-19 10:19:45.844725	2025-10-19 11:19:45.844725	60	t	87.94	80.27	ios	2025-11-04 19:19:45.844725
5363ff14-87f9-4304-89cb-4952adfb9a96	f0000015-0000-0000-0000-000000000015	practice_test	reading	f0db27d2-772e-44f0-81ae-b509b7cbcb84	exercise	2025-10-19 10:19:45.844725	2025-10-19 11:19:45.844725	60	t	34.42	97.85	web	2025-11-04 19:19:45.844725
c9a23b5c-b10b-44ae-bda7-9326393ca151	f0000015-0000-0000-0000-000000000015	lesson	speaking	014ee00f-9a36-481c-b22c-8dd35309ced5	lesson	2025-10-19 10:19:45.844725	2025-10-19 11:19:45.844725	60	t	74.97	79.55	ios	2025-11-04 19:19:45.844725
51438843-bfe4-4e89-b958-a6ba3f26034e	f0000016-0000-0000-0000-000000000016	practice_test	reading	8876fdba-bbb8-458b-8bfd-00841dfe3958	exercise	2025-10-09 02:19:45.844725	2025-10-09 03:46:45.844725	87	f	9.72	\N	ios	2025-11-04 19:19:45.844725
642216ce-256a-40e3-9b5b-fc17e036f895	f0000016-0000-0000-0000-000000000016	practice_test	reading	ef90c121-0ee6-4de3-9edc-ec10997dd191	exercise	2025-10-09 02:19:45.844725	2025-10-09 03:46:45.844725	87	t	86.49	\N	android	2025-11-04 19:19:45.844725
91f76856-58b4-45eb-9b8a-5e6ace7cdc71	f0000016-0000-0000-0000-000000000016	lesson	writing	3f273828-5449-4980-bb3b-0d1873854a7d	exercise	2025-10-09 02:19:45.844725	2025-10-09 03:46:45.844725	87	t	82.69	73.58	ios	2025-11-04 19:19:45.844725
e71781ec-948e-4d74-a54d-bb42e5fb9c26	f0000016-0000-0000-0000-000000000016	practice_test	speaking	52166755-60b5-41ca-96f3-4f2b8d280cfa	exercise	2025-10-09 02:19:45.844725	2025-10-09 03:46:45.844725	87	t	31.76	62.07	android	2025-11-04 19:19:45.844725
6a62c1f8-c915-4778-8261-da010c61e780	f0000016-0000-0000-0000-000000000016	practice_test	writing	7e9095ec-3e3e-42e2-abbf-706df8c9310d	lesson	2025-10-09 02:19:45.844725	2025-10-09 03:46:45.844725	87	t	35.83	\N	ios	2025-11-04 19:19:45.844725
89a9bb04-04fb-4593-8654-f0f2ad24b2f3	f0000017-0000-0000-0000-000000000017	exercise	writing	e4db1931-0091-4913-bb2c-7156edadaba1	lesson	2025-10-18 01:19:45.844725	2025-10-18 02:22:45.844725	63	t	95.23	68.74	android	2025-11-04 19:19:45.844725
7f1d8e16-95dd-4d1a-ac19-4fbc779ae931	f0000017-0000-0000-0000-000000000017	lesson	speaking	11081409-965f-4c52-a70b-564fe11726c5	lesson	2025-10-18 01:19:45.844725	2025-10-18 02:22:45.844725	63	t	85.13	77.19	ios	2025-11-04 19:19:45.844725
6587815c-cbe3-4129-a150-b434aea785e1	f0000017-0000-0000-0000-000000000017	exercise	speaking	4f8d972f-9b40-4316-9cc9-a9bbb7996aba	exercise	2025-10-18 01:19:45.844725	2025-10-18 02:22:45.844725	63	t	82.60	79.91	ios	2025-11-04 19:19:45.844725
66163eca-4226-4919-bd19-070042643a5d	f0000017-0000-0000-0000-000000000017	exercise	speaking	afe7fa0e-a577-424f-aa02-bb174d8b1d77	exercise	2025-10-18 01:19:45.844725	2025-10-18 02:22:45.844725	63	t	76.11	83.38	ios	2025-11-04 19:19:45.844725
aa854535-627d-43ea-85db-79a536d2d458	f0000017-0000-0000-0000-000000000017	exercise	speaking	e07c1edc-9512-4670-ac5f-72dfcb463722	exercise	2025-10-18 01:19:45.844725	2025-10-18 02:22:45.844725	63	t	86.10	\N	web	2025-11-04 19:19:45.844725
df9f1da1-bd60-4310-8a74-aefe01cdc9f1	f0000018-0000-0000-0000-000000000018	exercise	reading	aaced367-df7e-40bf-ba7e-d5d5b56cafe6	exercise	2025-10-25 05:19:45.844725	2025-10-25 06:49:45.844725	90	t	56.45	75.17	ios	2025-11-04 19:19:45.844725
c421ccec-12a1-4173-9271-e91651e44784	f0000018-0000-0000-0000-000000000018	practice_test	writing	5c3d43ef-6498-4ff3-907b-28e2ee362666	exercise	2025-10-25 05:19:45.844725	2025-10-25 06:49:45.844725	90	t	88.45	\N	ios	2025-11-04 19:19:45.844725
d704f9fc-f688-485e-a482-89fc3fe3a12c	f0000018-0000-0000-0000-000000000018	practice_test	speaking	995f106a-bd48-4e09-b08a-16e8c5a59629	exercise	2025-10-25 05:19:45.844725	2025-10-25 06:49:45.844725	90	f	92.87	80.38	ios	2025-11-04 19:19:45.844725
f92a1c86-e042-4b66-964c-3e45cf14f924	f0000018-0000-0000-0000-000000000018	practice_test	reading	b0508872-5fe7-4686-b2b2-1d15fb592ee5	exercise	2025-10-25 05:19:45.844725	2025-10-25 06:49:45.844725	90	f	91.96	\N	android	2025-11-04 19:19:45.844725
65e662aa-7a9d-4a51-8fae-c91369959e84	f0000018-0000-0000-0000-000000000018	practice_test	speaking	79e28fd0-0132-4626-9a7a-5779196ce5e2	exercise	2025-10-25 05:19:45.844725	2025-10-25 06:49:45.844725	90	f	37.11	74.73	ios	2025-11-04 19:19:45.844725
b6d1856d-36a7-4d7a-bd7a-f01a42cb64e7	f0000019-0000-0000-0000-000000000019	practice_test	listening	6a61da36-681a-4153-b015-9b00eeeb46d0	exercise	2025-10-15 17:19:45.844725	2025-10-15 19:33:45.844725	134	t	92.71	78.13	ios	2025-11-04 19:19:45.844725
7f0d0e04-8200-4554-9f0d-588f9abf8fce	f0000019-0000-0000-0000-000000000019	exercise	speaking	b92d877b-a733-4493-951d-d70d5c0543fa	exercise	2025-10-15 17:19:45.844725	2025-10-15 19:33:45.844725	134	t	34.62	88.64	android	2025-11-04 19:19:45.844725
8741e6b7-7d79-4cfd-9d3a-5bfb466102f6	f0000019-0000-0000-0000-000000000019	practice_test	listening	16b0409f-56ee-4dd6-9064-aa1112a30dea	exercise	2025-10-15 17:19:45.844725	2025-10-15 19:33:45.844725	134	t	85.93	\N	ios	2025-11-04 19:19:45.844725
1d943445-36c0-4b52-8c5c-31954e624929	f0000019-0000-0000-0000-000000000019	exercise	speaking	d172b77a-ef96-42b2-abce-7c3106d6d82b	exercise	2025-10-15 17:19:45.844725	2025-10-15 19:33:45.844725	134	t	94.04	72.46	android	2025-11-04 19:19:45.844725
d455a462-f7df-43b2-a5ea-ec664ed65e52	f0000019-0000-0000-0000-000000000019	practice_test	speaking	cfc5cc6b-7976-4213-84f9-1bef634c926d	lesson	2025-10-15 17:19:45.844725	2025-10-15 19:33:45.844725	134	f	77.01	\N	ios	2025-11-04 19:19:45.844725
997b9f20-d9df-497a-b7e4-9e58fed32f49	f0000020-0000-0000-0000-000000000020	exercise	speaking	0ffaf8ea-d2b4-4ece-8711-61d813209692	exercise	2025-10-25 13:19:45.844725	2025-10-25 13:47:45.844725	28	t	93.40	97.41	ios	2025-11-04 19:19:45.844725
a1fe4c24-9cc7-4889-beb8-0111fd90334f	f0000020-0000-0000-0000-000000000020	practice_test	writing	938c88c4-a5f2-4b62-861d-1832a31ec685	exercise	2025-10-25 13:19:45.844725	2025-10-25 13:47:45.844725	28	f	94.39	76.75	android	2025-11-04 19:19:45.844725
ffeeb89c-d02a-4c5e-88e8-fe9e1d6763a2	f0000020-0000-0000-0000-000000000020	exercise	speaking	94c11f19-b79f-4633-89dd-d9a68a3325bd	exercise	2025-10-25 13:19:45.844725	2025-10-25 13:47:45.844725	28	f	79.54	\N	android	2025-11-04 19:19:45.844725
fd71aa08-9820-4f76-b1d3-555d499f95a8	f0000020-0000-0000-0000-000000000020	practice_test	writing	33d1d425-dbd5-4bbe-b859-e158ec804c14	exercise	2025-10-25 13:19:45.844725	2025-10-25 13:47:45.844725	28	t	79.80	75.95	web	2025-11-04 19:19:45.844725
40bcf627-0b44-404f-8b16-1fea668e6a07	f0000020-0000-0000-0000-000000000020	lesson	listening	72582791-8067-4e87-b3cf-dd263c622e97	exercise	2025-10-25 13:19:45.844725	2025-10-25 13:47:45.844725	28	t	77.03	61.21	ios	2025-11-04 19:19:45.844725
bcd76a83-01a6-478d-b3ee-8b8c28591f85	f0000021-0000-0000-0000-000000000021	practice_test	reading	0905d8c5-c0e4-4978-8faa-d674db792eb7	exercise	2025-10-05 21:19:45.844725	2025-10-05 22:39:45.844725	80	t	76.53	\N	web	2025-11-04 19:19:45.844725
6b1851a8-3d32-46ee-aff7-9f66a6a3a5b8	f0000021-0000-0000-0000-000000000021	practice_test	speaking	03c480e9-6b4c-41d1-918a-a4c736ecb85e	exercise	2025-10-05 21:19:45.844725	2025-10-05 22:39:45.844725	80	f	91.38	\N	web	2025-11-04 19:19:45.844725
cc9c894b-6dad-4a8a-a3d2-654175af142b	f0000021-0000-0000-0000-000000000021	practice_test	listening	bfd08930-813f-4502-82b3-c8195cb7376c	lesson	2025-10-05 21:19:45.844725	2025-10-05 22:39:45.844725	80	f	93.91	69.86	ios	2025-11-04 19:19:45.844725
7aea37da-0266-451d-8d23-9f4e47d14417	f0000021-0000-0000-0000-000000000021	exercise	speaking	f26ddc5c-99f2-4b3e-9199-633c86e24cf4	exercise	2025-10-05 21:19:45.844725	2025-10-05 22:39:45.844725	80	t	87.87	\N	web	2025-11-04 19:19:45.844725
180c3ca6-71ca-4f10-a6d9-1a1849d2389d	f0000021-0000-0000-0000-000000000021	practice_test	reading	1507b429-e4c5-4b9e-b1f6-5dd6b46d58ad	exercise	2025-10-05 21:19:45.844725	2025-10-05 22:39:45.844725	80	t	83.84	67.53	ios	2025-11-04 19:19:45.844725
8fcfcc38-6b6a-4a79-b5a9-759e35bd5838	f0000022-0000-0000-0000-000000000022	practice_test	writing	c684b0d9-0f78-4d7e-bcc6-bd51a0d2e29c	exercise	2025-10-30 08:19:45.844725	2025-10-30 09:44:45.844725	85	f	8.03	97.07	android	2025-11-04 19:19:45.844725
6401520b-875f-47d2-8d29-4f8b580069e8	f0000022-0000-0000-0000-000000000022	exercise	writing	337da42a-746d-449c-bb73-8c2cb413da71	exercise	2025-10-30 08:19:45.844725	2025-10-30 09:44:45.844725	85	t	51.14	67.48	android	2025-11-04 19:19:45.844725
abf599f6-85f6-4594-a682-9875aae01b91	f0000022-0000-0000-0000-000000000022	practice_test	speaking	726e9f2e-dc98-4a75-84bf-e63c9197b1e8	exercise	2025-10-30 08:19:45.844725	2025-10-30 09:44:45.844725	85	t	95.66	96.35	ios	2025-11-04 19:19:45.844725
33beec35-7c0d-42e6-a5db-725e4f871e81	f0000022-0000-0000-0000-000000000022	lesson	reading	9a6e0ab1-a24e-471b-b13f-4cefc152c970	lesson	2025-10-30 08:19:45.844725	2025-10-30 09:44:45.844725	85	t	71.40	90.71	ios	2025-11-04 19:19:45.844725
433659d5-f2eb-4cb0-ad54-82732e457945	f0000022-0000-0000-0000-000000000022	practice_test	speaking	28b6c5bd-b9a0-4edd-863f-3ee1fff56af3	exercise	2025-10-30 08:19:45.844725	2025-10-30 09:44:45.844725	85	f	41.19	68.28	ios	2025-11-04 19:19:45.844725
9d927224-ac58-4385-80b1-cbd9a74705e0	f0000023-0000-0000-0000-000000000023	exercise	writing	43f6635c-94fd-4bd2-a3a1-069b34672d82	exercise	2025-10-07 11:19:45.844725	2025-10-07 13:13:45.844725	114	t	47.02	86.23	android	2025-11-04 19:19:45.844725
3040434e-3c63-47d6-a8c2-41b500b7d6ef	f0000023-0000-0000-0000-000000000023	exercise	writing	e3bc963c-a04e-4218-baa6-addce04ac353	exercise	2025-10-07 11:19:45.844725	2025-10-07 13:13:45.844725	114	t	81.73	\N	android	2025-11-04 19:19:45.844725
bde535f7-30d8-45e6-a13a-1aef7157511a	f0000023-0000-0000-0000-000000000023	exercise	writing	70bc4450-2b60-47f8-a312-6aff1585b6cf	exercise	2025-10-07 11:19:45.844725	2025-10-07 13:13:45.844725	114	t	45.70	\N	android	2025-11-04 19:19:45.844725
bfac8bdc-6d21-4d1d-993b-f9981a3ad7ec	f0000023-0000-0000-0000-000000000023	exercise	listening	7bc3cb4e-c2f5-4084-ab85-a741bc7a5355	exercise	2025-10-07 11:19:45.844725	2025-10-07 13:13:45.844725	114	t	76.89	\N	ios	2025-11-04 19:19:45.844725
edcc2f31-c773-4998-9e7f-8e5f74fc6c5e	f0000023-0000-0000-0000-000000000023	lesson	listening	936d38a5-d8ab-4b4e-bb05-a10f832fd86c	exercise	2025-10-07 11:19:45.844725	2025-10-07 13:13:45.844725	114	t	85.62	73.87	ios	2025-11-04 19:19:45.844725
99ad7bb6-603d-4e60-9237-2a751b8c3b4f	f0000024-0000-0000-0000-000000000024	exercise	reading	6cb64711-efcb-495e-971b-8afec6858fd6	exercise	2025-10-16 15:19:45.844725	2025-10-16 16:56:45.844725	97	t	39.03	93.35	web	2025-11-04 19:19:45.844725
e3ecaa43-5423-426d-9549-2544ea372458	f0000024-0000-0000-0000-000000000024	lesson	writing	9bbeffee-2416-491c-bd44-cc2a972e6968	exercise	2025-10-16 15:19:45.844725	2025-10-16 16:56:45.844725	97	t	98.56	74.05	ios	2025-11-04 19:19:45.844725
aec8ba7d-d554-436c-bacd-30216312373e	f0000024-0000-0000-0000-000000000024	exercise	speaking	42ed8772-30c9-4233-92f4-e5697207b9c7	exercise	2025-10-16 15:19:45.844725	2025-10-16 16:56:45.844725	97	t	75.81	\N	android	2025-11-04 19:19:45.844725
dfc2ee46-da29-4eea-91cf-ec9f5693bcc7	f0000024-0000-0000-0000-000000000024	practice_test	listening	29e6d616-302a-45c0-b2d9-475981c5eeba	exercise	2025-10-16 15:19:45.844725	2025-10-16 16:56:45.844725	97	t	55.78	79.10	android	2025-11-04 19:19:45.844725
0aa589c7-19fa-4887-ac34-97e946f836d1	f0000024-0000-0000-0000-000000000024	exercise	reading	eefa7cbe-4c7a-40ba-b8b9-a32cf5b3afca	lesson	2025-10-16 15:19:45.844725	2025-10-16 16:56:45.844725	97	t	90.51	\N	ios	2025-11-04 19:19:45.844725
eb201167-8c30-47f5-ac0b-ecf82e728caa	f0000025-0000-0000-0000-000000000025	lesson	speaking	ca9f9df3-ed0c-4aea-aef2-696b3503a024	lesson	2025-10-09 13:19:45.844725	2025-10-09 14:18:45.844725	59	t	85.02	70.18	ios	2025-11-04 19:19:45.844725
76eef1f0-fa73-47e0-89c6-1d4b497a324d	f0000025-0000-0000-0000-000000000025	practice_test	writing	8e20b0cd-164a-4c78-8d03-076615797df3	lesson	2025-10-09 13:19:45.844725	2025-10-09 14:18:45.844725	59	t	71.76	\N	ios	2025-11-04 19:19:45.844725
f8f59924-7890-4786-83e6-c86bd473f5d3	f0000025-0000-0000-0000-000000000025	practice_test	speaking	f37a9c08-d3e8-4e3b-be3b-ad1e0168613c	exercise	2025-10-09 13:19:45.844725	2025-10-09 14:18:45.844725	59	f	78.89	\N	ios	2025-11-04 19:19:45.844725
52e036eb-2682-4f7b-b286-2034b02bcdb7	f0000025-0000-0000-0000-000000000025	practice_test	speaking	3bbc2da2-d8fa-4d87-8156-de98a9e9b3e9	exercise	2025-10-09 13:19:45.844725	2025-10-09 14:18:45.844725	59	t	87.22	75.38	android	2025-11-04 19:19:45.844725
6e46f991-9e86-4a35-92b6-5f3af8916d39	f0000025-0000-0000-0000-000000000025	exercise	speaking	7e3998e9-4b80-4448-97d2-b6daf20c1a43	exercise	2025-10-09 13:19:45.844725	2025-10-09 14:18:45.844725	59	t	54.27	86.86	web	2025-11-04 19:19:45.844725
ffd2930d-c218-42bd-b7fc-be7e75ff8e79	f0000026-0000-0000-0000-000000000026	exercise	speaking	1bda1f3c-4ec8-44e6-969f-77519d217e07	exercise	2025-10-06 03:19:45.844725	2025-10-06 03:41:45.844725	22	t	84.37	74.63	android	2025-11-04 19:19:45.844725
290ee0f7-de2d-4218-a1ff-8327fdb25071	f0000026-0000-0000-0000-000000000026	practice_test	writing	7f0e90d4-f812-4330-b7ed-1eb9ec9db42e	lesson	2025-10-06 03:19:45.844725	2025-10-06 03:41:45.844725	22	t	74.72	97.04	android	2025-11-04 19:19:45.844725
828cfb74-8ade-496c-aa64-8ef074057a73	f0000026-0000-0000-0000-000000000026	exercise	writing	ce65db7b-ad03-44a3-af51-10893b377b38	exercise	2025-10-06 03:19:45.844725	2025-10-06 03:41:45.844725	22	t	72.48	89.52	android	2025-11-04 19:19:45.844725
e6576335-533e-488e-bdb7-837575c592bc	f0000026-0000-0000-0000-000000000026	exercise	speaking	774208bc-03cf-44a6-803b-cdd31ccd600e	exercise	2025-10-06 03:19:45.844725	2025-10-06 03:41:45.844725	22	t	95.44	64.72	ios	2025-11-04 19:19:45.844725
220715d1-bb09-4f9e-abaa-90c1d60a6aac	f0000026-0000-0000-0000-000000000026	exercise	writing	b327fc49-8634-46cb-b223-3121aad35119	exercise	2025-10-06 03:19:45.844725	2025-10-06 03:41:45.844725	22	t	99.37	\N	web	2025-11-04 19:19:45.844725
e0bb681b-9318-403c-83bc-78cf0913bb71	f0000027-0000-0000-0000-000000000027	practice_test	writing	f13a5f1a-1925-4bf3-88a8-0da43e43dc7f	exercise	2025-10-29 07:19:45.844725	2025-10-29 08:03:45.844725	44	t	86.02	66.31	web	2025-11-04 19:19:45.844725
e486243d-119a-4225-b462-cae7dac0c326	f0000027-0000-0000-0000-000000000027	exercise	writing	d6dd810b-d1c6-4f07-b501-7b7bb6d55e55	exercise	2025-10-29 07:19:45.844725	2025-10-29 08:03:45.844725	44	f	97.76	\N	web	2025-11-04 19:19:45.844725
0593a003-de00-4907-a189-3351fc4b7a9e	f0000027-0000-0000-0000-000000000027	practice_test	writing	a965fc51-a3ee-4984-8bcf-2af98faed93c	lesson	2025-10-29 07:19:45.844725	2025-10-29 08:03:45.844725	44	t	90.14	\N	android	2025-11-04 19:19:45.844725
852a665f-5fe4-4316-8321-d8ffa4bf6173	f0000027-0000-0000-0000-000000000027	practice_test	writing	f6fbcaa6-33bf-41c9-924f-0b3e80407382	lesson	2025-10-29 07:19:45.844725	2025-10-29 08:03:45.844725	44	t	85.51	67.89	android	2025-11-04 19:19:45.844725
d657e70a-ce1c-44f6-815e-07f22814dc8d	f0000027-0000-0000-0000-000000000027	lesson	reading	81fc77a5-3ddc-40ea-8121-e36bd3443c8a	exercise	2025-10-29 07:19:45.844725	2025-10-29 08:03:45.844725	44	t	85.88	60.51	ios	2025-11-04 19:19:45.844725
10c52be7-45d1-4b1a-9034-8785069cf625	f0000028-0000-0000-0000-000000000028	lesson	writing	377b4234-34a5-4a4f-97f7-9ac02ed1e4ea	exercise	2025-10-10 21:19:45.844725	2025-10-10 21:51:45.844725	32	f	57.86	75.00	ios	2025-11-04 19:19:45.844725
c2aea8d6-cd8d-4d74-9b50-160935103b6d	f0000028-0000-0000-0000-000000000028	exercise	speaking	7c251831-853f-41f7-a919-9a29b5b92f48	exercise	2025-10-10 21:19:45.844725	2025-10-10 21:51:45.844725	32	t	26.21	64.86	android	2025-11-04 19:19:45.844725
d8734a3f-e519-4c90-af50-40c9b57f4966	f0000028-0000-0000-0000-000000000028	practice_test	reading	dc4d28a3-3a25-43a9-9eb7-3eeb03b64177	exercise	2025-10-10 21:19:45.844725	2025-10-10 21:51:45.844725	32	f	94.56	\N	ios	2025-11-04 19:19:45.844725
39fc89f6-7cce-4504-b123-cc77bce993d4	f0000028-0000-0000-0000-000000000028	practice_test	reading	3e76bdd0-8a4a-42cc-9ea5-99a2c75567bd	exercise	2025-10-10 21:19:45.844725	2025-10-10 21:51:45.844725	32	f	93.23	85.75	ios	2025-11-04 19:19:45.844725
92d08db8-5205-4293-b9d0-e9edc090c1ac	f0000028-0000-0000-0000-000000000028	lesson	speaking	bdd0aa41-1964-4e88-a9d3-8b33f655d82c	exercise	2025-10-10 21:19:45.844725	2025-10-10 21:51:45.844725	32	t	86.81	81.63	web	2025-11-04 19:19:45.844725
4def3fbd-8ced-47cc-afe0-1d7724b51b2f	f0000029-0000-0000-0000-000000000029	exercise	speaking	d8fcc185-28a8-42be-b208-8a5c84a16c5e	exercise	2025-10-07 06:19:45.844725	2025-10-07 07:39:45.844725	80	t	94.34	\N	android	2025-11-04 19:19:45.844725
fed86c98-0625-4bb3-a14c-00d5e2c6276d	f0000029-0000-0000-0000-000000000029	practice_test	speaking	6a84a859-6103-47bd-81be-12df4fd27d53	lesson	2025-10-07 06:19:45.844725	2025-10-07 07:39:45.844725	80	t	89.54	72.86	ios	2025-11-04 19:19:45.844725
1be92a19-a71f-4911-8938-0ae06ba3f414	f0000029-0000-0000-0000-000000000029	exercise	reading	538d427a-77b6-4859-b860-e4a126f1614e	exercise	2025-10-07 06:19:45.844725	2025-10-07 07:39:45.844725	80	t	97.00	\N	ios	2025-11-04 19:19:45.844725
4675124b-3b83-495c-bafc-7ea7075f4350	f0000029-0000-0000-0000-000000000029	exercise	listening	956d45d9-e96f-4cf3-bd17-728f10648be1	lesson	2025-10-07 06:19:45.844725	2025-10-07 07:39:45.844725	80	t	98.79	68.77	android	2025-11-04 19:19:45.844725
8049f2ac-0987-4674-a199-739e9bcdb7e5	f0000029-0000-0000-0000-000000000029	exercise	speaking	a04b847c-acea-4f64-8d41-1f3d5a355076	exercise	2025-10-07 06:19:45.844725	2025-10-07 07:39:45.844725	80	t	91.59	82.88	web	2025-11-04 19:19:45.844725
dc581a18-1119-4469-8aa6-51f3770229a0	f0000030-0000-0000-0000-000000000030	exercise	reading	5316b3a6-737b-46d6-b5b0-2bdcc8c4818f	lesson	2025-10-27 23:19:45.844725	2025-10-28 00:33:45.844725	74	t	58.80	65.53	android	2025-11-04 19:19:45.844725
b5ac7d91-5503-458d-929d-22c6286f54c8	f0000030-0000-0000-0000-000000000030	lesson	speaking	1049476e-eb4b-46cf-ae55-be3a6fe5c08b	exercise	2025-10-27 23:19:45.844725	2025-10-28 00:33:45.844725	74	t	36.69	85.60	android	2025-11-04 19:19:45.844725
655e1b43-101b-4001-98c9-19e76cee9ec5	f0000030-0000-0000-0000-000000000030	exercise	speaking	d74692af-4725-4570-98f1-fc8f7c466b31	exercise	2025-10-27 23:19:45.844725	2025-10-28 00:33:45.844725	74	t	85.65	78.58	ios	2025-11-04 19:19:45.844725
a01d9815-2bb9-4a62-ab81-eccaf466f70b	f0000030-0000-0000-0000-000000000030	exercise	speaking	d250c7c1-c68f-4745-b170-16461d004d1d	lesson	2025-10-27 23:19:45.844725	2025-10-28 00:33:45.844725	74	t	80.23	\N	ios	2025-11-04 19:19:45.844725
0f23907f-5b2d-46d1-aed2-1bf409a9aaf8	f0000030-0000-0000-0000-000000000030	practice_test	listening	c71dd8e8-9683-427d-b78b-679c12082892	exercise	2025-10-27 23:19:45.844725	2025-10-28 00:33:45.844725	74	t	84.72	68.50	ios	2025-11-04 19:19:45.844725
de01d23e-9231-4c6d-9b36-7805414091d0	f0000031-0000-0000-0000-000000000031	exercise	writing	34cf72ac-85d2-485b-bb87-0cc20998b303	exercise	2025-10-05 02:19:45.844725	2025-10-05 04:25:45.844725	126	f	95.88	75.58	ios	2025-11-04 19:19:45.844725
53570dc7-3f40-4022-86e4-992f05b6b6ff	f0000031-0000-0000-0000-000000000031	exercise	speaking	962cee66-beb8-4bad-b7d2-fd6a991bef0c	exercise	2025-10-05 02:19:45.844725	2025-10-05 04:25:45.844725	126	t	98.14	70.20	web	2025-11-04 19:19:45.844725
236a01d1-3e13-49e4-9887-05c2b8fcbfce	f0000031-0000-0000-0000-000000000031	exercise	writing	a092ca68-0b49-4934-89e5-0948c96bb3d3	exercise	2025-10-05 02:19:45.844725	2025-10-05 04:25:45.844725	126	f	86.92	\N	ios	2025-11-04 19:19:45.844725
8e333900-3550-439c-ae50-291d94ab67fb	f0000031-0000-0000-0000-000000000031	lesson	speaking	289b2bc7-581d-46ea-9b46-ae20ea970e31	exercise	2025-10-05 02:19:45.844725	2025-10-05 04:25:45.844725	126	t	99.73	90.09	ios	2025-11-04 19:19:45.844725
b44ece86-4b3b-4323-b1f1-4bedaa08f385	f0000031-0000-0000-0000-000000000031	practice_test	writing	1cbbdd1e-b072-45c9-8247-84141ca2d129	exercise	2025-10-05 02:19:45.844725	2025-10-05 04:25:45.844725	126	t	94.66	67.83	ios	2025-11-04 19:19:45.844725
fd2840ca-3ff6-43e8-acc3-883679e644e5	f0000032-0000-0000-0000-000000000032	practice_test	speaking	0f2f3209-3d13-4858-a604-fec45513f2ac	lesson	2025-10-11 16:19:45.844725	2025-10-11 17:44:45.844725	85	t	98.95	96.72	ios	2025-11-04 19:19:45.844725
f2e01024-576f-45b1-97c7-012ece54c37c	f0000032-0000-0000-0000-000000000032	practice_test	speaking	585bca6e-00f1-4128-aa1f-d725efa1b597	exercise	2025-10-11 16:19:45.844725	2025-10-11 17:44:45.844725	85	t	75.99	92.87	web	2025-11-04 19:19:45.844725
baa68ae5-f070-4235-9893-522b4e4d2a44	f0000032-0000-0000-0000-000000000032	exercise	reading	0076c699-d89e-4cfc-be26-644b1bc8d12f	exercise	2025-10-11 16:19:45.844725	2025-10-11 17:44:45.844725	85	t	97.43	77.77	ios	2025-11-04 19:19:45.844725
816727c9-cc59-4401-b336-2c08879f0e3c	f0000032-0000-0000-0000-000000000032	practice_test	speaking	4fafd62e-7350-4722-8d0e-a3f175c9a73e	exercise	2025-10-11 16:19:45.844725	2025-10-11 17:44:45.844725	85	t	89.67	72.03	web	2025-11-04 19:19:45.844725
53553516-ffb5-4836-bc75-94b0c6aaab8b	f0000032-0000-0000-0000-000000000032	practice_test	speaking	1ae378d2-e0c5-4338-9a70-7c2fbfb58bb1	exercise	2025-10-11 16:19:45.844725	2025-10-11 17:44:45.844725	85	t	70.33	78.46	android	2025-11-04 19:19:45.844725
81adef3d-daa0-4ba8-a54f-789320bedb33	f0000033-0000-0000-0000-000000000033	exercise	writing	fc363b6e-9c4d-4a85-9111-c9ccb3cadb06	exercise	2025-10-18 10:19:45.844725	2025-10-18 12:30:45.844725	131	f	95.52	91.32	android	2025-11-04 19:19:45.844725
79549530-cd25-482d-b647-3e7faccf6ddd	f0000033-0000-0000-0000-000000000033	practice_test	writing	d28998a2-4204-4a10-b5fc-52ab59ee4627	exercise	2025-10-18 10:19:45.844725	2025-10-18 12:30:45.844725	131	t	71.44	93.70	android	2025-11-04 19:19:45.844725
2dfb9191-1cc3-4ff5-869b-1ae69e03cfca	f0000033-0000-0000-0000-000000000033	lesson	speaking	05568e20-74e0-406e-b7b3-6ea404b30b43	exercise	2025-10-18 10:19:45.844725	2025-10-18 12:30:45.844725	131	t	71.65	92.59	ios	2025-11-04 19:19:45.844725
95691b84-c580-4ee2-aeb9-f63820644ca9	f0000033-0000-0000-0000-000000000033	exercise	writing	1ba1c72e-733f-4cfb-94ce-528265710d8b	exercise	2025-10-18 10:19:45.844725	2025-10-18 12:30:45.844725	131	t	78.95	88.29	ios	2025-11-04 19:19:45.844725
e206614e-06e2-46ea-af5b-82701ca5cbcc	f0000033-0000-0000-0000-000000000033	exercise	reading	bae1b461-5e1d-477a-9f9e-86aa0a9996bb	exercise	2025-10-18 10:19:45.844725	2025-10-18 12:30:45.844725	131	t	99.98	\N	ios	2025-11-04 19:19:45.844725
593a6358-4bd6-44e4-856c-67ea1442e399	f0000034-0000-0000-0000-000000000034	practice_test	reading	f91f66cf-378a-4554-ab1c-de71a361468b	lesson	2025-11-01 00:19:45.844725	2025-11-01 01:37:45.844725	78	f	56.73	84.13	ios	2025-11-04 19:19:45.844725
08ea0648-e209-429e-b040-831cf698d7ed	f0000034-0000-0000-0000-000000000034	exercise	speaking	d5fbd7a5-1750-4e51-8ba5-21b0602748c7	lesson	2025-11-01 00:19:45.844725	2025-11-01 01:37:45.844725	78	t	95.58	97.99	android	2025-11-04 19:19:45.844725
a89bfff9-08ac-403b-9274-e022f3f60985	f0000034-0000-0000-0000-000000000034	lesson	reading	01cb0cfa-14a8-4eca-a09c-7675eb689560	exercise	2025-11-01 00:19:45.844725	2025-11-01 01:37:45.844725	78	t	86.02	95.32	web	2025-11-04 19:19:45.844725
28264697-65ca-47f2-971c-0ed709ce014a	f0000034-0000-0000-0000-000000000034	exercise	reading	f9173ed3-e6ca-4c4d-892e-d133b4e217c7	exercise	2025-11-01 00:19:45.844725	2025-11-01 01:37:45.844725	78	t	81.96	84.38	android	2025-11-04 19:19:45.844725
0ba2c305-2bc9-497f-85f8-1c83e24b8def	f0000034-0000-0000-0000-000000000034	practice_test	speaking	7f33b2ab-eee4-4370-b0a8-461e64f63c39	exercise	2025-11-01 00:19:45.844725	2025-11-01 01:37:45.844725	78	t	14.57	\N	android	2025-11-04 19:19:45.844725
d52ed91d-8d86-4eb3-9ff1-2f92f70d12e5	f0000035-0000-0000-0000-000000000035	exercise	speaking	d8a20d95-52b8-4832-a939-7b731a376c28	exercise	2025-10-10 22:19:45.844725	2025-10-11 00:16:45.844725	117	t	96.98	65.29	ios	2025-11-04 19:19:45.844725
7722bf5b-ac1a-4d08-bd19-a4c54b94b061	f0000035-0000-0000-0000-000000000035	lesson	writing	28e555cc-73e5-4d6d-aa46-17084ffa4e6d	lesson	2025-10-10 22:19:45.844725	2025-10-11 00:16:45.844725	117	t	87.28	\N	web	2025-11-04 19:19:45.844725
9c997962-4ba5-4c3c-86e9-93461bf9b422	f0000035-0000-0000-0000-000000000035	lesson	writing	73b7144a-1178-4462-9d4c-600c8f958064	exercise	2025-10-10 22:19:45.844725	2025-10-11 00:16:45.844725	117	t	24.37	79.95	android	2025-11-04 19:19:45.844725
ea295b7e-ef45-4b03-94d9-27549c9c47ca	f0000035-0000-0000-0000-000000000035	practice_test	listening	3881df70-c4bb-4861-9979-fedbea385878	exercise	2025-10-10 22:19:45.844725	2025-10-11 00:16:45.844725	117	t	80.76	\N	web	2025-11-04 19:19:45.844725
1baf32bf-17fa-48ad-88c4-86ad6fcecc11	f0000035-0000-0000-0000-000000000035	practice_test	speaking	5bcee4b0-08c6-47b9-aecb-c90710849fa5	exercise	2025-10-10 22:19:45.844725	2025-10-11 00:16:45.844725	117	t	88.45	71.42	ios	2025-11-04 19:19:45.844725
dea12de0-4e5b-4164-9313-bc79133d77ea	f0000036-0000-0000-0000-000000000036	lesson	writing	a9a6824c-529d-4a46-9835-781b19bcb7de	exercise	2025-10-30 15:19:45.844725	2025-10-30 16:04:45.844725	45	t	95.00	\N	web	2025-11-04 19:19:45.844725
921cd6ec-3a06-439b-abe7-ff713dfbe18e	f0000036-0000-0000-0000-000000000036	practice_test	reading	edb64553-7497-46bb-9681-80bd81abf32b	exercise	2025-10-30 15:19:45.844725	2025-10-30 16:04:45.844725	45	t	25.34	75.46	ios	2025-11-04 19:19:45.844725
29d4ebe4-3c72-4a9c-8cb2-fd500eb40f4f	f0000036-0000-0000-0000-000000000036	exercise	writing	33b3f187-67ad-4f0e-a18a-db32fda9a3c6	exercise	2025-10-30 15:19:45.844725	2025-10-30 16:04:45.844725	45	t	73.07	76.42	android	2025-11-04 19:19:45.844725
b7e049a4-093b-4857-bb30-d4882f1a5846	f0000036-0000-0000-0000-000000000036	lesson	speaking	fab76565-f86e-4b6a-86d6-e7280c3940ac	exercise	2025-10-30 15:19:45.844725	2025-10-30 16:04:45.844725	45	t	76.41	86.57	android	2025-11-04 19:19:45.844725
2e636d09-539c-4604-a654-43340c8690fe	f0000036-0000-0000-0000-000000000036	exercise	speaking	b3a6f515-1a57-440e-868a-0d3a23affbec	exercise	2025-10-30 15:19:45.844725	2025-10-30 16:04:45.844725	45	t	83.22	90.00	ios	2025-11-04 19:19:45.844725
448614ac-538b-47ca-9ef5-53e30d9831cc	f0000037-0000-0000-0000-000000000037	practice_test	speaking	8cfec06d-48c6-4ebc-a3b3-670ff0b5c4f8	exercise	2025-11-03 00:19:45.844725	2025-11-03 00:45:45.844725	26	t	73.88	\N	ios	2025-11-04 19:19:45.844725
7042cf0e-f85c-4e29-941b-36a4a6d13a8b	f0000037-0000-0000-0000-000000000037	practice_test	reading	8b09c126-822f-4922-a460-73aa27a673ea	exercise	2025-11-03 00:19:45.844725	2025-11-03 00:45:45.844725	26	f	84.23	84.99	ios	2025-11-04 19:19:45.844725
82b08b84-2eb6-43b4-bf21-596aa993d61f	f0000037-0000-0000-0000-000000000037	exercise	writing	1f6596eb-fbbb-495e-b327-b199edfa8420	exercise	2025-11-03 00:19:45.844725	2025-11-03 00:45:45.844725	26	t	79.28	\N	ios	2025-11-04 19:19:45.844725
c355be8a-4bf3-4315-80fa-f10935e07943	f0000037-0000-0000-0000-000000000037	practice_test	writing	c4a2329b-4cbc-4c9e-aca1-4503f7105ad3	lesson	2025-11-03 00:19:45.844725	2025-11-03 00:45:45.844725	26	t	98.24	91.43	android	2025-11-04 19:19:45.844725
d81941f8-18cd-4d9a-abab-c585cb09b1f6	f0000037-0000-0000-0000-000000000037	practice_test	speaking	9e25fbe3-7c43-4d65-a89d-a652f7c44df9	exercise	2025-11-03 00:19:45.844725	2025-11-03 00:45:45.844725	26	t	92.93	63.51	android	2025-11-04 19:19:45.844725
07a4b650-f82d-4dae-959a-932f71c66f6d	f0000038-0000-0000-0000-000000000038	practice_test	writing	ea1af4bc-d15d-406d-85ff-a7fb5251afc3	exercise	2025-10-17 22:19:45.844725	2025-10-17 23:13:45.844725	54	t	83.56	\N	web	2025-11-04 19:19:45.844725
661f2e2b-821b-4ae8-b9b0-78b847fcf99d	f0000038-0000-0000-0000-000000000038	lesson	reading	00cc2156-bcae-4d76-ae8b-f481f10e0dfe	exercise	2025-10-17 22:19:45.844725	2025-10-17 23:13:45.844725	54	t	72.68	63.58	android	2025-11-04 19:19:45.844725
5aa810c7-9a65-4b3f-931b-f075aee2226f	f0000038-0000-0000-0000-000000000038	exercise	speaking	e34d149b-2490-4b94-8b1c-9c298867489e	exercise	2025-10-17 22:19:45.844725	2025-10-17 23:13:45.844725	54	f	78.61	\N	web	2025-11-04 19:19:45.844725
aa000c9c-251a-4668-9de1-05f5e0f59dc5	f0000038-0000-0000-0000-000000000038	practice_test	writing	2142b69f-b516-4968-a24f-9255e039dfc0	exercise	2025-10-17 22:19:45.844725	2025-10-17 23:13:45.844725	54	t	71.42	90.62	ios	2025-11-04 19:19:45.844725
c038803f-e92e-4289-8840-0e55e240c5f5	f0000038-0000-0000-0000-000000000038	exercise	listening	3c4401b5-65a6-458b-abd6-c372b98d5566	exercise	2025-10-17 22:19:45.844725	2025-10-17 23:13:45.844725	54	t	99.17	\N	ios	2025-11-04 19:19:45.844725
edaef9e0-9ae5-4989-a530-001d78513349	f0000039-0000-0000-0000-000000000039	exercise	reading	34a73530-5c34-482a-ab85-19ab6a94d003	exercise	2025-10-21 06:19:45.844725	2025-10-21 07:05:45.844725	46	t	78.32	92.13	ios	2025-11-04 19:19:45.844725
1202a550-5ba5-4f54-8d77-f0eb5430e4a7	f0000039-0000-0000-0000-000000000039	exercise	speaking	1a6fa433-1c21-45c5-85e3-dae156bb6ef0	exercise	2025-10-21 06:19:45.844725	2025-10-21 07:05:45.844725	46	f	86.97	72.38	ios	2025-11-04 19:19:45.844725
ea347df8-7ab8-48be-9487-140b41ca7cb5	f0000039-0000-0000-0000-000000000039	exercise	reading	986e5d1d-d313-4033-b35b-e20c0866bb4c	exercise	2025-10-21 06:19:45.844725	2025-10-21 07:05:45.844725	46	f	99.09	77.75	android	2025-11-04 19:19:45.844725
d7d73993-136f-488b-9e88-8973b814518d	f0000039-0000-0000-0000-000000000039	lesson	writing	f7060341-ae4d-4e0f-8888-8e17b444de0c	exercise	2025-10-21 06:19:45.844725	2025-10-21 07:05:45.844725	46	t	86.92	65.17	ios	2025-11-04 19:19:45.844725
97052e4b-10dc-4dc0-be75-6c8ffa6dd9dc	f0000039-0000-0000-0000-000000000039	lesson	listening	03e8d053-fa3d-444c-bacc-6e9f0a3c121d	exercise	2025-10-21 06:19:45.844725	2025-10-21 07:05:45.844725	46	t	86.42	81.30	ios	2025-11-04 19:19:45.844725
1d7e23c0-6a98-4193-b2b6-38f16f02286a	f0000040-0000-0000-0000-000000000040	exercise	writing	e5a6c264-5afb-43bf-b38f-348a5695b1c6	exercise	2025-10-11 03:19:45.844725	2025-10-11 03:44:45.844725	25	f	56.86	83.43	android	2025-11-04 19:19:45.844725
7283d7bc-4390-4b20-b2d3-bf56d0ec1bd9	f0000040-0000-0000-0000-000000000040	exercise	listening	7cb857a2-0094-4fc2-8107-0ff23382a54c	exercise	2025-10-11 03:19:45.844725	2025-10-11 03:44:45.844725	25	f	72.41	88.56	ios	2025-11-04 19:19:45.844725
00999468-deda-450d-b7b4-b7c08c7507cd	f0000040-0000-0000-0000-000000000040	exercise	writing	a3e3b4d5-a11a-410a-9674-f1336d2d47f6	exercise	2025-10-11 03:19:45.844725	2025-10-11 03:44:45.844725	25	f	79.25	84.36	web	2025-11-04 19:19:45.844725
16992527-32c4-4361-97be-e24877aee5d7	f0000040-0000-0000-0000-000000000040	lesson	writing	d73e0066-fb88-43df-99af-2adcb14b6488	lesson	2025-10-11 03:19:45.844725	2025-10-11 03:44:45.844725	25	f	73.51	90.41	ios	2025-11-04 19:19:45.844725
801a9489-f500-4b58-aec5-23b9af245775	f0000040-0000-0000-0000-000000000040	practice_test	reading	36c98953-8522-4bb8-883e-bfdc906ce18e	lesson	2025-10-11 03:19:45.844725	2025-10-11 03:44:45.844725	25	f	86.96	96.74	android	2025-11-04 19:19:45.844725
9f29c8a2-c25b-42f3-8210-b261db87c1ad	f0000041-0000-0000-0000-000000000041	practice_test	speaking	6cd78ddc-c4c0-4aeb-9d69-4455d2ab3795	lesson	2025-11-03 08:19:45.844725	2025-11-03 10:00:45.844725	101	t	73.08	86.03	ios	2025-11-04 19:19:45.844725
335e8b4e-544c-4f58-9c9d-004560cd8cc3	f0000041-0000-0000-0000-000000000041	practice_test	reading	9afb4a28-09df-4fa2-a48b-c1c65079ccac	exercise	2025-11-03 08:19:45.844725	2025-11-03 10:00:45.844725	101	t	85.84	91.86	ios	2025-11-04 19:19:45.844725
80b77981-3c8c-4666-a765-7e4925d3eb6e	f0000041-0000-0000-0000-000000000041	lesson	speaking	67d8d645-641e-4410-bc76-ebf13ea9a5c2	exercise	2025-11-03 08:19:45.844725	2025-11-03 10:00:45.844725	101	t	25.27	\N	ios	2025-11-04 19:19:45.844725
a69f8db7-8d88-4c73-b8ba-f6b9896bf8a8	f0000041-0000-0000-0000-000000000041	lesson	reading	a29814a5-2e82-48fb-a927-309b485d6cff	exercise	2025-11-03 08:19:45.844725	2025-11-03 10:00:45.844725	101	t	38.95	77.48	ios	2025-11-04 19:19:45.844725
4f986d0e-75a7-4005-bfe6-92f6c380133f	f0000041-0000-0000-0000-000000000041	exercise	listening	921fc772-58a5-4aa6-8972-5b49dd284720	exercise	2025-11-03 08:19:45.844725	2025-11-03 10:00:45.844725	101	t	76.13	\N	web	2025-11-04 19:19:45.844725
a4d97b9c-7ad8-4a14-9002-aebdb1ccad47	f0000042-0000-0000-0000-000000000042	exercise	writing	5f5654d4-72c3-4e11-9956-cbcb607a99e5	lesson	2025-10-21 13:19:45.844725	2025-10-21 14:57:45.844725	98	t	96.50	85.67	ios	2025-11-04 19:19:45.844725
f6522f04-501d-4446-8011-7c1cf6d7cf09	f0000042-0000-0000-0000-000000000042	practice_test	reading	f1a048fa-a11a-467d-ba78-f6eb684a9ac3	exercise	2025-10-21 13:19:45.844725	2025-10-21 14:57:45.844725	98	t	82.96	64.90	android	2025-11-04 19:19:45.844725
0307fef0-a91b-4dc9-afbb-2d069bc25f32	f0000042-0000-0000-0000-000000000042	practice_test	reading	c2c16b96-c814-42de-a569-76dfe43c8e7a	exercise	2025-10-21 13:19:45.844725	2025-10-21 14:57:45.844725	98	f	75.94	\N	ios	2025-11-04 19:19:45.844725
52899744-0716-4f1b-981f-6bacb4b00c94	f0000042-0000-0000-0000-000000000042	exercise	speaking	33f742de-fd35-4b9f-b9af-b14081c31c98	exercise	2025-10-21 13:19:45.844725	2025-10-21 14:57:45.844725	98	t	99.32	71.74	web	2025-11-04 19:19:45.844725
72d465c0-0ed5-4dbe-b672-b7945d83762b	f0000042-0000-0000-0000-000000000042	practice_test	writing	9fd50ed2-4971-4ba3-a62c-860b1a81b354	exercise	2025-10-21 13:19:45.844725	2025-10-21 14:57:45.844725	98	t	86.83	79.64	android	2025-11-04 19:19:45.844725
90467c21-8bee-4699-a618-6f2b83aad50b	f0000043-0000-0000-0000-000000000043	lesson	reading	62d801de-2131-4a6d-a36d-451b88491d44	exercise	2025-11-02 12:19:45.844725	2025-11-02 14:06:45.844725	107	t	80.09	\N	ios	2025-11-04 19:19:45.844725
a52694d7-048c-452f-890c-6335929aa79c	f0000043-0000-0000-0000-000000000043	exercise	writing	35951982-5e66-49f0-800c-f6313006ea61	exercise	2025-11-02 12:19:45.844725	2025-11-02 14:06:45.844725	107	t	6.53	82.73	ios	2025-11-04 19:19:45.844725
972327dc-10a1-4646-9b37-325e50bca41e	f0000043-0000-0000-0000-000000000043	lesson	reading	5a84c2d7-ae94-4f84-948d-219237c75988	lesson	2025-11-02 12:19:45.844725	2025-11-02 14:06:45.844725	107	f	98.61	\N	android	2025-11-04 19:19:45.844725
4ba8b6e8-7bbc-48f6-9ad1-3c8f88a0f68e	f0000043-0000-0000-0000-000000000043	practice_test	reading	73f71645-e576-498a-a256-16fae46f880d	exercise	2025-11-02 12:19:45.844725	2025-11-02 14:06:45.844725	107	t	79.38	93.49	ios	2025-11-04 19:19:45.844725
65f99f07-c959-459c-92ec-0dc5af66ce5d	f0000043-0000-0000-0000-000000000043	exercise	listening	8867753a-25df-4289-a3df-d99d94af9612	exercise	2025-11-02 12:19:45.844725	2025-11-02 14:06:45.844725	107	t	19.04	87.05	ios	2025-11-04 19:19:45.844725
6e367f0e-dd77-4971-8688-1c27a330d98a	f0000044-0000-0000-0000-000000000044	exercise	reading	43c47da1-b967-4e3f-9818-714b9c1ccb34	exercise	2025-10-05 21:19:45.844725	2025-10-05 21:47:45.844725	28	t	84.26	\N	android	2025-11-04 19:19:45.844725
37e9f1a6-076a-492b-91d2-6c81e5427cf6	f0000044-0000-0000-0000-000000000044	exercise	reading	d5658c96-3016-46ba-83cb-2f5ee3e0aa22	exercise	2025-10-05 21:19:45.844725	2025-10-05 21:47:45.844725	28	t	84.42	\N	web	2025-11-04 19:19:45.844725
b87a1dbb-62de-4d48-a4c7-c88698aaac1f	f0000044-0000-0000-0000-000000000044	practice_test	reading	68b0df7b-3dab-446a-bd90-15cad9004290	lesson	2025-10-05 21:19:45.844725	2025-10-05 21:47:45.844725	28	t	95.93	62.80	web	2025-11-04 19:19:45.844725
7bade3c2-8baf-473a-8862-fddcd02b2eac	f0000044-0000-0000-0000-000000000044	exercise	speaking	dc826bcd-76e6-4c9f-aea0-8c767faaf7d3	exercise	2025-10-05 21:19:45.844725	2025-10-05 21:47:45.844725	28	t	95.25	\N	ios	2025-11-04 19:19:45.844725
3c64a1eb-ef51-4a42-9685-3e8fdbd8bbcd	f0000044-0000-0000-0000-000000000044	practice_test	reading	6f82ac51-6c71-4bb0-af3e-8e36dd3d423c	exercise	2025-10-05 21:19:45.844725	2025-10-05 21:47:45.844725	28	t	71.64	77.03	web	2025-11-04 19:19:45.844725
36648444-87a1-471c-9f56-59b7e0267578	f0000045-0000-0000-0000-000000000045	practice_test	reading	ec70db44-6407-4487-98ba-4dd398d93424	lesson	2025-10-07 22:19:45.844725	2025-10-07 23:55:45.844725	96	t	79.74	62.55	ios	2025-11-04 19:19:45.844725
d4fcf9da-df07-46d1-9800-1cd8b27b8450	f0000045-0000-0000-0000-000000000045	exercise	writing	a669e1e9-ab62-44f3-8c03-631fa8bb4145	exercise	2025-10-07 22:19:45.844725	2025-10-07 23:55:45.844725	96	f	91.88	\N	android	2025-11-04 19:19:45.844725
a7665148-0499-4145-9fe1-d6fffd288db8	f0000045-0000-0000-0000-000000000045	practice_test	reading	d3e58932-76af-4df5-ac4f-1307f5b5ad46	exercise	2025-10-07 22:19:45.844725	2025-10-07 23:55:45.844725	96	t	99.23	72.12	ios	2025-11-04 19:19:45.844725
589d0983-629d-4360-b882-e45b323be9e3	f0000045-0000-0000-0000-000000000045	practice_test	writing	7ac271ed-b2ac-4057-ae5f-67efe2c0a2c3	exercise	2025-10-07 22:19:45.844725	2025-10-07 23:55:45.844725	96	f	96.10	81.56	ios	2025-11-04 19:19:45.844725
a1831041-59c1-459a-9355-832caceb432d	f0000045-0000-0000-0000-000000000045	practice_test	listening	7e42bbee-b570-4670-837e-4b553246eff1	exercise	2025-10-07 22:19:45.844725	2025-10-07 23:55:45.844725	96	f	77.57	91.71	ios	2025-11-04 19:19:45.844725
8a2bfb1d-1dbc-44a7-8b83-cfa79c01a74c	f0000046-0000-0000-0000-000000000046	exercise	reading	4536a788-bf0d-4eaa-a48b-3231d4dbcfc3	lesson	2025-10-28 13:19:45.844725	2025-10-28 14:33:45.844725	74	t	86.97	\N	ios	2025-11-04 19:19:45.844725
ab8a58b9-ac05-4845-9125-e48d57b31bea	f0000046-0000-0000-0000-000000000046	lesson	speaking	26607be5-f0ab-4b88-8769-77676a9d3414	exercise	2025-10-28 13:19:45.844725	2025-10-28 14:33:45.844725	74	t	71.83	97.03	android	2025-11-04 19:19:45.844725
6e8e35d5-d2e1-4573-b317-fc703b9075b9	f0000046-0000-0000-0000-000000000046	exercise	writing	47413750-5811-4ae4-9dd1-315c64401b1e	lesson	2025-10-28 13:19:45.844725	2025-10-28 14:33:45.844725	74	t	93.98	\N	web	2025-11-04 19:19:45.844725
1a4ebdf4-068c-42c5-a629-21ac6a258b5d	f0000046-0000-0000-0000-000000000046	practice_test	writing	a62ab7bd-4388-4dce-8210-e38fb63921ae	lesson	2025-10-28 13:19:45.844725	2025-10-28 14:33:45.844725	74	t	75.54	94.44	ios	2025-11-04 19:19:45.844725
49526c7b-58ff-4183-a423-28d07db4ca25	f0000046-0000-0000-0000-000000000046	practice_test	speaking	37205fb9-c75d-4e87-a1d0-5bb6faa9b9d8	exercise	2025-10-28 13:19:45.844725	2025-10-28 14:33:45.844725	74	t	88.94	86.21	android	2025-11-04 19:19:45.844725
8980e461-04e5-4060-a361-2d6a2da36ace	f0000047-0000-0000-0000-000000000047	exercise	listening	a8c6c0db-58a0-45dc-9ed1-43eda35281a6	exercise	2025-10-31 06:19:45.844725	2025-10-31 08:09:45.844725	110	t	96.57	63.54	android	2025-11-04 19:19:45.844725
7e75dce1-f416-4e42-8a73-460530d27ab1	f0000047-0000-0000-0000-000000000047	exercise	speaking	d7952042-c40e-47a4-b687-e416d9220653	exercise	2025-10-31 06:19:45.844725	2025-10-31 08:09:45.844725	110	f	94.31	99.68	android	2025-11-04 19:19:45.844725
9b56b1e2-2551-42f1-9e53-603cf3537082	f0000047-0000-0000-0000-000000000047	practice_test	reading	e6ee8aea-a49e-4a3b-87cc-ca792704dea6	lesson	2025-10-31 06:19:45.844725	2025-10-31 08:09:45.844725	110	t	94.44	99.67	ios	2025-11-04 19:19:45.844725
8697c490-6aeb-44b5-b68f-238c5d57289e	f0000047-0000-0000-0000-000000000047	practice_test	listening	223464c6-b6fe-4994-b8f0-50eb9e0c4bf9	exercise	2025-10-31 06:19:45.844725	2025-10-31 08:09:45.844725	110	t	83.70	\N	ios	2025-11-04 19:19:45.844725
5296f8b9-5b90-4e3a-96f9-ed628aedd7fd	f0000047-0000-0000-0000-000000000047	practice_test	listening	18d0b8e8-c26d-4fd6-8996-07c48a116928	exercise	2025-10-31 06:19:45.844725	2025-10-31 08:09:45.844725	110	t	97.50	74.68	android	2025-11-04 19:19:45.844725
cd354d0a-30fe-4562-9177-b49ae0784fda	f0000048-0000-0000-0000-000000000048	exercise	writing	70696eb3-6ba5-4858-a95e-5e4524ce3ba1	exercise	2025-10-29 15:19:45.844725	2025-10-29 17:03:45.844725	104	t	39.61	74.13	ios	2025-11-04 19:19:45.844725
bf5432d6-2988-43c7-870a-cab2a760ea6c	f0000048-0000-0000-0000-000000000048	practice_test	speaking	ab258567-1ca1-406b-b8da-90266997e5b9	exercise	2025-10-29 15:19:45.844725	2025-10-29 17:03:45.844725	104	f	56.23	\N	ios	2025-11-04 19:19:45.844725
d989ef4a-3295-449e-a227-aed17df5e05e	f0000048-0000-0000-0000-000000000048	practice_test	writing	9cd9288b-f54b-4413-9b20-c8c3eb573f78	exercise	2025-10-29 15:19:45.844725	2025-10-29 17:03:45.844725	104	f	92.81	99.30	android	2025-11-04 19:19:45.844725
0c3daac0-913a-4cd7-bfae-be511544f148	f0000048-0000-0000-0000-000000000048	practice_test	writing	a245c9e8-f2c3-404c-82d6-d07f7c69e1df	exercise	2025-10-29 15:19:45.844725	2025-10-29 17:03:45.844725	104	t	76.75	\N	ios	2025-11-04 19:19:45.844725
aeff27da-09fc-423d-b2c1-a6fa26d57b0b	f0000048-0000-0000-0000-000000000048	exercise	writing	ec1386f7-5143-49e6-a185-57fb295eedb3	exercise	2025-10-29 15:19:45.844725	2025-10-29 17:03:45.844725	104	t	74.23	\N	ios	2025-11-04 19:19:45.844725
227133a8-3f6e-4f50-bc85-b6085f9808c0	f0000049-0000-0000-0000-000000000049	lesson	speaking	5fddca5a-bbcf-41af-8699-a707d6592e84	exercise	2025-10-14 16:19:45.844725	2025-10-14 16:44:45.844725	25	f	39.35	\N	ios	2025-11-04 19:19:45.844725
30953cc2-f3ba-41cc-95fb-28bdfb9dbe3d	f0000049-0000-0000-0000-000000000049	exercise	listening	cf0e3bbd-d779-4261-91c2-b489d9698e17	exercise	2025-10-14 16:19:45.844725	2025-10-14 16:44:45.844725	25	t	70.35	87.13	ios	2025-11-04 19:19:45.844725
59210293-3265-4474-b543-21d5d632f212	f0000049-0000-0000-0000-000000000049	exercise	speaking	c5e6947f-02a8-4d93-b87e-8b981cd2f66a	lesson	2025-10-14 16:19:45.844725	2025-10-14 16:44:45.844725	25	t	80.48	\N	ios	2025-11-04 19:19:45.844725
416eef9a-07bb-4e6f-aa44-dc9d56dbde5d	f0000049-0000-0000-0000-000000000049	exercise	reading	f46efb81-46cc-4337-8b7e-77686f74cd60	exercise	2025-10-14 16:19:45.844725	2025-10-14 16:44:45.844725	25	f	75.12	73.08	android	2025-11-04 19:19:45.844725
b263ada2-eead-43c1-9cc2-5d58e8345665	f0000049-0000-0000-0000-000000000049	lesson	writing	f14b708d-49ac-4600-b0dd-54a1829f9b14	lesson	2025-10-14 16:19:45.844725	2025-10-14 16:44:45.844725	25	t	83.43	70.20	android	2025-11-04 19:19:45.844725
492ef02b-82b8-4ec5-a231-e683f505c5be	f0000050-0000-0000-0000-000000000050	practice_test	writing	8d20f1d9-c746-46ba-9730-13ef51320995	exercise	2025-10-16 01:19:45.844725	2025-10-16 02:34:45.844725	75	f	87.41	\N	ios	2025-11-04 19:19:45.844725
7c49e0bc-9d6e-44b4-8e73-8115fdccb88e	f0000050-0000-0000-0000-000000000050	practice_test	speaking	e004b91d-a155-41d5-ab7d-55345c5e9a24	exercise	2025-10-16 01:19:45.844725	2025-10-16 02:34:45.844725	75	t	33.98	87.20	ios	2025-11-04 19:19:45.844725
3a2a2355-f5a5-4d90-bafe-c51d66845a62	f0000050-0000-0000-0000-000000000050	exercise	reading	3b99a757-209b-42ed-9fed-30e8b9ddc01e	exercise	2025-10-16 01:19:45.844725	2025-10-16 02:34:45.844725	75	t	85.87	83.64	ios	2025-11-04 19:19:45.844725
3295dc17-0eb8-415e-9ca4-3896cf68802f	f0000050-0000-0000-0000-000000000050	practice_test	writing	ae8bc4c4-acf1-4b19-946c-9132a23a6887	exercise	2025-10-16 01:19:45.844725	2025-10-16 02:34:45.844725	75	t	92.63	\N	web	2025-11-04 19:19:45.844725
01140e11-86d0-4f0c-84c6-c2b6be75b75b	f0000050-0000-0000-0000-000000000050	lesson	reading	ada2159c-7704-4b19-af0a-65cd6712b1f4	exercise	2025-10-16 01:19:45.844725	2025-10-16 02:34:45.844725	75	t	99.71	64.80	ios	2025-11-04 19:19:45.844725
9d094d45-ece7-4370-9640-3c3957d88bb3	f0000003-0000-0000-0000-000000000003	exercise	listening	e1000018-0000-0000-0000-000000000021	\N	2025-11-04 19:40:36.279884	2025-11-04 19:40:36.279884	1	t	\N	2.00	\N	2025-11-04 19:40:36.280463
f51c554d-df58-4a60-b439-84cc105ac01d	f0000003-0000-0000-0000-000000000003	exercise	listening	e1000018-0000-0000-0000-000000000021	\N	2025-11-04 19:59:38.890155	2025-11-04 19:59:38.890155	1	t	\N	2.00	\N	2025-11-04 19:59:38.890998
40803a7c-9b84-432c-b8f9-5206c2b7d563	f0000003-0000-0000-0000-000000000003	exercise	listening	e1000017-0000-0000-0000-000000000020	\N	2025-11-05 06:14:59.292325	2025-11-05 06:14:59.292325	40	t	\N	2.00	\N	2025-11-05 06:14:59.292487
\.


--
-- Data for Name: user_achievements; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.user_achievements (id, user_id, achievement_id, earned_at) FROM stdin;
9825	a0000001-0000-0000-0000-000000000001	2	2025-09-14 19:19:45.853519
9826	a0000001-0000-0000-0000-000000000001	3	2025-07-30 19:19:45.853519
9827	a0000001-0000-0000-0000-000000000001	4	2025-08-14 19:19:45.853519
9828	a0000001-0000-0000-0000-000000000001	6	2025-09-08 19:19:45.853519
9829	a0000002-0000-0000-0000-000000000002	3	2025-10-22 19:19:45.853519
9830	a0000002-0000-0000-0000-000000000002	5	2025-09-12 19:19:45.853519
9831	b0000001-0000-0000-0000-000000000001	2	2025-09-20 19:19:45.853519
9832	b0000001-0000-0000-0000-000000000001	4	2025-10-17 19:19:45.853519
9833	b0000001-0000-0000-0000-000000000001	5	2025-09-18 19:19:45.853519
9834	b0000002-0000-0000-0000-000000000002	4	2025-08-09 19:19:45.853519
9835	b0000002-0000-0000-0000-000000000002	5	2025-09-22 19:19:45.853519
9836	b0000002-0000-0000-0000-000000000002	6	2025-10-18 19:19:45.853519
9837	b0000003-0000-0000-0000-000000000003	2	2025-08-07 19:19:45.853519
9838	b0000003-0000-0000-0000-000000000003	4	2025-10-25 19:19:45.853519
9839	b0000003-0000-0000-0000-000000000003	5	2025-09-20 19:19:45.853519
9840	b0000003-0000-0000-0000-000000000003	6	2025-10-26 19:19:45.853519
9841	b0000004-0000-0000-0000-000000000004	4	2025-09-10 19:19:45.853519
9842	b0000004-0000-0000-0000-000000000004	5	2025-09-03 19:19:45.853519
9843	f0000001-0000-0000-0000-000000000001	1	2025-10-02 19:19:45.853519
9844	f0000001-0000-0000-0000-000000000001	4	2025-08-13 19:19:45.853519
9845	f0000001-0000-0000-0000-000000000001	6	2025-08-08 19:19:45.853519
9846	f0000002-0000-0000-0000-000000000002	1	2025-10-12 19:19:45.853519
9847	f0000002-0000-0000-0000-000000000002	2	2025-10-09 19:19:45.853519
9848	f0000002-0000-0000-0000-000000000002	5	2025-10-07 19:19:45.853519
9849	f0000003-0000-0000-0000-000000000003	1	2025-09-13 19:19:45.853519
9850	f0000003-0000-0000-0000-000000000003	4	2025-09-09 19:19:45.853519
9851	f0000003-0000-0000-0000-000000000003	5	2025-08-29 19:19:45.853519
9852	f0000003-0000-0000-0000-000000000003	6	2025-11-03 19:19:45.853519
9853	f0000004-0000-0000-0000-000000000004	1	2025-10-30 19:19:45.853519
9854	f0000004-0000-0000-0000-000000000004	2	2025-09-14 19:19:45.853519
9855	f0000004-0000-0000-0000-000000000004	4	2025-10-27 19:19:45.853519
9856	f0000004-0000-0000-0000-000000000004	5	2025-10-12 19:19:45.853519
9857	f0000005-0000-0000-0000-000000000005	1	2025-10-30 19:19:45.853519
9858	f0000005-0000-0000-0000-000000000005	2	2025-08-25 19:19:45.853519
9859	f0000005-0000-0000-0000-000000000005	4	2025-08-01 19:19:45.853519
9860	f0000005-0000-0000-0000-000000000005	6	2025-10-24 19:19:45.853519
9861	f0000006-0000-0000-0000-000000000006	1	2025-09-13 19:19:45.853519
9862	f0000006-0000-0000-0000-000000000006	4	2025-08-03 19:19:45.853519
9863	f0000006-0000-0000-0000-000000000006	6	2025-07-30 19:19:45.853519
9864	f0000007-0000-0000-0000-000000000007	1	2025-09-23 19:19:45.853519
9865	f0000007-0000-0000-0000-000000000007	6	2025-08-25 19:19:45.853519
9866	f0000008-0000-0000-0000-000000000008	1	2025-10-10 19:19:45.853519
9867	f0000008-0000-0000-0000-000000000008	2	2025-08-28 19:19:45.853519
9868	f0000008-0000-0000-0000-000000000008	5	2025-08-03 19:19:45.853519
9869	f0000009-0000-0000-0000-000000000009	1	2025-09-21 19:19:45.853519
9870	f0000009-0000-0000-0000-000000000009	5	2025-10-18 19:19:45.853519
9871	f0000009-0000-0000-0000-000000000009	6	2025-09-13 19:19:45.853519
9872	f0000010-0000-0000-0000-000000000010	1	2025-09-21 19:19:45.853519
9873	f0000010-0000-0000-0000-000000000010	2	2025-08-09 19:19:45.853519
9874	f0000010-0000-0000-0000-000000000010	3	2025-09-27 19:19:45.853519
9875	f0000010-0000-0000-0000-000000000010	5	2025-09-21 19:19:45.853519
9876	f0000011-0000-0000-0000-000000000011	1	2025-10-09 19:19:45.853519
9877	f0000011-0000-0000-0000-000000000011	4	2025-10-21 19:19:45.853519
9878	f0000011-0000-0000-0000-000000000011	5	2025-09-01 19:19:45.853519
9879	f0000012-0000-0000-0000-000000000012	1	2025-08-13 19:19:45.853519
9880	f0000012-0000-0000-0000-000000000012	4	2025-09-27 19:19:45.853519
9881	f0000013-0000-0000-0000-000000000013	1	2025-09-27 19:19:45.853519
9882	f0000013-0000-0000-0000-000000000013	2	2025-10-23 19:19:45.853519
9883	f0000013-0000-0000-0000-000000000013	3	2025-08-22 19:19:45.853519
9884	f0000013-0000-0000-0000-000000000013	5	2025-07-28 19:19:45.853519
9885	f0000014-0000-0000-0000-000000000014	1	2025-11-02 19:19:45.853519
9886	f0000014-0000-0000-0000-000000000014	2	2025-08-29 19:19:45.853519
9887	f0000014-0000-0000-0000-000000000014	4	2025-09-15 19:19:45.853519
9888	f0000014-0000-0000-0000-000000000014	5	2025-07-27 19:19:45.853519
9889	f0000015-0000-0000-0000-000000000015	1	2025-09-30 19:19:45.853519
9890	f0000015-0000-0000-0000-000000000015	2	2025-08-09 19:19:45.853519
9891	f0000015-0000-0000-0000-000000000015	4	2025-10-01 19:19:45.853519
9892	f0000016-0000-0000-0000-000000000016	1	2025-10-19 19:19:45.853519
9893	f0000016-0000-0000-0000-000000000016	4	2025-09-04 19:19:45.853519
9894	f0000017-0000-0000-0000-000000000017	1	2025-09-16 19:19:45.853519
9895	f0000017-0000-0000-0000-000000000017	3	2025-10-27 19:19:45.853519
9896	f0000018-0000-0000-0000-000000000018	1	2025-08-07 19:19:45.853519
9897	f0000018-0000-0000-0000-000000000018	4	2025-10-22 19:19:45.853519
9898	f0000019-0000-0000-0000-000000000019	1	2025-09-02 19:19:45.853519
9899	f0000019-0000-0000-0000-000000000019	2	2025-10-20 19:19:45.853519
9900	f0000019-0000-0000-0000-000000000019	3	2025-07-31 19:19:45.853519
9901	f0000019-0000-0000-0000-000000000019	4	2025-09-23 19:19:45.853519
9902	f0000020-0000-0000-0000-000000000020	1	2025-10-22 19:19:45.853519
9903	f0000020-0000-0000-0000-000000000020	2	2025-09-24 19:19:45.853519
9904	f0000020-0000-0000-0000-000000000020	5	2025-09-29 19:19:45.853519
9905	f0000021-0000-0000-0000-000000000021	1	2025-07-29 19:19:45.853519
9906	f0000021-0000-0000-0000-000000000021	2	2025-09-17 19:19:45.853519
9907	f0000021-0000-0000-0000-000000000021	5	2025-10-17 19:19:45.853519
9908	f0000022-0000-0000-0000-000000000022	1	2025-10-02 19:19:45.853519
9909	f0000022-0000-0000-0000-000000000022	2	2025-08-19 19:19:45.853519
9910	f0000022-0000-0000-0000-000000000022	4	2025-09-05 19:19:45.853519
9911	f0000022-0000-0000-0000-000000000022	5	2025-09-20 19:19:45.853519
9912	f0000023-0000-0000-0000-000000000023	1	2025-08-08 19:19:45.853519
9913	f0000023-0000-0000-0000-000000000023	4	2025-07-29 19:19:45.853519
9914	f0000023-0000-0000-0000-000000000023	6	2025-10-27 19:19:45.853519
9915	f0000024-0000-0000-0000-000000000024	1	2025-09-11 19:19:45.853519
9916	f0000024-0000-0000-0000-000000000024	4	2025-09-05 19:19:45.853519
9917	f0000024-0000-0000-0000-000000000024	6	2025-08-31 19:19:45.853519
9918	f0000025-0000-0000-0000-000000000025	1	2025-10-02 19:19:45.853519
9919	f0000025-0000-0000-0000-000000000025	2	2025-10-13 19:19:45.853519
9920	f0000025-0000-0000-0000-000000000025	3	2025-10-04 19:19:45.853519
9921	f0000025-0000-0000-0000-000000000025	4	2025-10-30 19:19:45.853519
9922	f0000025-0000-0000-0000-000000000025	5	2025-07-27 19:19:45.853519
9923	f0000025-0000-0000-0000-000000000025	6	2025-09-09 19:19:45.853519
9924	f0000026-0000-0000-0000-000000000026	1	2025-10-07 19:19:45.853519
9925	f0000026-0000-0000-0000-000000000026	3	2025-10-31 19:19:45.853519
9926	f0000026-0000-0000-0000-000000000026	4	2025-11-04 19:19:45.853519
9927	f0000027-0000-0000-0000-000000000027	1	2025-08-28 19:19:45.853519
9928	f0000027-0000-0000-0000-000000000027	4	2025-09-17 19:19:45.853519
9929	f0000027-0000-0000-0000-000000000027	5	2025-10-05 19:19:45.853519
9930	f0000027-0000-0000-0000-000000000027	6	2025-09-09 19:19:45.853519
9931	f0000028-0000-0000-0000-000000000028	1	2025-09-10 19:19:45.853519
9932	f0000028-0000-0000-0000-000000000028	2	2025-10-16 19:19:45.853519
9933	f0000029-0000-0000-0000-000000000029	1	2025-10-11 19:19:45.853519
9934	f0000029-0000-0000-0000-000000000029	2	2025-10-17 19:19:45.853519
9935	f0000029-0000-0000-0000-000000000029	3	2025-10-11 19:19:45.853519
9936	f0000029-0000-0000-0000-000000000029	5	2025-07-28 19:19:45.853519
9937	f0000030-0000-0000-0000-000000000030	1	2025-10-10 19:19:45.853519
9938	f0000030-0000-0000-0000-000000000030	4	2025-09-18 19:19:45.853519
9939	f0000030-0000-0000-0000-000000000030	5	2025-09-08 19:19:45.853519
9940	f0000030-0000-0000-0000-000000000030	6	2025-10-26 19:19:45.853519
9941	f0000031-0000-0000-0000-000000000031	1	2025-10-31 19:19:45.853519
9942	f0000031-0000-0000-0000-000000000031	2	2025-10-29 19:19:45.853519
9943	f0000031-0000-0000-0000-000000000031	4	2025-10-29 19:19:45.853519
9944	f0000031-0000-0000-0000-000000000031	5	2025-08-24 19:19:45.853519
9945	f0000032-0000-0000-0000-000000000032	1	2025-08-07 19:19:45.853519
9946	f0000032-0000-0000-0000-000000000032	2	2025-10-11 19:19:45.853519
9947	f0000032-0000-0000-0000-000000000032	4	2025-09-30 19:19:45.853519
9948	f0000032-0000-0000-0000-000000000032	5	2025-10-29 19:19:45.853519
9949	f0000033-0000-0000-0000-000000000033	1	2025-09-19 19:19:45.853519
9950	f0000033-0000-0000-0000-000000000033	3	2025-08-28 19:19:45.853519
9951	f0000033-0000-0000-0000-000000000033	4	2025-08-05 19:19:45.853519
9952	f0000033-0000-0000-0000-000000000033	5	2025-09-08 19:19:45.853519
9953	f0000034-0000-0000-0000-000000000034	1	2025-10-24 19:19:45.853519
9954	f0000034-0000-0000-0000-000000000034	2	2025-08-29 19:19:45.853519
9955	f0000034-0000-0000-0000-000000000034	5	2025-07-31 19:19:45.853519
9956	f0000034-0000-0000-0000-000000000034	6	2025-10-15 19:19:45.853519
9957	f0000035-0000-0000-0000-000000000035	1	2025-10-13 19:19:45.853519
9958	f0000035-0000-0000-0000-000000000035	2	2025-08-18 19:19:45.853519
9959	f0000035-0000-0000-0000-000000000035	3	2025-10-20 19:19:45.853519
9960	f0000036-0000-0000-0000-000000000036	1	2025-11-01 19:19:45.853519
9961	f0000036-0000-0000-0000-000000000036	3	2025-10-20 19:19:45.853519
9962	f0000036-0000-0000-0000-000000000036	5	2025-11-04 19:19:45.853519
9963	f0000037-0000-0000-0000-000000000037	1	2025-08-02 19:19:45.853519
9964	f0000037-0000-0000-0000-000000000037	5	2025-10-18 19:19:45.853519
9965	f0000037-0000-0000-0000-000000000037	6	2025-09-25 19:19:45.853519
9966	f0000038-0000-0000-0000-000000000038	1	2025-09-25 19:19:45.853519
9967	f0000038-0000-0000-0000-000000000038	3	2025-09-09 19:19:45.853519
9968	f0000038-0000-0000-0000-000000000038	4	2025-10-20 19:19:45.853519
9969	f0000038-0000-0000-0000-000000000038	5	2025-10-17 19:19:45.853519
9970	f0000039-0000-0000-0000-000000000039	1	2025-08-17 19:19:45.853519
9971	f0000039-0000-0000-0000-000000000039	5	2025-08-13 19:19:45.853519
9972	f0000040-0000-0000-0000-000000000040	1	2025-10-26 19:19:45.853519
9973	f0000040-0000-0000-0000-000000000040	3	2025-08-29 19:19:45.853519
9974	f0000040-0000-0000-0000-000000000040	4	2025-09-22 19:19:45.853519
9975	f0000040-0000-0000-0000-000000000040	5	2025-10-25 19:19:45.853519
9976	f0000041-0000-0000-0000-000000000041	1	2025-09-22 19:19:45.853519
9977	f0000041-0000-0000-0000-000000000041	2	2025-10-11 19:19:45.853519
9978	f0000041-0000-0000-0000-000000000041	3	2025-09-19 19:19:45.853519
9979	f0000041-0000-0000-0000-000000000041	4	2025-08-14 19:19:45.853519
9980	f0000041-0000-0000-0000-000000000041	5	2025-09-21 19:19:45.853519
9981	f0000042-0000-0000-0000-000000000042	1	2025-08-23 19:19:45.853519
9982	f0000042-0000-0000-0000-000000000042	3	2025-09-06 19:19:45.853519
9983	f0000042-0000-0000-0000-000000000042	5	2025-08-26 19:19:45.853519
9984	f0000043-0000-0000-0000-000000000043	1	2025-09-29 19:19:45.853519
9985	f0000043-0000-0000-0000-000000000043	2	2025-08-20 19:19:45.853519
9986	f0000043-0000-0000-0000-000000000043	4	2025-09-12 19:19:45.853519
9987	f0000043-0000-0000-0000-000000000043	5	2025-08-12 19:19:45.853519
9988	f0000043-0000-0000-0000-000000000043	6	2025-08-15 19:19:45.853519
9989	f0000044-0000-0000-0000-000000000044	1	2025-09-03 19:19:45.853519
9990	f0000044-0000-0000-0000-000000000044	4	2025-09-20 19:19:45.853519
9991	f0000045-0000-0000-0000-000000000045	1	2025-10-18 19:19:45.853519
9992	f0000045-0000-0000-0000-000000000045	2	2025-09-12 19:19:45.853519
9993	f0000046-0000-0000-0000-000000000046	1	2025-08-28 19:19:45.853519
9994	f0000046-0000-0000-0000-000000000046	4	2025-10-10 19:19:45.853519
9995	f0000046-0000-0000-0000-000000000046	5	2025-10-03 19:19:45.853519
9996	f0000047-0000-0000-0000-000000000047	1	2025-08-04 19:19:45.853519
9997	f0000047-0000-0000-0000-000000000047	3	2025-08-25 19:19:45.853519
9998	f0000047-0000-0000-0000-000000000047	5	2025-09-02 19:19:45.853519
9999	f0000047-0000-0000-0000-000000000047	6	2025-09-06 19:19:45.853519
10000	f0000048-0000-0000-0000-000000000048	1	2025-09-30 19:19:45.853519
10001	f0000048-0000-0000-0000-000000000048	2	2025-10-11 19:19:45.853519
10002	f0000048-0000-0000-0000-000000000048	5	2025-08-05 19:19:45.853519
10003	f0000048-0000-0000-0000-000000000048	6	2025-09-20 19:19:45.853519
10004	f0000049-0000-0000-0000-000000000049	1	2025-07-27 19:19:45.853519
10005	f0000049-0000-0000-0000-000000000049	2	2025-11-01 19:19:45.853519
10006	f0000049-0000-0000-0000-000000000049	5	2025-09-07 19:19:45.853519
10007	f0000050-0000-0000-0000-000000000050	1	2025-08-07 19:19:45.853519
10008	f0000050-0000-0000-0000-000000000050	4	2025-08-09 19:19:45.853519
10009	f0000051-0000-0000-0000-000000000051	1	2025-10-25 19:19:45.853519
10010	f0000051-0000-0000-0000-000000000051	2	2025-09-29 19:19:45.853519
10011	f0000051-0000-0000-0000-000000000051	3	2025-07-28 19:19:45.853519
10012	f0000051-0000-0000-0000-000000000051	5	2025-10-01 19:19:45.853519
10013	f0000052-0000-0000-0000-000000000052	1	2025-07-31 19:19:45.853519
10014	f0000052-0000-0000-0000-000000000052	2	2025-09-14 19:19:45.853519
10015	f0000052-0000-0000-0000-000000000052	4	2025-10-04 19:19:45.853519
10016	f0000052-0000-0000-0000-000000000052	5	2025-09-03 19:19:45.853519
10017	f0000053-0000-0000-0000-000000000053	1	2025-10-29 19:19:45.853519
10018	f0000053-0000-0000-0000-000000000053	2	2025-08-17 19:19:45.853519
10019	f0000053-0000-0000-0000-000000000053	3	2025-11-01 19:19:45.853519
10020	f0000053-0000-0000-0000-000000000053	5	2025-10-30 19:19:45.853519
10021	f0000054-0000-0000-0000-000000000054	1	2025-09-21 19:19:45.853519
10022	f0000054-0000-0000-0000-000000000054	4	2025-08-28 19:19:45.853519
10023	f0000054-0000-0000-0000-000000000054	5	2025-07-29 19:19:45.853519
10024	f0000055-0000-0000-0000-000000000055	1	2025-10-27 19:19:45.853519
10025	f0000055-0000-0000-0000-000000000055	2	2025-08-25 19:19:45.853519
10026	f0000055-0000-0000-0000-000000000055	3	2025-07-29 19:19:45.853519
10027	f0000055-0000-0000-0000-000000000055	5	2025-09-18 19:19:45.853519
10028	f0000056-0000-0000-0000-000000000056	1	2025-11-03 19:19:45.853519
10029	f0000056-0000-0000-0000-000000000056	3	2025-10-12 19:19:45.853519
10030	f0000056-0000-0000-0000-000000000056	5	2025-10-19 19:19:45.853519
10031	f0000056-0000-0000-0000-000000000056	6	2025-10-15 19:19:45.853519
10032	f0000057-0000-0000-0000-000000000057	1	2025-08-21 19:19:45.853519
10033	f0000057-0000-0000-0000-000000000057	2	2025-08-17 19:19:45.853519
10034	f0000057-0000-0000-0000-000000000057	4	2025-10-22 19:19:45.853519
10035	f0000057-0000-0000-0000-000000000057	5	2025-11-03 19:19:45.853519
10036	f0000057-0000-0000-0000-000000000057	6	2025-08-18 19:19:45.853519
10037	f0000058-0000-0000-0000-000000000058	1	2025-07-29 19:19:45.853519
10038	f0000058-0000-0000-0000-000000000058	3	2025-10-06 19:19:45.853519
10039	f0000058-0000-0000-0000-000000000058	4	2025-08-31 19:19:45.853519
10040	f0000058-0000-0000-0000-000000000058	5	2025-08-22 19:19:45.853519
10041	f0000058-0000-0000-0000-000000000058	6	2025-08-09 19:19:45.853519
10042	f0000059-0000-0000-0000-000000000059	1	2025-09-05 19:19:45.853519
10043	f0000060-0000-0000-0000-000000000060	1	2025-08-26 19:19:45.853519
10044	f0000060-0000-0000-0000-000000000060	3	2025-10-13 19:19:45.853519
10045	f0000060-0000-0000-0000-000000000060	5	2025-08-10 19:19:45.853519
10046	f0000060-0000-0000-0000-000000000060	6	2025-11-02 19:19:45.853519
10047	f0000061-0000-0000-0000-000000000061	1	2025-08-16 19:19:45.853519
10048	f0000061-0000-0000-0000-000000000061	4	2025-10-25 19:19:45.853519
\.


--
-- Data for Name: user_follows; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.user_follows (id, follower_id, following_id, created_at) FROM stdin;
\.


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.user_preferences (user_id, email_notifications, push_notifications, study_reminders, weekly_report, theme, font_size, auto_play_next_lesson, show_answer_explanation, playback_speed, profile_visibility, show_study_stats, updated_at, locale) FROM stdin;
a0000001-0000-0000-0000-000000000001	t	t	f	t	auto	medium	f	f	1.25	public	t	2025-11-04 19:19:45.860065	vi
a0000002-0000-0000-0000-000000000002	t	f	f	t	dark	large	f	t	0.94	friends	t	2025-11-04 19:19:45.860065	vi
b0000001-0000-0000-0000-000000000001	t	t	t	f	auto	large	t	t	1.88	public	t	2025-11-04 19:19:45.860065	vi
b0000002-0000-0000-0000-000000000002	t	t	t	t	dark	medium	f	t	1.25	private	t	2025-11-04 19:19:45.860065	vi
b0000003-0000-0000-0000-000000000003	t	t	t	t	light	large	t	t	1.93	friends	t	2025-11-04 19:19:45.860065	vi
b0000004-0000-0000-0000-000000000004	t	t	t	f	auto	large	f	t	1.28	friends	t	2025-11-04 19:19:45.860065	vi
f0000001-0000-0000-0000-000000000001	t	t	t	t	auto	large	t	t	1.59	private	t	2025-11-04 19:19:45.860065	vi
f0000002-0000-0000-0000-000000000002	t	f	t	t	light	large	f	t	0.95	private	t	2025-11-04 19:19:45.860065	vi
f0000004-0000-0000-0000-000000000004	t	t	f	t	auto	medium	f	t	1.47	private	t	2025-11-04 19:19:45.860065	vi
f0000005-0000-0000-0000-000000000005	t	t	f	t	auto	medium	t	t	0.99	private	t	2025-11-04 19:19:45.860065	vi
f0000006-0000-0000-0000-000000000006	t	t	f	t	dark	large	t	t	1.49	private	t	2025-11-04 19:19:45.860065	vi
f0000007-0000-0000-0000-000000000007	t	t	t	f	auto	large	t	t	1.22	private	t	2025-11-04 19:19:45.860065	vi
f0000008-0000-0000-0000-000000000008	f	t	f	t	auto	large	f	f	0.85	private	t	2025-11-04 19:19:45.860065	vi
f0000009-0000-0000-0000-000000000009	t	t	t	t	dark	medium	f	t	1.27	public	t	2025-11-04 19:19:45.860065	vi
f0000010-0000-0000-0000-000000000010	f	t	t	t	dark	large	t	t	1.87	private	t	2025-11-04 19:19:45.860065	vi
f0000011-0000-0000-0000-000000000011	t	t	t	t	auto	large	f	t	1.58	private	t	2025-11-04 19:19:45.860065	vi
f0000012-0000-0000-0000-000000000012	t	t	t	t	dark	large	f	t	1.02	private	t	2025-11-04 19:19:45.860065	vi
f0000013-0000-0000-0000-000000000013	f	t	f	t	light	large	f	t	0.76	public	f	2025-11-04 19:19:45.860065	vi
f0000014-0000-0000-0000-000000000014	f	t	t	f	auto	medium	t	t	1.24	friends	t	2025-11-04 19:19:45.860065	vi
f0000015-0000-0000-0000-000000000015	t	t	t	f	auto	large	t	f	0.79	private	t	2025-11-04 19:19:45.860065	vi
f0000016-0000-0000-0000-000000000016	t	t	f	t	dark	large	f	t	2.00	private	t	2025-11-04 19:19:45.860065	vi
f0000017-0000-0000-0000-000000000017	t	f	t	t	auto	large	t	t	1.07	friends	t	2025-11-04 19:19:45.860065	vi
f0000018-0000-0000-0000-000000000018	t	t	t	t	light	small	f	t	0.78	public	t	2025-11-04 19:19:45.860065	vi
f0000019-0000-0000-0000-000000000019	t	t	f	f	auto	medium	f	f	1.56	public	t	2025-11-04 19:19:45.860065	vi
f0000020-0000-0000-0000-000000000020	t	t	t	t	dark	large	t	t	1.90	friends	f	2025-11-04 19:19:45.860065	vi
f0000021-0000-0000-0000-000000000021	t	t	t	t	auto	large	t	t	1.08	public	t	2025-11-04 19:19:45.860065	vi
f0000022-0000-0000-0000-000000000022	t	t	f	f	auto	large	t	t	1.41	private	f	2025-11-04 19:19:45.860065	vi
f0000023-0000-0000-0000-000000000023	f	t	f	t	auto	small	f	t	1.10	private	f	2025-11-04 19:19:45.860065	vi
f0000024-0000-0000-0000-000000000024	t	t	t	t	auto	small	f	f	0.77	public	t	2025-11-04 19:19:45.860065	vi
f0000025-0000-0000-0000-000000000025	t	t	t	f	light	medium	f	t	1.22	friends	t	2025-11-04 19:19:45.860065	vi
f0000026-0000-0000-0000-000000000026	t	t	f	t	auto	medium	f	t	1.60	public	f	2025-11-04 19:19:45.860065	vi
f0000027-0000-0000-0000-000000000027	t	t	t	t	auto	large	f	t	1.46	friends	t	2025-11-04 19:19:45.860065	vi
f0000028-0000-0000-0000-000000000028	t	t	t	f	auto	large	f	t	1.78	friends	t	2025-11-04 19:19:45.860065	vi
f0000029-0000-0000-0000-000000000029	t	t	t	t	auto	large	f	t	0.87	private	f	2025-11-04 19:19:45.860065	vi
f0000030-0000-0000-0000-000000000030	t	t	f	t	auto	small	t	t	1.66	private	f	2025-11-04 19:19:45.860065	vi
f0000031-0000-0000-0000-000000000031	t	t	t	t	auto	large	t	t	0.78	private	t	2025-11-04 19:19:45.860065	vi
f0000032-0000-0000-0000-000000000032	f	t	t	t	dark	medium	f	t	0.83	public	f	2025-11-04 19:19:45.860065	vi
f0000033-0000-0000-0000-000000000033	t	t	t	f	auto	medium	t	t	1.20	friends	t	2025-11-04 19:19:45.860065	vi
f0000034-0000-0000-0000-000000000034	t	t	t	t	light	large	f	f	1.54	private	t	2025-11-04 19:19:45.860065	vi
f0000035-0000-0000-0000-000000000035	t	t	t	t	dark	medium	f	t	1.14	public	t	2025-11-04 19:19:45.860065	vi
f0000036-0000-0000-0000-000000000036	t	t	t	t	auto	small	t	f	1.28	private	f	2025-11-04 19:19:45.860065	vi
f0000037-0000-0000-0000-000000000037	t	t	f	t	dark	large	f	t	1.17	public	f	2025-11-04 19:19:45.860065	vi
f0000038-0000-0000-0000-000000000038	f	t	f	f	dark	medium	t	f	1.16	private	t	2025-11-04 19:19:45.860065	vi
f0000039-0000-0000-0000-000000000039	f	t	t	t	dark	medium	f	t	1.87	private	t	2025-11-04 19:19:45.860065	vi
f0000040-0000-0000-0000-000000000040	t	t	f	t	light	large	t	t	1.69	friends	f	2025-11-04 19:19:45.860065	vi
f0000041-0000-0000-0000-000000000041	t	t	t	t	dark	large	t	t	1.53	friends	t	2025-11-04 19:19:45.860065	vi
f0000042-0000-0000-0000-000000000042	t	t	f	f	auto	large	f	t	1.10	private	t	2025-11-04 19:19:45.860065	vi
f0000043-0000-0000-0000-000000000043	t	t	f	t	light	medium	f	f	1.59	friends	t	2025-11-04 19:19:45.860065	vi
f0000044-0000-0000-0000-000000000044	t	t	t	t	auto	large	t	t	0.81	friends	t	2025-11-04 19:19:45.860065	vi
f0000045-0000-0000-0000-000000000045	t	t	t	t	dark	large	t	t	1.80	friends	t	2025-11-04 19:19:45.860065	vi
f0000046-0000-0000-0000-000000000046	t	t	f	t	auto	medium	t	t	0.76	private	t	2025-11-04 19:19:45.860065	vi
f0000047-0000-0000-0000-000000000047	f	t	t	f	dark	large	f	t	1.03	private	t	2025-11-04 19:19:45.860065	vi
f0000048-0000-0000-0000-000000000048	t	f	f	f	auto	large	f	t	1.25	private	t	2025-11-04 19:19:45.860065	vi
f0000049-0000-0000-0000-000000000049	f	t	f	t	auto	large	t	t	0.94	private	t	2025-11-04 19:19:45.860065	vi
f0000050-0000-0000-0000-000000000050	t	f	f	f	auto	small	t	t	1.67	friends	t	2025-11-04 19:19:45.860065	vi
f0000051-0000-0000-0000-000000000051	t	t	t	f	dark	small	t	t	1.92	public	f	2025-11-04 19:19:45.860065	vi
f0000052-0000-0000-0000-000000000052	t	f	t	t	dark	large	t	t	1.57	friends	t	2025-11-04 19:19:45.860065	vi
f0000053-0000-0000-0000-000000000053	f	t	t	t	light	large	f	t	0.90	friends	t	2025-11-04 19:19:45.860065	vi
f0000054-0000-0000-0000-000000000054	t	f	t	t	dark	large	f	t	1.26	public	t	2025-11-04 19:19:45.860065	vi
f0000055-0000-0000-0000-000000000055	t	t	t	t	dark	large	f	t	1.61	friends	t	2025-11-04 19:19:45.860065	vi
f0000056-0000-0000-0000-000000000056	t	t	t	t	dark	large	t	t	1.23	public	f	2025-11-04 19:19:45.860065	vi
f0000057-0000-0000-0000-000000000057	t	f	f	f	light	medium	f	t	1.91	private	t	2025-11-04 19:19:45.860065	vi
f0000058-0000-0000-0000-000000000058	t	t	t	f	auto	large	f	t	1.02	friends	f	2025-11-04 19:19:45.860065	vi
f0000059-0000-0000-0000-000000000059	t	t	t	f	auto	large	t	t	0.76	private	t	2025-11-04 19:19:45.860065	vi
f0000060-0000-0000-0000-000000000060	t	f	t	t	dark	large	f	t	1.34	private	t	2025-11-04 19:19:45.860065	vi
f0000061-0000-0000-0000-000000000061	t	t	f	t	auto	large	t	t	1.10	private	t	2025-11-04 19:19:45.860065	vi
f0000003-0000-0000-0000-000000000003	t	t	t	t	auto	medium	t	t	1.85	friends	t	2025-11-05 16:24:13.302202	en
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: public; Owner: ielts_admin
--

COPY public.user_profiles (user_id, first_name, last_name, full_name, date_of_birth, gender, phone, address, city, country, timezone, avatar_url, cover_image_url, current_level, target_band_score, target_exam_date, bio, learning_preferences, language_preference, created_at, updated_at, deleted_at) FROM stdin;
a0000001-0000-0000-0000-000000000001	Admin	One	Admin One	1985-03-15	male	+84901234567	123 Admin St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	advanced	8.5	2025-06-01	Platform administrator with 10+ years experience in education technology.	{"daily_goal_minutes": 120, "study_time_preference": "morning"}	vi	2024-11-04 19:19:45.823143	2025-11-04 19:19:45.823143	\N
a0000002-0000-0000-0000-000000000002	Admin	Two	Admin Two	1988-07-22	female	+84901234568	456 Admin Ave	Hanoi	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	advanced	8.0	2025-05-15	System administrator passionate about educational technology.	{"daily_goal_minutes": 90, "study_time_preference": "afternoon"}	vi	2025-01-08 19:19:45.823143	2025-11-04 19:19:45.823143	\N
b0000001-0000-0000-0000-000000000001	Sarah	Mitchell	Sarah Mitchell	1980-05-10	female	+84901234572	789 Education Blvd	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	advanced	9.0	\N	IELTS expert with 15+ years teaching experience. Specialized in Listening and Speaking. CELTA certified.	{"daily_goal_minutes": 60, "study_time_preference": "morning"}	en	2025-05-08 19:19:45.823143	2025-11-04 19:19:45.823143	\N
b0000002-0000-0000-0000-000000000002	James	Anderson	James Anderson	1978-11-30	male	+84901234573	321 Teacher St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	advanced	9.0	\N	IELTS instructor specializing in Reading and Writing. Author of multiple IELTS preparation books.	{"daily_goal_minutes": 90, "study_time_preference": "evening"}	en	2025-05-13 19:19:45.823143	2025-11-04 19:19:45.823143	\N
b0000003-0000-0000-0000-000000000003	Emma	Thompson	Emma Thompson	1985-02-14	female	+84901234574	654 Academic Way	Hanoi	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200&h=400&fit=crop	advanced	8.5	\N	Experienced IELTS tutor with focus on Academic module. Help students achieve their dream scores.	{"daily_goal_minutes": 75, "study_time_preference": "morning"}	en	2025-05-18 19:19:45.823143	2025-11-04 19:19:45.823143	\N
b0000004-0000-0000-0000-000000000004	Michael	Chen	Michael Chen	1982-08-25	male	+84901234575	987 Language Lane	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	advanced	8.5	\N	Native English speaker teaching IELTS for 12 years. Passionate about helping Vietnamese students succeed.	{"daily_goal_minutes": 80, "study_time_preference": "afternoon"}	en	2025-05-23 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000001-0000-0000-0000-000000000001	Minh	Tran	Tran Minh	1995-06-20	male	+84901234587	123 Le Loi St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	elementary	6.5	2025-08-15	Student preparing for IELTS to study abroad. Focus on improving all skills.	{"daily_goal_minutes": 60, "study_time_preference": "evening"}	vi	2025-07-27 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000002-0000-0000-0000-000000000002	Lan	Nguyen	Nguyen Lan	1998-03-12	female	+84901234588	456 Nguyen Hue Blvd	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	pre-intermediate	7.0	2025-07-20	Working professional aiming for Band 7.0 to apply for work visa.	{"daily_goal_minutes": 45, "study_time_preference": "morning"}	vi	2025-08-01 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000003-0000-0000-0000-000000000003	Duc	Le	Le Duc	1996-09-08	male	+84901234589	789 Dong Khoi St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	intermediate	7.5	2025-09-10	University student planning to study Master degree abroad.	{"daily_goal_minutes": 90, "study_time_preference": "afternoon"}	vi	2025-08-06 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000004-0000-0000-0000-000000000004	Huyen	Pham	Pham Huyen	1997-12-25	female	+84901234590	321 Vo Van Tan St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200&h=400&fit=crop	beginner	5.5	2025-10-05	Just started learning IELTS. Motivated to improve step by step.	{"daily_goal_minutes": 30, "study_time_preference": "evening"}	vi	2025-08-11 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000005-0000-0000-0000-000000000005	Khoa	Hoang	Hoang Khoa	1994-04-18	male	+84901234591	654 Pasteur St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	upper-intermediate	8.0	2025-08-30	Professional aiming for Band 8.0 to immigrate to Australia.	{"daily_goal_minutes": 120, "study_time_preference": "morning"}	vi	2025-08-16 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000006-0000-0000-0000-000000000006	Thao	Vo	Vo Thao	1999-07-03	female	+84901234592	987 Mac Dinh Chi St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	intermediate	6.5	2025-09-15	High school student preparing for university admission.	{"daily_goal_minutes": 60, "study_time_preference": "afternoon"}	vi	2025-08-21 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000007-0000-0000-0000-000000000007	Nam	Bui	Bui Nam	1993-01-30	male	+84901234593	147 Nguyen Dinh Chieu St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	pre-intermediate	6.0	2025-11-20	Engineer preparing for IELTS to work overseas.	{"daily_goal_minutes": 75, "study_time_preference": "evening"}	vi	2025-08-26 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000008-0000-0000-0000-000000000008	Mai	Do	Do Mai	2000-05-15	female	+84901234594	258 Cao Thang St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	elementary	5.0	2026-01-10	College student beginning IELTS journey.	{"daily_goal_minutes": 45, "study_time_preference": "morning"}	vi	2025-08-31 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000009-0000-0000-0000-000000000009	Anh	Tran	Tran Anh	1995-10-22	male	+84901234595	369 Le Thanh Ton St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200&h=400&fit=crop	upper-intermediate	7.5	2025-07-05	MBA student targeting Band 7.5 for scholarship application.	{"daily_goal_minutes": 105, "study_time_preference": "afternoon"}	vi	2025-09-05 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000010-0000-0000-0000-000000000010	Phuong	Le	Le Phuong	1997-08-14	female	+84901234596	741 Hai Ba Trung St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	intermediate	6.5	2025-08-25	Marketing professional preparing for international opportunities.	{"daily_goal_minutes": 60, "study_time_preference": "evening"}	vi	2025-09-10 19:19:45.823143	2025-11-04 19:19:45.823143	\N
f0000011-0000-0000-0000-000000000011	Quang	Nguyen	Nguyen Quang	1992-12-12	male	+84900123466	1 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	elementary	4.6	2025-12-05	Nhân viên văn phòng muốn nâng cao trình độ tiếng Anh để thăng tiến. Mục tiêu Band 6.5 trong 6 tháng tới.	{"daily_goal_minutes": 35, "study_time_preference": "afternoon"}	vi	2025-07-29 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000012-0000-0000-0000-000000000012	Hung	Tran	Tran Hung	2003-10-27	male	+84900123476	2 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	pre-intermediate	4.7	2025-12-06	Học sinh cấp 3 chuẩn bị thi IELTS để apply đại học. Đang luyện tập hàng ngày với mục tiêu Band 6.0.	{"daily_goal_minutes": 40, "study_time_preference": "evening"}	vi	2025-07-31 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000013-0000-0000-0000-000000000013	Long	Le	Le Long	2001-06-12	male	+84900123486	3 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	intermediate	4.8	2025-12-07	Kỹ sư muốn di cư sang Canada. Cần Band 7.0 để đủ điểm Express Entry. Đang học IELTS được 3 tháng.	{"daily_goal_minutes": 45, "study_time_preference": "morning"}	vi	2025-08-02 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000014-0000-0000-0000-000000000014	Thanh	Pham	Pham Thanh	1992-03-15	male	+84900123496	4 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	upper-intermediate	4.9	2025-12-08	Giáo viên tiếng Anh muốn nâng cao chứng chỉ. Đã có nền tảng tốt, cần luyện thi để đạt Band 8.0.	{"daily_goal_minutes": 50, "study_time_preference": "afternoon"}	vi	2025-08-04 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000015-0000-0000-0000-000000000015	Dung	Hoang	Hoang Dung	1992-05-15	male	+84900123506	5 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	advanced	5.0	2025-12-09	Sinh viên năm 4 chuẩn bị tốt nghiệp. Cần IELTS để apply cao học ở nước ngoài. Đang tập trung Reading và Writing.	{"daily_goal_minutes": 55, "study_time_preference": "evening"}	vi	2025-08-06 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000016-0000-0000-0000-000000000016	Hai	Vo	Vo Hai	1993-11-24	male	+84900123516	6 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	beginner	5.1	2025-12-10	Nhân viên ngân hàng muốn làm việc ở chi nhánh quốc tế. Mục tiêu Band 7.5 trong 1 năm. Đã học được 6 tháng.	{"daily_goal_minutes": 60, "study_time_preference": "morning"}	vi	2025-08-08 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000017-0000-0000-0000-000000000017	Tuan	Bui	Bui Tuan	2000-08-05	male	+84900123526	7 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	elementary	5.2	2025-12-11	Học viên mới bắt đầu học IELTS. Chưa có nền tảng, đang học từ cơ bản với mục tiêu Band 5.5.	{"daily_goal_minutes": 65, "study_time_preference": "afternoon"}	vi	2025-08-10 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000018-0000-0000-0000-000000000018	Cuong	Do	Do Cuong	1998-01-28	male	+84900123536	8 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	pre-intermediate	5.3	2025-12-12	Freelancer muốn làm việc với khách hàng quốc tế. Cần IELTS để chứng minh khả năng giao tiếp. Mục tiêu Band 6.5.	{"daily_goal_minutes": 70, "study_time_preference": "evening"}	vi	2025-08-12 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000019-0000-0000-0000-000000000019	Kien	Truong	Truong Kien	1991-12-04	male	+84900123546	9 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	intermediate	5.4	2025-12-13	Học viên chăm chỉ, đã học IELTS được 1 năm. Đã đạt Band 6.0, đang cố gắng lên Band 7.0. Tập trung vào Listening và Speaking.	{"daily_goal_minutes": 75, "study_time_preference": "morning"}	vi	2025-08-14 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000020-0000-0000-0000-000000000020	Tien	Dang	Dang Tien	2000-12-03	male	+84900123556	10 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	upper-intermediate	5.5	2025-12-14	Bác sĩ muốn làm việc tại bệnh viện quốc tế. Cần IELTS Academic Band 7.0 để đáp ứng yêu cầu nghề nghiệp. Đang cải thiện từng kỹ năng.	{"daily_goal_minutes": 80, "study_time_preference": "afternoon"}	vi	2025-08-16 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000021-0000-0000-0000-000000000021	Binh	Ngo	Ngo Binh	2001-11-29	male	+84900123566	11 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	advanced	5.6	2025-12-15	Sinh viên kinh tế muốn học MBA ở Anh. Mục tiêu Band 7.5 để apply vào các trường top. Đã học được 8 tháng.	{"daily_goal_minutes": 85, "study_time_preference": "evening"}	vi	2025-08-18 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000022-0000-0000-0000-000000000022	Dat	Luu	Luu Dat	1996-12-03	male	+84900123576	12 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	beginner	5.7	2025-12-16	Nhà thiết kế đồ họa muốn làm việc tại agency quốc tế. Cần IELTS để chứng minh khả năng giao tiếp với khách hàng.	{"daily_goal_minutes": 90, "study_time_preference": "morning"}	vi	2025-08-20 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000023-0000-0000-0000-000000000023	Hieu	Ly	Ly Hieu	1993-06-29	male	+84900123586	13 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	elementary	5.8	2025-12-17	Nhân viên IT muốn relocate sang Singapore. Cần Band 7.0 để đủ điều kiện visa. Đang học IELTS được 4 tháng.	{"daily_goal_minutes": 95, "study_time_preference": "afternoon"}	vi	2025-08-22 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000024-0000-0000-0000-000000000024	Khang	Vu	Vu Khang	1999-09-22	male	+84900123596	14 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	pre-intermediate	5.9	2025-12-18	Sinh viên y khoa chuẩn bị thi PLAB để hành nghề tại UK. Cần IELTS Academic Band 7.5. Đang tập trung vào Reading và Writing.	{"daily_goal_minutes": 100, "study_time_preference": "evening"}	vi	2025-08-24 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000025-0000-0000-0000-000000000025	Huy	Dinh	Dinh Huy	2003-07-05	male	+84900123606	15 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	intermediate	6.0	2025-12-19	Nhân viên marketing muốn làm việc tại công ty đa quốc gia. Mục tiêu Band 6.5 trong 3 tháng tới.	{"daily_goal_minutes": 105, "study_time_preference": "morning"}	vi	2025-08-26 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000026-0000-0000-0000-000000000026	Lam	Dao	Dao Lam	2002-03-01	male	+84900123616	16 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	upper-intermediate	6.1	2025-12-20	Học sinh lớp 12 muốn apply vào đại học ở Úc. Cần Band 6.5 để đủ điều kiện nhập học. Đang luyện tập tích cực.	{"daily_goal_minutes": 110, "study_time_preference": "afternoon"}	vi	2025-08-28 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000027-0000-0000-0000-000000000027	Loc	Ho	Ho Loc	1991-11-15	male	+84900123626	17 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	advanced	6.2	2025-12-21	Luật sư muốn làm việc tại văn phòng luật quốc tế. Cần IELTS để chứng minh trình độ tiếng Anh chuyên nghiệp.	{"daily_goal_minutes": 115, "study_time_preference": "evening"}	vi	2025-08-30 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000028-0000-0000-0000-000000000028	Phuc	Phan	Phan Phuc	1996-03-07	male	+84900123636	18 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	beginner	6.3	2025-12-22	Giáo viên mầm non muốn làm việc tại trường quốc tế. Mục tiêu Band 7.0 để đáp ứng yêu cầu nghề nghiệp.	{"daily_goal_minutes": 120, "study_time_preference": "morning"}	vi	2025-09-01 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000029-0000-0000-0000-000000000029	Son	Duong	Duong Son	1993-10-14	male	+84900123646	19 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	elementary	6.4	2025-12-23	Kế toán viên muốn thi ACCA. Cần IELTS để đáp ứng yêu cầu của chứng chỉ. Đang học song song cả hai.	{"daily_goal_minutes": 125, "study_time_preference": "afternoon"}	vi	2025-09-03 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000030-0000-0000-0000-000000000030	Minh	Nguyen	Nguyen Minh	1992-09-29	male	+84900123656	20 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	pre-intermediate	6.5	2025-12-24	Sinh viên ngành du lịch muốn làm việc tại resort quốc tế. Cần IELTS để giao tiếp tốt với khách hàng.	{"daily_goal_minutes": 130, "study_time_preference": "evening"}	vi	2025-09-05 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000031-0000-0000-0000-000000000031	Duc	Tran	Tran Duc	1998-02-11	male	+84900123666	21 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	intermediate	6.6	2025-12-25	Nhân viên xuất nhập khẩu muốn làm việc với đối tác nước ngoài. Mục tiêu Band 6.5 để tự tin giao tiếp.	{"daily_goal_minutes": 135, "study_time_preference": "morning"}	vi	2025-09-07 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000032-0000-0000-0000-000000000032	Hoang	Le	Le Hoang	2004-05-05	male	+84900123676	22 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	upper-intermediate	6.7	2025-12-26	Học viên đã thi IELTS 2 lần nhưng chưa đạt mục tiêu. Đang học lại từ đầu với phương pháp mới.	{"daily_goal_minutes": 140, "study_time_preference": "afternoon"}	vi	2025-09-09 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000033-0000-0000-0000-000000000033	Khoa	Pham	Pham Khoa	1998-01-23	male	+84900123686	23 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	advanced	6.8	2025-12-27	Sinh viên kiến trúc muốn học thạc sĩ ở châu Âu. Cần Band 7.0 để apply học bổng. Đang tập trung Writing.	{"daily_goal_minutes": 145, "study_time_preference": "evening"}	vi	2025-09-11 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000034-0000-0000-0000-000000000034	Nam	Hoang	Hoang Nam	2000-02-28	male	+84900123696	24 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	beginner	6.9	2025-12-28	Nhân viên bán hàng muốn làm việc tại showroom quốc tế. Cần IELTS để giao tiếp tốt với khách hàng nước ngoài.	{"daily_goal_minutes": 150, "study_time_preference": "morning"}	vi	2025-09-13 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000035-0000-0000-0000-000000000035	Anh	Vo	Vo Anh	1993-07-18	male	+84900123706	25 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	elementary	7.0	2025-12-29	Sinh viên ngôn ngữ Anh muốn học sâu hơn về IELTS. Mục tiêu Band 8.0 để trở thành giáo viên IELTS.	{"daily_goal_minutes": 155, "study_time_preference": "afternoon"}	vi	2025-09-15 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000036-0000-0000-0000-000000000036	Hoa	Nguyen	Nguyen Hoa	1997-03-02	female	+84900123716	26 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	pre-intermediate	7.1	2025-12-30	Nhân viên hàng không muốn apply vào hãng bay quốc tế. Cần IELTS để đáp ứng yêu cầu tuyển dụng.	{"daily_goal_minutes": 160, "study_time_preference": "evening"}	vi	2025-09-17 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000037-0000-0000-0000-000000000037	Huong	Tran	Tran Huong	1996-10-22	female	+84900123726	27 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	intermediate	7.2	2025-12-31	Kỹ sư phần mềm muốn làm việc tại startup ở Silicon Valley. Cần IELTS để đủ điều kiện visa.	{"daily_goal_minutes": 165, "study_time_preference": "morning"}	vi	2025-09-19 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000038-0000-0000-0000-000000000038	Ly	Le	Le Ly	1992-09-05	female	+84900123736	28 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	upper-intermediate	7.3	2026-01-01	Sinh viên dược muốn làm việc tại nhà thuốc quốc tế. Mục tiêu Band 7.0 để đáp ứng yêu cầu nghề nghiệp.	{"daily_goal_minutes": 170, "study_time_preference": "afternoon"}	vi	2025-09-21 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000039-0000-0000-0000-000000000039	Nga	Pham	Pham Nga	1993-11-08	female	+84900123746	29 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	advanced	7.4	2026-01-02	Nhân viên tư vấn tài chính muốn làm việc tại công ty đa quốc gia. Cần IELTS để giao tiếp với khách hàng.	{"daily_goal_minutes": 175, "study_time_preference": "evening"}	vi	2025-09-23 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000040-0000-0000-0000-000000000040	Linh	Hoang	Hoang Linh	1999-08-08	female	+84900123756	30 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	beginner	7.5	2026-01-03	Học viên đã có bằng IELTS nhưng muốn nâng cao điểm số. Đang học lại để đạt Band 8.0.	{"daily_goal_minutes": 180, "study_time_preference": "morning"}	vi	2025-09-25 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000041-0000-0000-0000-000000000041	My	Vo	Vo My	2004-12-03	female	+84900123766	31 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	elementary	7.6	2026-01-04	Sinh viên MBA muốn làm việc tại consulting firm quốc tế. Cần IELTS để chứng minh khả năng tiếng Anh.	{"daily_goal_minutes": 185, "study_time_preference": "afternoon"}	vi	2025-09-27 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000042-0000-0000-0000-000000000042	Ngoc	Bui	Bui Ngoc	1995-08-17	female	+84900123776	32 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	pre-intermediate	7.7	2026-01-05	Nhân viên PR muốn làm việc tại agency quốc tế. Mục tiêu Band 7.5 để tự tin giao tiếp với media.	{"daily_goal_minutes": 190, "study_time_preference": "evening"}	vi	2025-09-29 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000043-0000-0000-0000-000000000043	Thu	Do	Do Thu	1993-10-24	female	+84900123786	33 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	intermediate	7.8	2026-01-06	Giáo viên Toán muốn làm việc tại trường quốc tế. Cần IELTS để đáp ứng yêu cầu giảng dạy bằng tiếng Anh.	{"daily_goal_minutes": 195, "study_time_preference": "morning"}	vi	2025-10-01 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000044-0000-0000-0000-000000000044	Trang	Truong	Truong Trang	2003-09-21	female	+84900123796	34 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	upper-intermediate	7.9	2026-01-07	Sinh viên ngành thời trang muốn học thạc sĩ ở London. Cần Band 7.0 để apply vào các trường danh tiếng.	{"daily_goal_minutes": 200, "study_time_preference": "afternoon"}	vi	2025-10-03 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000045-0000-0000-0000-000000000045	Van	Dang	Dang Van	2001-11-23	female	+84900123806	35 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	advanced	8.0	2026-01-08	Nhân viên nhân sự muốn làm việc tại công ty đa quốc gia. Cần IELTS để giao tiếp với nhân viên quốc tế.	{"daily_goal_minutes": 205, "study_time_preference": "evening"}	vi	2025-10-05 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000046-0000-0000-0000-000000000046	Yen	Ngo	Ngo Yen	2001-04-23	female	+84900123816	36 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	beginner	8.1	2026-01-09	Học viên đã học IELTS tại nhiều trung tâm nhưng chưa đạt mục tiêu. Đang thử phương pháp học online.	{"daily_goal_minutes": 210, "study_time_preference": "morning"}	vi	2025-10-07 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000047-0000-0000-0000-000000000047	Quynh	Luu	Luu Quynh	1992-01-10	female	+84900123826	37 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	elementary	8.2	2026-01-10	Sinh viên ngành môi trường muốn làm việc tại tổ chức quốc tế. Cần IELTS để tham gia các dự án quốc tế.	{"daily_goal_minutes": 215, "study_time_preference": "afternoon"}	vi	2025-10-09 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000048-0000-0000-0000-000000000048	Diem	Ly	Ly Diem	2000-10-04	female	+84900123836	38 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	pre-intermediate	8.3	2026-01-11	Nhân viên logistics muốn làm việc tại công ty vận tải quốc tế. Mục tiêu Band 6.5 để giao tiếp tốt.	{"daily_goal_minutes": 220, "study_time_preference": "evening"}	vi	2025-10-11 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000049-0000-0000-0000-000000000049	Giang	Vu	Vu Giang	2003-12-20	female	+84900123846	39 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	intermediate	8.4	2026-01-12	Kỹ sư xây dựng muốn làm việc tại dự án quốc tế. Cần IELTS để đọc hiểu tài liệu kỹ thuật.	{"daily_goal_minutes": 225, "study_time_preference": "morning"}	vi	2025-10-13 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000050-0000-0000-0000-000000000050	Khanh	Dinh	Dinh Khanh	1990-01-10	female	+84900123856	40 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	upper-intermediate	8.5	2026-01-13	Sinh viên ngành truyền thông muốn làm việc tại media quốc tế. Cần IELTS để viết bài và phỏng vấn.	{"daily_goal_minutes": 230, "study_time_preference": "afternoon"}	vi	2025-10-15 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000051-0000-0000-0000-000000000051	Ha	Dao	Dao Ha	1994-01-12	female	+84900123866	41 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	advanced	4.5	2026-01-14	Nhân viên chăm sóc khách hàng muốn làm việc tại call center quốc tế. Cần IELTS để giao tiếp tốt.	{"daily_goal_minutes": 235, "study_time_preference": "evening"}	vi	2025-10-17 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000052-0000-0000-0000-000000000052	Nhung	Ho	Ho Nhung	1998-08-06	female	+84900123876	42 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	beginner	4.6	2026-01-15	Sinh viên đại học chuẩn bị đi du học. Mong muốn đạt Band 7.0 để apply học bổng. Đang tập trung cải thiện Writing và Speaking.	{"daily_goal_minutes": 240, "study_time_preference": "morning"}	vi	2025-10-19 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000053-0000-0000-0000-000000000053	Hong	Phan	Phan Hong	2001-10-28	female	+84900123886	43 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	elementary	4.7	2026-01-16	Nhân viên văn phòng muốn nâng cao trình độ tiếng Anh để thăng tiến. Mục tiêu Band 6.5 trong 6 tháng tới.	{"daily_goal_minutes": 245, "study_time_preference": "afternoon"}	vi	2025-10-21 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000054-0000-0000-0000-000000000054	Bich	Duong	Duong Bich	1994-08-24	female	+84900123896	44 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	pre-intermediate	4.8	2026-01-17	Học sinh cấp 3 chuẩn bị thi IELTS để apply đại học. Đang luyện tập hàng ngày với mục tiêu Band 6.0.	{"daily_goal_minutes": 250, "study_time_preference": "evening"}	vi	2025-10-23 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000055-0000-0000-0000-000000000055	Hanh	Nguyen	Nguyen Hanh	2000-08-17	female	+84900123906	45 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	intermediate	4.9	2026-01-18	Kỹ sư muốn di cư sang Canada. Cần Band 7.0 để đủ điểm Express Entry. Đang học IELTS được 3 tháng.	{"daily_goal_minutes": 255, "study_time_preference": "morning"}	vi	2025-10-25 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000056-0000-0000-0000-000000000056	Diep	Tran	Tran Diep	1998-11-16	female	+84900123916	46 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	upper-intermediate	5.0	2026-01-19	Giáo viên tiếng Anh muốn nâng cao chứng chỉ. Đã có nền tảng tốt, cần luyện thi để đạt Band 8.0.	{"daily_goal_minutes": 260, "study_time_preference": "afternoon"}	vi	2025-10-27 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000057-0000-0000-0000-000000000057	Lan	Le	Le Lan	2003-07-09	female	+84900123926	47 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	advanced	5.1	2026-01-20	Sinh viên năm 4 chuẩn bị tốt nghiệp. Cần IELTS để apply cao học ở nước ngoài. Đang tập trung Reading và Writing.	{"daily_goal_minutes": 265, "study_time_preference": "evening"}	vi	2025-10-29 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000058-0000-0000-0000-000000000058	Huyen	Pham	Pham Huyen	1998-02-06	female	+84900123936	48 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&h=400&fit=crop	beginner	5.2	2026-01-21	Nhân viên ngân hàng muốn làm việc ở chi nhánh quốc tế. Mục tiêu Band 7.5 trong 1 năm. Đã học được 6 tháng.	{"daily_goal_minutes": 270, "study_time_preference": "morning"}	vi	2025-10-31 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000059-0000-0000-0000-000000000059	Phuong	Hoang	Hoang Phuong	1994-01-05	female	+84900123946	49 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop	elementary	5.3	2026-01-22	Học viên mới bắt đầu học IELTS. Chưa có nền tảng, đang học từ cơ bản với mục tiêu Band 5.5.	{"daily_goal_minutes": 275, "study_time_preference": "afternoon"}	vi	2025-11-02 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000060-0000-0000-0000-000000000060	Thao	Vo	Vo Thao	1990-09-19	female	+84900123956	50 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&h=400&fit=crop	pre-intermediate	5.4	2026-01-23	Freelancer muốn làm việc với khách hàng quốc tế. Cần IELTS để chứng minh khả năng giao tiếp. Mục tiêu Band 6.5.	{"daily_goal_minutes": 280, "study_time_preference": "evening"}	vi	2025-11-04 19:19:45.82703	2025-11-04 19:19:45.82703	\N
f0000061-0000-0000-0000-000000000061	Mai	Bui	Bui Mai	1997-05-15	female	+84900123966	51 Student St	Ho Chi Minh City	Vietnam	Asia/Ho_Chi_Minh	https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop	https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&h=400&fit=crop	intermediate	5.5	2026-01-24	Học viên chăm chỉ, đã học IELTS được 1 năm. Đã đạt Band 6.0, đang cố gắng lên Band 7.0. Tập trung vào Listening và Speaking.	{"daily_goal_minutes": 285, "study_time_preference": "morning"}	vi	2025-11-06 19:19:45.82703	2025-11-04 19:19:45.82703	\N
\.


--
-- Name: achievements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.achievements_id_seq', 6, true);


--
-- Name: learning_progress_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.learning_progress_id_seq', 2977, true);


--
-- Name: schema_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.schema_migrations_id_seq', 18, true);


--
-- Name: skill_statistics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.skill_statistics_id_seq', 9245, true);


--
-- Name: user_achievements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.user_achievements_id_seq', 10048, true);


--
-- Name: user_follows_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ielts_admin
--

SELECT pg_catalog.setval('public.user_follows_id_seq', 85, true);


--
-- Name: achievements achievements_code_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT achievements_code_key UNIQUE (code);


--
-- Name: achievements achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT achievements_pkey PRIMARY KEY (id);


--
-- Name: learning_progress learning_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.learning_progress
    ADD CONSTRAINT learning_progress_pkey PRIMARY KEY (id);


--
-- Name: learning_progress learning_progress_user_id_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.learning_progress
    ADD CONSTRAINT learning_progress_user_id_key UNIQUE (user_id);


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
-- Name: skill_statistics skill_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.skill_statistics
    ADD CONSTRAINT skill_statistics_pkey PRIMARY KEY (id);


--
-- Name: skill_statistics skill_statistics_user_id_skill_type_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.skill_statistics
    ADD CONSTRAINT skill_statistics_user_id_skill_type_key UNIQUE (user_id, skill_type);


--
-- Name: study_goals study_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.study_goals
    ADD CONSTRAINT study_goals_pkey PRIMARY KEY (id);


--
-- Name: study_reminders study_reminders_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.study_reminders
    ADD CONSTRAINT study_reminders_pkey PRIMARY KEY (id);


--
-- Name: study_sessions study_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.study_sessions
    ADD CONSTRAINT study_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_achievements user_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_pkey PRIMARY KEY (id);


--
-- Name: user_achievements user_achievements_user_id_achievement_id_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_id_achievement_id_key UNIQUE (user_id, achievement_id);


--
-- Name: user_follows user_follows_follower_id_following_id_key; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_follows
    ADD CONSTRAINT user_follows_follower_id_following_id_key UNIQUE (follower_id, following_id);


--
-- Name: user_follows user_follows_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_follows
    ADD CONSTRAINT user_follows_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: idx_learning_progress_streak; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_learning_progress_streak ON public.learning_progress USING btree (user_id, current_streak_days DESC);


--
-- Name: INDEX idx_learning_progress_streak; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON INDEX public.idx_learning_progress_streak IS 'Optimize streak queries for leaderboard display';


--
-- Name: idx_learning_progress_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_learning_progress_user_id ON public.learning_progress USING btree (user_id);


--
-- Name: idx_skill_statistics_skill_type; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_skill_statistics_skill_type ON public.skill_statistics USING btree (skill_type);


--
-- Name: idx_skill_statistics_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_skill_statistics_user_id ON public.skill_statistics USING btree (user_id);


--
-- Name: idx_study_goals_end_date; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_goals_end_date ON public.study_goals USING btree (end_date);


--
-- Name: idx_study_goals_status; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_goals_status ON public.study_goals USING btree (status);


--
-- Name: idx_study_goals_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_goals_user_id ON public.study_goals USING btree (user_id);


--
-- Name: idx_study_reminders_next_send_at; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_reminders_next_send_at ON public.study_reminders USING btree (next_send_at) WHERE (is_active = true);


--
-- Name: idx_study_reminders_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_reminders_user_id ON public.study_reminders USING btree (user_id);


--
-- Name: idx_study_sessions_skill_type; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_sessions_skill_type ON public.study_sessions USING btree (skill_type);


--
-- Name: idx_study_sessions_started_at; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_sessions_started_at ON public.study_sessions USING btree (started_at);


--
-- Name: idx_study_sessions_user_duration; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_sessions_user_duration ON public.study_sessions USING btree (user_id, duration_minutes);


--
-- Name: INDEX idx_study_sessions_user_duration; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON INDEX public.idx_study_sessions_user_duration IS 'Optimize SUM(duration_minutes) aggregation for leaderboard';


--
-- Name: idx_study_sessions_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_study_sessions_user_id ON public.study_sessions USING btree (user_id);


--
-- Name: idx_user_achievements_earned_at; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_achievements_earned_at ON public.user_achievements USING btree (earned_at);


--
-- Name: idx_user_achievements_user_earned; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_achievements_user_earned ON public.user_achievements USING btree (user_id, earned_at DESC);


--
-- Name: INDEX idx_user_achievements_user_earned; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON INDEX public.idx_user_achievements_user_earned IS 'Optimize achievement queries with date sorting';


--
-- Name: idx_user_achievements_user_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_achievements_user_id ON public.user_achievements USING btree (user_id);


--
-- Name: idx_user_achievements_user_id_count; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_achievements_user_id_count ON public.user_achievements USING btree (user_id);


--
-- Name: INDEX idx_user_achievements_user_id_count; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON INDEX public.idx_user_achievements_user_id_count IS 'Optimize COUNT(*) queries for achievements in leaderboard';


--
-- Name: idx_user_follows_created_at; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_follows_created_at ON public.user_follows USING btree (created_at DESC);


--
-- Name: idx_user_follows_follower_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_follows_follower_id ON public.user_follows USING btree (follower_id);


--
-- Name: idx_user_follows_following_id; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_follows_following_id ON public.user_follows USING btree (following_id);


--
-- Name: idx_user_profiles_country; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_profiles_country ON public.user_profiles USING btree (country);


--
-- Name: idx_user_profiles_current_level; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_profiles_current_level ON public.user_profiles USING btree (current_level);


--
-- Name: idx_user_profiles_leaderboard; Type: INDEX; Schema: public; Owner: ielts_admin
--

CREATE INDEX idx_user_profiles_leaderboard ON public.user_profiles USING btree (user_id, full_name) WHERE (full_name IS NOT NULL);


--
-- Name: INDEX idx_user_profiles_leaderboard; Type: COMMENT; Schema: public; Owner: ielts_admin
--

COMMENT ON INDEX public.idx_user_profiles_leaderboard IS 'Optimize user profile lookups in leaderboard';


--
-- Name: learning_progress update_learning_progress_updated_at; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER update_learning_progress_updated_at BEFORE UPDATE ON public.learning_progress FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: skill_statistics update_skill_statistics_updated_at; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER update_skill_statistics_updated_at BEFORE UPDATE ON public.skill_statistics FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: study_goals update_study_goals_updated_at; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER update_study_goals_updated_at BEFORE UPDATE ON public.study_goals FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_profiles update_user_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: ielts_admin
--

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: learning_progress learning_progress_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.learning_progress
    ADD CONSTRAINT learning_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- Name: skill_statistics skill_statistics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.skill_statistics
    ADD CONSTRAINT skill_statistics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- Name: study_goals study_goals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.study_goals
    ADD CONSTRAINT study_goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- Name: study_reminders study_reminders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.study_reminders
    ADD CONSTRAINT study_reminders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- Name: study_sessions study_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.study_sessions
    ADD CONSTRAINT study_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- Name: user_achievements user_achievements_achievement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_achievement_id_fkey FOREIGN KEY (achievement_id) REFERENCES public.achievements(id) ON DELETE CASCADE;


--
-- Name: user_achievements user_achievements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- Name: user_follows user_follows_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_follows
    ADD CONSTRAINT user_follows_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- Name: user_follows user_follows_following_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_follows
    ADD CONSTRAINT user_follows_following_id_fkey FOREIGN KEY (following_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ielts_admin
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(user_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

