# Learn & Earn (WIP)

## Terms

- PT = Partner-hosted Tutorial
- SS = Solana Spaces
- LET = Learn & Earn Tablet
- LEP = Learn & Earn inside Phantom

## Flow Overview

- Partner gives SS their PT URL, i.e.: https://mysite.demo/spaces-onboarding
- SS adds Partner to LET directory: Button, Text, Video, etc.
- Consumer links their wallet address to LET to launch PT
- LEP sends Consumer to https://mysite.demo/spaces-onboarding?sid=SESSIONID
- PT uses passed SESSIONID in subsequent api calls to SS

## SS Learn & Earn API

`GET /api/le/session?sessionId=${SESSION_ID}`

Get session info: address and rewards to date. This can be used to determine
what flow to display to the Consumer, or to block/redirect access entirely,
for example if the rule is a Consumer can only go through the flow and be
rewarded once.

Response:

```json
{
  "address": "ABC123...",
  "rewardsToDate": {
    "TokenDEF456...": 0.45 // based on calls to /api/le/reward
  }
}
```

---

`POST /api/le/setup`

Renders the LET outline while the user is using the LEP.

Request:

```json
{
  "sessionId": SESSION_ID,
  "steps": [
    {
      "id": 1,
      "title": "Intro Video",
      "description": "Learn the basics of ..."
    },
    {
      "id": 2,
      "title": "Perform a swap",
      "description": "You'll turn X into Y ..."
    }
  ]
}
```

Response:

```json
{
  "ok": true
}
```

---

`POST /api/le/step`

Updates the step status on the LET.

Request:

```json
{
  "sessionId": SESSION_ID,
  "step": 1,
  "status": "COMPLETE" // COMPLETE | TODO | IN_PROGRESS
}
```

Response:

```json
{
  "ok": true
}
```

---

`POST /api/le/collect`

General analytics collect endpoint.

Request:

```json
{
  "sessionId": SESSION_ID,
  "event": "Something happened",
  "data": {
    "foo": "bar"
  }
}
```

Response:

```json
{
  "ok": true
}
```

---

`POST /api/le/reward`

Track that the session has been rewarded by PT.

Request:

```json
{
  "sessionId": SESSION_ID,
  "amount": "1.123",
  "token": "ABC123..."
}
```

Response:

```json
{
  "ok": true
}
```

---

`POST /api/le/complete`

Mark the session complete. Subsequent API calls with this sessionId will fail.

Request:

```json
{
  "sessionId": SESSION_ID,
}
```

Response:

```json
{
  "ok": true
}
```

---

`POST /api/le/mark_redeemed`

Given a wallet + token combo, marks them as externally redeemed.

The response of `true` can be used for external decision making.

For a given wallet + token combo, the first call to this endpoint will
return `true` or `false`. If `true`, a second call to this endpoint
with the same combo will always return `false`, as the combo was
previously marked redeemed.

Request:

```json
{
  "wallet_address": WALLET_ADDRESS,
  "token": TOKEN_OR_NFT_REWARDED_ADDRESS
}
```

Response:

```json
{
  "ok": true // (records existed for wallet+token that had not yet been marked externally redeemed) or false (combo doesnt exist or was already marked redeemed)
}
```

## Typical Flow from PT perspective

1. App launches inside Phantom.
1. App calls `GET /api/le/session` with the passed `sid`.
1. App decides what the experience will be.
1. App calls `POST /api/le/setup` with outline of steps. (LET updates)
1. App begins flow.
1. Consumer completes step 1.
1. App calls `POST /api/le/step` to mark step 1 complete.
1. App renders next step. Repeat.
1. Along the way, App may want to track arbitary events, using `POST /api/le/collect`.
1. At the end, App airdrops the reward to address, calls `POST /api/le/reward`.
1. App shows completion page and calls `POST /api/le/complete`.
1. LET shows "Start Over / Reset", which resets the LET.
