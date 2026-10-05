import Foundation
import SiteKit
import Testing
@testable import Website

/**
The components that are custom elements (``ScriptedElement``) and their scripts next to their Swift files.
*/
@Suite
struct ScriptedElementTests {
	private static let sourceDirectory = Project.website.root.appending(path: "Sources/Website")

	@Test
	func `every script in the sources is the script of a listed element, and the package excludes its folder`() throws {
		let scripts = try Self.sourceDirectory.filesRecursively().filter { $0.pathExtension == "js" }
		let listed = Set(Site.scriptedElements.compactMap { $0.script.file?.resolvingSymlinksInPath().path })
		let package = try String(contentsOf: Project.website.root.appending(path: "Package.swift"), encoding: .utf8)

		#expect(!scripts.isEmpty)

		for script in scripts {
			let path = script.path(relativeTo: Self.sourceDirectory)
			#expect(listed.contains(script.resolvingSymlinksInPath().path), "\(path) is not the script of an element in `Site.scriptedElements`.")
			let folder = script.deletingLastPathComponent().path(relativeTo: Self.sourceDirectory)
			#expect(package.contains("\"\(folder)\""), "The folder of \(path), \(folder), is not in the `exclude` of the Website target in Package.swift.")
		}
	}

	@Test
	func `every element has a valid tag name and a script`() throws {
		for element in Site.scriptedElements {
			#expect(element.tagName.wholeMatch(of: /[a-z][a-z0-9]*(-[a-z0-9]+)+/) != nil, "\(element.tagName) is not a valid name of a custom element.")
			if let file = element.script.file {
				#expect(file.isFile, "\(element) has no script at \(file.path(percentEncoded: false)).")
			}

			#expect(throws: Never.self, "\(element) has an invalid script.") {
				try element.generatedScript()
			}
		}
	}

	/**
	A script that uses a part that the component does not have would find nothing. The base class throws for it when it runs (`this.parts`), and this test finds it without running it, for the direct forms of ``usedParts(in:)``. A part that the markup has but no script uses is only a leftover attribute, so it is not checked.
	*/
	@Test
	func `every part that a script uses is declared`() throws {
		for element in Site.scriptedElements {
			let usedParts = Self.usedParts(in: Self.code(of: try element.script.source))
			#expect(usedParts.subtracting(element.declaredParts).sorted() == [], "The script of \(element) uses parts that `\(element).Parts` does not have.")
		}
	}

	@Test
	func `only the parts of the element itself count as used`() {
		let script = """
		const {screen, sound} = this.parts;
		const {
			start,
			stop: stopButton,
		} = this.parts;
		this.parts.odds.textContent = '';
		const {width, height} = this.parts.canvas;
		const marbles = game.parts.filter(part => part.isMarble);
		const keys = this.querySelectorAll('[data-part="key"]');
		"""

		#expect(Self.usedParts(in: script) == ["screen", "sound", "start", "stop", "odds", "canvas", "key"])
	}

	@Test(.enabled(if: Self.isNodeAvailable, "Install Node.js to check the syntax of the scripts of the elements."))
	func `the script that the build writes for each element is valid JavaScript`() throws {
		for element in Site.scriptedElements {
			let process = Process()
			process.executableURL = URL(filePath: "/usr/bin/env")
			process.arguments = ["node", "--input-type=module", "--check"]
			let input = Pipe()
			let errors = Pipe()
			process.standardInput = input
			process.standardError = errors
			try process.run()
			try input.fileHandleForWriting.write(contentsOf: Data(element.generatedScript().utf8))
			try input.fileHandleForWriting.close()
			process.waitUntilExit()

			let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
			#expect(process.terminationStatus == 0, "The script of \(element) has a syntax error: \(message)")
		}
	}

	private static var isNodeAvailable: Bool {
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["node", "--version"]
		process.standardOutput = FileHandle.nullDevice
		process.standardError = FileHandle.nullDevice

		guard (try? process.run()) != nil else {
			return false
		}

		process.waitUntilExit()
		return process.terminationStatus == 0
	}

	/**
	The script without its comment lines, so a part in a comment is not a use.
	*/
	private static func code(of script: String) -> String {
		script
			.split(separator: "\n")
			.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
			.joined(separator: "\n")
	}

	/**
	The parts that a script uses directly: `this.parts.screen`, `const {screen, status} = this.parts;` (also with `screen: name`), and `data-part="key"`, like in `querySelectorAll('[data-part="key"]')` for a list of the same part. Not `game.parts.filter` or `const {width} = this.parts.canvas`, which are not parts. A part that a function gets in `this.parts`, like `setUp(this, this.parts)`, is only checked when it runs.

	The word boundaries are simple, as the default Unicode ones treat `this.parts.odds` as one word.
	*/
	private static func usedParts(in script: String) -> Set<String> {
		let members = script.matches(of: /\bthis\.parts\.(\w+)/.wordBoundaryKind(.simple)).map { String($0.1) }

		let destructured = script.matches(of: /\{([\w\s,:]+)\}\s*=\s*this\.parts\b(?![.\[])/.wordBoundaryKind(.simple)).flatMap { names(in: $0.1) }

		let selected = script.matches(of: /data-part="(\w+)"/).map { String($0.1) }

		return Set(members + destructured + selected)
	}

	/**
	The names of a destructuring, like `screen` and `flip` for `screen, flip: button`.
	*/
	private static func names(in destructuring: Substring) -> [String] {
		destructuring.split(separator: ",").compactMap { $0.split(separator: ":").first?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
	}
}

extension ScriptedElement {
	/**
	The names of the parts of the element.
	*/
	fileprivate static var declaredParts: [String] {
		Parts.allCases.map(\.rawValue)
	}
}
