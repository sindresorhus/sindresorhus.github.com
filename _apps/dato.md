---
title: Dato
subtitle: Better menu bar clock with calendar and time zones
description: Dato is a replacement for the system menu bar clock. By default, it looks exactly the same, but when you click it, you'll get a small calendar, ability to show the current time in various time zones (even with custom names), optionally show the week number, and more. <a href="https://sindresorhus.com/feedback/?product=Dato&referrer=Website">Let me know</a> what more you would like to see in the menu.
type: macOS
date: 2019-07-13
mac_app_store_url: https://apps.apple.com/us/app/dato/id1470584107?mt=12
---

<br>

### Roadmap

- Custom date format.
- Time slider for the time zones.
- Show the time for multiple time zones in the menu bar.
- Customizable keyboard shortcut to open Dato.
- Improved time zone management, including easier reordering.
- A proper preferences window.
- Timers and stopwatches (like the iOS Clock app, but including Pomodoro).
- Maybe: Alarm clock.

<br>

<h3 id="tips">Tips</h3>
<table>
	<tr>
		<td>
			Double-click a day in the calendar to open that day in the default calendar app.
		</td>
	</tr>
	<tr>
		<td>
			Hold <kbd>option</kbd> while clicking the calendar arrows to jump a year instead of a month.
		</td>
	</tr>
</table>

<br>

<h3 id="keyboard-shortcuts">Keyboard shortcuts</h3>
<table>
	<tr>
		<td>
			<kbd>◀</kbd>
			/
			<kbd>▶</kbd>
		</td>
		<td>Previous/next day in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>▲</kbd>
			/
			<kbd>▼</kbd>
		</td>
		<td>Same day in the previous/next week in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>option</kbd> <kbd>◀</kbd>
			<br>
			<kbd>option</kbd> <kbd>▶</kbd>
		</td>
		<td>Previous/next month in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>shift</kbd> <kbd>option</kbd> <kbd>◀</kbd>
			<br>
			<kbd>shift</kbd> <kbd>option</kbd> <kbd>▶</kbd>
		</td>
		<td>Previous/next year in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>space</kbd>
		</td>
		<td>Select today in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>command</kbd> <kbd>q</kbd>
		</td>
		<td>Quit the app</td>
	</tr>
</table>

<br>

<h3 id="gestures">Gestures</h3>
<table>
	<tr>
		<td>
			Swipe left/right
		</td>
		<td>Previous/next month in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>option</kbd> + Swipe left/right
		</td>
		<td>Previous/next year in the calendar</td>
	</tr>
</table>

<br>


<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Dato&referrer=Website-FAQ)

#### How can I toggle AM/PM for the time?

Dato adheres to what you have set in “System Preferences › Language and Region”.

#### How can I change the first day of the week?

Dato adheres to what you have set in “System Preferences › Language and Region”.

#### Can you localize the app into my language?

All the date and time output and the calendar adhere to your locale preferences. I have no plans to localize the app itself.

#### I added a calendar to the Calendar app but it doesn't show up in Dato

You need to enable the calendar in “Dato › Preferences › Calendar Events”.

#### Dato doesn't show up in the menu bar

When the menu bar grows too large, macOS hides overflowing items, so Dato might have been hidden. Try to close some of your other menu bar apps. There’s, unfortunately, no way for apps to detect this and warn the user.

#### How can I reorder the time zones?

You can change the order in “Preferences > Time Zones > [Some Time Zone] > Position”. The usability of this will be improved later this year with a new time zone management.

#### Can you add support for Google Calendar?

It's already supported. Just add your Google calendars to the Calendar app and then enable the calendars in the Dato preferences.

#### How can I make my calendar refresh more often?

Open the Calendar app, open its "Preferences", go to the "Accounts" tab, choose the relevant calendar service in the left sidebar, and then change the "Refresh Calendars" preference. Ideally, it should be set to "Push", but not all services support that, like Google.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/us/app/dato/id1470584107?mt=12) and click “Version History”.

#### Can you add support for showing an analog clock like the system clock?

I have no plans to add that, but you can make it work by unchecking the "Time" preference in Dato and keep the system clock.

#### Can you add support for flashing the time separator like the system clock?

I have no plans to add that, but you can make it work by unchecking the "Time" preference in Dato and keep the system clock.

#### Is it possible to pin Dato so it's always visible?

This is unfortunately not possible as Dato uses a menu, not a popover, which can’t be pinned.

#### So this is like iStat Menus?

iStat Menus does all the things. Dato is focused on date and time only. Dato also looks better.

#### How is it different from Itsycal?

Itsycal is a great app too. While Itsycal has more advanced calendar functionality, Dato is not just a calendar app, but also includes menu bar clock replacement, time zones, and in the future, timers.

#### Why the name "Dato"?

It means "date" in Norwegian. I just wanted a short, unique, and relevant name.

#### Do you plan to open-source it?

I open-source [most things](https://github.com/sindresorhus) I make, but I don’t intend to open-source this app. Many open-source apps have problems with someone using the source to publish clones and it’s a hassle to get Apple to take down such clones. I also have my own private framework that makes it faster for me to build apps, but I don’t want to open-source it as then I would have to maintain it.

#### Can you add support for macOS 10.13 or older?

No, there were several bugs in 10.13 I could not work around.

#### Is this a native app?

Yes, it’s a native app written in Swift.

#### Can you port it to Windows/Linux?

No, I’m a Mac developer.
