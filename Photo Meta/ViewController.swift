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
  @IBOutlet weak var keepCheckBtn: NSButton!
  @IBOutlet weak var tagCheckTitle: NSButton!
  @IBOutlet weak var tagCheckDate: NSButton!
  
  @IBOutlet weak var sourcePath: NSPathCell!
  @IBAction func tagCheckClick(sender: NSButton) {
    toggleColumnVisibility(selectedTags)
  }
  
  @IBAction func open(sender: AnyObject) {
    openSelectPaths()
  }
  
  @IBAction func read(sender: AnyObject) {
    read(selectedTags)
  }
  
  @IBAction func write(sender: AnyObject) {
    run(selectedTags, keepExistingTags: (keepCheckBtn.state == NSOnState))
  }
  
  @IBAction func delete(sender: AnyObject) {
    run(selectedTags, keepExistingTags: false, deleteTags: true)
  }
  
  @IBAction func cancel(sender: AnyObject) {
    photoManager?.cancelRun()
  }
  
  private let exifToolRunner = ExifToolRunner()
  private (set) var photoManager: PhotoManager?
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
  
  override func viewDidAppear() {
    super.viewDidAppear()
    if photoManager == nil {
      openSelectPaths()
    }
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
  
  override func validateToolbarItem(theItem: NSToolbarItem) -> Bool {
    if photoManager?.running == true && theItem.action != "cancel:" {
      return false
    }
    
    switch theItem.action {
    case "read:", "write:", "delete:":
      if photoManager != nil && selectedTags.count > 0 {
        return true
      } else {
        return false
      }
    case "cancel:":
      if photoManager?.running == true {
        return true
      } else {
        return false
      }
    case "open:":
      return true
    default:
      return false
    }
  }
  
  func initProject(sourceURL: NSURL, targetURL: NSURL) {
    sourcePath.URL = sourceURL
    self.view.window?.setTitleWithRepresentedFilename(targetURL.path!)
    photoManager = PhotoManager(sourceURL: sourceURL, targetURL: targetURL, runner: exifToolRunner)
    toggleColumnVisibility()
    tableView.reloadData()
  }
  
  private func read(tags: [Tag]) {
    toggleColumnVisibility(selectedTags)
    
    dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
      self.photoManager?.read(tags, afterEach: {
        dispatch_async(dispatch_get_main_queue()) {
          self.tableView.reloadData()
        }
      })
      
      dispatch_async(dispatch_get_main_queue()) {
        self.view.window?.toolbar?.validateVisibleItems()
      }
    }
  }
  
  private func run(tags: [Tag], keepExistingTags: Bool = true, deleteTags: Bool = false, withSelected: [Photo] = []) {
    if photoManager == nil {
      return
    }
    
    toggleColumnVisibility(selectedTags)
    
    dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
      let afterEach = {
          dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
          }
      }
      if deleteTags {
        self.photoManager?.delete(tags, afterEach: afterEach)
      } else {
        self.photoManager?.write(tags, keepExistingTags: keepExistingTags, withSelected: withSelected, afterEach: afterEach)
      }
      
      for tagName in self.photoManager!.kept.keys {
        dispatch_async(dispatch_get_main_queue()) {
          self.overwrite(self.photoManager!.kept[tagName]!, tag: Tag(name: tagName))
        }
      }
      
      dispatch_async(dispatch_get_main_queue()) {
        self.view.window?.toolbar?.validateVisibleItems()
      }
    }
  }
  
  private func toggleColumnVisibility(tags: [Tag] = []) {
    for column in tableView.tableColumns {
      switch column.identifier {
      case "status", "enum", "path":
        column.hidden = false
        
      default:
        var tagFound = false
        for tag in tags {
          if column.identifier == tag.name {
            tagFound = true
          }
        }
        if tagFound {
          column.hidden = false
        } else {
          column.hidden = true
        }
      }
    }
  }
  
  // MARK: - Table View
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return photoManager?.files.count ?? 0
  }
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var cellView: NSTableCellView?
    let columnID: String
    
    if photoManager == nil {
      return cellView
    }
    
    if photoManager!.files.count < row {
      return cellView
    }
    
    if (tableColumn?.identifier != nil) {
      columnID = tableColumn!.identifier
    } else {
      return cellView
    }
    
    let file = photoManager!.files[row]
    
    if columnID == "enum" {
      cellView = tableView.makeViewWithIdentifier("enumCell", owner: self) as? NSTableCellView
      cellView?.textField?.stringValue = "\(row + 1)"
      
    } else if columnID == "path" {
      cellView = tableView.makeViewWithIdentifier("pathCell", owner: self) as? NSTableCellView
      cellView?.textField?.stringValue = file.relativePath
      
    } else if let photo = file as? Photo {
      cellView = renderPhoto(tableView, viewForTableColumnID: columnID, photo: photo)
    }
    
    if !(file is Photo) {
      cellView?.textField?.textColor = NSColor.grayColor()
    }
    
    return cellView
  }
  
  private func renderPhoto(tableView: NSTableView, viewForTableColumnID columnID: String, photo: Photo) -> NSTableCellView? {
    var cellView: NSTableCellView?
    var text = ""
    
    if columnID == "status" {
      cellView = tableView.makeViewWithIdentifier("statusCell", owner: self) as? NSTableCellView
      cellView?.textField?.hidden = false
      
      switch photo.latestRunStatus {
      case .Success:
        cellView?.textField?.backgroundColor = NSColor.greenColor()
      case .Partially:
        cellView?.textField?.backgroundColor = NSColor.yellowColor()
      default:
        cellView?.textField?.hidden = true
      }
      
    } else if columnID == "date" {
      cellView = tableView.makeViewWithIdentifier("dateCell", owner: self) as? NSTableCellView
      if photo.tagValues[Tag.DateTag] != nil {
        text = photo.tagValues[Tag.DateTag]!
      }
      
    } else if columnID == "title" {
      cellView = tableView.makeViewWithIdentifier("titleCell", owner: self) as? NSTableCellView
      if photo.tagValues[Tag.TitleTag] != nil {
        text = photo.tagValues[Tag.TitleTag]!
      }
    }
    
    cellView?.textField?.stringValue = text
    
    return cellView
  }
  
  // MARK: - Alert
  
  func overwrite(files: [Photo], tag: Tag) {
    let alert = NSAlert()
    alert.addButtonWithTitle(NSLocalizedString("Yes", comment: "Overwrite alert"))
    alert.addButtonWithTitle(NSLocalizedString("No", comment: "Overwrite alert"))
    alert.messageText = String(format: NSLocalizedString("Existing values for the %@ tag", comment: "Overwrite alert"), NSLocalizedString(tag.name, comment: "Overwrite alert"))
    let fileEnum = (files.count == 1) ? NSLocalizedString("file", comment: "Overwrite alert") :NSLocalizedString("files", comment: "Overwrite alert")
    alert.informativeText = String(format: NSLocalizedString("%1$d %2$@ already have values. Do you want to overwrite?", comment: "Overwrite alert"), files.count, fileEnum)
    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
    
    let result = alert.runModal()
    if result == NSAlertFirstButtonReturn {
      run([tag], keepExistingTags: false, withSelected: files)
    }
  }
}
