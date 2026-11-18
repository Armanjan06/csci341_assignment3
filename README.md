# CSCI 341 — Research Conference and Paper Review Management System

## 1. Project Overview & File Structure

This repository implements the **Research Conference and Paper Review Management System** for **CSCI 341** using **PostgreSQL**, **Python 3**, **SQLAlchemy 2.0**, and **FastAPI**.

```text
├── schema.sql             # Part 1: PostgreSQL DDL (15 tables, PKs, FKs, UNIQUE & CHECK constraints)
├── seed.sql               # Part 1: Repeatable sample dataset (12 users, 3 conferences, 12 papers, 14 reviews)
├── part2.py    # Part 2: SQLAlchemy scripts for Tasks 1–8 with bound parameters & rollbacks
├── app.py                 # Part 3: FastAPI web application with full CRUD & domain validation checks
├── init_db.py             # Helper script to initialize/reset PostgreSQL with schema, seed data, and view
├── requirements.txt       # Python package dependencies
├── backup.sql             # Plain SQL export (pg_dump) including schema, seed data, and view
└── README.md              # Project documentation
```

---

## 2. Software Versions

| Component | Version |
| :--- | :--- |
| **PostgreSQL** | 18.x |
| **Python** | 3.14 |
| **SQLAlchemy** | 2.1.9 |
| **FastAPI** | 0.164.0 |
| **Uvicorn** | 0.54.0 |
| **Pydantic** | 2.14.3 |
| **psycopg2-binary** | 2.9.13 |

---

## 3. Environment Setup & Database Restoration

### 3.1 Install Python Dependencies

```bash
python -m venv venv
source venv/bin/activate        # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Set your PostgreSQL connection string:

```bash
export DATABASE_URL="postgresql://csci341_assignment3_user:92TrmFxbiHVd5lYvJBvGvIjToquKQTh2@dpg-dbutkg8n74is739cq84g-a.singapore-postgres.render.com/csci341_assignment3"
```

### 3.2 Create or Restore the Database

You can create or restore the database to its initial seed state using any of the three methods below:

1. **Using Python (`init_db.py`):** Drops existing tables/views, executes `schema.sql` and `seed.sql`, and creates the `accepted_paper_schedule` view.
   ```bash
   python init_db.py
   ```
2. **Using `psql` with `schema.sql` and `seed.sql`:**
   ```bash
   psql -U postgres -d conference_db -f schema.sql
   psql -U postgres -d conference_db -f seed.sql
   ```
3. **Using the plain SQL dump (`backup.sql`):**
   ```bash
   psql -U postgres -d conference_db -f backup.sql
   ```

---

## 4. How to Run Part 2 Queries and Part 3 Web Application

### 4.1 Running Part 2 (`part2_operations.py`)

```bash
python part2_operations.py
```

* Executes **Tasks 1–8** in sequence using SQLAlchemy.
* Prints every SQL statement, bound parameter dictionary, and formatted result table.
* Wraps all `UPDATE` and `DELETE` tasks (**Tasks 3.1, 3.2, 4.1, 4.2**) in explicit transactions that display **BEFORE** and **AFTER** states and then execute `ROLLBACK`, ensuring all subsequent queries (**Tasks 5–8**) run against the unmodified seed dataset.

### 4.2 Running Part 3 (`app.py`)

Start the FastAPI server locally:

```bash
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

Open `http://127.0.0.1:8000/` in a browser (automatically redirects to `/docs` interactive Swagger UI) to execute CRUD operations on:
* **Users** (`/users`): Manages `APP_USER` together with `AUTHOR` (`orcid`, `AUTHOR_RESEARCH_AREA`) and `REVIEWER` (`years_experience`, `REVIEWER_EXPERTISE`).
* **Papers** (`/papers`): Manages `PAPER` together with `PAPER_KEYWORD`, `PAPER_AUTHOR`, and `PAPER_VERSION`.
* **Reviews** (`/reviews`): Manages completed `REVIEW` records.
* **Sessions** (`/sessions`): Manages `CONFERENCE_SESSION` records.
* **Read-Only Lookups**: `/conferences`, `/tracks`, and `/schedule` (queries the `accepted_paper_schedule` view).

---

## 5. Relational Schema, Keys & Referential Actions

The schema implements all **15 relations** from Appendix A of Assignment 3. Multivalued descriptive labels (`research_areas`, `expertise_areas`, `host_name`, `keyword`) are normalized into separate relations rather than stored as delimited strings.

| Table | Primary Key | Foreign Keys & `ON DELETE` Actions | `UNIQUE` & `CHECK` Constraints |
| :--- | :--- | :--- | :--- |
| **`APP_USER`** | `user_id` | — | `UNIQUE (email)` |
| **`AUTHOR`** | `author_id` | `author_id -> APP_USER(user_id)` (`CASCADE`) | `UNIQUE (orcid)` (nullable) |
| **`AUTHOR_RESEARCH_AREA`** | `(author_id, area_label)` | `author_id -> AUTHOR(author_id)` (`CASCADE`) | — |
| **`REVIEWER`** | `reviewer_id` | `reviewer_id -> APP_USER(user_id)` (`CASCADE`) | `CHECK (years_experience >= 0)` |
| **`REVIEWER_EXPERTISE`** | `(reviewer_id, area_label)` | `reviewer_id -> REVIEWER(reviewer_id)` (`CASCADE`) | — |
| **`CONFERENCE`** | `conference_id` | — | `CHECK (end_date >= start_date)` |
| **`CONFERENCE_HOST`** | `(conference_id, host_name)` | `conference_id -> CONFERENCE(conference_id)` (`CASCADE`) | — |
| **`CONFERENCE_REVIEWER`** | `(conference_id, reviewer_id)` | `conference_id -> CONFERENCE(conference_id)` (`CASCADE`)<br>`reviewer_id -> REVIEWER(reviewer_id)` (`RESTRICT`) | — |
| **`TRACK`** | `track_id` | `conference_id -> CONFERENCE(conference_id)` (`CASCADE`)<br>`coordinator_id -> REVIEWER(reviewer_id)` (`RESTRICT`)<br>`(conference_id, coordinator_id) -> CONFERENCE_REVIEWER(conference_id, reviewer_id)` (`RESTRICT`) | Ensures coordinator belongs to the conference's reviewer pool |
| **`CONFERENCE_SESSION`** | `session_id` | `conference_id -> CONFERENCE(conference_id)` (`CASCADE`)<br>`chair_id -> REVIEWER(reviewer_id)` (`RESTRICT`)<br>`(conference_id, chair_id) -> CONFERENCE_REVIEWER(conference_id, reviewer_id)` (`RESTRICT`) | `CHECK (end_time > start_time)`<br>Ensures session chair belongs to the conference's reviewer pool |
| **`PAPER`** | `paper_id` | `track_id -> TRACK(track_id)` (`RESTRICT`)<br>`session_id -> CONFERENCE_SESSION(session_id)` (`SET NULL`) | `CHECK (status IN ('submitted', 'under review', 'accepted', 'rejected', 'withdrawn'))` |
| **`PAPER_KEYWORD`** | `(paper_id, keyword)` | `paper_id -> PAPER(paper_id)` (`CASCADE`) | — |
| **`PAPER_AUTHOR`** | `(paper_id, author_id)` | `paper_id -> PAPER(paper_id)` (`CASCADE`)<br>`author_id -> AUTHOR(author_id)` (`RESTRICT`) | `UNIQUE (paper_id, author_position)`<br>`CHECK (author_position >= 1)`<br>Partial unique index on `(paper_id) WHERE is_corresponding = TRUE` |
| **`PAPER_VERSION`** | `(paper_id, version_no)` | `paper_id -> PAPER(paper_id)` (`CASCADE`) | `CHECK (version_no >= 1)` |
| **`REVIEW`** | `review_id` | `paper_id -> PAPER(paper_id)` (`CASCADE`)<br>`reviewer_id -> REVIEWER(reviewer_id)` (`RESTRICT`) | `UNIQUE (paper_id, reviewer_id)`<br>`CHECK (overall_score BETWEEN 1 AND 5)`<br>`CHECK (recommendation IN ('accept', 'reject'))` |

### Material Changes from Assignment 1 Conceptual Design
* **Superclass/Subclass Mapping:** `APP_USER` is mapped using class-table inheritance with separate subclass tables `AUTHOR` and `REVIEWER` sharing `user_id` as their primary key, supporting overlapping participation (users who are authors, reviewers, or both).
* **Weak Entity & Multivalued Attributes:** `PAPER_VERSION` is modeled with a composite primary key `(paper_id, version_no)` and `ON DELETE CASCADE`. Multivalued labels (`AUTHOR_RESEARCH_AREA`, `REVIEWER_EXPERTISE`, `CONFERENCE_HOST`, `PAPER_KEYWORD`) are implemented as dependent tables with composite primary keys.
* **Pool Membership Constraints:** Composite foreign keys from `TRACK(conference_id, coordinator_id)` and `CONFERENCE_SESSION(conference_id, chair_id)` to `CONFERENCE_REVIEWER(conference_id, reviewer_id)` enforce at the schema level that coordinators and session chairs belong to their conference's reviewer pool.

---

## 6. Required Checks & Assignment 1 Business Rules

### 6.1 Required Database Constraints (Enforced in PostgreSQL)
* Unique user emails (`APP_USER.email`).
* Positive integer author positions (`author_position >= 1`), unique per paper `(paper_id, author_position)`.
* At most one completed review per reviewer and paper (`UNIQUE (paper_id, reviewer_id)`).
* Paper status restricted to `submitted`, `under review`, `accepted`, `rejected`, or `withdrawn`.
* Integer review scores restricted to `1..5` and recommendations restricted to `accept` or `reject`.
* Positive version numbers (`version_no >= 1`), identified by `(paper_id, version_no)`, cascading on paper deletion (`ON DELETE CASCADE`).
* Nonnegative reviewing experience (`years_experience >= 0`).
* Conference `end_date >= start_date` and session `end_time > start_time`.

### 6.2 Required Application Checks (Enforced in `app.py`)
1. **Prevent Self-Reviews:**
   * Checked on `POST /reviews` and `PUT /reviews/{review_id}`: rejects the operation with HTTP `400` if `reviewer_id` exists in `PAPER_AUTHOR` for `paper_id`.
   * Checked on `PUT /papers/{paper_id}`: rejects author list changes with HTTP `400` if any newly assigned author already has a `REVIEW` recorded for that paper.
2. **Validate Session Assignments:**
   * Checked on `POST /papers` and `PUT /papers/{paper_id}`: if `session_id` is non-null, verifies that `paper.status == 'accepted'` and that `track.conference_id == conference_session.conference_id`; rejects invalid assignments with HTTP `400`.
   * Checked on `PUT /sessions/{session_id}`: rejects changing a session's `conference_id` if any paper currently assigned to that session belongs to a track in a different conference.

### 6.3 Remaining Assignment 1 Business Rules

| Business Rule (Assignment 1) | Holds in Seed Data? | Automatically Enforced? | Enforcement Mechanism |
| :--- | :---: | :---: | :--- |
| Every user is an author, a reviewer, or both | Yes | **Yes (Web App)** | `validate_user_roles()` in `app.py` rejects user creation/update if both `author` and `reviewer` profiles are omitted. |
| Required child records (`>= 1` research area per author, expertise per reviewer, keyword/author/version per paper, host/track/reviewer per conference) | Yes | **Yes (Web App)** | Pydantic `min_length=1` validation in `UserPayload` and `PaperPayload` in `app.py`; verified in `seed.sql` for conferences. |
| Exactly one corresponding author per paper (`is_corresponding = TRUE`) | Yes | **Yes (DB + Web App)** | Partial unique index `uq_paper_single_corresponding_author` enforces `<= 1` in PostgreSQL; `validate_paper_payload()` in `app.py` enforces `== 1`. |
| Track coordinator belongs to the conference's reviewer pool | Yes | **Yes (DB)** | Composite FK `fk_track_coordinator_in_pool` on `(conference_id, coordinator_id)` referencing `CONFERENCE_REVIEWER`. |
| Session chair belongs to the conference's reviewer pool | Yes | **Yes (DB)** | Composite FK `fk_session_chair_in_pool` on `(conference_id, chair_id)` referencing `CONFERENCE_REVIEWER`. |

---

## 7. Design Assumptions

1. **Version Numbering:** Version numbers within a paper must be positive integers (`>= 1`) and unique per paper, but gaps are permitted (e.g., Paper 1 has versions `1, 2, 4`). The highest `version_no` identifies the current version.
2. **Completed Reviews Only:** Only submitted/completed reviews are persisted in `REVIEW`.
3. **File Storage:** Paper files are represented by string paths/URIs in `PAPER_VERSION.file_location` rather than binary blobs.
4. **Deletion Semantics:**
   * Deleting a `PAPER` cascades to `PAPER_VERSION`, `PAPER_AUTHOR`, `PAPER_KEYWORD`, and `REVIEW`.
   * Deleting a `CONFERENCE` cascades to its `CONFERENCE_HOST`, `CONFERENCE_REVIEWER` pool entries, `TRACK`, and `CONFERENCE_SESSION` records (when no papers restrict track deletion), while independent `APP_USER`, `AUTHOR`, and `REVIEWER` records are preserved.
   * Deleting a `CONFERENCE_SESSION` sets `PAPER.session_id = NULL` (`ON DELETE SET NULL`) so accepted papers are not lost.

---

## 8. Part 2 Query Parameter Values & Verified Results

| Task | Description | Bound Parameter Values | Verified Result on Seed Dataset |
| :--- | :--- | :--- | :--- |
| **3.1** | Update Arman Armanov's phone number | `email = 'arman.armanov@example.com'`<br>`new_phone = '+77773414141'` | Updates `user_id = 1` (`+77011112233` -> `+77773414141`), then rolls back. |
| **3.2** | Conditionally extend review deadlines | `target_city = 'Astana'`<br>`astana_days = 7`, `other_days = 3` | Extends `CACDIS 2026` (Astana) by 7 days (`2026-08-15` -> `2026-08-22`) and `ESSCE 2026` / `DWNDM 2026` by 3 days, then rolls back. |
| **4.1** | Delete withdrawn papers with corresponding author Amina Aminova | `target_status = 'withdrawn'`<br>`corresponding_email = 'amina.aminova@example.com'` | Deletes `paper_id` `6` and `10` (cascading to keywords, authorships, versions, and review `10`); keeps `paper_id` `3` and `12` where Amina is a non-corresponding co-author; then rolls back. |
| **4.2** | Delete empty sessions in Astana conferences | `target_city = 'Astana'` | Deletes empty Astana sessions `3` and `4`; retains non-empty Astana sessions `1` and `2` and Almaty sessions `5` and `6`; then rolls back. |
| **5.1** | Accepted papers with corresponding author, track, and conference | `status = 'accepted'` | Returns **6 rows** (`paper_id` `1, 2, 3, 4, 7, 8`). |
| **5.2** | Case-insensitive `"machine learning"` search in abstract | `search_pattern = '%machine learning%'` | Returns **4 rows** (`paper_id` `1, 3, 6, 7`). |
| **5.3** | Versions of a selected paper ordered highest to lowest | `paper_id = 1` | Returns **3 rows** (`version_no` `4, 2, 1`). |
| **5.4** | Qualified `"Databases"` reviewers in conference pool | `conference_id = 1`<br>`expertise_area = 'Databases'`<br>`min_years = 3` | Returns **5 distinct reviewers** (`user_id` `1, 3, 4, 7, 11`). |
| **6.1** | Track distinct papers and distinct authors | *(none)* | Returns all **6 tracks**; Track 1 reports `2` distinct papers and `3` distinct authors; empty Tracks 3 and 6 report `0` and `0`. |
| **6.2** | Reviewer completed review count and average score | *(none)* | Returns all **9 reviewers**; Reviewer 12 (`Klara Novak`) reports `0` reviews and `NULL` average. |
| **6.3** | Conference total papers, accepted papers, and average score | `accepted_status = 'accepted'` | `CACDIS 2026`: `6` total, `4` accepted, `3.80` avg;<br>`ESSCE 2026`: `6` total, `2` accepted, `3.75` avg;<br>`DWNDM 2026`: `0` total, `0` accepted, `NULL` avg. |
| **6.4** | Reviewers with above-average completed review counts | *(none)* | Overall average across all 9 reviewers is `1.56` (`14 / 9`); returns **6 reviewers** (`7, 8` with 3 reviews; `1, 3, 4, 11` with 2 reviews). |
| **7** | Conference acceptance rate (%) | `accepted_status = 'accepted'`<br>`rejected_status = 'rejected'` | `CACDIS 2026`: `80.00%` (`4/5`);<br>`ESSCE 2026`: `66.67%` (`2/3`);<br>`DWNDM 2026`: `NULL` (`0/0`). |
| **8** | Query view `accepted_paper_schedule` | *(none)* | Returns **4 rows** (`paper_id` `1, 2, 3, 7`) ordered by `conference_id, session_date, start_time, session_id, paper_id`; omits unscheduled accepted papers `4` and `8`. |
