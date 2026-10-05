import Foundation
import SiteKit

/**
Where the App Store, GitHub, and npm data of a build comes from.
*/
public enum ExternalData: Sendable {
	/**
	Fetches the data, with responses in the cache.
	*/
	case fetch(ResponseCache)

	/**
	No App Store, GitHub, or npm data, so the build runs offline, like in tests.
	*/
	case none
}
