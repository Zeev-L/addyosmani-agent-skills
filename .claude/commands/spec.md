---
description: Start spec-driven development — write a structured specification before writing code
---

Invoke the agent-skills:spec-driven-development skill.

Begin by understanding what the user wants to build. Ask clarifying questions about:
1. The objective and target users
2. Core features and acceptance criteria
3. Tech stack preferences and constraints
4. Known boundaries (what to always do, ask first about, and never do)

Then generate a structured spec covering all six core areas: objective, commands, project structure, code style, testing strategy, and boundaries.

Save the spec to a feature-specific directory: docs/features/[feature-name]/spec.md

First, determine the feature name based on the objective (e.g., "user-authentication", "payment-integration", "dashboard-analytics"). Create the directory structure docs/features/[feature-name]/ and save the spec as spec.md within that directory.

This prevents spec overwriting and enables multiple simultaneous features. Confirm with the user before proceeding.
