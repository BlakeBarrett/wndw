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
    
    // For an example of when/how to call this, check <#TouchableUIImageView.swift>
    // or check out mrkr
    
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