# Poetry Backend MVP Epics

This folder groups backend work into epics and sprint plans.

Tracking convention:

- Active planning lives in `epics/`
- Completed epics are moved into `epics/done/`

Workflow summary:

1. Create a new epic folder in `epics/` with `README.md` and `tickets/`.
2. Create one ticket file per task in that epic's `tickets/` folder.
3. Create or update a sprint plan in `epics/sprints/`:
   - file name format: `sprint-<n>.md` (for example `sprint-2.md`)
   - include scope, subagent assignment, sequencing, and done criteria
   - start from `epics/sprints/sprint-template.md`
4. Implement and verify sprint scope.
5. When a sprint is completed, move its plan file into `epics/sprints/done/`.
6. When an epic is completed, move its folder into `epics/done/`.

Checklist before marking complete:

- Sprint file moved to `epics/sprints/done/`
- Epic folder moved to `epics/done/` (if epic fully complete)
- Build/tests pass (`cd poe && ./mvnw clean install`)
- Docs updated if behavior/commands changed

Project constraints for this MVP:

- Anonymous poems only (no auth, no author field)
- Published-only model (no drafts)
- No edit/delete
- No likes/reactions
- Plain text poems only
- Max poem length: 2000 characters
- Mindful discovery: same 10 poems for everyone each UTC day
- Users can browse historical daily sets

Current layout:

- `sprints/` - active sprint plan files
- `sprints/done/` - completed sprint plan files
- `done/` - completed epic folders
