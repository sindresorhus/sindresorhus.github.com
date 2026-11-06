---
title: 'How to Run JavaScript in Shortcuts on iPhone and Mac'
description: 'The JavaScript actions of Shortcuts run on a web page in Safari, or control Mac apps. The free Actions app adds an action that runs JavaScript on any text.'
publicationDate: 2026-11-11
topic: 'iphone'
apps: [
	'actions'
]
---

@QuickAnswer {
	The “Run JavaScript on Web Page” action of Shortcuts needs a web page from Safari as its input. To run JavaScript on a text in any shortcut, like to change it with a regular expression, add the “Transform Text with JavaScript” action of the free [Actions](../apps/actions/index.md) app.
}

## With Actions

@Steps {
1. Install [Actions](../apps/actions/index.md), and open it once.
1. In your shortcut, add the “Transform Text with JavaScript” action of Actions.
1. In the first field, choose the text, like the result of the action above it.
1. In the second field, write the code. The text is in the `$text` variable, and the code must return a string.
}

For example, this code keeps only the lines that have an email address:

```js
return $text.split('\n').filter(line => line.includes('@')).join('\n');
```

The result is “Transformed Text”. To return an object, return it as JSON with `JSON.stringify()`, and give the result to the “Get Dictionary from Input” action of Shortcuts.

The code runs in JavaScriptCore, the JavaScript engine of Safari, and without a web page. So it has the JavaScript language, like `JSON`, `Math`, and regular expressions, but not the things of a browser, like `document` and `fetch`. The code must be synchronous: it cannot wait for a promise.

## Without an app

**On a web page:** The “Run JavaScript on Web Page” action runs your code on the page that is open in Safari, like to get data from the page, or to change it. On iPhone and iPad, turn on “Show in Share Sheet” in the details of the shortcut, and run the shortcut from the share sheet of Safari. Before the first run, you must turn on “Allow Running Scripts” in the settings of Shortcuts. [Apple’s instructions.](https://support.apple.com/guide/shortcuts/apdb71a01d93/ios)

**On Mac:** The “Run JavaScript for Mac Automation” action runs JavaScript that controls the apps of your Mac. It is not on iPhone or iPad.

These actions are the right tools for a web page, or to control Mac apps. To only calculate something or change a text, the action of Actions is simpler, and the same shortcut works on iPhone, iPad, and Mac.
