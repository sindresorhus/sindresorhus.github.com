import Foundation
import SiteCore

@main
struct WebsiteCommand {
	static func main() async throws {
		let arguments = Array(CommandLine.arguments.dropFirst())
		let command = arguments.first ?? "build"
		let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
		let builder = SiteBuilder(root: root)

		switch command {
		case "build":
			let report = try await builder.build()
			print("Built \(report.routeCount) routes from \(report.appCount) apps and \(report.postCount) blog posts.")
			if !report.validation.brokenInternalLinks.isEmpty {
				print("Broken internal links:")
				for link in report.validation.brokenInternalLinks { print("- \(link)") }
				throw Exit.invalidSite
			}
		case "validate":
			let report = try await builder.build()
			guard report.isValid else {
				for link in report.validation.brokenInternalLinks { print("- \(link)") }
				throw Exit.invalidSite
			}
			print("Validation passed: \(report.routeCount) routes.")
		default:
			print("Usage: swift run website [build|validate]")
			throw Exit.invalidArguments
		}
	}
}

enum Exit: Error { case invalidArguments, invalidSite }
