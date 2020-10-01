//
//  AppDelegate.swift
//  Photo Meta
//
//  Created by Jonas Rydenhag on 2015-08-19.
//  Copyright (c) 2015 Jonas Rydenhag. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    //NSUserDefaults.standardUserDefaults().setBool(true, forKey:"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")

    guard
      let splitViewController = NSApplication.shared.mainWindow?.contentViewController as? NSSplitViewController,
      let viewController = splitViewController.splitViewItems.first?.viewController as? ViewController,
      let photoViewController = splitViewController.splitViewItems.last?.viewController as? PhotoViewController
      else { fatalError() }

    viewController.delegate = photoViewController
  }
}
