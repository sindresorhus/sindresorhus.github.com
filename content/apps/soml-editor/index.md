---
isUnlisted: true
title: 'SOML Editor'
subtitle: 'View and edit SOML files'
publicationDate: '2026-10-12'
platforms: [
	'macOS'
	# 'iOS'
	# 'visionOS'
]
appStoreID: 6821636565
# requirement: 'macOS 27 or iOS 27 or later'
requirement: 'macOS 27 or later'
---

[SOML](https://soml.sh) is a new config format for humans, and an alternative to JSON.

Browse your document as a tree alongside its source. Find keys and values, inspect their types, and edit individual settings while preserving surrounding comments and formatting.

**Features**

- Syntax highlighting, bracket matching, and clear error messages
- Searchable outline and quick navigation by key path
- Edit values, rename keys, duplicate, and reorder items, while keeping comments
- View lists of records as a sortable, editable table
- Automatic formatting as you type
- Change how a value is written, like an int in hexadecimal or an instant in local time
- Import JSON, YAML, TOML, and property lists, and export JSON and PDF
- Paste JSON and get SOML
- Preview files with Quick Look
- Automate editing, merging, validation, and conversion with Shortcuts

*iOS version is planned*

## Tips {#tips}

### Work with several rows at once

<kbd>Command</kbd>-click or <kbd>Shift</kbd>-click rows in the outline to select several. Move Up, Move Down, and Delete in the Node menu then apply to all of them. Drag rows to reorder them within their object or array. Drag rows to another app to get them as SOML text, or as JSON in apps that want JSON.

### Show a list of records as a table

When every member of an object or an array is an object, like a list of servers, choose “Node › Show as Table” or press <kbd>Control+Command+T</kbd>. Click a column header to sort, and choose “Apply Order” to put the items in that order in the document. Edit a cell in place. “Copy as TSV” copies the table for a spreadsheet.

### Duplicate and rename in one go

Press <kbd>Command+D</kbd> to duplicate the selected item. For a member, the key of the copy is selected in the source, so you can type the new name right away.

### Change a number, duration, or date with the keyboard

Put the caret on a value and press <kbd>Control+Command+Up Arrow</kbd> or <kbd>Control+Command+Down Arrow</kbd>. The value changes by one and keeps how it is written, so `0x00FF` becomes `0x0100`, and the caret on the minutes of `1h30m` gives `1h31m`. On an instant, the part under the caret changes. On a bool, it switches between `true` and `false`.

### Write a value in another way

Right-click an item and choose “Convert” to write an int in decimal, hexadecimal, octal, or binary, group its digits, write a duration in its shortest form, or an instant in UTC or your local time. A string such as `'false'` or `'30s'` can become the value it looks like.

### Turn a setting off without deleting it

Choose “Node › Comment Out” or press <kbd>Option+Command+/</kbd> to make the item a `#` comment. In the source, <kbd>Command+/</kbd> comments or uncomments the selected lines.

### Paste JSON

Paste JSON in the source and it becomes SOML that fits where you paste it: members on their own lines, or a value with braces after a key. Use “Edit › Paste and Match Style” to paste the text as it is.

### Convert text in any app

Select JSON, YAML, or TOML in any app and choose “Services › Convert Selection to SOML”. “Convert Selection to JSON” does the opposite.

### See what a date or duration means

Hover over an instant or a duration in the outline to see it in your local time or in words. The edit sheet shows the same while you type.

### Use the outline from the keyboard

Press <kbd>Command+1</kbd> to focus the outline and <kbd>Command+2</kbd> to return to the source. <kbd>Return</kbd> edits the selected value, switches a bool, or expands a container. <kbd>Option</kbd>-click a disclosure arrow to expand or collapse everything inside it.

### Paste code with colors

Choose “Edit › Copy with Syntax Highlighting” to paste the source with colors into apps like Pages, Keynote, or Mail.

### Files from Windows

SOML uses LF line endings. When you open a file with CRLF line endings, the app converts it, and you can undo that.

### Layered config with Shortcuts

The “Merge SOML” action puts an overlay, like your own settings, over a base file, like the defaults, and the base keeps its comments. The “Canonicalize SOML” action can give a hash that only changes when the values change, not when comments or formatting do.

## Frequently Asked Questions {#faq}

### What is SOML?

[SOML](https://soml.sh) is a configuration format designed to be pleasant to write and easy to read. It supports comments, unquoted keys, multiline strings, dates, and durations. Top-level objects need no braces, and line breaks can replace commas. A value’s type comes from its syntax, so `'123'` is always a string and `123` is a number.

### Why use this instead of a regular text editor?

The outline lets you browse nested values without following brackets by hand. You can inspect types, jump to a key path, and edit or move individual items while keeping surrounding comments. You can still edit the source directly whenever you prefer. The main usefulness, however, is to get Quick Look previews of SOML files.

### Why does it require macOS 27 or later?

The app uses newer system APIs for document handling and text editing. Supporting older versions would mean extra testing, compatibility code, and working around older system bugs. Keeping the requirements current lets me focus on improving the app.

### Can I use the app offline? Are my files uploaded anywhere?

Editing, validation, formatting, and conversion all run locally on your Mac. The app does not upload your documents. If you save a file in iCloud Drive or another synced folder, that service handles syncing it.

### Can I edit JSON, TOML, or YAML files?

The app edits SOML files. You can import JSON, TOML, YAML, and property lists as SOML, and export SOML as JSON. Import discards comments and formatting. TOML and YAML dates and times become strings, and property list dates become SOML dates. Exporting to TOML, YAML, or property lists is not supported.

### Does converting to JSON preserve everything?

No. JSON has no comments, dates, or durations. Comments and source formatting are lost, and dates and durations become strings. Converting those strings back to SOML leaves them as strings. Values such as `infinity` cannot be exported as JSON.

### Does editing preserve comments and formatting?

Editing an individual value preserves the surrounding source. Renaming keys and moving items also preserve their source spelling and attached comments.

When you pause typing, the app formats the document: it fixes indentation, spacing, and commas, and keeps one-line objects and arrays on one line. You can turn this off in settings. “Edit › Format Document” also expands nonempty objects and arrays onto separate lines. Both keep comments and value spelling.

### Can I open my files in other editors?

Yes. SOML files are ordinary UTF-8 text files. There is no app-specific wrapper or database. You can edit them in another text editor and track changes with Git.

### Can I preview a file without opening it?

Yes. Select a `.soml` file in Finder and press <kbd>Space</kbd> to see its Quick Look preview.

### How can I sync files between devices?

Save your files in iCloud Drive or another file provider available on your devices. SOML documents are ordinary text files, so you can also share them or keep them in version control.

### Can I automate the app with Shortcuts?

Yes. It provides actions to format, validate, and canonicalize SOML, convert between SOML and JSON, convert YAML, TOML, and property lists to SOML, get, set, and remove a value at a key path, rename a key, set a comment, get the keys or items at a path, and merge two documents. The editing actions keep comments and formatting. The actions accept text or a file and run without opening the editor.

### How can I jump to a deeply nested value?

Choose “View › Go to Path…” or press <kbd>Command+Shift+O</kbd>, then search for a path such as `server.host` or `items[0]`. You can also filter keys and values in the outline.

### Can I navigate the outline with the keyboard?

Press <kbd>Command+1</kbd> to focus the outline, then use the arrow keys to navigate it. Press <kbd>Command+2</kbd> to return to the source editor. The Node menu lists shortcuts for editing, renaming, moving, and deleting items.

### How can I copy a string without its quotes?

Right-click the item in the outline and choose “Copy String Contents”. This copies the string’s value, including decoded escape sequences. “Copy Value” copies its SOML source instead, including quotes. “Copy String Contents” only appears for strings.

### How can I make the source easier to read?

Use “View › Bigger Text” to increase the text size. The View menu also lets you toggle line wrapping and show invisible characters. Settings has options for indentation guides and highlighting the current line.

### Why can’t I edit values in the outline?

Fix any syntax errors in the source first. While the document is invalid, the outline shows the last valid structure and disables edits. The error message helps you find what needs fixing.
