//
//  ViewController.swift
//  streamingIPCamera
//
//  Created by Mattia Cantalù on 24/12/2016.
//  Copyright © 2016 Mattia Cantalù. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var imageView : UIImageView!
    
    var player : RTSPPlayer?
    var camUrl = "rtsp://[username]:[password]@[ip]:[port]/videoMain"
    var lastTimeFrame = -1.0
    var nextFrameTimer = Timer()
    var nextFrameTimerTmp = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareStreaming()
    }

    //MARK: - Streaming

    //Setup
    func prepareStreaming() {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        //Add dispatch async to avoid ui issues
        let backgroundQueue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        backgroundQueue.async(execute: {
            
            self.player = RTSPPlayer(video: self.camUrl, usesTcp: true)
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                //Check if streaming exists
                if (self.player == nil) {
                    NSLog("Player failed to load")
                    return
                }
                
                self.player?.outputWidth = 1920
                self.player?.outputHeight = 1080
                self.imageView.contentMode = UIViewContentMode.scaleAspectFit
                
                self.startStream()
                activityIndicator.stopAnimating()
            })
        })
    }
    
    //Start
    func startStream() {
        self.player?.seekTime(0.0)
        self.nextFrameTimer.invalidate()
        self.nextFrameTimer = Timer.scheduledTimer(timeInterval: 1.0/30, target: self, selector: #selector(ViewController.displayNextFrame(_:)), userInfo: nil, repeats: true)
    }
    
    //Setup frame overview
    func displayNextFrame(_ timer : Timer) {
        self.nextFrameTimerTmp = timer
        let startTime : TimeInterval = Date.timeIntervalSinceReferenceDate
        if ([self.player? .stepFrame()] == nil) {
            NSLog("Stream not available")
            self.nextFrameTimerTmp.invalidate()
            self.player?.closeAudio()
            return
        }
        
        self.imageView.image = self.player?.currentImage;
        let frameTime = 1.0/(Date.timeIntervalSinceReferenceDate - startTime)
        if (self.lastTimeFrame < 0) {
            self.lastTimeFrame = frameTime
        }
        else {
            self.lastTimeFrame = (frameTime*(1.0-0.8) + self.lastTimeFrame*0.8)
        }
    }
    
    deinit {
        if (self.player != nil) {
            self.nextFrameTimerTmp.invalidate()
            self.nextFrameTimer.invalidate()
            self.player?.closeAudio()
            self.player = nil
            NSLog("Dealloc player")
        }
    }
}

