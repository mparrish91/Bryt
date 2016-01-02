//
//  AppDelegate.swift
//  Bryt
//
//  Created by Malcolm Parrish on 10/30/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import UIKit
import Parse
import Bolts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var userTitle: String?
    
    var callerTitle: String?
    var sessionID: String?
    var publisherToken: String?
    var subscriberToken: String?
    
    var bFullyLoggedIn: Bool?
    
    var currentLocation: CLLocation?
    weak var appTimer: NSTimer?




    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("iirMSp4mpvmgnGGKtqPd92OiiHAXqjEroqzsbzbX",
            clientKey: "fPKkRUDiF5alWT2TFm5vp5cppfqIkJVp3zVIy0ek")
        
        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        bFullyLoggedIn = false
        ParseHelper.initData()
        registerNotifs()
        ParseHelper.anonymousLogin()
        
        
        
        return true
    }
    
    func registerNotifs() {
//        let rootViewController = self.window?.rootViewController as UIViewController
        
//        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
//        var storyboard = UIStoryboard(name: "Main", bundle: nil)
//        var firstVC = storyboard.instantiateViewControllerWithIdentifier("listvc") as! ListViewController
//        
//        
//        NSNotificationCenter.defaultCenter().addObserver(firstVC, selector: "didCallArrive", name:  "kIncomingCallNotification", object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(firstVC, selector: "didLogin", name: "kLoggedInNotification", object: nil)

    
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        let backgroundTask = application.beginBackgroundTaskWithExpirationHandler {(
            application.endBackgroundTask(UIBackgroundTaskInvalid))
            
        //Start the long-running task and return immediately
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
            })
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        self.bFullyLoggedIn = false
        ParseHelper.anonymousLogin()
        ParseHelper.initData()
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func fireListeningTimer() {
        
        if (appTimer == nil){
            return
            appTimer = NSTimer.scheduledTimerWithTimeInterval(12.0,target: self,selector: Selector("onTick:"),userInfo: nil, repeats: true)
            
            ParseHelper.setPollingTimer(true)
            print("fired timer")
        }
    }
    
    func onTick(timer: NSTimer){
        print("onTick")
        ParseHelper.pollParseForActiveSessions()
        }

}

