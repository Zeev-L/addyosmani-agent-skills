# Observability Checklist

Use this checklist when instrumenting a service for production or auditing an existing service's observability coverage.

## Logging

- [ ] Logs are structured (JSON) — not free-form strings
- [ ] Every log line includes a `trace_id` or correlation identifier
- [ ] Log levels are correct: `error` = needs human attention, `warn` = degraded but non-fatal, `info` = key business events, `debug` = disabled in production
- [ ] No PII in logs (passwords, tokens, credit card numbers, SSNs, email addresses)
- [ ] External service calls are logged with inputs (redacted where needed) and outcomes
- [ ] Log output has been reviewed — nothing that would expose internals to an attacker

## Metrics

- [ ] Request count emitted for every HTTP endpoint (by status code, method, route template)
- [ ] Request duration histogram emitted for every HTTP endpoint (p50, p95, p99)
- [ ] Queue depth and processing duration tracked for every worker/queue
- [ ] Dependency error rates and latency tracked per external service
- [ ] All metric labels are low-cardinality — no user IDs, tenant IDs, raw paths, or query strings
- [ ] Latency represented as histograms (p95/p99), not averages

## Tracing

- [ ] OpenTelemetry (or equivalent) initialized at service startup
- [ ] Trace context propagated on every outbound HTTP/gRPC call via W3C `traceparent`/`tracestate`
- [ ] Trace context extracted from every inbound request
- [ ] Key business operations wrapped in named spans with relevant attributes
- [ ] No sensitive data (tokens, PII) set as span attributes

## SLOs and Alerting

- [ ] SLOs defined for availability (e.g. 99.9% non-5xx) and latency (e.g. p95 < 500ms)
- [ ] Error budget calculated and visible to the team
- [ ] Alerts fire on SLO burn rate, not raw resource thresholds (CPU/memory)
- [ ] Every alert has a documented runbook or clear action to take
- [ ] Alert routing tested end-to-end: alert fires → right person paged → runbook resolves it
- [ ] No noisy alerts that get auto-acknowledged without action

## Dashboards

- [ ] Service health dashboard exists: error rate, latency p99, traffic, saturation
- [ ] Dashboard default time range is sensible (last 1h or last 6h, not last 30d)
- [ ] At least one person on the team has looked at the dashboard in the last week
- [ ] Dependency health panel shows per-service error rates and latency

## Pre-launch Gate

Before a service goes to production, all of the following must be true:

- [ ] Structured logs flowing to the log aggregator
- [ ] Four golden signals (latency, traffic, errors, saturation) visible in dashboards
- [ ] SLOs defined and error budget tracked
- [ ] At least one alert configured and tested
- [ ] On-call rotation knows where the runbooks are
