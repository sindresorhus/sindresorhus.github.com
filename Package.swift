// swift-tools-version: 6.4
import CompilerPluginSupport
import PackageDescription

// Warnings fail the build, so they are fixed right away.
let swiftSettings: [SwiftSetting] = [
	.treatAllWarnings(as: .error),
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
		.package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.9.0"),
		.package(url: "https://github.com/jpsim/Yams.git", exact: "6.2.2"),
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
				.product(name: "Yams", package: "Yams"),
			],
			swiftSettings: swiftSettings
		),
		.target(
			name: "Website",
			dependencies: [
				"RSS",
				"SiteKit",
				.product(name: "Elementary", package: "elementary"),
			],
			resources: [
				.copy("Resources/Fonts"),
			],
			swiftSettings: swiftSettings
		),
		.executableTarget(
			name: "WebsiteCLI",
			dependencies: [
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
		.testTarget(
			name: "SiteKitTests",
			dependencies: ["SiteKit"],
			swiftSettings: swiftSettings
		),
		.testTarget(
			name: "SiteKitMacrosTests",
			dependencies: [
				"SiteKitMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			],
			swiftSettings: swiftSettings
		),
		.testTarget(
			name: "WebsiteTests",
			dependencies: ["Website"],
			swiftSettings: swiftSettings
		),
	]
)
