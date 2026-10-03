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
body { margin: 0; color: var(--text); background: var(--surface); overflow-x: clip; -webkit-font-smoothing: antialiased; }
a { color: inherit; }
img, video { max-width: 100%; height: auto; }
button, input, textarea, select { font: inherit; }
.site-header { position: sticky; top: 0; z-index: 40; border-bottom: 1px solid var(--border); background: color-mix(in srgb, var(--surface) 92%, transparent); backdrop-filter: blur(14px); }
.site-nav { max-width: 72rem; margin: 0 auto; min-height: 4.5rem; padding: .75rem 1rem; display: flex; align-items: center; justify-content: space-between; gap: 1rem; }
.site-brand { font-size: 1.4rem; font-weight: 800; text-decoration: none; color: var(--text); white-space: nowrap; }
.site-links { display: flex; align-items: center; gap: .25rem; list-style: none; padding: 0; margin: 0; }
.site-links a { display: inline-flex; align-items: center; padding: .65rem .85rem; border-radius: .55rem; text-decoration: none; color: var(--text-secondary); font-weight: 550; }
.site-links a:hover, .site-links a[aria-current="page"] { color: var(--text); background: color-mix(in srgb, var(--text) 6%, transparent); }
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
.prose { font-size: 1.125rem; line-height: 1.75; overflow-wrap:anywhere; }
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
.apps-title { font-size:clamp(2.5rem,6vw,4.5rem); font-weight:800; letter-spacing:-.045em; margin:.2em 0; }
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
.feedback-main{max-width:48rem;margin:2rem auto 5rem;padding:0 1.5rem}.feedback-header{text-align:center}.feedback-header #app-icon{width:8rem;height:8rem;margin:0 auto 1rem}.feedback-form{margin-top:2rem}.field{margin-bottom:1.5rem}.field-label{display:block;margin-bottom:.5rem;font-size:.875rem;font-weight:650}.input{display:block;width:100%;font-size:1.05rem;padding:.7rem;background:color-mix(in srgb,var(--surface) 80%,transparent);color:var(--text);border:1px solid var(--border);border-radius:.55rem}.input:focus{outline:2px solid color-mix(in srgb,var(--primary) 35%,transparent);border-color:var(--primary)}.feedback-notice{padding:.8rem;border-radius:.55rem;font-size:.9rem;margin-top:.75rem}.crash-warning{background:#fffbeb;border:1px solid #fcd34d;color:#92400e}.faq-suggestions{background:#eff6ff;border:1px solid #bfdbfe;color:#1e40af}.file-list{display:grid;gap:.4rem;margin-top:.5rem}.feedback-submit{border:0;border-radius:999px;padding:.8rem 2rem;background:#1d4ed8;color:#fff;font-weight:650;cursor:pointer}.feedback-submit:disabled{opacity:.5}.feedback-actions{display:flex;gap:1.25rem;align-items:center}.feedback-fineprint{font-size:.75rem;color:#64748b}
.home-hero{position:relative;overflow:hidden;min-height:calc(100vh - 4.5rem);display:flex;align-items:center;justify-content:center}.home-center{text-align:center;padding:4rem 1.5rem;position:relative;z-index:1}.profile-ring{display:inline-flex;position:relative;border-radius:50%;margin:2rem}.profile-photo{border-radius:50%;display:block;position:relative;z-index:1}.home-title{font-size:clamp(3rem,8vw,4rem);letter-spacing:-.05em;margin:.2em 0;font-weight:800}.home-tagline{font-size:1.5rem;color:var(--text-secondary);letter-spacing:.04em}.home-actions{display:flex;justify-content:center;gap:1.5rem;margin-top:2.5rem}.home-button{display:inline-flex;align-items:center;gap:.4rem;padding:.85rem 2rem;border-radius:999px;color:#fff;text-decoration:none;font-weight:650;box-shadow:0 8px 24px rgb(0 0 0/.12);transition:.2s}.home-button:hover{transform:translateY(-1px)}.home-button-primary{background:#2563eb}.home-button-dark{background:#111827}.nebula-canvas{position:absolute;inset:0;width:100%;height:100%;pointer-events:none;display:none}@media(prefers-color-scheme:dark){.nebula-canvas{display:block}.profile-ring::before{content:"";position:absolute;inset:-3px;border-radius:50%;background:conic-gradient(#3b82f6,#8b5cf6,#ec4899,#8b5cf6,#3b82f6);animation:ringRotate 10s linear infinite}}@media(prefers-reduced-motion:reduce){.nebula-canvas{display:none!important}.profile-ring::before{animation:none!important}}@keyframes ringRotate{to{transform:rotate(360deg)}}
.custom-download-button{width:180px;height:60px;display:flex;align-items:center;justify-content:center;background:#1d4ed8;color:#fff;border-radius:.55rem;text-decoration:none;font-size:1.1rem;font-weight:700}.overflow-menu-wrap{position:relative;display:inline-flex;align-items:center}.overflow-menu-component{position:absolute;inset:0;width:100%;height:100%;opacity:0}.announcement{display:flex;align-items:center;justify-content:center;gap:1rem;max-width:48rem;margin:-2rem auto 6rem;padding:1rem 1.25rem;border:1px solid color-mix(in srgb,var(--primary) 25%,transparent);border-radius:1rem;background:linear-gradient(120deg,color-mix(in srgb,#dbeafe 65%,transparent),color-mix(in srgb,#fce7f3 45%,transparent))}.announcement-button{display:inline-flex;align-items:center;gap:.3rem;padding:.45rem 1rem;border-radius:999px;background:linear-gradient(90deg,#2563eb,#db2777);color:white;text-decoration:none;font-weight:650}
@media(max-width:767px){.site-nav{display:block}.site-nav-top{display:flex;justify-content:space-between;align-items:center}.mobile-menu-toggle{display:inline-flex}.site-links-wrap{display:none}.site-nav:has(#menu-toggle:checked) .site-links-wrap{display:block}.site-links{flex-direction:column;align-items:stretch;padding:1.5rem 0;font-size:1.8rem}.site-footer-inner{display:block;text-align:center}.social-links{justify-content:center}.site-footer-quote{display:none}.contact-note,.feedback-actions{flex-direction:column}.app-media-item{flex-basis:85vw}}
"""#
}
