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
  @IBOutlet weak var fileExtensionLabel: NSTextField!
  @IBOutlet weak var imageView: NSImageView!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!

  private var photo: Photo? {
    didSet {
      refresh()
    }
  }

  @IBAction func descriptionInput(_ sender: NSTextField) {
  }

  private func refresh() {
    contentView.isHidden = true
    setCollapsedState()

    progressIndicator.startAnimation(nil)
    progressIndicator.isHidden = false

    DispatchQueue.main.async {
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

  private func renderPhoto() {
    if let photoPath = photo?.URL.path {
      let image = NSImage(byReferencingFile: photoPath)

      imageView.image = image
    } else {
      imageView.image = nil
    }
  }
}

extension PhotoViewController: PhotoSelectionDelegate {
  func photoSelected(_ photo: Photo?) {
    self.photo = photo
  }
}
