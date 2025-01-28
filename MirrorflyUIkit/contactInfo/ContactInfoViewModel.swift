//
//  ContactInfoViewModel.swift
//  MirrorflyUIkit
//
//  Created by John on 29/01/22.
//

import Foundation
import MirrorFlySDK

class ContactInfoViewModel : NSObject {
    
    func getContactInfo(jid : String) -> ProfileDetails? {
        return ChatManager.getContact(jid: jid)
    }
    
    func getLastSeen(jid : String, completionHandler : @escaping (String) -> Void) {
        ChatManager.getUserLastSeen(for: jid) { [self] isSuccess, flyError, flyData in
            var data  = flyData
            if isSuccess {
                
                guard let lastSeenTime = data.getData() as? String else{
                    return
                }
                if (Int(lastSeenTime) == 0) {
                    completionHandler(online.localized)
                }
                else {
                    completionHandler(calculateLastSeen(lastSeenTime: lastSeenTime))
                }
            } else{
                completionHandler("error")
            }
        }
    }
    
    func calculateLastSeen(lastSeenTime : String) -> String{
        let dateFormat = DateFormatter()
        dateFormat.timeStyle = .short
        dateFormat.dateStyle = .short
        dateFormat.doesRelativeDateFormatting = true
        let dateString = dateFormat.string(from: Date(timeIntervalSinceNow: TimeInterval(-(Int(lastSeenTime) ?? 0))))
        let timeDifference = "\(NSLocalizedString(lastSeen.localized, comment: "")) \(dateString)"
        let lastSeen = timeDifference.lowercased()
        return lastSeen
    }
    
    func muteNotification(jid : String, mute : Bool) {
        ChatManager.updateChatMuteStatus(jidList: [jid], mute: mute)
    }
    
}
