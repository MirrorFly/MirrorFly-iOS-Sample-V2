//
//  GroupInfoViewModel.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 09/03/22.
//

import Foundation
import MirrorFlySDK

class GroupInfoViewModel: NSObject {
    
    // MARK: - Public Methods
    
    func getContactInfo(jid : String) -> ProfileDetails? {
        return ChatManager.getContact(jid: jid)
    }
    
    func isBlockedByAdmin(groupJid : String) -> Bool {
        return getContactInfo(jid: groupJid)?.isBlockedByAdmin ?? false
    }
    
    func muteNotification(jid : String, mute : Bool) {
        ChatManager.updateChatMuteStatus(jid: jid, muteStatus: mute)
    }
    
    func updateGroupName(groupID: String, groupName: String,
                         completionHandler: @escaping (_ isSuccess: Bool,
                                                       _ error: FlyError?,
                                                       _ data : [String: Any])-> Void) {
        
        try! GroupManager.shared.updateGroupName(groupJid: groupID,
                                                 groupName: groupName) { isSuccess, error, data in
            completionHandler(isSuccess, error, data)
        }
    }
    
    func updateGroupProfileImage(groupID: String, groupProfileImageUrl: String,
                                 completionHandler: @escaping (Bool) -> Void) {
        
        try! GroupManager.shared.updateGroupProfileImage(groupJid: groupID,
                                                         groupProfileImageUrl: groupProfileImageUrl) { isSuccess, error, data in
            completionHandler(isSuccess)
            
        }
    }
    
    func makeGroupAdmin(groupID: String, userJid: String, completionHandler: @escaping(_ isSuccess: Bool,
                                                                                       _ error: FlyError?,
                                                                                       _ data : [String: Any]) -> Void) {
        
        try! GroupManager.shared.makeAdmin(groupJid: groupID, userJid: userJid) {
            isSuccess, error, data in
            
            completionHandler(isSuccess, error, data)
        }
    }
    
    func removeParticipantFromGroup(groupID: String, removeGroupMemberJid: String,
                                    completionHandler: @escaping (Bool) -> Void) {
        
        try! GroupManager.shared.removeParticipantFromGroup(groupId: groupID,
                                                            removeGroupMemberJid: removeGroupMemberJid) { isSuccess, error, data in
            completionHandler(isSuccess)
        }
    }
    
    func removeGroupProfileImage(groupID: String, completionHandler: @escaping(_ isSuccess: Bool,
                                                                               _ error: FlyError?,
                                                                               _ data : [String: Any])-> Void) {
        
        try! GroupManager.shared.removeGroupProfileImage(groupJid: groupID) { isSuccess, error, data in
            completionHandler(isSuccess, error, data)
        }
    }
    
    func leaveFromGroup(groupID: String, userJid: String,
                        completionHandler: @escaping (Bool) -> Void) {
        
        try! GroupManager.shared.leaveFromGroup(groupJid: groupID, userJid: userJid) { isSuccess,error,data in
            completionHandler(isSuccess)
        }
    }
    
    func deleteGroup(groupID: String, completionHandler: @escaping(_ isSuccess: Bool,
                                                                   _ error: FlyError?,
                                                                   _ data : [String: Any])-> Void) {
        
        try! GroupManager.shared.deleteGroup(groupJid: groupID) { isSuccess, error, data in
            completionHandler(isSuccess, error, data)
        }
    }
    
    func isParticiapntExistingIn(groupJid: String, participantJid: String) -> (doesExist: Bool,
                                                                               message: String) {
        
        let result = GroupManager.shared.isParticiapntExistingIn(groupJid: groupJid,
                                                                 participantJid: participantJid)
        return result
    }
    
    func isGroupAdminMember(participantJid: String, groupJid: String) -> (isAdmin: Bool,
                                                                          message: String) {
        
        let result = GroupManager.shared.isAdmin(participantJid: participantJid, groupJid: groupJid)
        
        return result
    }
    
    func checkContactType(participantJid: String) -> ProfileDetails? {
        
        let result = ChatManager.profileDetaisFor(jid: participantJid)
        
        return result
    }
}

