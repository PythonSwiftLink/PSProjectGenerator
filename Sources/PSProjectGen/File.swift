//
//  File.swift
//  
//
//  Created by CodeBuilder on 10/10/2023.
//

import Foundation
import SwiftSyntax
//import SwiftSyntaxParser
import SwiftParser
import SwiftSyntaxBuilder

private func addPythonSwiftImport(_ module_name: String) -> ExprSyntax {
//	let memberAccessExpr = MemberAccessExprSyntax(dot: .periodToken(), name: .identifier("init"))
//	let tuple: TupleExprElementList =  .init([
//		.init(label: .identifier("name"), expression: IdentifierExprSyntax(stringLiteral: "corebluetooth")),
//		.init(label: "name", expression: .init(stringLiteral: "PyInit_corebluetooth"))
//	])
	//return FunctionCallExprSyntax(calledExpression: memberAccessExpr, argumentList: tuple)
	return .init(ExprSyntax(stringLiteral: ".init(name: \"\(module_name)\", module: PyInit_\(module_name))"))
		.with(\.leadingTrivia ,.newline + .tab)
//	fatalError()
}

public func ModifyMainFile(source: String, imports: [String], pyswiftProducts: [String]) -> String {
	let parse = Parser.parse(source: source)
	var export: [CodeBlockItemListSyntax.Element] = []
	var productImports: [ImportDeclSyntax] = pyswiftProducts.map { p in
		return .init(path: .init([.init(name: .identifier(p))]))
	}
	for stmt in parse.statements {
		let item = stmt.item
		//print()
		//print(item.kind)
		
		switch item.kind {
		case .variableDecl:
			var variDecl = item.as(VariableDeclSyntax.self)!
			//print(variDecl.modifiers)
			var binding = variDecl.bindings.first!
			//print(binding.typeAnnotation!)
			if
				let id = binding.pattern.as(IdentifierPatternSyntax.self),
				
				let initializer = binding.initializer,
				id.identifier.text == "pythonSwiftImportList"
			{
				pyswiftProducts.forEach { imp in
					export.append(
						.init( leadingTrivia: .newline, item: .decl(.init(stringLiteral: "import \(imp)")) )
					)
				}
				if var arrayExpr = initializer.value.as(ArrayExprSyntax.self) {
					var elements = arrayExpr.elements.map(\.expression)
					
					for imp in imports {
						elements.append(addPythonSwiftImport(imp))
					}
					
					arrayExpr.elements = .init(elements.map({ .init(expression: $0, trailingComma: .commaToken()) }))
					binding.initializer = .init(value: arrayExpr.with(\.leadingTrivia ,.space))
					variDecl.bindings = .init([binding])
					
					export.append(
						.init( leadingTrivia: .newline, item: .decl(.init(variDecl)) )
					)
				}
			} else {
				export.append(stmt)
			}

		default: export.append(stmt)
		}

	}

	return SourceFileSyntax(statements: .init(export), endOfFileToken: .endOfFileToken()).description
}
