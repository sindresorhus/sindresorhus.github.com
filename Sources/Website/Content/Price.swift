import Foundation
import SiteKit

/**
An amount of money in a currency, like $4.99.

In frontmatter, it is a number of US dollars, like `20` or `4.99`.
*/
struct Price: Hashable, Sendable {
	let amount: Decimal
	let currency: Locale.Currency

	init(_ amount: Decimal, currency: Locale.Currency = "USD") {
		self.amount = amount
		self.currency = currency
	}

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

		self.init(amount)
	}
}
