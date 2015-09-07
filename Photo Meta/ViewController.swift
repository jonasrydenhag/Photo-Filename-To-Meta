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
  @IBOutlet weak var deleteBtn: NSButton!
  @IBOutlet weak var readBtn: NSButton!
  @IBOutlet weak var writeBtn: NSButton!
  @IBOutlet weak var keepCheckBtn: NSButton!
  @IBOutlet weak var tagCheckTitle: NSButton!
  @IBOutlet weak var tagCheckDate: NSButton!
  @IBOutlet weak var overwriteCheck: NSButton!
  @IBOutlet weak var targetSelectBtn: NSButton!
  @IBOutlet weak var sourceTextField: NSTextField!
  @IBOutlet weak var targetTextField: NSTextField!
  @IBOutlet weak var targetTextFieldLabel: NSTextField!
  
  @IBAction func selectSourceDialog(sender: NSButton) {
    if let selectedPath = choosePath() {
      collectFilesFrom(selectedPath)
    }
  }
  
  @IBAction func selectTargetDialog(sender: NSButton) {
    if let selectedPath = choosePath(canChooseFiles: false) {
      targetUrl = selectedPath
    }
  }
  
  @IBAction func tagCheckClick(sender: NSButton) {
    if sourceUrl.path != nil {
      collectFilesFrom(sourceUrl)
    }
    setOutletsEnableState()
  }
  
  @IBAction func overwriteCheckClick(sender: NSButton) {
    setOutletsEnableState()
  }
  
  @IBAction func read(sender: NSButton) {
    mode = ViewController.readMode
    run(filesInUrl, tags: selectedTags, readTags: true)
  }
  
  @IBAction func write(sender: NSButton) {
    mode = ViewController.writeMode
    run(filesInUrl, tags: selectedTags, keepExistingTags: (keepCheckBtn.state == NSOnState))
  }
  
  @IBAction func delete(sender: NSButton) {
    mode = ViewController.writeMode
    run(filesInUrl, tags: selectedTags, keepExistingTags: false, deleteTags: true)
  }
  
  private let exifToolRunner = ExifToolRunner()
  private let fileManager = NSFileManager.defaultManager()
  private var collectedFilesBaseUrl: NSURL = NSURL() {
    didSet {
      var value: String
      if collectedFilesBaseUrl.path != nil {
        value = collectedFilesBaseUrl.path!.stringByReplacingOccurrencesOfString(NSHomeDirectory() + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
      } else {
        value = ""
      }
      sourceTextField.stringValue = value
    }
  }
  private var sourceUrl: NSURL = NSURL() {
    didSet {
      setOutletsEnableState()
    }
  }
  private var targetUrl: NSURL = NSURL() {
    didSet {
      setOutletsEnableState()
      var value: String
      if targetUrl.path != nil {
        value = targetUrl.path!.stringByReplacingOccurrencesOfString(NSHomeDirectory() + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
      } else {
        value = ""
      }
      targetTextField.stringValue = value
    }
  }
  private var baseUrlIsDir: ObjCBool = false
  private var filesInUrl: [File] = []
  private var processedFiles: [File] = []
  private static let listMode = "list"
  private static let readMode = "read"
  private static let writeMode = "write"
  private var mode = listMode
  private var selectedTags: [Tag] {
    get {
      var checkedTags = [Tag]()
      if tagCheckTitle.state == NSOnState {
        checkedTags.append(Tag(name: Tag.TitleTag))
      }
      if tagCheckDate.state == NSOnState {
        checkedTags.append(Tag(name: Tag.DateTag))
      }
      return checkedTags
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
  
  private func setOutletsEnableState() {
    if sourceUrl.path != nil && selectedTags.count > 0 {
      readBtn.enabled = true
    } else {
      readBtn.enabled = false
    }
    
    if sourceUrl.path != nil && (overwriteCheck.state == NSOnState || targetUrl.path != nil) {
      deleteBtn.enabled = true
      writeBtn.enabled = true
      
      if selectedTags.count == 0 {
        deleteBtn.enabled = false
        writeBtn.enabled = false
      }
      
    } else {
      deleteBtn.enabled = false
      writeBtn.enabled = false
    }
    
    if overwriteCheck.state == NSOnState {
      targetSelectBtn.enabled = false
      targetTextField.enabled = false
      targetTextFieldLabel.textColor = NSColor.grayColor()
    } else {
      targetSelectBtn.enabled = true
      targetTextField.enabled = true
      targetTextFieldLabel.textColor = nil
    }
  }

  func choosePath(canChooseFiles: Bool = true) -> NSURL? {
    var selectedPath: NSURL?
    var myOpenDialog: NSOpenPanel = NSOpenPanel()
    myOpenDialog.canChooseDirectories = true
    myOpenDialog.canChooseFiles = canChooseFiles
    var clickedBtn = myOpenDialog.runModal()
    
    if clickedBtn == NSFileHandlingPanelOKButton {
      // Make sure that a path was chosen
      if let selectedPath: NSURL = myOpenDialog.URL {
        var err = NSError?()
        
        if !(err != nil) {
          return selectedPath
        }
      }
    }
    return selectedPath
  }
  
  func collectFilesFrom(URL: NSURL) {
    collectedFilesBaseUrl = URL
    sourceUrl = URL
    targetUrl = NSURL()
    mode = ViewController.listMode
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
  
  private func run(files: [File], tags: [Tag], keepExistingTags: Bool = true, readTags: Bool = false, deleteTags: Bool = false, process: Bool = true) {
    if process {
      processedFiles = []
    }
    var kept: [String: [File]] = [String : [File]]()
    toggleColumnVisibility(tableView, tags: selectedTags)
    
    for file in files {
      if fileManager.fileExistsAtPath(file.path) {
        if file.valid {
          if readTags {
            file.read(tags)
            
          } else {
            if overwriteCheck.state == NSOffState {
              if !copy(file, toDir: targetUrl) {
                break
              }
            }
            
            if deleteTags {
              file.deleteValueFor(tags)
              
            } else {
              file.write(tags, keepExistingTags: keepExistingTags)
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
        }
        if process {
          processedFiles.append(file)
        }
        tableView.reloadData()
      }
    }
    
    if overwriteCheck.state == NSOffState && targetUrl.path != nil {
      sourceUrl = targetUrl
    }
    
    for tagName in kept.keys {
      overwrite(kept[tagName]!, tag: Tag(name: tagName))
    }
  }
  
  private func prepareCopyDestPath(file: File, fromBase: NSURL, toDir: NSURL) -> String? {
    var fromBaseDir: ObjCBool = false
    var destPath: String?
    
    if fileManager.fileExistsAtPath(fromBase.path!, isDirectory:&fromBaseDir) {
      var diffFromBase = file.path.stringByReplacingOccurrencesOfString(fromBase.path! + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
      var targetPath = toDir.path! + "/"
      destPath = targetPath + file.path.lastPathComponent
      
      if fromBaseDir {
        
        for component in diffFromBase.pathComponents {
          if component != file.path.lastPathComponent {
            targetPath += component + "/"
          }
        }
        
        destPath = targetPath + file.path.lastPathComponent
        
        if destPath != file.path {
          var targetPathDir: ObjCBool = false
          if fileManager.fileExistsAtPath(targetPath, isDirectory:&targetPathDir) && !targetPathDir {
            var targetPathRemove: NSError?
            fileManager.removeItemAtPath(targetPath, error: &targetPathRemove)
            
            if targetPathRemove != nil {
              return nil
            }
          }
          
          var create: NSError?
          fileManager.createDirectoryAtPath(targetPath, withIntermediateDirectories: true, attributes: nil, error: &create)
          
          if create != nil {
            return nil
          }
        }
      }
      
      if destPath != file.path {
        if fileManager.fileExistsAtPath(destPath!) {
          var targetPathRemove: NSError?
          fileManager.removeItemAtPath(destPath!, error: &targetPathRemove)
          
          if targetPathRemove != nil {
            return nil
          }
        }
      }
    }
    return destPath
  }
  
  private func copy(file: File, toDir: NSURL) -> Bool {
    var error: NSError?
    
    if let toDirPath = toDir.path {
      var isDir: ObjCBool = false
      if fileManager.fileExistsAtPath(toDirPath, isDirectory:&isDir) && isDir {
        if fileManager.fileExistsAtPath(file.path) {
          if let destPath = prepareCopyDestPath(file, fromBase: sourceUrl, toDir: targetUrl) {
            if destPath != file.path {
              if fileManager.copyItemAtPath(file.path, toPath: destPath, error: &error){
                file.URL = NSURL(fileURLWithPath: destPath)!
                return true
              }
            } else {
              return true
            }
          }
        }
      }
    }
    return false
  }
  
  private func toggleColumnVisibility(tableView: NSTableView, tags: [Tag] = []) {
    var column = tableView.columnWithIdentifier("status")
    
    for column in tableView.tableColumns {
      if let column = column as? NSTableColumn {
        
        switch column.identifier {
        case "enum", "path":
            column.hidden = false
          
        case "status":
          if mode == ViewController.writeMode {
            column.hidden = false
          } else {
            column.hidden = true
          }
          
        default:
          column.hidden = true
          for tag in tags {
            if column.identifier == tag.name && mode != ViewController.listMode {
              column.hidden = false
            }
          }
        }
      }
    }
  }
  
  // MARK: - Table View
  
  func tableObjects() -> [File] {
    return mode == ViewController.listMode ? filesInUrl : processedFiles
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
            let basePath: String = targetUrl.path == nil || !file.valid ? collectedFilesBaseUrl.path! : targetUrl.path!
            text = file.path.stringByReplacingOccurrencesOfString(basePath + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
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
