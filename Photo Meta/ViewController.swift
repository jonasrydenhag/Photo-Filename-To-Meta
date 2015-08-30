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
  @IBOutlet weak var deleteCheckBtn: NSButton!
  
  @IBAction func openFileDialog(sender: NSButton) {
    choosePath()
  }
  
  @IBAction func run(sender: NSButton) {
    run()
  }
  
  @IBAction func deleteCheck(sender: NSButton) {
    deleteTags = (sender.state == NSOnState)
  }
  
  private let exifToolRunner = ExifToolRunner()
  private let fileManager = NSFileManager.defaultManager()
  private var baseUrl: NSURL = NSURL()
  private var baseUrlIsDir: ObjCBool = false
  private var files: [File] = []
  private var reportObjects: [File] = []
  private var runMode = false
  
  private var keepExistingTags = true
  private var deleteTags = false {
    didSet {
      if deleteTags {
        deleteCheckBtn.state = NSOnState
      } else {
        deleteCheckBtn.state = NSOffState
      }
    }
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
    var clickedBtn = myOpenDialog.runModal()
    
    if clickedBtn == NSFileHandlingPanelOKButton {
      // Get the path to the file chosen in the NSOpenPanel
      var selectedPath = myOpenDialog.URL
      
      // Make sure that a path was chosen
      if let selectedPath: NSURL = myOpenDialog.URL {
        var err = NSError?()
        
        if !(err != nil) {
          deleteTags = false
          collectFilesFrom(selectedPath)
          runBtn.enabled = true
        }
      }
    }
  }
  
  func collectFilesFrom(URL: NSURL) {
    baseUrl = URL
    files = []
    if URL.path != nil {
      if fileManager.fileExistsAtPath(URL.path!, isDirectory:&baseUrlIsDir) && !baseUrlIsDir {
        addFileIn(URL)
        
      } else {
        let enumerator: NSDirectoryEnumerator? = fileManager.enumeratorAtURL(URL, includingPropertiesForKeys: nil, options: nil, errorHandler: nil)
        
        while let fileURL: NSURL = enumerator?.nextObject() as? NSURL {
          addFileIn(fileURL)
        }
      }
    }
    runMode = false
    toggleColumnVisibility(tableView)
    tableView.reloadData()
  }
  
  private func addFileIn(URL: NSURL) {
    if let path: String = URL.path {
      var isDir: ObjCBool = false
      if fileManager.fileExistsAtPath(path, isDirectory:&isDir) && !isDir && path.lastPathComponent != ".DS_Store" {
        let file = File(fileURL: URL, runner: exifToolRunner)
        files.append(file)
      }
    }
  }
  
  private func run() {
    runMode = true
    reportObjects = []
    toggleColumnVisibility(tableView)
    for file in files {
      if fileManager.fileExistsAtPath(file.path) {
        if file.valid {
          if deleteTags {
            file.deleteValueFor([Tag(name: Tag.TitleTag), Tag(name: Tag.DateTag)], overwriteFile: true)
          } else {
            file.write([Tag(name: Tag.TitleTag), Tag(name: Tag.DateTag)], keepExistingTags: keepExistingTags, overwriteFile: true)
          }
        }
        reportObjects.append(file)
        tableView.reloadData()
      }
    }
  }
  
  private func toggleColumnVisibility(tableView: NSTableView) {
    let showExistingData = runMode && (keepExistingTags || !deleteTags)
    var column = tableView.columnWithIdentifier("status")
    
    for column in tableView.tableColumns {
      if let column = column as? NSTableColumn {
        
        switch column.identifier {
        case "status":
          if runMode {
            column.hidden = false
          } else {
            column.hidden = true
          }

        case "date", "title":
          if showExistingData {
            column.hidden = false
          } else {
            column.hidden = true
          }
          
        default: ()
        }
      }
    }
  }
  
  // MARK: - Table View
  
  func tableObjects() -> [File] {
    if runMode {
      return reportObjects
    } else {
      return files
    }
  }
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return tableObjects().count
  }
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var cellView: NSTableCellView!
    var text = ""
    
    if tableObjects().count > row {
      var file = tableObjects()[row]
      
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
          if baseUrlIsDir {
            text = file.path.stringByReplacingOccurrencesOfString(baseUrl.path! + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
          } else {
            text = file.path.lastPathComponent
          }
          
        } else if columnID == "date" {
          cellView = tableView.makeViewWithIdentifier("dateCell", owner: self) as! NSTableCellView
          if file.originalTagValues[Tag.DateTag] != nil {
            text = file.originalTagValues[Tag.DateTag]!
          }
          
        } else if columnID == "title" {
          cellView = tableView.makeViewWithIdentifier("titleCell", owner: self) as! NSTableCellView
          if file.originalTagValues[Tag.TitleTag] != nil {
            text = file.originalTagValues[Tag.TitleTag]!
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
