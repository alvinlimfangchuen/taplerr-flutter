# Screenshot Checklist — for the Flutter build agent

Drop screenshots into `documentation/flutter/screenshots/`, named `NN-page-name.png` (e.g. `01-login.png`) so they sort in the same order as this list. Capture at a **mobile viewport width (375–430px)**, not desktop — the existing app's desktop layout hides how things collapse on a phone, which Flutter needs to decide independently anyway. Where a page has visibly different states, capture each state as its own file.

Reference: full endpoint/behavior detail for every page below is in [`flutter-documentation.md`](flutter-documentation.md).

## Tier 1 — must-have (auth + core identity)

- [ ] `01-login.png` — `/login`
- [ ] `02-register.png` — `/register`
- [ ] `03-forgot-password.png` — `/forgot-password`
- [ ] `04-reset-password.png` — `/reset-password?token=...`
- [ ] `05-dashboard-guest.png` — `/dashboard` logged out
- [ ] `06-dashboard-logged-in.png` — `/dashboard` logged in (notification badge, promo banners)
- [ ] `07-profile-edit.png` — `/profile` full edit form
- [ ] `08-profile-photo-crop-modal.png` — `/profile`, photo crop modal open
- [ ] `09-profile-banner-crop-modal.png` — `/profile`, banner crop modal open
- [ ] `10-profile-visibility-toggles.png` — `/profile`, show_phone/show_email/etc. switches in "on" state
- [ ] `11-card-public-classic.png` — `/card?slug=...` (or `/public-profile?uid=...`), `card_layout = classic`
- [ ] `12-card-public-compact.png` — same page, `card_layout = compact`
- [ ] `13-card-management-list.png` — `/card-management`, list of bound cards
- [ ] `14-card-management-bind-form.png` — `/card-management`, bind-card modal/form open

## Tier 2 — high-value next

- [ ] `15-contacts-all.png` — `/contacts`, "All contacts" tab
- [ ] `16-contacts-requests.png` — `/contacts`, "Requests" tab
- [ ] `17-contacts-sent.png` — `/contacts`, "Sent" tab
- [ ] `18-contacts-manual.png` — `/contacts`, "Added manually" tab
- [ ] `19-notifications-list.png` — `/notifications`, with unread items
- [ ] `20-analytics-overview.png` — `/analytics`, card performance charts (doughnut)
- [ ] `21-analytics-heatmap.png` — `/analytics`, account engagement heatmap

## Tier 3 — commerce flow (only if the app will sell cards too)

- [ ] `22-products.png` — `/products`
- [ ] `23-customize-select.png` — `/customize`
- [ ] `24-customize-basic.png` — `/customize/basic`, with add-ons checked
- [ ] `25-cart.png` — `/cart`
- [ ] `26-checkout.png` — `/checkout`
- [ ] `27-my-orders.png` — `/my-orders`, a couple of different status tabs
- [ ] `28-order-detail.png` — `/order-detail?id=...`
- [ ] `29-points.png` — `/points`
- [ ] `30-rewards.png` — `/rewards`

## Capture notes

- Use real/seeded data where possible (an empty-state screenshot and a populated-state screenshot both have value if they render differently — capture both as separate files, e.g. `15-contacts-all.png` / `15-contacts-all-empty.png`).
- These are read-only reference captures — no app code or backend was changed to produce this checklist.
