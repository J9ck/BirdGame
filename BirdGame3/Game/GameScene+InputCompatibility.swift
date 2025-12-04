//
//  GameScene+InputCompatibility.swift
//  BirdGame3
//
//  Small compatibility wrappers so views/controllers can call common input methods
//  (movePlayer(direction:), movePlayer(directionVector:), playerBlock(_:)).
//  These forward to the existing playerBird methods if available.
//  Add this file to the app target (File Inspector → Target Membership).
//

import SpriteKit
import CoreGraphics

extension GameScene {
    /// Called by controllers to move the player. Accepts a horizontal speed scalar.
    /// We clamp the value to a sane range to avoid huge jumps from controller input.
    func movePlayer(direction: CGFloat) {
        // If the scene has a dedicated method with the same name, this will simply be this method.
        // Forward to the player character to perform movement if available.
        let clamped = max(-1000, min(1000, direction))
        playerBird?.move(by: CGVector(dx: clamped, dy: 0))
    }

    /// Convenience overload used when controller supplies a CGVector (joystick).
    func movePlayer(directionVector: CGVector) {
        movePlayer(direction: directionVector.dx)
    }

    /// Called by controllers to toggle player blocking.
    /// If the scene already implements playerBlock(_:), this will call that; otherwise we operate directly on playerBird.
    func playerBlock(_ blocking: Bool) {
        // Forward to any existing explicit playerBlock(_:) implementation if present.
        // Since this is an extension, calling self.playerBlock(_:) would recurse; instead check if playerBird exists and operate on it.
        if blocking {
            playerBird?.startBlocking()
        } else {
            playerBird?.stopBlocking()
        }
    }
}
