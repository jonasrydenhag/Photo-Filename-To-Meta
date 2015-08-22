//
//  ViewController.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-19.
//  Copyright (c) 2015 Yasai, Inc. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

  @IBAction func openFileDialog(sender: NSButton) {
    choosePath()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  override var representedObject: AnyObject? {
    didSet {
      // Update the view, if already loaded.
    }
  }

  func choosePath() {
    
    var myOpenDialog: NSOpenPanel = NSOpenPanel()
    myOpenDialog.canChooseDirectories = true
    myOpenDialog.runModal()
    
    // Get the path to the file chosen in the NSOpenPanel
    var path = myOpenDialog.URL?.path
    
    // Make sure that a path was chosen
    if (path != nil) {
      var err = NSError?()
      
      println(path)
      let runner = ExifToolRunner()
      runner.runTool(path!)
      
     if !(err != nil) {
        NSLog(path!)
     }
    }
  }
}

