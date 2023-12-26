//
//  DeleteViewModel.swift
//  MirrorflyUIkit
//
//  Created by sowmiya on 27/09/22.
//

import Foundation

import MirrorFlySDK

class DeleteViewModel  {
    func getDeleteMessageForMe(jid: String,messageIdList: [String], deleteChatType: ChatType, completionHandler : @escaping FlyCompletionHandler) {
        if !jid.isEmpty {
            let isRevokeMediaAccess = Utility.getBoolFromPreference(key: revokeMediaAccess)
            ChatManager.deleteMessagesForMe(toJid: jid, messageIdList: messageIdList, deleteChatType: deleteChatType,isRevokeMediaAccess: isRevokeMediaAccess) { (isSuccess, error, data) in
                completionHandler(isSuccess, error, data)
            }
        } else {
            completionHandler(false, nil, [:])
        }
    }
    
    func getDeleteMessageForEveryOne(jid: String,messageIdList: [String], deleteChatType: ChatType, completionHandler : @escaping FlyCompletionHandler) {
        if !jid.isEmpty {
            let isRevokeMediaAccess = Utility.getBoolFromPreference(key: revokeMediaAccess)
            messageIdList.forEach { messageId in
                ChatManager.deleteMessagesForEveryone(toJid: jid, messageIdList: [messageId], deleteChatType: deleteChatType,isRevokeMediaAccess: isRevokeMediaAccess) { (isSuccess, error, data) in
                    completionHandler(isSuccess, error, data)
                }
            }
        } else {
            completionHandler(false, nil, [:])
        }
    }
}
