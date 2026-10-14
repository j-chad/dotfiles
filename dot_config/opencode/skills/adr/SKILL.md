---
name: adr
description: "Architecture Decision Record reference. MADR 4.0 format with YAML frontmatter, template, and conventions."
---

# ADRs — Architecture Decision Records

ADRs capture the WHY behind architectural choices. Short, one-per-decision markdown files stored in the repo. This skill follows the MADR 4.0 format, which uses YAML frontmatter for machine-readable metadata.

## Location

Store ADRs in `docs/adr/` or `doc/architecture/decisions/`. Include an index file (`README.md`) listing all ADRs.

## Template

```markdown
---
status: accepted
date: 2025-03-15
decision-makers: Jackson, Peter
superseded-by: null
tags:
  - infrastructure
  - messaging
---

# Use Pub/Sub for Job Queue

## Context and Problem Statement

What situation prompted this decision? What forces are at play?
Be specific. Name the constraints, requirements, and tradeoffs.

## Considered Options

### Option A: [Name]
- Pros: ...
- Cons: ...

### Option B: [Name]
- Pros: ...
- Cons: ...

### Option C: [Name]
- Pros: ...
- Cons: ...

## Decision Outcome

Chosen option: "[Name]", because [justification].

### Consequences

What becomes easier. What becomes harder. What new constraints this creates.
Be honest about the tradeoffs.

## More Information

Links to relevant docs, discussions, PRs, or related ADRs.
```

## Frontmatter Fields

| Field | Required | Description |
|---|---|---|
| `status` | Yes | `proposed`, `accepted`, `deprecated`, or `superseded` |
| `date` | Yes | Date the decision was made or proposed. `YYYY-MM-DD` |
| `decision-makers` | No | Who was involved in making this decision |
| `superseded-by` | No | Filename of the ADR that replaces this one. `null` if active |
| `tags` | No | Categories for filtering/grouping. Keep to 1-3 tags |

## Minimal Template

For small or obvious decisions that don't need the full format:

```markdown
---
status: accepted
date: 2025-04-01
---

# Use Redis for Report Caching

## Context and Problem Statement

Report queries take 5-15 seconds. Users hit the same reports repeatedly.
Need a caching layer that supports TTL and key-based invalidation.

## Decision Outcome

Chosen option: Redis via GCP Memorystore, because it's managed,
the team already knows Redis, and it supports TTL natively.

### Consequences

- Good: report latency drops to <100ms for cached results.
- Bad: adds a new infrastructure dependency.
- Neutral: cache invalidation on data refresh needs to be implemented.
```

## Index File Template

```markdown
# Architecture Decision Records

| # | Title | Status | Date | Tags |
|---|-------|--------|------|------|
| [001](./001-use-pubsub-for-job-queue.md) | Use Pub/Sub for job queue | accepted | 2025-03-15 | infrastructure, messaging |
| [002](./002-bigquery-over-snowflake.md) | BigQuery over Snowflake | accepted | 2025-04-02 | data, warehouse |
| [003](./003-redis-for-report-caching.md) | Redis for report caching | superseded | 2025-04-10 | infrastructure, caching |
| [005](./005-memcached-for-report-caching.md) | Memcached for report caching | accepted | 2025-06-01 | infrastructure, caching |
```

## Conventions

**One decision per ADR.** "We chose PostgreSQL" and "we chose Go" are separate ADRs with separate reasoning.

**Write at decision time.** Not after the fact. Context is freshest when the decision is being made. Reconstructing reasoning months later is unreliable.

**Never delete ADRs.** If a decision is reversed, set `status: superseded` and `superseded-by: NNN-new-decision.md` in the frontmatter. Write a new ADR. The history of why things changed is as valuable as the current state.

**Keep them short.** A good ADR is one page. If you need more, the decision might need to be decomposed.

**Number sequentially.** `001`, `002`, etc. Zero-padded three digits so they sort correctly.

**File naming.** `NNN-short-descriptive-title.md`. Example: `001-use-pubsub-for-job-queue.md`.

## Status Lifecycle

```
proposed → accepted → (optionally) deprecated or superseded
```

- **proposed** — under discussion, not yet decided.
- **accepted** — decided and in effect.
- **deprecated** — no longer relevant (e.g., the feature was removed).
- **superseded** — replaced by a newer decision. Always set `superseded-by` in frontmatter.

## What Makes a Good ADR

- **Context is specific.** Not "we needed a database" but "we needed a relational store that supports JSON columns, handles 10K writes/sec, and is managed on GCP."
- **Options are real.** Document options that were genuinely considered, not strawmen. Include at least two.
- **Decision explains the reasoning.** Not just "we chose X" but "we chose X because [specific reasons], despite [acknowledged tradeoffs]."
- **Consequences are honest.** Every decision has downsides. If you can't name any, you haven't thought hard enough. Use Good/Bad/Neutral as a simple framework.
- **Tags are useful.** Tag by area (infrastructure, data, auth, api) so ADRs can be filtered. Don't over-tag.

## When to Write an ADR

Write an ADR when:
- Choosing a technology, framework, or service
- Deciding on an architectural pattern or approach
- Changing an existing architectural decision
- Making a tradeoff that future developers will need to understand
- The decision would be non-obvious to someone joining the team

Don't write an ADR for:
- Trivial choices (which linter config to use)
- Decisions imposed by constraints with no alternatives
- Temporary workarounds (use code comments instead)
