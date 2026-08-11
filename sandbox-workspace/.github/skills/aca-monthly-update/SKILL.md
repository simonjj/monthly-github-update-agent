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

Search first-party sources first:

- `microsoft/azure-container-apps` issues, commits, templates, docs, and releases
- Microsoft Tech Community, Developer Blogs, Learn, and Azure Updates
- Azure CLI, Azure Developer CLI, SDK release notes, and Microsoft videos
- Microsoft and Azure-Samples GitHub repositories

Then search public practitioner blogs, technical walkthroughs, conference
recordings, samples, and videos where ACA is the main subject.

For every candidate record the title, original publication date, author or
publisher, canonical URL, ACA relevance, inclusion reason, duplicates, and date
evidence. Search results are discovery hints, not evidence. Open the original
page. Prefer `datePublished`, `article:published_time`, RSS `pubDate`, GitHub
`created_at`, or a visible source date. Reject ambiguous dates.

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
