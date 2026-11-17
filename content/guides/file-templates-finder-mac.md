---
title: 'How to Make a New File from a Template in Finder on Mac'
description: 'Right-click in a Finder folder and make a new file from your own templates with Supercharge, or make a stationery pad with “Get Info”.'
publicationDate: 2026-11-22
topic: 'finder-and-desktop'
isForWindowsUsers: true
apps: [
	'supercharge'
]
---

@QuickAnswer {
	In the “Tweaks” settings of [Supercharge](/supercharge), click “Configure…” next to “Context menu items”, turn on “New From Template”, and put your template files in its Templates folder. Then right-click an empty area of a Finder folder, and choose a template in “New”. [Without an app](#without-an-app), select the file in Finder, choose “File › Get Info”, and turn on “Stationery pad”.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “New From Template”.
1. Click the settings button next to it, and click “Open Templates Folder”. Put your template files in this folder, like a Markdown file with your headings.
1. In Finder, right-click an empty area of the folder for the new file, and choose “New” and the template.
1. Type the name of the new file, and press ++Return++.
}

The Templates folder is “Documents › Supercharge › Templates”, and it has templates for text, Markdown, Pages, Numbers, and Keynote to start. A folder in it is a submenu, and choosing the folder itself copies the folder with all its files, like the folders of a new project. A name like `Diary {date-fixed}.md` gets the date of today, like “Diary 2026-11-22.md”.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox.

## Without an app

Unlike Windows, Finder has no “New” menu, but a file can be a stationery pad. When you open it, you get a copy of it, and the template stays the same:

@Steps {
1. Select the template file in Finder, and choose “File › Get Info”.
1. In “General”, turn on “Stationery pad”.
1. Double-click the file. You get a new copy of it to edit.
}

The template stays in its folder, so you must save or move each new file to where it belongs. Supercharge makes the file in the folder that is open.
