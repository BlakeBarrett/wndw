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
            print("Image generation failed with error \(error)")
            return nil
        }
    }
    
    class func getAVAssetAt(url: NSURL) -> AVURLAsset {
        return AVURLAsset(URL: url, options: nil)
    }
    
    class func overlay(video sourceVideo: AVURLAsset, withImage image: UIImage, atRect imageRect: CGRect?) {
        // compilation code
        let compiledVideo = AVMutableComposition()
        let trackVideo: AVMutableCompositionTrack = compiledVideo.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        //let trackAudio : AVMutableCompositionTrack = compiledVideo.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        let sourceDuration = CMTimeRangeMake(kCMTimeZero, sourceVideo.duration)
        
        guard let videoTrack: AVAssetTrack = (sourceVideo.tracksWithMediaType(AVMediaTypeVideo).first! as AVAssetTrack) else { return }
        //guard let audioTrack: AVAssetTrack = (sourceVideo.tracksWithMediaType(AVMediaTypeAudio).first! as AVAssetTrack) else { return }
        
        let renderWidth = videoTrack.naturalSize.width
        let renderHeight = videoTrack.naturalSize.height
        
        let renderSize = CGSizeMake(renderWidth, renderHeight)
        let layerRect: CGRect
        if let imageRect = imageRect {
            layerRect = imageRect
        } else {
            layerRect = CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight)
        }
        
        let insertTime = kCMTimeZero
        let endTime = sourceVideo.duration
        let range = sourceDuration
        
        do {
            try trackVideo.insertTimeRange(sourceDuration, ofTrack: videoTrack, atTime: insertTime)
        } catch _ {
            print("time range not inserted")
        }
        
        // Layer stuff
        let backgroundLayer = VideoMaskingUtils.createLayerFor(image)
        backgroundLayer.frame = layerRect
        backgroundLayer.opacity = 0.3
        
        let videoLayer = CALayer()
        videoLayer.frame = layerRect
        
        let parentLayer = CALayer()
        parentLayer.frame = layerRect
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(backgroundLayer)
        
        // Layer instruction stuff
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trackVideo)
        layerInstruction.setTransform(trackVideo.preferredTransform, atTime: insertTime)
        layerInstruction.setOpacity(0.0, atTime: endTime)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = range
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition(propertiesOfAsset: sourceVideo)
        videoComposition.renderScale = 1.0
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTimeMake(1, 30)
        videoComposition.instructions = [instruction]
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        
        let outputUrl = VideoMaskingUtils.getPathForTempFileNamed("output.mov")
        
        VideoMaskingUtils.exportVideo(compiledVideo, toURL: outputUrl, withComposition: videoComposition)
        
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
    
    private class func exportVideo(compiledVideo: AVMutableComposition, toURL outputUrl: NSURL, withComposition videoComposition: AVMutableVideoComposition) {
        guard let exporter = AVAssetExportSession(asset: compiledVideo, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = outputUrl
        exporter.videoComposition = videoComposition
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronouslyWithCompletionHandler({
            switch exporter.status {
            case AVAssetExportSessionStatus.Failed:
                if (exporter.error != nil) {
                    print("Error: \(exporter.error)")
                    print("Description: \(exporter.description)")
                }
                break
                
            case AVAssetExportSessionStatus.Completed:
                let path = exporter.outputURL!.path
                UISaveVideoAtPathToSavedPhotosAlbum(path!, nil, nil, nil)
                print("export succeeded")
                break
                
            default: break
            }
        })
    }
    
    class func createLayerFor(image: UIImage?) -> CALayer {
        let layer = CALayer()
        guard let image = image else {
            return layer
        }
        layer.contents = image.CGImage
        layer.frame = CGRectMake(0, 0, image.size.width / 2, image.size.height / 2)
        layer.opacity = 1.0
        layer.position = CGPointMake(0, -0)
        layer.zPosition = 0.7
        layer.masksToBounds = true
        return layer
    }

}
