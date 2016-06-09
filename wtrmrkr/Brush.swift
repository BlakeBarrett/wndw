//
//  Brush.swift
//  wndw
//
//  Created by Blake Barrett on 5/7/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import CoreGraphics

class Brush {
    
    init() {
    }
    
    init(red: CGFloat, green: CGFloat, blue: CGFloat, width: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.width = width
        self.alpha = alpha
    }
    
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var width: CGFloat = 10.0
    var alpha: CGFloat = 1.0
}
