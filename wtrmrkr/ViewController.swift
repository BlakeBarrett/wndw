//
//  ViewController.swift
//  wtrmrkr
//
//  Created by Blake Barrett on 5/23/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var watermarkThumbnailImage: UIImageView!
    @IBOutlet weak var videoThumbnailImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
    }
    
    @IBAction func onExportButtonClick(sender: UIButton) {
        let image = self.watermarkThumbnailImage.image!
        let video = VideoMaskingUtils.getAVAssetAt(self.moviePath!)
        VideoMaskingUtils.overlay(video: video, withImage: image, atRect: nil)
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

}

