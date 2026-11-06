import Foundation
import SiteKit
import Testing
@testable import Website

struct DiagnosticIdentityTests {
	@Test
	func `shared diagnostics deduplicate by source and payload rather than their originating page`() async throws {
		let html = #"<a href="/missing">Link</a>"#
		let first = Route.page(#path("/first")) { html }
		let second = Route.page(#path("/second")) { html }
		let published = PublishedSite(routeFiles: ["first.html": Data(html.utf8), "second.html": Data(html.utf8)], publicFiles: [])
		let links = await LinkValidator(site: SiteOrigin(#URL("https://example.com"))).brokenLinks(in: [first, second], published: published)
		let firstLink = try #require(links.first)
		let secondLink = try #require(links.last)
		let location = SourceLocation.file(URL(filePath: "/content/shared-questions.md"), line: 4)
		let firstDiagnostic = Site.BuildReport.BrokenLink(link: firstLink, location: location, draftFile: nil)
		let secondDiagnostic = Site.BuildReport.BrokenLink(link: secondLink, location: location, draftFile: nil)
		#expect(firstLink.page != secondLink.page)
		#expect(firstDiagnostic.identity == secondDiagnostic.identity)
		let differentLine = Site.BuildReport.BrokenLink(link: firstLink, location: .file(URL(filePath: "/content/shared-questions.md"), line: 5), draftFile: nil)
		#expect(firstDiagnostic.identity != differentLine.identity)
	}
}
