import Foundation
import SiteKit

/**
Where the App Store, GitHub, npm, and Bluesky data of a build comes from.
*/
public enum ExternalData: Sendable {
	/**
	Fetches the data, with responses in the cache.
	*/
	case fetch(ResponseCache)

	/**
	No App Store, GitHub, npm, or Bluesky data, so the build runs offline, like in tests.
	*/
	case none
}
