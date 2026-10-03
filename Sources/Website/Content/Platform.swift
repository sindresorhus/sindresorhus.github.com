public enum Platform: String, CaseIterable, Codable, Sendable {
	case macOS
	case iOS
	case watchOS
	case tvOS
	case visionOS
	case Linux
	case Windows
}

/**
A macOS version that has a free older version of an app.

Future versions are listed ahead of time on purpose, so the list never needs updating. Keep it an enum, and do not remove the future cases.
*/
public enum MacOSVersion: String, CaseIterable, Codable, Sendable {
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
	For sorting, since `10.15` comes before `11`.
	*/
	var number: Double {
		Double(rawValue) ?? 0
	}

	/**
	A fragment-safe ID, like `macos-10-15`.
	*/
	var id: String {
		"macos-\(rawValue.replacing(".", with: "-"))"
	}
}
