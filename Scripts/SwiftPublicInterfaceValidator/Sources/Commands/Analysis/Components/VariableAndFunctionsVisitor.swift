//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

final class VariableAndFunctionsVisitor: SyntaxVisitor {

    private let publicOnly: Bool
    private let depth: Int
    private let parent: ContainerDeclSyntax
    private var items: [PublicInterfaceEntry] = []

    init(
        parent: ContainerDeclSyntax,
        depth: Int,
        publicOnly: Bool,
        viewMode: SyntaxTreeViewMode = .all
    ) {
        self.parent = parent
        self.depth = depth
        self.publicOnly = publicOnly
        super.init(viewMode: viewMode)
    }

    func traverse() -> [PublicInterfaceEntry] {
        super.walk(parent.memberBlock)
        return items
    }

    // MARK: - Container

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        visitContainerNode(node)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        visitContainerNode(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        visitContainerNode(node)
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        visitContainerNode(node)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        visitContainerNode(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let hasPublicMembers = node.memberBlock.members.contains { member in
            if let decl = member.decl.as(VariableDeclSyntax.self) {
                return decl.modifiers.isPublicOrOpen
            } else if let decl = member.decl.as(FunctionDeclSyntax.self) {
                return decl.modifiers.isPublicOrOpen
            }
            return false
        }

        guard
            node.modifiers.isPublicOrOpen || hasPublicMembers
        else {
            return .skipChildren
        }

        return visitContainerNode(node)
    }

    // MARK: - Children

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.modifiers.isPublicOrOpen || !publicOnly {
            items.append(.variable(node.removingInitializer(), depth))
        }
        return .skipChildren
    }

    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        items.append(.enumCase(node.removingTrivia(), depth))
        return .skipChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.modifiers.isPublicOrOpen || !publicOnly {
            items.append(.function(node.removeTrivia().removeBody(), depth))
        }

        return .skipChildren
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.modifiers.isPublicOrOpen || !publicOnly {
            items.append(.subscript(node.removeTrivia().removeAccessor(), depth))
        }

        return .skipChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.modifiers.isPublicOrOpen || !publicOnly {
            items.append(.initialiser(node.removeTrivia().removeBody(), depth))
        }

        return .skipChildren
    }

    // MARK: - Private Helpers

    private func visitContainerNode(
        _ node: DeclSyntaxProtocol
    ) -> SyntaxVisitorContinueKind {
        guard
            let container = node as? ContainerDeclSyntax,
            container.modifiers.isPublicOrOpen || node.is(ExtensionDeclSyntax.self)
        else {
            return .skipChildren
        }

        let newVisitor = VariableAndFunctionsVisitor(
            parent: container,
            depth: depth + 1,
            publicOnly: !(node.is(ExtensionDeclSyntax.self) || node.is(ProtocolDeclSyntax.self))
        )
        let children = newVisitor.traverse()
        items.append(.container(container, depth, children))

        return .skipChildren
    }
}
