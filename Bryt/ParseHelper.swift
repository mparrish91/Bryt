//
//  ParseHelper.swift
//  Bryt
//
//  Created by Malcolm Parrish on 11/20/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation
import Parse
import DBAlertController



class ParseHelper: NSObject {
    
    class var loginTextField: UITextField?
    class var loggedInUser: PFUser
    
    class var bPollingTimerOn: Bool


//will initiate the call by saving session
//if there is a session already existing, do not save,
//just pop an alert

class func saveSessionToParse(inputDict:Dictionary<String, AnyObject>) {
    
    let recieverID = inputDict["recieverID"]
    
    loginTextField
    
    
    //check if the recipient is either the caller or receiver in one of the activesessions.
    let predicate = NSPredicate(format: "recieverID = '%@' OR callerID = %@", argumentArray: [recieverID!,recieverID!])
    var query = PFQuery(className:"ActiveSessions", predicate:predicate)
    
    query.getFirstObjectInBackgroundWithBlock{ (object: PFObject?, error: NSError?) -> Void in
        if error == nil {
            NSNotificationCenter.defaultCenter().postNotificationName("kRecieverBusyNotication", object: nil)
            return
        } else {
            print("No session with recieverID exists.")
            storeToParse(inputDict)
        }
    
    }
    }
    
    
    class func storeToParse(inputDict:Dictionary<String, AnyObject>) {
        
        let activeSession = PFObject(className: "ActiveSessions")
        let callerID = inputDict["callerID"]
        
        if (callerID != nil) {
            activeSession["callerID"] = callerID
        }
        
        let bAudio = inputDict["isAudio"]?.boolValue
        activeSession["isAudio"] = bAudio?.toInt()
        
        let bVideo = inputDict["isAudio"]?.boolValue
        activeSession["isVideo"] = bVideo?.toInt()

        
        let recieverID = inputDict["receiverID"]
        if (recieverID != nil) {
            activeSession["recieverID"] = callerID
        }
     
        
        //callerTitle
        let callerTitle = inputDict["callerTitle"]
        if (recieverID != nil) {
            activeSession["CallerTitle"] = callerTitle
        }
        
        activeSession.saveInBackgroundWithBlock {
            (success Bool, error: NSError?) -> Void in
            if (error == nil) {
                print("sessionID: \(activeSession["sessionID"]), publisherToken: \(activeSession["publisherToken"]), subscriberToken: \(activeSession["subscriberToken"])")
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.sessionID = activeSession["sessionID"] as? String
                appDelegate.subscriberToken = activeSession["subscriberToken"] as? String
                appDelegate.publisherToken = activeSession["publisherToken"] as? String
                appDelegate.callerTitle = activeSession["callerTitle"] as? String
                NSNotificationCenter.defaultCenter().postNotificationName("kSessionSavedNotification", object: nil)
            } else {
                let description = error?.localizedDescription
                print("savesession error!!! \(description)")
                let msg  = "Failed to save outgoing call session. Please try again \(description)"
                showAlert(msg, nil)
            }
        }
    }


    
//      login prompt
    class func showUserTitlePrompt() {
        
        //present the AlertViewController
        
//        let userNameAlert = UIAlertController(title: "LiveSessions", message:"Enter your name", preferredStyle: UIAlertControllerStyle.Alert)
//        userNameAlert.addTextFieldWithConfigurationHandler(nil)
//        
//        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
//            print("User click Ok button")  })
//        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(alert: UIAlertAction!) in
//            print("User click Cancel button")  })
//        
//        userNameAlert.addAction(okAction)
//        userNameAlert.addAction(cancelAction)
//        
//        
        
        let alertController = DBAlertController(title: "LiveSessions", message: "Enter your name", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            print("Ok Button Pressed")
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.userTitle = alertController.textFields![0].text
            appDelegate.bFullyLoggedIn = true
            
            //fire appdelegat timer
            appDelegate.fireListeningTimer()
            NSNotificationCenter.defaultCenter().postNotificationName("kLoggedInNotification", object: nil)


        })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            print("Cancel Button Pressed")
            //setPollingTimer
        }
        alertController.addAction(ok)
        alertController.addAction(cancel)
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            // Enter the textfiled customization code here.
//            loginTextField = textField
//            loginTextField?.placeholder = "Enter your login ID"
        }
        let textField = alertController.textFields![0]
        textField.placeholder = "Enter your login ID"
        
        alertController.show()

        
        
        //will probably use somewhere else
        NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotification", object: nil)

    }
    
    
//    //works
    class func anonymousLogin() {
        let loggedInUser = PFUser.currentUser()
        
        if (loggedInUser != nil) {
            showUserTitlePrompt()
            return
        }
        
        PFAnonymousUtils.logInWithBlock({ (user : PFUser?, error: NSError?) -> Void in
            if error != nil || user == nil {
                let description = error?.localizedDescription
                print("Failed to login anonymously. Please try again. \(description)")
                let msg  = "Failed to save outgoing call session. Please try again \(description)"
                showAlert(msg, nil)
            } else{
                var loggedInUser = PFUser()
                loggedInUser = user!
                showUserTitlePrompt()
            }
            
        })
    }
    class func showAlert(message: String, handler: ((UIAlertAction) -> Void)?))){

    
    class func showAlert(message: String, handler: () -> void {
        let alert = DBAlertController(title: "LiveSessions", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in handler}))
        
        // add code to handle the different button hits
        alert.show()
    }
    
    class func saveUserToParse(user: PFUser) {
        
        var activeUser: PFObject
        
        let query = PFQuery(className: "ActiveUsers")
        query.whereKey("user", equalTo: user.objectId!)
        query.findObjectsInBackgroundWithBlock {(objects, error) -> Void in
            if error == nil {
                //if user is active user already, just update the entry
                //otherwise create it.
                if objects?.count == 0 {
                    activeUser = PFObject(className: "ActiveUsers")
                }else{
                    activeUser = objects![0]
                }
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                activeUser["userID"] = user.objectId
                activeUser["userTitle"] = appDelegate.userTitle
                
                activeUser.saveInBackgroundWithBlock{ (success, error) -> Void in
                    
                    if success {
                        print("activeUser saved: \(success)")
                        NSNotificationCenter.defaultCenter().postNotificationName("kSessionSavedNotification", object: nil)
                    }else{
                        let description = error?.localizedDescription
                        print(" \(description)")
                        let msg  = "Save to ActiveUsers failed. \(description)"
                        self.showAlert(msg, nil)
                    }
                }
            }
        }
        
    }
    
    class func pollParseForActiveSessions() {
        var activeSession: PFObject
        
        if bPollingTimerOn != nil {
            return
        }
        
        var query = PFQuery(className:"ActiveSessions")
        
        let currentUserID = loggedInUser.objectID
        query.whereKey("recieverID", equalTo: currentUserID)
        
        query.findObjectsInBackgroundWithBlock {(objects, error) -> Void in
            if error == nil {
                //if user is active user already, just update the entry
                //otherwise create it.
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                
                if objects?.count == 0 {
                    
                }else{
                    let activeSession = objects[0] as! PFObject
                    appDelegate.sessionID = activeSession["sessionID"] as? String
                    appDelegate.subscriberToken = activeSession["subscriberToken"] as? String
                    appDelegate.publisherToken = activeSession["publisherToken"] as? String
                    appDelegate.callerTitle = activeSession["callerTitle"] as? String

                    //done with backend object, remove it.
                    
                    
                    let msg  = "Incoming call from, %@, \(appDelegate.callerTitle)"
                    self.showAlert(msg,             NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotication", object: nil)
 )
                    //page 11  set  incoming notifcation = nil
                    
                }else{
                    let msg  = "Failed to retrieve active session for incoming call.  Please try again. %@ \(error?.description)"
                    self.showAlert(msg,nil)
                }
        
    }
}




extension Bool {
    
    func toInt () ->Int? {
        
        switch self {
            
        case false:
            
            return 0
            
        case true:
            
            return 1
            
        default:
            
            return nil
            
        }
        
    }
}



