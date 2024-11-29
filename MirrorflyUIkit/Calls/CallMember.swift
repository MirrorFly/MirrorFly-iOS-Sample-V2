//
//  File.swift
//  MirrorFlyiOS-SDK
//
//  Created by User on 06/07/21.
//

import Foundation
import MirrorFlySDK

class CallMember: NSObject {
    
    var jid : String!
    
    var name : String = ""
    
    var image : String = ""
    
    var color : String = "#20B2AA"
    
    var callStatus : CallStatus = .connecting
    
    var isVideoMuted : Bool = false
    
    var isAudioMuted : Bool = false
    
    var isCaller : Bool = false
    
    var isOnSpeaker : Bool = false
    
    var isOnBackCamera : Bool = false
    
    var videoTrack : RTCVideoTrack? = nil
    
#if arch(arm64)
    var videoTrackView = RTCMTLVideoView(frame: .zero)
#else
    var videoTrackView = RTCEAGLVideoView(frame: .zero)
#endif
    var isVideoTrackAdded: Bool = false
}

enum CallStatus : String {
    case calling = "Calling";
    case ringing = "Ringing";
    case attended = "Attended";
    case connecting = "Connecting";
    case connected = "Connected";
    case disconnected = "Disconnected"
    case reconnecting = "Reconnecting";
    case reconnected = "Reconnected";
    case tryagain = "Unavailable, Try again later"
    case onHold = "Call on Hold"
}
