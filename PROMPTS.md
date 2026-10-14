# PROMPTS.md — AI Usage

**Candidate:** Ezinwa Victor  
**Role:** Mobile Engineer — React Native  
**AI assistant:** Grok Bot  
**Development environment:** VS Code / IntelliJ IDEA, Android SDK, Pixel 8 Pro

## How I used AI

I used AI to accelerate the initial implementation, explain unfamiliar code, and help debug integration issues. I reviewed the generated changes and worked through the React Native implementation step by step rather than accepting the first pass unchanged. I remained responsible for the implementation decisions and for checking the feature in the running application.

The assignment README was the source of the product requirements. Where it left implementation details open, I made decisions based on the existing codebase and the need to keep pricing authoritative on the server, preserve existing behavior, and deliver the mobile flow end to end.

## Main implementation prompt

The following is the main prompt I used for the first implementation pass:

> Implement the promo codes feature per the README brief, Mobile role focus (RN feature end to end). Backend: PromoCode model (case-insensitive unique code, percent|fixed, value, expires_at, active), cart apply/remove endpoints, discount computed server-side, one code per order, order stores a subtotal/discount/total/code snapshot, fixed discount capped at subtotal, revalidate at checkout. Seed WELCOME10, SAVE5, EXPIRED, DISABLED. Mobile: promo input on the cart screen, apply/remove, clear errors, show discount + new total, checkout sends the code, order history shows the discount. Write tests at both layers and run tsc/lint/jest. Commit in small logical commits and write SUBMISSION.md.

I treated this as an initial scope prompt, not a substitute for reviewing the existing implementation or verifying the result.

## Follow-up prompts and examples

These are representative prompts and requests from the development process:

| Prompt or request | Purpose |
| --- | --- |
| "can we walk through the code base as a pair" | I shifted to a step-by-step workflow for the React Native changes, reviewing the code as we worked. |
| "can we implement a helper extension that can help map api response to easy ui consumable data" | More directive to helper simply the mappers. |
| "Property 'isFinite' does not exist on type 'NumberConstructor'…" seems like a dependecy error | Investigated a TypeScript error; the issue was missing installed dependencies, and installing them resolved it without a source-code change. |
| "product: { ...item.product, price: toNumber(...) }, what do we mean here?" do we  | Asked for an explanation of the nested spread and price normalization so I could understand the change. |
| "what does cartcontext do its it like a viewmodel in android" | Connected the existing React Native state-management pattern to Android ViewModel concepts to clarify state ownership. |
| "Put the full CartContext back" | Corrected an overly broad edit to `CartContext.tsx` and reinforced the need to preserve existing code. |
| "let use my device for android" | Set up Android device testing with `adb reverse` and a Pixel 8 Pro. |
| "am getting this error trying to apply a discount: That code couldnt be applied" | Investigated a backend integration issue and identified an older Rails server still using port 3000. |
| "cannot connect to server" | Moved long-running processes into my own terminal after they stopped with the AI agent's shell session. |

## Engineering decisions and review

After the initial implementation, I wrote a stricter review brief to assess the result against the assignment and production-minded engineering considerations. This was a later review prompt, not the prompt that initiated the first implementation.

The main review criteria were:

- Follow the existing React Native and Rails architecture; avoid unnecessary rewrites and dependencies.
- Keep promo validation and discount calculation on the server.
- Keep the API contract consistent across backend, mobile client, and tests.
- Support applying, replacing, and removing a code with clear loading and error states.
- Revalidate promo eligibility at checkout and avoid silently changing the amount presented to the customer.
- Preserve the pricing snapshot for completed orders so history reflects the original transaction.
- Test relevant success and failure cases using the project's existing tools.
- Verify the end-to-end experience on a device or emulator and review the final diff for unintended changes.

These are review criteria. They should not be read as a claim that every edge case was implemented or tested.

## What I learned

- Inspect the current code and Git status before editing; prefer focused patches over replacing whole files.
- Agree on the API contract before wiring up the mobile experience.
- Keep long-running services in a persistent terminal when device testing depends on them.
- Treat a successful build or isolated test as one signal, not proof that the entire user journey works.
- Verify the actual behavior and report test results and limitations accurately.

## Verification note

I used TypeScript, Jest, `curl`, and a Pixel 8 Pro during development. The exact commands, outcomes, and tested scenarios should be documented in `SUBMISSION.md` based on the final repository state. Do not interpret this list of tools as a claim that every check or every edge case passed.

## Summary

AI helped with the initial implementation, explanations, and debugging. I reviewed and adjusted the generated work, improved the workflow when broad edits caused problems, and took responsibility for verifying the mobile experience. My goal was to use AI as a pair-programming aid while retaining ownership of the code and engineering decisions.
