//
//  ChatViewModel.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 16/11/21.
//

import Foundation
import MirrorFlySDK

class
RecentChatViewModel  {
  
    func getRecentChatList(isBackground: Bool, completionHandler:  @escaping ([RecentChat]?)-> Void) {
        if isBackground {
            ChatManager.getRecentChatList { (isSuccess, flyError, resultDict) in
                let flydata = resultDict
                completionHandler(flydata[FlyConstants.data] as? [RecentChat])
            }
        } else {
            completionHandler(ChatManager.getRecentChatList())
        }
    }

    func getRecentChatListWithArchive(isBackground: Bool, completionHandler:  @escaping ([RecentChat]?)-> Void) {
        if isBackground {
            ChatManager.getRecentChatListIncludingArchive { (isSuccess, flyError, resultDict) in
                let flydata = resultDict
                completionHandler(flydata[FlyConstants.data] as? [RecentChat])
            }
        } else {
            completionHandler(ChatManager.getRecentChatListIncludingArchived())
        }
    }
    
    func getMessageOfId(messageId: String, completionHandler:  @escaping (ChatMessage?)-> Void) {
        if messageId.isEmpty {
            ChatManager.getRecentChatList { (isSuccess, flyError, resultDict) in
                var flydata = resultDict
                print(flydata.getData())
            }
        } else {
            completionHandler(ChatManager.getMessageOfId(messageId: messageId))
        }
    }
    
    func deleteRecentChats(jids: [String], completionHandler: @escaping FlyCompletionHandler) {
        ChatManager.deleteRecentChats(jids: jids, completionHandler: completionHandler)
    }

    func getChatReadUnread(jids: [String], isRead: Bool, fullMarkAsRead: Bool, completionHandler:  @escaping (Bool?)-> Void) {
        if jids.count > 0 {
            if isRead {
                ChatManager.markConversationAsRead(for: jids,fullMarkAsRead: fullMarkAsRead)
                completionHandler(true)
            } else {
                ChatManager.markConversationAsUnread(for: jids)
                completionHandler(true)
            }
        }
    }

    func getPinChat(jid: String, isPin: Bool, completionHandler:  @escaping (Bool?)-> Void) {
        if !jid.isEmpty {
            ChatManager.updateRecentChatPinStatus(jid: jid, pinRecentChat: isPin)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }

    func getMuteChat(jid: String, isMute: Bool, completionHandler:  @escaping (Bool?)-> Void) {
        if !jid.isEmpty {
            ChatManager.updateChatMuteStatus(jid: jid, muteStatus: isMute)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }

    func getArchiveChat(jids: [String], isArchive: Bool, completionHandler : @escaping FlyCompletionHandler) {
        if jids.count > 0 {
            ChatManager.updateArchiveUnArchiveChat(jids, isArchive) { isSuccess, error, data in
                completionHandler(isSuccess, error, data)
            }
        }
    }

    func getGroupDetails(groupJid : String) -> ProfileDetails? {
        return GroupManager.shared.getAGroupFromLocal(groupJid: groupJid)
    }
    
    func getRecentChat(jid : String)-> RecentChat?{
        return ChatManager.getRechtChat(jid: jid)
    }

}

struct SelectedMessages {
    var isSelected: Bool = false
    var chatMessage: ChatMessage = ChatMessage()
}

struct SelectedForwardMessage {
    var isSelected: Bool = false
    var chatMessage: ChatMessage = ChatMessage()
}
