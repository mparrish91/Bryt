//
//  DBAlertController.swift
//  DBAlertController
//
//  Created by Dylan Bettermann on 5/11/15.
//  Copyright (c) 2015 Dylan Bettermann. All rights reserved.
//

import UIKit

public class DBAlertController: UIAlertController {
   
    /// The UIWindow that will be at the top of the window hierarchy. The DBAlertController instance is presented on the rootViewController of this window.
    private lazy var alertWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.rootViewController = UIViewController()
        window.backgroundColor = UIColor.clearColor()
        window.windowLevel = UIWindowLevelAlert + 1 // Guarantees that our UIAlertController will appear above all other UIAlertControllers.
        return window
    }()
    
    /**
    Present the DBAlertController on top of the visible UIViewController.
    
    :param: flag       Pass true to animate the presentation; otherwise, pass false. The presentation is animated by default.
    :param: completion The closure to execute after the presentation finishes.
    */
    public func show(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        if let rootViewController = alertWindow.rootViewController {
            alertWindow.makeKeyAndVisible()
            
            rootViewController.presentViewController(self, animated: flag, completion: completion)
        }
    }
    
    /**
    Dismiss the DBAlertController
    
    :param: flag       Pass true to animate the presentation; otherwise, pass false. The presentation is animated by default.
    :param: completion The closure to execute after the dismiss finishes.
    */
    public func dismiss(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        dismissViewControllerAnimated(flag, completion: completion)
    }
    
    
    // Fix for bug in iOS 9 Beta 5 that prevents the original window from becoming keyWindow again
    deinit {
        alertWindow.hidden = true
    }
}
