//
//  ParseHelper.swift
//  Bryt
//
//  Created by Malcolm Parrish on 11/20/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation
import Parse

class ParseHelper: NSObject {


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
                return
            }
        } else {
            print("No session with recieverID exists")
            inputDict
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
            activeSession["CallerTitle"] = CallerTitle
        }
        
    
        
        activeSession.saveInBackgroundWithBlock{ (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                    // Do something
                    return
                }
            } else {
                print(No session with recieverID exists)
                inputDict
            }
        
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

