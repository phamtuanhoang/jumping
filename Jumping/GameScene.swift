//
//  GameScene.swift
//  Jumping
//
//  Created by hoang pham on 21/5/16.
//  Copyright (c) 2016 camonia. All rights reserved.
//

import SpriteKit
import CoreMotion
import GameplayKit

struct PhysicalCategory{
    static let None: UInt32                 = 0
    static let Player: UInt32               = 0b1       //1
    static let PlatformNormal: UInt32       = 0b10      //2
    static let PlatformBreakable: UInt32    = 0b100     //4
    static let Edges: UInt32                = 0b1000    //8
    static let Water: UInt32                = 0b10000   //16
    
}

struct MovingDirection{
    static let MoveLeft: UInt32 = 0
    static let MoveRight: UInt32 = 0
}

struct MovingSpeedLevel{
    static let Speed_1: Int = 5
    static let Speed_2: Int = 4
    static let Speed_3: Int = 3
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    //Mark: properties
    
    var bgNode = SKNode()
    var fgNode = SKNode()
    var background: SKNode!
    var backHeight: CGFloat = 0.0
    var player: SKSpriteNode!
    
    var platform: SKSpriteNode!
    var currentJumpingNode: SKSpriteNode!
    var previousJumpingNode: SKSpriteNode!
    
    var lastItemPosition = CGPointZero
    var lastItemHeight : CGFloat = 0.0
    var levelY: CGFloat = 0.0
    var allowJump: Bool = true
    var fallState: Bool = true
    var jumpLowState: Bool = false
    var checkFallingDown: Bool = false
    
    let motionManager = CMMotionManager()
    var xAcceleration = CGFloat(0)
    
    //camera tracking
    let cameraNode  = SKCameraNode()
    
    //water flow
    var waterFlow: SKSpriteNode!
    
    var lastUpdateTimeInterval: NSTimeInterval = 0
    var deltaTime: NSTimeInterval = 0
    
    let gain: CGFloat = 2.5
    var squishAndStretch: SKAction! = nil
    
    var squishAction: SKAction! = nil
    var stretchAction: SKAction! = nil

    var movingDirection: Bool!
    var gameScore: SKLabelNode!
    var score: Int = 0
    
    //state machine
    lazy var gameState: GKStateMachine = GKStateMachine(states: [WaitingForTap(scene: self),PlayGame(scene: self),GameOver(scene: self)])
    
    lazy var playerState: GKStateMachine = GKStateMachine(states: [IdleState(scene: self), JumpState(scene: self), FallState(scene: self)])
    
    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTimeInterval > 0 {
            deltaTime = currentTime - lastUpdateTimeInterval
        }else{
            deltaTime = 0
        }
        lastUpdateTimeInterval = currentTime
        if paused {return }
        
        gameState.updateWithDeltaTime(deltaTime)
    }
    
    override func didMoveToView(view: SKView) {
        movingDirection = true
        setupNodes()
        //add platform
        setupLevel()
        
        //setup player
        setupPlayer()
        
        //contact delegate
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVectorMake(0.0, -10)
        setupCoreMotion()
        
        //update camera tracking
        setCameraPosition(CGPoint(x: size.width/2, y: size.height/2))
        //enter state
        gameState.enterState(WaitingForTap)
        playerState.enterState(IdleState)
        
    }
    
    func setupNodes(){
        let worldNode = childNodeWithName("World")
        let bgNode = worldNode?.childNodeWithName("Background")
        background = bgNode?.childNodeWithName("Overlay")!.copy() as! SKNode
        backHeight = background.calculateAccumulatedFrame().height
        fgNode = worldNode!.childNodeWithName("Foreground")!
        player = fgNode.childNodeWithName("Player") as! SKSpriteNode
        
        //load overlay
        platform = loadOverlayNode("Platform")
        //add camera tracking
        addChild(cameraNode)
        camera = cameraNode
        
        //setup water
        setupWater()
        
        //squish and stretch action
        squishAction = SKAction.scaleXTo(1.25, y:0.85, duration: 0.25)
        squishAction.timingMode = SKActionTimingMode.EaseInEaseOut
        stretchAction = SKAction.scaleXTo(0.75, y: 1.2,duration: 0.25)
        stretchAction.timingMode = SKActionTimingMode.EaseInEaseOut
        squishAndStretch = SKAction.sequence([squishAction, stretchAction])
        
        //setup score node
        gameScore = SKLabelNode(text: "0")
        gameScore.setScale(5)
        gameScore.position = self.getScorePosition()
        gameScore.zPosition = 10
        gameScore.text = String(score)
        self.addChild(gameScore)
    }
    //set up level
    func setupLevel(){
        //place initial platform
        let initialPlatform = platform.copy() as! SKSpriteNode
        var itemPosition = player.position
        itemPosition.y = player.position.y - ((player.size.height*0.5) + (initialPlatform.size.height*0.25))
        initialPlatform.position = itemPosition
        fgNode.addChild(initialPlatform)
        lastItemPosition = itemPosition
        lastItemHeight = initialPlatform.size.height / 2.0
        levelY = background.position.y + backHeight
        while lastItemPosition.y < levelY {
            addRandomOverlayNode()
        }
    }
    
    //set up level
    func setupWater(){
        //add water
        waterFlow = fgNode.childNodeWithName("Water") as! SKSpriteNode
        let emitter = SKEmitterNode(fileNamed: "Water.sks")!
        emitter.particlePositionRange = CGVector(dx: size.width*1.125, dy:0.0)
        emitter.advanceSimulationTime(3.0)
        emitter.zPosition = 4
        waterFlow.addChild(emitter)
    }
    
    //set up player
    func setupPlayer(){
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width*0.3)
        player.physicsBody!.dynamic = false
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.categoryBitMask = PhysicalCategory.Player
        player.physicsBody!.contactTestBitMask = PhysicalCategory.PlatformNormal
        player.physicsBody!.collisionBitMask = 1;

    }
    
    //update Water
    func updateCollisionWater(){
        if(player.position.y < waterFlow.position.y + 180){
            NSLog("Touch Water")
            addSmoke()
            gameState.enterState(GameOver)
        }
    }
    func addSmoke(){
        let smokeTrial = addTrail("SmokeTrail")
        self.runAction(SKAction.sequence([SKAction.waitForDuration(3.0), SKAction.runBlock(){
            //self.removeTrail(smokeTrial)
            }
            ]))
    }
    //MARK: moving water
    
    func updateWater(dt: NSTimeInterval){
        //calculate the lower left position of the viewable part of the screen
        //y is changing so subtracting the height of scene from current camera(y) position
        let lowerLeft = CGPoint(x:0, y:cameraNode.position.y - (size.height/2))
        //convert the water point from fgNode to scene coordinates
        let visibleMinYFg = scene!.convertPoint(lowerLeft, toNode: fgNode).y
        let waterVelocity = CGPoint(x:0, y: 120)
        //define base velocity, mutiplying time steps and update position
        let waterStep = waterVelocity * CGFloat(dt)
        var newPosition = waterFlow.position + waterStep
        //return the highest (y) position between new position and a position slightly below the visible area of the screen
        //keep water in sync with the camara position
        newPosition.y = max(newPosition.y,(visibleMinYFg - 125.0))
        waterFlow.position = newPosition
    }
    //MARK: update moving platform
    func checkIfPlayerFallDown(){
        if (currentJumpingNode) != nil {
            NSLog("Platform position %f", currentJumpingNode.position.y)
            NSLog("Player position %f", player.position.y)
            
//            if((Float)currentJumpingNode.position.y > (Float)player.po){
//                checkFallingDown = true
//            }else{
//                checkFallingDown = false
//            }
        }
        
    }
    
    
    //set up core motion
    func setupCoreMotion(){
        motionManager.accelerometerUpdateInterval = 0.2
        let queue = NSOperationQueue()
        motionManager.startAccelerometerUpdatesToQueue(queue, withHandler: {
            accelerometerData, error in
            guard let accelerometerData = accelerometerData else {
                return
            }
            let acceleration = accelerometerData.acceleration
            self.xAcceleration = CGFloat(acceleration.x)*0.75 + self.xAcceleration*0.25
        })
    }
    
    //update player core motion
    func updatePlayer(){
        //set velocity based on core motion
        player.physicsBody?.velocity.dx = xAcceleration * 1000.0
        var playerPosition = convertPoint(player.position, fromNode: fgNode)
        if playerPosition.x < -player.size.width/2
        {
            playerPosition = convertPoint(CGPoint(x: size.width + player.size.width/2, y: 0.0), toNode: fgNode)
            player.position.x = playerPosition.x
        }
        else if playerPosition.x > size.width + player.size.width/2
        {
            playerPosition = convertPoint(CGPoint(x:-player.size.width/2, y:0.0), toNode: fgNode)
            player.position.x = playerPosition.x
        }
        if player.physicsBody?.velocity.dy < 0{
            playerState.enterState(FallState)
            fallState = true
        }else{
            playerState.enterState(JumpState)
        }
        
//        if player.physicsBody?.velocity.dy > 0{
//            fallState = false
//            allowJump = false
//
//        }
//        else if (player.physicsBody?.velocity.dy <= 0 && player.physicsBody?.velocity.dy >= -500){
//            allowJump = true
//        }else {
//            allowJump = false
//        }
       
    }
    
    //take platform node and load into overlay node
    func loadOverlayNode(fileName: String) -> SKSpriteNode {
        let overlayScene = SKScene(fileNamed: fileName)
        let contentTemplateNode = overlayScene?.childNodeWithName("Overlay")
        return contentTemplateNode as! SKSpriteNode
    }
    func createOverLayNode(nodeType: SKSpriteNode, flipX: Bool){
        let platform = nodeType.copy() as! SKSpriteNode
        lastItemPosition.y = lastItemPosition.y + (lastItemHeight + (platform.size.height * 5.0))
        lastItemHeight = platform.size.height / 2.0
        platform.position = lastItemPosition
        //        let startingPoint = CGPoint(x: 0, y: lastItemPosition.y)
        platform.position = lastItemPosition
        platform.name = "Platform"
        if flipX == true{
            platform.xScale = -1.0
        }
        
        //add new node
        let movingTime = arc4random_uniform(3) + 2;
        
        let moveLeft = SKAction.moveToX(500, duration: NSTimeInterval(Int(movingTime)))
        let moveRight = SKAction.moveToX(-500, duration:NSTimeInterval(Int(movingTime)))
        if(movingDirection == true){
            let actionSequence = SKAction.sequence([moveLeft, moveRight])
            //platform.runAction(SKAction.repeatActionForever(actionSequence))
            movingDirection = false
        }else {
            let actionSequence = SKAction.sequence([moveRight,moveLeft])
            //platform.runAction(SKAction.repeatActionForever(actionSequence))
            movingDirection = true
        }
        
        fgNode.addChild(platform)
        
    }
    //make background continous cycling
    func createBackgroundNode(){
        let backNode = background.copy() as! SKNode
        backNode.position = CGPoint(x:0.0, y: levelY)
        bgNode.addChild(backNode)
        levelY += backHeight
    }
    //adding random overlay node
    func addRandomOverlayNode (){
        let overlaySprite: SKSpriteNode!
        
        let platformPercentage = 60
        //if Int.random(min: 1, max: 100) <= platformPercentage{
        overlaySprite = platform
        overlaySprite.name = "Platform"
        //}
        createOverLayNode(overlaySprite, flipX: false)
    }
    
    //Events
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (allowJump == true){
            if(fallState){
                jumpPlayer()
                jumpLowState = false
                allowJump = false
                fallState = false
            }
        }
        
        switch gameState.currentState{
        case is WaitingForTap:
            self.runAction(SKAction.waitForDuration(0.5),completion:{
                self.gameState.enterState(PlayGame)
            })
        case is GameOver:
            let newScene = GameScene(fileNamed: "GameScene")
            newScene!.scaleMode = .AspectFill
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            self.view?.presentScene(newScene!, transition: reveal)
            
        default:break
        }
    }
    
    func startGame(){
        player.physicsBody!.dynamic = true
        jumpPlayer()
        allowJump = false
        
    }
    
    func setPlayerVelocity(amount: CGFloat){
        let gain: CGFloat = 1.5
        player.physicsBody!.velocity.dy = max(player.physicsBody!.velocity.dy, amount*gain)
    }
    
    func jumpPlayer(){
        setPlayerVelocity(1000)
    }
    
    func jumpLow(){
        jumpLowState = true
        print("Velocity falling: %d ", self.player.physicsBody?.velocity.dy)
        setPlayerVelocity(250)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicalCategory.Player ? contact.bodyB : contact.bodyA
        switch other.categoryBitMask {
        case PhysicalCategory.PlatformNormal:
           
            print("Touched platform")
            if let platform = other.node as? SKSpriteNode
            {
                if let _ = other.node as? SKSpriteNode {
                    
                    if (player.physicsBody!.velocity.dy < 0){
                        if(!jumpLowState){
                            score += 1
                            gameScore.text = String(score)
                        }
                        jumpLow()
                        allowJump = true
                        platformAction(platform)
                    }
                }
                
            }
        default:
            break;
        }
    }
    
    //MARK: - Camera
    func overlapAmount() -> CGFloat{
        guard let view = self.view else{
            return 0
        }
        let scale = view.bounds.size.height / self.size.height
        let scaleWidth = self.size.width * scale
        let scaleOverlap = scaleWidth - view.bounds.size.width
        return scaleOverlap/scale
    }
    func getCameraPosition() -> CGPoint {
        return CGPoint(x: cameraNode.position.x + overlapAmount()/2, y: cameraNode.position.y)
    }
    func getScorePosition() -> CGPoint {
        return CGPoint(x:self.size.width, y: self.size.height)
    }
    func setCameraPosition(position: CGPoint){
        cameraNode.position = CGPoint(x:position.x - overlapAmount()/2,y:position.y)
    }
    
    func setScorePosition(position: CGPoint){
        gameScore.position = position
    }
    
    func updateScoreNode(){
        //convert player position within fgNode to scene coordinates
        setScorePosition(CGPoint(x:self.size.width*0.8, y: getCameraPosition().y + self.size.height*0.4))
    }
    
    func updateCamera(){
        //convert player position within fgNode to scene coordinates
        let cameraTarget = convertPoint(player.position, fromNode: fgNode)
        //set the target position of camera to  player's position less 40% of the scene's height
        var targetPosition = CGPoint(x: getCameraPosition().x, y: cameraTarget.y - (scene!.view!.bounds.height * 0.4))
        let waterPos = convertPoint(waterFlow.position, fromNode: fgNode)
        targetPosition.y = max(targetPosition.y, waterPos.y)
        //different of target camera position and current position
        let diff = targetPosition - getCameraPosition()
        //instead of updating to target, move camera 5% toward targe, make camera take a while to catchup
        //linear interpolation technique
        let lerpValue = CGFloat(0.05)
        let lerpDiff = diff * lerpValue
        //set camera to new target position
        let newPosition = getCameraPosition() + lerpDiff
        setCameraPosition(CGPoint(x: size.width/2, y: newPosition.y))
    }
    
    
    //Mark: - Update level, continious adding platform
    func updateLevel(){
        let cameraPos = getCameraPosition()
        if cameraPos.y > levelY - (size.height * 0.55){
            createBackgroundNode()
            while lastItemPosition.y < levelY {
                addRandomOverlayNode()
            }
        }
    }
    
    //add smoke to player
    func addTrail(name: String) -> SKEmitterNode{
        let trail = SKEmitterNode(fileNamed: name)!
        trail.targetNode = fgNode
        player.addChild(trail)
        return trail
    }
    func removeTrail(trail: SKEmitterNode) {
        trail.numParticlesToEmit = 1
        trail.runAction(SKAction.removeFromParentAfterDelay(1.0))
    }
    
    //MARK : Bouncing effect
    func platformAction(sprite: SKSpriteNode){
        let amount = CGPoint(x: 0, y: -15.0)
        let action = SKAction.screenShakeWithNode(sprite, amount: amount, oscillations: 10, duration: 2.0)
        sprite.runAction(action)
    }
}
