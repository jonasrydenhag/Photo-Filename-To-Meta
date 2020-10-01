//
//  ViewController.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-19.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Cocoa

enum PathExceptions: Error {
  case TargetURLNotDir
}

protocol PhotoSelectionDelegate: class {
  func photoSelected(_ photo: Photo?)
}

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSToolbarItemValidation {

  // MARK: - Outlets
  
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var overwriteCheckBtn: NSButton!
  @IBOutlet weak var tagCheckDate: NSButton!
  @IBOutlet weak var tagCheckDescription: NSButton!
  @IBOutlet weak var tagCheckTitle: NSButton!
  @IBOutlet weak var sourcePath: NSPathCell!
  
  // MARK: - Vars

  weak var delegate: PhotoSelectionDelegate?
  
  private (set) var photoManager: PhotoManager?
  private var selectedTags: [Tag] {
    get {
      var checkedTags = [Tag]()
      if tagCheckDate.state == NSControl.StateValue.on {
        checkedTags.append(Tag.Date)
      }
      if tagCheckDescription.state == NSControl.StateValue.on {
        checkedTags.append(Tag.Description)
      }
      if tagCheckTitle.state == NSControl.StateValue.on {
        checkedTags.append(Tag.Title)
      }
      return checkedTags
    }
  }
  
  // MARK: - ViewControlller
  
  override func viewDidAppear() {
    super.viewDidAppear()
    if photoManager == nil {
      selectPaths()
    }
  }
  
  // MARK: - Source and Target chooser

  private func selectPaths() {
    if let savedSourceURLString = UserDefaults.standard.string(forKey: "sourceURL"),
       let savedTargetURLString = UserDefaults.standard.string(forKey: "targetURL") {
      initProject(sourceURL: NSURL(fileURLWithPath: savedSourceURLString), targetURL: NSURL(fileURLWithPath: savedTargetURLString))
    } else {
      openSelectPaths()
    }
  }
  
  private func openSelectPaths() {
    self.performSegue(withIdentifier: "selectPaths", sender: self)
  }

  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    if let pathsController: PathsController = segue.destinationController as? PathsController {
      pathsController.caller = self
    }
  }
  
  // MARK: - Start
  
  func initProject(sourceURL: NSURL, targetURL: NSURL) {
    delegate?.photoSelected(nil)

    sourcePath.url = sourceURL as URL
    self.view.window?.setTitleWithRepresentedFilename(targetURL.path!)
    photoManager = PhotoManager(sourceURL: sourceURL, targetURL: targetURL)
    toggleColumnVisibility()
    tableView.reloadData()
  }
  
  // MARK: - Action buttons

  func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
    if photoManager?.running == true && item.action != #selector(self.cancel(_:)) {
      return false
    }

    switch item.action {
    case #selector(self.read(_:)), #selector(self.write(_:)), #selector(self.delete(_:)):
      if photoManager != nil && selectedTags.count > 0 {
        return true
      } else {
        return false
      }
    case #selector(self.cancel(_:)):
      if photoManager?.running == true {
        return true
      } else {
        return false
      }
    case #selector(self.open(_:)):
      return true
    default:
      return false
    }
  }
  
  // MARK: - Actions
  
  @IBAction func tagCheckClick(_ sender: NSButton) {
    toggleColumnVisibility(tags: selectedTags)
  }
  
  @IBAction func open(_ sender: Any) {
    openSelectPaths()
  }
  
  @IBAction func read(_ sender: Any) {
    toggleColumnVisibility(tags: selectedTags)

    let tags = self.selectedTags

    DispatchQueue.global(qos: .userInitiated).async {
      self.photoManager?.read(tags: tags, afterEach: {
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      })

      DispatchQueue.main.async {
        self.view.window?.toolbar?.validateVisibleItems()
      }
    }
  }
  
  @IBAction func write(_ sender: Any) {
    run(tags: selectedTags, overwriteValues: (overwriteCheckBtn.state == NSControl.StateValue.on))
  }
  
  @IBAction func delete(_ sender: Any) {
    run(tags: selectedTags, deleteTags: true)
  }
  
  @IBAction func cancel(_ sender: Any) {
    photoManager?.cancelRun()
  }
  
  private func run(tags: [Tag], overwriteValues: Bool = false, deleteTags: Bool = false) {
    if photoManager == nil {
      return
    }
    
    toggleColumnVisibility(tags: selectedTags)
    
    DispatchQueue.global(qos: .userInitiated).async {
      let afterEach = {
          DispatchQueue.main.async {
            self.tableView.reloadData()
          }
      }
      
      if deleteTags {
        self.photoManager?.delete(tags: tags, afterEach: afterEach)
        
      } else {
        self.photoManager?.write(tags: tags, overwriteValues: overwriteValues, afterEach: afterEach)
      }
      
      DispatchQueue.main.async {
        self.view.window?.toolbar?.validateVisibleItems()
      }
    }
  }
  
  // MARK: - Table View
  
  private func toggleColumnVisibility(tags: [Tag] = []) {
    for column in tableView.tableColumns {
      switch column.identifier.rawValue {
      case "status", "enum", "path":
        column.isHidden = false
        
      default:
        var tagFound = false
        for tag in tags {
          if column.identifier.rawValue == tag.rawValue {
            tagFound = true
          }
        }
        if tagFound {
          column.isHidden = false
        } else {
          column.isHidden = true
        }
      }
    }
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    return photoManager?.files.count ?? 0
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    var cellView: NSTableCellView?
    let columnID: String
    
    if photoManager == nil {
      return cellView
    }
    
    if photoManager!.files.count < row {
      return cellView
    }
    
    if (tableColumn?.identifier.rawValue != nil) {
      columnID = tableColumn!.identifier.rawValue
    } else {
      return cellView
    }
    
    let file = photoManager!.files[row]
    
    if columnID == "enum" {
      cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "enumCell"), owner: self) as? NSTableCellView
      cellView?.textField?.stringValue = "\(row + 1)"
      
    } else if columnID == "path" {
      cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "pathCell"), owner: self) as? NSTableCellView
      cellView?.textField?.stringValue = file.relativePath
      
    } else if let photo = file as? Photo {
      cellView = renderPhoto(tableView: tableView, viewForTableColumnID: columnID, photo: photo)
    }
    
    if !(file is Photo) {
      cellView?.textField?.textColor = NSColor.gray
    } else {
      cellView?.textField?.textColor = nil
    }
    
    return cellView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    if let selectedPhoto = photoManager!.files[row] as? Photo {
      delegate?.photoSelected(selectedPhoto)

      return true
    } else {
      return false
    }
  }

  private func renderPhoto(tableView: NSTableView, viewForTableColumnID columnID: String, photo: Photo) -> NSTableCellView? {
    var cellView: NSTableCellView?
    var text = ""
    
    if columnID == "status" {
      cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "statusCell"), owner: self) as? NSTableCellView
      cellView?.textField?.isHidden = false
      
      switch photo.latestRunStatus {
      case .Success:
        cellView?.textField?.backgroundColor = NSColor.green
      case .Partially:
        cellView?.textField?.backgroundColor = NSColor.yellow
      case .Failed:
        cellView?.textField?.backgroundColor = NSColor.red
      default:
        cellView?.textField?.isHidden = true
      }
      
    } else if columnID == "Date" {
      cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "dateCell"), owner: self) as? NSTableCellView
      if photo.tagsValue[Tag.Date] != nil {
        text = photo.tagsValue[Tag.Date]!
      }
    } else if columnID == "Description" {
      cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "descriptionCell"), owner: self) as? NSTableCellView
      if photo.tagsValue[Tag.Description] != nil {
        text = photo.tagsValue[Tag.Description]!
      }
    } else if columnID == "Title" {
      cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "titleCell"), owner: self) as? NSTableCellView
      if photo.tagsValue[Tag.Title] != nil {
        text = photo.tagsValue[Tag.Title]!
      }
    }
    
    cellView?.textField?.stringValue = text
    
    return cellView
  }
}
