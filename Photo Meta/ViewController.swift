//
//  ViewController.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-19.
//  Copyright (c) 2015 Yasai, Inc. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
  
  private let fileManager = NSFileManager.defaultManager()
  private let exifToolRunner = ExifToolRunner()

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
    var pathURL = myOpenDialog.URL
    
    // Make sure that a path was chosen
    if let pathURL: NSURL = myOpenDialog.URL {
      var err = NSError?()
      
      if !(err != nil) {
        var isDir: ObjCBool = false
        if fileManager.fileExistsAtPath(pathURL.path!, isDirectory:&isDir) && !isDir {
          processFile(pathURL)
          
        } else {
          let enumerator: NSDirectoryEnumerator? = fileManager.enumeratorAtURL(pathURL, includingPropertiesForKeys: nil, options: nil, errorHandler: nil)
          
          while let fileURL: NSURL = enumerator?.nextObject() as? NSURL {
            processFile(fileURL)
          }
        }
      }
    }
  }
  
  func processFile(URL: NSURL) {
    if let path: String = URL.path {
      var isDir: ObjCBool = false
      if fileManager.fileExistsAtPath(path, isDirectory:&isDir) && !isDir {
        if File.fileTypeConfomsTo(path, types: [kUTTypeJPEG, kUTTypeGIF, kUTTypeTIFF]) {
          let file = File(fileURL: URL, runner: exifToolRunner)
          file.process([Tag(name: "title")])
        }
      }
    }
  }
}
