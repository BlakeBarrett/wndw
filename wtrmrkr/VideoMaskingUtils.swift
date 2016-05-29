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

    // Lifted straight up from here: http://stackoverflow.com/questions/7501413/create-thumbnail-from-a-video-url-in-iphone-sdk
    class func thumbnailImageForVideo(url:NSURL) -> UIImage? {
        let asset = AVAsset(URL: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: imageRef)
        } catch let error as NSError
        {
            print("VideoMaskingUtils.thumbnailImageForVideo:: Error: \(error)")
            return nil
        }
    }
    
    class func getAVAssetAt(url: NSURL) -> AVURLAsset {
        return AVURLAsset(URL: url, options: nil)
    }
    
    class func overlay(video sourceVideo: AVURLAsset, withSecondVideo secondVideo: AVURLAsset, andAlpha alpha: Float) {
        // Most of this code was translated into Swift 2.2 from this example here:
        //   https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/03_Editing.html
        
        guard let videoAssetTrack = sourceVideo.tracksWithMediaType(AVMediaTypeVideo).first else { return }
        guard let videoAssetTrackTwo = secondVideo.tracksWithMediaType(AVMediaTypeVideo).first else { return }
        
        guard let audioAssetTrack = sourceVideo.tracksWithMediaType(AVMediaTypeAudio).first else { return }
        guard let audioAssetTrackTwo = secondVideo.tracksWithMediaType(AVMediaTypeAudio).first else { return }
        
        let sourceVideoDuration = CMTimeRangeMake(kCMTimeZero, min(sourceVideo.duration, secondVideo.duration))
        
        let mutableCompositon = AVMutableComposition()
        let mutableVideoCompositionTrack = mutableCompositon.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let mutableVideoCompositionTrackTwo = mutableCompositon.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let mutableAudioCompositionTrack = mutableCompositon.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let mutableAudioCompositionTrackTwo = mutableCompositon.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do {
            try mutableVideoCompositionTrack.insertTimeRange(sourceVideoDuration, ofTrack: videoAssetTrack, atTime: kCMTimeZero)
            try mutableVideoCompositionTrackTwo.insertTimeRange(sourceVideoDuration, ofTrack: videoAssetTrackTwo, atTime: kCMTimeZero)
            try mutableAudioCompositionTrack.insertTimeRange(sourceVideoDuration, ofTrack: audioAssetTrack, atTime: kCMTimeZero)
            try mutableAudioCompositionTrackTwo.insertTimeRange(sourceVideoDuration, ofTrack: audioAssetTrackTwo, atTime: kCMTimeZero)
        } catch (let error) {
            print(error)
        }
        
        let width = videoAssetTrack.naturalSize.width
        let height = videoAssetTrack.naturalSize.height
        
        let videoFrameRect = CGRect(x: 0, y: 0, width: width, height: height)
        
        let watermarkLayer = CALayer()
        watermarkLayer.contents = videoAssetTrackTwo
        watermarkLayer.frame = videoFrameRect
        watermarkLayer.opacity = alpha
        
        let parentLayer: CALayer = CALayer()
        parentLayer.frame = videoFrameRect
        
        let videoLayer: CALayer = CALayer()
        videoLayer.frame = videoFrameRect
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(watermarkLayer)
        
        
        
        
        
        
        
        
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableVideoCompositionTrack)
        layerInstruction.setTransform(mutableVideoCompositionTrack.preferredTransform, atTime: kCMTimeZero)
        layerInstruction.setOpacity(0.0, atTime: sourceVideoDuration.duration)
        
        let layerInstructionTwo = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableVideoCompositionTrackTwo)
        layerInstructionTwo.setTransform(mutableVideoCompositionTrackTwo.preferredTransform, atTime: kCMTimeZero)
        layerInstructionTwo.setOpacity(0.0, atTime: sourceVideoDuration.duration)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = sourceVideoDuration
        instruction.layerInstructions = [layerInstruction, layerInstructionTwo]
        
        let videoComposition = AVMutableVideoComposition() //AVMutableVideoComposition(propertiesOfAsset: sourceVideo)
        videoComposition.renderScale = 1.0
        videoComposition.renderSize = videoFrameRect.size
        videoComposition.frameDuration = videoAssetTrack.minFrameDuration
        videoComposition.instructions = [instruction]
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        
        
//        let firstVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
//        // Set the time range of the first instruction to span the duration of the first video track.
//        firstVideoCompositionInstruction.timeRange = sourceVideoDuration
//        
//        let secondVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
//        secondVideoCompositionInstruction.timeRange = sourceVideoDuration
//        
//        let firstVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack:mutableVideoCompositionTrack)
//        firstVideoLayerInstruction.setTransform(videoAssetTrack.preferredTransform, atTime: kCMTimeZero)
//        
//        let secondVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack:mutableVideoCompositionTrackTwo)
//        secondVideoLayerInstruction.setTransform(secondVideoAssetTrack.preferredTransform, atTime: kCMTimeZero)
//        
//        
//        firstVideoCompositionInstruction.layerInstructions = [firstVideoLayerInstruction]
//        secondVideoCompositionInstruction.layerInstructions = [secondVideoLayerInstruction]
//        
//        let videoComposition = AVMutableVideoComposition(propertiesOfAsset: sourceVideo)
//        videoComposition.instructions = [firstVideoCompositionInstruction, secondVideoCompositionInstruction]
//        videoComposition.renderSize = videoFrameRect.size
        
        let outputUrl = VideoMaskingUtils.getPathForTempFileNamed("output.mov")
        
        VideoMaskingUtils.exportCompositedVideo(mutableCompositon, toURL: outputUrl, withVideoComposition: videoComposition)
        
        VideoMaskingUtils.removeTempFileAtPath(outputUrl.absoluteString)
    }
    
    
    class func overlay(video sourceVideo: AVURLAsset, withImage image: UIImage, andAlpha alpha: Float, atRect imageRect: CGRect?) {
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
            try mutableAudioCompositionTrack.insertTimeRange(sourceVideoDuration, ofTrack: audioAssetTrack, atTime: kCMTimeZero)
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
        layerInstruction.setOpacity(0.0, atTime: sourceVideoDuration.duration)
        
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
    
    private class func exportCompositedVideo(compiledVideo: AVMutableComposition, toURL outputUrl: NSURL, withVideoComposition videoComposition: AVMutableVideoComposition) {
        guard let exporter = AVAssetExportSession(asset: compiledVideo, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = outputUrl
        exporter.videoComposition = videoComposition
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronouslyWithCompletionHandler({
            switch exporter.status {
            case .Completed:
                // we can be confident that there is a URL because
                // we got this far. Otherwise it would've failed.
                UISaveVideoAtPathToSavedPhotosAlbum(exporter.outputURL!.path!, nil, nil, nil)
                print("VideoMaskingUtils.exportVideo SUCCESS!")
                if exporter.error != nil {
                    print("VideoMaskingUtils.exportVideo Error: \(exporter.error)")
                    print("VideoMaskingUtils.exportVideo Description: \(exporter.description)")
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: exporter.error)
                break
            
            case .Exporting:
                let progress = exporter.progress
                print("VideoMaskingUtils.exportVideo \(progress)")
                
                NSNotificationCenter.defaultCenter().postNotificationName("videoExportProgress", object: progress)
                break
            
            case .Failed:
                print("VideoMaskingUtils.exportVideo Error: \(exporter.error)")
                print("VideoMaskingUtils.exportVideo Description: \(exporter.description)")
                
                NSNotificationCenter.defaultCenter().postNotificationName("videoExportDone", object: exporter.error)
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
