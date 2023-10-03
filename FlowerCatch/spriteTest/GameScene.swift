//
//  GameScene.swift
//  spriteTest
//
//  Created by Dylan Lindeman
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let vase = SKSpriteNode(imageNamed: "vase")
    var score = 0
    var timeRemaining = 25
    let scoreLabel = SKLabelNode(fontNamed: "SF")
    let timeLabel = SKLabelNode(fontNamed: "SF")
    
    //physics contstraints for vase and flower
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let all: UInt32 = UInt32.max
        static let vase: UInt32 = 0b1       //1
        static let flower: UInt32 = 0b10    //2
    }
    
    override func didMove(to view: SKView) {
        // Set up the game scene
        
        // Set the background color
        backgroundColor = .gray
        
        // Set up the vase sprite
        vase.size = CGSize(width: 100, height: 100)
        vase.position = CGPoint(x: frame.midX, y: frame.minY + 100)
        vase.physicsBody = SKPhysicsBody(rectangleOf: vase.size)
        vase.physicsBody?.categoryBitMask = PhysicsCategory.vase
        vase.physicsBody?.contactTestBitMask = PhysicsCategory.flower
        vase.physicsBody?.collisionBitMask = PhysicsCategory.none
        vase.physicsBody?.isDynamic = false
        addChild(vase)
        
        // Set up the physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: -1.8)
        physicsWorld.contactDelegate = self
        
        // Create the score label for testing
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .black
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: frame.maxX - 150, y: frame.maxY - 100)
        //addChild(scoreLabel)
        
        // Create the time label
        timeLabel.text = "Time: 60"
        timeLabel.fontSize = 20
        timeLabel.fontColor = .black
        timeLabel.horizontalAlignmentMode = .left
        timeLabel.position = CGPoint(x: frame.maxX - 150, y: frame.maxY - 115)
        addChild(timeLabel)

        
        // Start the timer
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        // Generate flowers
        let generateFlower = SKAction.run {
            let flower = SKSpriteNode(imageNamed: "flower")
            flower.size = CGSize(width: 64, height: 64)
            let randomX = CGFloat.random(in: 50...(self.frame.maxX - 50))
            flower.position = CGPoint(x: randomX, y: self.frame.maxY)
            flower.physicsBody = SKPhysicsBody(circleOfRadius: flower.size.width / 2)
            flower.physicsBody?.categoryBitMask = PhysicsCategory.flower
            flower.physicsBody?.contactTestBitMask = PhysicsCategory.vase
            flower.physicsBody?.collisionBitMask = PhysicsCategory.none
            flower.physicsBody?.usesPreciseCollisionDetection = true
            self.addChild(flower)
            
            let move = SKAction.moveTo(y: self.frame.minY - flower.size.height, duration: 5)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, remove])
            flower.run(sequence)
        }
        let wait = SKAction.wait(forDuration: 2)
        let sequence = SKAction.sequence([generateFlower, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        run(repeatForever)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Move the vase sprite
        for touch in touches {
            let location = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            let dx = location.x - previousLocation.x
            vase.position.x += dx
        }
    }
    // Check for collision and make sound alert
    func flowerDidCollideWithVase(flower: SKSpriteNode, vase: SKSpriteNode){
        flower.removeFromParent()
        score += 1
        let sound = SKAction.playSoundFileNamed("Stapler.mp3", waitForCompletion: false)
        run(sound)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Handle collisions between the vase and the flowers
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & PhysicsCategory.vase != 0) && (secondBody.categoryBitMask & PhysicsCategory.flower != 0) {
            if let vase = firstBody.node as? SKSpriteNode, let flower = secondBody.node as? SKSpriteNode {
                flowerDidCollideWithVase(flower: flower, vase: vase)
            }
        }
    }



        
        @objc func updateTime() {
            // Update the time remaining label and end the game if time is up
            timeRemaining -= 1
            timeLabel.text = "Time: \(timeRemaining)"
            if timeRemaining == 0 {
                endGame()
            }
        }
    
    func restartGame() {
        // Reload the current scene
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }

    func quitGame() {
        // Exit the game
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
    }

        
    func endGame() {
        // End the game and ask the user if they would like to restart or quit the game
        removeAllActions()
        physicsWorld.contactDelegate = nil
        let alertController = UIAlertController(title: "Game Over", message: "Final Score: \(score)\nWould you like to restart or quit?", preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart", style: .default) { (_) in
            // Restart the game
            self.restartGame()
        }
        let quitAction = UIAlertAction(title: "Quit", style: .default) { (_) in
            // Quit the game
            self.quitGame()
        }
        alertController.addAction(restartAction)
        alertController.addAction(quitAction)
        self.view?.window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }


        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            // Restart the game if the restart button is touched
            for touch in touches {
                let location = touch.location(in: self)
                let nodes = nodes(at: location)
                if nodes.contains(where: { $0.name == "restart" }) {
                    let newGameScene = GameScene(size: size)
                    newGameScene.scaleMode = scaleMode
                    let transition = SKTransition.fade(withDuration: 1)
                    view?.presentScene(newGameScene, transition: transition)
                }
            }
        }
    }

