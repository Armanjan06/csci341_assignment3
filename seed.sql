-- ============================================================================
-- CSCI 341 - Assignment 3 (Part 1): Sample Seed Data (PostgreSQL)
-- ============================================================================

BEGIN;

-- 1. APP_USER (12 users: 3 author-only, 3 reviewer-only, 6 both)
INSERT INTO app_user (user_id, given_name, surname, email, affiliation, country, phone_number) VALUES
(1,  'Arman',   'Armanov',   'arman.armanov@example.com',   'Nazarbayev University',      'Kazakhstan',     '+77011112233'),
(2,  'Amina',   'Aminova',   'amina.aminova@example.com',   'Astana IT University',       'Kazakhstan',     '+77022223344'),
(3,  'Daniyar', 'Bekov',     'daniyar.bekov@example.com',   'KBTU',                       'Kazakhstan',     '+77033334455'),
(4,  'Elena',   'Petrova',   'elena.petrova@example.com',   'TU Wien',                    'Austria',        '+43158801001'),
(5,  'Timur',   'Kassymov',  'timur.kassymov@example.com',  'Suleyman Demirel University','Kazakhstan',     '+77055556677'),
(6,  'Madina',  'Omarova',   'madina.omarova@example.com',  'Satbayev University',        'Kazakhstan',     '+77066667788'),
(7,  'Lukas',   'Gruber',    'lukas.gruber@example.com',    'University of Vienna',       'Austria',        '+4314277002'),
(8,  'Aigerim', 'Nurlanova', 'aigerim.nurlanova@example.com','Nazarbayev University',     'Kazakhstan',     '+77088889900'),
(9,  'Murat',   'Tolegenov', 'murat.tolegenov@example.com', 'Eurasian National University','Kazakhstan',    '+77099990011'),
(10, 'Sofia',   'Rossi',     'sofia.rossi@example.com',     'Politecnico di Milano',      'Italy',          '+39022399001'),
(11, 'Nurlan',  'Seitov',    'nurlan.seitov@example.com',   'Nazarbayev University',      'Kazakhstan',     '+77012345678'),
(12, 'Klara',   'Novak',     'klara.novak@example.com',     'Charles University',         'Czech Republic', '+420221911001');

-- 2. AUTHOR (9 authors: 2, 5, 6 are author-only; 1, 3, 4, 10, 11, 12 are both)
INSERT INTO author (author_id, orcid) VALUES
(1,  '0000-0001-1001-0001'),
(2,  '0000-0001-1001-0002'),
(3,  '0000-0001-1001-0003'),
(4,  '0000-0001-1001-0004'),
(5,  NULL),
(6,  '0000-0001-1001-0006'),
(10, '0000-0001-1001-0010'),
(11, NULL),
(12, '0000-0001-1001-0012');

INSERT INTO author_research_area (author_id, area_label) VALUES
(1,  'Databases'),
(1,  'Distributed Systems'),
(2,  'Machine Learning'),
(2,  'Data Mining'),
(3,  'Machine Learning'),
(3,  'Natural Language Processing'),
(4,  'Databases'),
(4,  'Query Optimization'),
(5,  'Computer Vision'),
(5,  'Machine Learning'),
(6,  'Cybersecurity'),
(6,  'Cloud Computing'),
(10, 'Distributed Systems'),
(10, 'Cloud Computing'),
(11, 'Artificial Intelligence'),
(11, 'Machine Learning'),
(12, 'Data Mining'),
(12, 'Databases');

-- 3. REVIEWER (9 reviewers: 7, 8, 9 are reviewer-only; 1, 3, 4, 10, 11, 12 are both)
INSERT INTO reviewer (reviewer_id, years_experience) VALUES
(1,  6),
(3,  5),
(4,  8),
(7,  7),
(8,  4),
(9,  2),
(10, 9),
(11, 3),
(12, 0);

INSERT INTO reviewer_expertise (reviewer_id, area_label) VALUES
(1,  'Databases'),
(1,  'Distributed Systems'),
(3,  'Databases'),
(3,  'Machine Learning'),
(4,  'Databases'),
(4,  'Query Optimization'),
(7,  'Databases'),
(7,  'Data Warehousing'),
(8,  'Machine Learning'),
(8,  'Artificial Intelligence'),
(9,  'Databases'),
(9,  'Software Engineering'),
(10, 'Distributed Systems'),
(10, 'Cloud Computing'),
(11, 'Databases'),
(11, 'Artificial Intelligence'),
(12, 'Data Mining');

-- 4. CONFERENCE (3 conferences: Astana, Almaty, and Vienna with 0 papers)
INSERT INTO conference (
    conference_id, name, acronym, description, city, country,
    start_date, end_date, submission_deadline, review_deadline
) VALUES
(1, 'Central Asian Conference on Data and Intelligent Systems', 'CACDIS 2026',
    'Annual international forum on database systems, AI, and scalable computing held in Astana.',
    'Astana', 'Kazakhstan', '2026-10-15', '2026-10-17', '2026-07-01', '2026-08-15'),
(2, 'Eurasian Symposium on Software and Cloud Engineering', 'ESSCE 2026',
    'Regional symposium covering cloud architectures, cybersecurity, and machine learning applications.',
    'Almaty', 'Kazakhstan', '2026-11-05', '2026-11-07', '2026-07-20', '2026-09-01'),
(3, 'Danube Workshop on Next-Generation Data Management', 'DWNDM 2026',
    'Focused European workshop on modern storage engines and distributed query processing.',
    'Vienna', 'Austria', '2026-12-10', '2026-12-10', '2026-09-15', '2026-10-25');

INSERT INTO conference_host (conference_id, host_name) VALUES
(1, 'Nazarbayev University'),
(1, 'Astana IT University'),
(2, 'KBTU'),
(2, 'Satbayev University'),
(3, 'TU Wien');

INSERT INTO conference_reviewer (conference_id, reviewer_id) VALUES
-- Conference 1 (Astana) pool: reviewers 1, 3, 4, 7, 8, 9, 10, 11
(1, 1), (1, 3), (1, 4), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11),
-- Conference 2 (Almaty) pool: reviewers 1, 3, 4, 8, 10, 11
(2, 1), (2, 3), (2, 4), (2, 8), (2, 10), (2, 11),
-- Conference 3 (Vienna) pool: reviewers 4, 7, 10, 12
(3, 4), (3, 7), (3, 10), (3, 12);

-- 5. TRACK (6 tracks; tracks 3 and 6 are intentionally empty)
INSERT INTO track (track_id, conference_id, name, description, research_area, coordinator_id) VALUES
(1, 1, 'Database Systems & Query Processing', 'Relational engines, indexing, and query optimization.', 'Databases', 1),
(2, 1, 'Applied Machine Learning & NLP',      'Statistical learning, transformers, and domain AI.',   'Machine Learning', 8),
(3, 1, 'Quantum & Green Computing',           'Sustainable data centers and quantum algorithms.',     'Distributed Systems', 10),
(4, 2, 'Cloud & Distributed Infrastructure',  'Serverless, edge nodes, and container orchestration.', 'Cloud Computing', 10),
(5, 2, 'Intelligent Security & Data Mining',  'Network defense, anomaly detection, and log mining.',  'Data Mining', 3),
(6, 3, 'Modern Storage Engines',              'LSM-trees, NVMe optimization, and buffer management.', 'Databases', 4);

-- 6. CONFERENCE_SESSION (6 sessions; sessions 3 & 4 are empty in Astana; session 6 is empty in Almaty)
INSERT INTO conference_session (
    session_id, conference_id, title, session_date, start_time, end_time, room_label, chair_id
) VALUES
(1, 1, 'Advances in Relational and Distributed Databases', '2026-10-15', '09:30:00', '11:00:00', 'Room C3.101',     4),
(2, 1, 'Machine Learning in Practice',                     '2026-10-15', '14:00:00', '15:30:00', 'Main Auditorium', 8),
(3, 1, 'Late-Breaking Posters & Demos',                    '2026-10-16', '10:00:00', '11:30:00', 'Hall B',          7),
(4, 1, 'Industry Panel on Data Governance',                '2026-10-17', '13:00:00', '14:30:00', 'Room C3.204',     1),
(5, 2, 'Cloud-Native Systems',                             '2026-11-05', '10:00:00', '12:00:00', 'Almaty Hall 1',   10),
(6, 2, 'Almaty Evening Workshop',                          '2026-11-06', '16:00:00', '17:30:00', 'Almaty Room 202', 11);

-- 7. PAPER (12 papers covering all 5 statuses; accepted papers both with and without sessions)
INSERT INTO paper (paper_id, track_id, title, abstract, submission_date, status, session_id) VALUES
(1,  1, 'Adaptive Cost-Based Query Optimization for Hybrid Cloud Databases',
        'We propose an adaptive query optimizer that integrates machine learning cardinality estimators with classical cost models for hybrid workloads.',
        '2026-06-25', 'accepted', 1),
(2,  1, 'Deterministic Consensus Protocols for Geo-Replicated Storage',
        'This paper presents a low-latency consensus protocol minimizing cross-datacenter round trips in distributed relational storage engines.',
        '2026-06-28', 'accepted', 1),
(3,  2, 'Transformer Embeddings for Low-Resource Turkic Languages',
        'We evaluate multilingual transformer architectures and machine learning transfer techniques for Kazakh and Uzbek morphological analysis.',
        '2026-06-29', 'accepted', 2),
(4,  2, 'Federated Anomaly Detection in Smart Grid Telemetry',
        'A privacy-preserving federated learning framework for detecting sensor anomalies across regional power grids.',
        '2026-06-30', 'accepted', NULL),
(5,  1, 'Heuristic Join Ordering Without Statistics',
        'An experimental study of rule-based join ordering heuristics on synthetic star schemas.',
        '2026-06-27', 'rejected', NULL),
(6,  2, 'Graph Neural Networks for Academic Citation Prediction',
        'We apply graph machine learning models to predict long-term citation trajectories of conference papers.',
        '2026-06-20', 'withdrawn', NULL),
(7,  4, 'Serverless Container Scheduling Under Burst Workloads',
        'We design a predictive autoscaler using lightweight machine learning regressors to reduce cold-start latency in serverless clusters.',
        '2026-07-15', 'accepted', 5),
(8,  4, 'Zero-Trust Microsegmentation for Multi-Tenant Clouds',
        'Automated policy synthesis for zero-trust network isolation across Kubernetes clusters.',
        '2026-07-18', 'accepted', NULL),
(9,  5, 'Static Signature Matching for Encrypted Traffic',
        'A comparative evaluation of packet-length heuristics for classifying encrypted TLS flows.',
        '2026-07-19', 'rejected', NULL),
(10, 5, 'Incremental Frequent Itemset Mining on Streaming Logs',
        'A sliding-window algorithm for mining frequent patterns in high-velocity system logs.',
        '2026-07-10', 'withdrawn', NULL),
(11, 4, 'Energy-Aware VM Consolidation in Edge Data Centers',
        'Multi-objective optimization for migrating virtual machines across renewable-powered edge nodes.',
        '2026-07-20', 'under review', NULL),
(12, 5, 'Explainable Credit Scoring Using Symbolic Rule Extraction',
        'Extracting human-readable decision rules from ensemble classifiers for regulated financial applications.',
        '2026-07-20', 'submitted', NULL);

-- 8. PAPER_KEYWORD
INSERT INTO paper_keyword (paper_id, keyword) VALUES
(1,  'Query Optimization'),
(1,  'Databases'),
(1,  'Machine Learning'),
(2,  'Distributed Systems'),
(2,  'Consensus'),
(2,  'Databases'),
(3,  'Natural Language Processing'),
(3,  'Machine Learning'),
(3,  'Kazakh NLP'),
(4,  'Federated Learning'),
(4,  'Anomaly Detection'),
(5,  'Join Ordering'),
(5,  'Query Execution'),
(6,  'Graph Neural Networks'),
(6,  'Machine Learning'),
(7,  'Serverless Computing'),
(7,  'Cloud Computing'),
(7,  'Machine Learning'),
(8,  'Zero-Trust Security'),
(8,  'Kubernetes'),
(9,  'Network Security'),
(9,  'Traffic Analysis'),
(10, 'Data Mining'),
(10, 'Streaming Algorithms'),
(11, 'Edge Computing'),
(11, 'Green IT'),
(12, 'Explainable AI'),
(12, 'Rule Extraction');

-- 9. PAPER_AUTHOR (Every paper has >=1 author, unique positions, and exactly 1 corresponding author)
INSERT INTO paper_author (paper_id, author_id, author_position, is_corresponding) VALUES
(1,  1,  1, TRUE),
(1,  4,  2, FALSE),
(2,  4,  1, TRUE),
(2,  1,  2, FALSE),
(2,  10, 3, FALSE),
(3,  3,  1, TRUE),
(3,  2,  2, FALSE),
(3,  11, 3, FALSE),
(4,  5,  1, TRUE),
(4,  3,  2, FALSE),
(5,  12, 1, TRUE),
(6,  2,  1, TRUE),   -- Amina Aminova is corresponding author on withdrawn paper 6
(6,  5,  2, FALSE),
(7,  10, 1, TRUE),
(7,  6,  2, FALSE),
(8,  6,  1, TRUE),
(9,  6,  1, TRUE),
(9,  12, 2, FALSE),
(10, 2,  1, TRUE),   -- Amina Aminova is corresponding author on withdrawn paper 10
(11, 1,  1, TRUE),
(11, 10, 2, FALSE),
(12, 11, 1, TRUE),
(12, 2,  2, FALSE);  -- Amina Aminova is non-corresponding co-author on submitted paper 12

-- 10. PAPER_VERSION (18 versions; paper 1 demonstrates version numbering with a gap: 1, 2, 4)
INSERT INTO paper_version (paper_id, version_no, file_location, uploaded_at, change_note) VALUES
(1,  1, '/storage/papers/paper_01_v1.pdf', '2026-06-25 10:15:00', 'Initial submission'),
(1,  2, '/storage/papers/paper_01_v2.pdf', '2026-06-30 18:40:00', 'Expanded TPC-H experimental benchmarks'),
(1,  4, '/storage/papers/paper_01_v4.pdf', '2026-09-10 09:00:00', 'Camera-ready revision addressing reviewer comments'),
(2,  1, '/storage/papers/paper_02_v1.pdf', '2026-06-28 14:20:00', 'Initial draft'),
(2,  2, '/storage/papers/paper_02_v2.pdf', '2026-09-12 11:05:00', 'Camera-ready final version'),
(3,  1, '/storage/papers/paper_03_v1.pdf', '2026-06-29 16:00:00', 'Original submission'),
(3,  2, '/storage/papers/paper_03_v2.pdf', '2026-09-14 15:30:00', 'Added ablation tables for camera-ready'),
(4,  1, '/storage/papers/paper_04_v1.pdf', '2026-06-30 21:10:00', NULL),
(5,  1, '/storage/papers/paper_05_v1.pdf', '2026-06-27 09:45:00', 'Initial submission'),
(6,  1, '/storage/papers/paper_06_v1.pdf', '2026-06-20 12:00:00', 'First submission'),
(6,  2, '/storage/papers/paper_06_v2.pdf', '2026-07-05 14:15:00', 'Updated dataset section prior to withdrawal'),
(7,  1, '/storage/papers/paper_07_v1.pdf', '2026-07-15 11:30:00', 'Submitted manuscript'),
(7,  2, '/storage/papers/paper_07_v2.pdf', '2026-09-25 17:45:00', 'Camera-ready manuscript'),
(8,  1, '/storage/papers/paper_08_v1.pdf', '2026-07-18 19:20:00', NULL),
(9,  1, '/storage/papers/paper_09_v1.pdf', '2026-07-19 08:50:00', 'Initial submission'),
(10, 1, '/storage/papers/paper_10_v1.pdf', '2026-07-10 13:10:00', 'Initial version'),
(11, 1, '/storage/papers/paper_11_v1.pdf', '2026-07-20 22:00:00', NULL),
(12, 1, '/storage/papers/paper_12_v1.pdf', '2026-07-20 23:30:00', 'Submitted prior to deadline');

-- 11. REVIEW (14 completed reviews; zero self-reviews; varied counts: 0, 2, 3 per reviewer)
INSERT INTO review (
    review_id, paper_id, reviewer_id, overall_score, recommendation,
    comments_for_authors, confidential_comments, review_submission_date
) VALUES
(1,  1, 7,  5, 'accept', 'Strong hybrid estimator design and clear experimental validation.', 'Top-tier database paper.', '2026-08-05'),
(2,  1, 3,  4, 'accept', 'Solid results; please clarify training overhead on dynamic schemas.', NULL, '2026-08-08'),
(3,  2, 7,  5, 'accept', 'Rigorous correctness proof and impressive wide-area latency reduction.', 'Recommend for best paper.', '2026-08-06'),
(4,  2, 11, 4, 'accept', 'Well written; add a brief discussion on network partition recovery.', NULL, '2026-08-10'),
(5,  3, 8,  5, 'accept', 'Valuable benchmark and strong morphological tagging improvements.', 'Great regional relevance.', '2026-08-07'),
(6,  3, 1,  4, 'accept', 'Clear methodology; expand error analysis on agglutinative suffixes.', NULL, '2026-08-11'),
(7,  4, 8,  4, 'accept', 'Practical federated setup with realistic grid telemetry traces.', NULL, '2026-08-12'),
(8,  5, 7,  2, 'reject', 'Lacks comparison against modern cardinality-based optimizers.', 'Insufficient novelty.', '2026-08-09'),
(9,  5, 4,  2, 'reject', 'Synthetic star-schema evaluation is too narrow to support claims.', NULL, '2026-08-13'),
(10, 6, 8,  3, 'reject', 'Interesting graph formulation, but baseline comparisons are incomplete.', 'Author later withdrew.', '2026-08-04'),
(11, 7, 1,  5, 'accept', 'Effective cold-start mitigation with low scheduling overhead.', 'Strong systems paper.', '2026-08-20'),
(12, 7, 3,  4, 'accept', 'Well-structured experiments; include p99 tail latency numbers.', NULL, '2026-08-22'),
(13, 8, 4,  4, 'accept', 'Clean policy synthesis model for multi-tenant Kubernetes clusters.', NULL, '2026-08-25'),
(14, 9, 11, 2, 'reject', 'Encrypted traffic features degrade sharply under padding defenses.', 'Weak evaluation.', '2026-08-27');

-- Sync identity sequences to MAX(id) so subsequent INSERTs work cleanly
SELECT setval(pg_get_serial_sequence('app_user', 'user_id'),             (SELECT MAX(user_id)       FROM app_user));
SELECT setval(pg_get_serial_sequence('conference', 'conference_id'),   (SELECT MAX(conference_id) FROM conference));
SELECT setval(pg_get_serial_sequence('track', 'track_id'),             (SELECT MAX(track_id)      FROM track));
SELECT setval(pg_get_serial_sequence('conference_session', 'session_id'), (SELECT MAX(session_id) FROM conference_session));
SELECT setval(pg_get_serial_sequence('paper', 'paper_id'),             (SELECT MAX(paper_id)      FROM paper));
SELECT setval(pg_get_serial_sequence('review', 'review_id'),           (SELECT MAX(review_id)     FROM review));

COMMIT;