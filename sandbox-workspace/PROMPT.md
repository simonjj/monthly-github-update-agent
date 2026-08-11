Publish the Azure Container Apps monthly update for the previous complete UTC
calendar month.

This is an unattended production run. Do not ask questions. Read and follow:

- `.github/skills/aca-monthly-update/SKILL.md`
- `.github/skills/anti-ai-writing/SKILL.md`

Use public web and GitHub sources only. Verify every included item's original
publication date against the exact target-month date range. Open the canonical
source for every candidate, and reject ambiguous dates, duplicates, generic
Azure/container content, and material where Azure Container Apps is only
incidental.

Broad discovery is a required completion gate, not optional guidance. Do not
draft after checking only the ACA repository or known Microsoft pages. Use the
available web-search tool. If it is unavailable, use public search pages, RSS
feeds, site searches, and public APIs through the browser or shell.

Before drafting, complete and record all of these search groups:

1. General web searches for both `"Azure Container Apps" <Month> <Year>` and
   `"ACA" "Container Apps" <Month> <Year>`, with variants for announcement,
   tutorial, sample, video, conference, and blog.
2. First-party site searches across Microsoft Tech Community, Developer Blogs,
   Microsoft Learn, Azure Updates, Microsoft/Azure-Samples GitHub repositories,
   Azure CLI and SDK release notes, and Microsoft video channels.
3. Community searches across practitioner blogs, engineering blogs, DEV
   Community, Medium, InfoQ, conference sites, podcasts, newsletters, YouTube,
   and public GitHub repositories outside Microsoft.
4. Feature-specific searches for any product terms found during research,
   including Sandboxes, Dynamic Sessions, Express, Jobs, serverless GPU,
   Functions on ACA, networking, ingress, Dapr, KEDA, OpenTelemetry, Java, and
   security.

Run at least 12 distinct discovery queries spanning every group. Open every
plausible result at its original URL. For each promising topic, run at least one
follow-up query using the feature name or author to find independent technical
coverage. Continue until two consecutive query variations produce no new
plausible candidates. A sparse final issue is acceptable; a narrow search is
not.

Keep private research notes in `/tmp/aca-monthly-research.md`. Include a search
coverage section with the exact queries or site searches run, the search surface,
plausible pages opened, and the inclusion or exclusion outcome. Never put these
notes in the issue.

Publish to `microsoft/azure-container-apps` as the authenticated `simonjj`
account:

- Title: `<Month> <Year> Updates`
- Label: `ANNOUNCEMENT`
- Body: short introduction, only nonempty sections, linked factual bullets, and
  a short thank-you line

Before creating anything, search open and closed issues for an exact title match.
If it already exists, verify its title, author, label, state, body, and links,
unpin only older pinned monthly issues whose titles end in `Updates`, ensure the
target issue is pinned, and do not create a duplicate.

For a new issue, draft and audit the public body first. Then:

1. List pinned issues.
2. Unpin only older monthly update issues with the `ANNOUNCEMENT` label and a
   title ending in `Updates`. Leave unrelated important pinned issues alone.
3. Create the new issue.
4. Pin it.
5. Read it back and verify the exact title, `simonjj` author, open state,
   `ANNOUNCEMENT` label, public-only body, working canonical links, and pinned
   status.

Do not publish research notes. Do not claim success until the final read confirms
the persisted issue.

After successful verification, write `result.json` in the current directory as
valid JSON with exactly these fields:

```json
{
  "status": "published",
  "issueUrl": "https://github.com/microsoft/azure-container-apps/issues/1234",
  "title": "Month Year Updates",
  "month": "YYYY-MM"
}
```

Use `"already_exists"` for `status` when the exact issue already existed and was
successfully verified and pinned. Do not write a success-shaped result file if
publishing or verification fails.
