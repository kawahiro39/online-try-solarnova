# Cloud Run Real-time Presence Service

Flask application that exposes a heartbeat endpoint and SSE stream to track active and
idle visitors without any external data store. Presence is calculated from recent
`uid` heartbeats sent by the Bubble application.

## Endpoints

- `POST /v1/hit` — accepts `{ "uid": "<user-id>", "last_activity": <unix-seconds> }`
  and records both the heartbeat receipt time (`last_seen`) and the visitor's most
  recent interaction (`last_activity`). Intended to be invoked from the visitor page
  every ~30 seconds.
- `GET /sse/online` — streams the current list of active and idle visitors every two
  seconds as Server-Sent Events with payloads like:

  ```json
  {
    "ts": 1710000000,
    "online_total": 5,
    "active_total": 3,
    "idle_total": 2,
    "active_uids": ["alice", "bob", "carol"],
    "idle_uids": ["dave", "eve"]
  }
  ```

  Visitors whose last heartbeat arrived within 60 seconds are treated as online, and
  those whose `last_activity` is within the most recent five minutes are considered
  active. Responses disable proxy buffering so events arrive immediately.

- `GET /healthz` — always returns `{ "ok": true }`.
- `GET /readyz` — always returns `{ "ok": true }`.

## Environment Variables

- `PORT` (default: `8080`)
- `CORS_ALLOW_ORIGIN` — Bubble domain allowed to access the API. Defaults to
  `https://solar-system-82998.bubbleapps.io`.

## Development

Install dependencies and run the Flask app:

```bash
pip install -r requirements.txt
gunicorn -b 0.0.0.0:8080 -w 1 -k gevent -t 0 app:app
```

No external services are required to run the server.

## Container Image

To build and run the service in a container (e.g. for Cloud Run), use the provided
`Dockerfile`:

```bash
docker build -t presence-service .
docker run --rm -p 8080:8080 presence-service
```

The container entrypoint runs Gunicorn with a single gevent worker and no timeout so
Server-Sent Event streams remain open indefinitely while still supporting concurrent
connections.

## Cloud Run Deployment Notes

- Configure the Cloud Run service with `max-instances=1` so a single instance maintains
  the in-memory presence dictionary.
- Adjust `--concurrency` to the expected number of simultaneous SSE clients (for example
  `--concurrency 50`).
