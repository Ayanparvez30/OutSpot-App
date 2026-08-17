# Backend spec — Challenge "Others who completed this" pagination

The Flutter app has been updated to consume this endpoint in a **server‑paginated,
server‑ordered** way. Until the backend implements the below, the app falls back
to client‑side pagination of the full list (works, but downloads everything).
**Once the backend returns the pagination fields described here, the app switches
to server pagination automatically — no further app changes are needed.**

---

## Endpoint

```
GET /api/challenges/{challengeId}/submissions
Authorization: Bearer <token>      // identifies the requesting user (drives ordering)
```

### Query params the app now sends

| Param      | Type   | Default  | Meaning |
|------------|--------|----------|---------|
| `page`     | int    | `1`      | 1‑based page number |
| `pageSize` | int    | `20`     | Items per page |
| `sort`     | string | `newest` | `newest` or `oldest` (by submission time) |

Example: `GET /api/challenges/482/submissions?page=2&pageSize=20&sort=newest`

---

## Required ordering (apply GLOBALLY, then paginate)

Order the **entire** result set for this challenge **before** slicing into pages,
relative to the authenticated requester:

1. **Friends** of the requester first.
2. Then users who **share a community OR group** with the requester.
3. Then **everyone else**.

Within each tier, order by submission/completion time according to `sort`
(`newest` = most recent first, `oldest` = oldest first).

> Ordering MUST be **deterministic/stable** (add a final tiebreaker such as
> `userId`) so paging never duplicates or skips a row when times tie.

Exclude the **requesting user** from the list (it's "*others* who completed this").

`page`/`pageSize` then select the slice of this fully‑ordered list.

---

## Required response (HTTP 200)

```jsonc
{
  "items": [ /* participant objects, see below */ ],
  "page": 2,          // echo of the requested page
  "pageSize": 20,     // echo of the requested pageSize
  "total": 51234,     // total count across ALL pages (int)
  "hasMore": true     // are there more pages after this one? (bool)
}
```

> **Important:** include at least one of `hasMore`, `total`, or `page` in the
> response. The app detects "server is paginating" by their presence; if none
> are present it assumes the response is the *full* list and paginates on the
> client. **Please return `hasMore` (bool) AND `total` (int) AND echo `page`.**
>
> A `{ "data": { items, page, ... } }` envelope is also accepted, but a flat
> object is preferred.

### Participant object (keep all current fields; add `submittedAt`)

```jsonc
{
  "userId": 123,
  "username": "bristy akter",
  "avatarUrl": "https://.../avatar.jpg",
  "uploadedCount": 1,
  "completed": true,
  "earnedPoints": 10,
  "weeklyPoints": 18,
  "totalPoints": 10,
  "relationship": {
    "isFriend": true,
    "sharedCommunities": ["Photography Club"],  // human-readable names; UI shows the first as a chip
    "sharedGroups": ["Weekend Hikers"],          // human-readable names; UI shows the first as a chip
    "badges": []
  },
  "submittedAt": "2026-06-10T09:47:24.536Z"      // ISO-8601; when this user completed the challenge
}
```

- `submittedAt` — ISO‑8601 (or epoch millis). Drives the newest/oldest sort and
  may be shown in the UI. (The app also accepts `completedAt` / `createdAt` /
  `lastSubmittedAt` / `updatedAt` as aliases, but **`submittedAt` is preferred**
  — send exactly one.)
- `relationship.sharedCommunities` / `sharedGroups` — arrays of **strings**
  (names). The UI renders the first element as a chip ("Friend" / community /
  group). Keep them as today.
- `relationship.isFriend` — bool.

---

## Edge cases

| Case | Expected response |
|------|-------------------|
| No participants | `{ "items": [], "page": 1, "pageSize": 20, "total": 0, "hasMore": false }` |
| `page` past the end | `{ "items": [], ..., "hasMore": false }` |
| Last page | `hasMore: false` |

---

## Why this matters

With 50k+ participants the current endpoint returns the whole list in one
response, which the app must download + parse at once (the crash). Server‑side
pagination (20 rows/request) + server‑side relationship ordering fixes it and
keeps the friends‑first ordering correct across the *entire* list (client‑side
ordering can only sort the rows already downloaded).

## Contract summary (what the app sends / expects)

- Sends: `?page=&pageSize=&sort=newest|oldest`, 1‑based pages, size 20.
- Expects: `{ items[], page, pageSize, total, hasMore }`, items ordered
  friends → shared community/group → others, then by time per `sort`.
- Switches to server pagination automatically once `hasMore`/`total`/`page` appear.
