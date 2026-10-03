/**
Builds the items of a feed with loops and conditions.
*/
@resultBuilder
public enum ItemBuilder {
	public static func buildExpression(_ item: Item) -> [Item] {
		[item]
	}

	public static func buildExpression(_ items: [Item]) -> [Item] {
		items
	}

	public static func buildBlock(_ components: [Item]...) -> [Item] {
		components.flatMap(\.self)
	}

	public static func buildArray(_ components: [[Item]]) -> [Item] {
		components.flatMap(\.self)
	}

	public static func buildOptional(_ component: [Item]?) -> [Item] {
		component ?? []
	}

	public static func buildEither(first component: [Item]) -> [Item] {
		component
	}

	public static func buildEither(second component: [Item]) -> [Item] {
		component
	}
}
