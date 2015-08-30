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
  @IBOutlet weak var runBtn: NSButton!
  
  @IBAction func openFileDialog(sender: NSButton) {
    choosePath()
  }
  
  @IBAction func run(sender: NSButton) {
    run()
  }
  
  @IBAction func deleteCheck(sender: NSButton) {
    deleteTags = (sender.state == NSOnState)
  }
  
  private let fileManager = NSFileManager.defaultManager()
  private let exifToolRunner = ExifToolRunner()
  private var reportObjects: [File] = []
  private var pathUrl: NSURL = NSURL() {
    didSet {
      if pathUrl.path == nil {
        runBtn.enabled = false
      } else {
        runBtn.enabled = true
      }
    }
  }
  private var pathUrlIsDir: ObjCBool = false
  private var keepExistingTags = true
  private var deleteTags = false
  

  
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
    var clickedBtn = myOpenDialog.runModal()
    
    if clickedBtn == NSFileHandlingPanelOKButton {
      // Get the path to the file chosen in the NSOpenPanel
      var selectedPath = myOpenDialog.URL
      
      // Make sure that a path was chosen
      if let selectedPath: NSURL = myOpenDialog.URL {
        var err = NSError?()
        
        if !(err != nil) {
          reportObjects = []
          pathUrl = selectedPath
        }
      }
    }
  }

  func run() {
    if pathUrl.path != nil {
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
  
  func processFile(URL: NSURL) {
    if let path: String = URL.path {
      var isDir: ObjCBool = false
      if fileManager.fileExistsAtPath(path, isDirectory:&isDir) && !isDir && path.lastPathComponent != ".DS_Store" {
        let file = File(fileURL: URL, runner: exifToolRunner)
        if file.valid {
          if deleteTags {
            file.deleteValueFor([Tag(name: Tag.TitleTag), Tag(name: Tag.DateTag)], overwriteFile: true)
          } else {
            file.write([Tag(name: Tag.TitleTag), Tag(name: Tag.DateTag)], keepExistingTags: keepExistingTags, overwriteFile: true)
          }
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
    var cellView: NSTableCellView!
    var text = ""
    let showExistingData = (keepExistingTags || !deleteTags)
    
    if self.reportObjects.count > row {
      var file = self.reportObjects[row]
      
      if let columnID = tableColumn?.identifier {
        if columnID == "enum" {
          cellView = tableView.makeViewWithIdentifier("enumCell", owner: self) as! NSTableCellView
          text = "\(row + 1)"
          
        } else if columnID == "status" {
          cellView = tableView.makeViewWithIdentifier("statusCell", owner: self) as! NSTableCellView
          if !file.valid {
            cellView.textField?.backgroundColor = NSColor.grayColor()
            
          } else {
            cellView.textField?.backgroundColor = NSColor.greenColor()
            
            if keepExistingTags {
              for (tagName, tagValue) in file.originalTagValues {
                if tagValue != "" {
                  cellView.textField?.backgroundColor = NSColor.yellowColor()
                  break
                }
              }
            }
          }
          
        } else if columnID == "path" {
          cellView = tableView.makeViewWithIdentifier("pathCell", owner: self) as! NSTableCellView
          text = file.path
          if pathUrlIsDir {
            text = file.path.stringByReplacingOccurrencesOfString(pathUrl.path! + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
          } else {
            text = file.path.lastPathComponent
          }
          
        } else if columnID == "date" {
          cellView = tableView.makeViewWithIdentifier("dateCell", owner: self) as! NSTableCellView
          if !showExistingData {
            tableColumn?.hidden = true
            
          } else {
            tableColumn?.hidden = false
            if file.originalTagValues[Tag.DateTag] != nil {
              text = file.originalTagValues[Tag.DateTag]!
            }
          }
          
        } else if columnID == "title" {
          cellView = tableView.makeViewWithIdentifier("titleCell", owner: self) as! NSTableCellView
          if !showExistingData {
            tableColumn?.hidden = true
            
          } else {
            tableColumn?.hidden = false
            if file.originalTagValues[Tag.TitleTag] != nil {
              text = file.originalTagValues[Tag.TitleTag]!
            }
          }
        }
        
        cellView.textField?.stringValue = text
        
        if !file.valid {
          cellView.textField?.textColor = NSColor.grayColor()
        } else {
          cellView.textField?.textColor = nil
        }
      }
    }
    
    return cellView
  }
}
