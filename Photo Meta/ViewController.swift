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
  @IBOutlet weak var deleteBtn: NSButton!
  @IBOutlet weak var keepCheckBtn: NSButton!
  
  @IBAction func openFileDialog(sender: NSButton) {
    choosePath()
  }
  
  @IBAction func run(sender: NSButton) {
    run(filesInUrl, tags: selectedTags, keepExistingTags: (keepCheckBtn.state == NSOnState))
  }
  
  @IBAction func delete(sender: NSButton) {
    run(filesInUrl, tags: selectedTags, keepExistingTags: false, deleteTags: true)
  }
  
  private let exifToolRunner = ExifToolRunner()
  private let fileManager = NSFileManager.defaultManager()
  private var baseUrl: NSURL = NSURL()
  private var baseUrlIsDir: ObjCBool = false
  private var filesInUrl: [File] = []
  private var processedFiles: [File] = []
  private var runMode = false
  private var selectedTags: [Tag] = [Tag(name: Tag.TitleTag), Tag(name: Tag.DateTag)]
  
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
          collectFilesFrom(selectedPath)
          runBtn.enabled = true
          deleteBtn.enabled = true
        }
      }
    }
  }
  
  func collectFilesFrom(URL: NSURL) {
    baseUrl = URL
    filesInUrl = []
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
        filesInUrl.append(file)
      }
    }
  }
  
  private func run(files: [File], tags: [Tag], keepExistingTags: Bool = true, deleteTags: Bool = false, process: Bool = true) {
    runMode = true
    if process {
      processedFiles = []
    }
    var kept: [String: [File]] = [String : [File]]()
    toggleColumnVisibility(tableView, runMode: runMode, tags: selectedTags)
    
    for file in files {
      if fileManager.fileExistsAtPath(file.path) {
        if file.valid {
          if deleteTags {
            file.deleteValueFor(tags, overwriteFile: true)
          } else {
            file.write(tags, keepExistingTags: keepExistingTags, overwriteFile: true)
            if keepExistingTags && file.kept.count > 0 {
              for tag in file.kept {
                if kept[tag.name] == nil {
                   kept[tag.name] = []
                }
                kept[tag.name]!.append(file)
              }
            }
          }
        }
        if process {
          processedFiles.append(file)
        }
        tableView.reloadData()
      }
    }
    
    for tagName in kept.keys {
      overwrite(kept[tagName]!, tag: Tag(name: tagName))
    }
  }
  
  private func toggleColumnVisibility(tableView: NSTableView, runMode: Bool = false, tags: [Tag] = []) {
    var column = tableView.columnWithIdentifier("status")
    
    for column in tableView.tableColumns {
      if let column = column as? NSTableColumn {
        
        switch column.identifier {
        case "enum", "path":
            column.hidden = false
          
        case "status":
          if runMode {
            column.hidden = false
          } else {
            column.hidden = true
          }
          
        default:
          column.hidden = true
          for tag in tags {
            if column.identifier == tag.name && runMode {
              column.hidden = false
            }
          }
        }
      }
    }
  }
  
  // MARK: - Table View
  
  func tableObjects() -> [File] {
    return runMode ? processedFiles : filesInUrl
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
            
            if !file.allInitialValuesUpdated() {
              cellView.textField?.backgroundColor = NSColor.yellowColor()
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
          if file.tagValues[Tag.DateTag] != nil {
            text = file.tagValues[Tag.DateTag]!
          }
          
        } else if columnID == "title" {
          cellView = tableView.makeViewWithIdentifier("titleCell", owner: self) as! NSTableCellView
          if file.tagValues[Tag.TitleTag] != nil {
            text = file.tagValues[Tag.TitleTag]!
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
  
  // MARK: - Alert
  
  func overwrite(files: [File], tag: Tag) {
    var alert = NSAlert()
    alert.addButtonWithTitle("Yes")
    alert.addButtonWithTitle("No")
    alert.messageText = "Existing values for the \(tag.name) tag"
    var fileEnum = (files.count == 1) ? "file" : "files"
    alert.informativeText = "\(files.count) \(fileEnum) already have a values. Do you want to overwrite?"
    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
    
    let result = alert.runModal()
    if result == NSAlertFirstButtonReturn {
      run(files, tags: [tag], keepExistingTags: false, process: false)
    }
  }
}
