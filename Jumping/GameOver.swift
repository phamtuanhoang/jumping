//
//  GameOver.swift
//  Jumping
//
//  Created by hoang pham on 23/5/16.
//  Copyright © 2016 camonia. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
class GameOver: GKState {
    unowned let scene: GameScene
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        if previousState is PlayGame{
            scene.physicsWorld.contactDelegate = nil
            scene.player.physicsBody?.dynamic = false
            let moveUpAction = SKAction.moveByX(0, y: scene.size.height/2, duration: 0.5)
            let moveDownAction = SKAction.moveByX(0, y: -(scene.size.height*1.5), duration: 3.0)
            let sequence = SKAction.sequence([moveUpAction, moveDownAction])
            scene.player.runAction(sequence)
            
//            let gameOver = SKSpriteNode(imageNamed: "GameOver")
//            gameOver.position = scene.getCameraPosition()
//            gameOver.zPosition = 10
//            scene.addChild(gameOver)
            let scale = SKAction.scaleTo(1.0, duration: 0.5)
            let gameOver = SKSpriteNode(imageNamed: "GameOver")
            gameOver.position = scene.getCameraPosition()
            gameOver.zPosition = 10
            scene.addChild(gameOver)
        
//            scene.fgNode.childNodeWithName("GameOver")!.runAction(scale)

//            scene.addChild(gameOver!)
        }
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is WaitingForTap.Type
    }
}
