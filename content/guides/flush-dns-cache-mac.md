---
title: 'How to Flush the DNS Cache on Mac'
description: 'Flush the DNS cache of macOS with one command in Terminal, or with the “Flush DNS Cache” button of Supercharge, without Terminal.'
publicationDate: 2026-11-09
topic: 'mac'
apps: [
	'supercharge'
]
---

@QuickAnswer {
	Open Terminal, run `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`, and enter your password. To do it with a button, without Terminal, use [Supercharge](../apps/supercharge/index.md).
}

## With Supercharge

@Steps {
1. Open the settings of [Supercharge](../apps/supercharge/index.md), and click “Tools”.
1. In the “Maintenance” section, click “Flush DNS Cache”.
1. Enter your administrator password.
}

Flushing the DNS cache can fix connection problems after a DNS change, like a website that does not load after it moved to a new server, or a new DNS server that seems to have no effect.

## Without an app

Open the Terminal app, and run this command:

```console
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

Enter your administrator password, and press ++Return++. Terminal shows no characters while you type the password, and there is no output when it works. If you are comfortable with Terminal, this is just as good as the button.
