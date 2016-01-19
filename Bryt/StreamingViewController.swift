//
//  ViewController.swift
//  Bryt
//
//  Created by Malcolm Parrish on 10/30/15.
//  Copyright © 2015 Bryt. All rights reserved.
//


import UIKit
import Parse



//OpenTok
let ApiKey = "45458232"
let SessionID = "1_MX40NTQ1ODIzMn5-MTQ1MjEwNTk0MTA4NH5lZWIvaUs2RjFuZTBQNmxCdVpYWGdReGF-fg"
let Token = "T1==cGFydG5lcl9pZD00NTQ1ODIzMiZzaWc9ZTIxZjBhNTg1OTkyYWNjYzc5MTYyYTdkMTA1MWY5ZDdmNWRhZGYwODpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTFfTVg0ME5UUTFPREl6TW41LU1UUTFNakV3TlRrME1UQTROSDVsWldJdmFVczJSakZ1WlRCUU5teENkVnBZV0dkUmVHRi1mZyZjcmVhdGVfdGltZT0xNDUyMTA2MDk0Jm5vbmNlPTAuMzk3MjQwNzkwNTg3MDU2NjQmZXhwaXJlX3RpbWU9MTQ1NDY5Nzg1MSZjb25uZWN0aW9uX2RhdGE9"

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
    
    var bAudio: Bool?
    var bVideo: Bool?
    var callReceiverID: String?
    
    var m_mode: Int?
    var m_connectionAttempts: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session = OTSession(apiKey: ApiKey, sessionId: SessionID, delegate: self)
        
    }

    
    override func viewWillAppear(animated: Bool) {
        doConnect()
    }
    
    override func viewDidAppear(animated: Bool) {
        if callReceiverID != "" {
            initOutGoingCall()
            
        }else{
            m_connectionAttempts = 1
            connectWithToken()
        }
    }
    
    
    func initOutGoingCall()
    {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        var inputDict = Dictionary<String, AnyObject>()
        inputDict["callerID"] = ParseHelper.loggedInUser?.objectId
        inputDict["callerTitle"] = appDelegate.userTitle
        inputDict["receiverID"] = self.callReceiverID
        
        inputDict["isAudio"] = bAudio
        inputDict["isVideo"] = bVideo
        
        m_connectionAttempts = 1
        ParseHelper.saveSessionToParse(inputDict)
    }
    
    func sessionSaved() {
        connectWithToken()
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
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
        publisher?.publishAudio = bAudio!
        publisher?.publishVideo = bVideo!
        
        var maybeError : OTError?
        session?.publish(publisher, error: &maybeError)
        
        if let error = maybeError {
            showAlert(error.localizedDescription)
        }
        guard let video = publisher?.view else{
            return
        }
        
        
        view.addSubview(video)
        video.translatesAutoresizingMaskIntoConstraints = false                      //tells us we will let autolayout handle
        video.topAnchor.constraintEqualToAnchor(self.topLayoutGuide.bottomAnchor).active = true
        video.bottomAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true

        video.trailingAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        video.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true

        view.bringSubviewToFront(disconnectButton)
        view.bringSubviewToFront(statusLabel)
        
        //stopTimer

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
            view.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false                      //tells us we will let autolayout handle
            view.topAnchor.constraintEqualToAnchor(self.topLayoutGuide.bottomAnchor).active = true
            view.bottomAnchor.constraintEqualToAnchor(self.bottomLayoutGuide.topAnchor).active = true
            
            view.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
            view.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
            
            if (publisher != nil) {
                view.bringSubviewToFront((publisher?.view)!)
            }
            
        }
        
        subscriber?.view.layer.cornerRadius = 10.0
        subscriber?.view.layer.masksToBounds = true
        subscriber?.view.layer.borderWidth = 5.0
//        subscriber?.view.layer.borderColor = UIColor.grayColor().CGColor
        
        statusLabel.text = "Connected, waiting for stream..."
        view.bringSubviewToFront(statusLabel)
        
    }
    
    func subscriber(subscriber: OTSubscriberKit, didFailWithError error : OTError) {
        NSLog("subscriber %@ didFailWithError %@", subscriber.stream.streamId, error)
        print("code: \(error.localizedDescription)")
        
        statusLabel.text = "Error receiving video feed, disconnecting..."
        view.bringSubviewToFront(statusLabel)
        callSelector("doneStreaming", object: nil, delay: 5.0)
        
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

