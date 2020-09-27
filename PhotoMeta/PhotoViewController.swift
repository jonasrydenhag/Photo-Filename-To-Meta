//
//  InspectorController.swift
//  PhotoMeta
//
//  Created by Jonas Rydenhag on 2020-09-27.
//  Copyright © 2020 Jonas Rydenhag. All rights reserved.
//

import Cocoa

class PhotoViewController: NSViewController {
  @IBOutlet weak var imageView: NSImageView!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!

  func open(photo: Photo) {
    viewDisplay(collapsed: false)

    load(photo: photo)
  }

  func viewDisplay(collapsed: Bool) {
    if let splitViewController = self.parent as? NSSplitViewController {
      if let parentSplitView = splitViewController.splitViewItem(for: self) {
        parentSplitView.isCollapsed = collapsed

        if collapsed == true {
          unloadPhoto()
        }
      }
    }
  }

  private func load(photo: Photo) {
    if let photoPath = photo.URL.path {
      let image = NSImage(byReferencingFile: photoPath)

      unloadPhoto()
      progressIndicator.startAnimation(nil)

      DispatchQueue.main.async {
        self.imageView.image = image
        self.progressIndicator.stopAnimation(nil)
      }
    }
  }

  private func unloadPhoto() {
    if imageView != nil {
      imageView.image = nil
    }
  }
}
