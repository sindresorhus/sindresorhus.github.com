import Foundation
import SiteKit

/**
An amount of money in a currency, like $4.99.

In frontmatter, it is a number of US dollars, like `20` or `4.99`.
*/
struct Price: Hashable {
	let amount: Decimal
	let currency: Locale.Currency

	/**
	An imported amount, including zero for a free app. Authored US-dollar prices use the stricter `init(validating:)`.
	*/
	init(amount: Decimal, currency: Locale.Currency = "USD") throws(ContentError) {
		guard
			!amount.isNaN,
			amount >= 0
		else {
			throw ContentError(reason: "A price must be a nonnegative amount, got \(amount).")
		}

		self.amount = amount
		self.currency = currency
	}

	/**
	Free, like for the offer of an app that costs nothing. Frontmatter prices are positive, so only the build makes this one.
	*/
	static let free = try! Self(amount: 0)

	var isFree: Bool {
		amount == 0
	}

	/**
	Like “$4.99”, or “$20” without cents for a whole amount.
	*/
	var formatted: String {
		amount.formatted(.currency(code: currency.identifier).locale(.site).precision(.fractionLength(amount.isWholeNumber ? 0 : 2)))
	}

	/**
	Like “$4.99, one-time purchase”.
	*/
	var oneTimePurchaseText: String {
		"\(formatted), one-time purchase"
	}
}

extension Price: ValidatedValue {
	init(validating rawValue: Double) throws(ContentError) {
		// Through the text, as 4.99 as a `Double` is 4.990000000000000213…
		guard
			rawValue > 0,
			let amount = Decimal(string: String(rawValue), locale: Locale(identifier: "en_US_POSIX")),
			(amount * 100).isWholeNumber
		else {
			throw ContentError(reason: "Must be a positive number of US dollars with at most two decimals, like `20` or `4.99`, got \(rawValue).")
		}

		try self.init(amount: amount)
	}
}
