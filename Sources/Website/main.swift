import ArgumentParser
import Foundation
import SiteCore

@main
struct WebsiteCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "website",
		abstract: "Build and validate sindresorhus.com.",
		subcommands: [Build.self, Validate.self, Serve.self],
		defaultSubcommand: Build.self
	)
}

private struct SiteOptions: ParsableArguments {
	@Option(help: "Repository root directory.")
	var root = "."

	@Option(help: "Output directory. Defaults to <root>/dist.")
	var output: String?

	func builder() -> SiteBuilder {
		let rootURL = URL(
			fileURLWithPath: root,
			relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
		).standardizedFileURL

		let outputURL = output.map {
			URL(fileURLWithPath: $0, relativeTo: rootURL).standardizedFileURL
		}

		return SiteBuilder(root: rootURL, output: outputURL)
	}
}

extension WebsiteCommand {
	struct Build: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Generate the static site."
		)

		@OptionGroup
		var site: SiteOptions

		mutating func run() async throws {
			let report = try await site.builder().build()
			print("Built \(report.routeCount) routes from \(report.appCount) apps and \(report.postCount) blog posts.")

			guard report.isValid else {
				printValidationErrors(report.validation)
				throw ExitCode.failure
			}
		}
	}

	struct Validate: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Build the site and validate internal links."
		)

		@OptionGroup
		var site: SiteOptions

		mutating func run() async throws {
			let report = try await site.builder().build()

			guard report.isValid else {
				printValidationErrors(report.validation)
				throw ExitCode.failure
			}

			print("Validation passed: \(report.routeCount) routes.")
		}
	}

	struct Serve: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Build the site and serve the generated output locally."
		)

		@OptionGroup
		var site: SiteOptions

		@Option(name: .shortAndLong, help: "HTTP port.")
		var port = 4321

		mutating func validate() throws {
			guard (1...65_535).contains(port) else {
				throw ValidationError("Port must be between 1 and 65535.")
			}
		}

		mutating func run() async throws {
			let builder = site.builder()
			let report = try await builder.build()

			guard report.isValid else {
				printValidationErrors(report.validation)
				throw ExitCode.failure
			}

			print("Serving \(builder.output.path) at http://localhost:\(port)")

			let process = Process()
			process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
			process.arguments = [
				"python3",
				"-m",
				"http.server",
				String(port),
				"--directory",
				builder.output.path,
			]
			try process.run()
			process.waitUntilExit()

			guard process.terminationStatus == 0 else {
				throw ExitCode(process.terminationStatus)
			}
		}
	}
}

private func printValidationErrors(_ validation: ValidationReport) {
	guard !validation.brokenInternalLinks.isEmpty else {
		return
	}

	print("Broken internal links:")
	for link in validation.brokenInternalLinks {
		print("- \(link)")
	}
}
