//
//  ViewController.swift
//  Bryt
//
//  Created by Malcolm Parrish on 10/30/15.
//  Copyright © 2015 Bryt. All rights reserved.
//


import UIKit
import Parse

//let videoWidth : CGFloat = 320
//let videoHeight : CGFloat = 240

let navController = segue.destinationViewController as! UINavigationController
let videoWidth : CGFloat = UIScreen.mainScreen().bounds.size.width
let videoHeight : CGFloat = UIScreen.mainScreen().bounds.size.height - navController.nav

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


class StreamingViewController: UIViewController, OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate {
    
    var session : OTSession?
    var publisher : OTPublisher?
    var subscriber : OTSubscriber?
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var disconnectButton: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    
    var bAudio: Bool
    var bVideo: Bool
    var callRecieverID: String
    
    var m_mode: int
    var m_connectionAttempts: int
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Step 1: As the view is loaded initialize a new instance of OTSession
        session = OTSession(apiKey: ApiKey, sessionId: SessionID, delegate: self)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        // Step 2: As the view comes into the foreground, begin the connection process.
        doConnect()
    }
    
    override func viewDidAppear(animated: Bool) {
        if callRecieverID != "" {
            m_mode = streamingModeOutgoing
            initOutGoingCall()
            
        }else{
            m_mode = streamingModeOutgoing
            m_connectionAttempts = 1
            connectWithToken()
        }
    }


    func initOutGoingCall()
    {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let inputDict = NSMutableDictionary()
        inputDict["callerID"] = ParseHelper().loggedInUser
        inputDict["callerTitle"] = appDelegate.userTitle
        inputDict["recieverID"] = self.callRecieverID
        inputDict["isAudio"] = bAudio.toInt()
        inputDict["isVideo"] = bVideo.toInt()

        m_connectionAttempts = 1
        ParseHelper.saveSessionToParse(inputDict)
    }
    
    func sessionSaved() {
        connectWithToken()
        
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
    
    func doDisconnect() {
        session?.disconnect()
    }
    
    func doPublish() {
        publisher = OTPublisher(delegate: self)
        publisher?.publishAudio = bAudio
        publisher?.publishVideo = bVideo
        session?.publish(publisher)
        
        
        
        
        var maybeError : OTError?
        session?.publish(publisher, error: &maybeError)
        
        if let error = maybeError {
            showAlert(error.localizedDescription)
        }
        
        view.addSubview(publisher!.view)
        publisher!.view.frame = CGRect(x: 5.0, y: 5.0, width: videoWidth, height: videoHeight)
        view.bringSubviewToFront(disconnectButton)
        view.bringSubviewToFront(statusLabel)
        
        print(publisher?.view.frame.origin.x, publisher?.view.frame.origin.y, publisher?.view.frame.size.width, publisher?.view.frame.size.height)
        
        publisher?.view.layer.cornerRadius = 10.0
        publisher?.view.layer.masksToBounds = true
        publisher?.view.layer.borderWidth = 5.0
        publisher?.view.layer.borderWidth = UIColor.yellowColor().CGColor
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
    
    func doUnpublish() {
        session?.unpublish(publisher)
    }
    
    // MARK: - OTSession delegate callbacks
    
    func sessionDidConnect(session: OTSession) {
        NSLog("sessionDidConnect (\(session.sessionId))")
        NSLog("connectionId (\(session.connection.connectionId))")
        NSLog("creationTime (\(session.connection.creationTime))")

        disconnectButton.hidden = false
        view.bringSubviewToFront(disconnectButton)
        statusLabel.text = "Connected, waiting for stream..."
        view.bringSubviewToFront(statusLabel)

        
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
            
            print("screenheight"/(videoHeight))
            print("navheight"/(videoHeight))
            
            view.bringSubviewToFront(disconnectButton)
            
            if publisher {
                view.bringSubviewToFront(publisher?.view)
            }

        }
        
        subscriber?.view.layer.cornerRadius = 10.0
        subscriber?.view.layer.masksToBounds = true
        subscriber?.view.layer.borderWidth = 5.0
        subscriber?.view.layer.borderWidth = UIColor.grayColor().CGColor
        
        statusLabel.text = "Connected, waiting for stream..."
        view.bringSubviewToFront(statusLabel)
        
    }
    
    func subscriber(subscriber: OTSubscriberKit, didFailWithError error : OTError) {
        NSLog("subscriber %@ didFailWithError %@", subscriber.stream.streamId, error)
        print("code: \(error.localizedDescription)")
        
        statusLabel.text = "Error recieving video feed, disconnecting..."
        view.bringSubviewToFront(statusLabel)
        callSelector(doneStreaming(), object: nil, delay: 5.0)
    }
    
    @IBAction func doneStreaming() {
        disConnectAndGoBack()
        }
    
    func disConnectAndGoBack(){
        doUnpublish()
        doUnsubscribe()
        disconnectButton.hidden = true
        //        ParseHelper

                ParseHelper.setPollingTimer(true)
        self.dismissViewControllerAnimated(true, completion: nil)
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
    
    //fix
    func publisher(publisher: OTPublisherKit, didFailWithError error: OTError) {
        NSLog("publisher didFailWithError %@", error)
        NSLog("publisher didFailWithError %@", error)
        NSLog("publisher didFailWithError %@", error)
        
        statusLabel.text = "Error recieving video feed, disconnecting..."
        view.bringSubviewToFront(statusLabel)

    }

    // MARK: - Helpers
    
    func showAlert(message: String) {
        // show alertview on main UI
        dispatch_async(dispatch_get_main_queue()) {
            
            let al = UIAlertController(title: "OTError", message:message, preferredStyle: UIAlertControllerStyle.Alert)
            
            al.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in print("Foo")}))
            
            self.presentViewController(al, animated: true, completion: nil)
        }
}


    func connectWithToken() {
        print("connectWithToken")
        doConnect()
        
        self.callSelector(done, object: <#T##AnyObject?#>, delay: <#T##NSTimeInterval#>)
}
}




extension NSObject {
    
    func callSelectorAsync(selector: Selector, object: AnyObject?, delay: NSTimeInterval) -> NSTimer {
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: selector, userInfo: object, repeats: false)
        return timer
    }
    
    func callSelector(selector: Selector, object: AnyObject?, delay: NSTimeInterval) {
        
        let delay = delay * Double(NSEC_PER_SEC)
        var time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            NSThread.detachNewThreadSelector(selector, toTarget:self, withObject: object)
        })
    }
}

