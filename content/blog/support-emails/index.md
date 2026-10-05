---
isDraft: true
title: 'What 10,000 Support Emails Taught Me'
description: 'I make my apps alone, and I answer the support email myself. Some lessons from the first 10,000 replies.'
publicationDate: '2026-10-07'
---

If anyone wonders what it takes to maintain some popular apps: I recently replied to my 10,000th support email.

I’m not a company. There is no support team. I read every support email and reply myself.

Here is what I have learned.

## Try restarting your device

I reply with this up to 10 times a day: “Try restarting your device.”

It works every time. It is still a waste of my time, and of yours.

A lot of support is not about the app. It is a stuck widget, a permission that macOS forgot, or an iCloud sync that is taking a nap. These are real problems for the person who writes, but the fix is the same short list every time. So I put that list in the [FAQ](/apps/faq#app-problem), and the [feedback page](/feedback) now suggests answers while you type your message. The best support email is the one that never had to be sent. <!-- TODO: confirm: does the feedback page reduce the number of emails? -->

## Ask “Just curious, …”

Most feature requests are a solution, not a problem. Someone asks for a setting, a button, or a toggle. If I build exactly that, I usually solve the wrong thing.

So I reply with “Just curious, …” and ask what they are actually trying to do. The real use case is often simpler than the request, and sometimes the app already does it. Sometimes it is a perfect job for the Shortcuts app. And sometimes it is a great idea that makes the app better for everyone.

## Every feature is a promise

The real cost of software is not building it. It is supporting it. Every feature is a promise to maintain it, and every setting is a new way for something to be set wrong.

That is why I say no to a lot of requests:

- **Out of scope.** An app should do one thing well. Every “yes” makes the next “no” harder.
- **Hacks.** Anything that relies on private behavior can break with the next macOS update. Hacks turn into support email.
- **Free APIs.** They go away. Jiffy, my GIF app, is gone because the API it used stopped being free.

Saying no is uncomfortable. Saying yes and then supporting it forever is worse.

## Price is a support tool

Velja was free for three years. The volume of support requests became unsustainable, so I made it paid.

This was not about revenue. A free app attracts a lot of people who never really wanted it, and they write the most email. Even a small price means the people who get the app actually wanted it. I wrote more about this in [Why My Apps Are Pay Once](../pay-once/index.md).

## Reviews will humble you

App Store reviews will humble you.

> Love the app. Been using it every day for years. Wish the app icon was green, not blue.

One star.

You cannot reply to everyone, and you cannot make everyone happy. Read the reviews for the real bugs, ignore the color requests, and move on.

## AI is on both sides now

Customers use AI to send me feature requests. I use AI to summarize and reply. It’s basically two language models roleplaying tech support while I sit here eating cereal.

It is funny, but it also helps. A summary gets me to the actual problem faster, and I still read the email and decide what to reply. <!-- TODO: confirm: how you use AI for support today -->

## Behind every email is a person

It is easy to get cynical after a few thousand emails about restarting a device. But behind every support email is a real person who took the time to write, often because something they rely on every day stopped working.

Most people are kind. Many say thank you after the fix. Some send a feature idea that ends up in the app. Those are the emails that make the other 9,000 worth it. <!-- TODO: confirm: the share of kind emails is a guess -->

## What I would tell another indie developer

- Put the answer to every repeated question on the app page, where people look before they write.
- Ask what people are trying to do before you build what they ask for.
- Count the support cost before you add a feature.
- Charge something if support is eating your time.
- Support only the latest OS, and spend the time on the apps instead.
- Restart your device. It works every time.
