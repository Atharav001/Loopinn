# ADR 0003 — Timer recovery

Status: accepted design; timer engine not yet implemented.

Timer sessions will persist absolute deadlines, mode, phase and paused remaining duration. On launch, wake and clock or timezone changes, the timer service will reconcile from persisted state. It will not infer activity logs from elapsed timer time or claim an OS notification was delivered while the device was off.
