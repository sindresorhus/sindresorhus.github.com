import Elementary
import Foundation
import SiteKit
import SOML

/**
A date for people, with the day for machines in `datetime`, in UTC like all dates on the site.

```swift
DateText(day: post.publicationDate, format: .siteMonth)
```
*/
struct DateText: HTML {
	let day: SOML.Date
	let format: Date.FormatStyle

	var body: some HTML<HTMLTag.time> {
		var format = format
		format.timeZone = .gmt

		return time(.dateTime(day)) {
			day.foundationDate.formatted(format)
		}
	}
}
