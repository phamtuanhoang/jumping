//
//  IdleState.swift
//  Jumping
//
//  Created by hoang pham on 24/5/16.
//  Copyright © 2016 camonia. All rights reserved.
//

import GameplayKit
import SpriteKit

class IdleState: GKState {
    unowned let scene: GameScene
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    override func didEnterWithPreviousState(previousState: GKState?) {
        scene.player.physicsBody = SKPhysicsBody(circleOfRadius: scene.player.size.width*0.3)
        scene.player.physicsBody!.dynamic = false
        scene.player.physicsBody!.allowsRotation = false
        scene.player.physicsBody!.categoryBitMask = PhysicalCategory.Player
        scene.player.physicsBody!.collisionBitMask = 0
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is JumpState.Type
    }

}