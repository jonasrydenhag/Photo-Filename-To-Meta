//
//  PathsController.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-09-27.
//  Copyright © 2015 Jonas Rydenhag. All rights reserved.
//

import Cocoa

class PathsController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

  @IBOutlet weak var sourceSelectBtn: NSButton!
  @IBOutlet weak var targetSelectBtn: NSButton!
  @IBOutlet weak var sourcePath: NSPathControl!
  @IBOutlet weak var targetPath: NSPathControl!
  @IBOutlet weak var targetTextFieldLabel: NSTextField!
  @IBOutlet weak var cancelBtn: NSButton!
  @IBOutlet weak var okBtn: NSButton!
  
  @IBAction func selectSourceDialog(sender: AnyObject) {
    if let selectedPath = choosePath() {
      sourceURL = selectedPath
    }
  }
  
  @IBAction func selectTargetDialog(sender: AnyObject) {
    if let selectedPath = choosePath(false, canCreateDirectories: true) {
      targetURL = selectedPath
    }
  }
  
  @IBAction func cancelBtnClick(sender: AnyObject) {
    self.view.window?.close()
  }
  
  @IBAction func okBtnClick(sender: AnyObject) {
    if sourceURL.path == nil || targetURL.path == nil {
      return
    }
    
    if let caller = caller {
      let closure = {
        caller.initProject(self.sourceURL, targetURL: self.targetURL)
        self.view.window?.close()
      }
      
      if sourceURL.path == targetURL.path {
        samePaths(closure)
      } else {
        closure()
      }
    }
  }
  
  var caller: ViewController?
  
  private let fileManager = NSFileManager.defaultManager()
  var sourceURL: NSURL = NSURL() {
    didSet {
      setOutletsEnableState()
      sourcePath.URL = sourceURL
    }
  }
  
  var targetURL: NSURL = NSURL() {
    didSet {
      setOutletsEnableState()
      targetPath.URL = targetURL
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setOutletsEnableState()
    
    if caller?.photoManager != nil {
      sourceURL = caller!.photoManager!.sourceURL
      targetURL = caller!.photoManager!.targetURL
    }
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    self.view.window?.preventsApplicationTerminationWhenModal = false
  }
  
  override var representedObject: AnyObject? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  private func setOutletsEnableState() {
    if sourceURL.path != nil && targetURL.path != nil {
      okBtn?.enabled = true
    } else {
      okBtn?.enabled = false
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
  
  // MARK: - Alert
  
  func samePaths(closure: () -> Void) {
    let alert = NSAlert()
    alert.addButtonWithTitle(NSLocalizedString("Continue", comment: "Same paths alert"))
    alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: "Same paths alert"))
    alert.messageText = String(format: NSLocalizedString("Overwrite file(s)?", comment: "Same paths alert"))
    alert.informativeText = String(format: NSLocalizedString("Since the source and target are the same, the file(s) will be overwritten", comment: "Same paths alert"))
    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
    
    let result = alert.runModal()
    if result == NSAlertFirstButtonReturn {
      closure()
    }
  }
}
