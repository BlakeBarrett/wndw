//
//  VideoMaskingUtils.swift
//  wtrmrkr
//
//  Created by Blake Barrett on 5/23/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import AVFoundation
import AssetsLibrary
import Photos
import CoreMedia
import Foundation
import UIKit

class VideoMaskingUtils {
    
    class func thumbnailsFor(asset: AVAsset, howMany count: Int) -> [UIImage] {
        var images = [UIImage]()
        
        let totalDuration = asset.duration.seconds
        let sliceDuation = (totalDuration / Double(count))
        
        for i in 1...count {
            let timescale = asset.duration.timescale
            let value = floor(sliceDuation * Double(i) * Double(timescale))
            var time = CMTimeMake(1, timescale)
            time.value = CMTimeValue(value)
            guard let image = VideoMaskingUtils.getFrameFrom(asset, atTime: time) else { continue }
            images.append(image)
        }
        return images
    }
    
    // Lifted straight up from here: http://stackoverflow.com/questions/7501413/create-thumbnail-from-a-video-url-in-iphone-sdk
    class func thumbnailImageForVideo(url:NSURL) -> UIImage? {
        let asset = AVAsset(URL: url)
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        return VideoMaskingUtils.getFrameFrom(asset, atTime: time)
    }
    
    class func getFrameFrom(asset: AVAsset, atTime time: CMTime) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: imageRef)
        } catch let error as NSError
        {
            print("VideoMaskingUtils.getFrameFrom:: Error: \(error)")
            return nil
        }
    }
    
    class func getAVAssetAt(url: NSURL) -> AVURLAsset {
        return AVURLAsset(URL: url, options: nil)
    }
    
    class func overlay(video firstAsset: AVURLAsset, withSecondVideo secondAsset: AVURLAsset, andAlpha alpha: Float) {
        // Most of this code was translated into Swift 2.2 from this example here:
        //   https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/03_Editing.html
        //
        // Or whichever is the original between these two (cloned) tutorials
        //   http://www.theappguruz.com/blog/ios-overlap-multiple-videos
        //   https://abdulazeem.wordpress.com/2012/04/02/video-manipulation-in-ios-resizingmerging-and-overlapping-videos-in-ios/
        
        
        let mixComposition = AVMutableComposition()
        
        let firstTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let secondTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        guard let firstMediaTrack = firstAsset.tracksWithMediaType(AVMediaTypeVideo).first else { return }
        guard let secondMediaTrack = secondAsset.tracksWithMediaType(AVMediaTypeVideo).first else { return }
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration), ofTrack: firstMediaTrack, atTime: kCMTimeZero)
            try secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration), ofTrack: secondMediaTrack, atTime: kCMTimeZero)
        } catch (let error) {
            print(error)
        }

        let width = max(firstMediaTrack.naturalSize.width, secondMediaTrack.naturalSize.width)
        let height = max(firstMediaTrack.naturalSize.height, secondMediaTrack.naturalSize.height)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSizeMake(width, height)
        videoComposition.frameDuration = firstMediaTrack.minFrameDuration

        let firstApproach = false
        if firstApproach {
//            let mainInstruction = AVMutableVideoCompositionInstruction()
//            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration)
//            mainInstruction.backgroundColor = UIColor.redColor().CGColor
//            
//            let firstlayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
//            firstlayerInstruction.setTransform(firstAsset.preferredTransform, atTime: kCMTimeZero)
//            
//            let secondInstruction = AVMutableVideoCompositionInstruction()
//            secondInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, secondAsset.duration)
//            let backgroundColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: alpha)
//            secondInstruction.backgroundColor = backgroundColor.CGColor
//            
//            let secondlayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondTrack)
//            secondlayerInstruction.setTransform(secondAsset.preferredTransform, atTime: kCMTimeZero)
//            
//            secondInstruction.layerInstructions = [secondlayerInstruction]
//            
//            mainInstruction.layerInstructions = [firstlayerInstruction]//, secondlayerInstruction]
//            
//            videoComposition.instructions = [mainInstruction, secondInstruction]
//
        } else {
            let firstLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstMediaTrack)
            firstLayerInstruction.setTransform(firstMediaTrack.preferredTransform, atTime: kCMTimeZero)
            firstLayerInstruction.setOpacity(1.0, atTime: kCMTimeZero)
            
            let secondlayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondMediaTrack)
            secondlayerInstruction.setTransform(secondMediaTrack.preferredTransform, atTime: kCMTimeZero)
            secondlayerInstruction.setOpacity(alpha, atTime: kCMTimeZero)

            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(kCMTimeZero, min(firstAsset.duration, secondAsset.duration))
            instruction.layerInstructions = [firstLayerInstruction, secondlayerInstruction]
            
            videoComposition.instructions = [instruction]
        }
        
        let outputUrl = VideoMaskingUtils.getPathForTempFileNamed("output.mov")
        
        VideoMaskingUtils.exportCompositedVideo(mixComposition, toURL: outputUrl, withVideoComposition: videoComposition)
        
        VideoMaskingUtils.removeTempFileAtPath(outputUrl.absoluteString)
    }
    
    
    class func overlay(video sourceVideo: AVURLAsset, withImage image: UIImage, andAlpha alpha: Float, atRect imageRect: CGRect?, muted: Bool) {
        // Most of this code was translated into Swift 2.2 from this example here:
        //   https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/03_Editing.html
        
        guard let videoAssetTrack = sourceVideo.tracksWithMediaType(AVMediaTypeVideo).first else { return }
        guard let audioAssetTrack = sourceVideo.tracksWithMediaType(AVMediaTypeAudio).first else { return }
        
        let width = videoAssetTrack.naturalSize.width
        let height = videoAssetTrack.naturalSize.height
        
        let videoFrameRect = CGRect(x: 0, y: 0, width: width, height: height)
        let watermarkRect: CGRect
        if let imageRect = imageRect {
            watermarkRect = imageRect
        } else {
            watermarkRect = videoFrameRect
        }
        
        let mutableCompositon = AVMutableComposition()
        let mutableVideoCompositionTrack = mutableCompositon.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let mutableAudioCompositionTrack = mutableCompositon.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let sourceVideoDuration = CMTimeRangeMake(kCMTimeZero, sourceVideo.duration)
        do {
            try mutableVideoCompositionTrack.insertTimeRange(sourceVideoDuration, ofTrack: videoAssetTrack, atTime: kCMTimeZero)
            if !muted {
                try mutableAudioCompositionTrack.insertTimeRange(sourceVideoDuration, ofTrack: audioAssetTrack, atTime: kCMTimeZero)
            }
        } catch (let error) {
            print(error)
        }
        
        let watermarkLayer: CALayer  = VideoMaskingUtils.createLayerWith(image)
        watermarkLayer.frame = watermarkRect
        watermarkLayer.opacity = alpha
        
        let parentLayer: CALayer = CALayer()
        parentLayer.frame = videoFrameRect
        
        let videoLayer: CALayer = CALayer()
        videoLayer.frame = videoFrameRect
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(watermarkLayer)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableVideoCompositionTrack)
        layerInstruction.setTransform(mutableVideoCompositionTrack.preferredTransform, atTime: kCMTimeZero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = sourceVideoDuration
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition(propertiesOfAsset: sourceVideo)
        videoComposition.renderScale = 1.0
        videoComposition.renderSize = videoFrameRect.size
        videoComposition.frameDuration = videoAssetTrack.minFrameDuration
        videoComposition.instructions = [instruction]
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        
        
        let outputUrl = VideoMaskingUtils.getPathForTempFileNamed("output.mov")
        
        VideoMaskingUtils.exportCompositedVideo(mutableCompositon, toURL: outputUrl, withVideoComposition: videoComposition)
        
        VideoMaskingUtils.removeTempFileAtPath(outputUrl.absoluteString)
    }
    
    private class func getPathForTempFileNamed(filename: String) -> NSURL {
        let outputPath = NSTemporaryDirectory() + filename
        let outputUrl = NSURL(fileURLWithPath: outputPath)
        VideoMaskingUtils.removeTempFileAtPath(outputPath)
        return outputUrl
    }
    
    private class func removeTempFileAtPath(path: String) {
        let fileManager = NSFileManager.defaultManager()
        if (fileManager.fileExistsAtPath(path)) {
            do {
                try fileManager.removeItemAtPath(path)
            } catch _ {
            }
        }
    }
    
    private class func exportCompositedVideo(compiledVideo: AVMutableComposition, toURL outputUrl: NSURL, withVideoComposition videoComposition: AVMutableVideoComposition?) {
        guard let exporter = AVAssetExportSession(asset: compiledVideo, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = outputUrl
        if let videoComposition = videoComposition {
            exporter.videoComposition = videoComposition
        }
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronouslyWithCompletionHandler({
            switch exporter.status {
            case .Completed:
                // we can be confident that there is a URL because
                // we got this far. Otherwise it would've failed.
                let url = exporter.outputURL!
                UISaveVideoAtPathToSavedPhotosAlbum(url.path!, nil, nil, nil)
                print("VideoMaskingUtils.exportVideo SUCCESS!")
                if exporter.error != nil {
                    print("VideoMaskingUtils.exportVideo Error: \(exporter.error)")
                    print("VideoMaskingUtils.exportVideo Description: \(exporter.description)")
                    NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: exporter.error)
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: url)
                }
                
                break
            
            case .Exporting:
                let progress = exporter.progress
                print("VideoMaskingUtils.exportVideo \(progress)")
                
                NSNotificationCenter.defaultCenter().postNotificationName("videoExportProgress", object: progress)
                break
            
            case .Failed:
                print("VideoMaskingUtils.exportVideo Error: \(exporter.error)")
                print("VideoMaskingUtils.exportVideo Description: \(exporter.description)")
                
                NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: exporter)
                break
            
            default: break
            }
        })
    }
    
    class func createLayerWith(image: UIImage?) -> CALayer {
        let layer = CALayer()
        guard let image = image else {
            return layer
        }
        layer.contents = image.CGImage
        layer.frame = CGRectMake(0, 0, image.size.width, image.size.height)
        layer.position = layer.frame.origin
        layer.opacity = 1.0
        return layer
    }

}
