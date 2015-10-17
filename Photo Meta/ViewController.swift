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

  // MARK: - Outlets
  
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var overwriteCheckBtn: NSButton!
  @IBOutlet weak var tagCheckTitle: NSButton!
  @IBOutlet weak var tagCheckDate: NSButton!
  @IBOutlet weak var sourcePath: NSPathCell!
  
  // MARK: - Vars
  
  private (set) var photoManager: PhotoManager?
  private var selectedTags: [Tag] {
    get {
      var checkedTags = [Tag]()
      if tagCheckTitle.state == NSOnState {
        checkedTags.append(Tag.Title)
      }
      if tagCheckDate.state == NSOnState {
        checkedTags.append(Tag.Date)
      }
      return checkedTags
    }
  }
  
  // MARK: - ViewControlller
  
  override func viewDidAppear() {
    super.viewDidAppear()
    if photoManager == nil {
      openSelectPaths()
    }
  }
  
  // MARK: - Source and Target chooser
  
  private func openSelectPaths() {
    self.performSegueWithIdentifier("selectPaths", sender: self)
  }
  
  override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
    if let pathsController: PathsController = segue.destinationController as? PathsController {
      pathsController.caller = self
    }
  }
  
  // MARK: - Start
  
  func initProject(sourceURL: NSURL, targetURL: NSURL) {
    sourcePath.URL = sourceURL
    self.view.window?.setTitleWithRepresentedFilename(targetURL.path!)
    photoManager = PhotoManager(sourceURL: sourceURL, targetURL: targetURL)
    toggleColumnVisibility()
    tableView.reloadData()
  }
  
  // MARK: - Action buttons
  
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
  
  // MARK: - Actions
  
  @IBAction func tagCheckClick(sender: NSButton) {
    toggleColumnVisibility(selectedTags)
  }
  
  @IBAction func open(sender: AnyObject) {
    openSelectPaths()
  }
  
  @IBAction func read(sender: AnyObject) {
    toggleColumnVisibility(selectedTags)
    
    dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
      self.photoManager?.read(self.selectedTags, afterEach: {
        dispatch_async(dispatch_get_main_queue()) {
          self.tableView.reloadData()
        }
      })
      
      dispatch_async(dispatch_get_main_queue()) {
        self.view.window?.toolbar?.validateVisibleItems()
      }
    }
  }
  
  @IBAction func write(sender: AnyObject) {
    run(selectedTags, overwriteValues: (overwriteCheckBtn.state == NSOnState))
  }
  
  @IBAction func delete(sender: AnyObject) {
    run(selectedTags, deleteTags: true)
  }
  
  @IBAction func cancel(sender: AnyObject) {
    photoManager?.cancelRun()
  }
  
  private func run(tags: [Tag], overwriteValues: Bool = false, deleteTags: Bool = false, withSelected: [Photo] = []) {
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
        self.photoManager?.write(tags, overwriteValues: overwriteValues, withSelected: withSelected, afterEach: afterEach)
      }
      
      dispatch_async(dispatch_get_main_queue()) {
        self.view.window?.toolbar?.validateVisibleItems()
      }
    }
  }
  
  // MARK: - Table View
  
  private func toggleColumnVisibility(tags: [Tag] = []) {
    for column in tableView.tableColumns {
      switch column.identifier {
      case "status", "enum", "path":
        column.hidden = false
        
      default:
        var tagFound = false
        for tag in tags {
          if column.identifier == tag.rawValue {
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
    } else {
      cellView?.textField?.textColor = nil
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
      case .Failed:
        cellView?.textField?.backgroundColor = NSColor.redColor()
      default:
        cellView?.textField?.hidden = true
      }
      
    } else if columnID == "Date" {
      cellView = tableView.makeViewWithIdentifier("dateCell", owner: self) as? NSTableCellView
      if photo.tagsValue[Tag.Date] != nil {
        text = photo.tagsValue[Tag.Date]!
      }
      
    } else if columnID == "Title" {
      cellView = tableView.makeViewWithIdentifier("titleCell", owner: self) as? NSTableCellView
      if photo.tagsValue[Tag.Title] != nil {
        text = photo.tagsValue[Tag.Title]!
      }
    }
    
    cellView?.textField?.stringValue = text
    
    return cellView
  }
}
