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

  @IBAction func selectSourceDialog(_ sender: Any) {
    if let selectedPath = choosePath() {
      sourceURL = selectedPath
    }
  }

  @IBAction func selectTargetDialog(_ sender: Any) {
    if let selectedPath = choosePath(canChooseFiles: false, canCreateDirectories: true) {
      targetURL = selectedPath
    }
  }

  @IBAction func cancelBtnClick(_ sender: Any) {
    self.view.window?.close()
  }

  @IBAction func okBtnClick(_ sender: Any) {
    if let selectedSource = sourceURL,
       let selectedTarget = targetURL {

      if let caller = caller {
        let closure = {
          self.savePaths(selectedSource, selectedTarget)

          caller.initProject(sourceURL: selectedSource, targetURL: selectedTarget)
          self.view.window?.close()
        }

        if selectedSource.path == selectedTarget.path {
          samePaths(closure: closure)
        } else {
          closure()
        }
      }
    }
  }

  var caller: ViewController?

  private let fileManager = FileHandler.default
  var sourceURL: URL? {
    didSet {
      setOutletsEnableState()
      sourcePath.url = sourceURL
    }
  }

  var targetURL: URL? {
    didSet {
      setOutletsEnableState()
      targetPath.url = targetURL
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setOutletsEnableState()

    if caller?.photoManager != nil {
      sourceURL = caller!.photoManager!.sourceDir
      targetURL = caller!.photoManager!.targetDir
    }
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    self.view.window?.preventsApplicationTerminationWhenModal = false
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }

  private func setOutletsEnableState() {
    if sourceURL != nil && targetURL != nil {
      okBtn?.isEnabled = true
    } else {
      okBtn?.isEnabled = false
    }
  }

  func choosePath(canChooseFiles: Bool = true, canCreateDirectories: Bool = false) -> URL? {
    let myOpenDialog: NSOpenPanel = NSOpenPanel()
    myOpenDialog.canChooseDirectories = true
    myOpenDialog.canChooseFiles = canChooseFiles
    myOpenDialog.canCreateDirectories = canCreateDirectories
    let clickedBtn = myOpenDialog.runModal()

    if clickedBtn.rawValue == NSApplication.ModalResponse.OK.rawValue {
      // Make sure that a path was chosen
      if let selectedPath = myOpenDialog.url {
          return selectedPath
      }
    }
    return nil
  }

  // MARK: - Alert

  func samePaths(closure: () -> Void) {
    let alert = NSAlert()
    alert.addButton(withTitle: NSLocalizedString("Continue", comment: "Same paths alert"))
    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Same paths alert"))
    alert.messageText = String(format: NSLocalizedString("Overwrite file(s)?", comment: "Same paths alert"))
    alert.informativeText = String(format: NSLocalizedString("Since the source and target are the same, the file(s) will be overwritten", comment: "Same paths alert"))
    alert.alertStyle = NSAlert.Style.informational

    let result = alert.runModal()
    if result == NSApplication.ModalResponse.alertFirstButtonReturn {
      closure()
    }
  }

  private func savePaths(_ sourcePath: URL, _ targetPath: URL) {
    UserDefaults.standard.set(sourcePath.path, forKey: "sourceURL")
    UserDefaults.standard.set(targetPath.path, forKey: "targetURL")
  }
}
