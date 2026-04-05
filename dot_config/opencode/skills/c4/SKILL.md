---
name: c4
description: "C4 model reference. Mermaid syntax for architecture diagrams at four zoom levels plus Dynamic and Deployment diagrams."
---

# C4 Model — Mermaid Reference

The C4 model gives you four zoom levels for architecture diagrams, plus Dynamic and Deployment diagram types.

## The Four Levels

### Level 1 — System Context (C4Context)

The highest zoom level. Your system as a single box, surrounded by users and external systems. Every stakeholder should understand this diagram.

**Use when:** introducing the system, README overviews, showing how the system fits into the landscape.

```mermaid
C4Context
    title System Context — Reporting Platform

    Person(analyst, "Data Analyst", "Queries reports and dashboards")
    System(reporting, "Reporting Platform", "Generates and serves business reports")
    System_Ext(bigquery, "BigQuery", "Data warehouse")
    System_Ext(slack, "Slack", "Notification delivery")

    Rel(analyst, reporting, "Views reports")
    Rel(reporting, bigquery, "Queries data", "SQL")
    Rel(reporting, slack, "Sends alerts", "Webhook")
```

### Level 2 — Container Diagram (C4Container)

Zoom into your system. Shows deployable units — services, apps, databases, queues. Each container is separately runnable/deployable.

**Use when:** showing internal architecture, explaining service communication, onboarding engineers.

```mermaid
C4Container
    title Container Diagram — Reporting Platform

    Person(analyst, "Data Analyst")

    System_Boundary(reporting, "Reporting Platform") {
        Container(api, "Report API", "Go", "Serves report data via REST")
        Container(worker, "ETL Worker", "Go", "Transforms and loads data")
        ContainerDb(cache, "Redis Cache", "Redis", "Caches frequent queries")
        ContainerDb(meta, "Metadata DB", "PostgreSQL", "Stores report definitions")
        ContainerQueue(queue, "Job Queue", "Pub/Sub", "Distributes ETL tasks")
    }

    System_Ext(bigquery, "BigQuery")

    Rel(analyst, api, "Requests reports", "HTTPS")
    Rel(api, cache, "Reads cached results")
    Rel(api, meta, "Reads report definitions")
    Rel(api, queue, "Enqueues refresh jobs")
    Rel(queue, worker, "Delivers jobs")
    Rel(worker, bigquery, "Queries data", "BigQuery Storage API")
    Rel(worker, cache, "Writes results")
```

### Level 3 — Component Diagram (C4Component)

Zoom into a single container. Shows major structural blocks inside — packages, modules, key interfaces.

**Use when:** explaining internals of a specific service, documenting a complex module.

```mermaid
C4Component
    title Component Diagram — Report API

    Container_Boundary(api, "Report API") {
        Component(router, "HTTP Router", "chi", "Routes requests to handlers")
        Component(handlers, "Report Handlers", "Go", "Validates requests, returns responses")
        Component(service, "Report Service", "Go", "Business logic for report generation")
        Component(repo, "Report Repository", "Go", "Data access layer")
    }

    ContainerDb(cache, "Redis Cache")
    ContainerDb(meta, "Metadata DB")

    Rel(router, handlers, "Dispatches to")
    Rel(handlers, service, "Calls")
    Rel(service, repo, "Reads/writes via")
    Rel(repo, cache, "Reads cached results")
    Rel(repo, meta, "Queries definitions")
```

### Level 4 — Code

Class-level diagrams. Usually auto-generated. Rarely worth writing by hand. Only create for particularly complex or non-obvious internal structures. Use standard Mermaid `classDiagram` syntax if needed.

## Additional Diagram Types

### Dynamic Diagram (C4Dynamic)

Shows the flow of a specific request or operation, numbered and sequenced. Use instead of sequence diagrams when you want flow overlaid on architecture.

```mermaid
C4Dynamic
    title Report Generation Flow

    Person(analyst, "Data Analyst")
    Container(api, "Report API", "Go")
    ContainerDb(cache, "Redis Cache")
    Container(worker, "ETL Worker", "Go")
    ContainerQueue(queue, "Job Queue", "Pub/Sub")
    System_Ext(bigquery, "BigQuery")

    Rel(analyst, api, "1. Requests report")
    Rel(api, cache, "2. Checks cache")
    Rel(api, queue, "3. Enqueues refresh job")
    Rel(queue, worker, "4. Delivers job")
    Rel(worker, bigquery, "5. Queries data")
    Rel(worker, cache, "6. Writes result")
    Rel(api, analyst, "7. Returns report")
```

### Deployment Diagram (C4Deployment)

Shows how containers map to infrastructure. Servers, clusters, cloud regions.

```mermaid
C4Deployment
    title Deployment — Reporting Platform

    Deployment_Node(gcp, "Google Cloud Platform") {
        Deployment_Node(gke, "GKE Cluster", "Kubernetes") {
            Container(api, "Report API", "Go")
            Container(worker, "ETL Worker", "Go")
        }
        Deployment_Node(managed, "Managed Services") {
            ContainerDb(cache, "Redis", "Memorystore")
            ContainerDb(meta, "Metadata DB", "Cloud SQL")
        }
    }

    Rel(api, cache, "Reads/writes")
    Rel(worker, cache, "Writes results")
    Rel(api, meta, "Reads definitions")
```

## Syntax Reference

### Elements

| Element | Syntax | Use for |
|---|---|---|
| Person | `Person(alias, "Label", "Description")` | Users, actors |
| External person | `Person_Ext(alias, "Label", "Description")` | Users outside your org |
| System | `System(alias, "Label", "Description")` | Your system (Level 1) |
| External system | `System_Ext(alias, "Label", "Description")` | Systems you don't control |
| Container | `Container(alias, "Label", "Tech", "Description")` | Deployable units |
| Container (DB) | `ContainerDb(alias, "Label", "Tech", "Description")` | Databases |
| Container (Queue) | `ContainerQueue(alias, "Label", "Tech", "Description")` | Message queues |
| Component | `Component(alias, "Label", "Tech", "Description")` | Modules inside a container |

### Boundaries

| Boundary | Syntax | Use for |
|---|---|---|
| System | `System_Boundary(alias, "Label") { ... }` | Group containers in a system |
| Container | `Container_Boundary(alias, "Label") { ... }` | Group components in a container |
| Enterprise | `Enterprise_Boundary(alias, "Label") { ... }` | Group systems in an org |
| Deployment node | `Deployment_Node(alias, "Label", "Tech") { ... }` | Infrastructure grouping |

### Relationships

| Relationship | Syntax |
|---|---|
| Basic | `Rel(from, to, "Label")` |
| With technology | `Rel(from, to, "Label", "Technology")` |
| Bidirectional | `BiRel(from, to, "Label")` |

## Guidelines

- **Always start at Level 1.** Even if the user wants component details, provide context first.
- **One diagram per zoom level.** Don't mix levels. Container diagrams should not contain component detail.
- **Label every relationship.** Include the verb ("Sends", "Queries") and protocol where relevant ("HTTPS", "gRPC").
- **Use `_Ext` suffixes** for anything outside your control.
- **Keep it focused.** More than ~15 elements? Split the diagram.
- **Introduce every diagram** with a sentence explaining what it shows. Follow with the key insight.
