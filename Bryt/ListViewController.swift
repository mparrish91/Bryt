//
//  ListViewController.swift
//  Bryt
//
//  Created by Malcolm Parrish on 12/12/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation
import Parse
import DBAlertController

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var bAudioOnly:Bool?
    
    var m_userArray = NSMutableArray()
    var m_recieverID =  String()

    @IBOutlet weak var m_userTableView: UITableView!

//Called in repsonse of kLoggedInNotification
func didLogin() {
    
    //not accounting for location...calls parse wrapper for storing to ActiveUsers table
    let thisUser = ParseHelper.loggedInUser
    ParseHelper.saveUserToParse(thisUser!)
    
}
    
    
func pullForNewUsers(bRefreshUI:Bool) {
    let query = PFQuery(className: "ActiveUsers")
        query.limit = 10000
        
        //delete all exiting rows, first from front end, then from data soruce
        m_userArray.removeAllObjects()
        //        m_userTableView.reloadData()
        
        query.findObjectsInBackgroundWithBlock {(objects, error) -> Void in
            if error == nil {
                for object in objects! {
                    //if for this user, skip it
                    let userID = object["userID"] as! String
                    let currentUser = ParseHelper.loggedInUser!.objectId
                    print(userID)
                    print(currentUser)
                    
                    if userID == currentUser! {
                        print("skipping - current user")
                        continue
                    }
                    
                    let userTitle = object["userTitle"]
                    
                    let dict = NSMutableDictionary()
                    dict["userID"] = userID
                    dict["userTitle"] = userTitle
                    
                    self.m_userArray.addObject(dict)
                }
                
                if (bRefreshUI)
                {
                   self.m_userTableView.reloadData()
                }else{
                    print("\(error?.description)")
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
            streamingVC.callRecieverID = m_recieverID.copy() as? String
 
            if (bAudioOnly != nil) {
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
    
    
     func showAlert(message: String, completionClosure:((action: UIAlertAction) -> ())? = nil) {
        let alert = DBAlertController(title: "LiveSessions", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in completionClosure}))
        
        // add code to handle the different button hits
        alert.show()
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dict = m_userArray.objectAtIndex(indexPath.row)
        let recieverID = dict.objectForKey("userID")
        m_recieverID = recieverID!.copy() as! String
        goToStreamingVC()
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dict = m_userArray.objectAtIndex(indexPath.row)
        let userTitle = dict.objectForKey("userTitle") as! String
        
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        cell?.backgroundColor = UIColor.clearColor()
        cell?.backgroundView = UIImageView(image: UIImage(named: "cellrow.png")?.stretchableImageWithLeftCapWidth(0, topCapHeight: 5))

        
        cell?.textLabel!.text = userTitle
        cell?.textLabel?.font = UIFont(name: "Verdana", size: 13)
        cell?.contentView.backgroundColor = UIColor.clearColor()
        
        
        let videoCallButton = UIButton(type: UIButtonType.System)
        videoCallButton.frame = CGRectMake(cell!.frame.size.width - 50, 10.0, 40.0, 40.0)
        videoCallButton.tag = indexPath.row
        videoCallButton.addTarget(self, action: "startVideoChat:", forControlEvents: UIControlEvents.TouchUpInside)
        cell?.addSubview(videoCallButton)
    
        return cell!

    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_userArray.count
    }
    
    

}