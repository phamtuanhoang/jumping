//
//  WaitingForTap.swift
//  Jumping
//
//  Created by hoang pham on 23/5/16.
//  Copyright © 2016 camonia. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class WaitingForTap: GKState {
    unowned let scene: GameScene
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    override func didEnterWithPreviousState(previousState: GKState?) {
        let scale = SKAction.scaleTo(1.0, duration: 0.5)
        scene.fgNode.childNodeWithName("Ready")!.runAction(scale)
        let scaleOut = SKAction.scaleTo(0.0, duration: 0.1)

        scene.fgNode.childNodeWithName("Ready")!.runAction(scale)

    }
    //say state machine can only transition to play game
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is PlayGame.Type
    }
}
