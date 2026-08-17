# Chat Features & Moderation — Backend Spec

**For:** Backend dev
**App:** OutSpot (Flutter)
**Base URL:** `https://api-app.outspot.app/api`
**Date:** 2026-06-09

This document describes every backend change needed for chat moderation and the
new chat features (reply / forward / multi-delete). Read the **Context** first —
it explains how chat works today so the rest makes sense.

---

## 0. Context — how chat works today (read this first)

- Messages are sent over **Socket.IO**, not REST. The client emits:
  ```js
  socket.emit('sendMessage', {
    chatId,                 // conversation id
    content,                // text / caption (string, may be "")
    imageUrl,               // optional media URL (image or video)
    meta: { isVideo: bool } // optional
  })
  ```
- Server broadcasts the new message to participants; the client appends it.
- The same chat screen is used for **1-on-1 friend DM**, **group**, and
  **community** chat (client distinguishes via an `isGlobalChat` flag). So **one
  backend implementation per feature covers all three contexts.**
- Messages are fetched via `GET /api/chats/messages/:chatId` (returns a JSON
  array of message objects).
- The client **already listens** for a socket event `messagesDeleted`:
  ```js
  // payload it expects:
  { chatId, messageIds: [id, id, ...] }
  ```
  When received, it removes those messages locally. **Use this event for delete
  (item 1) — no client change needed to remove them.**

### Three chat contexts and how moderation should behave

| Action | 1-on-1 DM | Group | Community |
|---|---|---|---|
| Report **message** (content) | ✅ | ✅ any member's msg | ✅ any member's msg |
| Report **user** | ✅ | ✅ | ✅ |
| **Block** user (global) | full block | hide their msgs from me | hide their msgs from me |
| Delete **own** message | ✅ | ✅ | ✅ |
| Remove/ban member, delete anyone's msg | — | group **admin** only | community **admin/owner** only |

**All reports go to the OutSpot moderation team** (not community admins).

---

## 1. Delete own message  ⭐ store-required

**Why:** Users must be able to delete their own messages. Store policy also
expects content removal tooling.

**New socket event (client → server):**
```js
socket.emit('deleteMessage', { chatId, messageIds: [123, 124] })
```
- Accepts an **array** so single-delete and multi-delete use the same path.
- **Permission:** for each id, verify `message.senderId === authUserId`.
  Skip / reject any id the caller does not own. **A user can delete ONLY their
  own messages — never another member's.** (Admin deletion is item 5.)
- Delete (or soft-delete) the owned messages.

**Server → all chat participants (existing event):**
```js
socket.emit('messagesDeleted', { chatId, messageIds: [123, 124] })
```
↑ Only include the ids that were actually deleted.

**Decisions you must confirm back to frontend:**
- Final event names (`deleteMessage` / `messagesDeleted`)?
- "Delete for everyone" vs "delete for me only"? (Recommended: delete for
  everyone, since it's the sender's own message.)
- Any time window (e.g. WhatsApp's limit), or unlimited?

---

## 2. Report a message (content)  ⭐ store-required

**Why:** Apple Guideline **1.2** and Google's UGC policy require a way to report
**objectionable content** (a specific message), not just a user. This is the
main store-compliance gap.

**New REST endpoint:**
```
POST /api/chats/messages/:messageId/report
Authorization: Bearer <token>
Body: { "reason": "spam" | "harassment" | "nudity" | "violence" | "other",
        "note": "optional free text" }
Response: { "success": true }
```
- Create a row in a **`reports` table** (see item 7). The backend should derive
  context from the message itself: store `messageId`, `reportedUserId` (the
  message sender), `reporterId` (auth user), `chatId`, the message's
  `contextType` (`dm` | `group` | `community`) and `communityId`/`groupId` if
  applicable, `reason`, `note`, `status: "pending"`.
- Do **not** auto-delete the message. A human reviews it (item 7).

**Confirm back:** final endpoint + body shape (or if you prefer extending the
existing `/report` endpoint with `{ type: "message", messageId, reason }`).

---

## 3. Report a user  — already exists, keep

`POST /api/report  { "reportedId": <userId> }` already works and is wired in the
profile screens (and now in the DM options screen as a workaround). Make sure
these reports land in the **same `reports` table / dashboard** as item 2 so the
team reviews everything in one place. Add a `type` column (`user` | `message`).

---

## 4. Block — global, but must filter group/community feeds  ⭐ partial gap

**Existing & working:** `POST /api/block/:userId`, `DELETE /api/block/:userId`,
`GET /api/users/blocked`. (Verified live: `GET /users/blocked` → 200.)

**Block is global and user-level.** Effect by context:
- **DM:** the two users can no longer message each other (already handled?).
- **Group / Community:** the blocked user is **not removed** (only an admin can
  remove them), but **their messages must be hidden from the blocker**.

**New backend requirement:** when returning messages for a group/community
chat (`GET /api/chats/messages/:chatId`) **and** when broadcasting new socket
messages, **filter out messages from users the recipient has blocked** (and
hide the recipient's messages from the blocked user). Do this server-side so the
client doesn't have to cross-reference the block list on every message.

**Confirm back:**
- Does DM block already prevent messaging both ways?
- Will you filter blocked users' messages in group/community feeds server-side?

---

## 5. Admin moderation for group / community  ⭐ store-required

**Why:** Apple 1.2 requires "the ability to eject abusive users." For
group/community (UGC spaces), the group/community **admin/owner** must be able to:
- **Remove / ban** a member.
- **Delete any message** in their group/community (not just their own).

**Confirm back:** do these already exist? If not, we need:
```
POST   /api/communities/:communityId/members/:userId/ban     (admin only)
DELETE /api/communities/:communityId/members/:userId         (remove, admin only)
POST   /api/chats/messages/:messageId/admin-delete           (admin/owner of that
                                                              group/community only)
```
(Equivalent routes for groups.) Admin-delete should also emit `messagesDeleted`
so all clients drop the message.

### List banned members (needed for the Unban UI)  ⭐ NEW

The app shows banned members on a dedicated **"Banned Users"** screen (reached
from the community ⋮ menu) where the admin taps **Unban** (calls the existing
unban endpoint). That needs a list endpoint:
```
GET /api/communities/:communityId/banned          (admin/creator only)
Response: { "data": [ { "id": int, "username": str, "firstName": str,
                        "lastName": str, "avatarUrl": str } ] }
```
(Client also accepts `banned`/`members` as the array key; parses defensively.)
A matching `GET /api/chats/:chatId/banned` would let us add the same Unban
screen to group settings later.

**Confirm back:** endpoint path + array shape.

---

## 6. Forward messages  (Phase 2 — likely NO backend change)

**Why:** UX parity (WhatsApp-style). Not store-required.

Forwarding = sending the same content/media to other chats. Since `sendMessage`
already accepts `imageUrl` directly, the client can forward by emitting
`sendMessage` to each target `chatId` with the original `content` + `imageUrl`
(**media is reused — no re-upload**).

**Confirm back:**
- Is it OK to reuse an existing `imageUrl` in a new message to a different chat
  (no re-upload, no ownership check that would block it)?
- Optional: add a `forwarded: true` field on the message so the client can show
  a "Forwarded" label. If you support it, include it in the message payload.

---

## 7. Moderation pipeline (reports table + admin dashboard)  ⭐ store-required

**Why:** A report button is useless without somewhere to review and act. Apple
1.2 is explicit: the developer must **act on reports within 24 hours** —
remove the content and eject the offending user. Reviewers will check that this
pipeline exists.

**Needed:**
1. **`reports` table:** `id, type (user|message), reporterId, reportedUserId,
   messageId (nullable), chatId (nullable), contextType (dm|group|community),
   communityId/groupId (nullable), reason, note, status (pending|reviewed|
   actioned|dismissed), createdAt, reviewedAt, reviewedBy.`
2. **Admin dashboard** (web) for the **OutSpot team**: list pending reports, view
   the reported message/user/context, and act — **delete content** and
   **ban the user**. (This is the bigger web task — flag it early.)
3. SLA: design so the team can action within 24h.

**Confirm back:** is there an existing admin/moderation dashboard? If not, this
needs to be built — it's mandatory for store approval.

---

## 8. Reply / quote  (Phase 3)

**Why:** UX parity. Not store-required.

**Change to `sendMessage` (client → server):** add optional field:
```js
socket.emit('sendMessage', { chatId, content, imageUrl, meta,
                             replyToMessageId: 456 })  // NEW, optional
```
**Change to message payload** (both the socket broadcast and
`GET /chats/messages/:chatId`): include a `replyTo` object when the message is a
reply, so the client can render the quoted bubble:
```js
{
  id, content, imageUrl, senderId, createdAt, ...,
  replyTo: {                 // null if not a reply
    id, content, imageUrl, senderId, senderName
  }
}
```

**Confirm back:** final `replyTo` shape.

---

## 9. Share story/post to chat = real image message (NOT a URL in text)  ⭐ important

**Why:** Today, "Send to" shares a story by sending the story's media **URL inside
the text** (`content: "Check out this post! https://...s3.../x.jpg"`). Problems:
- It renders as a raw link / broken inline, not a proper image message.
- **Stories are deleted after 24 hours.** The chat message points at the story's
  S3 object, so when the story expires the chat image **breaks** (404). The chat
  message must not depend on the story's lifecycle.

**Frontend change (already shipped):** the share now sends a clean caption plus a
separate `imageUrl` field:
```
POST /api/chats/messages
{ "chatId": 123, "content": "Check out Saj's post on OutSpot!", "imageUrl": "<story media url>" }
```
(The "Send To" sheet and `sendGlobalChatMessage` now pass `imageUrl`.)

**Backend work needed:**
1. **Accept & store `imageUrl`** on the message (so the bubble renders a real
   inline image), and return it on the message object (`imageUrl` / `mediaUrl`)
   for both the POST response and `GET /chats/messages/:chatId`.
2. **Copy the media to a chat-owned object** when the share is sent — do **not**
   just reference the story's S3 key. Duplicate it to a message-owned key (e.g.
   `chat-media/...`) and store that copy's URL on the message. This makes the
   shared image **survive the 24h story deletion** (the message owns its own
   media). This is the key requirement.
3. The story-expiry / cleanup job must delete only the **story's** media, never
   the copied chat-message media.

**Confirm back:** the field name (`imageUrl` vs `mediaUrl`), and that the media is
copied (not referenced) so it persists after the story expires.

---

## 10. Ban notification (Option B — explicit notify the banned user)  ⭐ requested

**Why:** When a user is banned from a community/group, they should be told —
not just silently lose access. Needs to work even when the app is **closed**.

The existing socket `*_banned` event only reaches the user while the app is open
**and** they're in that chat. For closed/background apps we need a push + a
persistent notification-list entry. So on ban, the server must do **three** things:

1. **Socket event** — `community.member_banned` / `group.member_banned` (already
   built; the client ejects the user from the room if they're viewing it).
2. **Create a notification record** for the banned user, so it shows in the
   in-app notification list. Use the SAME shape as existing notifications so the
   client renders it with zero changes:
   ```jsonc
   {
     "id": int,
     "userId": <bannedUserId>,
     "type": "COMMUNITY_BANNED" | "GROUP_BANNED",   // client maps these to a 🚫 icon
     "title": "Removed from <community/group name>",
     "description": "You were removed by an admin." + (reason ? " Reason: <reason>" : ""),
     "isRead": false,
     "createdAt": "<iso>"
     // communityId / chatId optional extra fields
   }
   ```
   The notification list already renders `title` + `description` generically, so
   any backend text shows correctly.
3. **Send an FCM push** to the banned user's device(s):
   ```jsonc
   {
     "notification": { "title": "Removed from <name>", "body": "You were removed by an admin." },
     "data": { "type": "COMMUNITY_BANNED", "communityId": "<id>" }   // or GROUP_BANNED + chatId
   }
   ```
   - The client's FCM router already handles unknown types via a safe default
     (opens the app). `COMMUNITY_BANNED` / `GROUP_BANNED` will route to the app
     gracefully; no client change required for it not to crash.
   - **Respect the per-user notification on/off toggle** (the FCM-guard feature
     handed over separately) — if the user disabled notifications, send the
     socket + notification record but **skip the FCM push**.

**Confirm back:** final `type` strings (`COMMUNITY_BANNED` / `GROUP_BANNED`), and
whether the notification record + FCM are emitted on ban (and optionally on
unban, if you want to notify reinstatement).

---

## Summary — what to build & priority

| # | Feature | Store-required? | Backend work |
|---|---|---|---|
| 1 | Delete own message | ✅ | `deleteMessage` socket → `messagesDeleted`, own-only |
| 2 | Report message | ✅ | `POST /chats/messages/:id/report` → reports table |
| 3 | Report user | ✅ (exists) | unify into reports table (+`type`) |
| 4 | Block + feed filtering | ✅ (filtering is the gap) | hide blocked users' msgs in group/community |
| 5 | Admin remove/ban/delete-any | ✅ | admin moderation routes (if missing) |
| 6 | Forward | ❌ | none / optional `forwarded` flag |
| 7 | Reports table + admin dashboard | ✅ | reports table + web dashboard + 24h SLA |
| 8 | Reply / quote | ❌ | `replyToMessageId` + `replyTo` in payload |
| 9 | Share story = image msg (copy media) | ⭐ | accept/store `imageUrl` + **copy** media so it survives 24h story delete |

**Do the ✅ items first (1, 2, 4, 5, 7) — those are what get the app accepted on
the App Store / Play Store. 6 and 8 are UX polish.**

For each feature, **reply back to the frontend dev with the final event/endpoint
names and the exact request/response (and socket payload) shapes** — the Flutter
side will be built to match exactly what you confirm here.

---

## Frontend workaround already shipped (so chat isn't unmoderated meanwhile)

In the DM conversation options screen we added **Report** and **Block** using the
existing user-level endpoints (`/report {reportedId}`, `/block/:id`). This is a
stopgap so a user can act on an abusive DM partner today. It will be replaced /
extended with per-message report + the chat long-press menu once items 1–2 land.
