//
//  ViewController.swift
//  wtrmrkr
//
//  Created by Blake Barrett on 5/23/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import MobileCoreServices

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var watermarkThumbnailImage: UIImageView!
    @IBOutlet weak var videoThumbnailImageView: UIImageView!
    
    // sliders
    @IBOutlet weak var alphaSliderView: UISlider!
    @IBOutlet weak var scaleSliderView: UISlider!
    @IBOutlet weak var xSliderView: UISlider!
    @IBOutlet weak var ySliderView: UISlider!
    
    @IBOutlet weak var exportButtonView: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func shouldAutorotate() -> Bool {
        return UIDevice.currentDevice().orientation == UIDeviceOrientation.Portrait
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    var fullsizeWatermarkOriginalImage: UIImage?
    func onWatermarkImageSelected(image: UIImage) {
        self.fullsizeWatermarkOriginalImage = ImageMaskingUtils.reconcileImageOrientation(image)
//        self.watermarkThumbnailImage.image = fullsizeWatermarkOriginalImage
        (self.watermarkThumbnailImage as? TouchableUIImageView)?.setOriginalImage(self.fullsizeWatermarkOriginalImage!)
    }
    
    var moviePath: NSURL? = nil
    var secondMoviePath: NSURL? = nil
    func onVideoSelected(path: NSURL) {
        let thumbnail = VideoMaskingUtils.thumbnailImageForVideo(path)
        if self.moviePath == nil {
            self.moviePath = path
            self.videoThumbnailImageView.image = thumbnail
        } else {
            self.secondMoviePath = path
            self.watermarkThumbnailImage.image = thumbnail
            (self.watermarkThumbnailImage as? TouchableUIImageView)?.setOriginalImage(ImageMaskingUtils.reconcileImageOrientation(thumbnail!))
        }
    }
    
    func startOver() {
        self.moviePath = nil
        self.secondMoviePath = nil
        self.fullsizeWatermarkOriginalImage = nil
        self.videoThumbnailImageView.image = nil
        self.watermarkThumbnailImage.image = nil
        self.exportButtonView.enabled = false
    }
    
    @IBAction func onAlphaSliderValueChange(sender: UISlider) {
        self.overlayAlpha = Float(sender.value)
//        self.watermarkThumbnailImage.alpha = CGFloat(self.overlayAlpha)
        self.brush.alpha = CGFloat(sender.value)
        (self.watermarkThumbnailImage as? TouchableUIImageView)?.brush.alpha = self.brush.alpha
    }
    
    @IBAction func onScaleSliderValueChange(sender: UISlider) {
        let value = CGFloat(sender.value)
        self.brush.width = value
        (self.watermarkThumbnailImage as? TouchableUIImageView)?.brush.width = self.brush.width
    }
    
    var brush = Brush()
    
    var overlayAlpha = Float(1.0)
    @IBAction func onExportButtonClick(sender: AnyObject) {
        
        guard let path = self.moviePath else { return }
        
        let video = VideoMaskingUtils.getAVAssetAt(path)
        let videoSize = self.videoThumbnailImageView.frame

        NSNotificationCenter.defaultCenter().addObserverForName("videoExportDone", object: nil, queue: NSOperationQueue.mainQueue()) {message in
            self.hideSpinner()
            if let error = message.object {
                print(error)
            }
        }
        self.showSpinner()
        
        let twoVideosOneCup = self.moviePath != nil && self.secondMoviePath != nil
        if twoVideosOneCup {
            
            guard let path2 = self.secondMoviePath else { return }
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                let secondVideo = VideoMaskingUtils.getAVAssetAt(path2)
                VideoMaskingUtils.overlay(video: video, withSecondVideo: secondVideo, andAlpha: self.overlayAlpha)
            }
        } else {
            let image: UIImage = self.watermarkThumbnailImage.image!
//            if self.fullsizeWatermarkOriginalImage != nil {
//                image = self.fullsizeWatermarkOriginalImage!
//            } else {
//                image = self.watermarkThumbnailImage.image!
//            }
            
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                let deets = ImageMaskingUtils.center(image, inFrame: videoSize)
                VideoMaskingUtils.overlay(video: video, withImage: deets.image, andAlpha: self.overlayAlpha, atRect: deets.rect)
            }
        }
        
    }
    
    @IBAction func onTrashButtonClick(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let destroyAction = UIAlertAction(title: "Reset", style: .Destructive) { (action) in
            self.startOver()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // no-op
        }
        
        alertController.addAction(destroyAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }

    }
    
    @IBAction func onOpenButtonClick(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let movieAction = UIAlertAction(title: "Movie", style: .Default) { (action) in
            self.browseForMediaType([kUTTypeMovie as String])
        }
        
        let imageAction = UIAlertAction(title: "Overlay", style: .Default) { (action) in
            self.browseForMediaType([kUTTypeImage as String, kUTTypeMovie as String])
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
        }
        
        alertController.addAction(movieAction)
        alertController.addAction(imageAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
    
    func browseForMediaType(mediaTypes: Array<String>) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        picker.mediaTypes = mediaTypes
        self.presentViewController(picker, animated: true) { () -> Void in
            // no-op
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

        let mediaType = info[UIImagePickerControllerMediaType] as! CFString
        if (mediaType == kUTTypeImage) {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.onWatermarkImageSelected(image)
            }
        } else if (mediaType == kUTTypeMovie) {
            if let referenceUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {
                self.onVideoSelected(referenceUrl)
            }
        }
        
        self.exportButtonView.enabled = (self.watermarkThumbnailImage?.image != nil &&
            self.videoThumbnailImageView?.image != nil)
        
        picker.dismissViewControllerAnimated(true) { () -> Void in
            // background thread
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                
            }
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }

    // MARK: Show Modal Loading Spinner
    var loadingIndicatorView: UIViewController?
    func showSpinner() {
        //LoadingIndicatorView
        if let loadingIndicatorView = self.storyboard?.instantiateViewControllerWithIdentifier("LoadingIndicatorView") {
            self.loadingIndicatorView = loadingIndicatorView
            loadingIndicatorView.modalPresentationStyle = .OverCurrentContext
            self.presentViewController(loadingIndicatorView, animated: true, completion: {
                
            })
        }
    }
    
    func hideSpinner() {
        guard let loadingIndicatorView = self.loadingIndicatorView else { return }
        loadingIndicatorView.dismissViewControllerAnimated(true, completion: {
            
        })
    }
}

