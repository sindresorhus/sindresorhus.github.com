import Foundation
import Network
import Synchronization
import UniformTypeIdentifiers

/**
Serves a published site on `127.0.0.1`, like GitHub Pages: `/about` serves `about.html`, a directory serves its `index.html`, and a missing file serves `404.html` with status 404.

It is for previewing only. It handles `GET` requests and closes the connection after each response. It does not answer range requests, so Safari does not play videos in the preview.

With `reloadsPages`, served pages reload after ``reload()``, and show the error of ``show(error:)``: the server adds a small script to each page that asks it for changes with a long-polling request.
*/
public struct PreviewServer: Sendable {
	public let directory: URL

	/**
	The port to listen on. `0` lets the system choose a free port, which ``run(onReady:)`` reports.
	*/
	public let port: UInt16

	public let reloadsPages: Bool
	private let state = State()

	public init(directory: URL, port: UInt16, reloadsPages: Bool = false) {
		self.directory = directory.standardizedFileURL
		self.port = port
		self.reloadsPages = reloadsPages
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
		parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: NWEndpoint.Port(integerLiteral: port))
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
			return Self.response(status: "405 Method Not Allowed", contentType: "text/plain", body: Data("Only GET is supported.".utf8))
		}

		let target = URLComponents(string: String(requestLine[1]))

		if
			reloadsPages,
			target?.path == Self.statePath
		{
			let snapshot = await state.change(after: target?.queryItems?.first { $0.name == "since" }?.value ?? "")
			return Self.response(status: "200 OK", contentType: "application/json", body: (try? JSONEncoder().encode(snapshot)) ?? Data())
		}

		// The version is read before the file, so a rebuild in between makes the page reload, instead of showing the old file with the new version.
		let version = state.snapshot.version

		if
			let file = target.flatMap({ directory.servedFile(forPath: $0.percentEncodedPath) }),
			let body = try? Data(contentsOf: file)
		{
			let contentType = Self.contentType(of: file)
			return Self.response(status: "200 OK", contentType: contentType, body: contentType.hasPrefix("text/html") ? addingReloadScript(to: body, version: version) : body)
		}

		let notFound = (try? Data(contentsOf: directory.appending(path: "404.html"))) ?? Data("Not found".utf8)
		return Self.response(status: "404 Not Found", contentType: "text/html; charset=utf-8", body: addingReloadScript(to: notFound, version: version))
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

	private static func response(status: String, contentType: String, body: Data) -> Data {
		let header = "HTTP/1.1 \(status)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
		return Data(header.utf8) + body
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
				try? await Task.sleep(for: .milliseconds(50))
			}

			return snapshot
		}
	}
}
