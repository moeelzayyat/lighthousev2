# COMMUNITY (L1.6)

What the owner sets up around the relaunch, and the support steps Claude follows. Nothing here is posted or sent by Claude: every message to the outside is the owner's.

## 1. Discord (owner sets up, about 30 minutes)
Server name: **Lighthouse Keepers**. Channels:
| Channel | Purpose | Who posts |
|---|---|---|
| #announcements | updates, codes, events (read only) | owner |
| #changelog | one post per publish (the release record's "what is in this build") | owner |
| #general | chat | everyone |
| #find-a-crew | "looking for 1–3 keepers" posts | everyone |
| #bug-reports | bugs, with the template below pinned | everyone |
| #ideas | suggestions | everyone |
| #clips | screenshots and videos | everyone |

Roles: Keeper (everyone after verifying), Tester (closed beta, B1.5), Creator (code partners). Turn on Discord's AutoMod (spam, mention spam, slurs) and the "members must have a verified email" level. The link goes in the experience description's social links (Creator Hub → Experience → Social Links), not in-game chat.

Pinned bug template:
```
What happened:
What you expected:
Night / voyage (Standard or Long):
Device (PC, phone, tablet, console):
Your Roblox username:
Screenshot or clip (if you have one):
```

## 2. Support macro (lost items, wrong Pearls)
Run on the owner's request through the owner-only admin channel (`AdminDataService.handle(callerUserId, action, targetUserId, arg)`, R1.8; from the owner's client via the `AdminRequest` remote, or from the live server console). Only the owner's UserId is accepted. Never `RemoveAsync`.
1. **Inspect:** action `inspect`, target the player's UserId → current profile (online) and the 7 daily snapshots with their dates and Pearls.
2. **Decide:** compare the snapshots with the report. If an item or Pearls disappeared between two snapshots, roll back to the last good day; if a reward was missed (no snapshot shows it), grant it.
3. **Rollback:** action `rollback`, arg the snapshot day `YYYY-MM-DD` → applied now if they are online (their current state is snapshotted first), else at their next join.
   **Grant:** action `grant`, arg the Pearls → one claim through GrantService, logged.
4. **Record:** a line in `docs/DECISION_LOG.md`: date, UserId, what was wrong, what was done, cause if known.
5. **Reply** (owner sends it): "Fixed: your profile is back to <date> / we added <n> Pearls. Rejoin to see it. Thanks for the report!"

## 3. Creator codes
Each creator gets a row in `Shared/Definitions/Codes` (kind `creator`, one cosmetic, D-034). The owner sends Claude the creator's chosen code; Claude adds the row, TestRunner checks it, the owner publishes.

## 4. Creator outreach list (owner fills in the names: 20 or more)
Who to look for on YouTube and TikTok: Roblox channels that play **co-op survival, tower defense or horror-lite games with friends**, 5,000–200,000 subscribers (big enough to matter, small enough to answer), posting in the last 30 days, family-friendly. Search terms: "roblox survive the night with friends", "roblox tower defense duo", "roblox co-op survival".

| # | Creator | Platform | Subscribers | Recent Roblox video | Contacted (date) | Reply | Code |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |
| 2 | | | | | | | |
| … | | | | | | | |
| 20 | | | | | | | |

Message template (the owner sends it from their own account):
```
Hi <name>! I make Lighthouse Keepers on Roblox: you and up to three friends keep a lighthouse alive through 7 stormy nights while monsters crawl out of the sea. I think it would fit your co-op videos. If you'd like to try it, I can make you your own code that gives your viewers a beam colour (looks only, no pay-to-win). Link: <experience link>. Thanks either way!
```
