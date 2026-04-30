---
name: observability-and-monitoring
description: Instruments systems for production visibility. Use when a service is about to ship, when debugging production issues without sufficient data, or when setting up alerting and dashboards for an existing system.
---

# Observability and Monitoring

## Overview

Shipping code without observability is guessing in the dark. This skill covers the three pillars of production visibility — logs, metrics, and traces — and the alerting strategy that turns raw signals into actionable pages. Build observability before you need it, not after your first outage.

## When to Use

- Before a service ships to production
- When a production issue can't be debugged because the data isn't there
- When alerts fire constantly (or never) and nobody trusts them
- When onboarding a new service or taking ownership of an existing one
- When defining or auditing SLOs

**When NOT to use:** Pre-production development where log output in the terminal is sufficient. Don't instrument for production before the feature is stable enough to ship.

## The Three Pillars

```
Logs ──────→ What happened (discrete events, full context)
Metrics ───→ How the system behaves over time (aggregates, trends)
Traces ────→ Why it happened (request path across services)
```

Each pillar answers different questions. Logs alone don't scale; metrics alone lose context; traces alone miss the big picture. Use all three.

## Step 0: Audit Existing Instrumentation (Brownfield Services)

If you're instrumenting an existing service rather than starting from scratch, don't add more before understanding what's already there. Duplicate or conflicting instrumentation is harder to fix than no instrumentation.

```
1. List what's already logging — structured or unstructured? correlation IDs present?
2. List existing metrics — what's being emitted? what's missing from the four golden signals?
3. List existing alerts — are they firing? are they being acted on?
4. Identify the gaps against references/observability-checklist.md
5. Fix gaps incrementally — don't rip out working instrumentation to replace it
```

If taking ownership of a service with no instrumentation at all, treat it as greenfield and start at Step 1.

## Step 1: Structured Logging

Logs are only useful if they're searchable and correlatable. Raw string logs are text you can grep at 3am — structured logs are data you can query.

**What structured logging looks like:**

```json
{
  "timestamp": "2025-03-01T14:23:01Z",
  "level": "error",
  "message": "Payment processing failed",
  "trace_id": "abc123",
  "user_id": "u_456",
  "order_id": "ord_789",
  "error_code": "card_declined",
  "duration_ms": 342
}
```

**Log level discipline:**

| Level | When to use |
|-------|-------------|
| `error` | Something failed that requires human attention |
| `warn` | Degraded state, non-fatal, worth investigating |
| `info` | Key business events (order placed, user signed in) |
| `debug` | Detailed internal state — disabled in production by default |

**Rules:**
- Include a `trace_id` on every log line so you can reconstruct a request's path
- Log at decision points, not every function call
- Never log PII (passwords, tokens, credit card numbers, SSNs)
- Log **metadata only** for external service calls: endpoint name, status code, latency, retry count, and sanitized identifiers (e.g. order ID) — never request/response bodies, auth headers, or tokens. Enable body logging only through an explicit, narrowly scoped debug flag that is off by default

## Step 2: Metrics

Metrics answer "how is the system performing?" They're aggregates — not individual events. The four golden signals cover most production systems:

```
Latency   → How long requests take (p50, p95, p99 — never just average)
Traffic   → How many requests per second
Errors    → Error rate (not count — rate normalizes for traffic)
Saturation → How full is the system (CPU, memory, queue depth, connection pool)
```

**Instrument these first:**

```
Every HTTP endpoint:
  - request_count (counter, by status code, method, route_template)
  - request_duration_seconds (histogram, by status code, method, route_template)

Every queue/worker:
  - queue_depth (gauge)
  - processing_duration_seconds (histogram)
  - job_failures_total (counter)

Every external dependency:
  - dependency_request_duration_seconds (histogram, by service, endpoint)
  - dependency_errors_total (counter, by service, error type)
```

**Use histograms for latency, not averages.** An average of 200ms can hide a p99 of 10s. A p99 of 10s means 1 in 100 users is waiting 10 seconds.

**Cardinality rule:** Metric labels must be low-cardinality. Use route templates (`/users/:id`), not raw paths (`/users/123`). Never include user IDs, tenant IDs, request bodies, or query strings in labels — each unique value creates a new time series, which can make dashboards unusable and drive up telemetry cost.

## Step 3: Distributed Tracing

Tracing shows the full path of a request across services. Add it when:
- You have more than one service involved in a request
- You're debugging latency and can't tell which service is slow

**Minimum viable tracing:**

Use OpenTelemetry — it is the industry standard and interoperates across services via the W3C `traceparent`/`tracestate` headers. Do not hand-roll custom `X-Trace-Id` or `X-Span-Id` headers; they will not be understood by downstream services or telemetry backends.

```python
# OpenTelemetry handles context propagation automatically
from opentelemetry import trace
from opentelemetry.propagate import inject

tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("checkout.process_payment") as span:
    span.set_attribute("order.id", order_id)
    headers = {}
    inject(headers)  # Injects W3C traceparent/tracestate — not custom headers
    response = http_client.post(payment_url, headers=headers)
```

Services that extract context via the configured OpenTelemetry propagator will automatically continue the trace across the boundary.

## Step 4: SLOs and Alerting

SLOs define what "working correctly" means. Without SLOs, you don't know when to page, and every anomaly becomes a question mark.

**Define SLOs before writing alerts:**

```
Service: Checkout API
SLO: 99.9% of requests succeed (non-5xx) over a 30-day window
SLO: 95% of requests complete in under 500ms over a 30-day window
Error budget: 0.1% = ~43 minutes of downtime per 30 days
```

**Alert on SLO burn rate, not thresholds:**

```
BAD:  Alert when error rate > 1%
      → Fires on transient spikes, causes alert fatigue

GOOD: Alert when error budget burns > 5% in the last 1 hour
      → Fires only when the SLO is at real risk
```

**Alert routing:**
- Page immediately: SLO breach imminent (burn rate high), complete outage
- Ticket (next business day): Elevated error rate but error budget not at risk
- Dashboard only: Normal variation, trends to watch

**Eliminate noisy alerts.** An alert that fires and gets ignored trains engineers to ignore alerts. Every alert must be actionable — if you can't describe what action to take, don't page for it.

## Step 5: Dashboards

Dashboards are for humans. Design them for the question they answer, not to show every metric.

**Three dashboards to build:**

```
1. Service health (operational)
   → Error rate, latency p99, traffic, saturation
   → Audience: on-call engineer at 3am
   → Design: big numbers, clear red/green status

2. Business metrics (product)
   → User-facing outcomes: signups, conversions, active sessions
   → Audience: PMs, leadership
   → Design: trends over time, week-over-week comparisons

3. Dependency health (diagnostic)
   → Per-dependency error rates and latency
   → Audience: engineer debugging an incident
   → Design: side-by-side, correlatable time ranges
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "We'll add monitoring after launch" | After launch you'll have a production incident and no data. You'll add monitoring reactively, under pressure, badly. |
| "The logs are enough" | Unstructured logs are full-text search. At 3am with a P0. No correlation IDs, no trace context, no queryable fields. |
| "We alert on CPU > 80%" | CPU is a symptom, not a user experience. You'll page at night for nothing. Alert on what users feel: error rates and latency. |
| "Our error rate is low, we're fine" | Error rate without a latency SLO misses slow requests. A 0% error rate with p99 of 30s is not "fine". |
| "We don't have SLOs yet" | Without SLOs you can't define "working correctly," you can't set meaningful alerts, and you can't have a rational on-call rotation. |
| "OpenTelemetry is too complex" | It's the industry standard. Rolling your own tracing is a much worse investment. |

## Red Flags

- Logs with no trace_id or correlation identifier
- Logging PII (passwords, tokens, card numbers)
- Alerts on raw resource metrics (CPU, memory) with no user-impact alerts
- Alert fatigue — engineers auto-acknowledging pages without looking
- `error_count > 10` style alerts instead of rate-based alerts
- No SLOs defined, so nobody agrees on what "working" means
- Dashboards nobody looks at (stale, wrong time range defaults, broken queries)
- Metrics averaged instead of percentiled (p95/p99) for latency
- No tracing across service boundaries — each service is a black box
- Observability added reactively after the first production incident

## Verification

After instrumenting a service:

- [ ] Every HTTP endpoint emits request count and latency histograms
- [ ] Logs are structured (JSON), include trace_id, and contain no PII
- [ ] Log levels are correct — debug disabled in production, errors are actionable
- [ ] SLOs are defined for availability and latency
- [ ] Alerts fire on SLO burn rate, not raw thresholds
- [ ] Every alert has a documented runbook or action to take
- [ ] Service health dashboard exists with error rate, latency p99, and traffic
- [ ] Trace context propagated across all outbound calls
- [ ] Error budget is tracked and visible to the team
- [ ] On-call rotation tested — alert fires, right person gets paged, runbook resolves it

For a comprehensive pre-launch gate and full instrumentation checklist, see `references/observability-checklist.md`.

Use `shipping-and-launch` for the pre-launch checklist that confirms observability is in place before going live.
