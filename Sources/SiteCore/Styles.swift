import Elementary
import Foundation

public struct CSSDeclaration: Hashable, Sendable {
	public let property: String
	public let value: String

	public init(_ property: String, _ value: String) {
		self.property = property
		self.value = value
	}
}

public struct StyleVariant: Hashable, Sendable {
	public let suffix: String
	public let media: String?
	public let declarations: [CSSDeclaration]

	public init(suffix: String = "", media: String? = nil, declarations: [CSSDeclaration]) {
		self.suffix = suffix
		self.media = media
		self.declarations = declarations
	}
}

public struct SiteStyle: Hashable, Sendable {
	public let declarations: [CSSDeclaration]
	public let variants: [StyleVariant]

	public init(_ declarations: [CSSDeclaration], variants: [StyleVariant] = []) {
		self.declarations = declarations
		self.variants = variants
	}
}

public enum CSS {
	public static func display(_ value: String) -> CSSDeclaration { .init("display", value) }
	public static func color(_ value: String) -> CSSDeclaration { .init("color", value) }
	public static func background(_ value: String) -> CSSDeclaration { .init("background", value) }
	public static func padding(_ value: String) -> CSSDeclaration { .init("padding", value) }
	public static func margin(_ value: String) -> CSSDeclaration { .init("margin", value) }
	public static func gap(_ value: String) -> CSSDeclaration { .init("gap", value) }
	public static func borderRadius(_ value: String) -> CSSDeclaration { .init("border-radius", value) }
	public static func boxShadow(_ value: String) -> CSSDeclaration { .init("box-shadow", value) }
	public static func transform(_ value: String) -> CSSDeclaration { .init("transform", value) }
	public static func transition(_ value: String) -> CSSDeclaration { .init("transition", value) }
	public static func fontSize(_ value: String) -> CSSDeclaration { .init("font-size", value) }
	public static func fontWeight(_ value: String) -> CSSDeclaration { .init("font-weight", value) }
	public static func textAlign(_ value: String) -> CSSDeclaration { .init("text-align", value) }
	public static func custom(_ property: String, _ value: String) -> CSSDeclaration { .init(property, value) }
}

public final class StyleRegistry: @unchecked Sendable {
	public static let shared = StyleRegistry()
	private let lock = NSLock()
	private var styles: [String: SiteStyle] = [:]

	private init() {}

	public func reset() {
		lock.lock(); defer { lock.unlock() }
		styles = [:]
	}

	public func register(_ style: SiteStyle) -> String {
		let signature = Self.signature(style)
		let className = "s-" + Self.fnv1a(signature)
		lock.lock(); defer { lock.unlock() }
		styles[className] = style
		return className
	}

	public func generatedCSS() -> String {
		lock.lock(); let snapshot = styles; lock.unlock()
		return snapshot.keys.sorted().compactMap { className in
			guard let style = snapshot[className] else { return nil }
			var sections: [String] = []
			if !style.declarations.isEmpty {
				sections.append(Self.render(selector: ".\(className)", declarations: style.declarations))
			}
			for variant in style.variants {
				let rule = Self.render(selector: ".\(className)\(variant.suffix)", declarations: variant.declarations)
				sections.append(variant.media.map { "@media \($0) {\n\(rule.indented())\n}" } ?? rule)
			}
			return sections.joined(separator: "\n")
		}.joined(separator: "\n\n")
	}

	private static func signature(_ style: SiteStyle) -> String {
		let base = style.declarations.map { "\($0.property):\($0.value)" }.sorted().joined(separator: ";")
		let variants = style.variants.map { variant in
			"\(variant.media ?? "")|\(variant.suffix)|" + variant.declarations.map { "\($0.property):\($0.value)" }.sorted().joined(separator: ";")
		}.sorted().joined(separator: "||")
		return base + "##" + variants
	}

	private static func fnv1a(_ string: String) -> String {
		var hash: UInt64 = 14_695_981_039_346_656_037
		for byte in string.utf8 { hash ^= UInt64(byte); hash &*= 1_099_511_628_211 }
		return String(hash, radix: 36)
	}

	private static func render(selector: String, declarations: [CSSDeclaration]) -> String {
		let body = declarations.map { "\t\($0.property): \($0.value);" }.joined(separator: "\n")
		return "\(selector) {\n\(body)\n}"
	}
}

public extension HTML where Tag: HTMLTrait.Attributes.Global {
	func siteStyle(_ style: SiteStyle) -> some HTML<Tag> {
		attributes(.class(StyleRegistry.shared.register(style)))
	}
}

private extension String {
	func indented() -> String { split(separator: "\n", omittingEmptySubsequences: false).map { "\t" + $0 }.joined(separator: "\n") }
}

public enum SiteStyles {
	public static var stylesheet: String {
		baseCSS + "\n\n" + StyleRegistry.shared.generatedCSS()
	}

	private static let baseCSS = #"""
:root {
	color-scheme: light dark;
	--primary: #2563eb;
	--primary-light: #60a5fa;
	--secondary: #ec4899;
	--color-primary-50: #eff6ff;
	--color-primary-100: #dbeafe;
	--color-primary-200: #bfdbfe;
	--color-primary-300: #93c5fd;
	--color-primary-400: #60a5fa;
	--color-primary-500: #3b82f6;
	--color-primary-600: #2563eb;
	--color-primary-700: #1d4ed8;
	--color-primary-800: #1e40af;
	--color-primary-900: #1e3a8a;
	--color-primary-950: #172554;
	--color-secondary-50: #fdf2f8;
	--color-secondary-100: #fce7f3;
	--color-secondary-200: #fbcfe8;
	--color-secondary-300: #f9a8d4;
	--color-secondary-400: #f472b6;
	--color-secondary-500: #ec4899;
	--color-secondary-600: #db2777;
	--color-secondary-700: #be185d;
	--color-secondary-800: #9d174d;
	--color-secondary-900: #831843;
	--color-secondary-950: #500724;
	--color-gray-400: #9ca3af;
	--surface: #ffffff;
	--surface-subtle: #f8fafc;
	--text: #111827;
	--text-secondary: #4b5563;
	--border: #e5e7eb;
	--code-bg: #f1f5f9;
	font-family: Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}
@media (prefers-color-scheme: dark) {
	:root {
		--surface: #020617;
		--surface-subtle: #0f172a;
		--text: #cbd5e1;
		--text-secondary: #94a3b8;
		--border: #1e293b;
		--code-bg: #1e293b;
	}
}
*, *::before, *::after { box-sizing: border-box; }
html { scroll-behavior: smooth; scroll-padding-top: 80px; }
body { margin: 0; color: var(--text); background: var(--surface); overflow-x: clip; -webkit-font-smoothing: antialiased; letter-spacing: -0.025em; }
@media (min-width: 1536px) { html { font-size: 20px; } }
a { color: inherit; }
img, video { max-width: 100%; height: auto; }
button, input, textarea, select { font: inherit; }
.site-header { position: sticky; top: 0; z-index: 40; border-bottom: 1px solid var(--border); background: color-mix(in srgb, var(--surface) 92%, transparent); backdrop-filter: blur(14px); }
.site-nav { max-width: 72rem; margin: 0 auto; min-height: 4.5rem; padding: .75rem 1rem; display: flex; align-items: center; justify-content: space-between; gap: 1rem; }
.site-brand { font-size: 1.4rem; font-weight: 800; text-decoration: none; color: var(--text); white-space: nowrap; }
.site-links { display: flex; align-items: center; gap: .25rem; list-style: none; padding: 0; margin: 0; }
.site-links a { display: inline-flex; align-items: center; padding: .65rem .85rem; border-radius: .55rem; text-decoration: none; color: var(--text-secondary); font-weight: 550; }
.site-links a:hover, .site-links a[aria-current="page"] { color: var(--text); background: color-mix(in srgb, var(--text) 6%, transparent); }
.mobile-nav-only { display: none; }
.desktop-nav-only { display: list-item; }
.nav-separator { width: 1px; height: 1.5rem; margin: 0 .75rem; align-self: center; background: color-mix(in srgb, var(--text-secondary) 25%, transparent); border-radius: 999px; }
.mobile-menu-toggle { display: none; }
#menu-toggle { position:absolute; opacity:0; pointer-events:none; }
.icon-link { display:inline-flex; align-items:center; justify-content:center; padding:.65rem; border-radius:.55rem; color:var(--text-secondary); }
.icon-link:hover { color:var(--text); background:color-mix(in srgb,var(--text) 6%,transparent); }
.icon { width: 1.25rem; height: 1.25rem; }
.site-footer { border-top: 1px solid var(--border); }
.site-footer-inner { max-width: 72rem; margin: 0 auto; padding: 1.5rem 1rem; display:flex; align-items:center; justify-content:space-between; gap:1rem; }
.social-links { display:flex; list-style:none; padding:0; margin:0; }
.page-container { max-width: 72rem; margin: 0 auto; padding: 4rem 1.5rem; }
.content-container { max-width: 48rem; margin: 0 auto; padding: 3rem 1.5rem 5rem; }
.prose { font-size: 1.125rem; line-height: 1.75; overflow-wrap:anywhere; letter-spacing: normal; }
.prose h1,.prose h2,.prose h3,.prose h4 { color:var(--text); line-height:1.15; letter-spacing:-.025em; }
.prose h1 { font-size:2.8rem; margin:1.2em 0 .7em; }
.prose h2 { font-size:2rem; margin:3em 0 .8em; }
.prose h3 { font-size:1.5rem; margin:2em 0 .7em; }
.prose h4 { font-size:1.15rem; margin:1.8em 0 .6em; }
.prose p,.prose ul,.prose ol,.prose blockquote,.prose table,.prose pre { margin:1.2em 0; }
.prose a { text-decoration: underline; text-decoration-color: var(--primary); text-decoration-thickness:2px; text-underline-offset:4px; }
.prose code { background:var(--code-bg); padding:.1em .3em; border-radius:.3em; font-size:.9em; }
.prose pre { background:#0f172a; color:#e2e8f0; padding:1rem; border-radius:.6rem; overflow:auto; }
.prose pre code { background:none; padding:0; }
.prose img { border-radius:.5rem; box-shadow:0 8px 30px rgb(0 0 0 / .12); }
.prose table { width:100%; border-collapse:collapse; }
.prose th,.prose td { padding:.6rem; border-bottom:1px solid var(--border); text-align:left; }
.kbd-sep { font-size:.6em; font-weight:600; color:#9ca3af; margin:0 .1em; }
kbd { font-family:inherit; font-size:.8em; background:#f0f2f5; color:#2d3748; border:1px solid #c4cad4; border-bottom-width:3px; border-radius:5px; padding:.1em .45em; }
@media (prefers-color-scheme:dark) { kbd { background:#252d3d; color:#c9d1e0; border-color:#3d4a5c; border-bottom-color:#111827; } }
.markdown-alert { padding:.65rem 1rem; margin:1rem 0; border-left:.25rem solid; border-radius:.5rem; }
.markdown-alert-title { font-weight:700; margin:0 0 .25rem !important; }
.markdown-alert-note { border-color:#60a5fa; background:#eff6ff; } .markdown-alert-note .markdown-alert-title{color:#0284c7}
.markdown-alert-tip { border-color:#6ee7b7; background:#ecfdf5; } .markdown-alert-tip .markdown-alert-title{color:#059669}
.markdown-alert-important { border-color:#c084fc; background:#faf5ff; } .markdown-alert-important .markdown-alert-title{color:#9333ea}
.markdown-alert-warning { border-color:#fbbf24; background:#fffbeb; } .markdown-alert-warning .markdown-alert-title{color:#d97706}
.markdown-alert-caution { border-color:#fb7185; background:#fff1f2; } .markdown-alert-caution .markdown-alert-title{color:#e11d48}
@media (prefers-color-scheme:dark) { .markdown-alert-note{background:#0f172a}.markdown-alert-tip{background:#0a1a17}.markdown-alert-important{background:#1a0a2e}.markdown-alert-warning{background:#1a1408}.markdown-alert-caution{background:#1f0a0a} }
.heading-anchor { margin-left:.45rem; opacity:0; font-size:.75em; text-decoration:none!important; }
:is(h2,h3,h4):hover>.heading-anchor,summary:hover>.heading-anchor { opacity:.55; }
.faq-collapsible details { background:color-mix(in srgb,var(--text) 2%,transparent); border-radius:.75rem; margin:.75rem 0; }
.faq-collapsible summary { display:flex; align-items:center; padding:.8rem 1rem; font-weight:650; cursor:pointer; list-style:none; }
.faq-content { padding:.1rem 1rem .8rem; }
.faq-more-link { display:block; padding:.8rem 1rem; }
.list-subtitle { display:block; line-height:1.35; opacity:.67; font-size:1rem; }
.list-description { display:block; font-size:.875rem; line-height:1.55; opacity:.65; }
.hidden { display:none!important; } .whitespace-nowrap{white-space:nowrap}.pl-2{padding-left:.5rem}.text-xs{font-size:.75rem}.not-prose{font-size:initial;line-height:initial}
@media (min-width:640px){.sm\:block{display:block!important}}
@media (prefers-color-scheme:dark){.dark\:text-black{color:#000!important}}
.apps-hero { text-align:center; margin-bottom:3rem; }
.apps-title-row{display:flex;align-items:center;justify-content:center;gap:.9rem;flex-wrap:wrap}
.apps-title { font-size:clamp(2.5rem,6vw,4.5rem); font-weight:800; letter-spacing:-.045em; margin:.2em 0; }
.apps-extra-menu{position:relative;display:inline-flex;align-items:center;transform:scale(1.15)}.apps-extra-menu .icon{color:#f472b6}.apps-extra{margin-top:7rem}.apps-extra-description{font-size:.875rem;color:var(--text-secondary)}
.gradient-text { background:linear-gradient(90deg,#3b82f6,#ec4899); color:transparent; background-clip:text; -webkit-background-clip:text; }
.apps-stats { color:#64748b; font: .85rem ui-monospace,SFMono-Regular,Menlo,monospace; }
.apps-grid { display:grid; grid-template-columns:1fr; gap:1rem; max-width:72rem; margin:2rem auto; }
.app-card { display:flex; align-items:center; gap:.5rem; padding:1rem .6rem; border-radius:.9rem; text-decoration:none; background:var(--surface); box-shadow:0 3px 14px rgb(15 23 42 / .08); border:1px solid transparent; transition:.25s ease; }
.app-card:hover { transform:translateY(-2px); border-color:#c7d2fe; box-shadow:0 12px 30px rgb(99 102 241 / .13); }
.app-card-icon { width:8rem; height:8rem; padding:.75rem; flex:none; filter:drop-shadow(0 2px 2px rgb(0 0 0/.1)); }
.app-card-title { font-size:1.75rem; font-weight:750; margin:0; }
.app-card-subtitle { font-size:1.1rem; line-height:1.25; color:var(--text-secondary); margin:.15rem 0; }
.tags { display:flex; flex-wrap:wrap; gap:.35rem; margin-top:.65rem; }.tag{font-size:.65rem;font-weight:750;color:#111827;background:#e2e8f0;padding:.15rem .45rem;border-radius:.5rem}
@media(min-width:1024px){.apps-grid{grid-template-columns:repeat(2,1fr);gap:2rem 3rem}}
.app-page { max-width:64rem; margin:0 auto; padding:3rem 1.5rem 6rem; }
.app-hero { text-align:center; margin-bottom:7rem; }.app-icon{width:16rem;height:16rem;padding:1rem;filter:drop-shadow(0 1px 2px rgb(0 0 0/.15)) drop-shadow(0 8px 24px rgb(0 0 0/.10))}.app-title{font-size:clamp(3rem,7vw,4.5rem);font-weight:800;margin:.2em 0}.app-subtitle{font-size:clamp(1.5rem,4vw,2.25rem);font-weight:400;color:var(--text-secondary);max-width:42rem;margin:.3em auto 1.2em}.download-options,.app-links{display:flex;flex-wrap:wrap;justify-content:center;gap:1rem;margin-top:1.5rem}.app-links a{font-size:1.1rem;font-weight:650;color:var(--primary);text-underline-offset:4px}.download-badge{transition:.2s}.download-badge:hover{transform:scale(1.05);filter:brightness(1.08)}.availability{text-align:center;color:#64748b;margin:-4rem 0 5rem}.app-media{display:flex;gap:1rem;overflow-x:auto;scroll-snap-type:x mandatory;padding:0 1rem;margin:0 auto 5rem}.app-media-item{flex:0 0 85vw;scroll-snap-align:center;display:flex;justify-content:center;align-items:center}.app-media img,.app-media video{border-radius:.5rem;box-shadow:0 10px 30px rgb(0 0 0/.15);max-height:640px}.press-quotes{max-width:48rem;margin:6rem auto;display:grid;gap:3rem;text-align:center}.quote-mark{font-size:4rem;color:#60a5fa}.related-apps{margin-top:7rem;text-align:center}.related-app-list{display:flex;justify-content:center;gap:2rem}.related-app-list a{width:7rem;text-decoration:none}.related-app-list img{width:4rem;height:4rem;border-radius:1rem;transition:.2s}.related-app-list a:hover img{transform:scale(1.1)}
.blog-shell{max-width:52rem;margin:0 auto;padding:4rem 1.5rem 6rem}.blog-list{display:grid;gap:4rem}.blog-item h2{font-size:clamp(2rem,5vw,2.5rem);margin:0}.blog-item h2 a{text-decoration:none}.blog-item h2 a:hover{box-shadow:inset 0 -4px currentColor}.blog-item .meta{color:#64748b;margin-top:1rem}.blog-post-header{max-width:48rem;margin:0 auto;padding:3rem 1.5rem 0}.blog-post-title{font-size:clamp(3rem,7vw,4rem);line-height:1.08;letter-spacing:-.04em;margin:.2em 0}.blog-post-description{font-size:1.25rem;font-style:italic;opacity:.7}.pagination{display:flex;justify-content:space-between;margin-top:4rem}.pagination a{text-decoration:none;color:var(--text-secondary)}
.contact-page{min-height:calc(100dvh - var(--header-h,0px));display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden;padding:2rem 1.5rem var(--header-h,0px)}.contact-center{text-align:center;width:100%;position:relative;z-index:2}.email-link{font-size:clamp(2rem,5.8vw,100rem);font-weight:800;letter-spacing:-.04em;line-height:1;text-decoration:none;display:block;transform-style:preserve-3d}.email-link .letter{display:inline-block;transform-origin:center 85%;transition:transform .08s cubic-bezier(.34,1.56,.64,1),color .08s,text-shadow .08s}.contact-note{display:flex;justify-content:center;gap:2rem;list-style:none;font-size:.75rem;opacity:.45;padding:0}.orb{position:fixed;border-radius:50%;pointer-events:none;filter:blur(140px);opacity:.055}.orb-blue{width:700px;height:700px;top:-20%;right:-20%;background:#3b82f6}.orb-pink{width:600px;height:600px;bottom:-20%;left:-20%;background:#ec4899}@media(prefers-color-scheme:dark){.orb{opacity:.14}}
.feedback-success{min-height:60vh;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;gap:1.5rem;padding:4rem 1rem}.feedback-success-icon{width:5rem;height:5rem;border-radius:999px;display:flex;align-items:center;justify-content:center;background:color-mix(in srgb,var(--primary) 15%,transparent)}.feedback-success-check{color:#1d4ed8}.feedback-success-title{font-size:1.9rem;font-weight:750;margin:0 0 .5rem}.feedback-success-message{max-width:24rem;margin:auto;color:var(--text-secondary)}.feedback-success-redirect{font-size:.875rem;color:#94a3b8}.attachment-chip{display:flex;align-items:center;gap:.35rem;font-size:.75rem;padding:.35rem .5rem;border-radius:.5rem;background:var(--code-bg);color:var(--text-secondary)}.attachment-name-wrap{display:flex;align-items:center;gap:.3rem;min-width:0;flex:1}.attachment-name{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.attachment-size{color:#94a3b8;flex:none}.attachment-remove{border:0;background:transparent;color:#94a3b8;cursor:pointer;flex:none}.attachment-remove:hover{color:var(--text)}.email-warning{margin-top:.4rem;font-size:.875rem;color:#d97706}.faq-suggestion-link{color:#1d4ed8;text-decoration:none}.faq-suggestion-link:hover{text-decoration:underline}
.feedback-main{max-width:48rem;margin:2rem auto 5rem;padding:0 1.5rem}.feedback-app-icon{visibility:hidden;display:block}.feedback-product-name{font-size:clamp(2.25rem,6vw,3rem);margin-bottom:.4rem}.feedback-title{font-size:clamp(1.5rem,4vw,1.9rem);margin-top:0;margin-bottom:2rem}.feedback-additional-info{font-size:1rem}.feedback-platform-notice{font-size:1.2rem}.feedback-noscript{text-align:center;font-size:1.5rem}.faq-suggestions-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:.5rem}.faq-suggestions-header span{font-weight:650}.faq-suggestions-header button{border:0;background:transparent;color:inherit;cursor:pointer;font-size:1.2rem}.email-label-row{display:flex;align-items:baseline;justify-content:space-between;margin-bottom:.5rem}.email-label{margin-bottom:0}.email-privacy-hint{font-size:.75rem;color:#64748b}.attachments-field{margin-bottom:2rem}.attachment-picker{display:inline-flex;align-items:center;gap:.4rem;font-size:.875rem;color:var(--text-secondary);cursor:pointer}.attachment-picker:hover{color:var(--text)}.attachment-input{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}.feedback-header{text-align:center}.feedback-header #app-icon{width:8rem;height:8rem;margin:0 auto 1rem}.feedback-form{margin-top:2rem}.field{margin-bottom:1.5rem}.field-label{display:block;margin-bottom:.5rem;font-size:.875rem;font-weight:650}.input{display:block;width:100%;font-size:1.05rem;padding:.7rem;background:color-mix(in srgb,var(--surface) 80%,transparent);color:var(--text);border:1px solid var(--border);border-radius:.55rem}.input:focus{outline:2px solid color-mix(in srgb,var(--primary) 35%,transparent);border-color:var(--primary)}.feedback-notice{padding:.8rem;border-radius:.55rem;font-size:.9rem;margin-top:.75rem}.crash-warning{background:#fffbeb;border:1px solid #fcd34d;color:#92400e}.faq-suggestions{background:#eff6ff;border:1px solid #bfdbfe;color:#1e40af}.file-list{display:grid;gap:.4rem;margin-top:.5rem}.feedback-submit{border:0;border-radius:999px;padding:.8rem 2rem;background:#1d4ed8;color:#fff;font-weight:650;cursor:pointer}.feedback-submit:disabled{opacity:.5}.feedback-actions{display:flex;gap:1.25rem;align-items:center}.feedback-fineprint{font-size:.75rem;color:#64748b}
.home-hero{position:relative;overflow:hidden;min-height:calc(100vh - 4.5rem);display:flex;align-items:center;justify-content:center}.home-center{text-align:center;padding:4rem 1.5rem;position:relative;z-index:1}.profile-ring{display:inline-flex;position:relative;border-radius:50%;margin:2rem}.profile-photo{border-radius:50%;display:block;position:relative;z-index:1}.home-title{font-size:clamp(3rem,8vw,4rem);letter-spacing:-.05em;margin:.2em 0;font-weight:800}.home-tagline{font-size:1.5rem;color:var(--text-secondary);letter-spacing:.04em}.home-actions{display:flex;justify-content:center;gap:1.5rem;margin-top:2.5rem}.home-button{display:inline-flex;align-items:center;gap:.4rem;padding:.85rem 2rem;border-radius:999px;color:#fff;text-decoration:none;font-weight:650;box-shadow:0 8px 24px rgb(0 0 0/.12);transition:.2s}.home-button:hover{transform:translateY(-1px)}.home-button-primary{background:#2563eb}.home-button-dark{background:#111827}.nebula-canvas{position:absolute;inset:0;width:100%;height:100%;pointer-events:none;display:none}@media(prefers-color-scheme:dark){.nebula-canvas{display:block}.profile-ring::before{content:"";position:absolute;inset:-3px;border-radius:50%;background:conic-gradient(#3b82f6,#8b5cf6,#ec4899,#8b5cf6,#3b82f6);animation:ringRotate 10s linear infinite}}@media(prefers-reduced-motion:reduce){.nebula-canvas{display:none!important}.profile-ring::before{animation:none!important}}@keyframes ringRotate{to{transform:rotate(360deg)}}
.custom-download-button{width:180px;height:60px;display:flex;align-items:center;justify-content:center;background:#1d4ed8;color:#fff;border-radius:.55rem;text-decoration:none;font-size:1.1rem;font-weight:700}.overflow-menu-wrap{position:relative;display:inline-flex;align-items:center}.overflow-menu-component{position:absolute;inset:0;width:100%;height:100%;opacity:0}.announcement{display:flex;align-items:center;justify-content:center;gap:1rem;max-width:48rem;margin:-2rem auto 6rem;padding:1rem 1.25rem;border:1px solid color-mix(in srgb,var(--primary) 25%,transparent);border-radius:1rem;background:linear-gradient(120deg,color-mix(in srgb,#dbeafe 65%,transparent),color-mix(in srgb,#fce7f3 45%,transparent))}.announcement-button{display:inline-flex;align-items:center;gap:.3rem;padding:.45rem 1rem;border-radius:999px;background:linear-gradient(90deg,#2563eb,#db2777);color:white;text-decoration:none;font-weight:650}
.apps-filter-notice{text-align:center;font-size:.875rem;color:#64748b;margin:0 0 1rem}.apps-filter-notice a{text-decoration:underline;text-underline-offset:3px}
.another-random-app{display:none;justify-content:center}.another-random-app-button{display:inline-flex;align-items:center;gap:.45rem;margin-bottom:1.5rem;padding:.5rem 1rem;border-radius:999px;color:#fff;text-decoration:none;font-weight:650;background:linear-gradient(90deg,#3b82f6,#ec4899);box-shadow:0 2px 8px rgb(0 0 0/.08)}
.app-store-download{position:relative}.share-button{display:none;position:absolute;left:-2rem;top:50%;transform:translateY(-50%);border:0;background:transparent;color:var(--text-secondary);padding:.25rem;cursor:pointer}
.app-media-carousel{position:relative;max-width:64rem;margin:0 auto 5rem}.app-media-carousel .app-media{margin-bottom:0}.media-control{display:none;position:absolute;top:50%;transform:translateY(-50%);z-index:2;width:3rem;height:3rem;border:0;border-radius:999px;background:color-mix(in srgb,var(--surface) 55%,transparent);backdrop-filter:blur(8px);box-shadow:0 3px 14px rgb(0 0 0/.15);color:var(--text);align-items:center;justify-content:center;opacity:0;transition:opacity .2s}.media-prev{left:2rem}.media-next{right:2rem}.app-media-carousel:hover .media-control{opacity:1}
.app-overflow-footer{max-width:48rem;margin:4rem auto 0;padding:0 1.5rem;display:flex;flex-wrap:wrap;justify-content:center;gap:.5rem 1.5rem;font-size:.875rem;color:var(--text-secondary)}.app-overflow-footer a{text-underline-offset:4px}
.app-secondary-nav{position:absolute;inset:0;display:flex;align-items:center;justify-content:space-between;width:100%;max-width:72rem;margin:auto;padding:.75rem 1rem;color:var(--text-secondary)}.app-secondary-identity{display:flex;align-items:center;gap:.75rem;text-decoration:none;flex:none}.app-secondary-identity img{border-radius:.5rem}.app-secondary-identity span{font-size:1.05rem;font-weight:700;color:var(--text)}.app-secondary-links{display:flex;align-items:center;gap:.25rem;min-width:0}.app-secondary-links>a{padding:.65rem .8rem;text-decoration:underline;text-decoration-thickness:3px;text-decoration-color:transparent;text-underline-offset:7px;font-weight:550;white-space:nowrap}.app-get-button{margin-left:1rem;padding:.5rem 1.25rem;border:0;border-radius:999px;background:#1d4ed8;color:#fff!important;text-decoration:none!important;font-weight:700;cursor:pointer}
@media(min-width:768px){.media-control{display:flex}}
@media(max-width:767px){.mobile-nav-only{display:list-item}.desktop-nav-only,.nav-separator{display:none!important}.site-nav{display:block}.site-nav-top{display:flex;justify-content:space-between;align-items:center}.mobile-menu-toggle{display:inline-flex}.site-links-wrap{display:none}.site-nav:has(#menu-toggle:checked) .site-links-wrap{display:block}.site-links{flex-direction:column;align-items:stretch;padding:1.5rem 0;font-size:1.8rem}.site-footer-inner{display:block;text-align:center}.social-links{justify-content:center}.site-footer-quote{display:none}.contact-note,.feedback-actions{flex-direction:column}.app-media-item{flex-basis:85vw}}

/* Migrated bespoke home styles. */
.nebula-canvas {
	position: absolute;
	inset: 0;
	width: 100%;
	height: 100%;
	pointer-events: none;
	display: none;
}

@media (prefers-color-scheme: dark) {
	.nebula-canvas {
		display: block;
		animation: nebulaFadeIn 3s ease-out forwards;
	}
}

@keyframes nebulaFadeIn {
	from { opacity: 0; }
	to   { opacity: 1; }
}

@media (prefers-reduced-motion: reduce) {
	.nebula-canvas { display: none !important; }
}

.profile-ring {
	position: relative;
	display: inline-flex;
	border-radius: 50%;
}

@media (prefers-color-scheme: dark) {
	/* Rotating conic gradient ring using galaxy palette */
	.profile-ring::before {
		content: '';
		position: absolute;
		inset: -3px;
		border-radius: 50%;
		background: conic-gradient(from 0deg, #3b82f6, #8b5cf6, #ec4899, #8b5cf6, #3b82f6);
		animation: ringRotate 10s linear infinite;
	}

	/* Nebula glow applied to the whole composition */
	.profile-ring {
		filter:
			drop-shadow(0 0 14px rgba(59, 130, 246, 0.50))
			drop-shadow(0 0 40px rgba(139, 92, 246, 0.28));
	}
}

@media (prefers-color-scheme: dark) and (prefers-reduced-motion: reduce) {
	.profile-ring::before { animation: none; }
}

@keyframes ringRotate {
	to { transform: rotate(360deg); }
}

.profile-photo {
	position: relative;
	z-index: 1;
	display: block;
	border-radius: 50%;
	transition: transform 0.35s ease;
	/* Edges dissolve into the galaxy/ring rather than hard-cutting */
	mask-image: radial-gradient(circle, black 80%, transparent 100%);
	-webkit-mask-image: radial-gradient(circle, black 80%, transparent 100%);
}

@media (hover: hover) {
	.profile-photo:hover {
		transform: scale(1.03);
	}
}

/*
 * SF Pro Expanded on Apple platforms (macOS/iOS), via ui-sans-serif.
 * font-stretch: expanded activates the 125% width variant of the variable font.
 * On non-Apple platforms it falls back to the system sans-serif, stretched if supported.
 */
.hero-name {
	font-family: ui-sans-serif, -apple-system, system-ui, sans-serif;
	font-stretch: expanded;
}

/* Same typeface as the title — expanded SF Pro Light — weight contrast creates hierarchy */
.hero-tagline {
	font-family: ui-sans-serif, -apple-system, system-ui, sans-serif;
	font-stretch: expanded;
	font-weight: 350;
	letter-spacing: 0.06em;
}

@media (prefers-color-scheme: dark) {
	.hero-name {
		filter:
			drop-shadow(0 0 12px rgba(59, 130, 246, 0.55))
			drop-shadow(0 0 32px rgba(139, 92, 246, 0.30))
			drop-shadow(0 0 60px rgba(236, 72, 153, 0.15));
	}

	.hero-tagline {
		color: rgb(226 232 240 / 0.82); /* slate-200 — brighter than title gradient, clearly secondary */
		text-shadow: 0 0 28px rgba(139, 92, 246, 0.28);
	}
}

/* --- Liquid glass buttons (dark mode only) --- */
.glass-btn {
	position: relative;
	overflow: hidden;
	color: white;
	transition: background 0.25s ease, box-shadow 0.25s ease, transform 0.2s ease, border-color 0.25s ease;
}

/* Light mode: original solid styles */
.glass-btn-primary {
	background: rgba(37, 99, 235, 0.9); /* primary-600/90 */
	border: 1px solid rgba(37, 99, 235, 0.3);
}

.glass-btn-dark {
	background: #111827; /* gray-900 */
	border: 1px solid transparent;
}

@media (hover: hover) {
	.glass-btn-primary:hover {
		background: #1d4ed8; /* primary-800 */
		border-color: #1d4ed8;
	}

	.glass-btn-dark:hover {
		background: #374151; /* gray-700 */
	}
}

@media (prefers-color-scheme: dark) {
	.glass-btn {
		backdrop-filter: blur(20px) saturate(180%);
		-webkit-backdrop-filter: blur(20px) saturate(180%);
	}

	/* Specular highlight — glossy cap on top half */
	.glass-btn::before {
		content: '';
		position: absolute;
		inset: 0;
		background: linear-gradient(
			175deg,
			rgba(255, 255, 255, 0.28) 0%,
			rgba(255, 255, 255, 0.06) 40%,
			transparent 70%
		);
		pointer-events: none;
		border-radius: inherit;
	}

	.glass-btn-primary {
		background: rgba(59, 130, 246, 0.22);
		border: 1px solid rgba(99, 160, 255, 0.45);
		box-shadow:
			inset 0 1.5px 0 rgba(255, 255, 255, 0.40),
			inset 0 -1px 0 rgba(0, 0, 0, 0.10),
			0 4px 24px rgba(59, 130, 246, 0.25),
			0 1px 4px rgba(0, 0, 0, 0.15);
	}

	.glass-btn-dark {
		background: rgba(10, 15, 30, 0.40);
		border: 1px solid rgba(255, 255, 255, 0.16);
		box-shadow:
			inset 0 1.5px 0 rgba(255, 255, 255, 0.25),
			inset 0 -1px 0 rgba(0, 0, 0, 0.15),
			0 4px 20px rgba(0, 0, 0, 0.30),
			0 1px 4px rgba(0, 0, 0, 0.20);
	}
}

@media (prefers-color-scheme: dark) and (hover: hover) {
	.glass-btn:hover {
		transform: translateY(-1px);
	}

	.glass-btn-primary:hover {
		background: rgba(59, 130, 246, 0.32);
		border-color: rgba(120, 180, 255, 0.60);
		box-shadow:
			inset 0 1.5px 0 rgba(255, 255, 255, 0.50),
			inset 0 -1px 0 rgba(0, 0, 0, 0.10),
			0 8px 32px rgba(59, 130, 246, 0.35),
			0 2px 6px rgba(0, 0, 0, 0.15);
	}

	.glass-btn-dark:hover {
		background: rgba(10, 15, 30, 0.55);
		border-color: rgba(255, 255, 255, 0.26);
		box-shadow:
			inset 0 1.5px 0 rgba(255, 255, 255, 0.35),
			inset 0 -1px 0 rgba(0, 0, 0, 0.15),
			0 8px 28px rgba(0, 0, 0, 0.40),
			0 2px 6px rgba(0, 0, 0, 0.20);
	}
}

.background-animate {
	background-size: 400%;
	animation: AnimationName 4s ease infinite;
}

@keyframes AnimationName {
	0%,
	100% {
		background-position: 0% 50%;
	}
	50% {
		background-position: 100% 50%;
	}
}

/* Migrated bespoke contact styles. */
/* Use CSS custom property set by JS for exact header height */
#contact-section {
	min-height: calc(100dvh - var(--header-h, 0px));
	/* Padding-bottom shifts flex center upward by header-h/2, landing on true viewport center */
	padding-bottom: var(--header-h, 0px);
}

.orb {
	position: fixed;
	border-radius: 50%;
	pointer-events: none;
	z-index: 0;
	filter: blur(140px);
}

.orb-blue {
	width: 700px;
	height: 700px;
	top: -20%;
	right: -20%;
	background: #3b82f6;
	opacity: 0.055;
	animation: drift-a 18s ease-in-out infinite alternate;
}

.orb-pink {
	width: 600px;
	height: 600px;
	bottom: -20%;
	left: -20%;
	background: #ec4899;
	opacity: 0.055;
	animation: drift-b 13s ease-in-out infinite alternate;
}

@media (prefers-color-scheme: dark) {
	.orb-blue,
	.orb-pink {
		opacity: 0.14;
	}
}

/* Outline helps rainbow colors pop against light backgrounds */
.email-link {
	-webkit-text-stroke: 1px rgba(0, 0, 0, 0.18);
}

@media (prefers-color-scheme: dark) {
	.email-link {
		-webkit-text-stroke: 0;
	}
}

@keyframes drift-a {
	to { transform: translate(60px, 50px) scale(1.1); }
}

@keyframes drift-b {
	to { transform: translate(-50px, -40px) scale(1.08); }
}

@keyframes reveal {
	from {
		opacity: 0;
		transform: translateY(20px);
		filter: blur(8px);
	}
	to {
		opacity: 1;
		transform: translateY(0);
		filter: blur(0);
	}
}

.reveal {
	animation: reveal 0.8s cubic-bezier(0.22, 1, 0.36, 1) both;
	animation-delay: var(--delay, 0ms);
}

.tilt-wrap {
	perspective: 800px;
	display: block;
}

.email-link {
	font-size: clamp(2rem, 10vw, 100rem);
	font-stretch: expanded;
	color: inherit;
	text-decoration: none;
	display: block;
	transform-style: preserve-3d;
}

@media (min-width: 640px) {
	.email-link {
		font-size: clamp(2rem, 5.8vw, 100rem);
	}
}

.nobr {
	white-space: nowrap;
	display: inline-block;
}

.letter {
	display: inline-block;
	transform-origin: center 85%;
	/* Fast spring-like enter; slow natural return using CSS linear() spring simulation */
	transition:
		transform 0.08s cubic-bezier(0.34, 1.56, 0.64, 1),
		color 0.08s ease,
		text-shadow 0.08s ease;
	will-change: transform;
}

.letter.leaving {
	transition:
		transform 0.6s linear(0, 0.5 7.7%, 0.9 14.4%, 1.04 19.4%, 1.06 23.7%, 1.02 30%, 1 35%, 0.99 45%, 1),
		color 0.5s ease,
		text-shadow 0.5s ease;
}

@media (prefers-reduced-motion: reduce) {
	.orb { animation: none; }
	.reveal { animation: none; opacity: 1; filter: none; }
	.letter, .letter.leaving { transition: none; }
}

/* Migrated global custom CSS after removal of Tailwind directives. */
/* Improvements over the Tailwind style */
kbd {
	font-family: inherit !important;
	font-size: 0.8em !important;
	background-color: #f0f2f5 !important;
	color: #2d3748 !important;
	border: 1px solid #c4cad4 !important;
	border-bottom-width: 3px !important;
	border-radius: 5px !important;
	padding: 0.1em 0.45em !important;
	margin-inline: 0.15em !important;
}

@media (prefers-color-scheme: dark) {
	kbd {
		background-color: #252d3d !important;
		color: #c9d1e0 !important;
		border-color: #3d4a5c !important;
		border-bottom-color: #111827 !important;
	}
}

/* Keyboard combo separator inserted between adjacent <kbd> elements */
.kbd-sep {
	font-size: 0.6em;
	font-weight: 600;
	color: #9ca3af;
	user-select: none;
	vertical-align: middle;
}

.footnotes {
	margin-top: 100px !important;
}

/*
Let tables that are wider than the content scroll horizontally instead of making the page scroll. The rows are put in an inner table so the table still fills the full width.

Limitation: Tables with a header or footer are excluded, as each row group would become its own table and the columns would not line up.
*/
.prose table:not(:has(> thead, > tfoot)) {
	display: block;
	overflow-x: auto;

	> tbody {
		display: table;
		width: 100%;
	}
}

/* Animate details open/close via ::details-content (requires interpolate-size support) */
@supports (interpolate-size: allow-keywords) {
	:root {
		interpolate-size: allow-keywords;
	}

	.faq-collapsible details::details-content {
		overflow: hidden;
		height: 0;
		transition: height 0.25s ease;
	}

	.faq-collapsible details[open]::details-content {
		height: auto;
	}
}

/* FAQ collapsible sections */
.faq-collapsible {
	details {
		background-color: rgb(0 0 0 / 0.015);
		border-radius: 0.75rem;
		padding: 0;

		& + details {
			margin-top: 0.75rem;
		}

		&[open] > summary {
			box-shadow: inset 0 -1px 0 rgb(0 0 0 / 0.05);
		}
	}

	summary {
		display: flex;
		align-items: center;
		padding: 0.75rem 1rem;
		font-weight: 600;
		font-size: inherit;
		cursor: pointer;
		list-style: none;
		user-select: none;
		transition: background-color 0.15s;
		border-radius: 0.75rem;
		background-color: rgb(0 0 0 / 0.015);

		&:hover {
			background-color: rgb(0 0 0 / 0.04);
		}

		&::-webkit-details-marker {
			display: none;
		}

		a {
			font-size: inherit;
			font-weight: inherit;
		}
	}

	.faq-summary-text {
		flex: 1;
		min-width: 0;
	}

	.faq-chevron {
		display: inline-flex;
		align-items: center;
		margin-left: 0.5rem;
		flex-shrink: 0;

		&::after {
			content: '';
			width: 0.5rem;
			height: 0.5rem;
			border-right: 2px solid #9ca3af;
			border-bottom: 2px solid #9ca3af;
			transform: rotate(-45deg);
			transition: transform 0.2s;
		}
	}

	details[open] .faq-chevron::after {
		transform: rotate(45deg);
	}

	.faq-more-link {
		display: block;
		margin-top: 0.75rem;
		padding: 0.75rem 1rem;
		border-radius: 0.75rem;
		font-size: inherit;
		color: rgb(0 0 0 / 0.75);
		text-decoration: underline;
		text-underline-offset: 4px;
		text-decoration-color: var(--color-primary-500);
		text-decoration-thickness: 2px;
		transition: color 0.15s, text-decoration-color 0.15s;

		&::after {
			content: ' →';
		}

		&:hover {
			color: rgb(0 0 0);
			text-decoration-color: var(--color-primary-700);
		}
	}

	.faq-content {
		padding: 0.75rem 1rem;

		> :first-child {
			margin-top: 0;
		}

		> :last-child {
			margin-bottom: 0;
		}

		p + p {
			margin-top: 0.5rem;
		}

		ul, ol {
			padding-left: 1.25rem;
			margin-top: 0.25rem;
			margin-bottom: 0.25rem;
		}

		li + li {
			margin-top: 0.125rem;
		}

		li p {
			margin: 0;
		}
	}
}

/* On small screens: full-width, no rounding, tighter gaps that read as dividers */
@media (max-width: 639px) {
	.faq-collapsible {
		details {
			border-radius: 0;
			margin-left: -1.5rem;
			margin-right: -1.5rem;

			& + details {
				margin-top: 0.2rem;
			}
		}

		summary {
			border-radius: 0;
		}

		.faq-more-link {
			border-radius: 0;
			margin-left: -1.5rem;
			margin-right: -1.5rem;
			margin-top: 0.2rem;
		}
	}
}

@media (prefers-color-scheme: dark) {
	.faq-collapsible {
		details {
			background-color: rgb(255 255 255 / 0.025);

			&[open] > summary {
				box-shadow: inset 0 -1px 0 rgb(255 255 255 / 0.07);
			}
		}

		summary {
			background-color: rgb(255 255 255 / 0.035);
		}

		summary:hover {
			background-color: rgb(255 255 255 / 0.06);
		}

		.faq-more-link {
			color: rgb(255 255 255 / 0.9);
			text-decoration-color: var(--color-primary-400);

			&:hover {
				color: rgb(255 255 255);
				text-decoration-color: var(--color-primary-300);
			}
		}

		.faq-chevron::after {
			border-color: #6b7280;
		}
	}
}

.scrollbar-hide::-webkit-scrollbar {
	display: none;
}

.scrollbar-hide {
	-ms-overflow-style: none;
	scrollbar-width: none;
}

.markdown-alert {
	padding: 0.5rem 1rem;
	margin: 1rem 0;
	border-left: 0.25rem solid;
	border-radius: 0.5rem;

	> * {
		margin-top: 0;
		margin-bottom: 0;
	}

	> * + * {
		margin-top: 0.25rem;
	}

	a {
		text-decoration-color: var(--alert-color) !important;
	}
}

.markdown-alert-title {
	display: flex;
	align-items: center;
	gap: 0.5rem;
	font-weight: 600;

	> svg {
		width: 1rem;
		height: 1rem;
		fill: currentColor;
	}
}

.markdown-alert-note {
	--alert-color: #60a5fa;
	border-color: color-mix(in srgb, var(--alert-color) 50%, transparent);
	background-color: #f8faff;

	.markdown-alert-title {
		color: #38bdf8;
	}
}

.markdown-alert-tip {
	--alert-color: #6ee7b7;
	border-color: color-mix(in srgb, var(--alert-color) 50%, transparent);
	background-color: #f8fdf9;

	.markdown-alert-title {
		color: #34d399;
	}
}

.markdown-alert-important {
	--alert-color: #c084fc;
	border-color: color-mix(in srgb, var(--alert-color) 50%, transparent);
	background-color: #fdf8ff;

	.markdown-alert-title {
		color: #a78bfa;
	}
}

.markdown-alert-warning {
	--alert-color: #fbbf24;
	border-color: color-mix(in srgb, var(--alert-color) 50%, transparent);
	background-color: #fffdf5;

	.markdown-alert-title {
		color: #f59e0b;
	}
}

.markdown-alert-caution {
	--alert-color: #fb7185;
	border-color: color-mix(in srgb, var(--alert-color) 50%, transparent);
	background-color: #fef8f8;

	.markdown-alert-title {
		color: #f43f5e;
	}
}

@media (prefers-color-scheme: dark) {
	.markdown-alert-note {
		background-color: #0f172a;
	}

	.markdown-alert-tip {
		background-color: #0a1a17;
	}

	.markdown-alert-important {
		background-color: #1a0a2e;
	}

	.markdown-alert-warning {
		background-color: #1a1408;
	}

	.markdown-alert-caution {
		background-color: #1f0a0a;
	}
}


/* Shared heading-anchor positioning from the Astro base layout. */
[data-heading-anchors] :is(h2, h3, h4)[id],
[data-heading-anchors] details[id] > summary {
	position: relative;
}
[data-heading-anchors] .heading-anchor {
	position: absolute;
	left: -28px;
	top: 0;
	bottom: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	width: 24px;
	opacity: 0;
	color: var(--color-gray-400);
	transition: opacity 0.15s ease, color 0.15s ease;
	pointer-events: none;
	transform: translateZ(0);
}
[data-heading-anchors] .heading-anchor::before {
	content: '';
	position: absolute;
	inset: -8px;
}
[data-heading-anchors] :is(h2, h3, h4)[id]:hover > .heading-anchor,
[data-heading-anchors] details[id] > summary:hover > .heading-anchor {
	opacity: 0.6;
	pointer-events: auto;
}
[data-heading-anchors] .heading-anchor:hover {
	opacity: 1 !important;
	color: var(--color-primary-500);
}
[data-heading-anchors] [data-anchor-state="copied"] > .heading-anchor {
	opacity: 1 !important;
	color: var(--color-primary-500) !important;
	pointer-events: none;
}
[data-heading-anchors] [data-anchor-state="hidden"] > .heading-anchor {
	opacity: 0 !important;
	pointer-events: none;
}

"""#
}
