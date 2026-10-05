import Elementary
import Foundation
import SiteKit

/**
A date for people, with the day for machines in `datetime`, in UTC like all dates on the site.

```swift
DateText(post.publicationDate, format: .siteMonth)
```
*/
struct DateText: HTML {
	let date: Date
	let format: Date.FormatStyle

	init(_ date: Date, format: Date.FormatStyle) {
		self.date = date
		self.format = format
	}

	var body: some HTML<HTMLTag.time> {
		time(.custom(name: "datetime", value: date.isoDay)) {
			date.formatted(format)
		}
	}
}
