# Flutter Integration Guide — Taplerr Backend

This doc is for building a **Flutter companion app** on top of this existing PHP backend. It's read-only analysis — nothing in `app/`, `index.php`, or `config/` was changed to produce it.

**Read this first, it changes how you build the app:** this backend is a traditional **server-rendered PHP app**, not a REST/JSON API. Authentication is a native **PHP session cookie**, not a bearer token/JWT, and most endpoints respond with full HTML pages or a `302` redirect rather than JSON. A handful of AJAX-only endpoints do return JSON (listed in §3). This matters a lot for a mobile client — see §2 before writing any Dart code.

## Current URL

`https://demo.taplerr.com` — all paths in this doc (`/login`, `/profile`, `/cart`, etc.) are relative to this host. Point the Flutter app's `baseUrl` here, not at `localhost`.

---

## 1. How requests reach the app

Every request — regardless of path — is funneled through `index.php` (see `.htaccess`), which does `session_start()`, builds `$conn` (mysqli) from `config/.env`, then a tiny in-house `Router` (`index.php:12-53`) matches the exact path string against a table of `$router->add($path, $controller, $action, $requiresAuth, $view)` calls. There is **no API prefix** (no `/api/v1/...`) — endpoints live at plain paths like `/login`, `/profile`, `/cart`.

Base URL for the Flutter app is `https://demo.taplerr.com` (see "Current URL" above) — or whatever host/port serves this Docker LAMP vhost in other environments, e.g. `http://localhost:8080`. There is no separate API subdomain.

---

## 2. Authentication — read this before writing any networking code

### 2.1 Mechanism: session cookie, not a token

`AccountController::login()` (`app/controllers/AccountController.php:10-70`):

- `POST /login` (or `POST /`, same handler) with **form-encoded** fields `email`, `password` (not JSON).
- On success: `session_regenerate_id(true)` then sets `$_SESSION['taplerr_user_id']`, `taplerr_user_name`, `taplerr_user_email`, `taplerr_user_status`, `taplerr_user_role`. PHP sends this back as a `Set-Cookie: PHPSESSID=...` header. The response itself is an **HTTP redirect** (`Location: /dashboard` or `/admin/dashboard` for `user_role === 'admin'`) — there is no JSON success body and no token in the body to parse.
- On failure (wrong credentials, or `isActivated = 0`): `$_SESSION['error']` is set and it redirects back to `Location: /login` — **the error message is not in this response**. It's only rendered as HTML text the next time something does `GET /login`. A pure API client gets no machine-readable failure reason from the login call itself.
- Every subsequent authenticated request must resend that same session cookie. The server checks `$_SESSION['taplerr_user_id']` per-controller-method (not centrally — see `$router->add()`'s `$requiresAuth` param, which is `false` on nearly every route in `index.php`; the real gate is each method's own `if (!isset($_SESSION['taplerr_user_id']))` check).

**Practical consequence for Flutter:** you cannot just POST credentials and parse a JSON token out of the response. You need an HTTP client that behaves like a browser — captures `Set-Cookie` on the login response, stores it, and replays it as a `Cookie` header on every later request. Treat "login succeeded" as *"the response was a redirect away from `/login`/`/`, and a new session cookie came back"* rather than parsing a body.

### 2.2 Recommended Flutter approach

Use `dio` + `cookie_jar` (`dio_cookie_manager`) so cookie persistence is automatic, same as a browser:

```dart
final cookieJar = PersistCookieJar(storage: FileStorage(appDocsDir.path));
final dio = Dio(BaseOptions(
  baseUrl: 'https://your-taplerr-host',
  followRedirects: false,      // so you can see the 302 and its Set-Cookie yourself
  validateStatus: (code) => code != null && code < 500,
  contentType: Headers.formUrlEncodedContentType,
));
dio.interceptors.add(CookieManager(cookieJar));

Future<bool> login(String email, String password) async {
  final res = await dio.post('/login', data: {'email': email, 'password': password});
  // success = redirected away from /login with a fresh session cookie;
  // the cookie jar already captured it via the interceptor.
  return res.statusCode == 302 && res.headers.value('location') != '/login';
}
```

Everything after login just reuses the same `dio` instance — `CookieManager` attaches the stored session cookie automatically.

**Logout** (`GET /logout`, `AccountController::logout()`) destroys the PHP session and clears the cookie server-side; call it and then drop/clear the local cookie jar too.

### 2.3 CSRF tokens — the other wrinkle

Several state-changing POSTs (`checkout`, `applyPromo` is exempt, `retryPayment`, `cancelOrder`, `confirmReceipt`, `redeemReward`, `markNotificationRead`, `markAllNotificationsRead`, `switchPlan`, `subscribeCheckout`, plus every `/admin/*` mutation) require a `csrf_token` form field, verified by `csrf_verify()` in `app/helpers.php:4-14` against `$_SESSION['csrf_token']`.

The token is only ever emitted as a hidden `<input>` inside server-rendered HTML (`csrf_token()` creates it lazily and every form embeds it via `htmlspecialchars(csrf_token())`). **There is no dedicated JSON endpoint that hands back a CSRF token** — a pure-API mobile client has no clean way to fetch one today. Two options, in order of effort:
1. Fetch the HTML page that contains the form (e.g. `GET /checkout`) and scrape the `csrf_token` value out of the markup with a regex before posting — ugly, but needs zero backend changes.
2. (Backend change, not covered by "don't modify existing code") Add a tiny JSON endpoint that returns `{"csrf_token": csrf_token()}` for authenticated sessions, and reuse the existing `csrf_token()`/`csrf_verify()` helpers as-is.

Login, register, and most profile-editing POSTs do **not** require CSRF today (per `documentation/endpoint-doc.md`, CSRF is only wired up for the order/payment flow, admin mutations, and the two notification "mark read" actions) — those are the easiest to integrate first.

### 2.4 Register

`POST /register` (`AccountController::register()`) — form fields `name`, `email`, `password`, `confirm_password`. Password policy enforced server-side (`validatePassword()`): 8–64 chars, needs upper+lower+digit. No CSRF required. Success → `302 /login` with a flash success message (not in the response body); failure → `302 /register` with `$_SESSION['error']` (same "no JSON body" caveat as login — you'd need to also `GET /register` to read the rendered error text, or just re-validate client-side against the same rules before submitting so failures are rare).

### 2.5 Forgot / reset / change password

- `POST /forgot-password` — field `email`. Always behaves the same regardless of whether the email exists (no account enumeration) — no outbound mail is configured in this app, so the reset link is only ever shown on the page itself, not emailed (see `app/controllers/AccountController.php:633-667` — wait, it does call `sendPasswordResetEmail()` via PHPMailer using `SMTP_*` keys from `config/.env`; whether that actually delivers depends on whether SMTP is configured in this environment). Treat this as "fire and forget" from the app; there's no token returned in the response to deep-link into a Flutter reset screen unless you also build an email-link handler (universal link / deep link into the Flutter app opening `/reset-password?token=...`).
- `POST /reset-password?token=...` — fields `password`, `confirm_password`. Token must be `pending` and unexpired (15 min) in `password_reset_requests`.
- `POST /change-password` (logged in) — fields `current_password`, `new_password`, `confirm_password`. No CSRF.

### 2.6 Delete account

`POST /delete-account` (logged in) with field `confirm_delete` present — soft-deletes (`deleted_at = NOW()`) and destroys the session. Response is a `<script>alert(...)</script>` redirect snippet, not JSON or a clean `Location` header — a Flutter client should just treat any `2xx` here as success and navigate to the login screen itself rather than trying to parse the body.

---

## 3. Endpoints that already return JSON (best candidates for a Flutter client)

These are genuine AJAX endpoints — safe to call with a normal JSON-style mental model (though the *request* body is still form-encoded, not JSON; only the *response* is JSON). All require the session cookie from §2 except where noted.

| Method | Path | Controller → Action | Auth | Request fields | Response |
|---|---|---|---|---|---|
| POST | `/profile/toggle-visibility` | `CardController::toggleVisibility` | ✅ | `field` (one of `show_phone`/`show_email`/`show_social`/`show_address`), `value` | `{"success": bool}` |
| POST | `/profile/update-theme-color` | `CardController::updateThemeColor` | ✅ | `theme_color` (`#RRGGBB`) | `{"success": bool}` |
| POST | `/profile/update-card-layout` | `CardController::updateCardLayout` | ✅ | `card_layout` (`classic`\|`compact`) | `{"success": bool}` |
| POST | `/upload-profile-picture` | `CardController::uploadPicture` | ✅ | `croppedImageData` (data: URL base64), optional `posX`/`posY`/`zoom` for GIFs | `{"success": bool, "path": "/public/img/profiles/..."}` |
| POST | `/upload-banner-picture` | `CardController::uploadBannerPicture` | ✅ | same shape as above | `{"success": bool, "path": "..."}` |
| POST | `/remove-banner-picture` | `CardController::removeBannerPicture` | ✅ | — | `{"success": bool}` |
| POST | `/track-click` | `CardController::trackClick` | ❌ public | `profile_id`, `field` | `{"ok": true}` |
| POST | `/checkout/apply-promo` | `OrderController::applyPromo` | ✅ (needs session cart) | `promo_code` | `{"ok": bool, "discount": num, "total": num}` or `{"ok": false, "message": "..."}` |
| POST | `/cart/update-quantity` | `ShopController::updateQuantity` | — (session cart) | `index`, `quantity` | `{"ok": bool, "line_total", "subtotal", "cart_count"}` |
| POST | `/notifications/mark-read` | `AccountController::markNotificationRead` | ✅ + CSRF | `notification_id`, `csrf_token` | `{"ok": bool}` |

Everything else in the app is either a full HTML page (GET with a view) or a redirect-only action (POST that ends in `header('Location: ...'); exit();`). For those, a Flutter client has two realistic options:
- **Keep using the web views as-is**: wrap the relevant pages in a `WebView` widget inside the app (fastest path, zero backend changes, inherits session/cookie state automatically since it's a real browser engine).
- **Treat redirects as signals**: for simple create/update actions (bind card, approve/reject contact, add manual contact, etc.) a `302` to a success URL vs. an error-flagged URL (many of them encode outcome as `?status=success|error` query params — see §4) is enough to drive native UI without ever parsing HTML, as long as you don't need the data *inside* that HTML back out.

---

## 4. Endpoint catalog for a companion app (grouped by feature)

Everything below is read from the live route table in `index.php` plus each controller's method body — not from the older `documentation/endpoint-doc.md`, which predates several of these routes (notifications, subscriptions, the profile AJAX endpoints) and is stale on its "4 controllers" framing (there are 5 customer-facing controllers today: `AccountController`, `CardController`, `UserController`, `ShopController`, `OrderController`, plus 8 `Admin*Controller` classes for the web-only admin panel, which a customer-facing Flutter app has no reason to call).

### 4.1 Account / session

| Method | Path | Auth | Format | Notes |
|---|---|---|---|---|
| GET/POST | `/login` | — | HTML / redirect | See §2.1 |
| GET | `/logout` | — | redirect | Destroys session |
| GET/POST | `/register` | — | HTML / redirect | See §2.4 |
| GET/POST | `/forgot-password` | — | HTML / redirect | See §2.5 |
| GET/POST | `/reset-password` | — | HTML / redirect | `?token=` |
| GET/POST | `/change-password` | ✅ | HTML / redirect | |
| GET/POST | `/delete-account` | ✅ | HTML / redirect | See §2.6 |
| GET | `/dashboard` (also `/`) | optional | HTML | Home feed — unread count, promo banners, cancel-plan notice if logged in |
| GET | `/notifications` | ✅ | HTML | Last 300 notifications |
| POST | `/notifications/mark-read` | ✅ + CSRF | **JSON** | See §3 |
| POST | `/notifications/mark-all-read` | ✅ + CSRF | redirect | |

### 4.2 Subscription / billing (Stripe-backed)

| Method | Path | Auth | Format | Notes |
|---|---|---|---|---|
| GET | `/subscription` | optional | HTML | Plan comparison; highlights current plan if logged in |
| GET | `/billing` | ✅ | HTML | Current plan + live Stripe subscription/payment-method detail |
| POST | `/subscription/checkout` | ✅ + CSRF | redirect to Stripe | fields `plan_id`, `billing_cycle` (`Monthly`\|`Yearly`) |
| POST | `/subscription/switch` | ✅ + CSRF | redirect | Same fields — switches an existing subscription's price in place |
| GET | `/subscription/success` | ✅ | redirect | Stripe Checkout return, `?session_id=` |
| GET | `/subscription/manage` | ✅ | redirect to Stripe | Opens Stripe's hosted Billing Portal |
| GET | `/subscription/manage-return` | ✅ | redirect | Billing Portal return |

A Flutter client realistically hands the Stripe Checkout/Billing Portal URL returned by the `Location` header to an in-app browser (`url_launcher` / `flutter_stripe`'s webview), same as the web app does — these are Stripe-hosted pages, not something to reimplement natively without swapping to Stripe's mobile SDK + a new server-side PaymentIntent endpoint (a real backend change, out of scope here).

### 4.3 Card / profile (`user_profiles`)

| Method | Path | Auth | Format | Notes |
|---|---|---|---|---|
| GET/POST | `/profile` | ✅ | HTML / redirect | Full profile edit form — see §3 for the piecemeal AJAX alternatives (toggle-visibility, theme-color, card-layout, pictures) which are far more Flutter-friendly than this full-form POST |
| GET | `/card?slug=` | ❌ public | HTML | Public card page |
| GET | `/qr-download?slug=` | ❌ public | PNG stream | |
| GET | `/vcard-download?slug=` | ❌ public | `.vcf` stream | |
| GET | `/analytics` | ✅ | HTML | Card performance + account engagement stats/charts |
| GET | `/public-profile?uid=` | ❌ public | HTML | NFC-tap resolution (`card_hash` → owner), same template as `/card` |
| GET | `/nfc-qr-download?uid=` | ❌ public | PNG stream | |
| GET | `/nfc-vcard-download?uid=` | ❌ public | `.vcf` stream | |
| POST | `/add-contact` | ❌ public (redirects to login if needed) | redirect | fields `uid` or `slug` — "Connect Now" |

### 4.4 NFC card management ("My Cards")

| Method | Path | Auth | Format | Notes |
|---|---|---|---|---|
| GET | `/card-management` | ✅ | HTML | List of the caller's bound NFC cards |
| POST | `/bind-card` | ✅ | redirect `?status=success\|error&action=bind` | fields `serial`, `otp` |
| GET | `/relink?uid=<serial>` | ✅ | redirect `?status=...&action=relink` | Reactivate a card the caller owns |
| GET | `/unlink?uid=<serial>` | ✅ | redirect `?status=...&action=unlink` | Deactivate a card the caller owns |

All three outcomes are query-param-encoded on the redirect target (`status=success|error`, `action=...`, sometimes `error=invalid`) — a Flutter client following the redirect (don't auto-follow in `dio`, read the `Location` header yourself) can drive success/failure UI without parsing any HTML, per §3's second bullet.

### 4.5 Contacts

| Method | Path | Auth | Format | Notes |
|---|---|---|---|---|
| GET | `/contacts` | ✅ | HTML | Mutual + manual contacts, pending requests, stats — all embedded as page JSON today, not a separate JSON endpoint |
| GET | `/contacts/approve?id=` | ✅ | redirect | |
| GET | `/contacts/reject?id=` | ✅ | redirect | |
| POST | `/contacts/manual/add` | ✅ | redirect | fields `contact_name` (required), `position`/`company`/`mobile_number`/`email` (optional) |
| POST | `/contacts/manual/edit` | ✅ | redirect | same fields + id |
| GET | `/contacts/manual/delete?id=` | ✅ | redirect | |
| GET | `/contacts/export` | ✅ | CSV stream | |
| GET | `/contacts/vcard?type=mutual\|manual&id=` | ✅ | `.vcf` stream | |

`/contacts`'s "all contacts as a JSON payload embedded in the HTML" pattern means the actual data **is** JSON server-side before it's serialized into the page — the fastest non-invasive win for Flutter here would be a backend change (a `/contacts.json` or `Accept: application/json` variant reusing the controller's existing query/shaping methods verbatim). Flagging it, not doing it, per your "don't modify existing code" instruction.

### 4.6 Shop: catalog, customization, cart

| Method | Path | Auth | Format | Notes |
|---|---|---|---|---|
| GET | `/products` | ❌ public | HTML | Visible products, cheapest first |
| GET/POST | `/customize` | ❌ public | HTML | `?product_id=` — choose customization method |
| GET/POST | `/customize/basic` | ❌ public | HTML / redirect | Text-overlay add-ons; fields `add_name`/`text_name`, `add_position`/`text_position`, `add_level`/`text_level`; optional `edit_index` to overwrite a cart line |
| GET/POST | `/customize/upload` | ❌ public | HTML / redirect | Multipart file upload (JPEG/PNG/WebP ≤10MB) |
| GET/POST | `/customize/live` | ❌ public | HTML / redirect | Live editor — client text/theme JSON, re-validated server-side |
| GET | `/cart` | ❌ public (session cart) | HTML | |
| GET | `/cart/remove?index=` | ❌ public | redirect | |
| POST | `/cart/update-quantity` | ❌ public | **JSON** | See §3 |

The cart lives entirely in `$_SESSION['cart']` — **not a database table**. That's an important architectural fact for a mobile client: there is nothing to "sync" from a server-side cart API; the cart only exists for the lifetime of the PHP session tied to your cookie. A Flutter app wanting an offline-friendly or cross-device cart would need its own local cart state and only hand it to the server at the point of hitting `/customize/*` (which append-to-cart) or `/checkout`.

### 4.7 Orders / checkout (Stripe)

| Method | Path | Auth | Format | Notes |
|---|---|---|---|---|
| GET/POST | `/checkout` | guest-allowed* | HTML / redirect to Stripe | fields `name`,`email`,`address`,`city`,`state`,`postcode`,`payment_method` (`card`\|`fpx`) + `csrf_token`. See §2.3 for the CSRF-token-acquisition problem. |
| POST | `/checkout/apply-promo` | — | **JSON** | See §3 |
| POST | `/checkout/retry` | ✅ + CSRF | redirect to Stripe | Re-opens a session for a `Pending` order |
| POST | `/checkout/cancel-order` | ✅ + CSRF | redirect | |
| GET | `/order-success` | guest-allowed* | HTML | Stripe's `success_url` |
| GET | `/order-cancel` | guest-allowed* | HTML | Stripe's `cancel_url` |
| GET | `/my-orders` | ✅ | HTML | Tabbed order history |
| GET | `/order-detail?id=` | ✅ | HTML | Single order, status timeline |
| POST | `/order-confirm-receipt` | ✅ + CSRF | redirect | |
| GET/POST | `/track` | ❌ public | HTML | Requires order number **and** email together |
| GET | `/points` | ✅ | HTML | Loyalty points balance + ledger |
| GET | `/rewards` | ✅ | HTML | Rewards catalogue + redemption history |
| POST | `/rewards/redeem` | ✅ + CSRF | redirect | |
| POST | `/webhook` | Stripe-signed, not session | — | Server-to-server only — never call this from the app |

\* these read the session user if present but don't require it (guest checkout is allowed; `order_id` is the access key for a guest's own order).

**Payment itself happens on Stripe's hosted Checkout page** (`Location:` header → `session->url`), same as the website — a native Flutter checkout would mean swapping this for Stripe's `flutter_stripe` SDK + a PaymentIntent-style endpoint, which again is a backend change this doc deliberately isn't making. Short-term, hand the returned Stripe URL to an in-app browser/webview.

### 4.8 Admin (`/admin/*`)

Role-gated (`AdminController::requireAdmin()`), web-only CRUD for managing products/orders/promotions/cards/users/shipping/subscriptions/dev-tools. Out of scope for a customer-facing Flutter app; only worth wiring up if you're also building an admin companion app, in which case every route in `index.php`'s `// ── Admin:` sections applies the same session-cookie + (for mutations) CSRF rules as above.

---

## 5. Summary: what to actually build first

1. **Session-cookie login/logout** (§2.1–§2.2) — the one piece everything else depends on.
2. **Register / forgot-password / change-password** (§2.4–§2.5) — no CSRF, straightforward form posts.
3. **The already-JSON profile/card endpoints** (§3) — toggling visibility, theme color, card layout, photo uploads — these map onto native Flutter UI with zero HTML parsing.
4. **Card management** (§4.4) — bind/relink/unlink, outcome signaled via redirect query params, no HTML parsing needed.
5. Anything requiring reading back structured data that today only exists embedded in server-rendered HTML (`/contacts`, `/my-orders`, `/order-detail`, `/analytics`, `/card-management`, `/notifications`) is the hard part — either scrape the embedded JSON out of the HTML (fragile, breaks if the view markup changes) or, longer-term, ask for a thin JSON-mirror endpoint per page reusing the controller's existing query logic (a real, scoped backend change — not something this read-only doc performs).
6. Payment (checkout, subscriptions) stays Stripe-hosted via webview until/unless the backend grows a mobile-native Stripe integration.
