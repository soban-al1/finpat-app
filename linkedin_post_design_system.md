# LinkedIn Post — Design System (FinPat series)

---

AI can build you a stunning screen in 30 seconds.

Then a second screen that doesn't quite match the first.

That's the trap. Not that AI builds bad UI — it builds beautiful UI, fast. The problem is that "fast and beautiful" and "consistent across 40 screens" are two completely different games. And most of us discover that the hard way: slightly different teal, a corner radius that drifted, a button 6px shorter for no reason. So you prompt again to fix it. And again. Burning time and tokens patching drift instead of shipping.

Vibe coding gets you to the first screen. It doesn't get you to the fortieth.

So building FinPat, I did one thing differently. Before AI built a single screen, I built the design system — in the repo, as rules the AI reads first. Tokens, colors, spacing, states, components. One source of truth.

Now every prompt inherits it. The AI can't invent a new teal, because the only teal that exists is in the tokens file. Consistency stops being something I police and becomes something the system guarantees.

What that bought me:
→ Time — I review against a checklist I wrote once, not taste every time.
→ Tokens — no re-explaining the rules every prompt, no re-fixing the same drift.
→ Sanity — every new screen strengthens the system instead of adding entropy.

The part I care about most, though, is accessibility — and not as a compliance box.

Accessibility is a usability lens that makes the product better for everyone. A tap target sized for a motor impairment is the one nobody mis-taps while walking. Contrast high enough for low vision is the text you can read in sunlight on a cheap phone. Across hundreds of Android devices and font settings you'll never test, that discipline is what keeps the UI from falling apart.

So I baked it in as a precondition, not an afterthought. No status by color alone. Screen readers announce "1,240 US dollars," not a run of digits. Contrast targets built into the palette. The AI clears that bar or the screen doesn't ship.

Spec to code. The vibes still get to be fun — they just build on a foundation now.

I wrote up the full technical detail — tokens, theme, how the AI references it, the accessibility patterns. Want the deep dive? Say so in the comments.

More as this builds.

#ProductManagement #AI #BuildingInPublic #FinPat #DesignSystems #Accessibility
