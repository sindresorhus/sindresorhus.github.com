---
title: 'How to Read a CSV File in Shortcuts on iPhone and Mac'
description: 'Turn a CSV file into a list of rows with a value for each column, with the Parse CSV action of the free Actions app, instead of splitting the text yourself.'
publicationDate: 2026-11-12
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Parse CSV” action of the free [Actions](../apps/actions/index.md) app, and give it the CSV file or text. The result is a list with a dictionary for each row, so “Get Dictionary Value” gets a value by the name of its column. The Shortcuts app itself has no action for CSV, only “Split Text”.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In your shortcut, add the “Parse CSV” action of Actions.
1. In “CSV”, choose the file, or select the result of an earlier action, like “Select File” or the text of “Get Contents of URL”.
1. Expand the action. If the first row of the file has no column names, turn off “First Row Is Header”. For a file with tabs between the values, change “Delimiter” to “Tab”. For another character, like a semicolon, choose “Custom”, and type the character.
1. Add “Repeat with Each” below it, and in the repeat, add “Get Dictionary Value” with the name of a column as the key, like `Email`.
}

The result, “Parsed CSV”, has one dictionary for each row. A value can have commas and line breaks in quotes, like in the CSV files of Numbers and Excel.

@Tips {
- To keep only some rows, use “Filter List of Dictionaries” of Actions. To sort them by a column, use “Sort List of Dictionaries”.
- To show the rows as a table, use “Make Markdown Table”. To make a CSV file, use “Generate CSV”.
- A row that has no value in a column has no key for it. Turn on “Consistent Structure” to give each row all the columns.
}

## Without an app

The Shortcuts app can split the text of a simple CSV file:

@Steps {
1. Add “Split Text”, and split the CSV text by “New Lines”.
1. Add “Repeat with Each”, and in the repeat, add a second “Split Text” with “Custom” and a comma.
1. Use “Get Item from List” to get the value of a column by its number.
}

This works only when no value has a comma or a line break, as Shortcuts splits them too. You must also skip the row with the column names yourself.
