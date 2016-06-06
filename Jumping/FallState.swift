//
//  FallState.swift
//  Jumping
//
//  Created by hoang pham on 24/5/16.
//  Copyright © 2016 camonia. All rights reserved.
//

import Foundation
import GameplayKit
import SpriteKit

class FallState: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    override func didEnterWithPreviousState(previousState: GKState?) {
//        scene.player.runAction(scene.squishAndStretch)
        scene.player.runAction(scene.squishAction)

    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is JumpState.Type
    }
}