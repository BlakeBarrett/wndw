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
            DrawingUtils.drawLineFrom(lastPoint, toPoint: currentPoint, inImageView: self.tempImageView, withBrush: self.brush)
            
            lastPoint = currentPoint
        }
    }
    
    func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !swiped {
            // draw a single point
            DrawingUtils.drawLineFrom(lastPoint, toPoint: lastPoint, inImageView: self.tempImageView, withBrush: self.brush)
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

    
    
    
    class func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint, inImageView: UIImageView, withBrush: Brush) {
        
        let brush = withBrush
        
        let size = inImageView.frame.size
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
//        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        inImageView.image?.drawInRect(inImageView.frame)
        
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, brush.width)
        CGContextSetRGBStrokeColor(context, brush.red, brush.green, brush.blue, brush.alpha)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        
        CGContextStrokePath(context)
        
        inImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
}