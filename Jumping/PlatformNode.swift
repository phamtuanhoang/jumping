//
//  PlatformNode.swift
//  Jumping
//
//  Created by hoang pham on 29/5/16.
//  Copyright © 2016 camonia. All rights reserved.
//

import Foundation
import SpriteKit

class PlatformNode: SKScene {
    
    
    init(color:SKColor,size:CGSize) {
        super.init()
        self.size=size
      
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}