//
//  TouchableUIImageView.swift
//  wndw
//
//  Created by Blake Barrett on 6/4/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class TouchableUIImageView: UIImageView {
//    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        super.touchesBegan(touches, withEvent: event)
//    }
//    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        super.touchesMoved(touches, withEvent: event)
//    }
//    
//    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        super.touchesEnded(touches, withEvent: event)
//    }
//    
    
    
    override func layoutSubviews() {
        self.mask.frame = self.frame
        self.temp.frame = self.frame
        self.masked.frame = self.frame
    }
    
    
    // MARK: - Line Drawing Code
    var brush: Brush = Brush(red: 1.0 ,green: 1.0, blue: 1.0, width: 10.0, alpha: 1.0)
    func setBrush(brush: Brush) {
        self.brush = brush
    }

//    var tempImageView = UIImageView()
    var swiped = false
    var lastPoint = CGPointMake(0,0)
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.locationInView(self)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.locationInView(self)
            DrawingUtils.drawLineFrom(lastPoint, toPoint: currentPoint, inImageView: self.mask, withBrush: self.brush)
            DrawingUtils.drawLineFrom(lastPoint, toPoint: currentPoint, inImageView: self.temp, withBrush: self.brush)
            
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        if !swiped {
            // draw a single point
            DrawingUtils.drawLineFrom(lastPoint, toPoint: lastPoint, inImageView: self.mask, withBrush: self.brush)
            DrawingUtils.drawLineFrom(lastPoint, toPoint: lastPoint, inImageView: self.temp, withBrush: self.brush)
        }

//        self.maskView = self
//        self.image = ImageMaskingUtils.mergeImages(self.image!,
//                                                   second: self.tempImageView.image!)
//        self.tempImageView.image = nil
        
        /*
         mainImageView.image = mergeImages(mainImageView.image, second: tempImageView.image)
         tempImageView.image = nil
         */
        
        self.applyMask()
        
        self.mask.image = nil
        
        self.image = self.masked.image
    }
    
    var temp = UIImageView()
    var mask = UIImageView()
    var masked = UIImageView()
    var original = UIImage()
    func applyMask() {
        guard let image = self.image else { return }
        guard let mask = self.mask.image else { return }
        
        self.masked.image = ImageMaskingUtils.maskImage(image, maskImage: mask)
    }
}
