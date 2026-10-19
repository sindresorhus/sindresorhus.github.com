import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/**
Implementation of `@Frontmatter`, which makes a struct decode strictly from SOML frontmatter.

It generates `CodingKeys` (renamed with `@Key`), an `init(from:)` that uses the default value of a property when its key is missing, and the `Frontmatter` conformance.

A property with a property wrapper, like `@NonEmpty var description: String?`, decodes the wrapper of the non-optional type, like `NonEmpty<String>`, and initializes the property with its wrapped value. So an optional property can be missing, like any other.

The type of a stored property comes from its type annotation, from an empty initializer that names the type (`[String]()`, `[String: Int]()`, `OrderedMapping<URL>()`), or from a literal default value: `false` is a `Bool`, `"text"` is a `String`, `1` is an `Int`, and `1.5` is a `Double`.

Limitations: A property inside an `#if` block is an error. Every attribute of a property without arguments, other than `@Key`, is taken to be a property wrapper that is generic over its wrapped value, like `NonEmpty<Value>`, written without generic arguments, and an attribute with arguments, other than `@Key`, is an error. Other default values need a type annotation, because macros cannot infer types. This includes string literals with interpolation, and literals that should be another type, like `var scale: Float = 1`.
*/
public enum FrontmatterMacro: MemberMacro, ExtensionMacro {
	struct Property {
		let name: TokenSyntax
		let key: ExprSyntax?
		let wrapper: TypeSyntax?
		let type: TypeSyntax
		let defaultValue: ExprSyntax?

		/**
		The wrapped type of `T?` or `Optional<T>`, which decodes with `decodeIfPresent`.
		*/
		var optionalWrappedType: TypeSyntax? {
			if let optional = type.as(OptionalTypeSyntax.self) {
				return optional.wrappedType
			}

			if
				let identifier = type.as(IdentifierTypeSyntax.self),
				identifier.name.text == "Optional",
				let argument = identifier.genericArgumentClause?.arguments.first?.argument.as(TypeSyntax.self)
			{
				return argument
			}

			return nil
		}

		/**
		The statement of `init(from:)` that decodes the property. An optional property, or a property with a default value, is decoded with `decodeIfPresent`, so its key can be missing.
		*/
		var decodingStatement: ExprSyntax {
			let valueType = optionalWrappedType ?? type
			let decodedType: TypeSyntax = wrapper.map { "\($0)<\(valueType)>" } ?? valueType

			guard optionalWrappedType != nil || defaultValue != nil else {
				let unwrap = wrapper == nil ? "" : ".wrappedValue"
				return "self.\(name) = try container.decode(\(decodedType).self, forKey: .\(name))\(raw: unwrap)"
			}

			let unwrap = wrapper == nil ? "" : "?.wrappedValue"
			let decode: ExprSyntax = "try container.decodeIfPresent(\(decodedType).self, forKey: .\(name))\(raw: unwrap)"
			return defaultValue.map { "self.\(name) = \(decode) ?? \($0)" } ?? "self.\(name) = \(decode)"
		}
	}

	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard declaration.is(StructDeclSyntax.self) else {
			throw MacroExpansionErrorMessage("'@Frontmatter' can only be applied to a struct")
		}

		let properties = try storedProperties(of: declaration)

		// A `CodingKeys` enum without cases cannot have the raw type that `@Key` needs.
		guard !properties.isEmpty else {
			throw MacroExpansionErrorMessage("'@Frontmatter' requires at least one stored property")
		}

		let access = declaration.modifiers.accessModifierForGeneratedMembers

		let codingKeys = try EnumDeclSyntax("enum CodingKeys: Swift.String, Swift.CodingKey") {
			for property in properties {
				if let key = property.key {
					DeclSyntax("case \(property.name) = \(key)")
				} else {
					DeclSyntax("case \(property.name)")
				}
			}
		}

		let initializer = try InitializerDeclSyntax("\(access)init(from decoder: any Swift.Decoder) throws") {
			DeclSyntax("let container = try decoder.container(keyedBy: CodingKeys.self)")

			for property in properties {
				property.decodingStatement
			}
		}

		return [DeclSyntax(codingKeys), DeclSyntax(initializer)]
	}

	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		// The member role reports errors, so they are not reported twice.
		guard
			declaration.is(StructDeclSyntax.self),
			!protocols.isEmpty
		else {
			return []
		}

		return [try ExtensionDeclSyntax("extension \(type.trimmed): SiteKit.Frontmatter {}")]
	}

	private static func storedProperties(of declaration: some DeclGroupSyntax) throws -> [Property] {
		var properties = [Property]()
		var diagnostics = conditionalDiagnostics(in: declaration.memberBlock.members.map(\.decl))

		for member in declaration.memberBlock.members {
			guard
				let variable = member.decl.as(VariableDeclSyntax.self),
				variable.isStoredInstanceProperty
			else {
				continue
			}

			// A property wrapper is written without arguments, so the type of the wrapper is the name alone.
			var attributeWithArguments: AttributeSyntax?

			for element in variable.attributes {
				guard
					case .attribute(let attribute) = element,
					attribute.attributeName.trimmedDescription != "Key",
					attribute.arguments != nil
				else {
					continue
				}

				attributeWithArguments = attribute
				break
			}

			if let attributeWithArguments {
				diagnostics.append(Diagnostic(node: attributeWithArguments, message: MacroExpansionErrorMessage("'@Frontmatter' supports only '@Key' and a property wrapper without arguments, like '@NonEmpty', got '\(attributeWithArguments.trimmedDescription)'.")))
				continue
			}

			let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
			let key = variable.attributes.keyArgument

			if variable.bindings.count > 1 {
				diagnostics.append(Diagnostic(node: variable, message: MacroExpansionErrorMessage("'@Frontmatter' requires one property per declaration")))
				continue
			}

			guard
				let binding = variable.bindings.first,
				let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
			else {
				continue
			}

			if
				isLet,
				binding.initializer != nil
			{
				diagnostics.append(Diagnostic(node: binding, message: MacroExpansionErrorMessage("A property with a default value must be a 'var', so it can be decoded")))
				continue
			}

			guard let type = binding.typeAnnotation?.type ?? binding.initializer?.value.inferredType else {
				diagnostics.append(Diagnostic(node: binding.pattern, message: MacroExpansionErrorMessage("'@Frontmatter' requires a type annotation, a literal default value like 'false', or an empty initializer like '[String]()', because macros cannot infer other types")))
				continue
			}

			properties.append(Property(name: name.trimmed, key: key, wrapper: variable.attributes.propertyWrapper, type: type.trimmed, defaultValue: binding.initializer?.value.trimmed))
		}

		guard diagnostics.isEmpty else {
			throw DiagnosticsError(diagnostics: diagnostics)
		}

		return properties
	}

	/**
	The mistakes of the properties inside an `#if`, which are not members of the struct, so the macro would leave them out and they would keep their default for every file. Blocks inside blocks are checked too.
	*/
	private static func conditionalDiagnostics(in declarations: [DeclSyntax]) -> [Diagnostic] {
		var diagnostics = [Diagnostic]()

		for declaration in declarations {
			guard let conditional = declaration.as(IfConfigDeclSyntax.self) else {
				continue
			}

			for clause in conditional.clauses {
				guard case .decls(let members) = clause.elements else {
					continue
				}

				for member in members {
					guard
						let variable = member.decl.as(VariableDeclSyntax.self),
						variable.isStoredInstanceProperty
					else {
						continue
					}

					diagnostics.append(Diagnostic(node: variable, message: MacroExpansionErrorMessage("A property in an '#if' block cannot be decoded, so '@Frontmatter' does not support it. Move it out of the conditional block.")))
				}

				diagnostics += conditionalDiagnostics(in: members.map(\.decl))
			}
		}

		return diagnostics
	}
}

/**
Implementation of `@Key("name")`, which marks the SOML key of a `@Frontmatter` property. It generates nothing.
*/
public enum KeyMacro: PeerMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		[]
	}
}

extension ExprSyntax {
	/**
	The type of a default value that the macro can know without type checking: a literal or an empty initializer.
	*/
	fileprivate var inferredType: TypeSyntax? {
		typeOfLiteral ?? typeOfEmptyInitializer
	}

	/**
	The default type of a Boolean, string (without interpolation), integer, or float literal, also with a leading minus, like `Int` for `-1`.
	*/
	private var typeOfLiteral: TypeSyntax? {
		if let prefix = self.as(PrefixOperatorExprSyntax.self) {
			guard
				prefix.operator.text == "-",
				prefix.expression.is(IntegerLiteralExprSyntax.self) || prefix.expression.is(FloatLiteralExprSyntax.self)
			else {
				return nil
			}

			return prefix.expression.typeOfLiteral
		}

		if self.is(BooleanLiteralExprSyntax.self) {
			return "Bool"
		}

		if self.is(IntegerLiteralExprSyntax.self) {
			return "Int"
		}

		if self.is(FloatLiteralExprSyntax.self) {
			return "Double"
		}

		if
			let string = self.as(StringLiteralExprSyntax.self),
			string.segments.allSatisfy({ $0.is(StringSegmentSyntax.self) })
		{
			return "String"
		}

		return nil
	}

	/**
	The type that an empty initializer names, like `[String]` for `[String]()`, `[String: Int]` for `[String: Int]()`, or `OrderedMapping<URL>` for `OrderedMapping<URL>()`.
	*/
	private var typeOfEmptyInitializer: TypeSyntax? {
		guard
			let call = self.as(FunctionCallExprSyntax.self),
			call.arguments.isEmpty,
			call.trailingClosure == nil
		else {
			return nil
		}

		let calledExpression = call.calledExpression

		if
			let array = calledExpression.as(ArrayExprSyntax.self),
			array.elements.count == 1,
			let element = array.elements.first
		{
			return TypeSyntax(stringLiteral: "[\(element.expression.trimmedDescription)]")
		}

		if
			let dictionary = calledExpression.as(DictionaryExprSyntax.self),
			case .elements(let elements) = dictionary.content,
			elements.count == 1,
			let element = elements.first
		{
			return TypeSyntax(stringLiteral: "[\(element.key.trimmedDescription): \(element.value.trimmedDescription)]")
		}

		if calledExpression.is(DeclReferenceExprSyntax.self) || calledExpression.is(GenericSpecializationExprSyntax.self) || calledExpression.is(MemberAccessExprSyntax.self) {
			return TypeSyntax(stringLiteral: calledExpression.trimmedDescription)
		}

		return nil
	}
}

extension AttributeListSyntax {
	/**
	The string literal of a `@Key("name")` attribute.
	*/
	fileprivate var keyArgument: ExprSyntax? {
		for element in self {
			guard
				case .attribute(let attribute) = element,
				attribute.attributeName.trimmedDescription == "Key",
				let argument = attribute.arguments?.as(LabeledExprListSyntax.self)?.first?.expression
			else {
				continue
			}

			return argument.trimmed
		}

		return nil
	}

	/**
	The type of the property wrapper: the first attribute that is not `@Key`, like `NonEmpty` for `@NonEmpty`.
	*/
	fileprivate var propertyWrapper: TypeSyntax? {
		for element in self {
			guard
				case .attribute(let attribute) = element,
				attribute.attributeName.trimmedDescription != "Key"
			else {
				continue
			}

			return attribute.attributeName.trimmed
		}

		return nil
	}
}

extension DeclModifierListSyntax {
	/**
	`public` for public types, so clients can use the generated initializer.
	*/
	fileprivate var accessModifierForGeneratedMembers: DeclModifierSyntax? {
		for modifier in self {
			switch modifier.name.tokenKind {
			case .keyword(.public), .keyword(.open):
				return DeclModifierSyntax(name: .keyword(.public), trailingTrivia: .space)
			case .keyword(.package):
				return DeclModifierSyntax(name: .keyword(.package), trailingTrivia: .space)
			default:
				continue
			}
		}

		return nil
	}
}

extension VariableDeclSyntax {
	fileprivate var isStoredInstanceProperty: Bool {
		guard !modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class) }) else {
			return false
		}

		return bindings.allSatisfy { binding in
			switch binding.accessorBlock?.accessors {
			case .none:
				true
			case .getter:
				false
			case .accessors(let accessors):
				accessors.allSatisfy { $0.accessorSpecifier.tokenKind == .keyword(.willSet) || $0.accessorSpecifier.tokenKind == .keyword(.didSet) }
			}
		}
	}
}
