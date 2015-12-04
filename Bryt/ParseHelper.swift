//
//  ParseHelper.swift
//  Bryt
//
//  Created by Malcolm Parrish on 11/20/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation
import Parse

protocol AlertProtocol : NSObjectProtocol {
    
    func loadNewScreen(controller: UIViewController) -> Void;
    func showAlert(message: String);
}

class ParseHelper: NSObject {
    
    var viewController:UIViewController?
    var test:String?
    @IBOutlet var userNameField: UITextField?
    weak var delegate: AlertProtocol?


//will initiate the call by saving session
//if there is a session already existing, do not save,
//just pop an alert

class func saveSessionToParse(inputDict:Dictionary<String, AnyObject>) {
    let recieverID = inputDict["recieverID"]
    
    //check if the recipient is either the caller or receiver in one of the activesessions.
    let predicate = NSPredicate(format: "recieverID = '%@' OR callerID = %@", argumentArray: [recieverID!,recieverID!])
    var query = PFQuery(className:"ActiveSessions", predicate:predicate)
    
    query.findObjectsInBackgroundWithBlock{ (objects: [PFObject]?, error: NSError?) -> Void in
        if error == nil {
            for object in objects! {
                // Do something
            NSNotificationCenter.defaultCenter().postNotificationName("kRecieverBusyNotication", object: nil)

                return
            }
        } else {
            print("No session with recieverID exists")
            //storeToParse
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
            (success: Bool, error: NSError?) -> Void in
            if success == true {
                print("Score created with ID: \(activeSession.objectId)")
                
                print("sessionID: \(activeSession["sessionID"]), publisherToken: \(activeSession["publisherToken"]), subscriberToken: \(activeSession["subscriberToken"])")
                
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.sessionID = activeSession["sessionID"] as? String
                appDelegate.subscriberToken = activeSession["sessionID"] as? String
                appDelegate.publisherToken = activeSession["sessionID"] as? String
                appDelegate.callerTitle = activeSession["sessionID"] as? String

                NSNotificationCenter.defaultCenter().postNotificationName("kSessionSavedNotification", object: nil)



            } else {
                let description = error?.localizedDescription
                print("savesession error!!! \(description)")
                let msg  = "Failed to save outgoing call session. Please try again \(description)"
                
                showAlert(msg)
                
            }
        }
            }
    
    class func showAlert(message: String){
//        let alert = UIAlertController(title: "LiveSessions", message:message, preferredStyle: UIAlertControllerStyle.Alert)
//        
//        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in print("Foo")}))
//        
////        ViewController.presentViewController(<#T##UIViewController#>)
        
        if((delegate?.respondsToSelector("showAlert:")) != nil)
        {
            delegate?.showAlert(message);
        }
        
        
    }



    
    func userNameEntered(alert: UIAlertAction!){
        // store the new word
        self.textView2.text = deletedString + " " + self.newWordField.text
    }
    
    
    
    func addTextField(textField: UITextField!){
        // add the text field and make the result global
        textField.placeholder = "test"
//        self.newWordField = textField
    }
    
        class func showUserTitlePrompt() {
            
            
            
            let userNameAlert = UIAlertController(title: "LiveSessions", message:"Enter your name", preferredStyle: UIAlertControllerStyle.Alert)
            userNameAlert.addTextFieldWithConfigurationHandler(addTextField)
            
            userNameAlert.addAction(UIAlertAction(title: :"Ok", style: UIAlertActionStyle.Default, handler: userNameEntered))

            
            
        }
    
    class func anonymousLogin{
        
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

