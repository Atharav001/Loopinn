# ADR 0001 — Local data ownership

Status: accepted for the current development build.

Loopinn's local SQLite database owns canonical tasks, lists and internal calendar blocks. Attachments live in the app's controlled support directory with stable IDs in task records. UI surfaces call shared services; they do not keep independent copies. SQLite transactions commit task and linked block changes together. Cloud transport, when introduced, will read committed local changes through a durable outbox and must never replace local data on sign-in.
