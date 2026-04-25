#!/usr/bin/env python3

import base64
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


def parse_timestamp(value: str):
    if not value:
        return None
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    return datetime.fromisoformat(value)


def decode_jwt_payload(token: str):
    parts = token.split(".")
    if len(parts) < 2:
        return None

    payload = parts[1] + "=" * (-len(parts[1]) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))


@dataclass
class Snapshot:
    timestamp: datetime
    limit_id: str | None
    primary_percent: float | None
    secondary_percent: float | None


@dataclass
class BucketState:
    percentage: float
    reset_at: datetime | None
    window_minutes: int


def is_canonical(snapshot: Snapshot) -> bool:
    return snapshot.limit_id == "codex"


def preferred_snapshot(events: list[Snapshot]):
    canonical = [event for event in events if is_canonical(event)]
    if canonical:
        return max(canonical, key=lambda item: item.timestamp)
    return max(events, key=lambda item: item.timestamp) if events else None


def normalize_bucket_state(bucket: BucketState, now: datetime):
    if bucket.reset_at is None:
        return bucket

    if bucket.reset_at > now:
        return bucket

    if bucket.window_minutes <= 0:
        return BucketState(percentage=0.0, reset_at=None, window_minutes=bucket.window_minutes)

    window_seconds = bucket.window_minutes * 60
    elapsed_windows = int((now - bucket.reset_at).total_seconds() // window_seconds)
    next_reset_at = bucket.reset_at.timestamp() + window_seconds * (max(0, elapsed_windows) + 1)
    return BucketState(
        percentage=0.0,
        reset_at=datetime.fromtimestamp(next_reset_at, tz=timezone.utc),
        window_minutes=bucket.window_minutes,
    )


def fixture_test():
    fixture_events = [
        Snapshot(
            timestamp=parse_timestamp("2026-04-23T21:07:11.925Z"),
            limit_id="codex",
            primary_percent=37.0,
            secondary_percent=20.0,
        ),
        Snapshot(
            timestamp=parse_timestamp("2026-04-23T21:07:24.404Z"),
            limit_id="codex_bengalfox",
            primary_percent=0.0,
            secondary_percent=0.0,
        ),
    ]

    selected = preferred_snapshot(fixture_events)
    assert selected is not None
    assert selected.limit_id == "codex", selected
    assert selected.primary_percent == 37.0, selected


def expired_bucket_reset_test():
    bucket = BucketState(
        percentage=0.92,
        reset_at=parse_timestamp("2026-04-24T00:07:20.526Z"),
        window_minutes=300,
    )

    normalized = normalize_bucket_state(
        bucket,
        now=parse_timestamp("2026-04-24T00:12:20.526Z"),
    )

    assert normalized.percentage == 0.0, normalized
    assert normalized.reset_at == parse_timestamp("2026-04-24T05:07:20.526Z"), normalized


def live_data_test():
    codex_home = Path.home() / ".codex"
    auth_path = codex_home / "auth.json"
    sessions_path = codex_home / "sessions"

    auth_json = json.loads(auth_path.read_text())
    last_refresh = parse_timestamp(auth_json.get("last_refresh", ""))
    subscription_active_start = None

    tokens = auth_json.get("tokens", {})
    for token in [tokens.get("id_token"), tokens.get("access_token")]:
        if not token:
            continue
        payload = decode_jwt_payload(token)
        auth = payload.get("https://api.openai.com/auth") if payload else None
        if not isinstance(auth, dict):
            continue
        subscription_active_start = parse_timestamp(
            auth.get("chatgpt_subscription_active_start", "")
        )
        break

    cutoff = max(
        [value for value in [last_refresh, subscription_active_start] if value],
        default=None,
    )

    session_files = sorted(
        sessions_path.rglob("*.jsonl"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )[:100]

    events: list[Snapshot] = []
    for session_file in session_files:
        for line in reversed(session_file.read_text().splitlines()):
            if '"type":"token_count"' not in line or '"rate_limits":' not in line:
                continue

            event = json.loads(line)
            if event.get("type") != "event_msg":
                continue

            payload = event.get("payload", {})
            if payload.get("type") != "token_count":
                continue

            rate_limits = payload.get("rate_limits") or {}
            if rate_limits.get("primary") is None and rate_limits.get("secondary") is None:
                continue

            timestamp = parse_timestamp(event.get("timestamp", ""))
            if cutoff and timestamp and timestamp < cutoff:
                continue

            events.append(
                Snapshot(
                    timestamp=timestamp,
                    limit_id=rate_limits.get("limit_id"),
                    primary_percent=(rate_limits.get("primary") or {}).get("used_percent"),
                    secondary_percent=(rate_limits.get("secondary") or {}).get("used_percent"),
                )
            )
            break

    assert events, "No eligible live Codex snapshots found"

    selected = preferred_snapshot(events)
    assert selected is not None

    canonical = [event for event in events if is_canonical(event)]
    assert canonical, "Expected at least one canonical codex snapshot in live data"
    assert selected.limit_id == "codex", selected


def main():
    fixture_test()
    expired_bucket_reset_test()
    live_data_test()
    now = datetime.now(timezone.utc).isoformat()
    print(f"{now} codex usage manager logic tests passed")


if __name__ == "__main__":
    main()
