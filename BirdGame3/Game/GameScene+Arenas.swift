//
//  GameScene+Arenas.swift
//  BirdGame3
//
//  NOTE: Arena setup helpers were removed from this file to avoid duplicate
//  declarations. The canonical arena helper implementations now live in
//  GameScene-BirdBattle.swift (GameScene.swift). If you want the helpers
//  to live here instead, delete them from GameScene.swift and move them back.
//
//  This file intentionally contains no arena setup functions to prevent
//  "Invalid redeclaration" compile errors.
//
import SpriteKit
import UIKit

// Intentionally empty extension — keep here only for optional future arena helpers.
// If you'd like to centralize arena helpers here, tell me and I'll move them and
// remove the duplicates from GameScene.swift.

extension GameScene {
    // Example non-conflicting helper (optional):
    // Use this kind of helper if you want shared utilities that don't clash
    // with existing function names.
    func makeArenaBackgroundNode(color: UIColor, name: String) -> SKSpriteNode {
        let node = SKSpriteNode(color: color, size: size)
        node.name = name
        node.zPosition = -100
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        return node
    }
}
