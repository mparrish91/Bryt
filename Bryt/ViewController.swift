//
//  ViewController.swift
//  Bryt
//
//  Created by Malcolm Parrish on 10/30/15.
//  Copyright © 2015 Bryt. All rights reserved.
//


import UIKit
import Parse

let videoWidth : CGFloat = 320
let videoHeight : CGFloat = 240

// *** Fill the following variables using your own Project info  ***
// ***          https://dashboard.tokbox.com/projects            ***
// Replace with your OpenTok API key
let ApiKey = "45403342"
// Replace with your generated session ID
let SessionID = "2_MX40NTQwMzM0Mn5-MTQ0ODA3MTA0OTkwN345bms5T25DQ1FHc3dWWm43TUhwRFdHSkJ-UH4"
// Replace with your generated token
let Token = "T1==cGFydG5lcl9pZD00NTQwMzM0MiZzaWc9NmZmMmU1YjAyNmM1ZjgwZDE0OWZhZDAwNjgxM2E2ODVjYjM4MjJhNjpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTJfTVg0ME5UUXdNek0wTW41LU1UUTBPREEzTVRBME9Ua3dOMzQ1Ym1zNVQyNURRMUZIYzNkV1dtNDNUVWh3UkZkSFNrSi1VSDQmY3JlYXRlX3RpbWU9MTQ0ODA3MTA3MiZub25jZT0wLjUyNDM3MjM3NzY3MTgzMDImZXhwaXJlX3RpbWU9MTQ0ODA3NDU1NyZjb25uZWN0aW9uX2RhdGE9"

// Change to YES to subscribe to your own stream.
let SubscribeToSelf = false


class ViewController: UIViewController, OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate {
    
    var session : OTSession?
    var publisher : OTPublisher?
    var subscriber : OTSubscriber?
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    
    var m_userArray = NSMutableArray()
    var m_recieverID =  String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Step 1: As the view is loaded initialize a new instance of OTSession
        session = OTSession(apiKey: ApiKey, sessionId: SessionID, delegate: self)
        
        
        
        //Home Screen
        let imageName = "studentStudying.jpg"
        let image = UIImage(named: imageName)
        
        self.imageView.image = image
        self.imageView.contentMode = UIViewContentMode .ScaleAspectFill
        
        loginButton.layer.cornerRadius = 5
        loginButton.layer.borderWidth = 1
        loginButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        
//        let testObject = PFObject(className: "TestObject")
//        testObject["foo"] = "bar"
//        testObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
//            print("Object has been saved.")}
        
            
        ParseHelper.saveSessionToParse([:])
            
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        // Step 2: As the view comes into the foreground, begin the connection process.
        doConnect()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: - OpenTok Methods
    
    /**
    * Asynchronously begins the session connect process. Some time later, we will
    * expect a delegate method to call us back with the results of this action.
    */
    func doConnect() {
        if let session = self.session {
            var maybeError : OTError?
            session.connectWithToken(Token, error: &maybeError)
            if let error = maybeError {
                showAlert(error.localizedDescription)
            }
        }
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    func doPublish() {
        publisher = OTPublisher(delegate: self)
        
        var maybeError : OTError?
        session?.publish(publisher, error: &maybeError)
        
        if let error = maybeError {
            showAlert(error.localizedDescription)
        }
        
        view.addSubview(publisher!.view)
        publisher!.view.frame = CGRect(x: 0.0, y: 0, width: videoWidth, height: videoHeight)
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    func doSubscribe(stream : OTStream) {
        if let session = self.session {
            subscriber = OTSubscriber(stream: stream, delegate: self)
            
            var maybeError : OTError?
            session.subscribe(subscriber, error: &maybeError)
            if let error = maybeError {
                showAlert(error.localizedDescription)
            }
        }
    }
    
    /**
     * Cleans the subscriber from the view hierarchy, if any.
     */
    func doUnsubscribe() {
        if let subscriber = self.subscriber {
            var maybeError : OTError?
            session?.unsubscribe(subscriber, error: &maybeError)
            if let error = maybeError {
                showAlert(error.localizedDescription)
            }
            
            subscriber.view.removeFromSuperview()
            self.subscriber = nil
        }
    }
    
    // MARK: - OTSession delegate callbacks
    
    func sessionDidConnect(session: OTSession) {
        NSLog("sessionDidConnect (\(session.sessionId))")
        
        // Step 2: We have successfully connected, now instantiate a publisher and
        // begin pushing A/V streams into OpenTok.
        doPublish()
    }
    
    func sessionDidDisconnect(session : OTSession) {
        NSLog("Session disconnected (\( session.sessionId))")
    }
    
    func session(session: OTSession, streamCreated stream: OTStream) {
        NSLog("session streamCreated (\(stream.streamId))")
        
        // Step 3a: (if NO == subscribeToSelf): Begin subscribing to a stream we
        // have seen on the OpenTok session.
        if subscriber == nil && !SubscribeToSelf {
            doSubscribe(stream)
        }
    }
    
    func session(session: OTSession, streamDestroyed stream: OTStream) {
        NSLog("session streamCreated (\(stream.streamId))")
        
        if subscriber?.stream.streamId == stream.streamId {
            doUnsubscribe()
        }
    }
    
    func session(session: OTSession, connectionCreated connection : OTConnection) {
        NSLog("session connectionCreated (\(connection.connectionId))")
    }
    
    func session(session: OTSession, connectionDestroyed connection : OTConnection) {
        NSLog("session connectionDestroyed (\(connection.connectionId))")
    }
    
    func session(session: OTSession, didFailWithError error: OTError) {
        NSLog("session didFailWithError (%@)", error)
    }
    
    // MARK: - OTSubscriber delegate callbacks
    
    func subscriberDidConnectToStream(subscriberKit: OTSubscriberKit) {
        NSLog("subscriberDidConnectToStream (\(subscriberKit))")
        if let view = subscriber?.view {
            view.frame =  CGRect(x: 0.0, y: videoHeight, width: videoWidth, height: videoHeight)
            self.view.addSubview(view)
        }
    }
    
    func subscriber(subscriber: OTSubscriberKit, didFailWithError error : OTError) {
        NSLog("subscriber %@ didFailWithError %@", subscriber.stream.streamId, error)
    }
    
    // MARK: - OTPublisher delegate callbacks
    
    func publisher(publisher: OTPublisherKit, streamCreated stream: OTStream) {
        NSLog("publisher streamCreated %@", stream)
        
        // Step 3b: (if YES == subscribeToSelf): Our own publisher is now visible to
        // all participants in the OpenTok session. We will attempt to subscribe to
        // our own stream. Expect to see a slight delay in the subscriber video and
        // an echo of the audio coming from the device microphone.
        if subscriber == nil && SubscribeToSelf {
            doSubscribe(stream)
        }
    }
    
    func publisher(publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        NSLog("publisher streamDestroyed %@", stream)
        
        if subscriber?.stream.streamId == stream.streamId {
            doUnsubscribe()
        }
    }
    
    func publisher(publisher: OTPublisherKit, didFailWithError error: OTError) {
        NSLog("publisher didFailWithError %@", error)
    }
    
    // MARK: - Helpers
    
//    func showAlert(message: String) {
//        // show alertview on main UI
//        dispatch_async(dispatch_get_main_queue()) {
//            let al = UIAlertView(title: "OTError", message: message, delegate: nil, cancelButtonTitle: "OK")
//        }
//    }
    
    
    func showAlert(message: String) {
        // show alertview on main UI
        dispatch_async(dispatch_get_main_queue()) {
            
            let al = UIAlertController(title: "OTError", message:message, preferredStyle: UIAlertControllerStyle.Alert)
            
            al.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in print("Foo")}))
            
            self.presentViewController(al, animated: true, completion: nil)
        }
    }
    
    //Called in repsonse of kLoggedInNotification
    func didLogin() {
        
    }
    
    func startUpdate() {
//        let thisUser = ParseHelper.logg
    }
    
    func saveUserToParse(user: PFUser) {
        
        var activeUser: PFObject
        
        let query = PFQuery(className: "ActiveUsers")
        query.whereKey("user", equalTo: user.objectId!)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
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
                    print("activeUser saved: \(success)")
                }
                
                
                appDelegate.sessionID = activeSession["sessionID"] as? String
                appDelegate.subscriberToken = activeSession["subscriberToken"] as? String
                appDelegate.publisherToken = activeSession["publisherToken"] as? String
                appDelegate.callerTitle = activeSession["callerTitle"] as? String
                NSNotificationCenter.defaultCenter().postNotificationName("kSessionSavedNotification", object: nil)
            
        }
    }
    
    func startVideoChat(sender:AnyObject) {
        let button = UIButton()
        
        if button.tag < 0 //out of bounds
        {
            showAlert("User is no longer online.")
            return
        }
        
        let dict = m_userArray[button.tag]
        let recieverID = dict["userID"]
        m_recieverID = recieverID!!.copy() as! String
        goToStreamingVC()
        
    }
    
    
    func goToStreamingVC()
    {
        performSegueWithIdentifier("StreamingSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "StreamingSegue"){
            let navController = segue.destinationViewController
//            let streamingVC = navController.topViewController as!
            
        }
    }
    

    
    
    
    

}


