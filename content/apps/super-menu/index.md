---
isDraft: true
title: 'Super Menu'
subtitle: 'Your files, folders, apps, links, and shortcuts in one menu'
publicationDate: '2026-10-18' # TODO: Update date
platforms: [
	'macOS'
]
sharedQuestions: [
	'menu-bar-icons'
	'backup-settings'
]
isPaid: true
isMenuBarApp: true
requirement: 'Requires macOS 27 or later'
---

Build one fast, personal menu for everything you open often.

For example, your project folders, the apps you use for work, a few websites, and the shortcuts you run every day.

@Feature(title: "Arranged your way") {
Add files, folders, apps, links, and shortcuts from anywhere, and arrange them in sections and nested submenus, or show apps as icons, like a small Dock. Show groups only in the apps they are for, or only when you hold Option. Choose the app that opens each file, folder, or link. Open the menu from the menu bar, or with a keyboard shortcut at the pointer, and use the arrow keys to get to an item. [Drag or paste items into the organizer](#tips) to fill the menu in a minute.
}

@Feature(title: "Browse folders without opening Finder") {
Hover over a folder to browse its subfolders, and preview files with Quick Look right in the menu. Each folder has its own [sorting, filter, and item limit](#folder-settings), so a large folder stays fast, and can show the date or size of each item. Make a smart folder, like all the PDFs in your Documents, show the newest downloads right in the menu, or show the results of a [Finder Saved Search](#saved-searches). Paste copied files into a folder, and eject drives.
}

@Feature(title: "Your shortcuts and recent files too") {
Run shortcuts from the menu, or add a linked Shortcuts folder that stays in sync with the Shortcuts app. Add links that do things in other apps, with the date, the copied text, or text you enter inserted. Add a Recent Files section to get back to what you opened, and keep the history private on your Mac. Switch between running apps, and see what you copied.
}

## Guide {#guide}

To open the organizer, choose “Manage Menu” from the `…` submenu, or press <kbd>Shift</kbd><kbd>Command</kbd><kbd>,</kbd> while the menu is open. You can also use the “Manage Super Menu” action in Shortcuts.

Use the Add button in the toolbar to add an item, a group, or a separator, or [drag items into the organizer](#tips).

Drag rows to reorder them. Create groups for related items, then choose whether each group shows as a section of the menu, under its name, or as a submenu. A group of only apps can show them as icons, in rows of up to six, like a small Dock. The path bar shows where you are when editing nested groups.

A group can show only while you use certain apps, like your Xcode projects while you use Xcode. Choose the apps when you edit the group. A group can also show only while you hold <kbd>Option</kbd>, to keep rarely used items out of the way. Press Option while the menu is open to show it. Choose “Never” to hide a group without removing it. To show or hide groups automatically, use the “Set Group Visibility” action in Shortcuts, for example in an automation for a Focus or a time of day. It can also toggle groups, for example from a keyboard shortcut. A group that shows only while you hold Option still does when the action shows it again.

Give an item a note, like “Client A” or “Needs VPN”, to show it below the name, or below the title of a section. It helps to tell items with the same name apart. Files and folders with the same name show the folder they are in.

A folder can also show its contents as a section of the menu instead of a submenu, like “Latest Downloads” with a low item limit, so they are one hover closer.

### Opening items {#opening-items}

- Click a file, folder, app, link, or shortcut to open or run it. An app that you add shows a dot while it is running, like in the Dock.
- A folder remains clickable even when it has a submenu. Click it to open the folder in Finder, or hover over it to browse its contents.
- The submenu of an item has its other actions. For a file, it shows a Quick Look preview with its kind, size, dimensions, modified date, and tags, and has Show in Finder, Open With, Quick Look, Share, Copy File, Copy Path, and Move to Trash. Quick Look opens the file in the Quick Look window, like pressing <kbd>Space</kbd> in Finder. Use the arrow keys to go to the other files of the folder. A file in iCloud Drive also has Download Now, or Remove Download to free space while it stays in iCloud. Text files also have Copy Contents, which copies the text, so a folder of text files works as a collection of snippets. RTF, Word, and OpenDocument text documents have it too, and keep their formatting. PDFs have Copy Text. Images have Copy Image, which keeps the format of the image, so an animated GIF still moves, and Copy Text, which copies the text in the image, such as in a screenshot, and works on your Mac. An image with a QR code or another barcode also has Copy QR Code Contents. A photo with a location, like one from a phone, also has Copy Image Without Location, which copies it without the place where it was taken, so you can share it safely. The date and the camera are kept when the format allows it. Images and videos have Copy Dimensions. While a checksum is copied, like from a download page, a file has Compare with Copied Checksum, which checks that the downloaded file is the right one (MD5, SHA-1, SHA-256, or SHA-512). A file in a folder or in the results of a Saved Search also has “Add to Menu”, which adds it at the end of the menu.
- A folder that is a drive, disk image, or network share has “Eject” at the end of its submenu ([tip](#tips)). When you add a drive itself, such as Macintosh HD or an external drive, it shows how much space is free.
- When you have copied files, for example in Finder, a folder's submenu ends with “Paste”, like “Paste 3 Items”, which copies them into the folder. When you have copied an image, such as a screenshot, it ends with “Paste Image as File”, which saves it as a new image file in the folder. The file gets the name of the image when it has one, like an image copied in a browser. When you have copied text, hold <kbd>Option</kbd> to show “Paste Text as File”, which saves it as a text file named after its first line. These rows are not there for a folder that Super Menu cannot change, like one on a read-only drive.
- Files that you add directly and recent files always show the preview. Files inside a folder follow the “Show file preview” setting of that folder. Audio files, presentations, archives, disk images, and apps show a picture instead, as their live preview does not work in a menu. A file that is only in iCloud and an empty file show their icon.

### Alternative actions {#alternative-actions}

Hold <kbd>Option</kbd> while clicking an item to use its alternative action:

- File, folder, or app: Show in Finder
- Link: Copy the URL
- Shortcut: Edit in the Shortcuts app

Hold <kbd>Option</kbd><kbd>Command</kbd> while clicking an app to open it and hide the other apps, like in the Dock.

Hold <kbd>Option</kbd> in the submenu of a folder to show “Copy Path”, and in the submenu of a group to show “Open All”, which opens the files, folders, Saved Searches, apps, and links in the group, like the things you need for one project.

Hold <kbd>Option</kbd> in the submenu of a file or folder in a folder you added to show “Pin to Top”, which keeps it at the top of that folder, like your current project in a big Projects folder. Pinned items come first, in the order you pinned them, and the item limit does not leave them out. Choose “Unpin” in the same place, or remove the pin in the settings of the folder. A pin only applies to the folder you added, not to the submenus of its subfolders. Apps, and folders without a submenu, cannot be pinned.

Hold <kbd>Shift</kbd> while clicking a file, folder, app, or link to open it in the background, so you can open several in a row. Some apps come to the front anyway.

A linked Shortcuts folder shows its shortcuts as a section or in a submenu. Click the submenu to open the Shortcuts app.

### Folder settings {#folder-settings}

Each folder has its own browsing settings:

- **File icon size:** Small, medium, or large
- **Sort order:** Name, date added, date modified, date created, date last opened, date accessed, kind, tags, or size. Date last opened is when you last opened the file, like in Recents in Finder.
- **Sort direction:** A to Z or Z to A, newest or oldest first, or largest or smallest first
- **Layout:** Hierarchy, or Flattened to show the items of subfolders in one list. An item in a subfolder shows the subfolder below its name.
- **Subfolder levels:** How many levels of subfolders a flattened folder includes, up to 5
- **Show:** Files and folders, files only, or folders only
- **Details:** Show the date modified, date added, date created, or size of each item below its name
- **Show hidden items:** Include hidden files. Files that macOS makes in folders, like `.DS_Store` and `.localized`, are always left out.
- **Browse package contents:** Treat app and document packages as folders
- **Keep folders on top:** Group folders before files without changing the selected sort order
- **Pinned:** The items you pinned to the top with [“Pin to Top”](#alternative-actions), in their order. Remove a pin here, also when its item is gone. It shows when the folder has pins.
- **Browse folder contents:** Show folders as submenus. Turn this off when you only want folders to open directly.
- **Show file preview:** Show a Quick Look preview in file submenus. This is off by default.
- **Item limit:** The maximum number of items to show in the folder itself. Use a low limit for very large folders. When there are more items, the last row shows how many, and opens the folder in Finder. Its subfolders show up to 200 items, or more if the limit is higher.
- **Hide when empty:** Leave the folder out of the menu while it lists nothing, like an inbox. For example, Downloads with the filter “Added Within 1 day” shows only when you downloaded something in the last 24 hours.
- **Filter:** Show only the items that match a name, extension, kind (such as images, PDFs, or screenshots), Finder tag, modification date, date added, or file size. In Hierarchy with files and folders, the filter applies only to files, which come first, and all folders stay, so you can open them.

@Details(summary: "Smart folder options") {
Make a smart folder with a filter and the Flattened layout. It then shows the matches from all the subfolder levels you choose in one list. For example, add your Documents folder, choose Flattened with 3 subfolder levels, and filter by the extension `pdf` to see all your PDFs in one list. The item limit applies too, so smart folders stay fast.
}

### Finder Saved Searches {#saved-searches}

Add a `.savedSearch` file to show the results of a [Smart Folder](https://support.apple.com/guide/mac-help/create-or-change-a-smart-folder-on-mac-mchlp2804/mac) that you made in Finder. Edit the search in Finder, and the menu shows the new results. Searches of “This Mac” and of specific folders work. The results are in the order of the search in Finder's list view, unless it is sorted by a column the menu cannot sort by, such as Version. Super Menu asks once for access to your home folder ([why](#home-folder-access)), and leaves out any result it cannot access. If you drag or paste a Saved Search into the organizer, right-click it and choose “Authorize Search Results…”. Each Saved Search has its own item limit.

### Recent files {#recent-files}

Add Recent Files, as a submenu or a section of the menu, to show files opened through Super Menu. This history is local to the app. Choose how many files it shows, up to 50. Choose “Add to Menu” in the submenu of a recent file to make it a permanent menu item, or choose “Clear Menu” to remove the history.

### Running apps {#running-apps}

Add Running Apps to list the apps that are running, sorted by name, in a submenu or as a section of the menu. Choose an app to switch to it.

### Clipboard {#clipboard}

Add Clipboard to show what you copied, like “Report.pdf”, “3 Files”, a link, an image, or the first line of copied text. It is hidden while nothing is copied, and while a password is copied from a password manager. Click it to see what is copied in Quick Look, or to open a copied link. Its submenu can also open copied files, show them in Finder, share what is copied, or clear the clipboard.

### Settings {#settings}

- **Keyboard shortcut:** Open the menu from anywhere. It can open at its menu bar icon or at the pointer. Then use the arrow keys and Return to navigate without reaching for the mouse.
- **Max menu width:** Make the menu wider, so long names are not cut off.
- **Text size:** Make the text in the menu larger, so it is easier to read.
- **Menu bar icon:** Choose from a set of icons.
- **Launch at login**

### Privacy {#privacy}

Your menu, recent-file history, and settings stay on your Mac. Super Menu can only read the files and folders that you add, and your home folder if you add a Saved Search. Your files and folders are never uploaded. It only reads the clipboard when you paste into the organizer, open or copy a link, to fill in placeholders like `{clipboard}`, open the menu when it has a link that can hide, to hide it when nothing it can use is copied, open the menu when it has a Clipboard item, to show what is copied, open a folder's submenu, to offer to paste copied files, an image, or text, open a file's submenu, to offer to compare a copied checksum, or open the “…” submenu, to offer to add a copied link. Text in images is recognized on your Mac.

### Tips {#tips}

The fastest way to fill your menu is to drag items into the organizer. Drop them between items to put them there, or on a group to add them to it. You can drop many items at once:

- Files, folders, and apps from Finder
- A website from the address bar of Safari or another browser, or a link from a web page
- Web location files (`.webloc` and `.inetloc`), which you get when you drag a link to the desktop. They become links.
- Shortcuts from the Shortcuts app

You can also copy them, for example in Finder, and paste them into the organizer with <kbd>Command</kbd><kbd>V</kbd>. Like the items in the “Add” menu, they go below the selected items.

To add files and folders without opening the organizer, select them in Finder, right-click, and choose “Add to Super Menu” in Quick Actions or Services. They go at the end of the menu.

To add a web link without opening the organizer, copy its address, for example from the address bar, and choose “Add Copied Link” in the <kbd>…</kbd> submenu at the end of the menu. You can also use the “Add to Super Menu” action in Shortcuts. For example, make a shortcut with it that shows in the Share menu, and share a page from Safari to add it, to the menu or to a group.

The “Add” menu also has presets: “Latest Downloads” shows your newest downloads as a section of the menu, “Recent Screenshots” lists your newest screenshots, “Apps” lists your apps, like the Applications stack in the Dock, and “Volumes” lists your drives, disk images, and network shares. Change their settings like those of any folder.

Use a group as a workspace for a project or a task, and open all of it at once: hold <kbd>Option</kbd> in the submenu of the group and choose “Open All”. It opens the files, folders, Saved Searches, apps, and links in the group. A link that needs something you have not copied is left out. For example:

- A “Client A” group with the project folder, the app you work in, the Figma file, and the issue tracker
- A “Morning” group with Mail, Calendar, your news sites, and the folder of today's work
- A “Writing” group with the draft, the folder of notes, and the style guide
- A “Meeting” group with the agenda, the notes from last time, and the link of the video call

A shortcut that is already in the group is not added again. When you drop it between items, its row is selected instead, so you can see where it is.

Hold <kbd>Option</kbd> when you drop items in the organizer to copy them instead of moving them, like in Finder. Groups, folders, links, and separators can be copied. A selection with other items is moved.

Drag items onto a group to move them into it, or onto a group in the path bar to move them out to it. Hold an item over a group to open the group, and then drop the item where you want it. This follows the “Spring-loading” setting in System Settings › Accessibility › Pointer Control. Right-click items for more actions.

Made a mistake? Press <kbd>Command</kbd><kbd>Z</kbd> to undo any change in the organizer, such as removing items. Press <kbd>Shift</kbd><kbd>Command</kbd><kbd>Z</kbd> to redo it.

Choose “Volumes” in the presets to get a menu of your drives, disk images, and network shares. It is the `/Volumes` folder. Each of them has “Eject” at the end of its submenu, and the menu ends with “Eject All”, to eject all of them before you unplug your Mac from a dock.

Open a page of System Settings directly from the menu with a link like `x-apple.systempreferences:com.apple.Wallpaper-Settings.extension`. See [this list](https://github.com/jaywcjlove/SystemSettings-URLs-macOS) for the pages. The pages can change between macOS versions.

A link can be any URL that an app on your Mac opens, not only a website. The app must be installed. Use it to go directly to something in another app, or to make an app do something:

- `x-apple.systempreferences:com.apple.Wallpaper-Settings.extension` opens the Wallpaper settings in System Settings
- `mailto:name@example.com` starts an email to that address
- `shortcuts://run-shortcut?name=Morning` runs the “Morning” shortcut
- `things:///add?title=Call%20mom` adds a to-do in [Things](https://culturedcode.com/things/support/articles/2803573/)
- `obsidian://open?vault=Notes` opens a vault in [Obsidian](https://help.obsidian.md/uri)
- `raycast://extensions/raycast/clipboard-history/clipboard-history` opens a command in [Raycast](https://developers.raycast.com/information/lifecycle/deeplinks)
- `smb://nas.local/Media` connects to a network share in Finder, so one click mounts it
- `vnc://mac-mini.local` opens Screen Sharing to another Mac
- `message://%3Cmessage-id%3E` opens one email in Mail. [This article](https://nshipster.com/message-id/) explains how to get the ID.

Many apps have a URL scheme like this. Look in the documentation of the app. A link shows the icon of the app that opens it, except a web link that opens in your default browser, which shows a link symbol.

#### Link placeholders {#link-placeholders}

Add a placeholder to a link to insert a value when the link opens:

- `{clipboard}`: The text on the clipboard
- `{clipboard url}`: The first web address on the clipboard, such as a link you copied, or one in copied text
- `{clipboard email}`, `{clipboard address}`, `{clipboard phone}`, `{clipboard date}`: The first email address, street address, phone number, or date in the copied text, like “next Friday at 3 pm”
- `{clipboard path}`: The path of the file you copied, for example in Finder, or a copied path, like `/Users/me/Notes`
- `{clipboard text-in-image}`: The text in a copied image, such as a screenshot, recognized on your Mac
- `{clipboard qr}`: What a QR code in a copied image contains
- `{input}`: Text you enter when you open the link, like a search query
- `{input multiline}`: Text with several lines, like the body of an issue
- `{input date}`: A date you choose. The options for dates work with it, and `start` and `offset` set the date it starts at.
- `{input datetime}`: A date and a time you choose, like `{input date}`. It is like `{datetime}` unless you set a `format`.
- `{input number}`: A whole number, like the number of a pull request
- `{input password}`: Text that is hidden as you type it, like a password or a token. It is not stored, and it is asked for separately from `{input}`, even with the same name. With `| shortcut`, it is in a temporary file while the shortcut runs, as that is how a shortcut gets its input.
- `{input file}`: The path of a file or folder you choose when you open the link
- `{date}`: Today's date, like 2026-10-18
- `{time}`: The time, like 14:05
- `{datetime}`: The date and time with the time zone, like 2026-10-18T14:05:00+02:00
- `{day}`, `{weekday}`, `{month}`, `{year}`, `{week}`: The day of the month (like 08), the day of the week (like Monday), the month (like 10), the year, or the ISO week of the year (like 07). Near 1 January, the ISO week can belong to the year before or after, so `{year}-W{week}` can be wrong for a few days.
- `{timestamp}`: The Unix time in seconds. Use `{timestamp milliseconds}` for milliseconds.
- `{uuid}`: A new unique ID
- `{app}`: The name of the app you were in when you opened the menu
- `{app-id}`, `{app-version}`: The bundle identifier or the version of that app
- `{random}`: A random number from 1 to 100
- `{os-version}`, `{mac-model}`: The version of macOS (like 27.0.1) and the model of your Mac (like `Mac16,10`)

Options for dates and times, `{clipboard date}` included:

- `format="d MMMM"`: `{date}`, `{time}`, `{datetime}`, or `{clipboard date}` in your own [format](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table), like 18 October
- `style="long"`: The date, the time, or both in the format of your region, in the style `short`, `medium`, `long`, or `full`, like “24 December 2026” for `{date style="long"}`. A `format` takes its place.
- `time-zone="UTC"`: The date and time in another time zone, like `UTC` or `America/New_York`, such as for a log search in UTC. `start` uses it too, so `start="day"` is midnight in that time zone. `{input date}` picks the day in that time zone, so the day you pick is the day in the link.
- `locale="en"`: The language of names, like the month in `MMMM` or `{weekday}`. It is your language unless you set it, so a link that needs English names should have `locale="en"`.
- `offset="+7d"`: Move the date by minutes (`m`), hours (`h`), days (`d`), weeks (`w`), months (`M`), or years (`y`), like `-1d` for yesterday
- `start="month"`: The start of the `day`, `week`, `month`, or `year`, like the first day of the month. The offset is added after it, so `start="month" offset="-1d"` is the last day of the previous month.

Options for `{input}`:

- `name="To"`: A name, so a link can ask for several things at once. `{input file}` can have a name too.
- `options="en, de, ja"`: Choices, shown as a pop-up menu
- `hint="123"`: Gray text in the empty field, like an example of what to enter

Add `| default "…"` to `{input}` to fill in the field, or to select one of the choices.

Options for `{random}`: `min=1 max=6` for the range, or `options="Run, Bike, Swim"` to pick one of them.

Add modifiers after `|` to change the value, like in Raycast. You can combine them, like `{input | slug | raw}`, and they apply in order. Some take arguments, in quotes or as one word, like `| replace "-" " "` or `| truncate 80`. Text in quotes can have braces, a quote written as `\"`, and a line break and a tab written as `\n` and `\t`.

- `| default "none"`: The text to use when the value is empty, such as when nothing is copied or entered. For `{input}`, it is also the text that the field starts with, except for `{input date}` and `{input datetime}`, which start at today.
- `| each`: Open the link once for each line of the value, like each issue number that `| match-all` finds. The modifiers after it change each line, except `| shortcut` and `| edit`, which run once for the link, so put them before it. It opens at most 50 links, so a value with more lines shows an error and opens nothing. Only the first placeholder with it in a link opens the link for each line.
- `| shortcut "Translate"`: Run a shortcut on the value in the background, and use the text it outputs, like a translation, a summary, or a calculation. It runs when the link opens, after the dialog for `{input}`, so put `| edit` and `| choose` before it. The menu cannot know what the shortcut will output, so it does not hide the link by what the modifiers after it find. If `| match` finds nothing in the output, the link opens with an empty value.
- `| choose`: When the value has several lines, show them in a pop-up menu in a dialog, so you pick one, like one of several issue numbers that `| match-all` finds. A value with one line is used without asking.
- `| edit`: Show the value in a dialog, so you can change it before the link opens, like a copied search. Add `name="…"` to the placeholder to give the field a label.
- `| match "#(\d+)"`: Only the part that matches a [regular expression](https://developer.apple.com/documentation/foundation/nsregularexpression), or its first group in parentheses, like the number in a copied “Fixes #123”
- `| match-all "[A-Z]+-\d+"`: All the parts that match, or their first groups, one on each line, like each issue key in copied release notes. Add `| join-lines ","` to put them on one line.
- `| replace-match "(\w+), (\w+)" "$2 $1"`: Replace each match of a regular expression, where `$1` is its first group, like “Sindre Sorhus” for a copied “Sorhus, Sindre”
- `| json-value "repository.full_name"`: A value in copied JSON, like the name of the repository in a webhook payload. A number is a position in a list, like `items.0.id` or `items[0].id`. A list or an object gives its JSON, and a path that is not there gives no value.
- `| lowercase`, `| uppercase`, `| capitalize-words`, `| capitalize`: Change the case. Capitalize words makes the first letter of each word uppercase, and capitalize makes only the first letter of the text uppercase, like “Buy milk”.
- `| slug`: Make a URL slug, like `my-new-note` for “My New Note”
- `| camel-case`, `| snake-case`: Join the words as one name, like `myNewNote` or `my_new_note` for “My new note”
- `| safe-filename`: Make the text safe as a file name, like a note title from copied text. A line break or a tab becomes a space, and `/` and `:` become `-`. Unlike `| slug`, the spaces and the case are kept.
- `| replace "a" "b"`: Replace each `a` with `b`. Use `""` to remove it.
- `| truncate 80`: At most 80 characters
- `| truncate-words 8`: At most 8 words, like a title made from a copied paragraph
- `| unwrap`: Join the lines of each paragraph, like text copied from a PDF or an email that is broken at a fixed width
- `| first-line`: The first line of the text that is not empty
- `| after-first-line`: The text after the first line, like the body of a note whose first line is its title
- `| line 2`: The second line that is not empty. A negative number counts from the end, so `| line -1` is the last line.
- `| join-lines ","`: The lines that are not empty, joined with a comma, like a column of email addresses copied from a spreadsheet
- `| unique-lines`, `| sort-lines`: The lines that are not empty, without duplicates, or sorted
- `| digits`: Only the digits, like `4791234567` for “+47 912 34 567”
- `| add 1`: Add to a whole number, like for the next page. Text that is not a whole number has no value.
- `| url-host`: The host of a URL, like `github.com` for a copied `https://github.com/sindresorhus`. Text that is not a URL has none.
- `| url-path`: The path of a URL, like `sindresorhus/ky/issues` for a copied `https://github.com/sindresorhus/ky/issues?q=bug`. Use it with `| raw`.
- `| url-parameter "v"`: The value of a query parameter in a URL, like the video ID in a copied YouTube link, or the search in a copied search page
- `| url-decode`: Decode percent-encoded text, like `My%20File` to “My File”
- `| filename`, `| stem`, `| extension`, `| parent`: The name of the file in a path or URL (like `Report.pdf`), the name without the extension (`Report`), the extension (`pdf`), or the folder it is in
- `| json-escape`: Make the text safe in a JSON string, such as in a [Things JSON link](https://culturedcode.com/things/support/articles/2803573/#json)
- `| base64-encode`: Encode the text as Base64
- `| sha256`: The SHA-256 hash of the text
- `| raw`: Insert the value without encoding `/`, `?`, `&`, and the other characters a link can have, so it can change the link, like a copied `owner/repo` in a path. A space is still encoded. Otherwise, all of it is encoded so it is safe in the link.

The link editor shows what is wrong with a placeholder: a name that it does not know, such as a typo, an option that the placeholder does not take, an option value that it cannot read, like `time-zone="Europe/Olso"`, and a regular expression that is not valid. For a typo, it suggests the name you probably meant, and for a name from Raycast, Alfred, or Liquid, like `{argument}` or `| upcase`, it tells you what to use instead.

You can add a search link from another app as it is, as its placeholder becomes `{input}`: `%s` from the keyword searches of Firefox and Chrome, `{{{s}}}` from DuckDuckGo bangs, and `{query}` from Alfred. `%S`, which Firefox inserts without encoding it, becomes `{input | raw}`.

In a web address, a placeholder can be in the path or the query, but not in the domain. A space or a quote that you type outside the braces is encoded for you. You can also type them encoded, like in `things:///json?data=%5B%7B%22type%22:%22to-do%22,%22attributes%22:%7B%22title%22:%22{clipboard | json-escape}%22%7D%7D%5D`.

A link that needs something copied, like `{clipboard path}` when no file is copied, or a `| match` that finds nothing, is hidden in the menu until you copy something it can use. Add `| default "…"` or `| edit` to show it anyway. A link that needs what is in a copied image shows while an image is copied, and tells you when it opens if nothing is found in it. A password copied from a password manager counts as nothing copied, so it is never put in a link.

For example:

- `https://github.com/search?q={input}` asks what to search for on GitHub
- `https://www.google.com/search?q={clipboard}` searches for the copied text
- `things:///add?title=Review&when=today&notes={clipboard}` adds a to-do with the copied text in [Things](https://culturedcode.com/things/support/articles/2803573/)
- `obsidian://new?vault=Notes&name={date}` creates a note named after today in [Obsidian](https://help.obsidian.md/uri)
- `things:///add?title=Pay%20rent&deadline={date offset="+7d"}` adds a to-do that is due in a week
- `https://github.com/{clipboard | raw}` opens a copied `owner/repo`
- `vscode://file{clipboard path | raw}` opens the copied file in Visual Studio Code
- `obsidian://new?vault=Notes&name={input | slug}` creates a note with a file name made from what you enter
- `things:///add?title=Workout&notes={random options="Run, Bike, Swim"}` adds a workout to-do with a random activity
- `https://translate.google.com/?tl={input name="To" options="en, de, ja"}&text={input name="Text"}` asks for the language and the text
- `https://github.com/sindresorhus/ky/issues/{clipboard | match "#(\d+)"}` opens the issue in a copied “Fixes #123”, and is hidden while no issue number is copied
- `https://www.google.com/search?q=site:{clipboard url | url-host}` searches the website of a copied link
- `https://calendar.google.com/calendar/r/month/{date start="month" offset="+1M" format="yyyy/M/d" | raw}` opens next month in Google Calendar
- `http://localhost:3000/{clipboard url | url-path | raw}` opens the page of a copied link on your local web server
- `https://www.youtube-nocookie.com/embed/{clipboard url | url-parameter "v"}` plays a copied YouTube video without the rest of the page
- `maps://?daddr={clipboard address}` gets directions to an address in copied text, like an email signature
- `tel:{clipboard phone}` calls a phone number in copied text
- `https://calendar.google.com/calendar/r/day/{clipboard date format="yyyy/M/d" | raw}` opens the day of a date in copied text, like “next Friday”
- `https://translate.google.com/?sl=auto&tl=en&text={clipboard text-in-image}` translates the text in a copied screenshot
- `https://www.google.com/search?q={clipboard qr}` searches for what is in a QR code that you copied, for example with a screenshot
- `https://www.google.com/search?q={clipboard | edit}` lets you change the copied text before searching
- `https://dict.cc/?s={input | default "hello"}` asks what to look up, with “hello” filled in
- `vscode://file{clipboard path | parent | raw}` opens the folder of the copied file in Visual Studio Code
- `https://github.com/{clipboard | replace "git@github.com:" "" | replace-match "\.git$" "" | raw}` opens the page of a copied `git@github.com:owner/repo.git`
- `https://wa.me/{clipboard | digits}` starts a WhatsApp chat with a copied phone number
- `https://github.com/search?q={clipboard | default "is:pr is:open author:@me"}&type=issues` searches for the copied text, or shows your open pull requests when nothing is copied
- `https://github.com/owner/repo/issues/new?body=macOS%20{os-version},%20{mac-model},%20{app}%20{app-version}` starts a bug report with the details of your Mac and the app you were in
- `https://github.com/owner/repo/issues/new?title={input name="Title"}&body={input multiline name="Details"}` asks for the title and the details of a new issue
- `https://calendar.google.com/calendar/r/day/{input date format="yyyy/M/d" | raw}` asks for a date and opens it in Google Calendar
- `things:///add?title={clipboard | first-line}&notes={clipboard | after-first-line}` adds a copied note as a to-do, with its first line as the title
- `https://www.deepl.com/translator#en/de/{clipboard | unwrap}` translates text copied from a PDF, without the line breaks in the middle of its sentences
- `things:///add?title={clipboard | first-line | truncate-words 8}&notes={clipboard}` adds a to-do with a short title from a copied paragraph
- `mailto:{clipboard email}` starts an email to the address in copied text, like an email signature
- `https://news.ycombinator.com/news?p={clipboard url | url-parameter "p" | add 1}` opens the next page of a copied link
- `vscode://file{input file | raw}` asks for a file or folder and opens it in Visual Studio Code
- `https://github.com/sindresorhus/ky/pull/{input number}` asks for the number of a pull request and opens it
- `things:///add?title={input name="Title" | capitalize}&when={input datetime format="yyyy-MM-dd@HH:mm"}` asks for a to-do and when to be reminded of it
- `https://www.google.com/search?q={clipboard | match-all "[A-Z]+-\d+" | join-lines " OR "}` searches for each issue key in copied release notes
- `https://raw.githubusercontent.com/{clipboard url | url-path | replace-match "^([^/]+/[^/]+)/blob/" "$1/" | raw}` opens the raw file of a copied GitHub file link
- `https://github.com/{clipboard | json-value "repository.full_name" | raw}` opens the repository in copied JSON, like a webhook payload
- `https://github.com/sindresorhus/ky/issues/{clipboard | match-all "#(\d+)" | unique-lines | choose}` opens an issue in copied release notes, and asks which one when there are several
- `obsidian://new?vault=Notes&name={clipboard | first-line | safe-filename}&content={clipboard}` creates a note from copied text, named after its first line
- `https://github.com/sindresorhus/ky/issues/{clipboard | match-all "#(\d+)" | unique-lines | each}` opens each issue in copied release notes
- `https://www.google.com/search?q={clipboard | shortcut "Translate to English"}` searches for the copied text after your shortcut “Translate to English” translates it
- `https://github.com/search?q={input | camel-case}&type=code` searches code for a name, like `isEmpty` for “is empty”
- `https://github.com/sindresorhus/ky/pull/{input number hint="123"}` asks for the number of a pull request, with an example in the field
- `mailto:?subject=Report%20for%20{date style="long"}` starts an email with today's date written out, like “Report for 24 December 2026”

### Keyboard Shortcuts {#keyboard-shortcuts}

#### Menu

<table>
	<tr>
		<td>
			<kbd>▲</kbd>
			<br>
			<kbd>▼</kbd>
		</td>
		<td>Select the previous/next item</td>
	</tr>
	<tr>
		<td>
			<kbd>▶</kbd>
		</td>
		<td>Open the submenu of the selected item</td>
	</tr>
	<tr>
		<td>
			<kbd>return</kbd>
		</td>
		<td>Open the selected item</td>
	</tr>
	<tr>
		<td>
			<kbd>option</kbd>
		</td>
		<td>Hold it to show the groups and the other items that only show with Option, like “Open All” in a group</td>
	</tr>
	<tr>
		<td>
			<kbd>shift+command+,</kbd>
		</td>
		<td>Open the organizer</td>
	</tr>
</table>

#### Organizer

<table>
	<tr>
		<td>
			<kbd>▲</kbd>
			<br>
			<kbd>▼</kbd>
		</td>
		<td>Select the previous/next item</td>
	</tr>
	<tr>
		<td>
			<kbd>return</kbd>
		</td>
		<td>Do the main action of the selected item: open a group, open a shortcut in Shortcuts, or edit the settings of other items, like a file or folder. Double-clicking does the same.</td>
	</tr>
	<tr>
		<td>
			<kbd>space</kbd>
		</td>
		<td>Quick Look the selected file or folder</td>
	</tr>
	<tr>
		<td>
			<kbd>command+▼</kbd>
		</td>
		<td>Open the selected group</td>
	</tr>
	<tr>
		<td>
			<kbd>command+▲</kbd>
		</td>
		<td>Go back to the enclosing group</td>
	</tr>
	<tr>
		<td>
			<kbd>option+command+▲</kbd>
			<br>
			<kbd>option+command+▼</kbd>
		</td>
		<td>Move the selected items up/down</td>
	</tr>
	<tr>
		<td>
			<kbd>delete</kbd>
		</td>
		<td>Remove the selected items from the menu (you can undo it). The files stay where they are.</td>
	</tr>
	<tr>
		<td>
			<kbd>command+i</kbd>
		</td>
		<td>Edit the selected item</td>
	</tr>
	<tr>
		<td>
			<kbd>command+o</kbd>
		</td>
		<td>Open the selected items</td>
	</tr>
	<tr>
		<td>
			<kbd>command+r</kbd>
		</td>
		<td>Show the selected items in Finder</td>
	</tr>
	<tr>
		<td>
			<kbd>command+d</kbd>
		</td>
		<td>Duplicate the selected items</td>
	</tr>
	<tr>
		<td>
			<kbd>control+command+n</kbd>
		</td>
		<td>Put the selected items in a new group</td>
	</tr>
	<tr>
		<td>
			<kbd>option+command+c</kbd>
		</td>
		<td>Copy the paths of the selected items, or the links of links</td>
	</tr>
	<tr>
		<td>
			<kbd>command+v</kbd>
		</td>
		<td>Add the copied files, folders, apps, links, or shortcuts below the selected items</td>
	</tr>
</table>

## Frequently Asked Questions {#faq}

### How is this different from Folder Peek? {#folder-peek}

[Folder Peek](/folder-peek) puts folders directly in the menu bar. Super Menu is one menu that mixes folders with files, apps, links, shortcuts, Saved Searches, and recent files. Use Folder Peek for a few folders one click away, and Super Menu for one menu of everything. They work well together.

### How is this different from Short Run? {#short-run}

[Short Run](/short-run) only organizes and runs shortcuts. Super Menu mixes shortcuts with files, folders, apps, and links. Use Short Run for a dedicated menu of shortcuts.

### How is this better than CustomMenu 3? {#custommenu3}
<!-- @faq.keywords discontinued intel rosetta -->

[CustomMenu 3](https://web.archive.org/web/20230603053427/https://www.pointworks.de/software/custommenu-3/) also puts a curated menu of apps, files, and folders in the menu bar. Compared to it:

- Super Menu is actively developed. CustomMenu 3 has not been updated since 2019 and can no longer be purchased.
- Super Menu runs natively on Apple Silicon. CustomMenu 3 is Intel-only and needs Rosetta, which Apple is phasing out.
- Add websites, shortcuts, linked Shortcuts folders, and Finder Saved Searches, not only files, folders, and apps.
- Create smart folders that filter by name, extension, Finder tag, date, or size.
- Nest groups, and show each group as a section or as a submenu.
- Give each folder its own sorting, icon size, item limit, and other settings.
- Preview files with Quick Look inside the menu.
- Choose the app that opens each file, folder, or link, and use Open With, Share, Copy File, and Copy Path.
- Keep a private list of recent files.
- Browse large folders without slowing down the menu.
- Recover moved items with Locate and Reauthorize.

You cannot import a CustomMenu 3 setup, but you can rebuild it in a few minutes by dragging your items into the organizer.

### Can Super Menu replace the Dock? {#dock}
<!-- @faq.keywords stacks -->

Not fully. Minimized windows and badges stay in the Dock, though Super Menu can list your [running apps](#running-apps). But for the things you open often, the menu bar is always visible, while the Dock is often hidden, and each folder has its own sorting, filtering, item limit, and previews.

### How is this different from Spotlight, Raycast, or Alfred? {#search-tools}
<!-- @faq.keywords search -->

Those are search tools: you type, and they find anything. Super Menu is a menu that you build once and browse. They work well together.

### Do I still need a folder of aliases to gather related items? {#alias-folders}
<!-- @faq.keywords scattered workaround -->

No. Add items from anywhere, and organize them with groups. An alias folder you already have still works.

### Can I use it as an app launcher? {#app-launcher}
<!-- @faq.keywords applications -->

Yes. Add the apps you want, or choose “Apps” in the presets of the “Add” menu to show all of them, also the apps that come with macOS, like Mail and Safari.

### Can I add a Smart Folder from Finder? {#smart-folder}
<!-- @faq.keywords saved search -->

Yes. Add its `.savedSearch` file ([how](#saved-searches)). Super Menu can also make its own [smart folders](#folder-settings).

### Can I show the files of several folders in one list? {#several-folders}
<!-- @faq.keywords merge combine inbox library -->

Yes, with a Smart Folder from Finder, which searches your whole Mac or one folder and its subfolders. For example, an “Inbox” with the files you added recently, wherever they are:

1. In Finder, open the folder that has all the folders you want, like your home folder. To search your whole Mac, you can skip this.
2. Choose “File” › “New Smart Folder”, and click “This Mac” or the name of the folder in the search bar.
3. Click the plus button and choose a rule, like “Date Added” is within the last 7 days. If a rule is not in the list, choose “Other…” to find it.
4. Click “Save” and give it a name. It is saved in the Saved Searches folder.
5. In Super Menu, add the `.savedSearch` file ([how](#saved-searches)).

The list follows the sort order of the search in Finder's list view, so sort it by Date Added there to show the newest first.

### How can I show my most recent screenshots? {#recent-screenshots}
<!-- @faq.keywords latest newest -->

Click “Add” and choose “Recent Screenshots…” in the presets, and choose the folder where your screenshots are saved. It lists your 20 newest screenshots and screen recordings, newest first. It finds them among your other files, so it works on a busy desktop too. Screenshots are saved on the desktop unless you changed it in the Screenshot app (“Options” › “Other Location”).

### Can I have more than one menu? {#multiple-menus}
<!-- @faq.keywords multiple several -->

No. Super Menu is deliberately one menu, but groups and submenus give you as many sections as you want. For several folders in the menu bar, use [Folder Peek](/folder-peek).

### Can I rename an item in the menu? {#rename}
<!-- @faq.keywords title label -->

Yes, in the organizer. The file on disk keeps its name. A shortcut uses its name from the Shortcuts app, so rename it there.

### Long names are cut off. Can I make the menu wider? {#menu-width}

Yes. Increase “Max menu width” in Settings.

### Can I give an item its own keyboard shortcut? {#item-keyboard-shortcuts}

No. The keyboard shortcut opens the menu. Then use the arrow keys and Return.

### Can I drag a file out of the menu? {#drag-out}

No. Choose “Show in Finder” in the submenu of the file, or <kbd>Option</kbd>-click it, and drag it from Finder. You can also use “Copy File” in its submenu.

### Can I drop files into a folder in the menu? {#drop-into-folder}
<!-- @faq.keywords drag -->

No, macOS menus cannot receive drops. Instead, copy the files, for example in Finder, and choose “Paste” at the end of the folder's submenu.

### Can folders open in Path Finder or another app instead of Finder? {#finder-alternative}
<!-- @faq.keywords forklift default -->

Yes. Choose the app for the folder in the organizer. Otherwise, folders open in your default file browser. The list also has code editors that open folders, like Xcode, Cursor, and Zed.

### Can I use aliases and symbolic links? {#aliases}

Yes. Super Menu follows them to open and browse the target. <kbd>Option</kbd>-click still shows the item you added.

### Can I add a folder from the Shortcuts app? {#shortcuts-folders}

Yes. Add a linked Shortcuts folder. It stays in sync with the Shortcuts app.

### Can I run a shortcut on a file, like a Quick Action? {#shortcut-on-file}

Yes. Edit a shortcut in the organizer and turn on “Show in file submenus”. It then shows in “Run Shortcut” in the submenu of each file in the menu, and gets the file as its input. Put the shortcut in a group with “Show: Never” to have it only in file submenus.

### My shortcut fails when it needs “Full Disk Access” {#full-disk-access}

Give Super Menu “Full Disk Access” too (“System Settings › Privacy & Security › Full Disk Access”). Super Menu runs the shortcut, so it needs the same permission.

### Can I pass input to a shortcut from the menu? {#shortcut-input}

Yes. For a file, see [above](#shortcut-on-file). For text, use a [link](#link-placeholders) that runs the shortcut, like `shortcuts://run-shortcut?name=Translate&input=text&text={input}` to ask for the text, or `&text={clipboard}` for the copied text. Use `input=clipboard` instead to give it what is on the clipboard, such as an image. The Shortcuts app comes to the front while the shortcut runs.

### Why does running a shortcut sometimes add a “Stop and Output” action to it? {#stop-and-output}

The Shortcuts app adds it when a shortcut has no clear output, like one that only opens an app. It is out of my control, and I have reported it to Apple: [FB19805797](https://github.com/feedback-assistant/reports/issues/703)

### Does the menu reorder itself based on what I use? {#auto-order}
<!-- @faq.keywords rearrange automatic -->

No. The menu stays as you arranged it. Only Recent Files and Running Apps change with use.

### I removed an item by mistake. Can I undo it? {#undo}
<!-- @faq.keywords accident restore -->

Yes. The organizer has full undo and redo. Changes save immediately.

### Why don’t I see my latest folder changes right away? {#folder-freshness}
<!-- @faq.keywords refresh stale outdated -->

A submenu that is already open does not change under your pointer. Close and reopen it. Folder contents older than five seconds show at once and refresh in the background.

### Does it watch or index my folders? {#background-activity}
<!-- @faq.keywords background cache -->

No. Super Menu does not watch your folders. It reads the folders in your menu when it starts, when you change the menu, and right after the menu closes, so they are ready the next time. Subfolders are read only when you open them. It keeps the listings in memory, never on disk, and does not keep its own cache of file previews.

### Will it download my iCloud files? {#icloud-downloads}
<!-- @faq.keywords dropbox onedrive -->

No. Browsing never downloads cloud files, and a slow provider cannot block the menu. Opening a file downloads it, like in Finder.

### What happens when a file moves or a drive disconnects? {#missing-items}
<!-- @faq.keywords missing unavailable network -->

The item leaves the menu but stays in the organizer, where Locate and Reauthorize fix it. It keeps its name, position, and settings, and comes back when the drive reconnects. Network shares are not mounted automatically ([why](/apps/faq#macos-sandbox)).

### Why did Super Menu ask for access to my home folder? {#home-folder-access}
<!-- @faq.keywords permission prompt -->

Only when you add a Finder Saved Search, as its results can be anywhere in your home folder. Results that the app cannot access are left out.

### Does it need Accessibility, Input Monitoring, or Screen Recording permission? {#permissions}
<!-- @faq.keywords monitoring -->

No. The only prompts are the standard file-access prompts when you add or reauthorize items.

### Does it track what I open? {#recent-tracking}
<!-- @faq.keywords history privacy -->

Only the files you open through Super Menu, so Recent Files can show them. Apps, folders, and links are not in the list. The history stays on your Mac, and you can clear it with “Clear Menu” in Recent Files.

### Can Super Menu modify or delete my files? {#read-only}
<!-- @faq.keywords rename move write -->

Only when you ask it to. It opens, previews, copies, reveals, and shares your files. The only changes it can make are “Move to Trash” in the submenu of a file, which you can undo in Finder, and “Paste”, “Paste Image as File”, and “Paste Text as File” in the submenu of a folder, which add files to it and never replace a file. “Remove Download” frees the space of an iCloud file, which stays in iCloud. Otherwise, the only thing it edits is the menu.

### Can you add sync? {#sync}
<!-- @faq.keywords macs computers -->

No. The access to the files that you add only works on the Mac where you added them.

### Can I run scripts or add plug-ins? {#scripts}
<!-- @faq.keywords plugin shell applescript -->

No, by design, as it is a security and reliability risk. Use shortcuts instead, or [Short Run](/short-run) for a menu of them.
