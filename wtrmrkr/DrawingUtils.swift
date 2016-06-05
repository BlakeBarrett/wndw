//
//  DrawingUtils.swift
//  wndw
//
//  Created by Blake Barrett on 6/4/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import MobileCoreServices

class DrawingUtils {
    
    var mainImageView = UIImageView()
    var tempImageView = UIImageView()
    
    var lastPoint = CGPointMake(0, 0)
    var swiped = false
    
    func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.locationInView(self.mainImageView)
        }
    }
    
    func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.locationInView(self.mainImageView)
            self.tempImageView.image = DrawingUtils.drawLineFrom(lastPoint, toPoint: currentPoint, onImage: self.tempImageView.image!, inFrame: self.rect, withBrush: self.brush)
            lastPoint = currentPoint
        }
    }
    
    func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !swiped {
            // draw a single point
            self.tempImageView.image = DrawingUtils.drawLineFrom(lastPoint, toPoint: lastPoint, onImage: self.tempImageView.image!, inFrame: self.rect, withBrush: self.brush)
        }
        
        self.mainImageView.image = ImageMaskingUtils.mergeImages(self.mainImageView.image!,
                                                                 second: self.tempImageView.image!)
        self.tempImageView.image = nil
    }
    
    // MARK: - Line Drawing Code
    var brush: Brush = Brush()
    func setBrush(brush: Brush) {
        self.brush = brush
    }

    var rect: CGRect = CGRectMake(0, 0, 1920, 1080)
    
    
    class func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint, onImage: UIImage, inFrame rect:CGRect, withBrush: Brush) -> UIImage {
    
        let brush = withBrush
        let size = rect.size
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        onImage.drawInRect(rect)
        
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, brush.width)
        CGContextSetRGBStrokeColor(context, brush.red, brush.green, brush.blue, brush.alpha)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        
        CGContextStrokePath(context)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}