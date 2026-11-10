# ADR 0004 — Sync conflicts

Status: provisional; cloud backend not yet implemented.

Each synced record will use a stable ID, owner, revision, device ID and tombstone. Local writes commit first to an outbox. Transport retries use stable idempotency keys and bounded backoff. A concurrent edit that cannot be merged without losing fields will surface a conflict to the user; server ownership rules must isolate accounts. This policy requires contract and two-device tests before release.
