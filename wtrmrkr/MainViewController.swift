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
    
    @IBOutlet weak var alphaSliderView: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.alphaSliderView.enabled = false
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
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func onWatermarkImageSelected(image: UIImage) {
        self.watermarkThumbnailImage.image = image
    }
    
    var moviePath: NSURL? = nil
    func onVideoSelected(path: NSURL) {
        self.moviePath = path
        let thumbnail = VideoMaskingUtils.thumbnailImageForVideo(path)
        self.videoThumbnailImageView.image = thumbnail
    }
    
    @IBAction func onVideoThumbnailTap(sender: UITapGestureRecognizer) {
        self.browseForMediaType([kUTTypeMovie as String])
    }
    
    @IBAction func onWatermarkThumbnailTap(sender: UITapGestureRecognizer) {
        self.browseForMediaType([kUTTypeImage as String])
        self.alphaSliderView.enabled = true
    }
    
    
    @IBAction func onAlphaSliderValueChange(sender: UISlider) {
        self.overlayAlpha = Float(sender.value)
        self.watermarkThumbnailImage.alpha = CGFloat(self.overlayAlpha)
    }
    
    var overlayAlpha = Float(1.0)
    @IBAction func onExportButtonClick(sender: UIButton) {
        guard let image = self.watermarkThumbnailImage.image else { return }
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

