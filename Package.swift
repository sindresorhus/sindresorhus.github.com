// swift-tools-version: 6.4
import CompilerPluginSupport
import PackageDescription

// Each target lists every module it imports, also one that a dependency already brings in. SwiftPM does not check it, as all modules of a build are in one folder, but it orders and invalidates builds only by the listed dependencies, so an unlisted module could leave a stale build, or break the build when the dependency that brought it in drops it.

// Warnings fail the build, so they are fixed right away.
let swiftSettings: [SwiftSetting] = [
	.treatAllWarnings(as: .error),
	.enableUpcomingFeature("ExistentialAny"),
	.enableUpcomingFeature("MemberImportVisibility"),
	.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
	.enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
	name: "SindreSorhusWebsite",
	platforms: [
		.macOS(.v26),
	],
	products: [
		.library(name: "RSS", targets: ["RSS"]),
		.executable(name: "website", targets: ["WebsiteCLI"]),
	],
	dependencies: [
		.package(url: "https://github.com/elementary-swift/elementary.git", exact: "0.8.2"),
		// A fork with footnotes, cmark extensions like autolinks, and GitHub alerts, which upstream does not have yet.
		.package(url: "https://github.com/sindresorhus/swift-markdown.git", branch: "sindre-improvements"),
		.package(url: "https://github.com/soml-lang/SOMLSwift.git", exact: "0.0.1"),
		.package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.8.2"),
		.package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0"),
	],
	targets: [
		.target(
			name: "RSS",
			swiftSettings: swiftSettings
		),
		.macro(
			name: "SiteKitMacros",
			dependencies: [
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				.product(name: "SwiftDiagnostics", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			],
			swiftSettings: swiftSettings
		),
		.target(
			name: "SiteKit",
			dependencies: [
				"SiteKitMacros",
				.product(name: "Elementary", package: "elementary"),
				.product(name: "Markdown", package: "swift-markdown"),
				.product(name: "SOML", package: "SOMLSwift"),
				// The parser of Swift classifies the tokens of Swift code blocks for syntax highlighting.
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftParser", package: "swift-syntax"),
				.product(name: "SwiftIDEUtils", package: "swift-syntax"),
			],
			swiftSettings: swiftSettings
		),
		.target(
			name: "Website",
			dependencies: [
				"RSS",
				"SiteKit",
				.product(name: "Elementary", package: "elementary"),
				.product(name: "Markdown", package: "swift-markdown"),
			],
			// The scripts of the elements, next to their Swift files. The build reads them from the sources (`ElementScript`), so a change shows in the preview without building the tool again. Each folder must be listed, as SwiftPM has no patterns, and a list made with `FileManager` would miss new folders, since SwiftPM caches the evaluated manifest.
			exclude: [
				"Components/Scripts",
				"Pages/1999/Scripts",
			],
			resources: [
				.copy("Resources/Fonts"),
			],
			swiftSettings: swiftSettings
		),
		.executableTarget(
			name: "WebsiteCLI",
			dependencies: [
				"SiteKit",
				"Website",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			],
			swiftSettings: swiftSettings
		),
		.testTarget(
			name: "RSSTests",
			dependencies: ["RSS"],
			swiftSettings: swiftSettings
		),
		// The helpers that several test targets use.
		.target(
			name: "TestSupport",
			path: "Tests/TestSupport",
			swiftSettings: swiftSettings
		),
		.testTarget(
			name: "SiteKitTests",
			dependencies: [
				"SiteKit",
				"TestSupport",
				.product(name: "Elementary", package: "elementary"),
				.product(name: "Markdown", package: "swift-markdown"),
			],
			swiftSettings: swiftSettings
		),
		.testTarget(
			name: "SiteKitMacrosTests",
			dependencies: [
				"SiteKitMacros",
				.product(name: "SwiftDiagnostics", package: "swift-syntax"),
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			],
			swiftSettings: swiftSettings
		),
		.testTarget(
			name: "WebsiteTests",
			dependencies: [
				"RSS",
				"SiteKit",
				"TestSupport",
				"Website",
				.product(name: "Elementary", package: "elementary"),
			],
			swiftSettings: swiftSettings
		),
	]
)
