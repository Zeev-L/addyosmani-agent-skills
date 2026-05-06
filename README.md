# Agent Skills

**Production-grade engineering skills for AI coding agents.**

Skills encode the workflows, quality gates, and best practices that senior engineers use when building software. These ones are packaged so AI agents follow them consistently across every phase of development.

```
  DEFINE          PLAN           BUILD          VERIFY         REVIEW          SHIP
 ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐
 │ Idea │ ───▶ │ Spec │ ───▶ │ Code │ ───▶ │ Test │ ───▶ │  QA  │ ───▶ │  Go  │
 │Refine│      │  PRD │      │ Impl │      │Debug │      │ Gate │      │ Live │
 └──────┘      └──────┘      └──────┘      └──────┘      └──────┘      └──────┘
  /spec          /plan          /build        /test         /review       /ship
```

---

## Commands

7 slash commands that map to the development lifecycle. Each one activates the right skills automatically.

| What you're doing | Command | Key principle |
|-------------------|---------|---------------|
| Define what to build | `/spec` | Spec before code |
| Plan how to build it | `/plan` | Small, atomic tasks |
| Build incrementally | `/build` | One slice at a time |
| Prove it works | `/test` | Tests are proof |
| Review before merge | `/review` | Improve code health |
| Simplify the code | `/code-simplify` | Clarity over cleverness |
| Ship to production | `/ship` | Faster is safer |

Skills also activate automatically based on what you're doing — designing an API triggers `api-and-interface-design`, building UI triggers `frontend-ui-engineering`, and so on.

---

## Quick Start

<details>
<summary><b>Claude Code (recommended)</b></summary>

**Marketplace install:**

```
/plugin marketplace add addyosmani/agent-skills
/plugin install agent-skills@addy-agent-skills
```

> **SSH errors?** The marketplace clones repos via SSH. If you don't have SSH keys set up on GitHub, either [add your SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) or use the full HTTPS URL to force the HTTPS cloning:
> ```bash
> /plugin marketplace add https://github.com/addyosmani/agent-skills.git
> /plugin install agent-skills@addy-agent-skills
> ```

**Local / development:**

```bash
git clone https://github.com/addyosmani/agent-skills.git
claude --plugin-dir /path/to/agent-skills
```

</details>

<details>
<summary><b>Cursor</b></summary>

Copy any `SKILL.md` into `.cursor/rules/`, or reference the full `skills/` directory. See [docs/cursor-setup.md](docs/cursor-setup.md).

</details>

<details>
<summary><b>Gemini CLI</b></summary>

Install as native skills for auto-discovery, or add to `GEMINI.md` for persistent context. See [docs/gemini-cli-setup.md](docs/gemini-cli-setup.md).

**Install from the repo:**

```bash
gemini skills install https://github.com/addyosmani/agent-skills.git --path skills
```

**Install from a local clone:**

```bash
gemini skills install ./agent-skills/skills/
```

</details>

<details>
<summary><b>Windsurf</b></summary>

Add skill contents to your Windsurf rules configuration. See [docs/windsurf-setup.md](docs/windsurf-setup.md).

</details>

<details>
<summary><b>OpenCode</b></summary>

Uses agent-driven skill execution via AGENTS.md and the `skill` tool.

See [docs/opencode-setup.md](docs/opencode-setup.md).

</details>

<details>
<summary><b>GitHub Copilot</b></summary>

Use agent definitions from `agents/` as Copilot personas and skill content in `.github/copilot-instructions.md`. See [docs/copilot-setup.md](docs/copilot-setup.md).

</details>

<details>
  <summary><b>Kiro IDE & CLI </b></summary>
  Skills for Kiro reside under ".kiro/skills/" and can be stored under Project or Global level. Kiro also supports Agents.md. See Kiro docs at https://kiro.dev/docs/skills/
</details>

<details>
<summary><b>Codex / Other Agents</b></summary>

Skills are plain Markdown - they work with any agent that accepts system prompts or instruction files. See [docs/getting-started.md](docs/getting-started.md).

</details>



---

## All 20 Skills

The commands above are the entry points. Under the hood, they activate these 20 skills — each one a structured workflow with steps, verification gates, and anti-rationalization tables. You can also reference any skill directly.

### Define - Clarify what to build

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [idea-refine](skills/idea-refine/SKILL.md) | Structured divergent/convergent thinking to turn vague ideas into concrete proposals | You have a rough concept that needs exploration |
| [spec-driven-development](skills/spec-driven-development/SKILL.md) | Write a PRD covering objectives, commands, structure, code style, testing, and boundaries before any code | Starting a new project, feature, or significant change |

### Plan - Break it down

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [planning-and-task-breakdown](skills/planning-and-task-breakdown/SKILL.md) | Decompose specs into small, verifiable tasks with acceptance criteria and dependency ordering | You have a spec and need implementable units |

### Build - Write the code

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [incremental-implementation](skills/incremental-implementation/SKILL.md) | Thin vertical slices - implement, test, verify, commit. Feature flags, safe defaults, rollback-friendly changes | Any change touching more than one file |
| [test-driven-development](skills/test-driven-development/SKILL.md) | Red-Green-Refactor, test pyramid (80/15/5), test sizes, DAMP over DRY, Beyonce Rule, browser testing | Implementing logic, fixing bugs, or changing behavior |
| [context-engineering](skills/context-engineering/SKILL.md) | Feed agents the right information at the right time - rules files, context packing, MCP integrations | Starting a session, switching tasks, or when output quality drops |
| [source-driven-development](skills/source-driven-development/SKILL.md) | Ground every framework decision in official documentation - verify, cite sources, flag what's unverified | You want authoritative, source-cited code for any framework or library |
| [frontend-ui-engineering](skills/frontend-ui-engineering/SKILL.md) | Component architecture, design systems, state management, responsive design, WCAG 2.1 AA accessibility | Building or modifying user-facing interfaces |
| [api-and-interface-design](skills/api-and-interface-design/SKILL.md) | Contract-first design, Hyrum's Law, One-Version Rule, error semantics, boundary validation | Designing APIs, module boundaries, or public interfaces |

### Verify - Prove it works

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [browser-testing-with-devtools](skills/browser-testing-with-devtools/SKILL.md) | Chrome DevTools MCP for live runtime data - DOM inspection, console logs, network traces, performance profiling | Building or debugging anything that runs in a browser |
| [debugging-and-error-recovery](skills/debugging-and-error-recovery/SKILL.md) | Five-step triage: reproduce, localize, reduce, fix, guard. Stop-the-line rule, safe fallbacks | Tests fail, builds break, or behavior is unexpected |

### Review - Quality gates before merge

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [code-review-and-quality](skills/code-review-and-quality/SKILL.md) | Five-axis review, change sizing (~100 lines), severity labels (Nit/Optional/FYI), review speed norms, splitting strategies | Before merging any change |
| [code-simplification](skills/code-simplification/SKILL.md) | Chesterton's Fence, Rule of 500, reduce complexity while preserving exact behavior | Code works but is harder to read or maintain than it should be |
| [security-and-hardening](skills/security-and-hardening/SKILL.md) | OWASP Top 10 prevention, auth patterns, secrets management, dependency auditing, three-tier boundary system | Handling user input, auth, data storage, or external integrations |
| [performance-optimization](skills/performance-optimization/SKILL.md) | Measure-first approach - Core Web Vitals targets, profiling workflows, bundle analysis, anti-pattern detection | Performance requirements exist or you suspect regressions |

### Ship - Deploy with confidence

| Skill | What It Does | Use When |
|-------|-------------|----------|
| [git-workflow-and-versioning](skills/git-workflow-and-versioning/SKILL.md) | Trunk-based development, atomic commits, change sizing (~100 lines), the commit-as-save-point pattern | Making any code change (always) |
| [ci-cd-and-automation](skills/ci-cd-and-automation/SKILL.md) | Shift Left, Faster is Safer, feature flags, quality gate pipelines, failure feedback loops | Setting up or modifying build and deploy pipelines |
| [deprecation-and-migration](skills/deprecation-and-migration/SKILL.md) | Code-as-liability mindset, compulsory vs advisory deprecation, migration patterns, zombie code removal | Removing old systems, migrating users, or sunsetting features |
| [documentation-and-adrs](skills/documentation-and-adrs/SKILL.md) | Architecture Decision Records, API docs, inline documentation standards - document the *why* | Making architectural decisions, changing APIs, or shipping features |
| [shipping-and-launch](skills/shipping-and-launch/SKILL.md) | Pre-launch checklists, feature flag lifecycle, staged rollouts, rollback procedures, monitoring setup | Preparing to deploy to production |

---

## Agent Personas

Pre-configured specialist personas for targeted reviews:

| Agent | Role | Perspective |
|-------|------|-------------|
| [code-reviewer](agents/code-reviewer.md) | Senior Staff Engineer | Five-axis code review with "would a staff engineer approve this?" standard |
| [test-engineer](agents/test-engineer.md) | QA Specialist | Test strategy, coverage analysis, and the Prove-It pattern |
| [security-auditor](agents/security-auditor.md) | Security Engineer | Vulnerability detection, threat modeling, OWASP assessment |

---

## Reference Checklists

Quick-reference material that skills pull in when needed:

| Reference | Covers |
|-----------|--------|
| [testing-patterns.md](references/testing-patterns.md) | Test structure, naming, mocking, React/API/E2E examples, anti-patterns |
| [security-checklist.md](references/security-checklist.md) | Pre-commit checks, auth, input validation, headers, CORS, OWASP Top 10 |
| [performance-checklist.md](references/performance-checklist.md) | Core Web Vitals targets, frontend/backend checklists, measurement commands |
| [accessibility-checklist.md](references/accessibility-checklist.md) | Keyboard nav, screen readers, visual design, ARIA, testing tools |

---

## How Skills Work

Every skill follows a consistent anatomy:

```
┌─────────────────────────────────────────────────┐
│  SKILL.md                                       │
│                                                 │
│  ┌─ Frontmatter ─────────────────────────────┐  │
│  │ name: lowercase-hyphen-name               │  │
│  │ description: Guides agents through [task].│  │
│  │              Use when…                    │  │
│  └───────────────────────────────────────────┘  │                                                                                                
│  Overview         → What this skill does        │
│  When to Use      → Triggering conditions       │
│  Process          → Step-by-step workflow       │
│  Rationalizations → Excuses + rebuttals         │
│  Red Flags        → Signs something's wrong     │
│  Verification     → Evidence requirements       │
└─────────────────────────────────────────────────┘
```

**Key design choices:**

- **Process, not prose.** Skills are workflows agents follow, not reference docs they read. Each has steps, checkpoints, and exit criteria.
- **Anti-rationalization.** Every skill includes a table of common excuses agents use to skip steps (e.g., "I'll add tests later") with documented counter-arguments.
- **Verification is non-negotiable.** Every skill ends with evidence requirements - tests passing, build output, runtime data. "Seems right" is never sufficient.
- **Progressive disclosure.** The `SKILL.md` is the entry point. Supporting references load only when needed, keeping token usage minimal.

---

## Project Structure

```
agent-skills/
├── skills/                            # 20 core skills (SKILL.md per directory)
│   ├── idea-refine/                   #   Define
│   ├── spec-driven-development/       #   Define
│   ├── planning-and-task-breakdown/   #   Plan
│   ├── incremental-implementation/    #   Build
│   ├── context-engineering/           #   Build
│   ├── source-driven-development/     #   Build
│   ├── frontend-ui-engineering/       #   Build
│   ├── test-driven-development/       #   Build
│   ├── api-and-interface-design/      #   Build
│   ├── browser-testing-with-devtools/ #   Verify
│   ├── debugging-and-error-recovery/  #   Verify
│   ├── code-review-and-quality/       #   Review
│   ├── code-simplification/          #   Review
│   ├── security-and-hardening/        #   Review
│   ├── performance-optimization/      #   Review
│   ├── git-workflow-and-versioning/   #   Ship
│   ├── ci-cd-and-automation/          #   Ship
│   ├── deprecation-and-migration/     #   Ship
│   ├── documentation-and-adrs/        #   Ship
│   ├── shipping-and-launch/           #   Ship
│   └── using-agent-skills/            #   Meta: how to use this pack
├── agents/                            # 3 specialist personas
├── references/                        # 4 supplementary checklists
├── hooks/                             # Session lifecycle hooks
├── .claude/commands/                  # 7 slash commands (Claude Code)
├── .gemini/commands/                  # 7 slash commands (Gemini CLI)
└── docs/                              # Setup guides per tool
```

---

## Why Agent Skills?

AI coding agents default to the shortest path - which often means skipping specs, tests, security reviews, and the practices that make software reliable. Agent Skills gives agents structured workflows that enforce the same discipline senior engineers bring to production code.

Each skill encodes hard-won engineering judgment: *when* to write a spec, *what* to test, *how* to review, and *when* to ship. These aren't generic prompts - they're the kind of opinionated, process-driven workflows that separate production-quality work from prototype-quality work.

Skills bake in best practices from Google's engineering culture — including concepts from [Software Engineering at Google](https://abseil.io/resources/swe-book) and Google's [engineering practices guide](https://google.github.io/eng-practices/). You'll find Hyrum's Law in API design, the Beyonce Rule and test pyramid in testing, change sizing and review speed norms in code review, Chesterton's Fence in simplification, trunk-based development in git workflow, Shift Left and feature flags in CI/CD, and a dedicated deprecation skill treating code as a liability. These aren't abstract principles — they're embedded directly into the step-by-step workflows agents follow.

---


How to reduce AI errors

AI tools despite being so advanced still sometimes make mistakes in the same ways over and over.

Here's how we can try to solve them.

The problem!

When you use an AI tool, a few things can go wrong:

The AI just assumes what you mean without asking

It gives you a complicated answer when a simple one would suffice

It edits things you didn't ask it to edit

It sounds confident even when it's wrong

It never actually checks if its answer worked

These rules are basically trying to fix all of that.

Rule 1: Understand the question before answering it

This is the big one.

AI tools have a habit of just jumping straight into an answer without fully understanding what was asked. And then you get something that's technically an answer but not really what you needed.

The fix is simple — before doing anything, just stop and ask:

What is actually being asked here?

Are you making any assumptions? What are they?

Is there more than one way to read this question?

If something isn't clear, say so. Ask. Don't just guess and run with it.

A good AI should ask a clarifying question before writing a 500-word answer that misses the point entirely.

Rule 2: Simple answers are usually better answers

There's this temptation — in AI and in people — to over-explain. To add more, make it sound more impressive, cover every possible case.

But most of the time, the person asking just wants a clear, direct answer.

The rule is to give the most straightforward answer that actually solves the problem. Don't add stuff "just in case." Don't make it any fancier than it needs to be.

If you can write something in three lines, don't write three paragraphs.

Rule 3: Only change what you were asked to change

When you ask an AI to fix one thing, it sometimes starts "enhancing" a bunch of other stuff around it that you didn't ask about.

The rule is: Edit only what you need to touch and nothing else.

If you ask someone to fix spelling in your essay, you don't want them rewriting your whole introduction. Every change should have a clear reason. If there's insufficient reason, don't make the change.

Rule 4: Decide what "good enough" looks like before you start

This is something most people skip, and it causes so many problems.

If you don't define what a good result looks like before you start, how do you know when you're done? You just kind of... guess. And that leads to going back and forth forever.

So before starting anything, answer this one question: how will I know this worked?

For example:

If you're fixing a bug in something — what does "fixed" actually look like?

If you're writing something — what should the reader walk away knowing.

Rule 5: Check if it worked —really check without assuming

This is the one that gets skipped the most.

After finishing something, most people (and most AI tools) just say "done!" and move on. But did it actually work? Was the answer right? Did it solve the real problem?

Go back and check. Look at it fresh. Test it if you can. Ask yourself if someone reading it for the first time would actually get it.

If it works but feels messy — clean it up. Messy answers cause confusion later even if they technically work right now.

"I think this is right" is not the same as "I checked and this is right."

This matters because while AI tools are powerful, but they have a few weak spots.

They answer too quickly without asking enough questions.

They sound confident even if they're wrong.

They don't verify things automatically.

Summary of questions to be given to AI:

Before doing anything -- do I actually understand what's being asked?

When giving an answer - is this as simple as it can be?

When making changes - am I only touching what I need to?

Before starting --------- what does "completed" actually look like?

After finishing ---------- did AI really check, or is the AI just assuming?

So you have to give all this whatever AI you use like Gemini or ChatGPT or Grok or Claude or Meta AI and then the model will learn to avoid errors.

USE WITH CAUTION! I AM NOT RESPONSIBLE FOR ANY UNTOWARD INCIDENTS AND THIS IS PURELY SUGGESTIVE WITH NO COERCION INVOLVED.


Prompt Engineering

The Almost Perfect Prompt Engineering Rules
Almost Perfect Prompt Engineering Rules
RULE 1: Be specific. Like, really specific.

Vague prompt leads to vague output almost every time

bad: write an email for me.

good: Write a follow up email to a client who hasn't responded in 5 days.

tone: professional but not too stiff. maximum 100 words.

RULE 2: Tell it WHO to be, not just WHAT to do

giving the model a role changes output quality significantly.

For e.g. "You are a senior backend engineer at a startup".

Review this code and point out anything that is or can be bad for you.

Just saying "review my code" leads to completely different output.

RULE 3: Show, don't just tell: if you want a specific FORMAT actually show an example. don't just describe it.

RULE 4: Ask it to think step by step(reason)

sounds stupid, but it works significantly well.

Just add: think step by step before replying

Or: before giving your final reply, reason through this carefully

This is recommended for math/logic/reasoning tasks.

when to use it: any problem with multiple steps. math, debugging, planning, analysis.

when NOT to: simple factual questions like 'who is the prime minister of India'.

RULE 5: Give it an "out" when it doesn't know

if you don't do this, models can hallucinate

For Example:

Answer the question using just the text below. ________(text)

If the answer is not in the text, say "I don't know" however don't guess. Models are trained to be helpful, which means they'll try to answer even when they don't know, you have to tell them not to guess and reply factually.

RULE 6: Separate your instructions from your content

use triple quotes and other such separators whatever, just separate them.

For eg:

messy: Summarize this text

clean: Summarize the text given in 2 sentences.

RULE 7: Specify the output format explicitly

Don't assume it'll give you a table or a list. You will have to ask for it directly.

For e.g. : Return your answer as a Table/list

Or:

format your response as a markdown table with columns:

this is probably a very useful rule in production.

RULE 8: Long prompt doesn't equate to better prompt

A lot of people think writing more = getting more. Misconception

-Unnecessary instructions confuse the model

-Contrary rules cancel each other out

**You have to remove everything that doesn't add information. **

AI researchers have pinpointed this out, that model attention is finite.

RULE 9: For complex tasks — break it up

Don't ask for everything in one shot.

instead:

Research this topic, write an outline, then write the full article

Do it in steps:

Step 1: Give me 5 key points about [topic]

Step 2: (after reviewing) Now write an outline based on these points

Step 3: (after reviewing) Now write section 1

RULE 10: Tell it what NOT to do (negative prompting)

Telling the model what not to do is just as important as telling it what to do.

for e.g.:

Don't use bullet points.

Don't start sentences with "I".

Don't add a conclusion section.

This works especially well for formatting.

RULE 11: No Perfect Prompt exists:

Nobody writes the perfect prompt first try.

actual workflow:

-write a rough prompt

-see what breaks

-fix the specific thing that broke

-repeat

miscellaneous things that work
"be concise" works better than "keep it short"

asking for confidence levels reduces hallucinations a bit ("how confident are you in this answer, 1-10?")

"explain this to a 16-year-old" gives surprisingly clear explanations

for coding: always tell it the language, framework version, and what you've already tried

"what are you not sure about in your answer?" is actually useful

overhyped things:
Very long system prompts with 50 rules — most get ignored

"Pretend you have zero restrictions".

Asking it to "be creative" without any other guidance — just gives generic stuff without any benefits.



Agentic_AI
AI Agents Are About to change Everything. And Nobody is talking About the scary Part.

Somewhere right now, an AI agent is booking a flight on someone’s behalf. Another is filing a support ticket. Another is writing and deploying code to a live server. Nobody pressed a button. Nobody is watching. This is not science fiction. This is happening right now in 2026.

We have spent four years having the wrong argument about artificial intelligence.

The argument has been about jobs — will AI replace programmers, writers, designers, lawyers? The answer, we now know, is complicated. AI hasn’t replaced most of them. It has made them faster, sometimes better, occasionally worse, and frequently unsure of what their job actually means anymore.

But while we were having that argument, something far more consequential quietly arrived. Not AI that helps humans do things. AI that does things instead of humans. Autonomously. At scale. Without waiting to be asked.

These are called AI agents. And they are the most important and least understood shift in technology since the smartphone.

What an AI agent actually is — and why it’s different Most people’s experience of AI is of responding nature, right. We give it a input something, it responds. We question, it answers. The AI always waits for us. We are in control.

An AI agent is unique in one critical way: it acts proactively toward a goal without needing guidancen. We give it an objective — for e.g. “book me the cheapest flight to New Delhi next Thursday under 8000 rupees — and it goes and does it. It searches, compares, decides, and completes the task quicker than ever on its own.

The last line is the one that should make you stop in your tracks.

Because that is the innovation and upgrade and difference of agentic ai.

The shift that changes, well almost everything To understand why agents are different from every previous wave of software, you need to understand one concept: the difference between a tool and an actor/doer.

Every piece of software ever built before AI agents was just a tool. Tools do only what you tell them. A hammer drives the nail where you place it. Excel calculates the formula that you enter. Even early AIs — the chatbots, the image generators — were reactive. Just a tool waiting to be picked up.

An AI agent is an actor/doer. It has a goal and it will do it. It has the ability to reason (that is unique) about how to reach that goal. Agentic AI can use other tools — browsers, APIs, code editors, email clients, databases — to pursue that goal. And critically, it does not stop and ask for permission at every single step. This is the X-factor that makes them truly different.

Difference between AI and Agentic Ai

This is not just an incremental improvement. This is a mega shift. And it is happening right now, quicker than most people realize, with very little public discussion about what it actually means.

The 3 things nobody is saying loudly enough The technology press covers AI agents as a productivity hack. More done, quicker, cheaper. All very true. But there are three other stories embedded in this shift that are getting probably negligible attention.

Agents make “mistakes” at the speed of automation People also make mistakes. The difference between AI mistakes and human is speed and scale.
When a human employee makes an error for e.g. — sends a wrong email, books the wrong flight, misreads a contract — it happens once, at human speed, and is usually caught before catastrophic damage happens. When an AI agent makes an error, it can possibly repeat that error thousands of times before anyone notices, because it never gets tired and never second-guesses itself (never stops).

The problem is not that AI agents are careless its actually the opposite. It’s that they can possibly be relentlessly competent at the wrong thing. They usually have no intuition for the unmeasurable things that actually matter. The relationships. The exception that required human judgment. The thing that was a duplicate but shouldn’t have been deleted.

“We taught AI to be productive. We forgot that sometimes inefficiency can be a kindness in disguise.”

Accountability is quietly being removed Here is a question that sounds simple but is genuinely unresolved: when an AI agent makes a decision that harms someone, who is responsible (Teslas black box problem)? The developer who built the agent or the company that deployed the agent or the user who set the goal or the model that generated the reasoning.
And this gap between rules and widespread deployment of AI agents in critical sectors of the world is even more acute in developing countries, where legislation if present is not enforced properly.

This is not a hypothetical future scenario. It’s a gap that exists right now, today, as agents send emails on behalf of companies, make hiring recommendations, flag insurance claims for denial, and route patients to treatment pathways. In every one of these cases, a human used to make the decision and could and can be held accountable. In many of them, an agent now makes it, and accountability has reduced.

The agent economy will concentrate power in never seen before In the current economy, size matters but it is not infinitely scalable. A law firm of 50 people can outcompete a sole practitioner — but still it cannot do the work of 5,000 people simultaneously, because you cannot hire and manage 5,000 lawyers.
In an agent economy, you can. One company with excellent AI agents and good infrastructure can deploy the equivalent of thousands of workers simultaneously, at a fraction of the cost, without HR, without training, without turnover. The advantages of scale become nearly limitless.

This does not mean human workers disappear overnight. It means the economic advantage of being large — of being a tech giant with resources to build and deploy agents — becomes so overwhelming that competition from smaller players becomes nearly impossible in many sectors.

This will mean that startups the poster boys/girls of innovation shall be doomed on the onset if we take the pessimistic view. While once upon a time a young Apple disrupted Nokia there is now a chance that large cap companies with money will invest more in AI and will reap the benefits of it.

So what do we have to do? I want to be clear: I am not saying that AI agents are bad. They are truly extraordinary. The ability to give complex multi-step tasks to an intelligent system is going to save millions of hours of human work, reduce errors in mechanical processes.

But extraordinary technology deployed without adequate thought about its possible failures is how we end up with problems that take decades to fix. And right now, we are in a critical window — agents are real and being deployed, but the legislation, laws, and oversight systems for them barely exist.

The question really worth asking Every major technology innovation in history — electricity, the internet, the smartphone — came just with a scenario like this. A time period where the technology existed, the applications were clear, the excitement was real, and the rules and laws hadn’t been written yet. What laws got passed changed everything that followed.

AI agents are that time period, currently. The decisions being made today — by coders, companies, policymakers, and actually by all of us in how we demand accountability from the systems we use — will determine whether this technology becomes one of the most empowering forces in human history, or one of the most destabilizing.

One version of this story is utopian on paper: AI agents that handle the mechanical so humans can focus on the meaningful. AI Agents that extend and enhance human capability rather than replacing human judgment entirely. Technology that makes the resources of a large company available to a single innovator with a good idea.

That version is possible with the right legislation

“Let’s hope that I am just being pessimistic and thinking about this more than I probably should.”



## Contributing

Skills should be **specific** (actionable steps, not vague advice), **verifiable** (clear exit criteria with evidence requirements), **battle-tested** (based on real workflows), and **minimal** (only what's needed to guide the agent).

See [docs/skill-anatomy.md](docs/skill-anatomy.md) for the format specification and [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT - use these skills in your projects, teams, and tools.
