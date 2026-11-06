import Foundation
import SiteKit
import Testing
import UniformTypeIdentifiers
import WebKit
@testable import Website

/**
Runs the scripts of the pages in WebKit, the engine of most visitors, as the other tests only read the scripts as text, so a selector that no longer matches, or an error when a script runs, would only show in a browser. The pages are served from the rendered pages and the files of the project, without a build, and requests to other sites are blocked.
*/
@MainActor
struct PageScriptTests {
	@Test
	func `the scripts of the pages run without errors`() async throws {
		let post = try #require(try await SiteContent.website.posts.first)

		// Supercharge has inline notes.
		let paths = [
			App.path(slug: "dato").description,
			App.path(slug: "supercharge").description,
			Self.feedbackPath,
			Self.sentFeedbackPath,
			RoutePath.contact.description,
			RoutePath.apps.description,
			RoutePath.appdle.description,
			RoutePath.now.description,
			post.path.description,
			RoutePath.notFound.description
		]

		// Each page in its own web view, at the same time, so the waits of the pages overlap. The tasks run on the main actor, like the web views.
		let loads = paths.map { path in
			Task {
				(path: path, errors: try await Self.makeWebView().loadingErrors(of: path))
			}
		}

		for load in loads {
			let page = try await load.value
			#expect(page.errors == [], "\(page.path) has script errors.")
		}
	}

	@Test
	func `the filter of the app picker finds apps by a name without spaces and punctuation, and with a typo, with the names first`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: RoutePath.feedback.description) == [])

		let visibleApps = """
		const filter = document.querySelector('#app-filter');
		filter.value = query;
		filter.dispatchEvent(new Event('input'));
		return [...document.querySelectorAll('[data-app-filter-text]:not([hidden])')].map(item => item.textContent);
		"""

		let withoutSpaces: [String] = try await webView.result(of: visibleApps, arguments: ["query": "zonebar"])
		#expect(withoutSpaces == ["Zone Bar"])
		let withTypo: [String] = try await webView.result(of: visibleApps, arguments: ["query": "gifksi"])
		#expect(withTypo == ["Gifski"])
		let withPunctuation: [String] = try await webView.result(of: visibleApps, arguments: ["query": "dsstore"])
		#expect(withPunctuation == ["DS_Store Inspector"])

		// The apps whose name has the words come before the apps whose subtitle has them.
		let byNameFirst: [String] = try await webView.result(of: visibleApps, arguments: ["query": "menu bar"])
		#expect(byNameFirst.first?.contains("Menu Bar") == true, "\(byNameFirst)")
		#expect(byNameFirst.contains { !$0.contains("Menu Bar") }, "\(byNameFirst)")
	}

	@Test
	func `the feedback page finds an app by the name that the app sends`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: RoutePath.feedback.description + "?product=Color%20Picker") == [])
		let product: String = try await webView.result(of: "return document.querySelector('#product-name').textContent")
		#expect(product == "System Color Picker")
	}

	@Test(arguments: ["data", "icon"])
	func `Escape cancels a link preview while its data or icon loads`(delayedResource: String) async throws {
		let webView = try await Self.makeWebView()
		webView.configuration.userContentController.addUserScript(WKUserScript(source: """
		const originalMatchMedia = window.matchMedia.bind(window);
		window.matchMedia = query => query === '(hover: hover) and (pointer: fine)' ? {matches: true} : originalMatchMedia(query);
		window.fetch = () => new Promise(resolve => {
			window.finishPreviewData = () => resolve({json: async () => ({'/dato': {name: 'Dato', icon: '/dato/icon.png', facts: 'macOS'}})});
		});
		HTMLImageElement.prototype.decode = () => new Promise(resolve => {
			window.finishPreviewIcon = resolve;
		});
		""", injectionTime: .atDocumentStart, forMainFrameOnly: true))
		#expect(try await webView.loadingErrors(of: RoutePath.faq.description) == [])

		let states: [Bool] = try await webView.result(of: """
		const container = document.createElement('div');
		container.setAttribute('data-link-previews', '');
		const link = document.createElement('a');
		link.href = '/dato';
		link.textContent = 'Dato';
		container.append(link);
		document.body.append(container);
		// Escape leaves the pointer on the link. Synthetic pointer events do not set :hover.
		const originalMatches = link.matches.bind(link);
		link.matches = selector => selector === ':hover' || originalMatches(selector);
		const enter = () => link.dispatchEvent(new PointerEvent('pointerover', {bubbles: true, pointerType: 'mouse'}));
		const wait = () => new Promise(resolve => setTimeout(resolve, 500));
		enter();
		await wait();
		if (delayedResource === 'icon') {
			finishPreviewData();
			await wait();
		}
		const states = [typeof (delayedResource === 'data' ? window.finishPreviewData : window.finishPreviewIcon) === 'function'];
		document.dispatchEvent(new KeyboardEvent('keydown', {key: 'Escape'}));
		if (delayedResource === 'data') {
			finishPreviewData();
			await wait();
		}
		window.finishPreviewIcon?.();
		await wait();
		states.push(Boolean(document.querySelector('[popover]:popover-open')));
		// A new entry still opens the preview, so cancellation does not disable later previews.
		HTMLImageElement.prototype.decode = async () => {};
		enter();
		await wait();
		states.push(Boolean(document.querySelector('[popover]:popover-open')));
		return states;
		""", arguments: ["delayedResource": delayedResource])

		#expect(states == [true, false, true])
	}

	@Test
	func `attachments accumulate across picks and removing an oversized file makes the field valid again`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: Self.feedbackPath) == [])

		let observations: [String] = try await webView.result(of: """
		const picker = document.querySelector('attachment-picker');
		const input = picker.querySelector('input');
		// A small limit exercises validation without allocating a large attachment.
		picker.setAttribute('maximum-file-size', '4');
		const observations = [];
		const add = file => {
			const transfer = new DataTransfer();
			transfer.items.add(file);
			input.files = transfer.files;
			input.dispatchEvent(new Event('change'));
		};

		add(new File(['text'], 'first.txt'));
		const filename = 'Screen Recording 👨‍👩‍👧‍👦 é.png';
		add(new File(['large'], filename));
		observations.push([...input.files].map(file => file.name).join('|'));
		observations.push(String(input.validity.valid));
		const chips = picker.querySelector('[data-part="fileList"]').children;
		const oversizedChip = chips[1];
		observations.push(oversizedChip.querySelector('[data-part="nameStart"]').textContent + oversizedChip.querySelector('[data-part="nameEnd"]').textContent);
		observations.push(oversizedChip.querySelector('[data-part="nameEnd"]').textContent);
		observations.push(String(input.validationMessage.includes(filename)));

		oversizedChip.querySelector('button').click();
		observations.push([...input.files].map(file => file.name).join('|'));
		observations.push(String(input.validity.valid));
		observations.push(String(chips.length));
		return observations;
		""")

		// The space before the end of the name goes to the start, so a cut name has no gap after the ellipsis.
		#expect(observations == ["first.txt|Screen Recording 👨‍👩‍👧‍👦 é.png", "false", "Screen Recording 👨‍👩‍👧‍👦 é.png", "👨‍👩‍👧‍👦 é.png", "true", "first.txt", "true", "1"])
	}

	/**
	A word that leaves no question, like a second word that no question has with the first, keeps the questions on screen, so the fields below do not jump while the visitor writes. An empty message hides them.
	*/
	@Test
	func `the related help stays while the visitor writes`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: Self.feedbackPath) == [])

		let isPanelShown = """
		const message = document.querySelector('#feedback-form').elements.message;
		message.value = text;
		message.dispatchEvent(new Event('input'));
		await new Promise(resolve => setTimeout(resolve, 500));
		return !document.querySelector('faq-suggestions [data-part="panel"]').hidden;
		"""

		let withMatch: Bool = try await webView.result(of: isPanelShown, arguments: ["text": "refund"])
		#expect(withMatch)
		let withoutMatch: Bool = try await webView.result(of: isPanelShown, arguments: ["text": "refund calendar"])
		#expect(withoutMatch)
		let empty: Bool = try await webView.result(of: isPanelShown, arguments: ["text": ""])
		#expect(!empty)
	}

	@Test
	func `an empty attachment shows as empty, not as 1 kB`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: Self.feedbackPath) == [])

		let sizes: [String] = try await webView.result(of: """
		const picker = document.querySelector('attachment-picker');
		const input = picker.querySelector('input');
		const transfer = new DataTransfer();
		transfer.items.add(new File([], 'empty.log'));
		transfer.items.add(new File(['text'], 'small.log'));
		input.files = transfer.files;
		input.dispatchEvent(new Event('change'));
		return [...picker.querySelectorAll('[data-part="size"]')].map(size => size.textContent);
		""")

		#expect(sizes.count == 2)
		#expect(sizes.first == "Empty")
		#expect(sizes.last?.contains("1") == true, "\(sizes)")
	}

	@Test
	func `the crash report reminder follows the attached reports`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: Self.feedbackPath) == [])

		let reminderStates: [Bool] = try await webView.result(of: """
		const message = document.querySelector('#feedback-form').elements.message;
		const picker = document.querySelector('attachment-picker');
		const input = picker.querySelector('input');
		const reminder = document.querySelector('faq-suggestions [data-part="crashWarning"]');
		const states = [];
		const record = async () => {
			await new Promise(resolve => setTimeout(resolve, 500));
			states.push(!reminder.hidden);
		};
		const attach = name => {
			const transfer = new DataTransfer();
			transfer.items.add(new File(['Report'], name));
			input.files = transfer.files;
			input.dispatchEvent(new Event('change', {bubbles: true}));
		};

		message.value = 'Dato quits unexpectedly.';
		message.dispatchEvent(new Event('input'));
		await record();
		attach('Screenshot.png');
		await record();
		attach('Dato.IPS');
		await record();
		picker.querySelector('[data-part="fileList"]').lastElementChild.querySelector('button').click();
		await record();
		return states;
		""")

		#expect(reminderStates == [true, true, false, true])
	}

	@Test
	func `the feedback page shows the message after a send`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: Self.sentFeedbackPath) == [])
		// The text that shows, as the picker and the form are in the HTML too.
		let text: String = try await webView.result(of: "return document.body.innerText")
		#expect(text.contains("Message sent!"))
		#expect(!text.contains("Which app is it about?"))
		// The message stays, with a link to the apps, instead of a timer that leaves the page.
		let appsLink: String = try await webView.result(of: "return [...document.querySelectorAll('a')].find(link => link.textContent === 'Back to the Apps')?.getAttribute('href') ?? ''")
		#expect(appsLink == RoutePath.apps.description)
	}

	/**
	The time of a send is in seconds, like the feedback form of the apps, which sends to the same form. A `submit` event that the test sends runs the listeners of the script without sending the form.
	*/
	@Test
	func `the feedback form sends the time in seconds`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: Self.feedbackPath) == [])
		let timestamp: String = try await webView.result(of: """
		const form = document.querySelector('#feedback-form');
		form.dispatchEvent(new Event('submit', {cancelable: true}));
		return form.elements.timestamp.value;
		""")
		let seconds = try #require(Double(timestamp))
		#expect(abs(seconds - Date.now.timeIntervalSince1970) < 60)
	}

	/**
	When a guess is not one of the apps, Appdle suggests the closest name, also for a name of 4 letters with a typo, or the one name that has the guess in it, and nothing for a part of several names. The suggestion shows in the next frame, which an offscreen web view does not draw, so the test runs it at once.
	*/
	@Test
	func `Appdle suggests the name that the visitor meant`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: RoutePath.appdle.description) == [])

		let status = """
		window.requestAnimationFrame = callback => callback();
		const form = document.querySelector('#appdle-form');
		form.elements.guess.value = name;
		form.requestSubmit();
		return document.querySelector('#appdle-status').textContent;
		"""

		let typo: String = try await webView.result(of: status, arguments: ["name": "daot"])
		#expect(typo.contains("Dato"), "\(typo)")
		let part: String = try await webView.result(of: status, arguments: ["name": "color picker"])
		#expect(part.contains("System Color Picker"), "\(part)")
		let partOfSeveralNames: String = try await webView.result(of: status, arguments: ["name": "menu bar"])
		#expect(partOfSeveralNames.contains("is not one of the apps"), "\(partOfSeveralNames)")
	}

	/**
	A URL parameter with the name of a field, like `email`, is not added as a second field, which would make `form.elements.email` a list and stop the script.
	*/
	@Test
	func `the feedback form can be sent with a URL parameter that has the name of a field`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: Self.feedbackPath + "&email=a@example.com") == [])
		let isDisabled: Bool = try await webView.result(of: "return document.querySelector('#submit-button').disabled")
		#expect(!isDisabled)
		let emailFieldCount: Int = try await webView.result(of: "return document.querySelectorAll('#feedback-form [name=\"email\"]').length")
		#expect(emailFieldCount == 1)
	}

	/**
	While the visitor types, an address that is not complete yet, like `anna@fastm`, gets no warning. It does when the visitor leaves the field.
	*/
	@Test
	func `the feedback form says that an email address looks incorrect only when the field is done`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: Self.feedbackPath) == [])

		let warning = """
		const field = document.querySelector('#email');
		field.value = 'anna@fastm';
		field.dispatchEvent(new Event(eventName));
		await new Promise(resolve => setTimeout(resolve, 700));
		return document.querySelector('#email-warning').textContent;
		"""

		let whileTyping: String = try await webView.result(of: warning, arguments: ["eventName": "input"])
		#expect(whileTyping.isEmpty)
		let whenDone: String = try await webView.result(of: warning, arguments: ["eventName": "change"])
		#expect(whenDone == "Your email address looks incorrect.")
	}

	/**
	A name that is close to the name of an app does not count as a guess, and the name of an app counts without its case and spaces, whether it is right or wrong. The suggestion for the close name shows in the next frame, which an offscreen web view does not draw, so the test does not check it.
	*/
	@Test
	func `Appdle counts only the names of the apps`() async throws {
		let webView = try await Self.makeWebView()
		#expect(try await webView.loadingErrors(of: RoutePath.appdle.description) == [])

		let guess = """
		const form = document.querySelector('#appdle-form');
		form.elements.guess.value = name;
		form.requestSubmit();
		return document.querySelector('#appdle-attempts').children.length;
		"""

		let nameWithSpace: String = try await webView.result(of: "return [...document.querySelectorAll('#appdle-names option')].map(option => option.value).find(name => name.includes(' '))")
		let closeNameGuessCount: Int = try await webView.result(of: guess, arguments: ["name": nameWithSpace + "x"])
		#expect(closeNameGuessCount == 0)
		let nameWithoutSpacesGuessCount: Int = try await webView.result(of: guess, arguments: ["name": nameWithSpace.lowercased().replacing(" ", with: "")])
		#expect(nameWithoutSpacesGuessCount == 1)
	}

	/**
	The feedback page adds the details of the browser to the form, after it waits for them. When the details fail, the script sends only the user agent, so the test checks the lines that only the details have.
	*/
	@Test
	func `the feedback form gets the details of the browser`() async throws {
		let webView = try await Self.makeWebView()
		let errors = try await webView.loadingErrors(of: Self.feedbackPath)
		#expect(errors == [])
		let metadata = try await webView.evaluateJavaScript("document.querySelector('input[name=\"metadata\"]')?.value ?? ''") as? String
		#expect(metadata?.hasPrefix("OS: ") == true)
		#expect(metadata?.contains("\nBrowser: ") == true)
	}

	private static let feedbackPath = RoutePath.feedback.description + "?product=Dato"
	private static let sentFeedbackPath = RoutePath.feedback.description + "?success"

	/**
	A web view that loads the site from ``SiteSchemeHandler``, collects the errors of the scripts in `pageErrors`, and blocks requests to other sites.
	*/
	private static func makeWebView() async throws -> WKWebView {
		let configuration = WKWebViewConfiguration()
		// So what a script stores, like a dismissed banner, does not change the next run.
		configuration.websiteDataStore = .nonPersistent()
		let handler = SiteSchemeHandler(pages: try await RenderedPage.website)
		configuration.setURLSchemeHandler(handler, forURLScheme: SiteSchemeHandler.scheme)

		let errorCollector = """
		window.pageErrors = [];

		addEventListener('error', event => {
			// The scripts of other sites, like the counter of the visits, are blocked. An inline module has no `src`, and fails when its imports do not load.
			if (event.target instanceof HTMLScriptElement) {
				if (!event.target.src || event.target.src.startsWith('\(SiteSchemeHandler.scheme):')) {
					pageErrors.push(`The script ${event.target.src} could not load.`);
				}

				return;
			}

			if (event.target === window) {
				pageErrors.push(`${event.message} at ${event.filename}:${event.lineno}`);
			}
		}, true);

		addEventListener('unhandledrejection', event => {
			pageErrors.push(`An unhandled rejection: ${event.reason} at ${event.reason?.stack}`);
		});
		"""
		configuration.userContentController.addUserScript(WKUserScript(source: errorCollector, injectionTime: .atDocumentStart, forMainFrameOnly: true))

		let blockOtherSites = #"[{"trigger": {"url-filter": "^https?:"}, "action": {"type": "block"}}]"#
		// In a temporary folder, not in the WebKit data of the user (`default()`), which each run would write to.
		let ruleListStore = try #require(WKContentRuleListStore(url: URL.temporaryDirectory.appending(path: "PageScriptTests", directoryHint: .isDirectory)))
		let ruleList = try #require(try await ruleListStore.compileContentRuleList(forIdentifier: "block-other-sites", encodedContentRuleList: blockOtherSites))
		configuration.userContentController.add(ruleList)

		let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1280, height: 800), configuration: configuration)
		// The handler keeps the page from navigating away after it has loaded, so a test can read a page that sends the visitor on, like the message after a send.
		webView.navigationDelegate = handler
		return webView
	}
}

extension WKWebView {
	/**
	Loads the page at the path of the site, waits until it and its scripts have loaded, and a moment more for the work that they wait for, and returns the errors of its scripts.
	*/
	fileprivate func loadingErrors(of path: String) async throws -> [String] {
		let url = try #require(URL(string: "\(SiteSchemeHandler.scheme)://site\(path)"))
		load(URLRequest(url: url))

		// Long, as it only catches a page that never loads: the pages load at the same time, and the site handler serves them one after the other on the main actor. It is even longer for CI, where the whole suite runs at once on a slower machine.
		let deadline = ContinuousClock.now + .seconds(120)

		// The URL of the document first, as the previous page is still complete until the navigation starts.
		while try await evaluateJavaScript("document.readyState === 'complete' ? document.URL : ''") as? String != url.absoluteString || isLoading {
			try #require(ContinuousClock.now < deadline, "\(path) did not load in 120 seconds.")
			try await Task.sleep(for: .milliseconds(50))
		}

		try await Task.sleep(for: .milliseconds(500))
		try #require(try await evaluateJavaScript("document.body?.childElementCount ?? 0") as? Int ?? 0 > 0, "\(path) is not a page of the site.")

		return try await evaluateJavaScript("pageErrors") as? [String] ?? ["The errors could not be read."]
	}

	/**
	Runs the body of an async function in the page, with the arguments as its parameters, and returns what it returns.
	*/
	fileprivate func result<Value>(of functionBody: String, arguments: [String: Any] = [:]) async throws -> Value {
		try #require(try await callAsyncJavaScript(functionBody, arguments: arguments, contentWorld: .page) as? Value)
	}
}

/**
The stylesheet and the scripts of the elements, made once for all the web views, as each web view has its own handler, and the handlers run on the main actor, one request after the other.
*/
private let siteStylesheet = Data(Stylesheet.site.css.utf8)
private let elementScripts = Project.website.elementScripts()

/**
Serves the site to the web view like a build: the rendered pages, the stylesheet, the icons, the scripts of the elements, and the public files.
*/
private final class SiteSchemeHandler: NSObject, WKURLSchemeHandler, WKNavigationDelegate {
	static let scheme = "sitetest"

	private let pages: [RenderedPage]
	private var hasLoadedPage = false

	init(pages: [RenderedPage]) {
		self.pages = pages
	}

	/**
	A page could send the visitor on after a moment. The test reads the page that it asked for, so a navigation after the first page loaded is canceled.
	*/
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
		hasLoadedPage ? .cancel : .allow
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		hasLoadedPage = true
	}

	func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
		guard let url = task.request.url else {
			return
		}

		let path = RoutePath(url.path(percentEncoded: false).isEmpty ? "/" : url.path(percentEncoded: false))
		let (data, mimeType) = response(for: path)
		task.didReceive(HTTPURLResponse(url: url, statusCode: data == nil ? 404 : 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": mimeType])!)
		task.didReceive(data ?? Data())
		task.didFinish()
	}

	func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}

	private func response(for path: RoutePath) -> (data: Data?, mimeType: String) {
		if let page = pages.first(where: { $0.route.path == path }) {
			return (Data(page.html.utf8), "text/html")
		}

		if path == Stylesheet.sitePath {
			return (siteStylesheet, "text/css")
		}

		if path == Icon.spritePath {
			return (Data(Icon.sprite.utf8), "image/svg+xml")
		}

		let file = elementScripts.first { $0.path == path }?.source ?? Project.website.publicFile(path)
		let mimeType = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
		return (try? Data(contentsOf: file), mimeType)
	}
}
