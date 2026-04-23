---
description: Run the pre-launch checklist and prepare for release
agent: build
---

Load and follow the `shipping-and-launch` skill using the native `skill` tool.

Run through the pre-launch checklist:

1. Code quality: tests, build, lint, and obvious cleanup
2. Security: secrets, auth, audit exposure, headers, and inputs
3. Performance: regressions, resource usage, and obvious bottlenecks
4. Accessibility: keyboard, screen-reader, and contrast checks where relevant
5. Infrastructure: configuration, migrations, monitoring, and rollback plan
6. Documentation: README, ADRs, and release notes as needed

Report failing checks and help resolve them before release.
