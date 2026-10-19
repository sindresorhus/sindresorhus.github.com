import Foundation
import SiteKit
import TestSupport
import Testing
@testable import Website

@Suite
struct ExternalDataDecodingTests {
	/**
	A response that cannot be decoded is removed from the cache, so the next build asks again instead of using it until it expires.
	*/
	@Test(.temporaryDirectory)
	func `an unexpected response is an error, and is not kept in the cache`() async throws {
		struct Totals: Decodable {
			let count: Int
		}

		let url = #URL("https://example.com/totals")
		let directory = try URL.temporaryDirectory()
		let cache = try ResponseCache(responses: [url.absoluteString: #"{"error": "Not found"}"#], directory: directory)
		#expect(try directory.filesRecursively().count == 1)

		await #expect(throws: (any Error).self) {
			try await cache.decoded(Totals.self, from: URLRequest(url: url))
		}

		#expect(try directory.filesRecursively().isEmpty)
	}
}
