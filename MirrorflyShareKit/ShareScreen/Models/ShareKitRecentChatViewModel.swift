//
//  ShareKitRecentChatViewModel.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 28/02/23.
//

import Foundation
import MirrorFlySDK

class ShareKitRecentChatViewModel {

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
