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
  @IBOutlet weak var sourceTextField: NSTextField!
  @IBOutlet weak var targetTextField: NSTextField!
  @IBOutlet weak var targetTextFieldLabel: NSTextField!
  @IBOutlet weak var cancelBtn: NSButton!
  @IBOutlet weak var okBtn: NSButton!
  
  @IBAction func selectSourceDialog(sender: NSButton) {
    if let selectedPath = choosePath() {
      sourceUrl = selectedPath
    }
  }
  
  @IBAction func selectTargetDialog(sender: NSButton) {
    if let selectedPath = choosePath(false, canCreateDirectories: true) {
      targetUrl = selectedPath
    }
  }
  
  @IBAction func cancelBtnClick(sender: AnyObject) {
    self.view.window?.close()
  }
  
  @IBAction func okBtnClick(sender: AnyObject) {
    if sourceUrl.path == nil || targetUrl.path == nil {
      return
    }
    
    if let caller = self.caller {
      let closure = {
        caller.collectFilesFrom(self.sourceUrl)
        caller.targetUrl = self.targetUrl
        self.view.window?.close()
      }
      
      if sourceUrl.path == targetUrl.path {
        samePaths(closure)
      } else {
        closure()
      }
    }
  }
  
  var caller: ViewController?
  
  private let fileManager = NSFileManager.defaultManager()
  private var sourceUrl: NSURL = NSURL() {
    didSet {
      setOutletsEnableState()
      var value: String
      if sourceUrl.path != nil {
        value = sourceUrl.path!.stringByReplacingOccurrencesOfString(NSHomeDirectory() + "/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
      } else {
        value = ""
      }
      sourceTextField.stringValue = value
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setOutletsEnableState()
    
    if caller != nil {
      sourceUrl = caller!.sourceUrl
      targetUrl = caller!.targetUrl
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
    if sourceUrl.path != nil && targetUrl.path != nil {
      okBtn.enabled = true
    } else {
      okBtn.enabled = false
    }
    
    // @todo Allow same target as path
    if sourceUrl.path == targetUrl.path {
      okBtn.enabled = false
    } else {
      okBtn.enabled = true
    }
    //
    
    if caller?.sourceUrl.path != nil {
      cancelBtn.hidden = false
    } else {
      cancelBtn.hidden = true
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