---
title: 'How to Copy the Folder Structure as a Tree on Mac'
description: 'Copy the folders and files of a folder as a text tree for a document or an AI chat, from the right-click menu of Finder with Supercharge, or in Terminal.'
publicationDate: 2026-11-17
topic: 'finder-and-desktop'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Right-click a folder in Finder, and choose “Copy Folder Tree” from [Supercharge](/supercharge). You get the folders and files as a text tree, which you can paste in a document, an issue, or a message to an AI chat. [Without an app](#without-an-app), the `find` command in Terminal lists the paths, but not as a tree.
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](/supercharge), click “Tweaks”, and click “Configure…” next to “Context menu items”.
1. In the “Main Menu” tab, turn on “Copy Folder Tree”.
1. Right-click a folder in Finder, and choose “Copy Folder Tree”. For the open folder, right-click an empty area of the window.
1. Paste the tree.
}

The result is like this:

```
Project/
├── src/
│   └── main.swift
└── README.md
```

Folders come first. Hidden files are not included, and an app or another package is one line. A tree with more than 1000 items stops with a line that tells you so.

The right-click items cannot show in synced folders, like iCloud Drive and Dropbox. There, right-click the folder, and choose “Services › Copy Folder Tree”.

## Without an app

In Terminal, [go to the folder](guide:open-terminal-in-folder-mac), and copy its paths without hidden files:

```console
cd ~/Projects/site
find . -not -path '*/.*' | sort | pbcopy
```

The result is one path on each line, like `./src/main.swift`, not a tree. The `tree` command prints a tree, but macOS does not have it. You can install it with [Homebrew](https://brew.sh):

```console
brew install tree
```

The `find` command is fine for a short list. Supercharge gives the tree in one click, without Terminal.
