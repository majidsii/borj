# Product name: Borj (برج)

Date: 2026-11-06. Status: **approved by the owner**. Roadmap §0 item 3, part C.

## Decision

The v2 product is named **برج** (Latin: **Borj**). It replaces the working name
"Dashboard Shakhsi" (داشبورد شخصی).

## Story

A tower (برج) rises brick by brick, the way a life is built one day, one task,
one saving at a time. In everyday Iranian speech برج also means a Jalali month
("سر برج": the start of the month, when rent is paid and salaries arrive), so the
name ties directly to the app's Jalali calendar and its finance side. The second
meaning only lands for Persian speakers, which makes the name ours.

Tagline candidate: «هر روز یک آجر، هر ماه یک برج» ("one brick a day, one borj a month").

## Brief the name was chosen against

- Persian word, also readable in Latin script.
- Audience: Persian speakers in general (GitHub and store users).
- First round asked for "calm and warm"; after it, the owner chose "short, one
  syllable, the story of building little by little; a solid sound is fine".
- Availability that matters: GitHub, a domain, Telegram and social handles.

## Process

Done with the `naming` skill (github.com/glacierphonk/naming, installed in
`~/.claude/skills/naming`): brief, metaphor territories, about 40 internal
candidates, anti-pattern filter, competitor search, availability, scoring.

Round 1 finalists, all rejected by the owner: ارسی (Orosi; pronunciation),
کندو (Kandoo), خشت (Khesht; liked best for brevity and story, but harsh sound).
Round 2 finalists: **برج**, گام (Gaam), پله (Pelleh). The owner picked برج.

Dropped for direct same-category competitors on Cafe Bazaar or elsewhere:
سررسید (two planner apps), میرزا (personal ledger app), روزنگار (calendar app),
فانوس (several apps incl. a messenger), انار (Persian-language stores).
Dropped for connotation: دیوان (courts, bureaucracy).

## Availability (checked 2026-11-06)

Method: RDAP via rdap.org for domains (404 = not registered), HTTP status for
GitHub orgs, public page for Telegram.

- No app named برج/Borj found in Persian stores or the App Store.
- `borj.app`: not registered. `getborj.com`: not registered.
- Telegram `@borjapp`: no public page (probably free; confirm in the app).
- Taken: `borj.dev`, `borjapp.com`, GitHub orgs `borj` and `borjapp`.
- Not verified: `.ir` domains (rdap.org has no `.ir` service) and trademarks.

Risk: Arabic "burj" (towers such as Burj Khalifa) crowds Latin-script search.

## Follow-ups (not done here)

- Apply the name: application ID, Linux binary and desktop entry, window title,
  data directory, Android package. Roadmap noted that the app ID and data paths
  depend on the name; v2's own data path changes, while the v1 importer must keep
  reading v1's `dashboard-shakhsi` path. Needs its own spec and plan.
- Register `borj.app` and the Telegram handle if wanted (owner action).
- Logo: next step, with the `logo-design` skill.
