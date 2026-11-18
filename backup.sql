--
-- PostgreSQL database dump
--

\restrict IBsv3uKpa9L2Zi1cnB1LEgYv9vYmuVbN5m3bksndTetVkx0SEjpgffZD8XAmz4p

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg12+2)
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_user (
    user_id integer NOT NULL,
    given_name character varying(100) NOT NULL,
    surname character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    affiliation character varying(255) NOT NULL,
    country character varying(100) NOT NULL,
    phone_number character varying(30) NOT NULL
);


--
-- Name: conference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conference (
    conference_id integer NOT NULL,
    name character varying(255) NOT NULL,
    acronym character varying(50) NOT NULL,
    description text NOT NULL,
    city character varying(100) NOT NULL,
    country character varying(100) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    submission_deadline date NOT NULL,
    review_deadline date NOT NULL,
    CONSTRAINT chk_conference_dates CHECK ((end_date >= start_date))
);


--
-- Name: conference_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conference_session (
    session_id integer NOT NULL,
    conference_id integer NOT NULL,
    title character varying(255) NOT NULL,
    session_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    room_label character varying(100) NOT NULL,
    chair_id integer NOT NULL,
    CONSTRAINT chk_session_times CHECK ((end_time > start_time))
);


--
-- Name: paper; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paper (
    paper_id integer NOT NULL,
    track_id integer NOT NULL,
    title character varying(300) NOT NULL,
    abstract text NOT NULL,
    submission_date date NOT NULL,
    status character varying(20) NOT NULL,
    session_id integer,
    CONSTRAINT paper_status_check CHECK (((status)::text = ANY ((ARRAY['submitted'::character varying, 'under review'::character varying, 'accepted'::character varying, 'rejected'::character varying, 'withdrawn'::character varying])::text[])))
);


--
-- Name: paper_author; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paper_author (
    paper_id integer NOT NULL,
    author_id integer NOT NULL,
    author_position integer NOT NULL,
    is_corresponding boolean DEFAULT false NOT NULL,
    CONSTRAINT paper_author_author_position_check CHECK ((author_position >= 1))
);


--
-- Name: track; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.track (
    track_id integer NOT NULL,
    conference_id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text NOT NULL,
    research_area character varying(120) NOT NULL,
    coordinator_id integer NOT NULL
);


--
-- Name: accepted_paper_schedule; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.accepted_paper_schedule AS
 SELECT p.paper_id,
    p.title AS paper_title,
    c.conference_id,
    c.acronym AS conference_acronym,
    t.name AS track_name,
    cs.session_id,
    cs.title AS session_title,
    cs.session_date,
    cs.start_time,
    cs.end_time,
    cs.room_label,
    (((chair_u.given_name)::text || ' '::text) || (chair_u.surname)::text) AS chair_full_name,
    (((auth_u.given_name)::text || ' '::text) || (auth_u.surname)::text) AS corresponding_author_full_name,
    auth_u.email AS corresponding_author_email
   FROM ((((((public.paper p
     JOIN public.conference_session cs ON ((cs.session_id = p.session_id)))
     JOIN public.track t ON ((t.track_id = p.track_id)))
     JOIN public.conference c ON ((c.conference_id = t.conference_id)))
     JOIN public.app_user chair_u ON ((chair_u.user_id = cs.chair_id)))
     JOIN public.paper_author pa ON (((pa.paper_id = p.paper_id) AND (pa.is_corresponding = true))))
     JOIN public.app_user auth_u ON ((auth_u.user_id = pa.author_id)))
  WHERE ((p.status)::text = 'accepted'::text);


--
-- Name: app_user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.app_user ALTER COLUMN user_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.app_user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: author; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.author (
    author_id integer NOT NULL,
    orcid character varying(25)
);


--
-- Name: author_research_area; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.author_research_area (
    author_id integer NOT NULL,
    area_label character varying(120) NOT NULL
);


--
-- Name: conference_conference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.conference ALTER COLUMN conference_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.conference_conference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: conference_host; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conference_host (
    conference_id integer NOT NULL,
    host_name character varying(255) NOT NULL
);


--
-- Name: conference_reviewer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conference_reviewer (
    conference_id integer NOT NULL,
    reviewer_id integer NOT NULL
);


--
-- Name: conference_session_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.conference_session ALTER COLUMN session_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.conference_session_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: paper_keyword; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paper_keyword (
    paper_id integer NOT NULL,
    keyword character varying(100) NOT NULL
);


--
-- Name: paper_paper_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.paper ALTER COLUMN paper_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.paper_paper_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: paper_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paper_version (
    paper_id integer NOT NULL,
    version_no integer NOT NULL,
    file_location character varying(500) NOT NULL,
    uploaded_at timestamp without time zone NOT NULL,
    change_note text,
    CONSTRAINT paper_version_version_no_check CHECK ((version_no >= 1))
);


--
-- Name: review; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review (
    review_id integer NOT NULL,
    paper_id integer NOT NULL,
    reviewer_id integer NOT NULL,
    overall_score integer NOT NULL,
    recommendation character varying(10) NOT NULL,
    comments_for_authors text NOT NULL,
    confidential_comments text,
    review_submission_date date NOT NULL,
    CONSTRAINT review_overall_score_check CHECK (((overall_score >= 1) AND (overall_score <= 5))),
    CONSTRAINT review_recommendation_check CHECK (((recommendation)::text = ANY ((ARRAY['accept'::character varying, 'reject'::character varying])::text[])))
);


--
-- Name: review_review_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.review ALTER COLUMN review_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.review_review_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reviewer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviewer (
    reviewer_id integer NOT NULL,
    years_experience integer NOT NULL,
    CONSTRAINT reviewer_years_experience_check CHECK ((years_experience >= 0))
);


--
-- Name: reviewer_expertise; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviewer_expertise (
    reviewer_id integer NOT NULL,
    area_label character varying(120) NOT NULL
);


--
-- Name: track_track_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.track ALTER COLUMN track_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.track_track_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: app_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_user (user_id, given_name, surname, email, affiliation, country, phone_number) FROM stdin;
1	Arman	Armanov	arman.armanov@example.com	Nazarbayev University	Kazakhstan	+77011112233
2	Amina	Aminova	amina.aminova@example.com	Astana IT University	Kazakhstan	+77022223344
3	Daniyar	Bekov	daniyar.bekov@example.com	KBTU	Kazakhstan	+77033334455
4	Elena	Petrova	elena.petrova@example.com	TU Wien	Austria	+43158801001
5	Timur	Kassymov	timur.kassymov@example.com	Suleyman Demirel University	Kazakhstan	+77055556677
6	Madina	Omarova	madina.omarova@example.com	Satbayev University	Kazakhstan	+77066667788
7	Lukas	Gruber	lukas.gruber@example.com	University of Vienna	Austria	+4314277002
8	Aigerim	Nurlanova	aigerim.nurlanova@example.com	Nazarbayev University	Kazakhstan	+77088889900
9	Murat	Tolegenov	murat.tolegenov@example.com	Eurasian National University	Kazakhstan	+77099990011
10	Sofia	Rossi	sofia.rossi@example.com	Politecnico di Milano	Italy	+39022399001
11	Nurlan	Seitov	nurlan.seitov@example.com	Nazarbayev University	Kazakhstan	+77012345678
12	Klara	Novak	klara.novak@example.com	Charles University	Czech Republic	+420221911001
\.


--
-- Data for Name: author; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.author (author_id, orcid) FROM stdin;
1	0000-0001-1001-0001
2	0000-0001-1001-0002
3	0000-0001-1001-0003
4	0000-0001-1001-0004
5	\N
6	0000-0001-1001-0006
10	0000-0001-1001-0010
11	\N
12	0000-0001-1001-0012
\.


--
-- Data for Name: author_research_area; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.author_research_area (author_id, area_label) FROM stdin;
1	Databases
1	Distributed Systems
2	Machine Learning
2	Data Mining
3	Machine Learning
3	Natural Language Processing
4	Databases
4	Query Optimization
5	Computer Vision
5	Machine Learning
6	Cybersecurity
6	Cloud Computing
10	Distributed Systems
10	Cloud Computing
11	Artificial Intelligence
11	Machine Learning
12	Data Mining
12	Databases
\.


--
-- Data for Name: conference; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conference (conference_id, name, acronym, description, city, country, start_date, end_date, submission_deadline, review_deadline) FROM stdin;
1	Central Asian Conference on Data and Intelligent Systems	CACDIS 2026	Annual international forum on database systems, AI, and scalable computing held in Astana.	Astana	Kazakhstan	2026-10-15	2026-10-17	2026-07-01	2026-08-15
2	Eurasian Symposium on Software and Cloud Engineering	ESSCE 2026	Regional symposium covering cloud architectures, cybersecurity, and machine learning applications.	Almaty	Kazakhstan	2026-11-05	2026-11-07	2026-07-20	2026-09-01
3	Danube Workshop on Next-Generation Data Management	DWNDM 2026	Focused European workshop on modern storage engines and distributed query processing.	Vienna	Austria	2026-12-10	2026-12-10	2026-09-15	2026-10-25
\.


--
-- Data for Name: conference_host; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conference_host (conference_id, host_name) FROM stdin;
1	Nazarbayev University
1	Astana IT University
2	KBTU
2	Satbayev University
3	TU Wien
\.


--
-- Data for Name: conference_reviewer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conference_reviewer (conference_id, reviewer_id) FROM stdin;
1	1
1	3
1	4
1	7
1	8
1	9
1	10
1	11
2	1
2	3
2	4
2	8
2	10
2	11
3	4
3	7
3	10
3	12
\.


--
-- Data for Name: conference_session; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conference_session (session_id, conference_id, title, session_date, start_time, end_time, room_label, chair_id) FROM stdin;
1	1	Advances in Relational and Distributed Databases	2026-10-15	09:30:00	11:00:00	Room C3.101	4
2	1	Machine Learning in Practice	2026-10-15	14:00:00	15:30:00	Main Auditorium	8
3	1	Late-Breaking Posters & Demos	2026-10-16	10:00:00	11:30:00	Hall B	7
4	1	Industry Panel on Data Governance	2026-10-17	13:00:00	14:30:00	Room C3.204	1
5	2	Cloud-Native Systems	2026-11-05	10:00:00	12:00:00	Almaty Hall 1	10
6	2	Almaty Evening Workshop	2026-11-06	16:00:00	17:30:00	Almaty Room 202	11
\.


--
-- Data for Name: paper; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.paper (paper_id, track_id, title, abstract, submission_date, status, session_id) FROM stdin;
1	1	Adaptive Cost-Based Query Optimization for Hybrid Cloud Databases	We propose an adaptive query optimizer that integrates machine learning cardinality estimators with classical cost models for hybrid workloads.	2026-06-25	accepted	1
2	1	Deterministic Consensus Protocols for Geo-Replicated Storage	This paper presents a low-latency consensus protocol minimizing cross-datacenter round trips in distributed relational storage engines.	2026-06-28	accepted	1
3	2	Transformer Embeddings for Low-Resource Turkic Languages	We evaluate multilingual transformer architectures and machine learning transfer techniques for Kazakh and Uzbek morphological analysis.	2026-06-29	accepted	2
4	2	Federated Anomaly Detection in Smart Grid Telemetry	A privacy-preserving federated learning framework for detecting sensor anomalies across regional power grids.	2026-06-30	accepted	\N
5	1	Heuristic Join Ordering Without Statistics	An experimental study of rule-based join ordering heuristics on synthetic star schemas.	2026-06-27	rejected	\N
6	2	Graph Neural Networks for Academic Citation Prediction	We apply graph machine learning models to predict long-term citation trajectories of conference papers.	2026-06-20	withdrawn	\N
7	4	Serverless Container Scheduling Under Burst Workloads	We design a predictive autoscaler using lightweight machine learning regressors to reduce cold-start latency in serverless clusters.	2026-07-15	accepted	5
8	4	Zero-Trust Microsegmentation for Multi-Tenant Clouds	Automated policy synthesis for zero-trust network isolation across Kubernetes clusters.	2026-07-18	accepted	\N
9	5	Static Signature Matching for Encrypted Traffic	A comparative evaluation of packet-length heuristics for classifying encrypted TLS flows.	2026-07-19	rejected	\N
10	5	Incremental Frequent Itemset Mining on Streaming Logs	A sliding-window algorithm for mining frequent patterns in high-velocity system logs.	2026-07-10	withdrawn	\N
11	4	Energy-Aware VM Consolidation in Edge Data Centers	Multi-objective optimization for migrating virtual machines across renewable-powered edge nodes.	2026-07-20	under review	\N
12	5	Explainable Credit Scoring Using Symbolic Rule Extraction	Extracting human-readable decision rules from ensemble classifiers for regulated financial applications.	2026-07-20	submitted	\N
\.


--
-- Data for Name: paper_author; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.paper_author (paper_id, author_id, author_position, is_corresponding) FROM stdin;
1	1	1	t
1	4	2	f
2	4	1	t
2	1	2	f
2	10	3	f
3	3	1	t
3	2	2	f
3	11	3	f
4	5	1	t
4	3	2	f
5	12	1	t
6	2	1	t
6	5	2	f
7	10	1	t
7	6	2	f
8	6	1	t
9	6	1	t
9	12	2	f
10	2	1	t
11	1	1	t
11	10	2	f
12	11	1	t
12	2	2	f
\.


--
-- Data for Name: paper_keyword; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.paper_keyword (paper_id, keyword) FROM stdin;
1	Query Optimization
1	Databases
1	Machine Learning
2	Distributed Systems
2	Consensus
2	Databases
3	Natural Language Processing
3	Machine Learning
3	Kazakh NLP
4	Federated Learning
4	Anomaly Detection
5	Join Ordering
5	Query Execution
6	Graph Neural Networks
6	Machine Learning
7	Serverless Computing
7	Cloud Computing
7	Machine Learning
8	Zero-Trust Security
8	Kubernetes
9	Network Security
9	Traffic Analysis
10	Data Mining
10	Streaming Algorithms
11	Edge Computing
11	Green IT
12	Explainable AI
12	Rule Extraction
\.


--
-- Data for Name: paper_version; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.paper_version (paper_id, version_no, file_location, uploaded_at, change_note) FROM stdin;
1	1	/storage/papers/paper_01_v1.pdf	2026-06-25 10:15:00	Initial submission
1	2	/storage/papers/paper_01_v2.pdf	2026-06-30 18:40:00	Expanded TPC-H experimental benchmarks
1	4	/storage/papers/paper_01_v4.pdf	2026-09-10 09:00:00	Camera-ready revision addressing reviewer comments
2	1	/storage/papers/paper_02_v1.pdf	2026-06-28 14:20:00	Initial draft
2	2	/storage/papers/paper_02_v2.pdf	2026-09-12 11:05:00	Camera-ready final version
3	1	/storage/papers/paper_03_v1.pdf	2026-06-29 16:00:00	Original submission
3	2	/storage/papers/paper_03_v2.pdf	2026-09-14 15:30:00	Added ablation tables for camera-ready
4	1	/storage/papers/paper_04_v1.pdf	2026-06-30 21:10:00	\N
5	1	/storage/papers/paper_05_v1.pdf	2026-06-27 09:45:00	Initial submission
6	1	/storage/papers/paper_06_v1.pdf	2026-06-20 12:00:00	First submission
6	2	/storage/papers/paper_06_v2.pdf	2026-07-05 14:15:00	Updated dataset section prior to withdrawal
7	1	/storage/papers/paper_07_v1.pdf	2026-07-15 11:30:00	Submitted manuscript
7	2	/storage/papers/paper_07_v2.pdf	2026-09-25 17:45:00	Camera-ready manuscript
8	1	/storage/papers/paper_08_v1.pdf	2026-07-18 19:20:00	\N
9	1	/storage/papers/paper_09_v1.pdf	2026-07-19 08:50:00	Initial submission
10	1	/storage/papers/paper_10_v1.pdf	2026-07-10 13:10:00	Initial version
11	1	/storage/papers/paper_11_v1.pdf	2026-07-20 22:00:00	\N
12	1	/storage/papers/paper_12_v1.pdf	2026-07-20 23:30:00	Submitted prior to deadline
\.


--
-- Data for Name: review; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.review (review_id, paper_id, reviewer_id, overall_score, recommendation, comments_for_authors, confidential_comments, review_submission_date) FROM stdin;
1	1	7	5	accept	Strong hybrid estimator design and clear experimental validation.	Top-tier database paper.	2026-08-05
2	1	3	4	accept	Solid results; please clarify training overhead on dynamic schemas.	\N	2026-08-08
3	2	7	5	accept	Rigorous correctness proof and impressive wide-area latency reduction.	Recommend for best paper.	2026-08-06
4	2	11	4	accept	Well written; add a brief discussion on network partition recovery.	\N	2026-08-10
5	3	8	5	accept	Valuable benchmark and strong morphological tagging improvements.	Great regional relevance.	2026-08-07
6	3	1	4	accept	Clear methodology; expand error analysis on agglutinative suffixes.	\N	2026-08-11
7	4	8	4	accept	Practical federated setup with realistic grid telemetry traces.	\N	2026-08-12
8	5	7	2	reject	Lacks comparison against modern cardinality-based optimizers.	Insufficient novelty.	2026-08-09
9	5	4	2	reject	Synthetic star-schema evaluation is too narrow to support claims.	\N	2026-08-13
10	6	8	3	reject	Interesting graph formulation, but baseline comparisons are incomplete.	Author later withdrew.	2026-08-04
11	7	1	5	accept	Effective cold-start mitigation with low scheduling overhead.	Strong systems paper.	2026-08-20
12	7	3	4	accept	Well-structured experiments; include p99 tail latency numbers.	\N	2026-08-22
13	8	4	4	accept	Clean policy synthesis model for multi-tenant Kubernetes clusters.	\N	2026-08-25
14	9	11	2	reject	Encrypted traffic features degrade sharply under padding defenses.	Weak evaluation.	2026-08-27
\.


--
-- Data for Name: reviewer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reviewer (reviewer_id, years_experience) FROM stdin;
1	6
3	5
4	8
7	7
8	4
9	2
10	9
11	3
12	0
\.


--
-- Data for Name: reviewer_expertise; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reviewer_expertise (reviewer_id, area_label) FROM stdin;
1	Databases
1	Distributed Systems
3	Databases
3	Machine Learning
4	Databases
4	Query Optimization
7	Databases
7	Data Warehousing
8	Machine Learning
8	Artificial Intelligence
9	Databases
9	Software Engineering
10	Distributed Systems
10	Cloud Computing
11	Databases
11	Artificial Intelligence
12	Data Mining
\.


--
-- Data for Name: track; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.track (track_id, conference_id, name, description, research_area, coordinator_id) FROM stdin;
1	1	Database Systems & Query Processing	Relational engines, indexing, and query optimization.	Databases	1
2	1	Applied Machine Learning & NLP	Statistical learning, transformers, and domain AI.	Machine Learning	8
3	1	Quantum & Green Computing	Sustainable data centers and quantum algorithms.	Distributed Systems	10
4	2	Cloud & Distributed Infrastructure	Serverless, edge nodes, and container orchestration.	Cloud Computing	10
5	2	Intelligent Security & Data Mining	Network defense, anomaly detection, and log mining.	Data Mining	3
6	3	Modern Storage Engines	LSM-trees, NVMe optimization, and buffer management.	Databases	4
\.


--
-- Name: app_user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.app_user_user_id_seq', 12, true);


--
-- Name: conference_conference_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conference_conference_id_seq', 3, true);


--
-- Name: conference_session_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conference_session_session_id_seq', 6, true);


--
-- Name: paper_paper_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.paper_paper_id_seq', 12, true);


--
-- Name: review_review_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.review_review_id_seq', 14, true);


--
-- Name: track_track_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.track_track_id_seq', 6, true);


--
-- Name: app_user app_user_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_email_key UNIQUE (email);


--
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (user_id);


--
-- Name: author author_orcid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_orcid_key UNIQUE (orcid);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (author_id);


--
-- Name: author_research_area author_research_area_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author_research_area
    ADD CONSTRAINT author_research_area_pkey PRIMARY KEY (author_id, area_label);


--
-- Name: conference_host conference_host_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_host
    ADD CONSTRAINT conference_host_pkey PRIMARY KEY (conference_id, host_name);


--
-- Name: conference conference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference
    ADD CONSTRAINT conference_pkey PRIMARY KEY (conference_id);


--
-- Name: conference_reviewer conference_reviewer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_reviewer
    ADD CONSTRAINT conference_reviewer_pkey PRIMARY KEY (conference_id, reviewer_id);


--
-- Name: conference_session conference_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_session
    ADD CONSTRAINT conference_session_pkey PRIMARY KEY (session_id);


--
-- Name: paper_author paper_author_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper_author
    ADD CONSTRAINT paper_author_pkey PRIMARY KEY (paper_id, author_id);


--
-- Name: paper_keyword paper_keyword_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper_keyword
    ADD CONSTRAINT paper_keyword_pkey PRIMARY KEY (paper_id, keyword);


--
-- Name: paper paper_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper
    ADD CONSTRAINT paper_pkey PRIMARY KEY (paper_id);


--
-- Name: paper_version paper_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper_version
    ADD CONSTRAINT paper_version_pkey PRIMARY KEY (paper_id, version_no);


--
-- Name: review review_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT review_pkey PRIMARY KEY (review_id);


--
-- Name: reviewer_expertise reviewer_expertise_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviewer_expertise
    ADD CONSTRAINT reviewer_expertise_pkey PRIMARY KEY (reviewer_id, area_label);


--
-- Name: reviewer reviewer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviewer
    ADD CONSTRAINT reviewer_pkey PRIMARY KEY (reviewer_id);


--
-- Name: track track_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.track
    ADD CONSTRAINT track_pkey PRIMARY KEY (track_id);


--
-- Name: paper_author uq_paper_author_position; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper_author
    ADD CONSTRAINT uq_paper_author_position UNIQUE (paper_id, author_position);


--
-- Name: review uq_review_paper_reviewer; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT uq_review_paper_reviewer UNIQUE (paper_id, reviewer_id);


--
-- Name: uq_paper_single_corresponding_author; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_paper_single_corresponding_author ON public.paper_author USING btree (paper_id) WHERE (is_corresponding = true);


--
-- Name: author author_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.app_user(user_id) ON DELETE CASCADE;


--
-- Name: author_research_area author_research_area_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author_research_area
    ADD CONSTRAINT author_research_area_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.author(author_id) ON DELETE CASCADE;


--
-- Name: conference_host conference_host_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_host
    ADD CONSTRAINT conference_host_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conference(conference_id) ON DELETE CASCADE;


--
-- Name: conference_reviewer conference_reviewer_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_reviewer
    ADD CONSTRAINT conference_reviewer_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conference(conference_id) ON DELETE CASCADE;


--
-- Name: conference_reviewer conference_reviewer_reviewer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_reviewer
    ADD CONSTRAINT conference_reviewer_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.reviewer(reviewer_id) ON DELETE RESTRICT;


--
-- Name: conference_session conference_session_chair_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_session
    ADD CONSTRAINT conference_session_chair_id_fkey FOREIGN KEY (chair_id) REFERENCES public.reviewer(reviewer_id) ON DELETE RESTRICT;


--
-- Name: conference_session conference_session_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_session
    ADD CONSTRAINT conference_session_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conference(conference_id) ON DELETE CASCADE;


--
-- Name: conference_session fk_session_chair_in_pool; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conference_session
    ADD CONSTRAINT fk_session_chair_in_pool FOREIGN KEY (conference_id, chair_id) REFERENCES public.conference_reviewer(conference_id, reviewer_id) ON DELETE RESTRICT;


--
-- Name: track fk_track_coordinator_in_pool; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.track
    ADD CONSTRAINT fk_track_coordinator_in_pool FOREIGN KEY (conference_id, coordinator_id) REFERENCES public.conference_reviewer(conference_id, reviewer_id) ON DELETE RESTRICT;


--
-- Name: paper_author paper_author_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper_author
    ADD CONSTRAINT paper_author_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.author(author_id) ON DELETE RESTRICT;


--
-- Name: paper_author paper_author_paper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper_author
    ADD CONSTRAINT paper_author_paper_id_fkey FOREIGN KEY (paper_id) REFERENCES public.paper(paper_id) ON DELETE CASCADE;


--
-- Name: paper_keyword paper_keyword_paper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper_keyword
    ADD CONSTRAINT paper_keyword_paper_id_fkey FOREIGN KEY (paper_id) REFERENCES public.paper(paper_id) ON DELETE CASCADE;


--
-- Name: paper paper_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper
    ADD CONSTRAINT paper_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.conference_session(session_id) ON DELETE SET NULL;


--
-- Name: paper paper_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper
    ADD CONSTRAINT paper_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.track(track_id) ON DELETE RESTRICT;


--
-- Name: paper_version paper_version_paper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paper_version
    ADD CONSTRAINT paper_version_paper_id_fkey FOREIGN KEY (paper_id) REFERENCES public.paper(paper_id) ON DELETE CASCADE;


--
-- Name: review review_paper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT review_paper_id_fkey FOREIGN KEY (paper_id) REFERENCES public.paper(paper_id) ON DELETE CASCADE;


--
-- Name: review review_reviewer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT review_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.reviewer(reviewer_id) ON DELETE RESTRICT;


--
-- Name: reviewer_expertise reviewer_expertise_reviewer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviewer_expertise
    ADD CONSTRAINT reviewer_expertise_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.reviewer(reviewer_id) ON DELETE CASCADE;


--
-- Name: reviewer reviewer_reviewer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviewer
    ADD CONSTRAINT reviewer_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.app_user(user_id) ON DELETE CASCADE;


--
-- Name: track track_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.track
    ADD CONSTRAINT track_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conference(conference_id) ON DELETE CASCADE;


--
-- Name: track track_coordinator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.track
    ADD CONSTRAINT track_coordinator_id_fkey FOREIGN KEY (coordinator_id) REFERENCES public.reviewer(reviewer_id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict IBsv3uKpa9L2Zi1cnB1LEgYv9vYmuVbN5m3bksndTetVkx0SEjpgffZD8XAmz4p

