import Foundation

/**
The source directory of a site: content, data, and the public assets that are copied as-is.
*/
public struct Project: Sendable {
	public let root: URL

	public init(root: URL) {
		self.root = root.standardizedFileURL
	}

	/**
	Files that are published unchanged, like images and scripts.
	*/
	public var publicDirectory: URL {
		root.appending(path: "public")
	}

	/**
	The file behind a public URL path, like `/apps/dato/icon.png`.
	*/
	public func publicFile(_ path: String) -> URL {
		publicDirectory.appending(path: String(path.drop { $0 == "/" }))
	}

	/**
	The date of the last commit that changed each Markdown file in the directory, keyed by the path relative to the project root, like `content/apps/dato.md`.

	Moving a file without changing it does not count as a change, so the dates survive a reorganization. Empty when the project is not a git repository or git is missing. A shallow clone only knows the dates of its commits.
	*/
	public func lastCommitDates(in directory: String) -> [String: Date] {
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		// Without `core.quotePath=false`, git quotes paths with non-ASCII characters, so they would not match the files.
		process.arguments = ["git", "-C", root.path(percentEncoded: false), "-c", "core.quotePath=false", "log", "--find-renames", "--name-status", "--format=%x00%cI", "--relative", "--", "*.md"]
		process.standardError = FileHandle.nullDevice
		let pipe = Pipe()
		process.standardOutput = pipe

		guard (try? process.run()) != nil else {
			return [:]
		}

		let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
		process.waitUntilExit()

		guard process.terminationStatus == 0 else {
			return [:]
		}

		var dates = [String: Date]()
		var date: Date?

		// The name that an older path has today, after the renames seen so far.
		var currentNames = [String: String]()

		// Commits are newest first, so the first change of a file is its latest.
		for line in output.split(separator: "\n") {
			if line.hasPrefix("\0") {
				date = try? Date(String(line.dropFirst()), strategy: .iso8601)
				continue
			}

			let fields = line.split(separator: "\t").map(String.init)

			guard
				let date,
				let status = fields.first,
				let path = fields.last
			else {
				continue
			}

			let currentName = currentNames[path] ?? path

			// `R100` is a rename without changes.
			if status != "R100", dates[currentName] == nil {
				dates[currentName] = date
			}

			if status.hasPrefix("R"), fields.count == 3 {
				currentNames[fields[1]] = currentName
			}
		}

		return dates.filter { $0.key.hasPrefix(directory + "/") }
	}
}
