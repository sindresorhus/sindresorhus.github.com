import SiteKit
@testable import Website

// Type-check against the testable Website module. The invalid branch must reject another model's key.
#if INVALID_FORMATTING_KEY
var keys = App.formattingKeys
keys.append(BlogPost.Frontmatter.CodingKeys.tags)
#else
func formattingKeys<Document: ContentDocument>(of type: Document.Type) -> [Document.Frontmatter.CodingKeys] {
	type.formattingKeys
}

var keys = App.formattingKeys
keys.append(App.Frontmatter.CodingKeys.title)
let pageKeys: [MarkdownPage.Frontmatter.CodingKeys] = MarkdownPage.formattingKeys
let guideKeys: [Guide.Frontmatter.CodingKeys] = formattingKeys(of: Guide.self)
#endif
