//
//  InspectorController.swift
//  PhotoMeta
//
//  Created by Jonas Rydenhag on 2020-09-27.
//  Copyright © 2020 Jonas Rydenhag. All rights reserved.
//

import Cocoa

class PhotoViewController: NSViewController {
  @IBOutlet weak var contentView: NSView!
  @IBOutlet weak var dateInput: NSDatePicker!
  @IBOutlet weak var descriptionInput: NSTextField!
  @IBOutlet weak var errorMsg: NSTextField!
  @IBOutlet weak var fileExtensionLabel: NSTextField!
  @IBOutlet weak var imageView: NSImageView!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!

  private let dateFormatter = DateFormatter()

  private var renamePhoto: ((String) throws -> Void)?

  private var photo: Photo? {
    didSet {
      renamePhoto = nil
      refresh()
    }
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)

    dateFormatter.dateFormat = "yyyy-MM-dd"
  }

  @IBAction func closeButton(_ sender: NSButton) {
    photo = nil
  }

  @IBAction func dateInput(_ sender: NSDatePicker) {
    resetErrors()

    if dateFormatter.string(from: dateInput.dateValue) != dateFormatter.string(from: dateInputDefaultValue()) {
      processRenaming(senderView: sender.layer)
    }
  }

  @IBAction func descriptionInput(_ sender: NSTextField) {
    resetErrors()

    if let selectedPhoto = photo {
      if descriptionInput.stringValue != extractDescription(selectedPhoto) {
        processRenaming(senderView: sender.layer)
      }
    }
  }

  private func refresh() {
    contentView.isHidden = true

    resetErrors()

    setCollapsedState()

    progressIndicator.startAnimation(nil)
    progressIndicator.isHidden = false

    DispatchQueue.main.async {
      self.renderDescription()
      self.renderPhoto()

      self.contentView.isHidden = self.photo == nil

      self.progressIndicator.stopAnimation(nil)
      self.progressIndicator.isHidden = true
    }
  }

  func setCollapsedState() {
    if let splitViewController = parent as? NSSplitViewController {
      if let parentSplitView = splitViewController.splitViewItem(for: self) {
        parentSplitView.isCollapsed = photo == nil
      }
    }
  }

  private func resetErrors() {
    errorMsg.stringValue = ""
    dateInput.layer?.borderWidth = 0
    descriptionInput.layer?.borderWidth = 0
  }

  private func renderPhoto() {
    if let photoPath = photo?.sourceFile.URL.path {
      let image = NSImage(byReferencingFile: photoPath)

      imageView.image = image
    } else {
      imageView.image = nil
    }
  }

  private func renderDescription() {
    dateInput.dateValue = dateInputDefaultValue()

    if let selectedPhoto = photo {
      descriptionInput.isEditable = false
      descriptionInput.stringValue = self.extractDescription(selectedPhoto)
      descriptionInput.isEditable = true
      descriptionInput.becomeFirstResponder()

      fileExtensionLabel.stringValue = "." + selectedPhoto.sourceFile.URL.pathExtension
    } else {
      descriptionInput?.stringValue = ""
      fileExtensionLabel?.stringValue = ""
    }
  }

  private func dateInputDefaultValue() -> Date {
    return photo?.date ?? Date()
  }

  private func extractDescription(_ photo: Photo) -> String {
    if let photoDate = photo.date {
      let dateString = dateFormatter.string(from: photoDate)

      return photo.title.replacingOccurrences(of: dateString, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return photo.title
  }

  private func processRenaming(senderView: CALayer?) {
    do {
      try renamePhoto?(assembleFilename())
    } catch {
      senderView?.borderColor = NSColor.red.cgColor
      senderView?.borderWidth = 1

      errorMsg.stringValue = error.localizedDescription
    }
  }

  private func assembleFilename() -> String {
    let date = dateInput.dateValue
    var description = descriptionInput.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

    let descFirstChar = String(description.prefix(1))
    if descFirstChar != "-" {
      description = " " + description
    }

    return dateFormatter.string(from: date) + description + fileExtensionLabel.stringValue
  }
}

extension PhotoViewController: PhotoSelectionDelegate {
  func selected(photo: Photo?, _ renameTo: ((String) throws -> Void)?) {
    self.photo = photo
    self.renamePhoto = renameTo
  }
}
