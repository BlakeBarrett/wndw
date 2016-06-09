//
//  ViewController.swift
//  wtrmrkr
//
//  Created by Blake Barrett on 5/23/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import MobileCoreServices

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, VideoCellPickerDelegate {

    @IBOutlet weak var watermarkThumbnailImage: UIImageView!
    @IBOutlet weak var videoThumbnailImageView: UIImageView!
    
    // sliders
    @IBOutlet weak var alphaSliderView: UISlider!
    @IBOutlet weak var scaleSliderView: UISlider!
    
    // labels
    @IBOutlet weak var alphaLabelView: UILabel!
    @IBOutlet weak var sizeLabelView: UILabel!
    
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
    
    func hideAlpha() {
        self.alphaSliderView.hidden = true
        self.alphaLabelView.hidden = true
    }
    
    func showAlpha() {
        self.alphaSliderView.hidden = false
        self.alphaLabelView.hidden = false
    }
    
    func hideSize() {
        self.sizeLabelView.hidden = true
        self.scaleSliderView.hidden = true
    }
    
    func showSize() {
        self.sizeLabelView.hidden = false
        self.scaleSliderView.hidden = false
    }
    
    var fullsizeWatermarkOriginalImage: UIImage?
    func onWatermarkImageSelected(image: UIImage) {
        self.fullsizeWatermarkOriginalImage = ImageMaskingUtils.reconcileImageOrientation(image)
        (self.watermarkThumbnailImage as? TouchableUIImageView)?.setOriginalImage(self.fullsizeWatermarkOriginalImage!)
        self.showAlpha()
        
        self.videoThumbnailImageView.hidden = true
    }
    
    var moviePath: NSURL? = nil
    func onVideoSelected(path: NSURL) {
        let thumbnail = VideoMaskingUtils.thumbnailImageForVideo(path)
        if self.moviePath == nil {
            self.moviePath = path
            self.videoThumbnailImageView.image = thumbnail
            self.showSize()
        }
    }
    
    func pickFrameForVideoAt(url: NSURL) {
        guard let videoCellPicker = self.storyboard?.instantiateViewControllerWithIdentifier("VideoCellPicker") as? VideoCellPickerViewController else { return }
        videoCellPicker.delegate = self
        videoCellPicker.asset = VideoMaskingUtils.getAVAssetAt(url)
        self.presentViewController(videoCellPicker, animated: true, completion: nil)
    }
    
    func onFrameSelected(image:UIImage) {
        let img = ImageMaskingUtils.reconcileImageOrientation(image)
        (self.watermarkThumbnailImage as? TouchableUIImageView)?.setOriginalImage(img)
        self.exportButtonView.enabled = true
    }
    
    func startOver() {
        self.moviePath = nil
        self.fullsizeWatermarkOriginalImage = nil
        self.videoThumbnailImageView.image = nil
        self.watermarkThumbnailImage.image = nil
        self.exportButtonView.enabled = false
        self.hideAlpha()
        self.hideSize()
    }
    
    @IBAction func onAlphaSliderValueChange(sender: UISlider) {
        self.overlayAlpha = Float(sender.value)
        self.watermarkThumbnailImage.alpha = CGFloat(self.overlayAlpha)
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
        
        NSNotificationCenter.defaultCenter().addObserverForName("videoExportDone", object: nil, queue: NSOperationQueue.mainQueue()) {message in
            self.hideSpinner()
            if let error = message.object {
                print(error)
            }
        }
        self.showSpinner()
        
        let image: UIImage = self.watermarkThumbnailImage.image!
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let rect = CGRectMake(0, 0, image.size.width, image.size.height)
            VideoMaskingUtils.overlay(video: video, withImage: image, andAlpha: self.overlayAlpha, atRect: rect, muted: false)
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
        
        let movieAction = UIAlertAction(title: "Video", style: .Default) { (action) in
            self.browseForMediaType([kUTTypeMovie as String])
        }
        
//        let imageAction = UIAlertAction(title: "Overlay", style: .Default) { (action) in
//            self.browseForMediaType([kUTTypeImage as String, kUTTypeMovie as String])
//        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            
        }
        
        alertController.addAction(movieAction)
//        alertController.addAction(imageAction)
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
        picker.allowsEditing = true
        self.presentViewController(picker, animated: true) { () -> Void in
            // no-op
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

        var path: NSURL?
        
        let mediaType = info[UIImagePickerControllerMediaType] as! CFString
        if (mediaType == kUTTypeImage) {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.onWatermarkImageSelected(image)
            }
        } else
        if (mediaType == kUTTypeMovie) {
            if let referenceUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {
                path = referenceUrl
                self.onVideoSelected(path!)
            }
        }
        
        self.exportButtonView.enabled = (self.watermarkThumbnailImage?.image != nil &&
            self.videoThumbnailImageView?.image != nil)
        
        picker.dismissViewControllerAnimated(true) { () -> Void in
            if let path = path {
                self.pickFrameForVideoAt(path)
            }
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

