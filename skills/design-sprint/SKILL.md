---
name: design-sprint
description: Guides an accelerated digital product design sprint from ambiguity to validated direction. Use when teams need to decide what to build under uncertainty, align on a target moment, prototype quickly, and validate assumptions before writing specs or implementation plans.
---

# Design Sprint

## Overview

Run a facilitated, adaptive-depth design sprint for digital products.

This skill converts uncertainty into evidence by guiding users through a 5-phase process:

```
MAP & TARGET → SKETCH → DECIDE → PROTOTYPE → VALIDATE
```

It is designed for agent-facilitated execution (solo builder or small team) and sits between:
- `idea-refine` (idea expansion)
- `spec-driven-development` (formalized requirements)

Methodology lineage: GV Design Sprint (Jake Knapp), Google Design Sprint Kit, and AJ&Smart Sprint 2.0 compression patterns.

## When to Use

Use this skill when:
- The team is unsure what to build next
- A feature is expensive/risky and assumptions need validation first
- Stakeholders disagree on problem framing or solution direction
- You need a prototype-backed decision before committing to specs
- A project needs pre-spec alignment around a specific user/system moment

**When NOT to use:**
- Trivial fixes with obvious requirements
- Pure implementation work that already has validated specs
- Compliance/security audits (use `security-and-hardening`)
- Small bug fixes (use `debugging-and-error-recovery`)

## Adaptive Depth and Track Selection

Before Phase 1, detect and confirm:

1. **Track**
   - **Design Creative:** UX/product design-led outcomes
   - **Development Creative:** architecture/feasibility-led outcomes

2. **Depth**
   - **Quick Sprint (30-45 min):** directional decision, one key assumption
   - **Standard Sprint (2-4 hours):** full 5-phase sprint for most product work
   - **Deep Sprint (full day+):** major bets, multiple stakeholders, high uncertainty

Ask for confirmation before proceeding.

## Core Process

Use `nudges.md` as the facilitation prompt library. Adapt prompts to context; do not recite scripts mechanically.

### Phase 1: Map & Target

**Goal:** Establish shared context, define risk questions, and pick one high-leverage focus moment.

**Activities:**
1. Define the 2-year goal
2. Capture sprint questions (what could fail / what must be answered)
3. Run expert Q&A while capturing HMW notes during discussion
4. Build a map:
   - Design track: user journey map
   - Dev track: system/data flow map
5. Place/vote HMW opportunities on the map
6. Choose one target moment

**Gate:**
- “Here is the map, target moment, sprint questions, and top HMWs. Proceed?”

**Artifacts:**
- Map with highlighted target
- Ranked HMW opportunities
- Sprint question list (carried to Phase 5 scorecard)

### Phase 2: Sketch

**Goal:** Generate and refine solution options focused on the chosen target.

**Activities:**
1. Run inspiration scan (3-5 references: competitor, adjacent, analogous)
2. Diverge with Crazy 8s-style generation
3. Refine 1-2 strongest options into detailed concept narratives

Use `idea-refine` for divergent lenses and variation quality.

**Gate:**
- “Here are the strongest concept narratives for the target moment. Ready to evaluate?”

**Artifacts:**
- Design track: detailed interaction concept narratives
- Dev track: detailed interface/sequence concept narratives

### Phase 3: Decide

**Goal:** Converge on the best direction and produce a build-ready storyboard.

**Activities:**
1. Evaluate concept elements with **Sprint Participant Lenses** (from `nudges.md`):
   - The User (desirability)
   - The Builder (feasibility)
   - The Strategist (viability/differentiation)
   - The Skeptic (assumption/risk)
2. Extract “hot” elements (cross-lens positives)
3. Decide **Rumble or Combine**:
   - **Rumble:** test two competing directions
   - **Combine:** merge best elements into one direction
4. Decider call (user makes final choice)
5. Produce detailed storyboard (10-15 steps)

**Gate:**
- “This storyboard defines exactly what we will prototype and test. Proceed?”

**Artifacts:**
- Decision rationale
- Storyboard blueprint:
  - Design track: screen/interaction sequence
  - Dev track: request/response and integration sequence

### Phase 4: Prototype

**Goal:** Build a realistic-enough artifact to test core sprint questions.

**Activities:**
1. Build directly from storyboard
2. Maintain **Goldilocks quality** (credible but cheap)
3. Prepare test scenarios in parallel and map them to sprint questions

Use:
- Design track → `frontend-ui-engineering`
- Dev track → `api-and-interface-design`, `source-driven-development`

**Gate:**
- “Prototype and test scenarios are ready. Validate?”

**Artifacts:**
- Design track: lo-fi clickable flow/spec
- Dev track: thin vertical slice with contract-first boundaries
- Scenario set mapped to sprint questions

### Phase 5: Validate

**Goal:** Convert observations into explicit go-forward decisions.

**Activities:**
1. Run scenarios against prototype behavior
2. Score sprint questions using a simple matrix:
   - Green = validated
   - Yellow = partial
   - Red = invalidated
3. Identify patterns and surprises
4. Make explicit next-step decision:
   - **Iterate**
   - **Pivot**
   - **Ship**
   - **Kill**

**Gate:**
- Present conclusion and confirm decision.

**Artifacts:**
- Sprint scorecard
- Final recommendation with rationale
- Handoff notes:
  - `spec-driven-development` when shipping
  - Re-entry phase recommendation when iterating/pivoting

## Integration and Handoffs

- Use `planning-and-task-breakdown` after a Ship decision to decompose delivery work.
- Use `incremental-implementation` + `test-driven-development` during build execution.
- Record major direction choices with `documentation-and-adrs`.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| “We can skip mapping; we already know the problem.” | Without a map and target moment, ideation drifts and validation is noisy. |
| “Let’s jump straight to prototype.” | Prototyping before target selection optimizes the wrong thing faster. |
| “Dot-voting doesn’t work with one person.” | Use Sprint Participant Lenses to simulate multi-perspective evaluation. |
| “We don’t need sprint questions; we’ll know it when we see it.” | No sprint questions means no scoring criteria in Validate, and no decision confidence. |
| “Let’s keep all ideas alive until the end.” | Convergence is the point of a sprint. Force a Decider call to avoid ambiguity debt. |
| “Agent validation is enough; skip real users.” | Agent validation is a pre-flight check, not a replacement for real user feedback. |

## Red Flags

- No explicit target moment selected in Phase 1
- Sprint questions defined but never scored in Phase 5
- Sketch phase produces one idea only (no divergence)
- Decide phase picks whole concepts without element-level analysis
- Prototype quality is either overbuilt (wasteful) or too rough to test credibly
- Validate phase ends with observations but no iterate/pivot/ship/kill decision
- Team starts implementation without sprint artifacts and handoff notes

## Verification

Before closing a sprint, confirm:

- [ ] Track and depth were selected and confirmed
- [ ] Phase 1 produced map + target + sprint questions + ranked HMWs
- [ ] Phase 2 included inspiration scan and divergent generation
- [ ] Phase 3 used all four Sprint Participant Lenses
- [ ] Rumble vs Combine was explicitly resolved when multiple options were strong
- [ ] Phase 3 produced a detailed storyboard blueprint
- [ ] Phase 4 prototype and test scenarios are mapped to sprint questions
- [ ] Phase 5 includes a scored question matrix (green/yellow/red)
- [ ] Final decision is explicit: iterate/pivot/ship/kill
- [ ] Handoff path to follow-up skill is documented
