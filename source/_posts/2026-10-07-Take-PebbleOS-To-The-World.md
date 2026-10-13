---
title: Take PebbleOS To The World
author: jplexer
date: 2026-10-07
tags:
- Freshly Baked
---

Pebble has always had a global community. From the very beginning, people
all over the world have worn Pebbles on their wrists, built watchfaces for
them, and kept them ticking long after anyone expected. But for a lot of
those people, the watch on their wrist has never really spoken their
language.

Today we're changing that. We're launching
[translate.repebble.com](https://translate.repebble.com), a new home for
translating PebbleOS, and we'd love your help to take PebbleOS to the world.


## Why Translations Matter

Your watch is one of the most personal devices you own. It's the first thing
you glance at in the morning and the thing that taps you on the wrist when
something important happens. Menus, settings, notifications and system
messages should all feel natural to read at a glance, and that means reading
them in the language you think in.

Now that PebbleOS is open source, the community can make that happen. Instead
of waiting for official language packs, anyone who speaks a language can help
bring PebbleOS to the people who speak it too.


## Weblate, With A Pebble Twist

translate.repebble.com is built on [Weblate](https://weblate.org), the open
source translation platform used by many open source projects. If you've
translated software before, you'll feel right at home: pick a language, work
through the strings, and leave suggestions and comments for other translators.
You don't need to clone a repository, set up a build environment or know
anything about how the firmware works.

Translating for a watch is a little different from translating for a phone or
a desktop, though. Screens are tiny, every pixel counts, and the watch can only
show characters its fonts contain. So we built **Peblate**, a Weblate extension
that adds the Pebble-specific pieces right into the editor:

* **Watch previews.** As you type, the editor shows your translation in a
  sample text box drawn by the real PebbleOS text renderer, compiled to run in
  your browser. You can see right away whether it fits and how it looks in
  Pebble's fonts.
* **Font coverage checks.** Peblate checks your language against the fonts
  that will be used and tells you exactly which characters are missing, with
  examples, so there are no surprise empty boxes on the watch.
* **Custom fonts.** Not every script is covered by Pebble's built-in fonts.
  For those languages you can upload a font along with its license. Peblate
  compiles it for every text style and lets you review it with the PebbleOS
  renderer before the language is created.
* **Draft language packs.** Want to see your work on a real watch? Peblate can
  build a draft language pack from the translations saved so far, including
  ones still waiting for review, so you can test before anything is final.


## From Your Browser To Your Wrist

So what happens to a translation after you hit save?

1. **On the web.** Your translation is saved on translate.repebble.com, and
   Weblate commits it to the
   [pebbleos-translations](https://github.com/coredevices/pebbleos-translations)
   repository on GitHub. A reviewer for your language then checks it and
   approves it.
2. **Building the pack.** Every hour, an automated build collects the approved
   strings for each language and turns them into a language pack: a single
   file containing the translated strings and any extra fonts the language
   needs. Only approved strings make it in. A language is published once it
   has a reviewer and at least 80% of its strings are approved. One pack works
   on every supported watch. New packs are published to GitHub, along with a
   list of all the available languages.
3. **On your phone.** The Pebble app reads that list. In your watch's settings
   in the app, tap **Language** to see the available packs, with ones matching
   your phone's language at the top. Pick one and the app downloads it and
   checks that it arrived intact.
4. **On your watch.** The app sends the pack to your watch over Bluetooth. The
   watch switches to the new language right away, with no restart needed, and
   keeps it across reboots. Your watch holds one language pack at a time, and
   you can switch back to English at any time under **Settings > Display >
   Language** on the watch.

Draft packs take a shortcut: build one in the editor, download the `.pbl`
file, and open it with the Pebble app to send it straight to your watch.


## How To Get Involved

1. Head over to [translate.repebble.com](https://translate.repebble.com) and
   sign in with your Pebble Account. That's the same account you already use
   with the Pebble app, so there's no new password to remember.
2. Choose the language you'd like to work on. If yours isn't there yet, start
   it with the new-language wizard. It checks whether Pebble's built-in fonts
   cover your language and walks you through adding a font if they don't.
3. Start translating! Even a few strings help, and every bit counts.

Each existing language already has a select few reviewers from the community.
They check new translations before they make it into a language pack, which
keeps each language consistent and high quality. So don't worry about getting
everything perfect. Your suggestions will get a second pair of eyes.

Want to help look after a language yourself?
[Apply to become a reviewer](https://translate.repebble.com/contact/?topic=server)
and tell us which language you'd like to review.

New languages are open to everyone. If your language isn't on the site yet,
you don't need to ask permission. Start it and get translating!

A few tips to keep in mind:

* **Keep it short.** Pebble screens are small, and a translation that's much
  longer than the original may get cut off. Keep an eye on the preview. Short,
  clear wording beats a literal translation.
* **Stay consistent.** If a term is already translated elsewhere, try to use
  the same wording so the interface feels cohesive.
* **Ask when in doubt.** If you're not sure what a string means or where it
  appears, ask the community. Context makes for better translations.


## What's Next

This is just the beginning. Next, we're working on full-screen watch previews,
and on getting reviewers in place for every language so its pack can be
published. Translators who get started now will be the ones who make sure
their language is ready for everyone.


## Join Us

PebbleOS is built by its community, and translations are one of the easiest
and most rewarding ways to contribute. Whether you speak one language or
five, you can help someone, somewhere, use their Pebble in their own
language.

If you have questions, feedback or want to coordinate with other translators
for your language, come and say hello on the
[Pebble forum]({{ site.links.forums }}).

We can't wait to see PebbleOS in your language.

JP
