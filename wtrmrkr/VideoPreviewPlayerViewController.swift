//
//  VideoPreviewPlayerViewController.swift
//  wndw
//
//  Created by Blake Barrett on 6/9/16.
//  Copyright © 2016 Blake Barrett. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

class VideoPreviewPlayerViewController: UIViewController {
    
    var url :NSURL?
    var player :AVPlayer?
    
    override func viewDidLoad() {
        guard let url = url else { return }
        self.player = AVPlayer(URL: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        self.addChildViewController(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
    }
    
    override func viewDidAppear(animated: Bool) {
        player?.play()
    }
}
