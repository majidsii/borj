# Liquid Glass kit (Chromium-first, graceful fallback)

Verified in headless Chrome (`--headless=new --disable-gpu`). Proof pages: `iOSToday.png`, `MacToday.png`, `t3.png` (variant sheet).

## How it works
- Lensing: `backdrop-filter: ... url(#lg-s|m|l)`. Each filter builds its own displacement map with **no image at all** (feImage refs and data: URIs do not work for backdrop-filter in Chrome): an opaque `feFlood` fills the filter region, `feGaussianBlur` turns it into a soft bump (alpha ramps 0 to 1 over a few px at the element edge), four `feDiffuseLighting` passes (light from +x, -x, +y, -y at elevation 0) read the bump slope = edge normal, and `feComposite`/`feColorMatrix` pack it into R (x shift) and G (y shift) around 0.5. Centre = flat = 0.5 = zero displacement; the rim bends the backdrop inward. Because the bump comes from the region edge, **one filter works for any size and any border-radius**; sizes `s/m/l` only change rim width and strength (s: buttons up to ~64px, m: bars/cards/rows, l: sidebars/sheets/big panels).
- Chromatic aberration: the SourceGraphic is displaced 3 times with scale x1, x(1+ca), x(1+2ca) and only R, G, B are kept from each, then added back.
- Specular: `::before` is a 1.25px gradient ring (mask-composite exclude) bright top-right (leading edge in RTL) and softer bottom-left, `::after` adds a faint inner sheen, box-shadows add inner glow. Only a 2px/8px drop shadow. To flip the light for LTR pages change `215deg` to `145deg`.
- Fallback: every size class first declares plain `blur() saturate()`, then repeats it with `url(#lg-x)` appended. Browsers that reject url() in backdrop-filter keep the frosted-glass line. Rim light, tint and shadows work everywhere.

## Rules
1. **Nested glass**: a backdrop-filter element becomes a backdrop root, so a `.lg` inside another `.lg` sees only the parent's content, not the page (it renders as a flat white blob). Inside any `.lg` use `.lg-in` (flat tinted fill + rim, no filter). Active tab pill, segmented selected thumb, list rows, the "now" lens in a card: all `.lg-in`.
2. A glass element must have something coloured/detailed behind it (wallpaper, orbs, band). On a flat pale page add soft orbs, or the rim light is all you see.
3. Variant by role: `.lg` (light regular) default for chrome and cards; `.lg-dark` for dark UIs and over bright wallpaper where white text is wanted; `.lg-clear` only over media/vivid art for small controls (add your own text-shadow, white ink); `.lg-tint` only for the single primary action per view (white ink).
4. Anything carrying body text gets `.lg-text` (tint .52 light, .58 dark) on top of the variant. Pure icon buttons may omit it.
5. Text colours on `.lg-text` light: primary `#1B2236` (about 12:1), secondary `#38425E` (4.7:1 worst case measured over the saturated wallpaper in MacToday), link/accent `#1F5FD0`, success `#07665D`. Do not use `#4F5874` or lighter on glass. Finished/disabled text may drop to `#5A6482` (about 3.4:1, intentional). White text only on `.lg-dark`, `.lg-tint`, or `.lg-clear` over dark art; check blob colours (orange wallpaper under white text fails 4.5:1: put a `.lg-dark` tint of .5+ behind it).
6. Pick the size class by element size, not by importance: s <= 64px tall controls, m bars/cards/rows <= ~120px, l big surfaces. Keep `border-radius` large (capsule 99px, cards 24-26px, sheets 36-38px).
7. Keep at most ~8 filtered elements on screen; each is a real-time filter (the three displacement maps make `l` the most expensive).
8. Position: `.lg` sets `position:relative`; inline `position:absolute` wins if you set it.

## SVG filter block (paste once at top of the artboard root)
```html
<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false"><defs>
<filter id="lg-s" x="0" y="0" width="1" height="1" color-interpolation-filters="sRGB">
<feFlood flood-color="#000"/><feGaussianBlur stdDeviation="6" result="h"/>
<feDiffuseLighting in="h" surfaceScale="6" diffuseConstant="1" lighting-color="#fff" result="xp"><feDistantLight azimuth="0" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="6" diffuseConstant="1" lighting-color="#fff" result="xn"><feDistantLight azimuth="180" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="6" diffuseConstant="1" lighting-color="#fff" result="yp"><feDistantLight azimuth="90" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="6" diffuseConstant="1" lighting-color="#fff" result="yn"><feDistantLight azimuth="270" elevation="0"/></feDiffuseLighting>
<feColorMatrix in="xp" values="-1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="ixp"/>
<feComposite in="xn" in2="ixp" operator="arithmetic" k2=".5" k3=".5" result="mx"/>
<feColorMatrix in="mx" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="mxr"/>
<feColorMatrix in="yp" values="0 0 0 0 0 0 -1 0 0 1 0 0 0 0 0 0 0 0 0 1" result="iyp"/>
<feComposite in="yn" in2="iyp" operator="arithmetic" k2=".5" k3=".5" result="my"/>
<feColorMatrix in="my" values="0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1" result="myg"/>
<feComposite in="mxr" in2="myg" operator="arithmetic" k2="1" k3="1" result="map"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="44" xChannelSelector="R" yChannelSelector="G" result="dr"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="50.2" xChannelSelector="R" yChannelSelector="G" result="dg"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="56.3" xChannelSelector="R" yChannelSelector="G" result="db"/>
<feColorMatrix in="dr" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="r"/>
<feColorMatrix in="dg" values="0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1" result="g"/>
<feColorMatrix in="db" values="0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1" result="b"/>
<feComposite in="r" in2="g" operator="arithmetic" k2="1" k3="1" result="rg"/>
<feComposite in="rg" in2="b" operator="arithmetic" k2="1" k3="1"/>
</filter>
<filter id="lg-m" x="0" y="0" width="1" height="1" color-interpolation-filters="sRGB">
<feFlood flood-color="#000"/><feGaussianBlur stdDeviation="9" result="h"/>
<feDiffuseLighting in="h" surfaceScale="9" diffuseConstant="1" lighting-color="#fff" result="xp"><feDistantLight azimuth="0" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="9" diffuseConstant="1" lighting-color="#fff" result="xn"><feDistantLight azimuth="180" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="9" diffuseConstant="1" lighting-color="#fff" result="yp"><feDistantLight azimuth="90" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="9" diffuseConstant="1" lighting-color="#fff" result="yn"><feDistantLight azimuth="270" elevation="0"/></feDiffuseLighting>
<feColorMatrix in="xp" values="-1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="ixp"/>
<feComposite in="xn" in2="ixp" operator="arithmetic" k2=".5" k3=".5" result="mx"/>
<feColorMatrix in="mx" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="mxr"/>
<feColorMatrix in="yp" values="0 0 0 0 0 0 -1 0 0 1 0 0 0 0 0 0 0 0 0 1" result="iyp"/>
<feComposite in="yn" in2="iyp" operator="arithmetic" k2=".5" k3=".5" result="my"/>
<feColorMatrix in="my" values="0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1" result="myg"/>
<feComposite in="mxr" in2="myg" operator="arithmetic" k2="1" k3="1" result="map"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="64" xChannelSelector="R" yChannelSelector="G" result="dr"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="71.7" xChannelSelector="R" yChannelSelector="G" result="dg"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="79.4" xChannelSelector="R" yChannelSelector="G" result="db"/>
<feColorMatrix in="dr" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="r"/>
<feColorMatrix in="dg" values="0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1" result="g"/>
<feColorMatrix in="db" values="0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1" result="b"/>
<feComposite in="r" in2="g" operator="arithmetic" k2="1" k3="1" result="rg"/>
<feComposite in="rg" in2="b" operator="arithmetic" k2="1" k3="1"/>
</filter>
<filter id="lg-l" x="0" y="0" width="1" height="1" color-interpolation-filters="sRGB">
<feFlood flood-color="#000"/><feGaussianBlur stdDeviation="14" result="h"/>
<feDiffuseLighting in="h" surfaceScale="13" diffuseConstant="1" lighting-color="#fff" result="xp"><feDistantLight azimuth="0" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="13" diffuseConstant="1" lighting-color="#fff" result="xn"><feDistantLight azimuth="180" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="13" diffuseConstant="1" lighting-color="#fff" result="yp"><feDistantLight azimuth="90" elevation="0"/></feDiffuseLighting><feDiffuseLighting in="h" surfaceScale="13" diffuseConstant="1" lighting-color="#fff" result="yn"><feDistantLight azimuth="270" elevation="0"/></feDiffuseLighting>
<feColorMatrix in="xp" values="-1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="ixp"/>
<feComposite in="xn" in2="ixp" operator="arithmetic" k2=".5" k3=".5" result="mx"/>
<feColorMatrix in="mx" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="mxr"/>
<feColorMatrix in="yp" values="0 0 0 0 0 0 -1 0 0 1 0 0 0 0 0 0 0 0 0 1" result="iyp"/>
<feComposite in="yn" in2="iyp" operator="arithmetic" k2=".5" k3=".5" result="my"/>
<feColorMatrix in="my" values="0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1" result="myg"/>
<feComposite in="mxr" in2="myg" operator="arithmetic" k2="1" k3="1" result="map"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="90" xChannelSelector="R" yChannelSelector="G" result="dr"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="99.0" xChannelSelector="R" yChannelSelector="G" result="dg"/>
<feDisplacementMap in="SourceGraphic" in2="map" scale="108.0" xChannelSelector="R" yChannelSelector="G" result="db"/>
<feColorMatrix in="dr" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1" result="r"/>
<feColorMatrix in="dg" values="0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1" result="g"/>
<feColorMatrix in="db" values="0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1" result="b"/>
<feComposite in="r" in2="g" operator="arithmetic" k2="1" k3="1" result="rg"/>
<feComposite in="rg" in2="b" operator="arithmetic" k2="1" k3="1"/>
</filter>
</defs></svg>
```

## CSS (paste into `<helmet><style>`)
```css
.lg{position:relative;isolation:isolate;--lg-tint:rgba(255,255,255,.26);--rim-a:.95;--rim-b:.55;--ink:#1B2236;background:var(--lg-tint);color:var(--ink);box-shadow:inset 0 0 0 .5px rgba(255,255,255,.45),inset 0 1px 1px rgba(255,255,255,.55),inset 0 -1px 2px rgba(20,30,80,.10),inset 0 0 14px rgba(255,255,255,.22),0 0 0 .5px rgba(20,30,70,.10),0 2px 8px rgba(20,30,70,.10)}
.lg::before,.lg-in::before{content:"";position:absolute;inset:0;border-radius:inherit;padding:1.25px;pointer-events:none;z-index:2;background:linear-gradient(215deg,rgba(255,255,255,var(--rim-a)) 0%,rgba(255,255,255,.18) 24%,rgba(255,255,255,0) 46%,rgba(255,255,255,0) 58%,rgba(255,255,255,.16) 76%,rgba(255,255,255,var(--rim-b)) 100%);-webkit-mask:linear-gradient(#000 0 0) content-box,linear-gradient(#000 0 0);-webkit-mask-composite:xor;mask:linear-gradient(#000 0 0) content-box exclude,linear-gradient(#000 0 0)}
.lg::after,.lg-in::after{content:"";position:absolute;inset:0;border-radius:inherit;pointer-events:none;z-index:-1;background:radial-gradient(120% 90% at 85% 0%,rgba(255,255,255,.34),rgba(255,255,255,0) 55%),linear-gradient(0deg,rgba(255,255,255,.10),rgba(255,255,255,0) 40%)}
/* size = which displacement filter + blur. plain blur line first = fallback */
.lg-s{-webkit-backdrop-filter:blur(5px) saturate(1.7) brightness(1.04);backdrop-filter:blur(5px) saturate(1.7) brightness(1.04);backdrop-filter:blur(5px) saturate(1.7) brightness(1.04) url(#lg-s)}
.lg-m{-webkit-backdrop-filter:blur(8px) saturate(1.7) brightness(1.04);backdrop-filter:blur(8px) saturate(1.7) brightness(1.04);backdrop-filter:blur(8px) saturate(1.7) brightness(1.04) url(#lg-m)}
.lg-l{-webkit-backdrop-filter:blur(12px) saturate(1.7) brightness(1.04);backdrop-filter:blur(12px) saturate(1.7) brightness(1.04);backdrop-filter:blur(12px) saturate(1.7) brightness(1.04) url(#lg-l)}
.lg-clear.lg-s{-webkit-backdrop-filter:blur(1px) saturate(1.3);backdrop-filter:blur(1px) saturate(1.3);backdrop-filter:blur(1px) saturate(1.3) url(#lg-s)}
.lg-clear.lg-m{-webkit-backdrop-filter:blur(2px) saturate(1.3);backdrop-filter:blur(2px) saturate(1.3);backdrop-filter:blur(2px) saturate(1.3) url(#lg-m)}
.lg-clear.lg-l{-webkit-backdrop-filter:blur(3px) saturate(1.3);backdrop-filter:blur(3px) saturate(1.3);backdrop-filter:blur(3px) saturate(1.3) url(#lg-l)}
.lg-clear{--lg-tint:rgba(255,255,255,.07);--rim-a:1;--rim-b:.7;box-shadow:inset 0 0 0 .5px rgba(255,255,255,.35),inset 0 0 16px rgba(255,255,255,.14),0 2px 10px rgba(10,15,40,.18)}
.lg-dark{--lg-tint:rgba(24,28,44,.38);--rim-a:.55;--rim-b:.28;--ink:#F4F6FC;box-shadow:inset 0 0 0 .5px rgba(255,255,255,.14),inset 0 1px 1px rgba(255,255,255,.18),inset 0 0 16px rgba(255,255,255,.05),0 0 0 .5px rgba(0,0,0,.45),0 2px 10px rgba(0,0,0,.28)}
.lg-dark::after{background:radial-gradient(120% 90% at 85% 0%,rgba(255,255,255,.12),rgba(255,255,255,0) 55%)}
.lg-tint{--lg-tint:rgba(47,111,219,.66);--rim-a:.95;--rim-b:.5;--ink:#fff;box-shadow:inset 0 0 0 .5px rgba(255,255,255,.35),inset 0 1px 1px rgba(255,255,255,.5),inset 0 0 14px rgba(160,200,255,.30),0 0 0 .5px rgba(20,50,140,.35),0 4px 12px rgba(47,111,219,.30)}
/* flat glass: for use INSIDE another glass element (nested backdrop-filter cannot see the page) */
.lg-in{--rim-a:.9;--rim-b:.5;position:relative;isolation:isolate;background:rgba(255,255,255,.34);color:var(--ink,#1B2236);box-shadow:inset 0 0 0 .5px rgba(255,255,255,.55),inset 0 1px 1px rgba(255,255,255,.7),inset 0 -1px 2px rgba(20,30,80,.08),0 0 0 .5px rgba(20,30,70,.08)}
.lg-dark .lg-in,.lg-in.lg-dark{background:rgba(255,255,255,.08);box-shadow:inset 0 0 0 .5px rgba(255,255,255,.12),inset 0 1px 1px rgba(255,255,255,.2),0 0 0 .5px rgba(0,0,0,.35)}
/* legibility: text-bearing glass gets a stronger tint */
.lg-text{--lg-tint:rgba(255,255,255,.52)}
.lg-dark.lg-text{--lg-tint:rgba(18,22,38,.58)}
.lg-in.lg-lens{background:rgba(255,255,255,.16);box-shadow:inset 0 0 0 .5px rgba(255,255,255,.7),inset 0 0 12px rgba(255,255,255,.35),0 4px 12px rgba(20,30,80,.22)}
.lg-dark .lg-in::before,.lg-in.lg-dark::before{--rim-a:.5;--rim-b:.25}
```

## Usage
```html
<!-- primary action: tinted circle button -->
<button class="lg lg-s lg-tint" aria-label="Add" style="width:44px;height:44px;border:0;border-radius:50%;display:grid;place-items:center">+</button>

<!-- circle button, regular -->
<button class="lg lg-s lg-text" aria-label="Search" style="width:64px;height:64px;border:0;border-radius:50%;display:grid;place-items:center">...</button>

<!-- capsule button / label -->
<button class="lg lg-s lg-text" style="height:40px;padding:0 18px;border:0;border-radius:99px;font:inherit;font-weight:700">Today</button>

<!-- tab bar: glass capsule, active tab is a flat inner pill -->
<nav class="lg lg-m lg-text" style="display:flex;padding:4px;border-radius:99px">
  <a class="lg-in" style="flex:1;height:56px;border-radius:99px;color:#1F5FD0;...">Today</a>
  <a style="flex:1;height:56px;color:#1B2236;...">Tasks</a>
</nav>

<!-- segmented control -->
<div class="lg lg-s lg-text" role="group" style="display:flex;padding:3px;border-radius:99px">
  <button class="lg-in" aria-pressed="true" style="height:34px;border:0;border-radius:99px;...">List</button>
  <button aria-pressed="false" style="height:34px;border:0;background:transparent;...">Board</button>
</div>

<!-- sidebar panel -->
<nav class="lg lg-l lg-text" style="width:236px;border-radius:20px;padding:14px 10px">
  <a class="lg-in" style="height:36px;border-radius:12px;...">Today</a> ...
</nav>

<!-- bottom sheet (dark variant works the same) -->
<div role="dialog" class="lg lg-l lg-text" style="position:absolute;inset-inline:8px;bottom:8px;border-radius:38px;padding:8px 16px 18px">
  <div style="width:38px;height:5px;border-radius:3px;background:rgba(20,30,60,.22);margin:0 auto"></div> ...
</div>

<!-- glass card / list container (text-legible) with glass rows inside -->
<section class="lg lg-l lg-text" style="border-radius:26px;padding:8px">
  <label class="lg-in" style="display:flex;align-items:center;gap:12px;min-height:54px;padding:0 12px;border-radius:18px;margin-bottom:6px">
    <input type="checkbox"><span style="flex:1">Task title</span><span style="color:#38425E;font-size:12px">15:00</span>
  </label>
</section>
<!-- or hairline rows: border-bottom:.5px solid rgba(27,34,54,.14) inside a plain .lg card -->

<!-- single stat card -->
<section class="lg lg-m lg-text" style="border-radius:26px;padding:16px">...</section>

<!-- lens / "now" marker inside a card -->
<div class="lg-in lg-lens" style="position:absolute;top:-6px;bottom:-6px;width:64px;border-radius:24px"></div>

<!-- clear glass over media -->
<button class="lg lg-s lg-clear" style="color:#fff;text-shadow:0 1px 6px rgba(0,0,40,.45);...">...</button>

<!-- dark glass -->
<div class="lg lg-m lg-dark lg-text" style="border-radius:26px;padding:16px">...</div>
```

## What does and does not render (headless Chrome, SwiftShader)
- Works: url() in backdrop-filter, feDiffuseLighting-derived map, 3x displacement + channel recombine, mask-composite rim rings, conic/linear gradients.
- Does not work: `feImage` pointing at an in-document element (`href="#id"`) inside a backdrop-filter returns an empty image (whole glass goes transparent); `data:` URIs are forbidden by the target format anyway.
- Lensing is intentionally subtle under `.lg-text` panels (blur 8-12px plus a .52 white tint hides most of it); it is clearest on `.lg-clear` and small circles over high-contrast art.
- Edge pixels sample from inside the element only (backdrop-filter cannot read outside the border box), so the rim magnifies inward rather than bending outside content in, a close but not identical match to Apple's thick-glass look.
- Not verified: Safari/Firefox (should show the frosted fallback; Safari may also ignore the url() declaration), real GPU compositing speed, high-DPR at 2x for the macOS page (iOS page was shot at 2x and looks the same).
