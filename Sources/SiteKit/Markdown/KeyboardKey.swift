/**
A key of a keyboard shortcut, like `Command`, `K`, or `◀` in `++Command+◀++`.

The keys have their names on the keyboard of a Mac, so all the shortcuts of the site look the same. A key without a name is its glyph, like `◀`, which the page shows with its name for screen readers, as they would read the Unicode name, like “black left-pointing triangle”.
*/
public enum KeyboardKey: Hashable, Sendable {
	/**
	A modifier key. The cases are in the order of Apple, like in the menus of macOS: Control, Option, Shift, Command. The raw value is the name on the keyboard of a Mac.
	*/
	public enum Modifier: String, CaseIterable, Sendable {
		case control = "Control"
		case option = "Option"
		case shift = "Shift"
		case command = "Command"

		/**
		The glyph of the modifier in the menus of macOS, like `⌘` for Command.
		*/
		public var glyph: Character {
			switch self {
			case .control:
				"⌃"
			case .option:
				"⌥"
			case .shift:
				"⇧"
			case .command:
				"⌘"
			}
		}

		/**
		The modifier of a glyph, like Command for `⌘`.
		*/
		public init?(glyph: Character) {
			guard let modifier = Self.allCases.first(where: { $0.glyph == glyph }) else {
				return nil
			}

			self = modifier
		}
	}

	/**
	A key that is written as its glyph, as the glyph is on the key, like `◀`. The raw value is the glyph.
	*/
	public enum Glyph: Character, CaseIterable, Sendable {
		case leftArrow = "◀"
		case rightArrow = "▶"
		case upArrow = "▲"
		case downArrow = "▼"
		case delete = "⌫"
		case forwardDelete = "⌦"
		case `return` = "↩"
		case tab = "⇥"
		case escape = "⎋"

		/**
		The name of the key, which screen readers read instead of the glyph, like “Left Arrow”.
		*/
		public var spokenName: String {
			switch self {
			case .leftArrow:
				"Left Arrow"
			case .rightArrow:
				"Right Arrow"
			case .upArrow:
				"Up Arrow"
			case .downArrow:
				"Down Arrow"
			case .delete:
				"Delete"
			case .forwardDelete:
				"Forward Delete"
			case .return:
				"Return"
			case .tab:
				"Tab"
			case .escape:
				"Escape"
			}
		}
	}

	case modifier(Modifier)
	case glyph(Glyph)

	/**
	The plus key, written as `Plus`, as a `+` between keys is a separator, like in `Command+Plus`. A `+` that ends the shortcut, like in `Command++`, or a shortcut that is only `+`, is the plus key too.
	*/
	case plus

	/**
	Any other key, like `K` or `Esc`, by its name as written.
	*/
	case named(String)

	/**
	The key written as `name`, like `Command`, `◀`, `Plus`, or `K`.
	*/
	init(_ name: some StringProtocol) {
		if let modifier = Modifier(rawValue: String(name)) {
			self = .modifier(modifier)
		} else if name == "Plus" || name == "+" {
			self = .plus
		} else if
			name.count == 1,
			let glyph = name.first.flatMap(Glyph.init(rawValue:))
		{
			self = .glyph(glyph)
		} else {
			self = .named(String(name))
		}
	}

	/**
	The keys of a shortcut, like `Command+K`. Smart punctuation changed keys like quotes, but a key is the character on the keyboard.
	*/
	static func keys(of shortcut: String) -> [Self] {
		names(of: shortcut.removingSmartPunctuation).map(Self.init)
	}

	/**
	The keys of a shortcut as they are written, like `Cmd` and `K` for `Cmd+K`. A `+` that ends the shortcut, like in `Cmd++` or `Ctrl+`, or a shortcut that is only `+`, is the plus key.
	*/
	private static func names(of shortcut: String) -> [String] {
		var names = [String]()
		var name = ""

		for character in shortcut {
			if
				character == "+",
				!name.isEmpty
			{
				names.append(name)
				name = ""
			} else {
				name.append(character)
			}
		}

		names.append(name.isEmpty ? "+" : name)
		return names
	}

	/**
	The shortcut as it is written in the Markdown of the site, with each key by its name on the keyboard of a Mac (``mistake(in:)``), like `Command+C` for `cmd+c` or `⌘C`, or `Command+Plus` for `Command+`, as a `+` is a separator.
	*/
	public static func correctedShortcut(_ shortcut: String) -> String {
		let correctedNames = keys(of: shortcut)
			.map { key in
				guard case .named(let name) = key else {
					return key.name
				}

				return correctName(of: name) ?? name
			}
			.joined(separator: "+")

		// A corrected key can be several keys, like `Option+Command+V` for `⌥⌘V`.
		return keys(of: correctedNames).inAppleOrder.map(\.name).joined(separator: "+")
	}

	/**
	How the key is written, like `Command` or `◀`.
	*/
	var name: String {
		switch self {
		case .modifier(let modifier):
			modifier.rawValue
		case .glyph(let glyph):
			String(glyph.rawValue)
		case .plus:
			"Plus"
		case .named(let name):
			name
		}
	}

	/**
	The HTML of the key in a `<kbd>`, like `Command`. The plus key is `+`. A glyph key has its name for screen readers, which skip the glyph.
	*/
	var html: String {
		switch self {
		case .modifier(let modifier):
			modifier.rawValue
		case .glyph(let glyph):
			// An image with a label, not hidden text, so screen readers say the name, but a copy of the text has only the glyph.
			#"<span role="img" aria-label="\#(glyph.spokenName)">\#(glyph.rawValue)</span>"#
		case .plus:
			"+"
		case .named(let name):
			name.escapedForHTML
		}
	}

	/**
	The modifier of the key, or `nil` for another key.
	*/
	var modifier: Modifier? {
		guard case .modifier(let modifier) = self else {
			return nil
		}

		return modifier
	}

	/**
	What is wrong with how the key is written in a shortcut like `++Command+K++`, or `nil` when it is right: a key must be its name on the keyboard of a Mac (``keyNames``), not a modifier glyph, like `⌘`, an abbreviation, like `Cmd`, a lowercase name, like `command` or `k`, or a name that no key has, like `Enterr`. A key without a name is its glyph, like `◀`, and the glyph needs a spoken name (``Glyph``).

	- Parameter shortcut: The shortcut, for the message.
	*/
	func mistake(in shortcut: String) -> String? {
		guard case .named(let name) = self else {
			return nil
		}

		if let correctName = Self.correctName(of: name) {
			return "Write the key `\(name)` of the keyboard shortcut `\(shortcut)` as `\(correctName)`, its name on the keyboard of a Mac."
		}

		// Screen readers read the punctuation of a keyboard, like `,` and `/`, by its name.
		if
			name.count == 1,
			let character = name.first,
			!character.isASCII,
			!character.isLetter,
			!character.isNumber
		{
			return "The key `\(name)` of the keyboard shortcut `\(shortcut)` is a glyph without a name for screen readers. Write the name of the key, or add the glyph to `KeyboardKey.Glyph`."
		}

		guard !Self.isKeyName(name) else {
			return nil
		}

		return "`\(name)` of the keyboard shortcut `\(shortcut)` is not a key of a Mac keyboard. Write the name on the key, like `Return` or `K`, or add the key to `KeyboardKey.keyNames`."
	}

	/**
	The names of the keys of a Mac keyboard that are not a modifier or a glyph, like `Return` or `F1`. `Win` is for the shortcuts of Windows, like in a Windows app.
	*/
	private static let keyNames: Set<String> = {
		let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)
		let digits = (0...9).map(String.init)
		let functionKeys = (1...20).map { "F\($0)" }
		let named = ["Return", "Enter", "Space", "Tab", "Esc", "Delete", "Forward Delete", "Fn", "Home", "End", "Page Up", "Page Down", "Caps Lock", "Win"]
		return Set(letters + digits + functionKeys + named)
	}()

	/**
	Whether the name is a key of a Mac keyboard (``keyNames``), or a punctuation key, like `,` or `/`.
	*/
	private static func isKeyName(_ name: String) -> Bool {
		guard !keyNames.contains(name) else {
			return true
		}

		guard
			name.count == 1,
			let character = name.first
		else {
			return false
		}

		return character.isASCII && (character.isPunctuation || character.isSymbol)
	}

	/**
	The name on the keyboard of a Mac for a key written with modifier glyphs, an abbreviation, another common name, or in another case, like `Command` for `⌘`, `Cmd`, and `command`, `Option+Command+V` for `⌥⌘V`, `Esc` for `Escape`, `▲` for `Up Arrow`, or `K` for `k`. `nil` for a key that is already right, like `Command` or `Esc`.
	*/
	private static func correctName(of name: String) -> String? {
		// The names of other keyboards and of guides for Windows too.
		let otherNames = ["cmd": "Command", "ctrl": "Control", "ctl": "Control", "opt": "Option", "alt": "Option", "del": "Delete", "escape": "Esc", "spacebar": "Space", "space bar": "Space", "backspace": "Delete"]

		// Glyph shortcuts start with their modifiers, like `⌥⌘V`.
		let glyphModifiers = name.prefix { Modifier(glyph: $0) != nil }.compactMap(Modifier.init(glyph:))

		if !glyphModifiers.isEmpty {
			let key = String(name.dropFirst(glyphModifiers.count))
			return (Modifier.allCases.filter(glyphModifiers.contains).map(\.rawValue) + (key.isEmpty ? [] : [correctName(of: key) ?? key])).joined(separator: "+")
		}

		let lowercasedName = name.lowercased()

		if let correctName = otherNames[lowercasedName] {
			return correctName
		}

		// An arrow key has no name on the keyboard, so it is its glyph.
		if
			let glyph = Glyph.allCases.first(where: { $0.spokenName.lowercased() == lowercasedName }),
			!keyNames.contains(glyph.spokenName)
		{
			return String(glyph.rawValue)
		}

		// A key name in another case, like `command`, `k`, or `page up`. A name that no key has gets no suggestion, as it is not the name of a key in any case.
		guard
			let keyName = (Modifier.allCases.map(\.rawValue) + [KeyboardKey.plus.name] + keyNames).first(where: { $0.lowercased() == lowercasedName }),
			keyName != name
		else {
			return nil
		}

		return keyName
	}
}

extension [KeyboardKey] {
	/**
	The keys with the modifiers first, in the order of Apple (``KeyboardKey/Modifier``), like `Shift+Command+K` for `Command+Shift+K`.
	*/
	var inAppleOrder: Self {
		let modifiers = compactMap(\.modifier)
		return KeyboardKey.Modifier.allCases.filter(modifiers.contains).map(KeyboardKey.modifier) + filter { $0.modifier == nil }
	}
}
