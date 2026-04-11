---
description: Run the pre-launch checklist and prepare for production deployment
---

Invoke the agent-skills:shipping-and-launch skill.

Run through the complete pre-launch checklist:

1. **Code Quality** — Tests pass, build clean, lint clean, no TODOs, no console.logs
2. **Security** — npm audit clean, no secrets in code, auth in place, headers configured
3. **Performance** — Core Web Vitals good, no N+1 queries, images optimized, bundle sized
4. **Accessibility** — Keyboard nav works, screen reader compatible, contrast adequate
5. **Infrastructure** — Env vars set, migrations ready, monitoring configured
6. **Observability** — Invoke the agent-skills:observability-and-monitoring skill to verify structured logging, metrics (four golden signals), SLOs, and alerting are in place before going live
7. **Documentation** — README current, ADRs written, changelog updated

Report any failing checks and help resolve them before deployment.
Define the rollback plan before proceeding.
