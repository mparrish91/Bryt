//
//  ViewController.swift
//  Bryt
//
//  Created by Malcolm Parrish on 10/30/15.
//  Copyright © 2015 Bryt. All rights reserved.
//


import UIKit
import Parse

enum streamingMode: Int {
    case streamingModeIncoming = 0
    case streamingModeOutgoing = 1
}


//OpenTok
let ApiKey = "45403342"

// Change to YES to subscribe to your own stream.
let SubscribeToSelf = false


class StreamingViewController: UIViewController, OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate {
    
    var session : OTSession?
    var publisher : OTPublisher?
    var subscriber : OTSubscriber?
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    var bAudio: Bool?
    var bVideo: Bool?
    var callReceiverID: String?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var m_mode: Int?
    var m_connectionAttempts: Int?
    
    
    func showReceiverBusyMsg() {
        statusLabel.text = "Receiver is busy on another call. Please try later."
        self.performSelector("goBack", withObject: nil, afterDelay: 5.0)
    }
    
    func goBack() {
        statusLabel.hidden = true
        dismissViewControllerAnimated(true, completion: nil)
    }
    
 

    override func viewDidLoad() {
        super.viewDidLoad()
        bAudio = true
        
    }

    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionSaved", name:  "kSessionSavedNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showReceiverBusyMsg", name: "kReceiverBusyNotification", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if callReceiverID != "" {
            m_mode = streamingMode.streamingModeOutgoing.rawValue
            initOutGoingCall()
            //connect, publish/subscriber -> will be taken care by
            //sessionSaved observed handler.
            
        }else{
            m_mode = streamingMode.streamingModeIncoming.rawValue
            m_connectionAttempts = 1
            connectWithPublisherToken()
        }
    }
    
    //FIXME: not sure if stream is set correctly with the tuple
    func updateSubscriber() {
        for (key, value) in session!.streams.enumerate() {
            let stream  = value.0 as! OTStream
            
            if stream.connection.connectionId != session?.connection.connectionId {
                subscriber = OTSubscriber(stream: stream, delegate: self)
                break
            }
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
    
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    // MARK: - OpenTok Methods
    
    func sessionSaved() {
        connectWithSubscriberToken()
    }
    
    func connectWithPublisherToken() {
        print("connectWithPublisherToken")
        doConnect(appDelegate.publisherToken!,sessionID: appDelegate.sessionID!)
    }
    
    func connectWithSubscriberToken() {
        print("connectWithSubscriberToken")
        doConnect(appDelegate.subscriberToken!,sessionID: appDelegate.sessionID!)
    }
    
    /**
    * Asynchronously begins the session connect process. Some time later, we will
    * expect a delegate method to call us back with the results of this action.
    */
    func doConnect(token: String, sessionID: String) {
        session = OTSession(apiKey: ApiKey, sessionId: appDelegate.sessionID, delegate: self)
        session?.addObserver(self, forKeyPath: "connectionCount", options: NSKeyValueObservingOptions.New, context: nil)
        
        var maybeError : OTError?
        session!.connectWithToken(token, error: &maybeError)
        if let error = maybeError {
            showAlert(error.localizedDescription)
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
        view.bringSubviewToFront(disconnectButton)
        view.bringSubviewToFront(statusLabel)
        
        video.translatesAutoresizingMaskIntoConstraints = false          //tells us we will let autolayout handle
        video.topAnchor.constraintEqualToAnchor(self.topLayoutGuide.bottomAnchor).active = true
        video.bottomAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        
        video.trailingAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        video.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        
        publisher?.view.layer.cornerRadius = 10.0
        publisher?.view.layer.masksToBounds = true

    }

    func observeValueForKeyPath(keyPath: String, ofObject: AnyObject, change: [String : AnyObject], context: Void) {
    if keyPath == "connectionCount" {
        //this is kept blank for possible implementation
        //in case one wants to handle more than 2 participants.
    }
}


    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    func doSubscribe(stream : OTStream) {
        
        if SubscribeToSelf == true  && stream.connection.connectionId == session?.connection.connectionId ||
            SubscribeToSelf == false  && stream.connection.connectionId != session?.connection.connectionId
        {
            
            if subscriber == nil {
                subscriber = OTSubscriber(stream: stream, delegate: self)
                subscriber?.subscribeToAudio = bAudio!
                subscriber?.subscribeToVideo = bVideo!
                
                var maybeError : OTError?
                session!.subscribe(subscriber, error: &maybeError)
                if let error = maybeError {
                    showAlert(error.localizedDescription)
                    
                }
            }
        }
    }
    
        
        
//        if let session = self.session {
//            subscriber = OTSubscriber(stream: stream, delegate: self)
//            subscriber?.subscribeToAudio = bAudio
//            subscriber?.subscribeToVideo = bVideo
//
//            
//            var maybeError : OTError?
//            session.subscribe(subscriber, error: &maybeError)
//            if let error = maybeError {
//                showAlert(error.localizedDescription)

    
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
        
        statusLabel.text = "Session disconnected..."
        view.bringSubviewToFront(statusLabel)
        
        //for cases when the other party disconnected the session. Fire the timer again.
        self.disconnectButton.hidden = true
        
        //set the polling on.
        ParseHelper.setPollingTimer(true)
        ParseHelper.deleteActiveSession()
        self.dismissViewControllerAnimated(true, completion: nil)

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
        
        //        if subscriber?.stream.streamId == stream.streamId {
        //            doUnsubscribe()
        //        }
        
        if (SubscribeToSelf == false && subscriber != nil && subscriber?.stream.streamId == stream.streamId) {
            doUnsubscribe()
            updateSubscriber()
            statusLabel.text = "Stream dropped, disconnecting..."
            view.bringSubviewToFront(statusLabel)
            
            self.performSelector("doneStreaming", withObject: nil, afterDelay: 5)
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
        print("- description: \(error.localizedDescription)")
        var errorMsg: String?
        
        if let attempts = m_connectionAttempts {
            m_connectionAttempts = attempts
        }
        
        if m_connectionAttempts < 10 {
            m_connectionAttempts = m_connectionAttempts! + 1
            errorMsg = "Session failed to connect - Reconnecting attempt \(m_connectionAttempts)"
            statusLabel.text = errorMsg
            view.bringSubviewToFront(statusLabel)
            
            if m_mode == streamingMode.streamingModeOutgoing.rawValue {
                self.performSelector("connectWithSubscriberToken", withObject: nil, afterDelay: 15.0)
            }else {
                self.performSelector("connectWithPublisherToken", withObject: nil, afterDelay: 15.0)
            }
        }else {
            m_connectionAttempts = 1
            errorMsg = "Session failed to connect - disconnecting now)"
            statusLabel.text = errorMsg
            self.performSelector("doneStreaming", withObject: nil, afterDelay: 10)
        }
    }



    // MARK: - OTSubscriber delegate callbacks
    
    func subscriberDidConnectToStream(subscriberKit: OTSubscriberKit) {
        NSLog("subscriberDidConnectToStream (\(subscriberKit))")
        NSLog("subscriberDidConnectToStream (\(subscriberKit.stream.connection.connectionId))")
        
        if let view = subscriber?.view {
            view.addSubview(view)
            disconnectButton.hidden = false
            view.translatesAutoresizingMaskIntoConstraints = false                      //tells us we will let autolayout handle
            view.topAnchor.constraintEqualToAnchor(self.topLayoutGuide.bottomAnchor).active = true
            view.bottomAnchor.constraintEqualToAnchor(self.bottomLayoutGuide.topAnchor).active = true
            
            view.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
            view.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        }
        
        if (publisher != nil) {
            view.bringSubviewToFront((publisher?.view)!)
            view.bringSubviewToFront(disconnectButton)
            view.bringSubviewToFront(statusLabel)
        }
        
        statusLabel.text = "Connected and streaming..."
        view.bringSubviewToFront(statusLabel)
        
    }
    
    func subscriber(subscriber: OTSubscriberKit, didFailWithError error : OTError) {
        NSLog("subscriber %@ didFailWithError %@", subscriber.stream.streamId, error)
        print("- code: \(error.code)")
        print("- description: \(error.localizedDescription)")
        
        statusLabel.text = "Error receiving video feed, disconnecting..."
        view.bringSubviewToFront(statusLabel)
        self.performSelector("doneStreaming", withObject: nil, afterDelay: 5.0)
        
    }
    
    func subscriberVideoEnabled(subscriber: OTSubscriberKit!, reason: OTSubscriberVideoEventReason) {
        NSLog("subscriber starting to receive video %@", subscriber.stream.streamId)
        statusLabel.text = "Receiving Stream..."
        view.bringSubviewToFront(statusLabel)
    }
    

    // MARK: - OTPublisher delegate callbacks
    
    func publisher(publisher: OTPublisherKit, streamCreated stream: OTStream) {
        NSLog("publisher streamCreated %@", stream)
        NSLog("- publisher.session:  %@", publisher.session.sessionId)
        NSLog("- publisher.name:  %@", publisher.name)
        
        
        // Step 3b: (if YES == subscribeToSelf): Our own publisher is now visible to
        // all participants in the OpenTok session. We will attempt to subscribe to
        // our own stream. Expect to see a slight delay in the subscriber video and
        // an echo of the audio coming from the device microphone.
        if subscriber == nil && SubscribeToSelf {
            doSubscribe(stream)
        }
        
        statusLabel.text = "Started your camera feed....."
        view.bringSubviewToFront(statusLabel)
    }
    
    func publisher(publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        NSLog("publisher streamDestroyed %@", stream)
        
        if subscriber?.stream.streamId == stream.streamId {
            doUnsubscribe()
        }
        statusLabel.text = "Stopping your camera feed..."
        view.bringSubviewToFront(statusLabel)
    }
    
    func publisher(publisher: OTPublisherKit, didFailWithError error: OTError) {
        print(publisher)
        NSLog("publisher didFailWithError %@", error)
        NSLog("- error code: %@", error.code)
        NSLog("- description %@", error.description)
        
        statusLabel.text = "Failed to share your camera feed, disconnecting..."
        view.bringSubviewToFront(statusLabel)
        self.performSelector("doneStreaming", withObject: nil, afterDelay: 5.0 )

    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    
        statusLabel = nil
        disconnectButton = nil
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
    
    
    @IBAction func touchDisconnect(sender: AnyObject) {
        disConnectAndGoBack()
    }


    
    func disConnectAndGoBack(){
        doUnpublish()
        doDisconnect()
        doUnsubscribe()  //not sure if I need this too
        
        disconnectButton.hidden = true
        ParseHelper.deleteActiveSession()
        
        //set the polling on
        ParseHelper.setPollingTimer(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}



