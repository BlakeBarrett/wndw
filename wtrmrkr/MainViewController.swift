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
        // Dispose of any resources that can be recreated.
    }

    override func shouldAutorotate() -> Bool {
        return UIDevice.currentDevice().orientation == UIDeviceOrientation.Portrait
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
//    override func prefersStatusBarHidden() -> Bool {
//        return true
//    }
    
    var fullsizeWatermarkOriginalImage: UIImage?
    func onWatermarkImageSelected(image: UIImage) {
        fullsizeWatermarkOriginalImage = image
        self.watermarkThumbnailImage.image = image
    }
    
    var moviePath: NSURL? = nil
    func onVideoSelected(path: NSURL) {
        self.moviePath = path
        let thumbnail = VideoMaskingUtils.thumbnailImageForVideo(path)
        self.videoThumbnailImageView.image = thumbnail
    }
    
    @IBAction func onAlphaSliderValueChange(sender: UISlider) {
        self.overlayAlpha = Float(sender.value)
        self.watermarkThumbnailImage.alpha = CGFloat(self.overlayAlpha)
    }
    
    @IBAction func onScaleSliderValueChange(sender: UISlider) {
        
        let img = self.fullsizeWatermarkOriginalImage!
        self.watermarkThumbnailImage.image = UIImage(CGImage: img.CGImage!, scale: img.scale * CGFloat(sender.value), orientation: img.imageOrientation)
    }
    
    @IBAction func onXSliderValueChange(sender: UISlider) {
        
    }
    
    @IBAction func onYSliderValueChange(sender: UISlider) {
    }
    
    func aspectFit(image: UIImage, inRect rect: CGRect) {
        
    }
    
    var overlayAlpha = Float(1.0)
    @IBAction func onExportButtonClick(sender: AnyObject) {
        guard let image = self.fullsizeWatermarkOriginalImage else { return }
        guard let path = self.moviePath else { return }
        let video = VideoMaskingUtils.getAVAssetAt(path)
        
        let videoSize = self.videoThumbnailImageView.image?.size
        let img = ImageMaskingUtils.fit(image, inSize: videoSize!)

        let width = img.size.width
        let height = img.size.height
        let left = (videoSize!.width - width) / 2
        let top = (videoSize!.height - height) / 2

        let centeredInVideoFrame = CGRectMake(left, top, width, height)
        
        
        NSNotificationCenter.defaultCenter().addObserverForName("videoExportDone", object: nil, queue: NSOperationQueue.mainQueue()) {message in
            self.hideSpinner()
            if let error = message.object {
                print(error)
            }
        }
        self.showSpinner()
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            VideoMaskingUtils.overlay(video: video, withImage: img, andAlpha: self.overlayAlpha, atRect: centeredInVideoFrame)
        }
    }
    
    @IBAction func onOpenButtonClick(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let movieAction = UIAlertAction(title: "Movie", style: .Default) { (action) in
            self.browseForMediaType([kUTTypeMovie as String])
        }
        
        let imageAction = UIAlertAction(title: "Overlay", style: .Default) { (action) in
            self.browseForMediaType([kUTTypeImage as String])
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

