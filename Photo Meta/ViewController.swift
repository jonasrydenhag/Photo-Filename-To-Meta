//
//  ViewController.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-19.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Cocoa

enum PathExceptions: ErrorType {
  case TargetURLNotDir
}

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var deleteBtn: NSButton!
  @IBOutlet weak var cancelBtn: NSButton!
  @IBOutlet weak var readBtn: NSButton!
  @IBOutlet weak var writeBtn: NSButton!
  @IBOutlet weak var keepCheckBtn: NSButton!
  @IBOutlet weak var tagCheckTitle: NSButton!
  @IBOutlet weak var tagCheckDate: NSButton!
  @IBOutlet weak var overwriteCheck: NSButton!
  @IBOutlet weak var sourceTextField: NSTextField!
  @IBOutlet weak var targetTextField: NSTextField!
  @IBOutlet weak var targetTextFieldLabel: NSTextField!
  
  @IBAction func tagCheckClick(sender: NSButton) {
    if sourceUrl.path != nil {
      collectFilesFrom(sourceUrl)
    }
    setOutletsEnableState()
  }
  
  @IBAction func cancelBtnClick(sender: NSButton) {
    cancelRun = true
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
  
  @IBAction func selectPaths(sender: AnyObject) {
    openSelectPaths()
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
  private (set) var sourceUrl: NSURL = NSURL() {
    didSet {
      setOutletsEnableState()
    }
  }
  var targetUrl: NSURL = NSURL() {
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
  private var files: [File] = []
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
  private var cancelRun = false
  
  override func viewDidAppear() {
    super.viewDidAppear()
    openSelectPaths()
  }
  
  private func openSelectPaths() {
    self.performSegueWithIdentifier("selectPaths", sender: self)
  }
  
  override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
    if let pathsController: PathsController = segue.destinationController as? PathsController {
      pathsController.caller = self
    }
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
      targetTextField.enabled = false
      targetTextFieldLabel.textColor = NSColor.grayColor()
    } else {
      targetTextField.enabled = true
      targetTextFieldLabel.textColor = nil
    }
    
    overwriteCheck.enabled = true
    
    keepCheckBtn.enabled = true
    tagCheckTitle.enabled = true
    tagCheckDate.enabled = true
    
    cancelBtn.enabled = false
  }
  
  private func disableAllOutlets(exceptions: [NSControl] = []) {
    readBtn.enabled = false
    deleteBtn.enabled = false
    writeBtn.enabled = false
  
    keepCheckBtn.enabled = false
    tagCheckTitle.enabled = false
    tagCheckDate.enabled = false
    
    cancelBtn.enabled = false
    
    for control in exceptions {
      control.enabled = true
    }
  }

  func choosePath(canChooseFiles: Bool = true, canCreateDirectories: Bool = false) -> NSURL? {
    let myOpenDialog: NSOpenPanel = NSOpenPanel()
    myOpenDialog.canChooseDirectories = true
    myOpenDialog.canChooseFiles = canChooseFiles
    myOpenDialog.canCreateDirectories = canCreateDirectories
    let clickedBtn = myOpenDialog.runModal()
    
    if clickedBtn == NSFileHandlingPanelOKButton {
      // Make sure that a path was chosen
      if let selectedPath: NSURL = myOpenDialog.URL {
        let err = NSError?()
        
        if !(err != nil) {
          return selectedPath
        }
      }
    }
    return nil
  }
  
  func collectFilesFrom(URL: NSURL) {
    collectedFilesBaseUrl = URL
    sourceUrl = URL
    mode = ViewController.listMode
    filesInUrl = []
    if URL.path != nil {
      if fileManager.fileExistsAtPath(URL.path!, isDirectory:&baseUrlIsDir) && !baseUrlIsDir {
        addFileIn(URL)
        
      } else {
        let enumerator: NSDirectoryEnumerator? = fileManager.enumeratorAtURL(URL, includingPropertiesForKeys: nil, options: [], errorHandler: nil)
        
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
      if fileManager.fileExistsAtPath(path, isDirectory:&isDir) && !isDir && URL.lastPathComponent != ".DS_Store" {
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
    
    disableAllOutlets([cancelBtn])
    
    dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
      for file in files {
        if self.cancelRun {
          break
        }
        if self.fileManager.fileExistsAtPath(file.URL.path!) {
          if file.valid {
            if readTags {
              file.read(tags)
              
            } else {
              if self.overwriteCheck.state == NSOffState {
                if !self.copy(file, toDir: self.targetUrl) {
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
          
          dispatch_async(dispatch_get_main_queue()) {
            if process {
              self.processedFiles.append(file)
            }
            self.tableView.reloadData()
          }
        }
      }
      
      if self.cancelRun {
        self.disableAllOutlets()
        
      } else {
        self.setOutletsEnableState()
        
        if self.overwriteCheck.state == NSOffState && self.targetUrl.path != nil {
          self.sourceUrl = self.targetUrl
        }
        
        for tagName in kept.keys {
          self.overwrite(kept[tagName]!, tag: Tag(name: tagName))
        }
      }
      
      self.cancelRun = false
    }
  }
  
  private func prepareCopyDestPath(file: File, toDir: NSURL) throws -> String {
    var fromBaseDir: ObjCBool = false
    var destPath: String
    let relativeFilePath = file.relativePath
    let relativeURL = NSURL(fileURLWithPath: relativeFilePath, isDirectory: false)
    
    fileManager.fileExistsAtPath(file.URL.path!, isDirectory:&fromBaseDir)
    
    var targetPath = toDir.path! + "/"
    destPath = targetPath + relativeFilePath
    
    if relativeURL.URLByDeletingLastPathComponent?.relativePath != "." {
      targetPath += relativeURL.URLByDeletingLastPathComponent!.relativePath! + "/"
      
      if destPath != file.URL.path {
        var targetPathDir: ObjCBool = false
        if fileManager.fileExistsAtPath(targetPath, isDirectory:&targetPathDir) && !targetPathDir {
          try fileManager.removeItemAtPath(targetPath)
        }
        
        try fileManager.createDirectoryAtPath(targetPath, withIntermediateDirectories: true, attributes: nil)
      }
    }
    
    if destPath != file.URL.path && fileManager.fileExistsAtPath(destPath) {
      try fileManager.removeItemAtPath(destPath)
    }
    
    return destPath
  }
  
  private func copy(file: File, toDir: NSURL) throws -> File? {
    var isDir: ObjCBool = false
    if !fileManager.fileExistsAtPath(toDir.path!, isDirectory:&isDir) || !isDir {
      throw PathExceptions.TargetURLNotDir
    }
    
    let destPath = try prepareCopyDestPath(file, toDir: targetUrl)
  
    if destPath == file.URL.path {
      return nil
    }
    
    try fileManager.copyItemAtPath(file.URL.path!, toPath: destPath)
    let URL = NSURL(fileURLWithFileSystemRepresentation: destPath, isDirectory: false, relativeToURL: targetUrl)
    
    return try File(fileURL: URL, baseURL: toDir, runner: exifToolRunner)
  }
  
  private func toggleColumnVisibility(tableView: NSTableView, tags: [Tag] = []) {
    for column in tableView.tableColumns {
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
  
  // MARK: - Table View
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return files.count
  }
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var cellView: NSTableCellView!
    var text = ""
    let columnID: String
    
    if files.count < row {
      return cellView
    }
    
    if (tableColumn?.identifier != nil) {
      columnID = tableColumn!.identifier
    } else {
      return cellView
    }
    
    let file = files[row]
    
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
      text = file.URL.path!
      if baseUrlIsDir {
        let basePath: String = targetUrl.path == nil || !file.valid ? collectedFilesBaseUrl.path! : targetUrl.path!
        text = file.URL.path!.stringByReplacingOccurrencesOfString(basePath + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
      } else {
        text = file.URL.lastPathComponent!
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
    
    return cellView
  }
  
  // MARK: - Alert
  
  func overwrite(files: [File], tag: Tag) {
    let alert = NSAlert()
    alert.addButtonWithTitle(NSLocalizedString("Yes", comment: "Overwrite alert"))
    alert.addButtonWithTitle(NSLocalizedString("No", comment: "Overwrite alert"))
    alert.messageText = String(format: NSLocalizedString("Existing values for the %@ tag", comment: "Overwrite alert"), NSLocalizedString(tag.name, comment: "Overwrite alert"))
    let fileEnum = (files.count == 1) ? NSLocalizedString("file", comment: "Overwrite alert") :NSLocalizedString("files", comment: "Overwrite alert")
    alert.informativeText = String(format: NSLocalizedString("%1$d %2$@ already have values. Do you want to overwrite?", comment: "Overwrite alert"), files.count, fileEnum)
    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
    
    let result = alert.runModal()
    if result == NSAlertFirstButtonReturn {
      run(files, tags: [tag], keepExistingTags: false, process: false)
    }
  }
}
