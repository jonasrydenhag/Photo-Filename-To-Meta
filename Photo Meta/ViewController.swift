//
//  ViewController.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-19.
//  Copyright (c) 2015 Yasai, Inc. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  @IBOutlet weak var tableView: NSTableView!
  
  @IBAction func openFileDialog(sender: NSButton) {
    choosePath()
  }
  
  private let fileManager = NSFileManager.defaultManager()
  private let exifToolRunner = ExifToolRunner()
  private var reportObjects: [File] = []
  private var pathUrl: NSURL = NSURL()
  private var pathUrlIsDir: ObjCBool = false
  
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
    var selectedPath = myOpenDialog.URL
    
    // Make sure that a path was chosen
    if let selectedPath: NSURL = myOpenDialog.URL {
      var err = NSError?()
      
      if !(err != nil) {
        reportObjects = []
        pathUrl = selectedPath
        if fileManager.fileExistsAtPath(pathUrl.path!, isDirectory:&pathUrlIsDir) && !pathUrlIsDir {
          processFile(pathUrl)
          
        } else {
          let enumerator: NSDirectoryEnumerator? = fileManager.enumeratorAtURL(pathUrl, includingPropertiesForKeys: nil, options: nil, errorHandler: nil)
          
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
        let file = File(fileURL: URL, runner: exifToolRunner)
        if file.valid {
          file.process([Tag(name: Tag.TitleTag), Tag(name: Tag.DateTag)], keepExistingTags: false, overwriteFile: true)
        }
        self.reportObjects.append(file)
        self.tableView.reloadData()
      }
    }
  }
  
  // MARK: - Table View
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.reportObjects.count
  }
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var cellView = tableView.makeViewWithIdentifier("cell", owner: self) as! NSTableCellView
    
    if self.reportObjects.count > row {
      var file = self.reportObjects[row]
      var path: String = file.path
      
      if pathUrlIsDir {
        path = file.path.stringByReplacingOccurrencesOfString(pathUrl.path! + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
      } else {
        path = file.path.lastPathComponent.stringByDeletingPathExtension
      }
      
      cellView.textField!.stringValue = path
      
      if !file.valid {
        cellView.textField!.textColor = NSColor.redColor()
      } else {
        cellView.textField!.textColor = nil
      }
    }
    
    
    return cellView
  }
}
