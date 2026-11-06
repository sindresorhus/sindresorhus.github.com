import Foundation
import Network
import Synchronization
import UniformTypeIdentifiers

/**
Serves a published site like GitHub Pages, on `127.0.0.1`, or on all IPv4 addresses with `servesLocalNetwork`: `/about` serves `about.html`, a directory serves its `index.html`, and a missing file serves `404.html` with status 404.

It is for previewing only. It handles `GET` requests and closes the connection after each response. It answers a request for one range of bytes of a file, as Safari asks for the bytes of a video in parts.

With `reloadsPages`, served pages reload after ``reload()``, and show the error of ``show(error:)``: the server adds a small script to each page that asks it for changes with a long-polling request.

With a ``projectDirectory``, a click on a location in the error box, like `content/apps/dato/index.md:268`, opens the file at the line in Sublime Text. Any web page can send a request to `127.0.0.1`, so the server only opens a file for a request with the random token of this launch, which only its own pages opened on this Mac as `localhost` or `127.0.0.1` get, so a page of another domain that resolves to this Mac and a device of the local network cannot read it. The request must also come from this Mac, with one of these hosts. It opens only the existing files in the `content`, `public`, and `Sources` directories of the project.

Limitation: a page that is opened with another host, like the address of the Mac on the local network, cannot open files.
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

	/**
	The project whose files a click on a location in the error box opens in Sublime Text, or `nil` to show the locations as text.
	*/
	public let projectDirectory: URL?

	private let state = State()

	/**
	The secret of this launch that a request to open a file must have. The pages get it in the reload script.
	*/
	private let openToken = UUID().uuidString

	public init(
		directory: URL,
		port: UInt16,
		reloadsPages: Bool = false,
		servesLocalNetwork: Bool = false,
		projectDirectory: URL? = nil
	) {
		self.directory = directory.standardizedFileURL
		self.port = port
		self.reloadsPages = reloadsPages
		self.servesLocalNetwork = servesLocalNetwork
		self.projectDirectory = projectDirectory
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
	The port has a listener already, like another preview of the site.
	*/
	public struct PortInUseError: LocalizedError {
		public let port: UInt16

		public var errorDescription: String? {
			"Port \(port) is in use, maybe by another `website serve`. Stop it, or use `--port 0`."
		}
	}

	/**
	Checks that the server can listen on its port, by listening on it for a moment, so a command can stop before a long build, and before it writes to the directory that another preview serves. Throws ``PortInUseError`` when the port is in use, and the error of the listener for another problem.
	*/
	public func checkPort() async throws {
		let (ready, readyContinuation) = AsyncStream.makeStream(of: Never.self)

		do {
			try await withThrowingTaskGroup(of: Void.self) { group in
				group.addTask {
					try await run { _ in
						readyContinuation.finish()
					}
				}

				group.addTask {
					for await _ in ready {}
				}

				// The listener is ready, or it failed. Then it stops, so the port is free again.
				defer {
					group.cancelAll()
				}

				try await group.next()
			}
		} catch NWError.posix(.EADDRINUSE) {
			throw PortInUseError(port: port)
		}
	}

	/**
	Serves until the task is cancelled. Throws if the port cannot be used.

	- Parameter onReady: Called once the server accepts connections, with the port it listens on.
	*/
	public func run(onReady: @escaping @Sendable (_ port: UInt16) -> Void = { _ in }) async throws {
		let listener = try NetworkListener(
			using: .parameters {
				TCP()
			}
			.localEndpoint(.hostPort(host: .ipv4(servesLocalNetwork ? .any : .loopback), port: NWEndpoint.Port(integerLiteral: port)))
		)

		// The listener stops when the task is cancelled, and each connection is closed when its handler returns.
		try await listener
			.onStateUpdate { listener, state in
				if state == .ready {
					onReady(listener.port?.rawValue ?? port)
				}
			}
			.run { connection in
				// A connection that closed before sending a request gets no response, and an error of one connection does not stop the server.
				do {
					let request = try await connection.receive(atMost: 65_536).content
					try await connection.send(await response(to: request, isFromThisMac: connection.remoteEndpoint?.isLoopback == true))
				} catch {}
			}
	}

	private func response(to request: Data, isFromThisMac: Bool) async -> Data {
		let requestLine = String(decoding: request.prefix { $0 != UInt8(ascii: "\r") }, as: UTF8.self).split(separator: " ")

		guard
			requestLine.count == 3,
			requestLine[0] == "GET"
		else {
			return Self.response(status: .methodNotAllowed, contentType: .plainText, body: Data("Only GET is supported.".utf8))
		}

		let target = URLComponents(string: String(requestLine[1]))

		if
			reloadsPages,
			target?.path == Self.statePath
		{
			let snapshot = await state.change(after: target?.queryItems?.first { $0.name == "since" }?.value ?? "")
			return Self.response(status: .ok, contentType: .json, body: (try? JSONEncoder().encode(snapshot)) ?? Data())
		}

		if
			reloadsPages,
			target?.path == Self.openPath
		{
			let isOpened = isFromThisMac && openFile(query: target?.queryItems ?? [], request: request)
			return Self.response(status: isOpened ? .noContent : .forbidden, contentType: .plainText, body: Data())
		}

		// Only a page that this Mac opened as `localhost` or `127.0.0.1` gets the token, so a page of another domain that resolves to this Mac, or a device of the local network, cannot read it.
		let includesOpenToken = isFromThisMac && Self.isLocalHost(request)

		// The version is read before the file, so a rebuild in between makes the page reload, instead of showing the old file with the new version.
		let version = state.snapshot.version

		if
			let file = target.flatMap({ directory.servedFile(forPath: $0.percentEncodedPath) }),
			var body = try? Data(contentsOf: file)
		{
			let contentType = Self.contentType(of: file)

			if contentType == .html {
				body = addingReloadScript(to: body, version: version, includesOpenToken: includesOpenToken)
			}

			return FileResponse(body, range: ByteRange(request: request)).render(contentType: contentType)
		}

		let notFound = directory.servedFile(forPath: "/404.html").flatMap { try? Data(contentsOf: $0) } ?? Data("Not found".utf8)
		return Self.response(status: .notFound, contentType: .html, body: addingReloadScript(to: notFound, version: version, includesOpenToken: includesOpenToken))
	}

	private enum HTTPStatus: String {
		case ok = "200 OK"
		case noContent = "204 No Content"
		case partialContent = "206 Partial Content"
		case forbidden = "403 Forbidden"
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
		func render(contentType: MediaType) -> Data {
			switch self {
			case .complete(let data):
				PreviewServer.response(status: .ok, contentType: contentType, body: data, fileResponse: self)
			case .partial(let data, let bytes):
				PreviewServer.response(status: .partialContent, contentType: contentType, body: data[bytes], fileResponse: self)
			case .unsatisfied:
				PreviewServer.response(status: .rangeNotSatisfiable, contentType: .plainText, body: Data(), fileResponse: self)
			}
		}
	}

	private static let statePath = "/_preview-server/state"

	private static let openPath = "/_preview-server/open"

	/**
	The `Host` header of a page that is opened as `localhost` or `127.0.0.1`, with any port.
	*/
	private nonisolated(unsafe) static let localHostHeader = /(?im)^host:\s*(?:localhost|127\.0\.0\.1)(?::\d+)?\s*$/

	/**
	Whether the request has `localhost` or `127.0.0.1` as its host, not another domain that resolves to this Mac.
	*/
	private static func isLocalHost(_ request: Data) -> Bool {
		String(decoding: request, as: UTF8.self).firstMatch(of: localHostHeader) != nil
	}

	private static let sublimeText = URL(filePath: "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl")

	/**
	The directories of the project whose files the error box links to, and the server opens (``openFile(query:request:)``).
	*/
	private static let openableDirectories = ["content", "public", "Sources"]

	/**
	Opens a file of the project at a line in Sublime Text, for a request with the `file`, `line`, and `token` of a location in the error box. Returns whether it opened the file.
	*/
	private func openFile(query: [URLQueryItem], request: Data) -> Bool {
		func value(_ name: String) -> String? {
			query.first { $0.name == name }?.value
		}

		guard
			let projectDirectory,
			value("token") == openToken,
			let path = value("file"),
			let line = value("line").flatMap({ Int($0) }),
			line > 0,
			Self.isLocalHost(request)
		else {
			return false
		}

		// The resolved paths, so a link or `..` cannot lead out of the directories.
		let file = projectDirectory.appending(path: path).resolvingSymlinksInPath().standardizedFileURL

		guard
			file.exists,
			Self.openableDirectories.contains(where: { file.path.hasPrefix(projectDirectory.appending(path: $0).resolvingSymlinksInPath().standardizedFileURL.path + "/") })
		else {
			return false
		}

		let process = Process()
		process.executableURL = Self.sublimeText
		process.arguments = ["\(file.path):\(line)"]
		return (try? process.run()) != nil
	}

	/**
	Adds the script that reloads the page when the version changes, and shows the error. It asks the server for the next change in a loop, and keeps asking while the server restarts. The page starts with the version it was served with, so a rebuild right after it loads is not missed.

	- Parameter version: The version of the site when the file was read.
	- Parameter includesOpenToken: Whether the page gets the token to open files.
	*/
	private func addingReloadScript(to html: Data, version: String, includesOpenToken: Bool) -> Data {
		guard reloadsPages else {
			return html
		}

		// A location in the error, like `content/apps/dato/index.md:268`, is a link that asks the server to open the file at the line, when the server has a project.
		let token = projectDirectory == nil || !includesOpenToken ? "" : openToken
		// The split has the file and the line of each location as two groups, so each location is three parts with the text before it.
		let directories = Self.openableDirectories.joined(separator: "|")
		let script = #"<script>{const version="\#(version)";const token="\#(token)";let revision="";let overlay;const show=error=>{overlay?.remove();overlay=undefined;if(!error){return}overlay=document.createElement("pre");const parts=token?error.split(/((?:\#(directories))\/[^\s:]+):(\d+)/):[error];for(let index=0;index<parts.length;index+=3){overlay.append(parts[index]);const file=parts[index+1];const line=parts[index+2];if(file===undefined){continue}const link=document.createElement("a");link.href='#';link.textContent=`${file}:${line}`;link.style.cssText="color:inherit;text-decoration:underline";link.addEventListener("click",event=>{event.preventDefault();fetch(`\#(Self.openPath)?${new URLSearchParams({file,line,token})}`)});overlay.append(link)}overlay.style.cssText="position:fixed;inset:auto 1rem 1rem;z-index:2147483647;max-height:50vh;overflow:auto;margin:0;padding:1rem;border-radius:.5rem;background:#991b1b;color:#fff;font:13px/1.5 ui-monospace,monospace;white-space:pre-wrap";document.documentElement.append(overlay)};(async()=>{while(true){try{const state=await(await fetch(`\#(Self.statePath)?since=${encodeURIComponent(revision)}`)).json();if(state.version!==version){location.reload();return}revision=state.revision;show(state.error)}catch{await new Promise(resolve=>setTimeout(resolve,500))}}})()}</script>"#
		return html + Data(script.utf8)
	}

	private static func contentType(of file: URL) -> MediaType {
		UTType(filenameExtension: file.pathExtension)?.preferredMIMEType.flatMap { try? MediaType(validating: $0) } ?? .octetStream
	}

	/**
	- Parameter fileResponse: The file response that owns its status, body, and range headers, when serving a file.
	*/
	private static func response(
		status: HTTPStatus,
		contentType: MediaType,
		body: Data,
		fileResponse: FileResponse? = nil
	) -> Data {
		let headers = fileResponse?.headers ?? []
		let contentType = contentType.rawValue + (contentType.rawValue.hasPrefix("text/") || contentType == .javascript ? "; charset=utf-8" : "")
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

			return bytes.nilIfEmpty
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

extension NWEndpoint {
	/**
	Whether the endpoint is an address of this Mac, like `127.0.0.1`.
	*/
	fileprivate var isLoopback: Bool {
		guard case .hostPort(let host, _) = self else {
			return false
		}

		switch host {
		case .ipv4(let address):
			return address.isLoopback
		case .ipv6(let address):
			return address.isLoopback
		default:
			return false
		}
	}
}
