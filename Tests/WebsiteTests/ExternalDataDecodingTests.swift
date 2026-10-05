import Foundation
import SiteKit
import Testing
@testable import Website

@Suite
struct ExternalDataDecodingTests {
	@Test
	func `the App Store file size is read from its string`() throws {
		let json = #"{"trackId": 1453273600, "fileSizeBytes": "7719936"}"#
		let info = try JSONDecoder().decode(AppStoreInfo.self, from: Data(json.utf8))
		#expect(info.fileSizeBytes == 7_719_936)

		let infoWithoutSize = try JSONDecoder().decode(AppStoreInfo.self, from: Data(#"{"trackId": 1}"#.utf8))
		#expect(infoWithoutSize.fileSizeBytes == nil)
	}

	/**
	A response that cannot be decoded is removed from the cache, so the next build asks again instead of using it until it expires.
	*/
	@Test(.temporaryDirectory)
	func `an unexpected response is an error, and is not kept in the cache`() async throws {
		struct Totals: Decodable {
			let count: Int
		}

		let url = "https://example.com/totals"
		let directory = try URL.temporaryDirectory()
		let cache = try ResponseCache(responses: [url: #"{"error": "Not found"}"#], directory: directory)
		#expect(try directory.filesRecursively().count == 1)

		await #expect(throws: (any Error).self) {
			try await cache.decoded(Totals.self, from: URLRequest(url: URL(string: url)!))
		}

		#expect(try directory.filesRecursively().isEmpty)
	}
}
