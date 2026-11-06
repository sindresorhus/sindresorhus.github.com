import Elementary
import Foundation
import Markdown
import SiteKit

/**
A shortcut that is shared on iCloud, like `https://www.icloud.com/shortcuts/41adf21d1bea44499d5034864687d01d`, with its name and its icon from its record on iCloud. An app page shows a link to it that is alone in its paragraph or list item, or at the start of a list item, as a card with the icon and the name (``ShortcutCard``), like in the Shortcuts app, so the visitor sees what the shortcut is before the click. A link in a sentence shows the icon and the name in a preview when the pointer rests on it (``LinkPreview``), and the Markdown copy of the page has the name after the link.

The record API (`https://www.icloud.com/shortcuts/api/records/<ID>`) is what the iCloud page of a shortcut uses. Apple does not document it.
*/
struct Shortcut: Sendable {
	/**
	The ID of a shared shortcut, the 32 hexadecimal digits at the end of its link.
	*/
	struct ID: Hashable, Sendable, CustomStringConvertible {
		/**
		The link of a shared shortcut, like `https://www.icloud.com/shortcuts/41adf21d1bea44499d5034864687d01d`.
		*/
		nonisolated(unsafe) private static let linkPattern = /https:\/\/www\.icloud\.com\/shortcuts\/([0-9a-f]{32})/

		let description: String

		/**
		The ID of the link, or `nil` for a link that is not to a shared shortcut.
		*/
		init?(link: String) {
			guard let match = link.wholeMatch(of: Self.linkPattern) else {
				return nil
			}

			self.description = String(match.1)
		}

		/**
		The link of the shortcut.
		*/
		var url: URL {
			#URL("https://www.icloud.com/shortcuts").appending(path: description)
		}

		/**
		Where the site publishes the icon of the shortcut.
		*/
		var iconPath: RoutePath {
			RoutePath("/shortcut-icons/\(self).png")
		}
	}

	let id: ID

	/**
	The name of the shortcut, like “Dato - Show seconds”.
	*/
	let name: String

	/**
	The icon of the shortcut, a 300 px PNG with the color and the glyph of the shortcut. The site publishes it at ``iconPath``, as the link of the icon on iCloud expires.
	*/
	let icon: Data

	/**
	The smaller JPEG XL copy of the icon, which the site publishes next to the icon. `nil` when the copy is not smaller.
	*/
	let iconJPEGXL: JPEGXLCopy?

	var iconPath: RoutePath {
		id.iconPath
	}

	/**
	The part of the record of a shortcut that the card uses.
	*/
	private struct Record: Decodable {
		struct Fields: Decodable {
			struct Name: Decodable {
				let value: String
			}

			struct Icon: Decodable {
				struct Value: Decodable {
					/**
					The link of the icon, with `${f}` where the file name goes. It expires after about an hour.
					*/
					let downloadURL: String

					/**
					The checksum of the icon file, which stays the same while the icon is the same, unlike its link.
					*/
					let fileChecksum: String
				}

				let value: Value
			}

			let name: Name
			let icon: Icon
		}

		let fields: Fields
	}

	/**
	Loads the record of the shortcut and its icon, with the responses in the cache. The icon is fetched right after its record, as its link expires.
	*/
	private init(id: ID, cache: ResponseCache, project: Project) async throws {
		let record = try await cache.decoded(Record.self, from: #URL("https://www.icloud.com/shortcuts/api/records").appending(path: id.description))

		guard let iconURL = URL(string: record.fields.icon.value.downloadURL.replacing("${f}", with: "icon.png")) else {
			throw ResponseCache.ReadError("The record has no valid link to the icon.")
		}

		self.id = id
		self.name = record.fields.name.value
		// By its checksum, as each record has a new link for the same icon, which would add a cache file for each refresh of the record. The icon of a checksum never changes, so it is used for a year without asking again, also on CI.
		self.icon = try await cache.decoded(
			from: iconURL,
			cacheIdentity: "shortcut-icon:\(record.fields.icon.value.fileChecksum)",
			maximumAge: .seconds(60 * 60 * 24 * 365)
		) { $0 }

		// `cjxl` reads a file, so the icon is also a file in the cache of the build.
		let iconFile = project.root.appending(path: ".cache/shortcut-icons/\(id).png")
		try iconFile.deletingLastPathComponent().createDirectory()
		try icon.write(to: iconFile, options: .atomic)
		self.iconJPEGXL = try await JPEGXLCopy(ofFile: iconFile, publishedAt: id.iconPath, project: project)
	}

	/**
	The shortcuts of the IDs, each with its record and icon. A shortcut that fails to load, like a deleted one, is a warning and is left out, so its link stays a plain link.
	*/
	static func load(
		ids: Set<ID>,
		cache: ResponseCache,
		project: Project,
		warnings: WarningCollector
	) async -> [ID: Self] {
		await warnings.values(of: ids) { id in
			"Could not get the shared shortcut \(id.url.absoluteString), so its link has no card and no preview. If the shortcut was deleted, remove its link"
		} request: { id in
			try await Self(id: id, cache: cache, project: project)
		}
	}
}

extension Markdown.Link {
	/**
	The shared shortcut that the link goes to, or `nil` for another link.
	*/
	var shortcutID: Shortcut.ID? {
		destination.flatMap(Shortcut.ID.init(link:))
	}
}

extension Paragraph {
	/**
	The link to a shared shortcut that the page shows as a card (``ShortcutCard``): the link that the paragraph starts with, when it is the whole paragraph, like a list item `- [Show seconds](https://www.icloud.com/shortcuts/…)`, or when the paragraph is the start of a list item, like `- [Presentation Mode](https://www.icloud.com/shortcuts/…): Hides the desktop icons.`, where the text after the link is a note below the card. A link in a sentence stays a link.
	*/
	var shortcutCardLink: Markdown.Link? {
		guard
			let link = child(at: 0) as? Markdown.Link,
			link.shortcutID != nil,
			childCount == 1 || (parent is ListItem && indexInParent == 0)
		else {
			return nil
		}

		return link
	}
}

extension Document {
	/**
	The shortcuts of the links to a shared shortcut, in a card or in a sentence.
	*/
	var shortcutIDs: Set<Shortcut.ID> {
		Set(descendants(of: Markdown.Link.self).compactMap(\.shortcutID))
	}

	/**
	The document with each link to one of the shortcuts that is a card as its card (``Paragraph/shortcutCardLink``, ``ShortcutCard``). The link of a shortcut that did not load stays a link.
	*/
	func showingShortcutCards(_ shortcuts: [Shortcut.ID: Shortcut]) -> Document {
		guard !shortcuts.isEmpty else {
			return self
		}

		var rewriter = ShortcutCardRewriter(shortcuts: shortcuts)
		return rewriter.visit(self) as? Document ?? self
	}
}

private struct ShortcutCardRewriter: MarkupRewriter {
	let shortcuts: [Shortcut.ID: Shortcut]

	/**
	The card of the link of the paragraph (``Paragraph/shortcutCardLink``), or `nil` for a paragraph without one, or with a shortcut that did not load. The title is the text of the link.
	*/
	private func card(of paragraph: Paragraph) -> HTMLBlock? {
		guard
			let link = paragraph.shortcutCardLink,
			let shortcut = link.shortcutID.flatMap({ shortcuts[$0] })
		else {
			return nil
		}

		return HTMLBlock(ShortcutCard(shortcut: shortcut, title: link.plainText).render())
	}

	mutating func visitParagraph(_ paragraph: Paragraph) -> (any Markup)? {
		// A paragraph with text after the link becomes two blocks, in its list item.
		guard paragraph.childCount == 1 else {
			return paragraph
		}

		return card(of: paragraph) ?? paragraph
	}

	mutating func visitListItem(_ listItem: ListItem) -> (any Markup)? {
		guard
			let paragraph = listItem.child(at: 0) as? Paragraph,
			paragraph.childCount > 1,
			let card = card(of: paragraph)
		else {
			return defaultVisit(listItem)
		}

		// The text after the link is a note below the card, without the colon or the space that was between them.
		var noteChildren = Array(paragraph.inlineChildren.dropFirst())

		if let text = noteChildren.first as? Markdown.Text {
			let trimmed = text.string.trimmingPrefix(Self.noteSeparator)
			noteChildren[0..<1] = trimmed.isEmpty ? [] : [Markdown.Text(String(trimmed))]
		}

		// Only a colon after the link is no note.
		guard !noteChildren.isEmpty else {
			var listItem = listItem
			listItem.replaceChildrenInRange(0..<1, with: [card] as [any BlockMarkup])
			return defaultVisit(listItem)
		}

		// In an element, which the styles of the card find, as a list without blank lines between its items has no paragraphs.
		var note = paragraph
		note.setInlineChildren([InlineHTML("<span>")] + noteChildren + [InlineHTML("</span>")])

		var listItem = listItem
		listItem.replaceChildrenInRange(0..<1, with: [card, note] as [any BlockMarkup])
		return defaultVisit(listItem)
	}

	/**
	What is between the link of a card and its note, like the colon and the space of `[Presentation Mode](…): Hides the desktop icons.`.
	*/
	nonisolated(unsafe) private static let noteSeparator = /:?\s*/
}
