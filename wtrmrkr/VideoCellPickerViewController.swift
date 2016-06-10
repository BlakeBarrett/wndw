//
//  VideoCellPickerViewController.swift
//  wndw
//
//  Created by Blake Barrett on 6/7/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoCellPickerDelegate {
    func onFrameSelected(image: UIImage)
}

class VideoCellPickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var asset: AVAsset? {
        didSet {
            self.populateItemsWithVideoFrames()
        }
    }
    
    required init() {
        super.init(nibName: "VideoCellPicker", bundle: NSBundle.mainBundle())
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var delegate: VideoCellPickerDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        switch UIDevice.currentDevice().userInterfaceIdiom {
        case .Pad:
            self.tableView.estimatedRowHeight = 432.0
            break
        case .Phone:
            self.tableView.estimatedRowHeight = 180.0
            break
        default:
            self.tableView.estimatedRowHeight = 200.0
            break
        }
        
        self.tableView.reloadData()
    }
    
    // nobody else need see these
    private var selectedImage: UIImage?
    private var items = [UIImage]()
    
    // MARK: Thumbnail generation
    
    func populateItemsWithVideoFrames() {
        guard let asset = self.asset else { return }
        self.items = VideoMaskingUtils.thumbnailsFor(asset, howMany: 20)
        self.cellHeightFor(self.items.first)
    }
    
    func onFrameSelected() {
        guard let image = self.selectedImage else { return }
        delegate?.onFrameSelected(image)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: IBAction for "Save" button click.
    
    @IBAction func saveButtonClicked(sender: UIBarButtonItem) {
        self.onFrameSelected()
    }
    
    // MARK: TableView stuff
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("videoFrameCellReuseIdentifier", forIndexPath: indexPath) as? VideoCellPickerViewCell else { return UITableViewCell() }
        let item = items[indexPath.row]
        
        dispatch_async(dispatch_get_main_queue(), {
            cell.backgroundImageView.image = item
        })
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedImage = items[indexPath.row]
        self.onFrameSelected()
    }
    
    // variable row height
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeightFor(self.items.first)
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeightFor(self.items.first)
    }
    
    var estimatedRowHeight: CGFloat?
    func cellHeightFor(image: UIImage?) -> CGFloat {
        if let _ = self.estimatedRowHeight {
            return self.estimatedRowHeight!
        }
        
        let size = image?.size
        let width = size?.width
        let height = size?.height
        let aspectRatio = (width! / height!)
        
        var tableWidth: CGFloat
        if let _ = self.tableView {
            tableWidth = self.tableView.frame.width
        } else {
            tableWidth = (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad ? 768.0 : 320.0)
        }
        
        self.estimatedRowHeight =  (tableWidth / aspectRatio)
        return self.estimatedRowHeight!
    }
    
}
