---
title: 'How to Encrypt Text in Shortcuts on iPhone and Mac'
description: 'Encrypt a secret text with a key of your own in a shortcut with the free Actions app, and decrypt it later on any of your devices.'
publicationDate: 2026-11-21
topic: 'shortcuts'
apps: [
	'actions'
]
---

@QuickAnswer {
	Add the “Encrypt Text” action of the free [Actions](/actions) app, give it the text and a key of 32 characters, and it returns the encrypted text. To read it again, set the action to “Decrypt”, and use the same key. [Without an app](#without-an-app), the Shortcuts app has no action that encrypts text.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In your shortcut, add the [“Encrypt Text”](/actions#:~:text=Encrypt%20Text) action of Actions.
1. Put the text in the action, and type a key of exactly 32 English letters and digits, like a random password.
1. Run the shortcut. The result is the encrypted text, which you can save in a file or send.
1. To decrypt, make a shortcut with the same action, choose “Decrypt” in place of “Encrypt”, and give it the encrypted text and the same key.
}

The action uses AES-256-GCM, and works on the device: nothing leaves it. The encrypted text is Base64 text, so you can paste it anywhere. Without the key, nobody can read it, also not you, so keep the key safe.

@Tips {
- Do not put the key in a shortcut that you share. Read it from a file on your device, like with the “Get File from Folder” action.
- To encrypt a photo or another file, use the “Encrypt File” action of Actions.
}

## Without an app

The Shortcuts app can change text to Base64 with the “Base64 Encode” action, but that is not encryption: anyone can decode it.

To keep a text private without a shortcut, put it in a locked note in the Notes app.
