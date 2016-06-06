//
//  JumpLowState.swift
//  Jumping
//
//  Created by hoang pham on 4/6/16.
//  Copyright © 2016 camonia. All rights reserved.
//

import Foundation
import GameplayKit
import SpriteKit

class JumpLowState: GKState{
    unowned let scene: GameScene
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        //        scene.player.runAction(scene.squishAndStretch)
        
    }
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        //run set of animation here
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is FallState.Type
    }
    
}
