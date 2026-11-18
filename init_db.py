
import os
from pathlib import Path
from sqlalchemy import create_engine

raw_url = "postgresql://csci341_assignment3_user:92TrmFxbiHVd5lYvJBvGvIjToquKQTh2@dpg-dbutkg8n74is739cq84g-a.singapore-postgres.render.com/csci341_assignment3"

if raw_url.startswith("postgres://"):
    raw_url = raw_url.replace("postgres://", "postgresql+psycopg2://", 1)
elif raw_url.startswith("postgresql://") and "+psycopg2" not in raw_url:
    raw_url = raw_url.replace("postgresql://", "postgresql+psycopg2://", 1)

BASE_DIR = Path(__file__).resolve().parent
schema_sql = (BASE_DIR / "schema.sql").read_text(encoding="utf-8")
seed_sql = (BASE_DIR / "seed.sql").read_text(encoding="utf-8")

view_sql = """
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
JOIN conference_session cs ON cs.session_id = p.session_id
JOIN track t ON t.track_id = p.track_id
JOIN conference c ON c.conference_id = t.conference_id
JOIN app_user chair_u ON chair_u.user_id = cs.chair_id
JOIN paper_author pa ON pa.paper_id = p.paper_id AND pa.is_corresponding = TRUE
JOIN app_user auth_u ON auth_u.user_id = pa.author_id
WHERE p.status = 'accepted';
"""

engine = create_engine(raw_url, future=True)
with engine.begin() as conn:
    conn.exec_driver_sql(schema_sql)
    conn.exec_driver_sql(seed_sql)
    conn.exec_driver_sql(view_sql)

print("Database schema, seed data, and accepted_paper_schedule view initialized successfully.")