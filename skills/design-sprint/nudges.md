# Design Sprint Nudges

Use these prompts to facilitate the sprint conversation.

Principles:

- Adapt wording to user context and domain
- Ask one nudge at a time, then synthesize
- Keep momentum: nudge → decision → artifact update
- Prefer concrete examples over abstract language

## Depth Compression Guide

- **Quick:** Ask 1-2 nudges per subsection
- **Standard:** Ask 2-4 nudges per subsection
- **Deep:** Ask 4+ nudges, plus follow-ups for ambiguity and trade-offs

## Phase 1: Map & Target Nudges

### Long-term Goal

- "Two years from now, what outcome would make this effort unquestionably successful?"
- "What user behavior should be different if we succeed?"
- "What business or product metric should move the most?"

### Sprint Questions

- "What could cause this to fail even if we build it well?"
- "What must we learn this sprint to avoid a bad investment?"
- "Which assumption is most dangerous if wrong?"

### HMW Capture During Expert Q&A

- "How might we reduce friction at this specific step?"
- "How might we make the value obvious in the first minute?"
- "How might we preserve trust when something goes wrong?"

### Draw the Map

- "Walk me from first contact to first value, step by step."
- "Where do users stall, hesitate, or abandon the flow today?"
- "What system boundaries or dependencies are most brittle here?"

### Choose Target Moment

- "If we could only improve one moment, where is the highest leverage?"
- "Which moment is both high impact and testable this sprint?"
- "What happens immediately before and after this target moment?"

## Phase 2: Sketch Nudges

### Inspiration Scan

- "Show me 3-5 references we can learn from (competitor, adjacent, analogous)."
- "What patterns in these examples are worth borrowing?"
- "What should we avoid copying, and why?"

### Diverge (Crazy 8s-style)

- "Give me eight different concepts for the target moment — fast and rough."
- "Now force diversity: one minimal, one premium, one automation-first, one trust-first."
- "What is the 10x simpler version?"

### Refine (Solution Sketch)

- "Pick the two strongest concepts and flesh each into beginning → middle → end."
- "What is the key interaction at the center of each concept?"
- "What assumption does each concept rely on most?"

## Phase 3: Decide Nudges

### Element Extraction (Heat-Map Equivalent)

- "Across all concepts, which specific elements keep showing promise?"
- "Which elements are attractive but risky?"
- "Which element would survive even if its parent concept is dropped?"

### Rumble or Combine

- "Do we test two competing directions (rumble), or merge strongest elements (combine)?"
- "If we run a rumble, what is the one differentiator each version must prove?"
- "If we combine, what trade-offs are we accepting?"

### Storyboard Build

- "List the exact 10-15 steps the user/system will experience in test order."
- "Where are the make-or-break moments in this sequence?"
- "What evidence do we expect to collect at each critical step?"

## Sprint Participant Lens Prompts

Apply each lens to the same candidate element.

### The User (Desirability)

- "Does this reduce pain or increase clarity for the user right now?"
- "Would this feel trustworthy at first encounter?"
- "Where might confusion or friction remain?"

### The Builder (Feasibility)

- "Can this be built within sprint constraints?"
- "What existing components/contracts can we reuse?"
- "What is technically fragile or costly here?"

### The Strategist (Viability)

- "Does this align with the 2-year goal?"
- "How does this direction differentiate from current alternatives?"
- "Is the value proposition strong enough to justify investment?"

### The Skeptic (Risk)

- "What core assumption is this betting on?"
- "What failure mode appears first if that assumption is false?"
- "What would invalidate this idea quickly?"

### Lens Output Template

Use this structure for each high-signal element:

```markdown
Element: [name]
- User: [signal]
- Builder: [signal]
- Strategist: [signal]
- Skeptic: [signal]
- Heat: [hot | discuss | decider-call]
- Recommendation: [keep | modify | drop]
```

## Phase 4: Prototype Nudges

### Goldilocks Quality

- "What is the minimum fidelity needed to trigger realistic reactions?"
- "What can we intentionally fake without harming test validity?"
- "What over-polish should we avoid this sprint?"

### Scenario Preparation

- "Define 3-5 test scenarios directly tied to sprint questions."
- "For each scenario, what observable signal indicates success?"
- "What evidence would count as a clear red signal?"

## Phase 5: Validate Nudges

### Score Sprint Questions

- "For each sprint question, assign green/yellow/red with evidence."
- "Which evidence is strongest, and which is ambiguous?"
- "What changed our confidence most during testing?"

### Pattern Identification

- "Which issues repeated across scenarios?"
- "Which positive signals repeated across scenarios?"
- "What surprised us enough to challenge our assumptions?"

### Next-Step Decision

- "Given the scorecard, should we iterate, pivot, ship, or kill?"
- "What is the smallest next action that preserves momentum?"
- "What must be true before we move into spec and implementation?"

## Closing Prompt

- "I’ll summarize the sprint artifacts, scorecard, and recommendation now. Confirm and I’ll route to the right follow-up skill."
