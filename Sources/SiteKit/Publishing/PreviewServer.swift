import Foundation
import Network
import Synchronization
import UniformTypeIdentifiers

/**
Serves a published site on `127.0.0.1`, like GitHub Pages: `/about` serves `about.html`, a directory serves its `index.html`, and a missing file serves `404.html` with status 404.

It is for previewing only. It handles `GET` requests and closes the connection after each response. It does not answer range requests, so Safari does not play videos in the preview.

With `reloadsPages`, served pages reload after ``reload()``: the server adds a small script to each page that asks it every half second whether the site changed.
*/
public struct PreviewServer: Sendable {
	public let directory: URL
	public let port: UInt16
	public let reloadsPages: Bool
	private let version = Version()

	public init(directory: URL, port: UInt16, reloadsPages: Bool = false) {
		self.directory = directory.standardizedFileURL
		self.port = port
		self.reloadsPages = reloadsPages
	}

	/**
	Reloads the open pages, after the site in the directory changed.
	*/
	public func reload() {
		version.increment()
	}

	/**
	Serves until the task is cancelled. Throws if the port cannot be used.

	- Parameter onReady: Called once the server accepts connections.
	*/
	public func run(onReady: @escaping @Sendable () -> Void = {}) async throws {
		let parameters = NWParameters.tcp
		parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: NWEndpoint.Port(integerLiteral: port))
		let listener = try NWListener(using: parameters)

		listener.newConnectionHandler = { connection in
			connection.start(queue: .global())
			connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, _, _ in
				connection.send(content: response(to: data ?? Data()), completion: .contentProcessed { _ in
					connection.cancel()
				})
			}
		}

		try await withTaskCancellationHandler {
			try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
				listener.stateUpdateHandler = { state in
					switch state {
					case .ready:
						onReady()
					case .failed(let error):
						listener.stateUpdateHandler = nil
						continuation.resume(throwing: error)
					case .cancelled:
						listener.stateUpdateHandler = nil
						continuation.resume()
					default:
						break
					}
				}

				listener.start(queue: .global())
			}
		} onCancel: {
			listener.cancel()
		}
	}

	private func response(to request: Data) -> Data {
		let requestLine = String(decoding: request.prefix { $0 != UInt8(ascii: "\r") }, as: UTF8.self).split(separator: " ")

		guard
			requestLine.count == 3,
			requestLine[0] == "GET"
		else {
			return Self.response(status: "405 Method Not Allowed", contentType: "text/plain", body: Data("Only GET is supported.".utf8))
		}

		if
			reloadsPages,
			requestLine[1] == Self.versionPath
		{
			return Self.response(status: "200 OK", contentType: "text/plain; charset=utf-8", body: Data(version.description.utf8))
		}

		if
			let file = file(for: String(requestLine[1])),
			let body = try? Data(contentsOf: file)
		{
			let contentType = Self.contentType(of: file)
			return Self.response(status: "200 OK", contentType: contentType, body: contentType.hasPrefix("text/html") ? addingReloadScript(to: body) : body)
		}

		let notFound = (try? Data(contentsOf: directory.appending(path: "404.html"))) ?? Data("Not found".utf8)
		return Self.response(status: "404 Not Found", contentType: "text/html; charset=utf-8", body: addingReloadScript(to: notFound))
	}

	private static let versionPath = "/_preview-server/version"

	/**
	Adds the script that reloads the page when the version changes. It keeps asking while the server restarts. The page starts with the version it was served with, so a rebuild right after it loads is not missed.
	*/
	private func addingReloadScript(to html: Data) -> Data {
		guard reloadsPages else {
			return html
		}

		let script = #"<script>{let version="\#(version.description)";setInterval(async()=>{try{const latest=await(await fetch("\#(Self.versionPath)")).text();if(version&&latest!==version){location.reload()}version=latest}catch{}},500)}</script>"#
		return html + Data(script.utf8)
	}

	/**
	The file for a request path, or `nil` when there is none or the path leaves the directory.
	*/
	private func file(for requestPath: String) -> URL? {
		directory.servedFile(forPath: String(requestPath.prefix { $0 != "?" && $0 != "#" }))
	}

	private static func contentType(of file: URL) -> String {
		let type = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
		return type.hasPrefix("text/") || type == "application/javascript" ? "\(type); charset=utf-8" : type
	}

	private static func response(status: String, contentType: String, body: Data) -> Data {
		let header = "HTTP/1.1 \(status)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
		return Data(header.utf8) + body
	}
}

extension PreviewServer {
	/**
	Identifies the published site. It changes on every reload and when the server restarts.
	*/
	private final class Version: Sendable, CustomStringConvertible {
		private let launch = UUID()
		private let count = Atomic(0)

		func increment() {
			count.add(1, ordering: .relaxed)
		}

		var description: String {
			"\(launch)-\(count.load(ordering: .relaxed))"
		}
	}
}
