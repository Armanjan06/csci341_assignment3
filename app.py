
from datetime import date, datetime, time
import os
from typing import Literal, Optional
from fastapi import FastAPI, HTTPException, status
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Connection
from sqlalchemy.exc import IntegrityError


def get_database_url() -> str:
    url = "postgresql://csci341_assignment3_user:92TrmFxbiHVd5lYvJBvGvIjToquKQTh2@dpg-dbutkg8n74is739cq84g-a.singapore-postgres.render.com/csci341_assignment3"
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+psycopg2://", 1)
    elif url.startswith("postgresql://") and "+psycopg2" not in url:
        url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
    return url


engine = create_engine(get_database_url(), pool_pre_ping=True, future=True)

app = FastAPI(
    title="CSCI 341 Conference & Paper Review Management System",
    description=(
        "Full CRUD management for Users (with Author/Reviewer profiles), "
        "Papers (with Authors, Keywords, and Versions), Reviews, and Sessions, "
        "plus read-only lookup endpoints for Conferences, Tracks, and Schedule."
    ),
    version="1.0.0",
)


def handle_db_error(exc: IntegrityError) -> HTTPException:
    detail = str(exc.orig) if exc.orig else str(exc)
    return HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=f"Database integrity constraint violated: {detail}",
    )


class AuthorProfileIn(BaseModel):
    orcid: Optional[str] = Field(default=None, max_length=25)
    research_areas: list[str] = Field(..., min_length=1, examples=[["Databases", "Machine Learning"]])


class ReviewerProfileIn(BaseModel):
    years_experience: int = Field(..., ge=0, examples=[4])
    expertise_areas: list[str] = Field(..., min_length=1, examples=[["Databases", "Distributed Systems"]])


class UserPayload(BaseModel):
    given_name: str = Field(..., min_length=1, max_length=100, examples=["Dana"])
    surname: str = Field(..., min_length=1, max_length=100, examples=["Suleimenova"])
    email: EmailStr = Field(..., examples=["dana.suleimenova@example.com"])
    affiliation: str = Field(..., min_length=1, max_length=255, examples=["Nazarbayev University"])
    country: str = Field(..., min_length=1, max_length=100, examples=["Kazakhstan"])
    phone_number: str = Field(..., min_length=1, max_length=30, examples=["+77019998877"])
    author: Optional[AuthorProfileIn] = None
    reviewer: Optional[ReviewerProfileIn] = None


class PaperAuthorIn(BaseModel):
    author_id: int = Field(..., ge=1)
    author_position: int = Field(..., ge=1)
    is_corresponding: bool = False


class PaperVersionIn(BaseModel):
    version_no: int = Field(..., ge=1)
    file_location: str = Field(..., min_length=1, max_length=500, examples=["/storage/papers/new_v1.pdf"])
    uploaded_at: datetime = Field(default_factory=datetime.now)
    change_note: Optional[str] = None


PaperStatus = Literal["submitted", "under review", "accepted", "rejected", "withdrawn"]


class PaperPayload(BaseModel):
    track_id: int = Field(..., ge=1, examples=[1])
    title: str = Field(..., min_length=1, max_length=300, examples=["Learned Indexes for Cloud Storage"])
    abstract: str = Field(..., min_length=1, examples=["We study machine learning index structures."])
    submission_date: date = Field(default_factory=date.today)
    status: PaperStatus = "submitted"
    session_id: Optional[int] = Field(default=None, ge=1)
    keywords: list[str] = Field(..., min_length=1, examples=[["Databases", "Machine Learning"]])
    authors: list[PaperAuthorIn] = Field(
        ...,
        min_length=1,
        examples=[[{"author_id": 1, "author_position": 1, "is_corresponding": True}]],
    )
    versions: list[PaperVersionIn] = Field(
        ...,
        min_length=1,
        examples=[
            [
                {
                    "version_no": 1,
                    "file_location": "/storage/papers/paper_new_v1.pdf",
                    "uploaded_at": "2026-10-01T12:00:00",
                    "change_note": "Initial submission",
                }
            ]
        ],
    )


class ReviewPayload(BaseModel):
    paper_id: int = Field(..., ge=1, examples=[1])
    reviewer_id: int = Field(..., ge=1, examples=[1])
    overall_score: int = Field(..., ge=1, le=5, examples=[4])
    recommendation: Literal["accept", "reject"] = "accept"
    comments_for_authors: str = Field(..., min_length=1, examples=["Clear experimental evaluation."])
    confidential_comments: Optional[str] = None
    review_submission_date: date = Field(default_factory=date.today)


class SessionPayload(BaseModel):
    conference_id: int = Field(..., ge=1, examples=[1])
    title: str = Field(..., min_length=1, max_length=255, examples=["Special Track on AI Systems"])
    session_date: date = Field(..., examples=["2026-10-16"])
    start_time: time = Field(..., examples=["15:00:00"])
    end_time: time = Field(..., examples=["16:30:00"])
    room_label: str = Field(..., min_length=1, max_length=100, examples=["Room C3.305"])
    chair_id: int = Field(..., ge=1, examples=[4])


def validate_user_roles(payload: UserPayload) -> None:
    if payload.author is None and payload.reviewer is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Every user must participate as an author, a reviewer, or both.",
        )


def validate_no_self_review(conn: Connection, paper_id: int, reviewer_id: int) -> None:
    row = conn.execute(
        text(
            """
            SELECT 1
            FROM paper_author
            WHERE paper_id = :paper_id AND author_id = :reviewer_id
            """
        ),
        {"paper_id": paper_id, "reviewer_id": reviewer_id},
    ).first()
    if row is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Self-review rejected: reviewer {reviewer_id} is listed as an author "
                f"of paper {paper_id}."
            ),
        )


def validate_paper_payload(
    conn: Connection,
    payload: PaperPayload,
    existing_paper_id: Optional[int] = None,
) -> None:
    corresponding_count = sum(1 for a in payload.authors if a.is_corresponding)
    if corresponding_count != 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"A paper must have exactly one corresponding author (found {corresponding_count}).",
        )

    author_ids = [a.author_id for a in payload.authors]
    if len(set(author_ids)) != len(author_ids):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Duplicate author_id entries are not allowed on the same paper.",
        )
    positions = [a.author_position for a in payload.authors]
    if len(set(positions)) != len(positions):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Author positions within a paper must be unique.",
        )

    version_nos = [v.version_no for v in payload.versions]
    if len(set(version_nos)) != len(version_nos):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Version numbers within a paper must be unique.",
        )

    if existing_paper_id is not None:
        conflict = conn.execute(
            text(
                """
                SELECT reviewer_id
                FROM review
                WHERE paper_id = :paper_id
                  AND reviewer_id = ANY(:author_ids)
                """
            ),
            {"paper_id": existing_paper_id, "author_ids": author_ids},
        ).first()
        if conflict is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Author update rejected: user {conflict.reviewer_id} has already "
                    f"submitted a review for paper {existing_paper_id}."
                ),
            )

    if payload.session_id is not None:
        if payload.status != "accepted":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Invalid session assignment: paper status is '{payload.status}', "
                    "but only 'accepted' papers may be assigned to a session."
                ),
            )

        track_row = conn.execute(
            text("SELECT conference_id FROM track WHERE track_id = :track_id"),
            {"track_id": payload.track_id},
        ).first()
        if track_row is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Track {payload.track_id} does not exist.",
            )

        session_row = conn.execute(
            text("SELECT conference_id FROM conference_session WHERE session_id = :session_id"),
            {"session_id": payload.session_id},
        ).first()
        if session_row is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Session {payload.session_id} does not exist.",
            )

        if track_row.conference_id != session_row.conference_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Invalid session assignment: track {payload.track_id} belongs to "
                    f"conference {track_row.conference_id}, whereas session {payload.session_id} "
                    f"belongs to conference {session_row.conference_id}."
                ),
            )


def fetch_user_detail(conn: Connection, user_id: int) -> dict:
    user = conn.execute(
        text("SELECT * FROM app_user WHERE user_id = :uid"),
        {"uid": user_id},
    ).mappings().first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    author = conn.execute(
        text("SELECT * FROM author WHERE author_id = :uid"),
        {"uid": user_id},
    ).mappings().first()
    author_data = None
    if author:
        areas = conn.execute(
            text("SELECT area_label FROM author_research_area WHERE author_id = :uid ORDER BY area_label"),
            {"uid": user_id},
        ).scalars().all()
        author_data = {"orcid": author["orcid"], "research_areas": list(areas)}

    reviewer = conn.execute(
        text("SELECT * FROM reviewer WHERE reviewer_id = :uid"),
        {"uid": user_id},
    ).mappings().first()
    reviewer_data = None
    if reviewer:
        areas = conn.execute(
            text("SELECT area_label FROM reviewer_expertise WHERE reviewer_id = :uid ORDER BY area_label"),
            {"uid": user_id},
        ).scalars().all()
        reviewer_data = {
            "years_experience": reviewer["years_experience"],
            "expertise_areas": list(areas),
        }

    return {**dict(user), "author": author_data, "reviewer": reviewer_data}


def fetch_paper_detail(conn: Connection, paper_id: int) -> dict:
    paper = conn.execute(
        text("SELECT * FROM paper WHERE paper_id = :pid"),
        {"pid": paper_id},
    ).mappings().first()
    if paper is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Paper not found.")

    keywords = conn.execute(
        text("SELECT keyword FROM paper_keyword WHERE paper_id = :pid ORDER BY keyword"),
        {"pid": paper_id},
    ).scalars().all()

    authors = conn.execute(
        text(
            """
            SELECT pa.author_id, u.given_name || ' ' || u.surname AS full_name,
                   pa.author_position, pa.is_corresponding
            FROM paper_author pa
            JOIN app_user u ON u.user_id = pa.author_id
            WHERE pa.paper_id = :pid
            ORDER BY pa.author_position
            """
        ),
        {"pid": paper_id},
    ).mappings().all()

    versions = conn.execute(
        text(
            """
            SELECT version_no, file_location, uploaded_at, change_note
            FROM paper_version
            WHERE paper_id = :pid
            ORDER BY version_no DESC
            """
        ),
        {"pid": paper_id},
    ).mappings().all()

    return {
        **dict(paper),
        "keywords": list(keywords),
        "authors": [dict(a) for a in authors],
        "versions": [dict(v) for v in versions],
    }


@app.get("/", include_in_schema=False)
def root() -> RedirectResponse:
    return RedirectResponse(url="/docs")


@app.get("/conferences", tags=["Supporting Data (Read-Only)"])
def list_conferences() -> list[dict]:
    with engine.connect() as conn:
        confs = conn.execute(text("SELECT * FROM conference ORDER BY conference_id")).mappings().all()
        result = []
        for c in confs:
            cid = c["conference_id"]
            hosts = conn.execute(
                text("SELECT host_name FROM conference_host WHERE conference_id = :cid ORDER BY host_name"),
                {"cid": cid},
            ).scalars().all()
            pool = conn.execute(
                text("SELECT reviewer_id FROM conference_reviewer WHERE conference_id = :cid ORDER BY reviewer_id"),
                {"cid": cid},
            ).scalars().all()
            result.append({**dict(c), "hosts": list(hosts), "reviewer_pool_ids": list(pool)})
        return result


@app.get("/tracks", tags=["Supporting Data (Read-Only)"])
def list_tracks() -> list[dict]:
    with engine.connect() as conn:
        rows = conn.execute(text("SELECT * FROM track ORDER BY track_id")).mappings().all()
        return [dict(r) for r in rows]


@app.get("/schedule", tags=["Supporting Data (Read-Only)"])
def view_accepted_paper_schedule() -> list[dict]:
    with engine.connect() as conn:
        rows = conn.execute(
            text(
                """
                SELECT * FROM accepted_paper_schedule
                ORDER BY conference_id, session_date, start_time, session_id, paper_id
                """
            )
        ).mappings().all()
        return [dict(r) for r in rows]

@app.get("/users", tags=["Users"])
def list_users() -> list[dict]:
    with engine.connect() as conn:
        ids = conn.execute(text("SELECT user_id FROM app_user ORDER BY user_id")).scalars().all()
        return [fetch_user_detail(conn, uid) for uid in ids]


@app.get("/users/{user_id}", tags=["Users"])
def get_user(user_id: int) -> dict:
    with engine.connect() as conn:
        return fetch_user_detail(conn, user_id)


@app.post("/users", status_code=status.HTTP_201_CREATED, tags=["Users"])
def create_user(payload: UserPayload) -> dict:
    validate_user_roles(payload)
    try:
        with engine.begin() as conn:
            new_id = conn.execute(
                text(
                    """
                    INSERT INTO app_user (given_name, surname, email, affiliation, country, phone_number)
                    VALUES (:given_name, :surname, :email, :affiliation, :country, :phone_number)
                    RETURNING user_id
                    """
                ),
                payload.model_dump(exclude={"author", "reviewer"}),
            ).scalar_one()

            if payload.author is not None:
                conn.execute(
                    text("INSERT INTO author (author_id, orcid) VALUES (:uid, :orcid)"),
                    {"uid": new_id, "orcid": payload.author.orcid},
                )
                for area in set(payload.author.research_areas):
                    conn.execute(
                        text("INSERT INTO author_research_area (author_id, area_label) VALUES (:uid, :area)"),
                        {"uid": new_id, "area": area.strip()},
                    )

            if payload.reviewer is not None:
                conn.execute(
                    text("INSERT INTO reviewer (reviewer_id, years_experience) VALUES (:uid, :exp)"),
                    {"uid": new_id, "exp": payload.reviewer.years_experience},
                )
                for area in set(payload.reviewer.expertise_areas):
                    conn.execute(
                        text("INSERT INTO reviewer_expertise (reviewer_id, area_label) VALUES (:uid, :area)"),
                        {"uid": new_id, "area": area.strip()},
                    )

            return fetch_user_detail(conn, new_id)
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.put("/users/{user_id}", tags=["Users"])
def update_user(user_id: int, payload: UserPayload) -> dict:
    validate_user_roles(payload)
    try:
        with engine.begin() as conn:
            updated = conn.execute(
                text(
                    """
                    UPDATE app_user
                    SET given_name = :given_name,
                        surname = :surname,
                        email = :email,
                        affiliation = :affiliation,
                        country = :country,
                        phone_number = :phone_number
                    WHERE user_id = :uid
                    """
                ),
                {**payload.model_dump(exclude={"author", "reviewer"}), "uid": user_id},
            ).rowcount
            if updated == 0:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

            if payload.author is None:
                conn.execute(text("DELETE FROM author WHERE author_id = :uid"), {"uid": user_id})
            else:
                conn.execute(
                    text(
                        """
                        INSERT INTO author (author_id, orcid)
                        VALUES (:uid, :orcid)
                        ON CONFLICT (author_id) DO UPDATE SET orcid = EXCLUDED.orcid
                        """
                    ),
                    {"uid": user_id, "orcid": payload.author.orcid},
                )
                conn.execute(text("DELETE FROM author_research_area WHERE author_id = :uid"), {"uid": user_id})
                for area in set(payload.author.research_areas):
                    conn.execute(
                        text("INSERT INTO author_research_area (author_id, area_label) VALUES (:uid, :area)"),
                        {"uid": user_id, "area": area.strip()},
                    )

            if payload.reviewer is None:
                conn.execute(text("DELETE FROM reviewer WHERE reviewer_id = :uid"), {"uid": user_id})
            else:
                conn.execute(
                    text(
                        """
                        INSERT INTO reviewer (reviewer_id, years_experience)
                        VALUES (:uid, :exp)
                        ON CONFLICT (reviewer_id) DO UPDATE SET years_experience = EXCLUDED.years_experience
                        """
                    ),
                    {"uid": user_id, "exp": payload.reviewer.years_experience},
                )
                conn.execute(text("DELETE FROM reviewer_expertise WHERE reviewer_id = :uid"), {"uid": user_id})
                for area in set(payload.reviewer.expertise_areas):
                    conn.execute(
                        text("INSERT INTO reviewer_expertise (reviewer_id, area_label) VALUES (:uid, :area)"),
                        {"uid": user_id, "area": area.strip()},
                    )

            return fetch_user_detail(conn, user_id)
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.delete("/users/{user_id}", tags=["Users"])
def delete_user(user_id: int) -> dict:
    try:
        with engine.begin() as conn:
            deleted = conn.execute(
                text("DELETE FROM app_user WHERE user_id = :uid"),
                {"uid": user_id},
            ).rowcount
            if deleted == 0:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
            return {"message": f"User {user_id} deleted successfully."}
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.get("/papers", tags=["Papers"])
def list_papers() -> list[dict]:
    with engine.connect() as conn:
        ids = conn.execute(text("SELECT paper_id FROM paper ORDER BY paper_id")).scalars().all()
        return [fetch_paper_detail(conn, pid) for pid in ids]


@app.get("/papers/{paper_id}", tags=["Papers"])
def get_paper(paper_id: int) -> dict:
    with engine.connect() as conn:
        return fetch_paper_detail(conn, paper_id)


@app.post("/papers", status_code=status.HTTP_201_CREATED, tags=["Papers"])
def create_paper(payload: PaperPayload) -> dict:
    try:
        with engine.begin() as conn:
            validate_paper_payload(conn, payload, existing_paper_id=None)

            new_pid = conn.execute(
                text(
                    """
                    INSERT INTO paper (track_id, title, abstract, submission_date, status, session_id)
                    VALUES (:track_id, :title, :abstract, :submission_date, :status, :session_id)
                    RETURNING paper_id
                    """
                ),
                payload.model_dump(exclude={"keywords", "authors", "versions"}),
            ).scalar_one()

            for kw in set(payload.keywords):
                conn.execute(
                    text("INSERT INTO paper_keyword (paper_id, keyword) VALUES (:pid, :kw)"),
                    {"pid": new_pid, "kw": kw.strip()},
                )

            for auth in payload.authors:
                conn.execute(
                    text(
                        """
                        INSERT INTO paper_author (paper_id, author_id, author_position, is_corresponding)
                        VALUES (:pid, :aid, :pos, :corr)
                        """
                    ),
                    {
                        "pid": new_pid,
                        "aid": auth.author_id,
                        "pos": auth.author_position,
                        "corr": auth.is_corresponding,
                    },
                )

            for ver in payload.versions:
                conn.execute(
                    text(
                        """
                        INSERT INTO paper_version (paper_id, version_no, file_location, uploaded_at, change_note)
                        VALUES (:pid, :vno, :loc, :ts, :note)
                        """
                    ),
                    {
                        "pid": new_pid,
                        "vno": ver.version_no,
                        "loc": ver.file_location,
                        "ts": ver.uploaded_at,
                        "note": ver.change_note,
                    },
                )

            return fetch_paper_detail(conn, new_pid)
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.put("/papers/{paper_id}", tags=["Papers"])
def update_paper(paper_id: int, payload: PaperPayload) -> dict:
    try:
        with engine.begin() as conn:
            exists = conn.execute(
                text("SELECT 1 FROM paper WHERE paper_id = :pid"),
                {"pid": paper_id},
            ).first()
            if exists is None:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Paper not found.")

            validate_paper_payload(conn, payload, existing_paper_id=paper_id)

            conn.execute(
                text(
                    """
                    UPDATE paper
                    SET track_id = :track_id,
                        title = :title,
                        abstract = :abstract,
                        submission_date = :submission_date,
                        status = :status,
                        session_id = :session_id
                    WHERE paper_id = :pid
                    """
                ),
                {**payload.model_dump(exclude={"keywords", "authors", "versions"}), "pid": paper_id},
            )

            conn.execute(text("DELETE FROM paper_keyword WHERE paper_id = :pid"), {"pid": paper_id})
            for kw in set(payload.keywords):
                conn.execute(
                    text("INSERT INTO paper_keyword (paper_id, keyword) VALUES (:pid, :kw)"),
                    {"pid": paper_id, "kw": kw.strip()},
                )

            conn.execute(text("DELETE FROM paper_author WHERE paper_id = :pid"), {"pid": paper_id})
            for auth in payload.authors:
                conn.execute(
                    text(
                        """
                        INSERT INTO paper_author (paper_id, author_id, author_position, is_corresponding)
                        VALUES (:pid, :aid, :pos, :corr)
                        """
                    ),
                    {
                        "pid": paper_id,
                        "aid": auth.author_id,
                        "pos": auth.author_position,
                        "corr": auth.is_corresponding,
                    },
                )

            conn.execute(text("DELETE FROM paper_version WHERE paper_id = :pid"), {"pid": paper_id})
            for ver in payload.versions:
                conn.execute(
                    text(
                        """
                        INSERT INTO paper_version (paper_id, version_no, file_location, uploaded_at, change_note)
                        VALUES (:pid, :vno, :loc, :ts, :note)
                        """
                    ),
                    {
                        "pid": paper_id,
                        "vno": ver.version_no,
                        "loc": ver.file_location,
                        "ts": ver.uploaded_at,
                        "note": ver.change_note,
                    },
                )

            return fetch_paper_detail(conn, paper_id)
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.delete("/papers/{paper_id}", tags=["Papers"])
def delete_paper(paper_id: int) -> dict:
    try:
        with engine.begin() as conn:
            deleted = conn.execute(
                text("DELETE FROM paper WHERE paper_id = :pid"),
                {"pid": paper_id},
            ).rowcount
            if deleted == 0:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Paper not found.")
            return {"message": f"Paper {paper_id} and its dependent versions/authorships/keywords/reviews deleted."}
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.get("/reviews", tags=["Reviews"])
def list_reviews() -> list[dict]:
    with engine.connect() as conn:
        rows = conn.execute(text("SELECT * FROM review ORDER BY review_id")).mappings().all()
        return [dict(r) for r in rows]


@app.get("/reviews/{review_id}", tags=["Reviews"])
def get_review(review_id: int) -> dict:
    with engine.connect() as conn:
        row = conn.execute(
            text("SELECT * FROM review WHERE review_id = :rid"),
            {"rid": review_id},
        ).mappings().first()
        if row is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found.")
        return dict(row)


@app.post("/reviews", status_code=status.HTTP_201_CREATED, tags=["Reviews"])
def create_review(payload: ReviewPayload) -> dict:
    try:
        with engine.begin() as conn:
            validate_no_self_review(conn, payload.paper_id, payload.reviewer_id)

            new_rid = conn.execute(
                text(
                    """
                    INSERT INTO review (
                        paper_id, reviewer_id, overall_score, recommendation,
                        comments_for_authors, confidential_comments, review_submission_date
                    )
                    VALUES (
                        :paper_id, :reviewer_id, :overall_score, :recommendation,
                        :comments_for_authors, :confidential_comments, :review_submission_date
                    )
                    RETURNING review_id
                    """
                ),
                payload.model_dump(),
            ).scalar_one()

            row = conn.execute(
                text("SELECT * FROM review WHERE review_id = :rid"),
                {"rid": new_rid},
            ).mappings().one()
            return dict(row)
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.put("/reviews/{review_id}", tags=["Reviews"])
def update_review(review_id: int, payload: ReviewPayload) -> dict:
    try:
        with engine.begin() as conn:
            validate_no_self_review(conn, payload.paper_id, payload.reviewer_id)

            updated = conn.execute(
                text(
                    """
                    UPDATE review
                    SET paper_id = :paper_id,
                        reviewer_id = :reviewer_id,
                        overall_score = :overall_score,
                        recommendation = :recommendation,
                        comments_for_authors = :comments_for_authors,
                        confidential_comments = :confidential_comments,
                        review_submission_date = :review_submission_date
                    WHERE review_id = :rid
                    """
                ),
                {**payload.model_dump(), "rid": review_id},
            ).rowcount
            if updated == 0:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found.")

            row = conn.execute(
                text("SELECT * FROM review WHERE review_id = :rid"),
                {"rid": review_id},
            ).mappings().one()
            return dict(row)
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.delete("/reviews/{review_id}", tags=["Reviews"])
def delete_review(review_id: int) -> dict:
    with engine.begin() as conn:
        deleted = conn.execute(
            text("DELETE FROM review WHERE review_id = :rid"),
            {"rid": review_id},
        ).rowcount
        if deleted == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found.")
        return {"message": f"Review {review_id} deleted successfully."}


@app.get("/sessions", tags=["Sessions"])
def list_sessions() -> list[dict]:
    with engine.connect() as conn:
        rows = conn.execute(text("SELECT * FROM conference_session ORDER BY session_id")).mappings().all()
        return [dict(r) for r in rows]


@app.get("/sessions/{session_id}", tags=["Sessions"])
def get_session(session_id: int) -> dict:
    with engine.connect() as conn:
        row = conn.execute(
            text("SELECT * FROM conference_session WHERE session_id = :sid"),
            {"sid": session_id},
        ).mappings().first()
        if row is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
        return dict(row)


@app.post("/sessions", status_code=status.HTTP_201_CREATED, tags=["Sessions"])
def create_session(payload: SessionPayload) -> dict:
    try:
        with engine.begin() as conn:
            new_sid = conn.execute(
                text(
                    """
                    INSERT INTO conference_session (
                        conference_id, title, session_date, start_time, end_time, room_label, chair_id
                    )
                    VALUES (
                        :conference_id, :title, :session_date, :start_time, :end_time, :room_label, :chair_id
                    )
                    RETURNING session_id
                    """
                ),
                payload.model_dump(),
            ).scalar_one()

            row = conn.execute(
                text("SELECT * FROM conference_session WHERE session_id = :sid"),
                {"sid": new_sid},
            ).mappings().one()
            return dict(row)
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.put("/sessions/{session_id}", tags=["Sessions"])
def update_session(session_id: int, payload: SessionPayload) -> dict:
    try:
        with engine.begin() as conn:
            mismatch = conn.execute(
                text(
                    """
                    SELECT p.paper_id, t.conference_id
                    FROM paper p
                    JOIN track t ON t.track_id = p.track_id
                    WHERE p.session_id = :sid
                      AND t.conference_id <> :new_conf_id
                    """
                ),
                {"sid": session_id, "new_conf_id": payload.conference_id},
            ).first()
            if mismatch is not None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(
                        f"Session update rejected: paper {mismatch.paper_id} assigned to this "
                        f"session belongs to conference {mismatch.conference_id}, not {payload.conference_id}."
                    ),
                )

            updated = conn.execute(
                text(
                    """
                    UPDATE conference_session
                    SET conference_id = :conference_id,
                        title = :title,
                        session_date = :session_date,
                        start_time = :start_time,
                        end_time = :end_time,
                        room_label = :room_label,
                        chair_id = :chair_id
                    WHERE session_id = :sid
                    """
                ),
                {**payload.model_dump(), "sid": session_id},
            ).rowcount
            if updated == 0:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")

            row = conn.execute(
                text("SELECT * FROM conference_session WHERE session_id = :sid"),
                {"sid": session_id},
            ).mappings().one()
            return dict(row)
    except IntegrityError as exc:
        raise handle_db_error(exc)


@app.delete("/sessions/{session_id}", tags=["Sessions"])
def delete_session(session_id: int) -> dict:
    with engine.begin() as conn:
        deleted = conn.execute(
            text("DELETE FROM conference_session WHERE session_id = :sid"),
            {"sid": session_id},
        ).rowcount
        if deleted == 0:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
        return {"message": f"Session {session_id} deleted (any assigned papers now have session_id = NULL)."}