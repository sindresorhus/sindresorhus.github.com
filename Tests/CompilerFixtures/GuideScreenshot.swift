import SiteKit
@testable import Website

// Type-check against the testable Website module. Each INVALID_* flag selects an unchecked construction that must fail.
#if INVALID_SCREENSHOT_INTEGER
func assignInteger(_ screenshot: inout Guide.Screenshot, number: Int) {
	screenshot.number = number
}
#elseif INVALID_SCREENSHOT_MEMBERWISE
let number = Guide.Screenshot.Number(value: 0)
#else
func selectScreenshot(_ screenshot: inout Guide.Screenshot, number: Int) throws(ContentError) {
	screenshot.number = try Guide.Screenshot.Number(validating: number)
}
#endif
