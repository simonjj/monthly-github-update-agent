---
name: aca-monthly-update
description: Research and publish a source-verified monthly Azure Container Apps update.
---

# ACA monthly update

Target the previous complete UTC calendar month. Use the inclusive range from
the month's first day through its last day. Never fill a sparse month with
material from an adjacent month.

## Repository style

Review current `ANNOUNCEMENT` update issues in
`microsoft/azure-container-apps`, including issues 1419 and 1524. Match their
short introduction, simple headings, linked bullets, and concise descriptions.
Do not copy their wording.

## Research

Broad discovery is mandatory. Repository history alone is not sufficient, even
when it produces valid first-party items. Use the available web-search tool. If
it is unavailable, use public search pages, RSS feeds, site searches, and public
APIs. Search engines are discovery tools, not publication-date evidence.

Search first-party sources first:

- `microsoft/azure-container-apps` issues, commits, templates, docs, and releases
- Microsoft Tech Community, Developer Blogs, Learn, and Azure Updates
- Azure CLI, Azure Developer CLI, SDK release notes, and Microsoft videos
- Microsoft and Azure-Samples GitHub repositories

Then search public practitioner blogs, technical walkthroughs, conference
recordings, samples, and videos where ACA is the main subject.

### Required search matrix

Complete every row before drafting:

| Search group | Required coverage |
| --- | --- |
| General web | Exact product name plus target month/year; ACA abbreviation plus target month/year; announcement, tutorial, sample, video, conference, and blog variants |
| Microsoft | Tech Community, Developer Blogs, Learn, Azure Updates, Azure CLI and SDK release notes, Microsoft video channels, Microsoft and Azure-Samples GitHub repositories |
| Community | Practitioner and company engineering blogs, DEV Community, Medium, InfoQ, conference sites, podcasts, newsletters, YouTube, and non-Microsoft public GitHub repositories |
| Feature follow-ups | Sandboxes, Dynamic Sessions, Express, Jobs, serverless GPU, Functions on ACA, networking, ingress, Dapr, KEDA, OpenTelemetry, Java, security, and any new feature term found during discovery |

Run at least 12 distinct discovery queries across the matrix. Open every
plausible result at its original URL. When a product announcement or feature
term is found, run at least one follow-up query for independent technical
coverage, samples, or walkthroughs. Continue until two consecutive query
variations produce no new plausible candidates.

Do not interpret the minimum query count as a minimum content count. A month can
still have few qualifying items after broad research.

For every candidate record the title, original publication date, author or
publisher, canonical URL, ACA relevance, inclusion reason, duplicates, and date
evidence. Search results are discovery hints, not evidence. Open the original
page. Prefer `datePublished`, `article:published_time`, RSS `pubDate`, GitHub
`created_at`, or a visible source date. Reject ambiguous dates.

Research notes must contain:

- A search coverage log with each exact query or site search and its surface.
- Every plausible canonical page opened.
- The inclusion or exclusion outcome and reason.
- Follow-up searches performed for promising product terms.
- A clear statement that all required search groups were completed.

Do not start drafting until the coverage log demonstrates the required matrix,
minimum query count, and saturation rule.

Include product releases, previews, retirements, region expansions, Sandboxes,
Dynamic Sessions, Express, Jobs, serverless GPUs, Functions on ACA, networking,
security, Dapr, KEDA, telemetry, ACA-specific tooling, samples, and substantial
community guides. Exclude passing mentions, generic Azure/container posts,
undated material, old posts merely edited this month, and duplicate coverage
without additional technical depth.

## Draft

Use the issue title as the title; do not repeat it as an H1. Use only sections
that have content, commonly `Product Updates` and `Content Highlights`.
Each bullet should contain a canonical link and one or two factual sentences.
Do not label something GA, preview, new, supported, or available unless its
source says so. Do not pad a sparse month.

## Publish

Use `gh` with the authenticated account. Search all issue states for the exact
title before creating. Create the issue with label `ANNOUNCEMENT`, pin it, and
read it back. Confirm author, exact title, open state, label, links, body, and
pin state. Never include private research notes in the issue.
