//
//  ImageMaskingUtils.swift
//  mskr
//
//  Created by Blake Barrett on 6/6/14.
//  Copyright © 2014 Blake Barrett. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class ImageMaskingUtils {
    
    // TODO: Implement "Green Screen" a.k.a. Chroma Key/Color Replacement.
    // https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_filer_recipes/ci_filter_recipes.html#//apple_ref/doc/uid/TP30001185-CH4-SW2
    // https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html#//apple_ref/doc/uid/TP30001185-CH3-BAJDAHAD
    
    // Apple's docs on CIFilters: 
    // https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
    
    // Video modification tutorials:
    // https://www.objc.io/issues/23-video/core-image-video/
    // http://krakendev.io/blog/be-cool-with-cifilter-animations
    // https://github.com/objcio/core-image-video/blob/master/CoreImageVideo/FunctionalCoreImage.swift
    // Merge and Export videos:
    // https://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
    // https://developer.apple.com/library/mac/documentation/AVFoundation/Reference/AVMutableComposition_Class/
    // Overlay videos:
    // https://abdulazeem.wordpress.com/2012/04/02/video-manipulation-in-ios-resizingmerging-and-overlapping-videos-in-ios/
    
    /**
     * Changes the saturation of the image to the provided value
     */
    class func setImageSaturation(image: UIImage!, saturation: NSNumber) -> UIImage {
        return ImageMaskingUtils.colorControlImage(image, brightness: 1.0, saturation: saturation, contrast: 1.0)
    }
    
    /**
     * Changes the brightness of the image
     */
    class func setImageBrightness(image: UIImage, brightness: NSNumber) -> UIImage {
        return ImageMaskingUtils.colorControlImage(image, brightness: brightness, saturation: 1.0, contrast: 1.0)
    }
    
    /**
     * Changes the contrast of the image
     */
    class func setImageContrast(image: UIImage, contrast: NSNumber) -> UIImage {
        return ImageMaskingUtils.colorControlImage(image, brightness: 1.0, saturation: 1.0, contrast: contrast)
    }
    
    /**
     * Modifies the image's Saturation/Brightness/Contrast
     */
    class func colorControlImage(image: UIImage, brightness: NSNumber, saturation: NSNumber, contrast: NSNumber) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        //ciImage?.imageByApplyingTransform:CGAffineTransformMakeTranslation(100, 100)]
        
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            UIGraphicsEndImageContext()
            return image
        }
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        let ret = UIImage(CGImage: context.createCGImage(result, fromRect: result.extent))
        UIGraphicsEndImageContext()
        return ret
    }
    
    /**
    * Changes the saturation of the image to the provided value
    */
    class func noirImage(image: UIImage) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            UIGraphicsEndImageContext()
            return image
        }
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        let ret = UIImage(CGImage: context.createCGImage(result, fromRect: result.extent))
        UIGraphicsEndImageContext()
        return ret
    }
    
    /**
     * Invert colors of image
     */
    class func invertImageColors(image: UIImage) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            UIGraphicsEndImageContext()
            return image
        }
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        let ret = UIImage(CGImage: context.createCGImage(result, fromRect: result.extent))
        UIGraphicsEndImageContext()
        return ret
    }
    
    /**
     * Takes a greyscale image, darker the color the lower the alpha (0x000000 == 0.0)
     */
    class func imageToMask(image: UIImage) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIMaskToAlpha")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let result = filter?.valueForKey(kCIOutputImageKey) as? CIImage else {
            return image
        }
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        return UIImage(CGImage: context.createCGImage(result, fromRect: result.extent))
    }
    
    /**
     * Masks the source image with the mask.
     */
    class func maskImage(source: UIImage!, maskImage: UIImage!) -> UIImage {
        
        // try the quick and dirty first
        if let mskd: CGImageRef = CGImageCreateWithMask(source.CGImage, invertImageColors(maskImage).CGImage) {
            log("CGImageCreateWithMask returned nil from source: \(source.CGImage) mask: \(maskImage.CGImage)")
            return UIImage(CGImage: mskd)
        } // okay then, do it the longer way
        
        guard let _ = maskImage.CGImage else {
            log("maskRef was nil")
            return source
        }
        
        guard let mask: CGImageRef = CGImageMaskCreate(CGImageGetWidth(maskImage.CGImage),
            CGImageGetHeight(maskImage.CGImage),
            CGImageGetBitsPerComponent(maskImage.CGImage),
            CGImageGetBitsPerPixel(maskImage.CGImage),
            CGImageGetBytesPerRow(maskImage.CGImage),
            CGImageGetDataProvider(maskImage.CGImage), nil, true) else {
                log("CGImageMaskCreate was nil")
                return source
        }
        
        guard let _ = source.CGImage else {
            log("source.CGImage was nil")
            return source
        }
        
        guard let masked: CGImageRef = CGImageCreateWithMask(source.CGImage, mask) else {
            log("CGImageCreateWithMask returned nil from source: \(source.CGImage) mask: \(mask)")
            return source
        }
        
        return UIImage(CGImage: masked)
    }
    
    /**
     * Flattens or rasterizes two images into one.
     */
    class func mergeImages(first: UIImage, second: UIImage) -> UIImage {
        let newImageSize: CGSize = CGSizeMake(
            max(first.size.width, second.size.width),
            max(first.size.height, second.size.height))

        UIGraphicsBeginImageContextWithOptions(newImageSize, false, 1)
        
        var wid: CGFloat = CGFloat(roundf(CFloat(newImageSize.width - first.size.width) / 2.0))
        var hei: CGFloat = CGFloat(roundf(CFloat(newImageSize.height-first.size.height) / 2.0))
        
        let firstPoint = CGPointMake(wid, hei)
        first.drawAtPoint(firstPoint)
        
        wid = CGFloat(roundf(CFloat(newImageSize.width - second.size.width) / 2.0))
        hei = CGFloat(roundf(CFloat(newImageSize.height-second.size.height) / 2.0))
        
        let secondPoint = CGPointMake(wid, hei);
        second.drawAtPoint(secondPoint)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func fit(image:UIImage, inSize: CGSize) -> UIImage {
        let size = inSize
        let originalAspectRatio = image.size.width / image.size.height
        
        let rect: CGRect
        let width, height, x, y: CGFloat
        //      width > height
        if (originalAspectRatio > 1) {
            // this appears to work
            width = size.width
            height = size.width / originalAspectRatio
            x = 0
            y = (size.height - height) / 2
            rect = CGRect(
                x: x, y: y,
                width: width,
                height: height
            )
        } else {
            // while this does not
            width = size.height * originalAspectRatio
            height = size.height
            x = (size.width - width) / 2
            y = 0
            rect = CGRect(
                x: x, y: y,
                width: width,
                height: height
            )
        }
        
        UIGraphicsBeginImageContext(size)
        image.drawInRect(rect)
        
        let rasterized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rasterized
    }
    /*
    class func imagePreservingAspectRatio(fromImage: UIImage, withSize size: CGSize, andAlpha alpha: CGFloat) -> UIImage {
        let originalSize = fromImage.size
        let naturalAspectRatio = originalSize.width / originalSize.height
        var newSize: CGSize
        if (fromImage.size.width > fromImage.size.height) {
            if (originalSize.width < originalSize.height) {
                newSize = CGSizeMake(size.width, size.width * naturalAspectRatio)
            } else {
                newSize = CGSizeMake(size.width * naturalAspectRatio, size.width)
            }
        } else {
            if (originalSize.width < originalSize.height) {
                newSize = CGSizeMake(size.height, size.height * naturalAspectRatio)
            } else {
                newSize = CGSizeMake(size.height * naturalAspectRatio, size.height)
            }
        }
        return ImageMaskingUtils.image(fromImage, withSize: newSize, andAlpha: alpha)
    }
    */
    /**
     * Returns a UIImage with the alpha modified
     */
    class func image(fromImage: UIImage, withAlpha alpha: CGFloat) -> UIImage {
        return image(fromImage, withSize: fromImage.size, andAlpha: alpha);
    }

    /**
     * Returns a UIImage with size and alpha passed in.
     * size param overrides image's natural size and aspect ratio.
     **/
    class func image(fromImage: UIImage, withSize size:CGSize, andAlpha alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
        let area: CGRect = CGRectMake(0, 0, size.width, size.height)
        
        CGContextScaleCTM(ctx, 1, -1)
        CGContextTranslateCTM(ctx, 0, -area.size.height)
        
        CGContextSetBlendMode(ctx, CGBlendMode.Multiply)
        
        CGContextSetAlpha(ctx, alpha)
        
        CGContextDrawImage(ctx, area, fromImage.CGImage)
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /**
     * Resize image: http://stackoverflow.com/a/12140767 and http://nshipster.com/image-resizing/
     **/
    class func resize(image: UIImage, size: CGSize) -> UIImage {
        let cgImage = image.CGImage
        let colorspace = CGImageGetColorSpace(cgImage)
        
        let context = CGBitmapContextCreate(nil,
                                            Int(size.width), Int(size.height),
                                            CGImageGetBitsPerComponent(cgImage),
                                            CGImageGetBytesPerRow(cgImage),
                                            colorspace,
                                            CGImageGetAlphaInfo(cgImage).rawValue)
        
        CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), cgImage)
        // extract resulting image from context
        guard let imgRef = CGBitmapContextCreateImage(context) else {
            UIGraphicsEndImageContext()
            return image
        }
        UIGraphicsEndImageContext()
        let resizedImage = UIImage(CGImage: imgRef)
        return resizedImage
    }
    
    /**
     * Stretches images that aren't 1:1 to squares based on their longest edge
     */
    class func makeItSquare(image: UIImage) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        let size: CGSize = CGSize(width: longestSide, height: longestSide)
        
        let x: CGFloat = (size.width - image.size.width) / 2
        let y: CGFloat = (size.height - image.size.height) / 2
        
        let cropRect: CGRect = CGRectMake(x, y, size.width, size.height)
        
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(image.CGImage!, cropRect)!
        let cropped: UIImage = UIImage(CGImage: imageRef)
        UIGraphicsEndImageContext()
        return ImageMaskingUtils.image(cropped, withSize: size, andAlpha: 1)
    }
    
    /**
     * Takes an image and rotates it.
     */
    class func rotate(image: UIImage, radians: CGFloat) -> UIImage {
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRectMake(0, 0, image.size.width, image.size.height));
        let transform: CGAffineTransform = CGAffineTransformMakeRotation(radians);
        rotatedViewBox.transform = transform;
        let rotatedSize: CGSize = rotatedViewBox.frame.size;
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        let bitmap: CGContextRef = UIGraphicsGetCurrentContext()!
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
        
        // Rotate the image context
        CGContextRotateCTM(bitmap, radians);
        
        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0);
        CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), image.CGImage);
        
        let rotated: UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return rotated;
    }
    
    /**
     * Fix the image orientation issues we've seen.
     * Translated from Objective-C from here: http://stackoverflow.com/a/1262395
     **/
    class func reconcileImageOrientation(image:UIImage) -> UIImage {
        let targetWidth = Int(image.size.width)
        let targetHeight = Int(image.size.height)
        
        let imageRef = image.CGImage
        let bitmapInfo = CGImageGetBitmapInfo(imageRef!)
        let colorSpaceInfo = CGImageGetColorSpace(imageRef!)
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(image.size);
        var bitmap: CGContextRef = UIGraphicsGetCurrentContext()!

        if (image.imageOrientation == UIImageOrientation.Up || image.imageOrientation == UIImageOrientation.Down) {
            bitmap = CGBitmapContextCreate(nil, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo.rawValue)!
        } else {
            bitmap = CGBitmapContextCreate(nil, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo.rawValue)!
        }
        
        if (image.imageOrientation == UIImageOrientation.Left) {
            CGContextRotateCTM (bitmap, radians(90))
            CGContextTranslateCTM (bitmap, 0, CGFloat(-targetHeight))
        } else if (image.imageOrientation == UIImageOrientation.Right) {
            CGContextRotateCTM (bitmap, radians(-90))
            CGContextTranslateCTM (bitmap, CGFloat(-targetWidth), 0)
        } else if (image.imageOrientation == UIImageOrientation.Up) {
            // NOTHING
        } else if (image.imageOrientation == UIImageOrientation.Down) {
            CGContextTranslateCTM (bitmap, CGFloat(targetWidth), CGFloat(targetHeight))
            CGContextRotateCTM (bitmap, radians(-180))
        }
        
        CGContextDrawImage(bitmap, CGRectMake(0, 0, CGFloat(targetWidth), CGFloat(targetHeight)), imageRef)
        let ref = CGBitmapContextCreateImage(bitmap)
        let newImage = UIImage(CGImage: ref!)
        
        UIGraphicsEndImageContext()
        
        return newImage;
    }
    
    static func radians (degrees: Int) -> CGFloat {
        return CGFloat(Double(degrees) * M_PI / 180.0)
    }
    
    static func log(message:String) {
        print(message)
    }
}
