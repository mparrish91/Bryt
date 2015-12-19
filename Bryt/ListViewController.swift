//
//  ListViewController.swift
//  Bryt
//
//  Created by Malcolm Parrish on 12/12/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation

class ListViewController: UIViewController {
    
    var bAudioOnly:Bool
    
    var m_userArray = NSMutableArray()
    var m_recieverID =  String()

    @IBOutlet weak var m_userTableView: UITableView!

//Called in repsonse of kLoggedInNotification
func didLogin() {
    
    //not accounting for location...calls parse wrapper for storing to ActiveUsers table
    let thisUser = ParseHelper().loggedInUser
    ParseHelper.saveUserToParse(thisUser)
    
}
    
    
func pullForNewUsers(bRefreshUI:Bool) {
    let query = PFQuery(className: "ActiveUsers")
        query.limit = 10000
        
        //delete all exiting rows, first from front end, then from data soruce
        m_userArray.removeAllObjects()
        //        m_userTableView.reloadData()
        
        query.findObjectsInBackgroundWithBlock {(objects, error) -> Void in
            if error == nil {
                for object in objects {
                    //if for this user, skip it
                    let userID = object["userID"]
                    let currentUser = ParseHelper().loggedInUser.objectId
                    print(userID)
                    print(currentuser)
                    
                    if userID == currentUser {
                        print("skipping - current user")
                        continue
                    }
                    
                    let userTitle = object["userTitle"]
                    
                    let dict = NSMutableDictionary()
                    dict["userID"] = userID
                    dict["userTitle"] = userTitle
                    
                    m_userArray.addObject(dict)
                }
                
                if (bRefreshUI)
                {
                    m_userTableView.reloadData()
                }else{
                    print("%@"/(error?.description))
                }
                
            }
    }
    }
    

    func startVideoChat(sender:AnyObject) {
        let button = UIButton()
        
        if button.tag < 0 //out of bounds
        {
            showAlert("User is no longer online.")
            return
        }
        
        let dict = m_userArray[button.tag] as! NSMutableDictionary
        let recieverID = dict["userID"]
        m_recieverID = recieverID!.copy() as! String
        goToStreamingVC()
        
    }
    
    
    func goToStreamingVC()
    {
        performSegueWithIdentifier("StreamingSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "StreamingSegue"){
            let navController = segue.destinationViewController as! UINavigationController
            let streamingVC = navController.topViewController as! StreamingViewController
            streamingVC.callRecieverID = m_recieverID.copy() as! String

            if bAudioOnly {
                streamingVC.bAudio = true
                streamingVC.bVideo = false
            }else{
                streamingVC.bAudio = true
                streamingVC.bVideo = true
            }
            
        }
    }
    
    
    func didCallArrive() {
        //pass blank because call has arrived, no need for recieverID
        m_recieverID = ""
        goToStreamingVC()
    }
    

}