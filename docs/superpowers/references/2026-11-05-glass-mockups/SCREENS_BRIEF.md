# Brief: all app screens in the approved Liquid Glass style

Owner-approved style = these two boards (read them fully; copy their structure, kit usage, colours, type, spacing):
- iPhone: /tmp/claude-1000/-home-shabin-projects-personal-dashboard-shakhsi-v2-integration/31ac1c0f-429c-4329-8ebd-6f4412ed7abc/scratchpad/allscreens/project/Main.dc.html (390x844)
- Mac:    /tmp/claude-1000/-home-shabin-projects-personal-dashboard-shakhsi-v2-integration/31ac1c0f-429c-4329-8ebd-6f4412ed7abc/scratchpad/allscreens/project/MacToday.dc.html (1440x900 fluid page)
Glass kit (MUST use, copy its <svg> filter block + classes into each file): /tmp/claude-1000/-home-shabin-projects-personal-dashboard-shakhsi-v2-integration/31ac1c0f-429c-4329-8ebd-6f4412ed7abc/scratchpad/glasskit/KIT.md
Also a dark reference (old style, use only for dark-mode mood): /tmp/claude-1000/-home-shabin-projects-personal-dashboard-shakhsi-v2-integration/31ac1c0f-429c-4329-8ebd-6f4412ed7abc/scratchpad/ref/project/MacFinance.dc.html and ref/project/iOSHabits.dc.html

Owner rules: EVERY element is Liquid Glass (cards, rows, chips, buttons, bars, sheets) over a colourful background (soft orbs/band behind, as in the references) — except that nothing glass sits inside glass: inner rows/thumbs/lenses use the kit's flat `.lg-in`. Persian RTL, Jalali dates, Persian digits, «٬» separators, Toman. iOS 27 / macOS 27 conventions: iPhone floating glass tab bar (امروز / کارها / مالی / عادت‌ها + separate search circle), large titles, glass circular toolbar buttons, sheets inset from edges; Mac: sidebar at the RIGHT (same sidebar as MacToday, with the current section selected), glass toolbar capsules at top, inspector pane at the LEFT when useful. Make each screen genuinely useful and realistic; not a copy of the Today layout.

## Format (fails silently if broken)
Same skeleton as the references: `<html lang="fa" dir="rtl">`, the `<script src="./support.js"></script>` head line EXACTLY, `<x-dc>` + `<helmet>` (one Google Fonts link + style), `<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":W,"height":H}}'>` with `class Component extends DCLogic { renderVals() {...} }`. Close every element, quote every attribute. No data: URIs, no external files, no emoji, no iframes. `{{hole}}` only dotted lookups; never `style="{{x}}"` (interpolate inside a literal style instead). Phone root FIXED 390x844 overflow hidden; Mac root fluid (min-height:100vh; window max-width ~1320px) and wraps at phone width. Real <button>/<a>/<input>+<label>; aria-label on icon buttons; text ≥4.5:1.
Links: phone tab-bar items may link to the phone boards of other sections by file name (e.g. href="Main.dc.html" for امروز, "PhoneTasks.dc.html", "PhoneMoney.dc.html", "PhoneHabits.dc.html").

## Verify by looking (required)
For each file, make a temporary plain-HTML copy (strip/expand template holes) in /tmp/claude-1000/-home-shabin-projects-personal-dashboard-shakhsi-v2-integration/31ac1c0f-429c-4329-8ebd-6f4412ed7abc/scratchpad/shots/ and screenshot with `google-chrome --headless=new --screenshot=<png> --window-size=390,844` (Mac: 1440,900), Read the PNG, fix overlaps/clipping/contrast. Max 3 rounds per file. Do not ship the temp copies.

## Sample data (synthetic)
Today چهارشنبه ۱۳ آبان ۱۴۰۵ (4 Nov 2026), now 14:30. Week starts Saturday. 1 Aban 1405 is a Friday; 30 days.
Tasks: ورزش صبح 07:00 done; پرداخت قسط وام 09:30 done; جلسه با تیم طراحی 15:00 (reminder 15 min, list کار, in progress); تمدید بیمهٔ ماشین 18:00 (list خانه); خرید هدیهٔ تولد مریم (no time, شخصی); overdue تعویض روغن ماشین (since 10 Aban). Lists: کار 14, خانه 8, شخصی 6; 24 open. Kanban: برنامه‌ریزی‌شده / در حال انجام / انجام‌شده / لغوشده. Timer running: «طراحی صفحهٔ اصلی» 00:42:10. Templates: پرداخت قبض (monthly, reminder), تماس کاری (30 min), خرید خانه (weekly).
Accounts: کارت ملت ۲۱٬۴۰۰٬۰۰۰ ; پس‌انداز ۳۱٬۰۰۰٬۰۰۰ ; نقد ۱٬۲۰۰٬۰۰۰. Aban budget ۲۰٬۰۰۰٬۰۰۰, spent ۱۲٬۴۵۰٬۰۰۰ (62%), left ۷٬۵۵۰٬۰۰۰, 17 days left.
By category: خوراک ۴٬۷۳۰٬۰۰۰ (38%) of 6.5M; مسکن ۴٬۲۳۰٬۰۰۰ (34%) of 4.3M; رفت‌وآمد ۱٬۹۹۰٬۰۰۰ (16%) of 3M; سایر ۱٬۴۹۰٬۰۰۰ (12%).
Monthly spend (M): خرداد 10.2, تیر 11.8, مرداد 9.6, شهریور 13.1, مهر 12.0, آبان-to-date 12.4; forecast 19.1.
Transactions: 13 Aban ناهار با علی −۴۵۰٬۰۰۰ (خوراک, کارت ملت); 13 Aban قسط وام مسکن −۴٬۲۰۰٬۰۰۰ (مسکن); 12 Aban اسنپ −۱۸۵٬۰۰۰ (رفت‌وآمد, نقد); 11 Aban سوپرمارکت −۸۴۰٬۰۰۰ (خوراک); 1 Aban حقوق آبان +۳۸٬۰۰۰٬۰۰۰ (درآمد).
Installment: وام مسکن 25 of 60, ۴٬۲۰۰٬۰۰۰ due 10 آذر. Debts: طلب از رضا ۲٬۰۰۰٬۰۰۰ (he owes me); بدهی به سارا ۵۰۰٬۰۰۰ (I owe).
Habits: پیاده‌روی 12-day streak (done today); کتاب ۱۵ از ۲۰ دقیقه; آب ۴ از ۸ لیوان; مدیتیشن (missed yesterday).
Goals: پس‌انداز سفر نوروز ۳۱ از ۵۰ میلیون (62%), 137 days left; خواندن ۲۴ کتاب در سال ۱۴ از ۲۴; دویدن ۱۰ کیلومتر (milestones 5k ✓, 7k ✓, 10k).

Final message: the file paths, one line per screen on what it shows, and the screenshot paths you looked at.
