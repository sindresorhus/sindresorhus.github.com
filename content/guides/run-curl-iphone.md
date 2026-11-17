---
title: 'How to Run a cURL Command on iPhone'
description: 'iPhone has no Terminal and no curl command. Paste a curl command in the Run cURL Command action of the free Actions app in Shortcuts, and run it.'
publicationDate: 2026-11-17
topic: 'internet-and-network'
apps: [
	'actions'
]
---

@QuickAnswer {
	iPhone has no Terminal, so it has no `curl` command. The free [Actions](/actions) app adds a “Run cURL Command” action to the Shortcuts app. Paste a curl command, like one that you copied from the developer tools of a browser or from the documentation of an API, and run the shortcut.
}

## With Actions

@Steps {
1. Install [Actions](/actions), and open it once.
1. In the Shortcuts app, make a new shortcut, and add the [“Run cURL Command”](/actions#:~:text=Run%20cURL%20Command) action.
1. Paste the command in the action, like `curl -X POST 'https://httpbin.org/post' -H 'Content-Type: application/json' -d '{"name":"John"}'`.
1. Add the “Show Content” action, and run the shortcut.
}

The result is the response, with its status code, its headers, and its body. You can use each part in the next actions, like an “If” action on the status code.

The action supports the common options, like `-X`, `-H`, `-d`, `-u`, `-L`, `-m`, `-A`, `-G`, `-I`, and `--compressed`. It ignores `-s`, `-v`, and `-o`. Another option gives an error, as it could change the request, and `--data-binary @file` does not work. On iPhone, iOS stops an action of an app after about 30 seconds, so a large upload can fail.

## Without an app

The built-in “Get Contents of URL” action of Shortcuts sends a request too. Tap “Show More” in the action to choose the method, like “POST”, and to add headers. For “POST”, “PUT”, and “PATCH”, the action also has “Request Body”, which can be JSON, a form, or a file. <source:https://support.apple.com/guide/shortcuts/apd58d46713f/ios>

It works, but you must put each part of the command in its own field. The “Run cURL Command” action is faster when you already have a curl command.
