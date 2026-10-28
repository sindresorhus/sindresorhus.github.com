import Foundation
import Network
import Synchronization
import UniformTypeIdentifiers

/**
Serves a published site like GitHub Pages, on `127.0.0.1`, or on all IPv4 addresses with `servesLocalNetwork`: `/about` serves `about.html`, a directory serves its `index.html`, and a missing file serves `404.html` with status 404.

It is for previewing only. It handles `GET` requests and closes the connection after each response. It answers a request for one range of bytes of a file, as Safari asks for the bytes of a video in parts.

With `reloadsPages`, served pages reload after ``reload()``, and show the error of ``show(error:)``: the server adds a small script to each page that asks it for changes with a long-polling request.
*/
public struct PreviewServer: Sendable {
	public let directory: URL

	/**
	The port to listen on. `0` lets the system choose a free port, which ``run(onReady:)`` reports.
	*/
	public let port: UInt16

	public let reloadsPages: Bool

	/**
	Whether other devices on the local network can open the site too, like an iPhone, and not only this Mac.
	*/
	public let servesLocalNetwork: Bool

	private let state = State()

	public init(
		directory: URL,
		port: UInt16,
		reloadsPages: Bool = false,
		servesLocalNetwork: Bool = false
	) {
		self.directory = directory.standardizedFileURL
		self.port = port
		self.reloadsPages = reloadsPages
		self.servesLocalNetwork = servesLocalNetwork
	}

	/**
	Reloads the open pages, after the site in the directory changed.
	*/
	public func reload() {
		state.reload()
	}

	/**
	Shows an error on the open pages, like a failed build, or hides it with `nil`. Pages that open later show it too.
	*/
	public func show(error: String?) {
		state.show(error: error)
	}

	/**
	Serves until the task is cancelled. Throws if the port cannot be used.

	- Parameter onReady: Called once the server accepts connections, with the port it listens on.
	*/
	public func run(onReady: @escaping @Sendable (_ port: UInt16) -> Void = { _ in }) async throws {
		let parameters = NWParameters.tcp
		parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(servesLocalNetwork ? .any : .loopback), port: NWEndpoint.Port(integerLiteral: port))
		let listener = try NWListener(using: parameters)

		listener.newConnectionHandler = { connection in
			connection.start(queue: .global())
			connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, _, _ in
				// A connection that closed before sending a request gets no response.
				guard let data else {
					connection.cancel()
					return
				}

				Task {
					connection.send(content: await response(to: data), completion: .contentProcessed { _ in
						connection.cancel()
					})
				}
			}
		}

		try await withTaskCancellationHandler {
			try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
				listener.stateUpdateHandler = { state in
					switch state {
					case .ready:
						onReady(listener.port?.rawValue ?? port)
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

				// A listener that is cancelled before it starts never reports it, so a cancelled task does not start it.
				guard !Task.isCancelled else {
					listener.stateUpdateHandler = nil
					continuation.resume()
					return
				}

				listener.start(queue: .global())
			}
		} onCancel: {
			listener.cancel()
		}
	}

	private func response(to request: Data) async -> Data {
		let requestLine = String(decoding: request.prefix { $0 != UInt8(ascii: "\r") }, as: UTF8.self).split(separator: " ")

		guard
			requestLine.count == 3,
			requestLine[0] == "GET"
		else {
			return Self.response(status: .methodNotAllowed, contentType: "text/plain", body: Data("Only GET is supported.".utf8))
		}

		let target = URLComponents(string: String(requestLine[1]))

		if
			reloadsPages,
			target?.path == Self.statePath
		{
			let snapshot = await state.change(after: target?.queryItems?.first { $0.name == "since" }?.value ?? "")
			return Self.response(status: .ok, contentType: "application/json", body: (try? JSONEncoder().encode(snapshot)) ?? Data())
		}

		// The version is read before the file, so a rebuild in between makes the page reload, instead of showing the old file with the new version.
		let version = state.snapshot.version

		if
			let file = target.flatMap({ directory.servedFile(forPath: $0.percentEncodedPath) }),
			var body = try? Data(contentsOf: file)
		{
			let contentType = Self.contentType(of: file)

			if contentType.hasPrefix("text/html") {
				body = addingReloadScript(to: body, version: version)
			}

			return FileResponse(body, range: ByteRange(request: request)).render(contentType: contentType)
		}

		let notFound = directory.servedFile(forPath: "/404.html").flatMap { try? Data(contentsOf: $0) } ?? Data("Not found".utf8)
		return Self.response(status: .notFound, contentType: "text/html; charset=utf-8", body: addingReloadScript(to: notFound, version: version))
	}

	private enum HTTPStatus: String {
		case ok = "200 OK"
		case partialContent = "206 Partial Content"
		case notFound = "404 Not Found"
		case methodNotAllowed = "405 Method Not Allowed"
		case rangeNotSatisfiable = "416 Range Not Satisfiable"
	}

	/**
	A file response keeps the full data and the selected bytes together, so its status, body length, and Content-Range describe the same bytes.
	*/
	private enum FileResponse {
		case complete(Data)
		case partial(Data, bytes: Range<Int>)
		case unsatisfied(total: Int)

		/**
		Selects the requested bytes from a full file, or serves the whole file without a range.
		*/
		init(_ data: Data, range: ByteRange?) {
			guard let range else {
				self = .complete(data)
				return
			}

			guard let bytes = range.bytes(ofCount: data.count) else {
				self = .unsatisfied(total: data.count)
				return
			}

			self = .partial(data, bytes: bytes)
		}

		var headers: [String] {
			switch self {
			case .complete:
				["Accept-Ranges: bytes"]
			case .partial(let data, let bytes):
				["Accept-Ranges: bytes", "Content-Range: bytes \(bytes.lowerBound)-\(bytes.upperBound - 1)/\(data.count)"]
			case .unsatisfied(let total):
				["Content-Range: bytes */\(total)"]
			}
		}

		/**
		Renders the status, range headers, and selected body as one response.
		*/
		func render(contentType: String) -> Data {
			switch self {
			case .complete(let data):
				PreviewServer.response(status: .ok, contentType: contentType, body: data, fileResponse: self)
			case .partial(let data, let bytes):
				PreviewServer.response(status: .partialContent, contentType: contentType, body: data[bytes], fileResponse: self)
			case .unsatisfied:
				PreviewServer.response(status: .rangeNotSatisfiable, contentType: "text/plain", body: Data(), fileResponse: self)
			}
		}
	}

	private static let statePath = "/_preview-server/state"

	/**
	Adds the script that reloads the page when the version changes, and shows the error. It asks the server for the next change in a loop, and keeps asking while the server restarts. The page starts with the version it was served with, so a rebuild right after it loads is not missed.

	- Parameter version: The version of the site when the file was read.
	*/
	private func addingReloadScript(to html: Data, version: String) -> Data {
		guard reloadsPages else {
			return html
		}

		let script = #"<script>{const version="\#(version)";let revision="";let overlay;const show=error=>{overlay?.remove();overlay=undefined;if(!error){return}overlay=document.createElement("pre");overlay.textContent=error;overlay.style.cssText="position:fixed;inset:auto 1rem 1rem;z-index:2147483647;max-height:50vh;overflow:auto;margin:0;padding:1rem;border-radius:.5rem;background:#991b1b;color:#fff;font:13px/1.5 ui-monospace,monospace;white-space:pre-wrap";document.documentElement.append(overlay)};(async()=>{while(true){try{const state=await(await fetch(`\#(Self.statePath)?since=${encodeURIComponent(revision)}`)).json();if(state.version!==version){location.reload();return}revision=state.revision;show(state.error)}catch{await new Promise(resolve=>setTimeout(resolve,500))}}})()}</script>"#
		return html + Data(script.utf8)
	}

	private static func contentType(of file: URL) -> String {
		let type = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
		return type.hasPrefix("text/") || type == "application/javascript" ? "\(type); charset=utf-8" : type
	}

	/**
	- Parameter fileResponse: The file response that owns its status, body, and range headers, when serving a file.
	*/
	private static func response(
		status: HTTPStatus,
		contentType: String,
		body: Data,
		fileResponse: FileResponse? = nil
	) -> Data {
		let headers = fileResponse?.headers ?? []
		let header = "HTTP/1.1 \(status.rawValue)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\n\(headers.map { "\($0)\r\n" }.joined())Cache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n"
		return Data(header.utf8) + body
	}
}

extension PreviewServer {
	/**
	The one range of bytes that the `Range` header of a request asks for.
	*/
	private enum ByteRange {
		/**
		From a byte to a byte, like `bytes=10-19`, or to the end, like `bytes=10-`.
		*/
		case from(Int, through: Int?)

		/**
		The last bytes, like `bytes=-10`.
		*/
		case suffix(Int)

		/**
		A `Range` header line with one range of bytes, with the first and the last byte, each of which can be missing.
		*/
		private nonisolated(unsafe) static let header = /(?i)range:\s*bytes=(\d*)-(\d*)\s*/

		/**
		The range of the request, or `nil` without a `Range` header, or with a header that is not one range of bytes, like several ranges, which then gets the whole file.
		*/
		init?(request: Data) {
			guard let match = String(decoding: request, as: UTF8.self).split(separator: "\r\n").lazy.compactMap({ $0.wholeMatch(of: Self.header) }).first else {
				return nil
			}

			// A number that is too large is not a range, not a missing number.
			switch (Int(match.1), Int(match.2)) {
			case (let first?, nil) where match.2.isEmpty:
				self = .from(first, through: nil)
			case (let first?, let last?) where first <= last:
				self = .from(first, through: last)
			case (nil, let length?) where match.1.isEmpty:
				self = .suffix(length)
			default:
				return nil
			}
		}

		/**
		The bytes of a body with the count, or `nil` when the range has none of them, like a range that starts after the end.
		*/
		func bytes(ofCount count: Int) -> Range<Int>? {
			let bytes = switch self {
			case .from(let first, let last):
				min(first, count)..<(min(last ?? count, count - 1) + 1)
			case .suffix(let length):
				max(count - length, 0)..<count
			}

			return bytes.isEmpty ? nil : bytes
		}
	}
}

extension PreviewServer {
	/**
	What the open pages need to know: the version of the published site, which changes on every reload and when the server restarts, and the error to show.
	*/
	private final class State: Sendable {
		struct Snapshot: Encodable {
			let version: String

			/**
			Changes with the version and the error, so a page can ask for the next change.
			*/
			let revision: String

			let error: String?
		}

		private struct Value {
			var reloads = 0
			var changes = 0
			var error: String?
		}

		private let launch = UUID()
		private let value = Mutex(Value())

		var snapshot: Snapshot {
			value.withLock { value in
				Snapshot(version: "\(launch)-\(value.reloads)", revision: "\(launch)-\(value.changes)", error: value.error)
			}
		}

		func reload() {
			value.withLock {
				$0.reloads += 1
				$0.changes += 1
			}
		}

		func show(error: String?) {
			value.withLock {
				guard $0.error != error else {
					return
				}

				$0.error = error
				$0.changes += 1
			}
		}

		/**
		The state once its revision is not the given one, or after 20 seconds, so a connection is not open for long. Checking often is cheap, and simpler than waking each request.
		*/
		func change(after revision: String) async -> Snapshot {
			let deadline = ContinuousClock.now + .seconds(20)

			while
				snapshot.revision == revision,
				ContinuousClock.now < deadline
			{
				do {
					try await Task.sleep(for: .milliseconds(50))
				} catch {
					break
				}
			}

			return snapshot
		}
	}
}
