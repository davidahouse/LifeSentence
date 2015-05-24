//
//  ViewController.swift
//  LifeSentence
//
//  Created by David House on 5/23/15.
//  Copyright (c) 2015 David House. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var simulation:GOL?
    var timer:NSTimer?
    
    @IBOutlet weak var golImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(animated: Bool) {
        
        // Create our game of life simulator and connect it to our image view
        simulation = GOL(width:100,height:100)
        simulation?.randomInitialState()
        simulation?.tick()
        if let iv = golImage {
            iv.image = simulation?.imageFromState()
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "tickSimulator", userInfo: nil, repeats: true);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tickSimulator() {
        simulation?.tick()
        if let iv = golImage {
            iv.image = simulation?.imageFromState()
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        simulation?.randomInitialState()
    }
    
}

