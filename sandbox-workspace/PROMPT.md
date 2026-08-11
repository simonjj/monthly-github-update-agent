Publish the Azure Container Apps monthly update for the previous complete UTC
calendar month.

This is an unattended production run. Do not ask questions. Read and follow:

- `.github/skills/aca-monthly-update/SKILL.md`
- `.github/skills/anti-ai-writing/SKILL.md`

Use public web and GitHub sources only. Verify every included item's original
publication date against the exact target-month date range. Search broadly, open
the canonical source for every candidate, and reject ambiguous dates, duplicates,
generic Azure/container content, and material where Azure Container Apps is only
incidental. Keep private research notes in `/tmp/aca-monthly-research.md`; never
put those notes in the issue.

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
