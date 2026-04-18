# Poetry Backend MVP Epics

This folder groups backend MVP work into epics and implementation tickets.

Project constraints for this MVP:

- Anonymous poems only (no auth, no author field)
- Published-only model (no drafts)
- No edit/delete
- No likes/reactions
- Plain text poems only
- Max poem length: 2000 characters
- Mindful discovery: same 10 poems for everyone each UTC day
- Users can browse historical daily sets

Epics:

- `core-publishing/` - schema and core read/write poem APIs
- `mindful-feed/` - finite daily feed and history endpoints
- `hardening-quality/` - anti-pollution checks, tests, docs
