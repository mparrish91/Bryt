//
//  ListViewController.swift
//  Bryt
//
//  Created by Malcolm Parrish on 12/12/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation
import Parse

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var bAudioOnly:Bool?
    var m_userArray = NSMutableArray()
    var m_receiverID =  String()
    var userPullTimer: NSTimer?

    @IBOutlet weak var m_userTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME: timer should be disabled when table view is not displayed.   er if in a call
    
      userPullTimer = NSTimer.scheduledTimerWithTimeInterval(5.0,target: self,selector: "pullForNewUsersWithRefresh",userInfo: nil, repeats: true)

    }
    
    
    

//Called in repsonse of kLoggedInNotification
func didLogin() {
    
    //not accounting for location...calls parse wrapper for storing to ActiveUsers table
    guard let thisUser = ParseHelper.loggedInUser else { print("What! No logged in user!!!!! Error HELP ME!"); return }
    ParseHelper.saveUserToParse(thisUser)
    
    pullForNewUsers(true)
    print(m_userArray)
}
    
    
    func pullForNewUsersWithRefresh() {
        pullForNewUsers(true)
    }
    
    func pullForNewUsers(bRefreshUI:Bool) {
        let query = PFQuery(className: "ActiveUsers")
        query.limit = 10000
        
        //delete all exiting rows, first from front end, then from data soruce
        m_userArray.removeAllObjects()
        //        m_userTableView.reloadData()
        
        //FIXME: change to only check for changes after creation.  only refresh table if new users
        
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
                }
            }else{
                print("\(error?.description)")
            }
            
        }
    }


    
    func didCallArrive() {
        //pass blank because call has arrived, no need for recieverID
        m_receiverID = ""
        goToStreamingVC()
    }
    
    //Not utilizing anymore
//    func showAlert(message: String, completionClosure:((action: UIAlertAction) -> ())? = nil) {
//        let alert = UIAlertController(title: "LiveSessions", message:message, preferredStyle: UIAlertControllerStyle.Alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in completionClosure}))
//        
//        // add code to handle the different button hits
//        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
//        ad.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
//    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dict = m_userArray[indexPath.row]
        let recieverID = dict.objectForKey("userID")
        m_receiverID = recieverID!.copy() as! String
        goToStreamingVC()
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dict = m_userArray.objectAtIndex(indexPath.row) as! [String:String]
        let userTitle = dict["userTitle"]
        
        print(m_userArray)
        
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        cell?.backgroundColor = UIColor.clearColor()
        
        cell?.textLabel!.text = userTitle
        cell?.textLabel?.font = UIFont(name: "System", size: 20)
        cell?.contentView.backgroundColor = UIColor.clearColor()
        
        
        let videoCallButton = VideoCallButton(type: .System)
        
        videoCallButton.frame = CGRectMake(cell!.bounds.size.width - 50,
            10,
            20,
            20)
        
        
        
        videoCallButton.userIndex = indexPath.row
        videoCallButton.userID = dict["userID"]
        
        videoCallButton.addTarget(self, action: "startVideoChat:", forControlEvents: UIControlEvents.TouchUpInside)
        videoCallButton.setImage(UIImage(named: "phonecall.png"), forState: UIControlState.Normal)
        cell?.contentView.addSubview(videoCallButton)
        
        return cell!
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_userArray.count
        
    }
    
    
    func startVideoChat(sender: VideoCallButton!) {
        print("start called")
        
        // FIXME: This probably won't work.  1.19 Still Confused
        if sender.userIndex < 0 {
            let msg = "User is no longer online."
            
            let alertController = UIAlertController(title: "LiveSessions", message: msg, preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            })
            
            alertController.addAction(ok)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
            return
        }
        
        
        print("user ID from button \(sender.userID!)")
        
        if let uID = sender.userID {
            m_receiverID = uID
        }
        
        
        goToStreamingVC()
        
    }
    
    
    func goToStreamingVC()
    {
        performSegueWithIdentifier("StreamingSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "StreamingSegue"){
            
            let streamingVC = segue.destinationViewController as! StreamingViewController
            streamingVC.callReceiverID = m_receiverID
            
            if (bAudioOnly != nil) {
                streamingVC.bAudio = true
                streamingVC.bVideo = false
            }else{
                streamingVC.bAudio = true
                streamingVC.bVideo = true
            }
            
        }
    }

}