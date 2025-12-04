#if false
// This placeholder scene is disabled to avoid duplicate compile-source warnings.
// You likely have two references to BowlingAlleyScene.swift in Build Phases -> Compile Sources.
// Remove the extra entry there. Re-enable this file by changing '#if false' to '#if true' if needed.
//

//
//  BowlingAlleyScene.swift
//  BirdGame3
//
//  Created by Jack Doyle on 12/4/25.
//


import SpriteKit
import UIKit

// Minimal placeholder to satisfy build if the real file is missing.
// Replace with the real implementation when available.
class BowlingAlleyScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .systemBackground

        let label = SKLabelNode(text: "Bowling Alley Scene (Placeholder)")
        label.fontSize = 24
        label.fontColor = .label
        label.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        let dot = SKShapeNode(circleOfRadius: 8)
        dot.fillColor = .systemBlue
        dot.position = p
        addChild(dot)
        dot.run(.sequence([.wait(forDuration: 0.8), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
#endif // Disabled placeholder to avoid duplicate compile entry
