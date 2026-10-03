// swift-tools-version: 6.1
import PackageDescription

let package = Package(
	name: "SindreSorhusWebsite",
	platforms: [
		.macOS(.v14),
	],
	products: [
		.library(name: "SiteCore", targets: ["SiteCore"]),
		.executable(name: "website", targets: ["Website"]),
	],
	dependencies: [
		.package(url: "https://github.com/elementary-swift/elementary.git", exact: "0.8.2"),
		.package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.9.0"),
		.package(url: "https://github.com/jpsim/Yams.git", exact: "6.2.2"),
	],
	targets: [
		.target(
			name: "SiteCore",
			dependencies: [
				.product(name: "Elementary", package: "elementary"),
				.product(name: "Markdown", package: "swift-markdown"),
				.product(name: "Yams", package: "Yams"),
			]
		),
		.executableTarget(
			name: "Website",
			dependencies: ["SiteCore"]
		),
		.testTarget(
			name: "SiteCoreTests",
			dependencies: ["SiteCore"]
		),
	]
)
