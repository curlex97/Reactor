//
//  GameScene.swift
//  Reactor
//
//  Created by Admin on 14.03.16.
//  Copyright (c) 2016 Admin. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity


class GameScene: SKScene, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    var sprite = SKSpriteNode(imageNamed:"gball")
    var finger = SKSpriteNode(imageNamed: "platform")
    var bgImage = SKSpriteNode(imageNamed: "blue")
    var lifesImg : [SKSpriteNode] = [];
    
    var startLabel = SKLabelNode(fontNamed: "Chalkduster")
    var joinLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    var isTap = false
    var isRight : Bool = true
    var isTop : Bool = true
    var isMove : Bool = false
    var isManipulated : Bool = false
    var isGameEnded : Bool = false
    
    let toCGFloat = { Double($0).map{ CGFloat($0) } }
    
    var x : CGFloat = 450
    var y : CGFloat = 150
    var speedX : CGFloat = 20
    var speedY : CGFloat  = 12
    var halfX : CGFloat = 97
    var halfY : CGFloat = 87
    var width : CGFloat = 1024
    var height : CGFloat = 768
    var numberOfLifes : Int = 3
    
    
    func IterateSpeed()
    {
        if self.mcSession.connectedPeers.count == 0 {return}
        
       // let randomX = CGFloat(Int(arc4random()) % 10) * 0.05
       // let randomY = CGFloat(Int(arc4random()) % 10) * 0.05
        speedX += speedY * 0.03
        speedY += speedX * 0.02
    }
    
    override func didMoveToView(view: SKView)
    {
        bgImage.position = CGPointMake(self.size.width/2, self.size.height/2)
        bgImage.zPosition = -1
        self.addChild(bgImage)
        
        
        startLabel.text = "Create game"
        startLabel.fontSize = 48
        startLabel.zPosition = 2
        startLabel.position = CGPointMake(CGRectGetMinX(self.frame) + 250, CGRectGetMidY(self.frame))
        self.addChild(startLabel)
        
        joinLabel.text = "Join game"
        joinLabel.fontSize = 48
        joinLabel.zPosition = 2
        
        joinLabel.position = CGPointMake(CGRectGetMaxX(self.frame) - 250, CGRectGetMidY(self.frame))
        self.addChild(joinLabel)
        
        
        peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .Required)
        mcSession.delegate = self
        
    }
    
    
    func addLifes()
    {
        self.speedX = 20
        self.speedY = 12
        
        while lifesImg.count > 0
        {
            let sp = lifesImg.removeLast()
            sp.runAction(SKAction.moveTo(CGPointMake(sp.position.x, self.height + 50), duration: 0.1), completion: {sp.removeFromParent()})
        }
        
        for i in 0 ..< numberOfLifes
        {
            let life = SKSpriteNode(imageNamed: "heart")
            life.zPosition = 4
            life.xScale = 0.2
            life.yScale = 0.2
            life.position = CGPointMake(CGFloat(60 + i*80), CGFloat(self.height + 50))
           
            lifesImg.append(life)
            
            self.addChild(lifesImg.last!)
            lifesImg.last!.runAction(SKAction.moveTo(CGPointMake(CGFloat(60 + i*80), CGFloat(self.height - 50)), duration: 0.2))
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
      
        let point = touches.first!.locationInView(self.view)

        if isGameEnded && !isMove
        {
            isMove = true
            isGameEnded = false
        }
        
        if !isTap
        {
            
            let t = CGFloat(self.width/2)
            if(point.x < t){
                self.startHosting()
                isGameEnded = true
            }
            else {
                self.joinSession()
            }

            addLifes()
            
            finger.xScale = 0.5
            finger.yScale = 0.5
            sprite.xScale = 0.3
            sprite.yScale = 0.3
            self.x = CGRectGetMidX(self.frame)
            self.y = CGRectGetMidY(self.frame)
            sprite.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
            sprite.zPosition = 3
            self.addChild(sprite)
           // let act = SKAction.repeatActionForever(SKAction.rotateByAngle(CGFloat(M_PI*12), duration: 1.0))
          //  sprite.runAction(act)
            isTap = true
            startLabel.removeFromParent()
            joinLabel.removeFromParent()
        
        }
        
        else if self.finger.parent == nil && !isGameEnded
        {
            self.finger.position = CGPointMake(point.x, -10)
            self.finger.zPosition = 1
            self.addChild(self.finger)
            let moveBottomLeft = SKAction.moveTo(CGPointMake(point.x,100), duration:0.1)
            finger.runAction(moveBottomLeft)
        }
  
        
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let point = touches.first!.locationInView(self.view)
        self.finger.position = CGPointMake(point.x, 100)
        
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        self.finger.removeFromParent()
        self.finger.position = CGPointMake(0, 0)

    }
    
    
    func RedirectMoving()
    {
        if isTop {y += speedY}
        else {y -= speedY}
        
        if isRight {x += speedX}
        else {x -= speedX}
        
        if x < halfX + speedX || x > width - halfX - speedX {isRight = !isRight}
        if y < halfY + speedY {
            isManipulated = true
            isTop = !isTop
            IterateSpeed()
            
            if lifesImg.count > 0
            {
                let sp = lifesImg.removeLast()
                sp.runAction(SKAction.moveTo(CGPointMake(sp.position.x, self.height + 50), duration: 0.1), completion: {sp.removeFromParent()})
            }
            else
            {
                isGameEnded = true
                isMove = false
                sprite.runAction(SKAction.moveTo(CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame)), duration: 0.15))
                self.x = CGRectGetMidX(self.frame)
                self.y = CGRectGetMidY(self.frame)
                addLifes()
                sendMessage("n_")
            }
            
        }
        if y > height - halfY - speedY && self.mcSession.connectedPeers.count == 0 {
            isTop = !isTop
            isManipulated = false
        }
        
        
        for node in self.children
        {
            if node == self.finger && sprite.intersectsNode(finger) && !isManipulated
            {
                IterateSpeed()
                isManipulated = true
                isTop = !isTop
            }
        }
        
    }
    
    
    
    func sendMessage(msg: String) {
        if mcSession.connectedPeers.count > 0 {
            
                do {
                    let data = msg.dataUsingEncoding(NSUTF8StringEncoding)
                    try mcSession.sendData(data!, toPeers: mcSession.connectedPeers, withMode: .Reliable)
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .Alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(ac, animated: true, completion: nil)
                }
           
        }
    }
    
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
        let count = data.length / sizeof(UInt8)
        var array = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&array, length:count * sizeof(UInt8))
        let data = bytesToString(array)
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                
                let fullNameArr = data.characters.split{$0 == "_"}.map(String.init)
                
                if fullNameArr[0] == "p"
                {
                    self.isRight = fullNameArr[1] == "r"
                    self.x = self.width - self.toCGFloat(fullNameArr[2])!
                    self.y = self.height + self.halfY - self.speedY
                    self.isTop = false
                    self.isMove = true
                    self.isGameEnded = false
                }
                
                else if fullNameArr[0] == "n"
                {
                    self.addLifes()
                }
              
                
                
        }
    }
    
    func bytesToString(array:[UInt8]) -> String {
        return String(data: NSData(bytes: array, length: array.count), encoding: NSUTF8StringEncoding) ?? ""
    }
    
    
    
    
    
   
    override func update(currentTime: CFTimeInterval) {
       
        
        if isMove
        {
            sprite.position = CGPoint(x:self.x, y:self.y)

            
            RedirectMoving()
            
            if y > height + halfY + speedY && self.mcSession.connectedPeers.count > 0
            {
                IterateSpeed()
                
                isTop = !isTop
                var str : String = "p_"
                if isRight
                {
                    str = str + "l"
                }
                else {
                    str = str + "r"
                }
                str += "_"
                 str += String(x)
                
                isMove = false
              isManipulated = false
              self.sendMessage(str)
            }
            
        }
        
    }
    
    
    func startHosting() {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-kb", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    func joinSession() {
        let mcBrowser = MCBrowserViewController(serviceType: "hws-kb", session: mcSession)
        mcBrowser.delegate = self
        UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(mcBrowser, animated: true, completion: nil)
    }
    
    
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
    }
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        UIApplication.sharedApplication().keyWindow!.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        UIApplication.sharedApplication().keyWindow!.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case MCSessionState.Connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.Connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.NotConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
}
