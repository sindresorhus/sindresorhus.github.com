---
title: Dato
subtitle: Better menu bar clock with calendar and time zones
description: Dato gives you a local clock, date, and multiple world clocks in the menu bar. When you click Dato in the menu bar, you get a menu with a calendar, calendar events, and world clocks. All of this is highly customizable. Dato also comes with some macOS 11 widgets.
type: macOS
date: 2019-07-13
mac_app_store_url: https://apps.apple.com/app/id1470584107
---

**Want to see Dato included in [Setapp](https://setapp.com)?** Help make it happen by [requesting it here](https://support.setapp.com/hc/en-us/articles/213780569-Can-I-suggest-an-app-).

Dato is a one-time purchase with free upgrades forever. Dato will never be subscription-based.

Dato supports all the locales and languages that macOS supports for the menu bar text, dates, times, and the calendar, but the menus and preferences are English-only.

[MacStories review of Dato.](https://www.macstories.net/reviews/dato-review-calendar-events-and-time-zones-from-your-macs-menu-bar/)

Dato requires macOS 10.15 or later.

<br>

<a id="trial"></a>
### Trial

There's a fully functional trial available [here](https://dsc.cloud/sindresorhus/Dato-2.4.0-trial-1615789998). The only limitation is that it will prompt to buy Dato every 12 hours and it will not receive updates. The trial is only available for macOS 11 since Dato works best on macOS 11. If you decide to buy Dato on the App Store, all data and settings from the trial version will be preserved (they share the same storage).

**If you're on macOS 11, please upgrade to macOS 11.3 before trying out Dato. There are a bunch of macOS bugs in earlier releases.**

### Features

- Calendar, optionally with week numbers and event indicators.
- Your upcoming events for the next week (customizable) at a glance.
- Time zones in the Dato menu, optionally with custom names.
- Show the upcoming event in the menu bar (like Fantastical, Meeter, and MeetingBar) *(macOS 11-only)*
- Create events (even with a global keyboard shortcut) *(macOS 11-only)*
- Join the next meeting (Zoom/Meet/Teams) with a customizable global keyboard shortcut *(macOS 11-only)*
- Clocks for multiple time zones in the menu bar.
- Custom format for the date & time in the menu bar.
- Highlight certain days of the week in the calendar.
- Search time zones by city (15k cities included offline).
- Supports all calendar services that the built-in Calendar app supports (iCloud, Google, Outlook, etc).
- Fully customizable.
- Lots of in-app keyboard shortcuts for power users.
- Global keyboard shortcut to open/close the app.
- Supports calendar events with HTML formatted notes.
- Show seconds in the menu bar clock or in the menu. (Optional)
- Zoom, Google Meet, and Microsoft Teams integration. (Shows icon on events and button to quickly join)
- Open calendar events from Google Calendar directly in Google Calendar on the web.
- Custom color for the date & time menu bar item. (macOS 10.15 only, not macOS 11)
- Comes with multiple menu bar icons to choose from: date in calendar, date with border (like Itsycal), static clock, none.
- Large text mode.

<br>

### Older versions

- [Last macOS 10.14 compatible version (free).](https://github.com/sindresorhus/meta/files/5360452/Dato.1.14.9.-.Special.last.Mojave.compatible.release.zip)

*(This build will not run on newer macOS versions)*

<br>

<h3 id="tips">Tips</h3>
<table>
	<tr>
		<td>
			Click the month & year label in the calendar (for example, “April 2020”) to change the selected day to “today”.
		</td>
	</tr>
	<tr>
		<td>
			Double-click a day in the calendar to open that day in the default calendar app. (Supports: Calendar, Fantastical 2, BusyCal, Outlook)
		</td>
	</tr>
	<tr>
		<td>
			Hold <kbd>option</kbd> while clicking the calendar arrows to jump a year instead of a month.
		</td>
	</tr>
	<tr>
		<td>
			In the event details, press <kbd>command</kbd> <kbd>c</kbd> to copy the selected text.
		</td>
	</tr>
	<tr>
		<td>
			While looking at an event, press <kbd>option</kbd> to see the name of the calendar it belongs to.
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
			<kbd>n</kbd>
		</td>
		<td>Create a new event</td>
	</tr>
	<tr>
		<td>
			<kbd>command</kbd> <kbd>o</kbd>
		</td>
		<td>Open the default calendar app</td>
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
			Swipe left/right on the calendar
		</td>
		<td>Previous/next month in the calendar</td>
	</tr>
	<tr>
		<td>
			<kbd>option</kbd> + Swipe left/right on the calendar
		</td>
		<td>Previous/next year in the calendar</td>
	</tr>
</table>

<br>

<h3 id="faq">Frequently Asked Questions</h3>

#### I have a feature request, bug report, or some feedback

[Send it here.](https://sindresorhus.com/feedback/?product=Dato&referrer=Website-FAQ)

<a id="macos11-hide-clock"></a>
#### How can I hide the built-in menu bar clock on macOS 11?

On macOS 11, it's unfortunately no longer possible to disable the built-in menu bar clock.

However, you have some options:
1. **(Recommended)** In “System Preferences › Dock & Menu Bar › Clock”, choose the analog clock and disable showing the date. This gets you the closest to how it was on macOS 10.15 as you can use Dato for both date and time. <img width="258" src="https://user-images.githubusercontent.com/170270/105505537-a5044800-5cfb-11eb-979b-7a0b109f0c93.png"><br>This has the added benefit that while the system clock [shows as disabled](https://user-images.githubusercontent.com/170270/105506021-2c51bb80-5cfc-11eb-84a6-79b62d69d4bc.png) when you enable “Do Not Disturb” (which makes it pretty unreadable), Dato always shows it the same way.
2. Use Dato for showing the date and the built-in clock for the time.
3. Only show an icon for Dato.

I would really appreciate it if you could take a moment to [complain to Apple](https://www.apple.com/feedback/macos.html) that they should bring back the ability to disable the built-in menu bar clock. For reference, on macOS 10.15, there's a checkbox called “Show date and time in the menu bar” in “System Preferences › Date & Time › Clock”. This checkbox no longer exists on macOS 11.

I have already [reported it to Apple](https://github.com/feedback-assistant/reports/issues/131), but I have yet to get a reply.

#### How can I toggle AM/PM for the time?

Dato adheres to what you have set in “System Preferences › Language and Region”.

#### How can I change the first day of the week?

Dato adheres to what you have set in “System Preferences › Language and Region”.

#### Can you localize the app into my language?

All the date and time output and the calendar adhere to your locale preferences. I have no plans to localize the app itself.

#### I added a calendar to the Calendar app but it doesn't show up in Dato

You need to enable the calendar in “Dato › Preferences › Events”.

#### Dato doesn't show up in the menu bar

When the menu bar grows too large, macOS hides overflowing items, so Dato might have been hidden. Try to close some of your other menu bar apps. There’s, unfortunately, no way for apps to detect this and warn the user.

#### Can you add support for Google Calendar / Outlook 365 / Exchange?

It's already supported. Just add your calendars to the built-in Calendar app and then enable those calendars in the Dato preferences.

#### How can I customize the menu bar date and time format?

If you just want to toggle a certain component, like date or time, use the checkboxes in the “General” preferences.

If you want something more custom, go to “Dato › Preferences › Advanced”, and in the “Date & Time Format” text field, you can specify a [datetime pattern](https://nsdateformatter.com).

For example, you could display the full month name, the year, or the day of the year.

#### How can I show the menu bar date and time in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format?

Either change [this system setting](https://apple.stackexchange.com/questions/191445/standard-iso-8601-week-number-in-calendar-app/209340#209340) or go to “Dato › Preferences › Advanced”, and in the “Date & Time Format” text field, write `YYYY-MM-DD  hh:mm:ss`.

#### Why is Dato not showing week 53?

That is called [ISO week-numbering](https://en.wikipedia.org/wiki/ISO_week_date). Change [this system setting](https://apple.stackexchange.com/questions/191445/standard-iso-8601-week-number-in-calendar-app/209340#209340).

#### Why is Dato showing the last days of December as week 1?

Same answer as above.

#### Dato is showing the incorrect week number

Same answer as above.

#### How can I change the week number to [ISO 8601](https://en.wikipedia.org/wiki/ISO_week_date) format?

Change [this system setting](https://apple.stackexchange.com/questions/191445/standard-iso-8601-week-number-in-calendar-app/209340#209340).

#### How can I open a calendar event in my favorite calendar app (Fantastical, BusyCal, etc.) instead of the built-in Calendar app?

Dato uses the system default calendar app. To change the default calendar app, open the built-in Calendar app, open “Preferences…”, and in the “Default calendar app” preference, select the app you want.

Dato supports opening calendar events directly in Calendar, Fantastical, BusyCal, Outlook, and Google Calendar (web). For other apps, Dato will just open the app.

#### How can I make my calendar refresh more often?

Open the Calendar app, open its “Preferences”, go to the “Accounts” tab, choose the relevant calendar service in the left sidebar, and then change the “Refresh Calendars” preference. Ideally, it should be set to “Push”, but not all services support that, like Google.

#### Where can I find the changelog?

Go [here](https://apps.apple.com/app/id1470584107) and click “Version History”.

#### Can you add support for showing an analog clock like the system clock?

I have no plans to add that, but you can make it work by unchecking the “Time” preference in Dato and keep the system clock in analog mode.

#### Can you add support for flashing the time separator like the system clock?

I have no plans to add that, but you can make it work by unchecking the “Time” preference in Dato and keep the system clock.

#### A calendar is missing

First, ensure that you have added the calendar to the system. Open the built-in Calendar app, open its preferences, click the “Accounts” tab, and then check that the calendar is there. Dato can only show calendars added there.

If it exists in the Calendar app, open the Dato preferences, click the “Events” tab, and make sure the calendar is enabled.

If it exists in the Calendar app but not in Dato, macOS might have corrupted some permissions. This is, unfortunately, a common problem. Try to reset the permissions for Dato. Quit Dato, open the Terminal app, and paste in the following command and press <kbd>Enter</kbd>:

```
tccutil reset All com.sindresorhus.Dato
```

Then launch Dato again.

#### Is it possible to pin Dato so it's always visible?

This is unfortunately not possible as Dato uses a menu, not a popover, which cannot be pinned.

#### How can I copy a link from the event notes? I need to open it in a specific browser profile.

If it's a non-clickable URL (not a link), you can select the URL and choose “Copy Selected Text”. Otherwise, activate the correct browser profile and then drag and drop the link into the browser window.

#### How can I export / import / sync / backup preferences?

I would recommend the [Syncalicious app](https://github.com/zenangst/Syncalicious) which works with any macOS app.

#### How can I open Google Meet links in a specific browser?

You can use the [Finicky app](https://github.com/johnste/finicky) with this config:

```js
module.exports = {
	defaultBrowser: 'Firefox',
	handlers: [
		{
			browser: 'Google Chrome',
			match: [
				'https://meet.google.com/*'
			]
		},
		{
			browser: 'Google Chrome',
			match: ({url}) => {
				return url.host == 'accounts.google.com'
					&& url.pathname == '/AccountChooser'
					&& /continue=https%3A%2F%2Fmeet\.google\.com/.test(url.search);
			}
		}
	]
};
```

#### How is this different from Fantastical?

Fantastical is a full-blown calendar app, while Dato is a read-only view of your events. Fantastical is a replacement for the built-in Calendar app. You can use both Fantastical and Dato at the same time. Dato even has integration with Fantastical, so you can open events in Dato directly in Fantastical. Fantastical also has a menu bar item, but many people prefer the UI of Dato. Dato also shows time zones and has more customizability for what's shown in the menu bar. Dato can replace the system date/time, for example.

#### How is this different from iStat Menus?

iStat Menus lets you show different kinds of info in the menu bar, like system stats, network speed, etc. Dato is focused on date and time only. Dato also looks better.

#### How is it different from Itsycal?

Itsycal is a good app too. While Itsycal has the ability to add calendar events, Dato is not just a calendar app, but also includes menu bar clock replacement, time zones, and more.

#### Why the name “Dato”?

It means “date” in Norwegian. I just wanted a short, unique, and relevant name.

#### Do you plan to open-source it?

I open-source [most things](https://github.com/sindresorhus) I make, but I don’t intend to open-source this app. Many open-source apps have problems with someone using the source to [publish clones](https://twitter.com/sindresorhus/status/1202144430477627394) and it’s a hassle to get Apple to take down such clones. I also have my own private framework that makes it faster for me to build apps, but I don’t want to open-source it as then I would have to maintain it.
