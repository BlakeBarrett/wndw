//
//  ProgressViewController.swift
//  wtrmrkr
//
//  Created by Blake Barrett on 5/27/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import UIKit

class ProgressViewController: UIViewController {
    
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    @IBOutlet weak var progressBarView: UIProgressView!
    
    override func viewDidLoad() {
        
        progressBarView.hidden = true
        
        NSNotificationCenter.defaultCenter().addObserverForName("videoExportProgress", object: nil, queue: NSOperationQueue.mainQueue()) {value in
            
            self.spinnerView.hidden = true
            self.progressBarView.hidden = false
            
            let progress = (value.object as! Float)
            self.progressBarView.setProgress(progress, animated: true)
        }
    }
    
}
