import Elementary
import SiteKit

// Type-check against the built SiteKit module. Each INVALID_* flag selects a call that must fail; without a flag, the typed calls and explicit raw font escape must compile.
#if INVALID_MEDIA_QUERY_DISJUNCTION
let invalidQuery = MediaQuery.print || MediaCondition.hover
#elseif INVALID_MEDIA_QUERY_NEGATION
let invalidQuery = !MediaQuery.print
#elseif INVALID_RAW_MEDIA_QUERY_COMPOSITION
let invalidQuery = MediaQuery(raw: "screen, print") && MediaCondition.dark
#elseif INVALID_SOURCE_SET_FRACTIONAL_WIDTH
let invalidSourceSet = ImageSourceSet.width([(.path(#path("/image.png")), 320.5)])
#elseif INVALID_ASPECT_RATIO_LENGTH
let invalidRatio = Style().aspectRatio(.ratio(width: Length.pixels(16), height: 9))
#elseif INVALID_NUMBER_DIVISION_LENGTH
let invalidNumber = CSSNumber.siblingIndex / Length.pixels(2)
#elseif INVALID_PRESSED_STRING
let invalidPressed = button(.ariaPressed("mixed")) {}
#elseif INVALID_COUNTER_IDENTITY
public enum InvalidCounters: CounterSet {
	case step
}
#elseif INVALID_DECLARATION_PAIR
let invalidDeclaration = Style().declaration(.width, Color.black)
#elseif INVALID_REGISTRATION_RELATIVE_LENGTH
let invalidRegistration = RegisteredProperty<Length>("relative", initialValue: .em(1))
#elseif INVALID_REGISTRATION_VARIABLE
let invalidRegistration = RegisteredProperty<Length>("variable", initialValue: StyleVariable<Length>("other").value)
#elseif INVALID_REGISTRATION_CURRENT_COLOR
let invalidRegistration = RegisteredProperty<Color>("dependent-color", initialValue: .currentColor)
#elseif INVALID_IMAGE_DIMENSION
let invalidImageSize = Style().backgroundSize(.dimensions(width: .black, height: .auto))
#elseif INVALID_LINE_HEIGHT_COLOR
let invalidLineHeight = Style().lineHeight(Color.black)
#elseif INVALID_OKLCH_COMPONENT
let invalidColor = Color.oklch(lightness: CSSNumber(50), chroma: 0.2, hue: .degrees(180))
#elseif INVALID_FONT_LITERAL
let invalidFont = Style().fontFamily("A,B")
#elseif INVALID_ANIMATION_DELAY
let invalidDelay = Style().animationDelay(100)
#elseif INVALID_DELAY_MULTIPLIER
let invalidMultiplier = Style().animationDelay(.seconds(1), multipliedBy: .pixels(1))
#elseif INVALID_SCROLL_NAMED_RANGE
let invalidRange = Style().animation(FixtureAnimations.fade, timeline: .scroll, from: .entry(.percent(10)), to: .exit(.percent(90)))
#elseif INVALID_SPECULATION_RULES
let invalidRules = JSONScript(speculationRules: 42)
#elseif INVALID_INTRINSIC_SIZE
let invalidSize = div().intrinsicSize(PixelSize(width: 640, height: 480)!)
#elseif INVALID_DISABLED_UNDERLINE_CONFIGURATION
let invalidUnderline = Style().underline(false, color: .black)
#else
let lengthRegistration = RegisteredProperty<Length>("constant-size", initialValue: .pixels(8))
let colorRegistration = RegisteredProperty<Color>("constant-color", initialValue: .rgb(red: 0, green: 128, blue: 255))
let styles = [
	Style().declaration(raw: .transformOrigin, "top left"),
	Style().backgroundSize(.cover).maskSize(.dimensions(width: .auto, height: .percent(100))),
	Style().lineHeight(.normal).lineHeight(1.5),
	Style().background(.oklch(lightness: .percent(50), chroma: 0.2, hue: .degrees(180))),
	Style().fontFamily(.named("A,B")),
	Style().fontFamily(.systemUI),
	Style().fontFamily(FontFamily(raw: "system-ui, sans-serif")),
	Style().content(.openQuote),
	Style().content("open-quote"),
	Style().underline(color: .currentColor, thickness: .pixels(2)).noUnderline(),
	Style().animationDelay(.milliseconds(-100)),
	Style().animationDelay(.milliseconds(100), multipliedBy: .siblingIndex - 2),
	Style().animation(FixtureAnimations.fade, timeline: .scroll, from: .zero, to: .percent(100)),
	Style().animation(FixtureAnimations.fade, viewTimeline: ViewTimeline("section"), from: .entry(.percent(10)), to: .exit(.percent(90))),
	Style().willChange(.transform, .opacity),
]
let sizedImage = img().intrinsicSize(PixelSize(width: 640, height: 480)!)
let responsiveImage = img(.srcset(.density([(.path(#path("/small.png")), 2), (.path(#path("/large.png")), 3)])))
let responsiveSource = source(.srcset(.width([(.path(#path("/small.png")), 320), (.path(#path("/large.png")), 640)])))
let printStyle = Style().media(.print(matching: .dark || .moreContrast)) { $0.noScrollSnapping() }
let conditionStyle = Style().media(.hover && .finePointer) { $0.opacity(1) }
let ratioStyle = Style().aspectRatio(.automatic(width: StyleVariable<CSSNumber>("width").value, height: 9))
let numericStyle = Style().opacity(-(CSSNumber.siblingIndex / .siblingCount))
let mixedButton = button(.ariaPressed(.mixed)) {}
#endif

enum FixtureAnimations: String, KeyframeSet {
	case fade

	var keyframes: [Keyframe] {
		[.to(Style().opacity(1))]
	}
}
