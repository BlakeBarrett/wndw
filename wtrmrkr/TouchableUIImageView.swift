//
//  TouchableUIImageView.swift
//  wndw
//
//  Created by Blake Barrett on 6/4/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class TouchableUIImageView: UIImageView {
  
    var touchesEnabled = true
    
    override func layoutSubviews() {
        self.mask.frame = self.frame
        self.temp.frame = self.frame
        self.masked.frame = self.frame
    }
    
    func setOriginalImage(image: UIImage) {
        temp.image = UIImage()
        mask.image = UIImage()
        masked.image = UIImage()
        
        self.image = image
        self.original = image
        
        self.rect = ImageMaskingUtils.center(image, inFrame: self.frame.size).rect
    }
    
    // MARK: - Line Drawing Code
    var brush: Brush = Brush(red: 1.0 ,green: 1.0, blue: 1.0, width: 10.0, alpha: 0.9)
    func setBrush(brush: Brush) {
        self.brush = brush
    }

    var swiped = false
    var lastPoint = CGPointMake(0,0)
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !touchesEnabled { return }
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.locationInView(self)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !touchesEnabled { return }
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.locationInView(self)
            self.temp.image = DrawingUtils.drawLineFrom(lastPoint, toPoint: currentPoint, onImage: self.temp.image!, inFrame: self.rect, withBrush: self.brush)
            lastPoint = currentPoint
        }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            dispatch_async(dispatch_get_main_queue(), {
                self.mask.image = ImageMaskingUtils.mergeImages(self.mask.image!,
                    second: self.temp.image!)
                self.applyMask()
            })
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !touchesEnabled { return }
        if !swiped {
            self.temp.image = DrawingUtils.drawLineFrom(lastPoint, toPoint: lastPoint, onImage: self.temp.image!, inFrame: self.rect, withBrush: self.brush)
        }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            dispatch_async(dispatch_get_main_queue(), {
                self.mask.image = ImageMaskingUtils.mergeImages(self.mask.image!,
                    second: self.temp.image!)
                
                self.temp.image = UIImage()

                self.applyMask()
            })
        }
    }
    
    var rect: CGRect = CGRectMake(0, 0, 1920, 1080)
    
    var temp = UIImageView()
    var mask = UIImageView()
    var masked = UIImageView()
    var original = UIImage()
    func applyMask() {
        guard let mask = self.mask.image else { return }
        
        self.masked.image = ImageMaskingUtils.maskImage(original, maskImage: mask)
        self.image = self.masked.image
    }
}
