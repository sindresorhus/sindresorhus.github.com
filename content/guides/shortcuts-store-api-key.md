---
title: 'How to Store an API Key Safely in Shortcuts on iPhone and Mac'
description: 'Keep an API key in the keychain, not in the text of a shortcut, with the free Actions app, so you can share the shortcut without the key.'
publicationDate: 2026-11-23
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Save the key once with the “Keychain: Set” action of the free [Actions](/actions) app. Then get it in your shortcut with “Keychain: Get”, so the key is not in the shortcut. [Without an app](#without-an-app), keep the key in a text file, and read the file in the shortcut.
}

A key in a “Text” action is part of the shortcut. When you share the shortcut, the key goes with it.

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. Make a new shortcut, and add the [“Keychain: Set”](/actions#:~:text=Keychain) action of Actions.
1. Type a name for the key, like `openai`, and paste the API key as the value. To have the key on all your devices, expand the action, and turn on “Sync to iCloud”.
1. Run the shortcut once. Then delete the shortcut, so the key is only in the keychain.
1. In the shortcut that uses the API, add “Keychain: Get” with the same name. Use its result, “Keychain Value”, where the key goes, like in a header of “Get Contents of URL”.
}

“Sync to iCloud” needs iCloud Keychain. Without it, the key is only on the device where you saved it. When the key does not exist, “Keychain: Get” returns nothing.

@Tips {
- To remove a key, use “Keychain: Delete”.
- To check that a key exists before you use it, use “Keychain: Has Key”.
- For ChatGPT, Claude, and Gemini, the actions of AI Actions keep the key in their own settings. <guide:chatgpt-in-shortcuts>
}

## Without an app

Put the key in a text file, like in the Shortcuts folder of iCloud Drive. In the shortcut, read the file with the “Get File from Folder” action, and use the result where the key goes.

When you share the shortcut, the key stays in the file. But the file is plain text, so all apps and people that can open the file can read the key. The keychain keeps it encrypted.
