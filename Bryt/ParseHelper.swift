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
    
    static var loginTextField: UITextField?
    static var loggedInUser: PFUser?

    static var bPollingTimerOn: Bool?
    static var activeUserobjID: String?
    static var objectsUnderDeletionQueue: NSMutableArray?
    


//will initiate the call by saving session
//if there is a session already existing, do not save,
//just pop an alert

class func saveSessionToParse(inputDict:Dictionary<String, AnyObject>) {
    
    let recieverID = inputDict["recieverID"]
    
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


    
    class func showUserTitlePrompt() {
        
        let alertController = DBAlertController(title: "LiveSessions", message: "Enter your name", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            print("Ok Button Pressed")
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.userTitle = alertController.textFields![0].text
            appDelegate.bFullyLoggedIn = true
            
            //fire appdelegate timer
            appDelegate.fireListeningTimer()
            NSNotificationCenter.defaultCenter().postNotificationName("kLoggedInNotification", object: nil)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            print("Cancel Button Pressed")
        }
        
        alertController.addAction(ok)
        alertController.addAction(cancel)
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
//            textField.placeholder = "Enter your login ID"
        }
        alertController.show()
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

    
    class func showAlert(message: String, completionClosure:(action: UIAlertAction) -> ()){
        let alert = DBAlertController(title: "LiveSessions", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in completionClosure}))
    
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
        
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                //if user is active user already, just update the entry
                //otherwise create it.
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                
                if objects?.count == 0 {
                    
                }else{
                    let activeSession = objects![0] as! PFObject
                    appDelegate.sessionID = activeSession["sessionID"] as? String
                    appDelegate.subscriberToken = activeSession["subscriberToken"] as? String
                    appDelegate.publisherToken = activeSession["publisherToken"] as? String
                    appDelegate.callerTitle = activeSession["callerTitle"] as? String


                    //done with backend object, remove it.
                    deleteActiveSession()
                    
                    let msg  = "Incoming call from, %@, \(appDelegate.callerTitle)"
                    
                    //create new alert message from scratch because need to set polling timer for cancel 
                    self.showAlert(msg,             NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotication", object: nil))
                }
            }else{
                let msg  = "Failed to retrieve active session for incoming call.  Please try again. %@ \(error?.description)"
                self.showAlert(msg,nil)
                }
        
    }
    }

    class func setPollingTimer(bArg:Bool) {
        bPollingTimerOn = bArg
}
    
    class func deleteActiveSession() {
    
        print("deleteActiveSession")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
        let activeSessionID = app
    
    }


    class func deleteActiveUser()
        {
            let activeUserobjID = self.activeUserobjID
//            
//            if activeUserobjID == nil || activeUserobjID == ""{
//                return
//            }
            
            var query = PFQuery(className:"ActiveUsers")
           
            query.whereKey("userID", equalTo: activeUserobjID)
            
//            query.findObjectsInBackgroundWithBlock{(objects,error) -> Void in
//                if error == nil {
//                    
//                    if objects.
//
//                    if objects?.count == 0 {
//                        print("No such user exists")
//                        
//                        
//    
//                        
//                    }else{
////                        let object = objects[0] as! PFObject
//                        let object = objects[0] as! PFObject
//                        object.contains()
//                        
//                        print("Sucessfully retrieved the Active User")
            
    
    }


    class func initData() {
        if let objectsUnderDeletionQueue = NSMutableArray(){
            print("Objectsunderdeletion not nil")
            
    }
}


class func isUnderDeletion(argObjectID:AnyObject) {
    
//properties not coming up
    
//    return objectsUnderDeletionQueue
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



