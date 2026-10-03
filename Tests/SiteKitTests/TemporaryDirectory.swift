import Foundation

extension URL {
	/**
	A new, empty directory for a test, with files from a dictionary of relative paths and contents.
	*/
	static func temporaryDirectory(files: [String: String] = [:]) throws -> URL {
		let directory = FileManager.default.temporaryDirectory.appending(path: "sitekit-tests-\(UUID().uuidString)")
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

		for (path, contents) in files {
			let file = directory.appending(path: path)
			try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
			try Data(contents.utf8).write(to: file)
		}

		return directory
	}
}
