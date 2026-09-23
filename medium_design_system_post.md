# How I Built a Referenceable, Accessible Design System With AI — Before Writing a Single Screen

*A solo product manager's playbook for turning a finished product spec into a design system that Claude Code can read, obey, and build against — with accessibility baked into the foundation, not bolted on at the end.*

---

I'm building FinPat as a one-person product team. FinPat is a mobile app for people who financially support family in another country — it tracks the obligations you owe, the remittances you send, and the savings you're trying to grow, all across a dozen currencies. I'm the PM, the designer, and the person typing the prompts. Flutter on the front end, Supabase on the back, Android first.

The thing nobody tells you about building solo with AI is that *consistency is the first thing to break*. You prompt "build me the dashboard," you get a beautiful teal card. Two days later you prompt "build the savings screen," and now you've got a slightly different teal, a different corner radius, and a button that's 6 pixels shorter for no reason. Multiply that across fifteen screens and you don't have a product — you have fifteen prototypes that happen to share a repo.

The second thing that breaks, and the one almost nobody catches early, is **accessibility**. Most PMs and designers treat it as a compliance chore for the end of the project — a screen-reader pass you do the week before launch, if at all. That's backwards, and it misunderstands what accessibility actually is.

Accessibility is not a favor you do for disabled users. It's a usability lens that makes the product better for *everyone*. This is the well-documented "curb-cut effect": the sloped curb built for wheelchairs also helps the parent with a stroller, the traveler with a suitcase, the delivery worker with a cart. In UI it's the same. A tap target big enough for someone with a motor impairment is also the target nobody mis-taps while walking. Contrast high enough for low vision is also the text you can actually read in direct sunlight on a cheap screen. A layout that respects the system font size for a low-vision user is also the layout that doesn't clip for the person who simply prefers bigger text. Build for the edge, and the middle gets better for free.

That matters even more once you remember what "mobile" really means. There is no single phone. There are hundreds of Android device types across a huge range of screen sizes, pixel densities, aspect ratios, and OS versions — flagships and $80 handsets side by side. A design that only looks right on the simulator you happened to use is fragile. The exact disciplines accessibility forces on you — relative spacing instead of magic pixel values, respecting the user's system text scale, sufficient contrast, generous touch targets, semantic structure instead of hardcoded layout — are precisely the disciplines that make a UI *survive that fragmentation*. Accessibility and device resilience are the same engineering problem wearing two hats.

And for a finance app the stakes are real. The people who most need to send money home reliably include older parents, people on cheap devices with the font size cranked up, and people navigating with a screen reader. If your app renders a balance as a color-coded number a screen reader announces as a meaningless string of digits — or a layout that breaks the moment someone bumps their font size — you haven't shipped a finance feature. You've shipped a barrier.

So before I let AI build a single production screen, I built the design system first. Not in Figma — in the repo, as documentation an AI could treat as law, with accessibility written into the rules themselves.

Here's exactly how I did it.

## Step 1: Finalize the spec, then freeze the design language — with accessibility as a principle

I only started this after the product spec was locked. A design system built on a moving product is just decoration. Once I had clarity on *what* FinPat does, I could ask the harder question: what should it consistently *feel* like, and who has to be able to use it?

I wrote that down as a single markdown file, `specs/01-design-system.md`. It opens with principles, not colors — and accessibility is one of them, sitting right next to "clarity":

> - **Clarity first:** financial information should be scannable in under 3 seconds.
> - **Progress over perfection:** highlight what to do next, not only current totals.
> - **Calm confidence:** avoid alarmist visuals unless the user is at risk.
> - **Accessibility by default:** readable typography, sufficient contrast, clear states.

And it closes with a hard accessibility contract that the rest of the system has to satisfy:

> - Color contrast: WCAG-compliant for text and controls.
> - Keyboard / assistive support for all actions.
> - Semantic labels for all inputs and icons.
> - **Do not rely only on color to indicate status.**

That last line is the one PMs forget. Roughly 1 in 12 men has some form of color vision deficiency. If "overdue" is just red and "on track" is just green, a meaningful chunk of your users can't tell them apart. Writing that rule into the constitution means every downstream example has to answer to it.

## Step 2: Compile the human spec into machine tokens — including accessibility constants

A principles document is great for a human and useless to a compiler. So the second layer translates the prose into hard values the framework consumes. In FinPat that's two Dart files.

`core/theme/ui_tokens.dart` turns "use an 8px spacing system" and "minimum 44×44 tap target" into non-negotiable constants. Accessibility isn't a separate file here — it lives inside the same tokens everything else uses:

```dart
class UiTokens {
  static const double pagePadding = 16;
  static const double sectionGap  = 14;
  static const double blockGap    = 10;
  static const double itemGap     = 8;

  static const double radiusLg = 28;
  static const double radiusMd = 20;

  static const double titleSize   = 40;
  static const double headingSize = 34;
  static const double metaSize    = 11;
}
```

Because spacing and sizing come from one place, "keep tap targets at least 48dp" (Material's accessible minimum on Android) stops being something I have to remember on every button — it's a property of the system. The theme reinforces it: every primary button defaults to a 58px height, comfortably above that floor, so the model *can't* generate a cramped, hard-to-tap control even if it tries.

This is also my defense against device fragmentation. Screens compose from these relative tokens instead of hardcoded pixel values, and text sizes flow from the theme's type scale rather than magic numbers scattered per screen. That matters because Flutter's text honors the user's system text-scale setting by default — so a themed `displaySmall` grows when someone bumps their font size, instead of being pinned to a hardcoded size that ignores them. (The flip side, which the system has to respect too: fixed-height containers can't swallow that growth, so the standard is minimum heights and flexible layouts rather than rigid boxes.) A card built from `sectionGap`, `radiusLg`, and a themed heading adapts across a 5-inch budget phone and a 6.7-inch flagship — and across font-size settings — far more gracefully than one stitched together from per-screen pixel values. One set of tokens, and the same rules that make the app accessible are what make it hold together across the hundreds of Android devices I will never personally test on.

`core/theme/app_theme.dart` turns the palette into a single Material 3 `ThemeData`. This is also where accessibility gets enforced quantitatively — I didn't pick the teal because it looked nice, I picked a shade dark enough to clear contrast thresholds:

```dart
class AppTheme {
  static const Color primary  = Color(0xFF004D60); // deep teal
  static const Color success  = Color(0xFF005049);
  static const Color warning  = Color(0xFFB06A00);
  static const Color critical = Color(0xFFBA1A1A);

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
      // 58px buttons, StadiumBorder, radiusLg cards, filled inputs — all
      // defined once and inherited, so accessible defaults are the only defaults.
    );
  }
}
```

White text on that teal lands at about **9.4:1 contrast — past WCAG AAA (7:1)**. The critical red on white clears **6.5:1**, comfortably above the AA threshold of 4.5:1. Those aren't happy accidents; they're the reason those specific hex values are in the file. Screens never hardcode a color, so no screen can quietly introduce a low-contrast one. Accessibility becomes a matter of architecture, not vigilance.

## Step 3: Make it referenceable by the AI — the MCP + docs layer

This is the part that makes it work as a solo dev, and it's worth being precise about the mechanism instead of hand-waving at "AI."

I keep the design system and screen specs as structured markdown *in the repo* — `specs/01-design-system.md`, one file per screen, an API contract, and an entry point called `specs/start.md` that declares the hierarchy:

> **Source of Truth.** Frontend implementation should use `specs/01-design-system.md`, the screen specs, and the API contract. Do not assume older draft naming from early docs.

The reason this beats pasting rules into every prompt is that the context is *addressable and versioned* rather than remembered. Two things make that real:

First, the plain repo convention: Claude Code reads a top-level project instruction file on every session and follows references from it, so `start.md` and the specs are always in scope without me re-explaining them. When the docs change, the guidance changes — there's a single source of truth, not a rule I retyped slightly differently across fifteen chats.

Second, an MCP (Model Context Protocol) server sitting in front of those docs. MCP is just a standard way to hand a model tools and resources; my server exposes the design system as *structured, queryable resources* rather than one giant blob of markdown. So instead of the assistant loading the entire spec every time, a build step can pull exactly the relevant slice — the token table, the required-states checklist, the accessibility contract, the spec for the one screen I'm building — as a named resource. That keeps the context window focused, keeps the rules consistent across sessions, and means the same design authority is available to any tool that speaks MCP, not just one chat window.

The net effect is that a build prompt isn't "make a savings screen that looks nice." It's "build the savings screen per `specs/08` and `specs/01`," and the model resolves those against live, structured docs — design system, tokens, and accessibility contract included — so the rules arrive *with* the request instead of being bolted on after.

## Step 4: Hold the AI to an accessibility standard on every component

The specs and tokens set the rules; this step is about the bar I make generated code clear before I accept it. My working principle is that no component is "done" until its accessible behavior is defined — so my spec pairs each component with the pattern I expect the AI to follow. Here are two of those standards, written the way I hand them to the model.

**Status must never be communicated by color alone.** The rule bans color-only status, so the standard for any status indicator is: color *plus* an icon (a distinct shape) *plus* a text label, with a semantic label for assistive tech. The pattern I hold the AI to looks like this:

```dart
Semantics(
  container: true,
  label: 'Obligation status: overdue',
  excludeSemantics: true,                    // don't double-announce the children
  child: Chip(
    avatar: const Icon(Icons.error_outline,  // shape, not just color
        size: 16, semanticLabel: ''),        // icon is decorative here
    label: const Text('Overdue'),            // words, not just red
    backgroundColor: AppTheme.errorContainer,
  ),
)
```

A sighted user sees red + a warning icon + the word "Overdue." A colorblind user still gets the icon and the word. A screen-reader user hears one clean announcement: "Obligation status: overdue." Same component, three ways in — none of them relying on color.

**A currency amount must be readable *and* announceable.** The formatting rule is "always use a currency formatter with code/symbol," and the accessibility standard adds one line: give the amount a spelled-out semantic label so a screen reader doesn't announce "$1,240" as a stray run of digits. Flutter makes this a one-liner, so there's no excuse for the model to skip it:

```dart
Text(
  '\$1,240',
  style: Theme.of(context).textTheme.displaySmall, // tight visual, from the theme
  semanticsLabel: 'Amount due: 1,240 US dollars',  // what a screen reader hears
)
```

The same "define once, reference everywhere" discipline extends to correctness logic — a single `Currency` helper holds the FX rates so multi-currency math is identical on every screen, and an `AppErrorMapper` turns a raw Supabase `429` into a human sentence ("Too many attempts. Please try again shortly.") instead of a generic failure. Accessible error messaging is accessibility too: a clear, actionable message helps everyone, and *especially* anyone using assistive tech, far more than "Request failed."

## What this bought me as a PM

**Speed with a floor under it.** I move as fast as "build this screen" prompts allow, without every screen drifting — and the floor includes accessibility. The AI can't fall through it because the guardrails are in the tokens and the spec it reads first.

**A review that's mostly a checklist.** My spec already lists the states every component must support, the contrast rules, and "no color-only status." Reviewing a generated screen becomes checking it against a list I wrote once, not relitigating accessibility from scratch every time.

**Leverage that outlives me.** The design system is documentation, tokens, and a theme — not knowledge trapped in my head. Any future collaborator, human or AI, inherits the same accessible constitution.

If you're a PM or founder building with AI, my one piece of advice: don't treat the design system — or accessibility — as something you'll clean up later. Build it first, write it as rules an AI can read, put it in the repo where the assistant lives, and make accessibility a *precondition* of every component rather than a launch-week audit.

And reframe accessibility in your own head while you're at it. It isn't a niche requirement for a small group of users — it's a design lens that makes the product more usable for every person on every device, and the discipline that lets one small team ship something that holds up across a fragmented, unpredictable hardware landscape. Every designer and PM should be looking through that lens by default. You're not slowing down to be thorough. You're installing the one thing that keeps AI-built software from quietly excluding people — and quietly falling apart on the devices you never tested.

---

*FinPat is in active development — Flutter, Supabase, Android first. This design-system-first, accessibility-first workflow is the reason a team of one can ship consistent, usable screens at all.*
