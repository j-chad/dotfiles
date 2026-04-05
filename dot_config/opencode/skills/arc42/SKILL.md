---
name: arc42
description: "Arc42 template reference. 12-section structure for architecture documentation, with C4 diagram mapping."
---

# Arc42 — Architecture Documentation Template

Arc42 is a 12-section template for structuring comprehensive architecture documentation. Not every section is needed for every project — use what's relevant, skip what isn't. Think of it as a cabinet with compartments: useful even if some are empty.

## Skills
- **c4** — C4 model reference. Mermaid syntax for architecture diagrams at four zoom levels plus Dynamic and Deployment diagrams. Load this skill when you need to draw architecture diagrams for the Context, Building Block, Runtime, or Deployment sections.
- **adr** — Architecture Decision Record reference. Template, format, and conventions. Load this skill when writing or managing decision records for the Architecture Decisions section.

## The 12 Sections

### 1. Introduction and Goals
Requirements overview, top 3-5 quality goals, key stakeholders and their expectations. The "why does this system exist" section.

**Include:** brief requirements summary, quality goals as a prioritised list, stakeholder table (role, name, expectations).

### 2. Constraints
Technical constraints (languages, platforms, mandated frameworks), organisational constraints (team structure, timelines, regulatory), conventions.

**Skip if:** there are no meaningful constraints worth documenting.

### 3. Context and Scope
The system boundary. Who and what interacts with the system from outside.

**Diagram:** C4 Level 1 (System Context). This section IS the context diagram plus prose explaining each external actor and system.

**Include:** business context (what users and partners see) and technical context (protocols, APIs, data formats).

### 4. Solution Strategy
Fundamental architectural decisions and approaches. Technology choices, decomposition approach, key patterns (event-driven, CQRS, monolith, microservices).

**Keep brief.** Details go in later sections. This is the 2-minute elevator pitch of the architecture.

### 5. Building Block View
The static decomposition of the system. This is where C4 shines:
- **Level 1** = C4 Container diagram (major deployable units)
- **Level 2** = C4 Component diagrams (inside a specific container)
- **Level 3+** = deeper decomposition if needed (rarely is)

For each building block: name, responsibility, interfaces.

**Use black box descriptions** at each level (what it does, not how). Use **white box descriptions** when zooming into a block at the next level.

**Recommendation:** stick to Level 1 for most projects. It gives enough guidance for most stakeholders.

### 6. Runtime View
How building blocks interact at runtime for key scenarios.

**Diagram:** sequence diagrams or C4 Dynamic diagrams.

**Pick 3-5 flows max:** the main happy path, error/retry handling, and any complex async flows. Don't try to document every interaction.

### 7. Deployment View
How the system maps to infrastructure.

**Diagram:** C4 Deployment diagram. Which services run where, network boundaries, cloud resources, scaling.

### 8. Crosscutting Concepts
Patterns and approaches that span the system rather than belonging to one component.

**Examples:** error handling strategy, logging/observability approach, authentication/authorisation model, persistence patterns, configuration management, internationalisation.

**These are often the most valuable parts** of architecture docs because they're the hardest to discover from code alone.

### 9. Architecture Decisions
Use **ADRs** (load the `adr` skill for the template). Link to them from this section or embed them directly.

This section answers "why is it built this way?"

### 10. Quality Requirements
Quality scenarios that make quality goals concrete and testable.

**Example:** "The API responds within 200ms at p99 under 1000 concurrent users."

Use a quality tree to organise by attribute (performance, security, reliability, maintainability).

### 11. Risks and Technical Debt
Known problems, risks, and tech debt. Be honest.

**Example:** "The ETL pipeline doesn't handle schema changes gracefully — this will break if BigQuery schemas are modified without coordinating with the reporting team."

This section builds trust and prevents surprises.

### 12. Glossary
Domain and technical terms the team uses. Especially important when terms are overloaded or domain-specific.

## Priority Guide

If time is limited, do these first:

| Priority | Section | Answers |
|---|---|---|
| **Must have** | 1. Introduction and Goals | Why does this exist? |
| **Must have** | 3. Context and Scope | What interacts with it? |
| **Must have** | 5. Building Block View | How is it structured? |
| **Must have** | 9. Architecture Decisions | Why was it built this way? |
| Should have | 4. Solution Strategy | What's the approach? |
| Should have | 6. Runtime View | How does it behave? |
| Should have | 8. Crosscutting Concepts | What patterns apply everywhere? |
| Should have | 11. Risks and Tech Debt | What could go wrong? |
| Nice to have | 2. Constraints | What limits us? |
| Nice to have | 7. Deployment View | What runs where? |
| Nice to have | 10. Quality Requirements | How good must it be? |
| Nice to have | 12. Glossary | What do we mean by X? |

## Section ↔ C4 Diagram Mapping

| Arc42 Section | C4 Diagram |
|---|---|
| 3. Context and Scope | C4 Context (Level 1) |
| 5. Building Block View (Level 1) | C4 Container (Level 2) |
| 5. Building Block View (Level 2) | C4 Component (Level 3) |
| 6. Runtime View | C4 Dynamic or sequence diagrams |
| 7. Deployment View | C4 Deployment |

## Guidelines

- **Pair every section with a diagram where possible.** Prose + diagram > prose alone.
- **Don't fill sections for the sake of completeness.** Empty section > filler section.
- **Keep it close to the code.** Store as markdown in the repo. Link to files using `file_path:line_number`. Docs in Confluence die in Confluence.
- **Review and update regularly.** Stale architecture docs are actively misleading.
