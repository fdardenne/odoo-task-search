---
name: Odoo Task Search
description: Search a configured Odoo project's open tasks by meaning, using a local script so the API token never passes through the conversation
---

## Odoo Task Search

When the user asks to search, find, or look up a task in Odoo (by
description, symptom, feature, or anything else), use this flow instead of
asking them for anything:

1. Run `~/.claude/skills/odoo-task-search/fetch_tasks.sh` (add
   `--include-closed` only if they explicitly ask to include closed/done
   tasks too). The script reads the user's Odoo token from the OS keychain
   and the project ID from their environment. Never ask for, read, store, or
   repeat this token yourself (including via `security` or `secret-tool`),
   and never construct the HTTP request yourself.
2. The script prints a JSON array of tasks (`id`, `name`, `description`,
   `stage_id`). Descriptions may contain HTML tags, ignore the markup and
   read the text underneath.
3. Compare the query against each task's title and description by meaning,
   not literal keyword overlap.
4. Report matches ordered by relevance: task name linked to
   `https://www.odoo.com/odoo/my-tasks/<id>`, with its stage. If nothing
   matches, say so plainly.
5. Never invent a task that wasn't in the script's output.

If the script fails because the token isn't in the keychain or
ODOO_PROJECT_ID isn't set, tell the user to follow the one-time setup in
this skill's README. Don't try to set the token for them.
