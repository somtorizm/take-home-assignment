# Submission — Ezinwa Victor — Mobile

**Video walkthrough:** <!-- TODO: paste unlisted Loom / YouTube link -->
**Time spent:** ~3 hours hands-on: ~30 min reading the code and fixing setup/pre-existing bugs, ~1 h backend (model, endpoints, checkout, tests), ~1.5 h React Native (cart UI, context, order history, tests). Notes and video not included.
**AI tools used:** Grok Bot (AI coding agent) for implementation and tests; see `PROMPTS.md`.

## How to run what I added

```bash
# Backend (Ruby 3.2.2)
cd backend
bundle install
bin/rails db:migrate db:seed
bin/rails test              # 25 tests: model + integration
bin/rails server -b 0.0.0.0

# Mobile
cd mobile
npm install
cp .env.example .env
npx tsc --noEmit && npm run lint && npm test   # 16 tests
npx react-native run-ios    # or run-android
```

Log in as `test@example.com` / `password123` (the seeded cart already has items), open **Cart**, enter a code, then **Checkout** and look at **Orders**.

API added:

| Method | Path | Body | Notes |
| --- | --- | --- | --- |
| `POST` | `/api/cart/promo_code` | `{ "code": "welcome10" }` | Applies (or replaces) the cart's code. 422 with `{ error, reason }` if invalid. |
| `DELETE` | `/api/cart/promo_code` | | Removes it. |
| `GET` | `/api/cart` | | Now returns `subtotal`, `discount`, `total`, `promo_code`, `promo_notice`. |
| `POST` | `/api/orders` | `{ "promo_code": "WELCOME10" }` (optional) | Revalidates the code, stores the breakdown and a snapshot. |
| `GET` | `/api/orders` | | Each order has `subtotal_amount`, `discount_amount`, `total_amount`, `promo_code`. |

## Promo codes to try

| Code | What it does |
| --- | --- |
| `WELCOME10` | 10% off |
| `SAVE5` | $5 off |
| `HALFOFF` | 50% off, ends in 30 days |
| `BIGSAVER` | $500 off. Bigger than any cart, so it shows the discount is capped and the total stops at $0.00 |
| `EXPIRED` | Expired yesterday: "The code "EXPIRED" expired on …" |
| `DISABLED` | Switched off by marketing: "…is no longer available." |
| `COMINGSOON` | Starts in 7 days: "…isn't active yet." |
| `anything else` | "We couldn't find the code …" |

Codes are case-insensitive and whitespace is trimmed (`welcome10` works). Marketing can switch a code off from the console today:
`bin/rails runner "PromoCode.find_by_code('save5').update!(active: false)"`

## Decisions and assumptions

- **The server owns the money math.** The app never calculates a discount. It shows `subtotal`/`discount`/`total` from the API. That gives one source of truth, the client can't be tampered with to get a better price, and rules can change without an app release.
- **The code lives on the cart, not just in the app's memory.** `carts.promo_code_id` keeps the code across app restarts and devices, and the discount recalculates when quantities change (a percent code on a bigger cart gives a bigger discount).
- **One code per order: applying a new code replaces the old one** instead of showing an error. That's the common pattern in shopping apps, and it's less frustrating than "remove your code first".
- **Revalidate at checkout.** A code can expire or be switched off between applying it and paying. In that case the order is **not** placed. The code is removed and the app shows the reason and reloads the cart, so the shopper sees the new total before paying it. I chose not to silently charge full price.
- **Checkout sends the code the shopper saw.** If it doesn't match the cart's code (for example, changed on another device), the API returns 409 and the app asks the shopper to review. The rule: never charge a price that wasn't on screen.
- **Stale codes on the cart are dropped with an explanation.** `GET /cart` removes a code that has since become invalid and returns `promo_notice`, which the app shows as an alert.
- **Orders snapshot what was paid.** Orders store `subtotal_amount`, `discount_amount`, `total_amount`, plus `promo_code_snapshot`/`promo_discount_type`/`promo_value`. If marketing edits or disables the code later, history still shows what the shopper actually paid. Old orders are backfilled with `subtotal = total` and no discount.
- **Fixed discounts are capped at the subtotal.** The total never goes negative, and $0 orders are allowed (the `total_amount > 0` validation became `>= 0`). Percent codes must be 0–100. Discounts are rounded half-up to cents with BigDecimal.
- **Discounts apply to the product subtotal only.** There's no tax or shipping in the app today.
- **Error messages are written for shoppers and come from the server**, along with a machine-readable `reason` (`not_found`, `expired`, `inactive`, `not_started`, `blank`, `empty_cart`, `promo_invalid`, `promo_mismatch`). The UI shows the message inline under the field and clears it as soon as the shopper starts typing again.
- **Codes are stored upper-cased** with a unique index, so case-insensitive uniqueness is enforced by the database, not just by a validation.
- **"A way to try out codes" = seeds plus console**, rather than an admin UI. That was the right size for the timebox.
- **No per-user or total usage limits** (e.g. "first order only", "one use per customer"). WELCOME10 can be reused. This is the first thing I'd add (see below).

### Pre-existing issues I found and fixed

1. **`GET /api/orders` was broken.** `render json: orders.map do … end` binds the `do` block to `render`, not `map`, so the serializer never ran. Order history couldn't work.
2. **Test fixtures were invalid.** Both users had the email `MyString`, which violates the unique index, and orders had status `MyString`, which fails the inclusion validation. Every test run errored when loading fixtures.
3. **Checkout wasn't atomic.** Order, items and stock changes weren't in a transaction, `OrderItem.create` failures were ignored, and stock wasn't rechecked, so a half-created order or negative stock was possible. It now runs in a transaction with row locks.
4. **Money was summed as Float** in `Cart#total`. It's now BigDecimal.
5. **Seeds:** delete order violated foreign keys on re-seed, and the sample order's `total_amount` (89.97) didn't match its items (98.98).
6. **Mobile cart quantity updates were fire-and-forget.** Line subtotals and the total weren't updated, and server errors (e.g. "exceeds available stock") were swallowed, so the UI could show a quantity the server had rejected. The update now re-syncs from the server and rolls back with an alert on failure.
7. **The cart footer was `position: absolute`.** It covered the last list items, and with a text field it would sit under the keyboard. It's now a normal flex child inside a `KeyboardAvoidingView`.
8. **Jest didn't run at all.** `@react-navigation` wasn't transformed and AsyncStorage wasn't mocked.
9. **The token check on launch called `/products`, which is public**, so an expired token was treated as valid. It now calls `/cart`.
10. **10 ESLint errors** (unused imports/vars). Fixed, and 3 pre-existing warnings remain. Also: there was no way to reach Order History except right after checkout, so I added an "Orders" header button.

Not fixed (noted): after a restart, `AuthContext` sets a placeholder user (`user@example.com`) because there's no `/me` endpoint. The many `console.log`s in `api.ts` should be removed for production.

## What I didn't get to, and what I'd do next

1. **Usage limits:** `max_redemptions`, per-user limits and "first order only" (needed for a real welcome code), with a `promo_redemptions` table and checks inside the checkout transaction.
2. **Marketing admin:** an authenticated admin API/UI (or ActiveAdmin) to create, schedule and disable codes, plus an audit trail.
3. **Minimum order amount** and product/category restrictions.
4. **Abuse protection:** rate-limit `POST /cart/promo_code` (e.g. Rack::Attack) to stop code guessing.
5. **Prices in integer cents** end to end, and a proper serializer layer.
6. **Mobile:** React Native Testing Library and an end-to-end Detox test of apply → checkout → history. Better loading/skeleton states. Deep links that pre-fill a code (`app://cart?promo=WELCOME10`).
7. **Analytics:** track apply attempts, failure reasons and conversion per code for marketing.
8. **Quote/version check at checkout:** checkout already rejects a promo code that differs from the one shown (409) or has become invalid, but it doesn't yet reject a cart whose *items* changed (e.g. from another device) between viewing and paying; the server recalculates instead. Next step: return a `quote_version` (or cart `updated_at`) with every cart response, send it at checkout, and return 409 with the fresh cart when it doesn't match.

Verification: backend `bin/rails test` (25 tests, 0 failures); mobile `tsc`, ESLint and Jest (16 tests); and a manual end-to-end run on a physical Android device (Pixel 8 Pro) covering every seeded code, replacing/removing codes, quantity changes, checkout and order history. iOS was not run.
