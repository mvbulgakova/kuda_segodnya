"""initial

Revision ID: 0001
Revises:
Create Date: 2026-08-05

"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "sources",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("slug", sa.String(64), nullable=False, unique=True),
        sa.Column("kind", sa.String(16), nullable=False),
        sa.Column("title", sa.String(256), nullable=False),
        sa.Column("url", sa.String(512), nullable=True),
        sa.Column("config", sa.JSON, nullable=False, server_default="{}"),
        sa.Column("active", sa.Boolean, nullable=False, server_default=sa.true()),
    )
    op.create_index("ix_sources_slug", "sources", ["slug"])

    op.create_table(
        "venues",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.String(256), nullable=False),
        sa.Column("address", sa.String(512), nullable=True),
        sa.Column("metro", sa.String(128), nullable=True),
        sa.Column("lat", sa.Float, nullable=True),
        sa.Column("lon", sa.Float, nullable=True),
    )
    op.create_index("ix_venues_name", "venues", ["name"])
    op.create_index("ix_venues_metro", "venues", ["metro"])

    op.create_table(
        "events",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("dedup_hash", sa.String(40), nullable=False, unique=True),
        sa.Column("title", sa.String(512), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "venue_id",
            sa.Integer,
            sa.ForeignKey("venues.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("price_kind", sa.String(16), nullable=False, server_default="free"),
        sa.Column("age_limit", sa.Integer, nullable=True),
        sa.Column("cover_url", sa.String(1024), nullable=True),
        sa.Column("canonical_url", sa.String(1024), nullable=True),
        sa.Column("status", sa.String(16), nullable=False, server_default="published"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_events_dedup_hash", "events", ["dedup_hash"])
    op.create_index("ix_events_starts_at", "events", ["starts_at"])
    op.create_index("ix_events_price_kind", "events", ["price_kind"])
    op.create_index("ix_events_status", "events", ["status"])

    op.create_table(
        "event_sources",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column(
            "event_id",
            sa.Integer,
            sa.ForeignKey("events.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "source_id",
            sa.Integer,
            sa.ForeignKey("sources.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("external_id", sa.String(128), nullable=False),
        sa.Column("external_url", sa.String(1024), nullable=True),
        sa.UniqueConstraint("source_id", "external_id", name="uq_source_external"),
    )
    op.create_index("ix_event_sources_event", "event_sources", ["event_id"])

    op.create_table(
        "users",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("tg_id", sa.BigInteger, nullable=False, unique=True),
        sa.Column("username", sa.String(64), nullable=True),
        sa.Column("first_name", sa.String(128), nullable=True),
        sa.Column("tz", sa.String(64), nullable=False, server_default="Europe/Moscow"),
        sa.Column(
            "subscribed_metros",
            sa.ARRAY(sa.String),
            nullable=False,
            server_default="{}",
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_users_tg_id", "users", ["tg_id"])

    op.create_table(
        "attendances",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column(
            "user_id",
            sa.Integer,
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "event_id",
            sa.Integer,
            sa.ForeignKey("events.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("status", sa.String(16), nullable=False, server_default="going"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("user_id", "event_id", name="uq_user_event"),
    )

    op.create_table(
        "reports",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column(
            "user_id",
            sa.Integer,
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "event_id",
            sa.Integer,
            sa.ForeignKey("events.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("reason", sa.String(32), nullable=False),
        sa.Column("text", sa.Text, nullable=True),
        sa.Column("resolved", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table("reports")
    op.drop_table("attendances")
    op.drop_index("ix_users_tg_id", table_name="users")
    op.drop_table("users")
    op.drop_index("ix_event_sources_event", table_name="event_sources")
    op.drop_table("event_sources")
    op.drop_index("ix_events_status", table_name="events")
    op.drop_index("ix_events_price_kind", table_name="events")
    op.drop_index("ix_events_starts_at", table_name="events")
    op.drop_index("ix_events_dedup_hash", table_name="events")
    op.drop_table("events")
    op.drop_index("ix_venues_metro", table_name="venues")
    op.drop_index("ix_venues_name", table_name="venues")
    op.drop_table("venues")
    op.drop_index("ix_sources_slug", table_name="sources")
    op.drop_table("sources")
