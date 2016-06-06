//
//  PlayGame.swift
//  Jumping
//
//  Created by hoang pham on 23/5/16.
//  Copyright © 2016 camonia. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit


class PlayGame: GKState {
    unowned let scene: GameScene
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        if previousState is WaitingForTap {
            //hide ready label
            let scale = SKAction.scaleTo(0, duration: 0.4)
            scene.fgNode.childNodeWithName("Ready")!.runAction(scale)
            SKAction.sequence([SKAction.waitForDuration(0.2), scale])
            scene.startGame()
        }
    }
    
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        scene.updateCamera()
        scene.updatePlayer()
        scene.updateLevel()
        scene.updateWater(seconds)
        scene.updateCollisionWater()
        scene.checkIfPlayerFallDown()
        scene.updateScoreNode()
        
    }
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is GameOver.Type
    }
    
}
