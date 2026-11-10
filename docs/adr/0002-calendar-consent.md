# ADR 0002 — Calendar consent

Status: accepted product boundary; external adapters not yet implemented.

A task gets an internal block only after a valid explicit start and end time. Due date alone is not a schedule. Apple or Google Calendar publication will require a provider/destination/interval preview and explicit approval for each operation or batch. Approval must be recorded before a durable publish request is queued. Provider disconnection leaves local tasks and blocks intact.
