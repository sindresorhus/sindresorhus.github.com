import SiteKit

enum Platform: String, ContentEnum, Encodable {
	case macOS
	case iOS
	case watchOS
	case tvOS
	case visionOS

	/**
	A device of the platform, like a laptop for macOS.
	*/
	var icon: Icon {
		switch self {
		case .macOS:
			.deviceLaptop
		case .iOS:
			.deviceMobile
		case .watchOS:
			.deviceWatch
		case .tvOS:
			.deviceTV
		case .visionOS:
			.deviceVisionPro
		}
	}

	/**
	Whether Safari on the platform shows the App Store banner of an app page, which is only for apps that run on the device. These are also the platforms whose apps are one purchase with the Mac app on the App Store (iPhone, iPad, and Apple Vision).
	*/
	var hasAppStoreBanner: Bool {
		self == .iOS || self == .visionOS
	}

	/**
	Whether an app of the platform is installed from a phone, so a QR code to the App Store helps. Apple Watch apps are installed from the iPhone too, so they count, unlike for the App Store banner.
	*/
	var installsFromPhone: Bool {
		hasAppStoreBanner || self == .watchOS
	}
}

/**
A macOS version that has a free older version of an app.

Future versions are listed ahead of time on purpose, so the list never needs updating. Keep it an enum, and do not remove the future cases. The cases are in version order, oldest first, which the older versions page sorts by.
*/
enum MacOSVersion: String, ContentEnum, Encodable {
	case v10_13 = "10.13"
	case v10_14 = "10.14"
	case v10_15 = "10.15"
	case v11 = "11"
	case v12 = "12"
	case v13 = "13"
	case v14 = "14"
	case v15 = "15"
	case v26 = "26"
	case v27 = "27"
	case v28 = "28"
	case v29 = "29"
	case v30 = "30"
	case v31 = "31"
	case v32 = "32"
	case v33 = "33"
	case v34 = "34"

	/**
	A fragment-safe ID, like `macos-10-15`.
	*/
	var id: String {
		"macos-\(rawValue.replacing(".", with: "-"))"
	}

	/**
	The name of the version, like “macOS 10.15”.
	*/
	var title: String {
		"macOS \(rawValue)"
	}

	/**
	The version as an ``OSVersion``, to compare it with another version, like a requirement.
	*/
	var osVersion: OSVersion {
		// Every raw value is a version.
		OSVersion(rawValue)!
	}
}

/**
The version of an OS with its minor version, like `26.1`, for the lowest version that an app runs on. A ``MacOSVersion`` has only the versions that have older versions of the apps.

In frontmatter, it is text, like `'26'` or `'26.1'`, as the numbers `26.1` and `26.10` are the same.
*/
struct OSVersion: Hashable, Comparable, CustomStringConvertible {
	let major: Int
	let minor: Int

	/**
	A version from its numbers, like `OSVersion(major: 26)` for a version that is a number in the frontmatter.
	*/
	init(major: Int, minor: Int = 0) {
		precondition(major >= 0 && minor >= 0, "OS version components cannot be negative.")
		self.major = major
		self.minor = minor
	}

	/**
	`nil` for text that is not a version, like `26.x`. A patch version is left out, like in `26.1.2`.
	*/
	init?(_ text: String) {
		// Only digits, as `Int` also reads a sign, like `+26`.
		let parts = text.split(separator: ".", omittingEmptySubsequences: false).map { part in part.allSatisfy { $0.isASCII && $0.isNumber } ? Int(part) : nil }

		guard
			(1...3).contains(parts.count),
			!parts.contains(nil),
			let major = parts[0],
			let minor = parts.count > 1 ? parts[1] : 0
		else {
			return nil
		}

		self.init(major: major, minor: minor)
	}

	/**
	Like `26`, or `26.1`, without `.0`, like Apple writes it.
	*/
	var description: String {
		minor == 0 ? String(major) : "\(major).\(minor)"
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		(lhs.major, lhs.minor) < (rhs.major, rhs.minor)
	}

	/**
	The start of a requirement (``macOSRequirementSentence``), which `website check` uses to find the requirement that the content writes below a list of older versions, like `*Requires macOS 15 or later*`.
	*/
	static let requirementPrefix = "Requires "

	/**
	The requirement of something that runs on this version of macOS or later, like “Requires macOS 26 or later”, which the trials, the older versions, and the tiny apps show. An app page says its requirement with its platforms (``AppListing/requirementSentence``).
	*/
	var macOSRequirementSentence: String {
		"\(Self.requirementPrefix)\(Platform.macOS.rawValue) \(self) or later"
	}
}

extension OSVersion: ValidatedValue {
	init(validating rawValue: String) throws(ContentError) {
		guard let version = Self(rawValue) else {
			throw ContentError(reason: "Must be a version, like `'26'` or `'26.1'`, got \(rawValue).")
		}

		self = version
	}
}
