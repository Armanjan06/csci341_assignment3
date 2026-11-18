

from decimal import Decimal
import os
from pathlib import Path
from typing import Any, Mapping, Sequence
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Connection, Engine

DATABASE_URL = "postgresql+psycopg2://postgres:postgres@localhost:5432/conference_db"

BASE_DIR = Path(__file__).resolve().parent
SCHEMA_FILE = BASE_DIR / "schema.sql"
SEED_FILE = BASE_DIR / "seed.sql"

ALL_TABLES = [
    "app_user",
    "author",
    "author_research_area",
    "reviewer",
    "reviewer_expertise",
    "conference",
    "conference_host",
    "conference_reviewer",
    "track",
    "conference_session",
    "paper",
    "paper_keyword",
    "paper_author",
    "paper_version",
    "review",
]


def print_banner(task_label: str, title: str) -> None:
    print("\n" + "=" * 88)
    print(f"[{task_label}] {title}")
    print("=" * 88)


def format_value(val: Any) -> str:
    if val is None:
        return "NULL"
    if isinstance(val, Decimal):
        return f"{val:.2f}"
    return str(val)


def print_table(columns: Sequence[str], rows: Sequence[Sequence[Any]]) -> None:
    if not rows:
        print("(0 rows)")
        return

    str_rows = [[format_value(cell) for cell in row] for row in rows]
    widths = [
        max(len(str(col)), *(len(r[idx]) for r in str_rows))
        for idx, col in enumerate(columns)
    ]

    header = " | ".join(str(col).ljust(widths[idx]) for idx, col in enumerate(columns))
    sep = "-+-".join("-" * w for w in widths)
    print(header)
    print(sep)
    for r in str_rows:
        print(" | ".join(r[idx].ljust(widths[idx]) for idx in range(len(columns))))
    print(f"({len(rows)} row{'s' if len(rows) != 1 else ''})")


def execute_and_show(
    conn: Connection,
    sql: str,
    params: Mapping[str, Any] | None = None,
    label: str | None = None,
) -> None:
    if label:
        print(f"\n--- {label} ---")
    print("SQL Statement:")
    print(sql.strip())
    if params:
        print(f"Bound Parameters: {dict(params)}")
    result = conn.execute(text(sql), params or {})
    if result.returns_rows:
        rows = result.fetchall()
        print("\nResult:")
        print_table(list(result.keys()), rows)
    else:
        print(f"\nRows affected: {result.rowcount}")


def task_1_create_schema(engine: Engine) -> None:
    print_banner("Task 1", "Create Tables and Database Constraints")
    schema_sql = SCHEMA_FILE.read_text(encoding="utf-8")
    print(f"Executing DDL script: {SCHEMA_FILE.name}")
    print(schema_sql.strip())
    with engine.begin() as conn:
        conn.exec_driver_sql(schema_sql)
    print("\nStatus: All 15 tables, primary keys, foreign keys, UNIQUE, and CHECK constraints created.")


def task_2_insert_seed_data(engine: Engine) -> None:
    print_banner("Task 2", "Populate Seed Data and Verify Table Row Counts")
    seed_sql = SEED_FILE.read_text(encoding="utf-8")
    print(f"Executing seed script: {SEED_FILE.name}")
    with engine.begin() as conn:
        conn.exec_driver_sql(seed_sql)

    count_query = "\nUNION ALL\n".join(
        f"SELECT '{tbl}' AS table_name, COUNT(*) AS row_count FROM {tbl}"
        for tbl in ALL_TABLES
    )
    with engine.connect() as conn:
        execute_and_show(conn, count_query, label="Row Count per Table")


def task_3_1_update_arman_phone(engine: Engine) -> None:
    print_banner("Task 3.1", "Update Phone Number of Arman Armanov")
    select_sql = """
    SELECT user_id, given_name, surname, email, phone_number
    FROM app_user
    WHERE email = :email
    """
    update_sql = """
    UPDATE app_user
    SET phone_number = :new_phone
    WHERE email = :email
    """
    email_param = {"email": "arman.armanov@example.com"}
    update_params = {
        "email": "arman.armanov@example.com",
        "new_phone": "+77773414141",
    }

    with engine.connect() as conn:
        trans = conn.begin()
        try:
            execute_and_show(conn, select_sql, email_param, label="BEFORE UPDATE")
            execute_and_show(conn, update_sql, update_params, label="EXECUTE UPDATE")
            execute_and_show(conn, select_sql, email_param, label="AFTER UPDATE")
        finally:
            trans.rollback()
            print("\n[ROLLBACK] Transaction rolled back; original seed data preserved.")


def task_3_2_extend_review_deadlines(engine: Engine) -> None:
    print_banner("Task 3.2", "Conditionally Extend Conference Review Deadlines")
    select_sql = """
    SELECT conference_id, acronym, city, review_deadline
    FROM conference
    ORDER BY conference_id
    """
    update_sql = """
    UPDATE conference
    SET review_deadline = review_deadline + CASE
        WHEN city = :target_city THEN CAST(:astana_days AS INTEGER)
        ELSE CAST(:other_days AS INTEGER)
    END
    """
    update_params = {
        "target_city": "Astana",
        "astana_days": 7,
        "other_days": 3,
    }

    with engine.connect() as conn:
        trans = conn.begin()
        try:
            execute_and_show(conn, select_sql, label="BEFORE UPDATE")
            execute_and_show(conn, update_sql, update_params, label="EXECUTE UPDATE")
            execute_and_show(conn, select_sql, label="AFTER UPDATE")
        finally:
            trans.rollback()
            print("\n[ROLLBACK] Transaction rolled back; original seed data preserved.")


def task_4_1_delete_amina_withdrawn_papers(engine: Engine) -> None:
    print_banner("Task 4.1", "Delete Withdrawn Papers with Corresponding Author Amina Aminova")
    counts_sql = """
    SELECT 'paper' AS entity, COUNT(*) AS total FROM paper
    UNION ALL SELECT 'paper_author', COUNT(*) FROM paper_author
    UNION ALL SELECT 'paper_keyword', COUNT(*) FROM paper_keyword
    UNION ALL SELECT 'paper_version', COUNT(*) FROM paper_version
    UNION ALL SELECT 'review', COUNT(*) FROM review
    UNION ALL SELECT 'app_user', COUNT(*) FROM app_user
    UNION ALL SELECT 'track', COUNT(*) FROM track
    UNION ALL SELECT 'conference', COUNT(*) FROM conference
    """
    papers_sql = """
    SELECT
        p.paper_id,
        p.title,
        p.status,
        u.email AS corresponding_author_email
    FROM paper p
    JOIN paper_author pa
        ON pa.paper_id = p.paper_id AND pa.is_corresponding = TRUE
    JOIN app_user u
        ON u.user_id = pa.author_id
    ORDER BY p.paper_id
    """
    delete_sql = """
    DELETE FROM paper
    WHERE status = :target_status
      AND paper_id IN (
          SELECT pa.paper_id
          FROM paper_author pa
          JOIN app_user u
              ON u.user_id = pa.author_id
          WHERE pa.is_corresponding = TRUE
            AND u.email = :corresponding_email
      )
    """
    delete_params = {
        "target_status": "withdrawn",
        "corresponding_email": "amina.aminova@example.com",
    }

    with engine.connect() as conn:
        trans = conn.begin()
        try:
            execute_and_show(conn, counts_sql, label="BEFORE DELETE (Table Counts)")
            execute_and_show(conn, papers_sql, label="BEFORE DELETE (Papers & Corresponding Authors)")
            execute_and_show(conn, delete_sql, delete_params, label="EXECUTE DELETE (Cascades to dependent records)")
            execute_and_show(conn, counts_sql, label="AFTER DELETE (Table Counts)")
            execute_and_show(conn, papers_sql, label="AFTER DELETE (Remaining Papers)")
        finally:
            trans.rollback()
            print("\n[ROLLBACK] Transaction rolled back; original seed data preserved.")


def task_4_2_delete_empty_astana_sessions(engine: Engine) -> None:
    print_banner("Task 4.2", "Delete Empty Sessions in Astana Conferences")
    sessions_sql = """
    SELECT
        cs.session_id,
        cs.title AS session_title,
        c.acronym AS conference_acronym,
        c.city,
        COUNT(p.paper_id) AS assigned_papers
    FROM conference_session cs
    JOIN conference c
        ON c.conference_id = cs.conference_id
    LEFT JOIN paper p
        ON p.session_id = cs.session_id
    GROUP BY cs.session_id, cs.title, c.acronym, c.city
    ORDER BY cs.session_id
    """
    delete_sql = """
    DELETE FROM conference_session cs
    USING conference c
    WHERE cs.conference_id = c.conference_id
      AND c.city = :target_city
      AND NOT EXISTS (
          SELECT 1
          FROM paper p
          WHERE p.session_id = cs.session_id
      )
    """
    delete_params = {"target_city": "Astana"}

    with engine.connect() as conn:
        trans = conn.begin()
        try:
            execute_and_show(conn, sessions_sql, label="BEFORE DELETE (All Sessions)")
            execute_and_show(conn, delete_sql, delete_params, label="EXECUTE DELETE")
            execute_and_show(conn, sessions_sql, label="AFTER DELETE (Remaining Sessions)")
        finally:
            trans.rollback()
            print("\n[ROLLBACK] Transaction rolled back; original seed data preserved.")


def task_5_simple_queries(engine: Engine) -> None:
    with engine.connect() as conn:
        print_banner("Task 5.1", "List Accepted Papers with Corresponding Author, Track, and Conference")
        sql_5_1 = """
        SELECT
            p.paper_id,
            p.title AS paper_title,
            u.given_name || ' ' || u.surname AS corresponding_author_name,
            u.email AS corresponding_author_email,
            t.name AS track_name,
            c.conference_id,
            c.acronym AS conference_acronym
        FROM paper p
        JOIN paper_author pa
            ON pa.paper_id = p.paper_id AND pa.is_corresponding = TRUE
        JOIN app_user u
            ON u.user_id = pa.author_id
        JOIN track t
            ON t.track_id = p.track_id
        JOIN conference c
            ON c.conference_id = t.conference_id
        WHERE p.status = :status
        ORDER BY p.paper_id
        """
        execute_and_show(conn, sql_5_1, {"status": "accepted"})

        print_banner("Task 5.2", "Papers Whose Abstract Contains 'machine learning' (Case-Insensitive)")
        sql_5_2 = """
        SELECT
            p.paper_id,
            p.title
        FROM paper p
        WHERE LOWER(p.abstract) LIKE LOWER(:search_pattern)
        ORDER BY p.paper_id
        """
        execute_and_show(conn, sql_5_2, {"search_pattern": "%machine learning%"})

        print_banner("Task 5.3", "Versions for Selected Paper Ordered Highest to Lowest")
        sql_5_3 = """
        SELECT
            pv.version_no,
            pv.file_location,
            pv.uploaded_at
        FROM paper_version pv
        WHERE pv.paper_id = :paper_id
        ORDER BY pv.version_no DESC
        """
        execute_and_show(conn, sql_5_3, {"paper_id": 1})

        print_banner("Task 5.4", "Qualified 'Databases' Reviewers in Selected Conference Pool")
        sql_5_4 = """
        SELECT DISTINCT
            u.user_id AS reviewer_id,
            u.given_name || ' ' || u.surname AS full_name,
            u.email
        FROM conference_reviewer cr
        JOIN reviewer r
            ON r.reviewer_id = cr.reviewer_id
        JOIN app_user u
            ON u.user_id = r.reviewer_id
        JOIN reviewer_expertise re
            ON re.reviewer_id = r.reviewer_id
        WHERE cr.conference_id = :conference_id
          AND re.area_label = :expertise_area
          AND r.years_experience >= :min_years
        ORDER BY u.user_id
        """
        execute_and_show(
            conn,
            sql_5_4,
            {
                "conference_id": 1,
                "expertise_area": "Databases",
                "min_years": 3,
            },
        )


def task_6_complex_queries(engine: Engine) -> None:
    with engine.connect() as conn:
        print_banner("Task 6.1", "Track Summary: Distinct Papers and Distinct Authors")
        sql_6_1 = """
        SELECT
            t.track_id,
            t.name AS track_name,
            t.conference_id,
            COUNT(DISTINCT p.paper_id) AS distinct_papers,
            COUNT(DISTINCT pa.author_id) AS distinct_authors
        FROM track t
        LEFT JOIN paper p
            ON p.track_id = t.track_id
        LEFT JOIN paper_author pa
            ON pa.paper_id = p.paper_id
        GROUP BY t.track_id, t.name, t.conference_id
        ORDER BY t.track_id
        """
        execute_and_show(conn, sql_6_1)

        print_banner("Task 6.2", "Reviewer Summary: Completed Reviews and Average Score")
        sql_6_2 = """
        SELECT
            r.reviewer_id,
            u.given_name || ' ' || u.surname AS full_name,
            COUNT(rev.review_id) AS completed_reviews,
            ROUND(AVG(rev.overall_score), 2) AS avg_overall_score
        FROM reviewer r
        JOIN app_user u
            ON u.user_id = r.reviewer_id
        LEFT JOIN review rev
            ON rev.reviewer_id = r.reviewer_id
        GROUP BY r.reviewer_id, u.given_name, u.surname
        ORDER BY r.reviewer_id
        """
        execute_and_show(conn, sql_6_2)

        print_banner("Task 6.3", "Conference Summary: Total Papers, Accepted Papers, and Average Score")
        sql_6_3 = """
        WITH paper_stats AS (
            SELECT
                t.conference_id,
                COUNT(p.paper_id) AS total_papers,
                COUNT(CASE WHEN p.status = :accepted_status THEN 1 END) AS accepted_papers
            FROM track t
            JOIN paper p
                ON p.track_id = t.track_id
            GROUP BY t.conference_id
        ),
        review_stats AS (
            SELECT
                t.conference_id,
                AVG(rev.overall_score) AS avg_overall_score
            FROM track t
            JOIN paper p
                ON p.track_id = t.track_id
            JOIN review rev
                ON rev.paper_id = p.paper_id
            GROUP BY t.conference_id
        )
        SELECT
            c.conference_id,
            c.acronym,
            COALESCE(ps.total_papers, 0) AS total_papers,
            COALESCE(ps.accepted_papers, 0) AS accepted_papers,
            ROUND(rs.avg_overall_score, 2) AS avg_overall_score
        FROM conference c
        LEFT JOIN paper_stats ps
            ON ps.conference_id = c.conference_id
        LEFT JOIN review_stats rs
            ON rs.conference_id = c.conference_id
        ORDER BY c.conference_id
        """
        execute_and_show(conn, sql_6_3, {"accepted_status": "accepted"})

        print_banner("Task 6.4", "Reviewers with Above-Average Completed Review Counts")
        sql_6_4 = """
        WITH reviewer_counts AS (
            SELECT
                r.reviewer_id,
                u.given_name || ' ' || u.surname AS full_name,
                COUNT(rev.review_id) AS review_count
            FROM reviewer r
            JOIN app_user u
                ON u.user_id = r.reviewer_id
            LEFT JOIN review rev
                ON rev.reviewer_id = r.reviewer_id
            GROUP BY r.reviewer_id, u.given_name, u.surname
        )
        SELECT
            rc.reviewer_id,
            rc.full_name,
            rc.review_count,
            ROUND((SELECT AVG(review_count) FROM reviewer_counts), 2) AS overall_avg_reviews
        FROM reviewer_counts rc
        WHERE rc.review_count > (SELECT AVG(review_count) FROM reviewer_counts)
        ORDER BY rc.review_count DESC, rc.reviewer_id
        """
        execute_and_show(conn, sql_6_4)

def task_7_acceptance_rate(engine: Engine) -> None:
    print_banner("Task 7", "Conference Acceptance Rate (%)")
    sql_7 = """
    SELECT
        c.conference_id,
        c.acronym,
        COUNT(CASE WHEN p.status = :accepted_status THEN 1 END) AS accepted_count,
        COUNT(CASE WHEN p.status = :rejected_status THEN 1 END) AS rejected_count,
        ROUND(
            100.0 * COUNT(CASE WHEN p.status = :accepted_status THEN 1 END)
            / NULLIF(
                COUNT(CASE WHEN p.status IN (:accepted_status, :rejected_status) THEN 1 END),
                0
            ),
            2
        ) AS acceptance_rate_pct
    FROM conference c
    LEFT JOIN track t
        ON t.conference_id = c.conference_id
    LEFT JOIN paper p
        ON p.track_id = t.track_id
    GROUP BY c.conference_id, c.acronym
    ORDER BY c.conference_id
    """
    with engine.connect() as conn:
        execute_and_show(
            conn,
            sql_7,
            {
                "accepted_status": "accepted",
                "rejected_status": "rejected",
            },
        )


def task_8_view_operation(engine: Engine) -> None:
    print_banner("Task 8", "Create and Query View: accepted_paper_schedule")
    create_view_sql = """
    CREATE OR REPLACE VIEW accepted_paper_schedule AS
    SELECT
        p.paper_id,
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
        chair_u.given_name || ' ' || chair_u.surname AS chair_full_name,
        auth_u.given_name || ' ' || auth_u.surname AS corresponding_author_full_name,
        auth_u.email AS corresponding_author_email
    FROM paper p
    JOIN conference_session cs
        ON cs.session_id = p.session_id
    JOIN track t
        ON t.track_id = p.track_id
    JOIN conference c
        ON c.conference_id = t.conference_id
    JOIN app_user chair_u
        ON chair_u.user_id = cs.chair_id
    JOIN paper_author pa
        ON pa.paper_id = p.paper_id AND pa.is_corresponding = TRUE
    JOIN app_user auth_u
        ON auth_u.user_id = pa.author_id
    WHERE p.status = 'accepted'
    """
    select_view_sql = """
    SELECT *
    FROM accepted_paper_schedule
    ORDER BY conference_id, session_date, start_time, session_id, paper_id
    """

    with engine.begin() as conn:
        execute_and_show(conn, create_view_sql, label="CREATE VIEW accepted_paper_schedule")
    with engine.connect() as conn:
        execute_and_show(conn, select_view_sql, label="QUERY VIEW accepted_paper_schedule")



engine = create_engine(DATABASE_URL, future=True)

task_1_create_schema(engine)
task_2_insert_seed_data(engine)

task_3_1_update_arman_phone(engine)
task_3_2_extend_review_deadlines(engine)

task_4_1_delete_amina_withdrawn_papers(engine)
task_4_2_delete_empty_astana_sessions(engine)

task_5_simple_queries(engine)
task_6_complex_queries(engine)
task_7_acceptance_rate(engine)
task_8_view_operation(engine)
