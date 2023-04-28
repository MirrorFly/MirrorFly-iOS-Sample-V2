//
//  MessageInfoViewModel.swift
//  MirrorflyUIkit
//
//  Created by John on 17/10/22.
//

import Foundation
import MirrorFlySDK


class MessageInfoViewModel {
    
    func getSingleChatSeenStatus(messageId : String) -> MessageReceipt? {
        ChatManager.getSingleChatMessageSeenReceipt(messageId: messageId)
    }
    
    func getSingleChatDeliveredStatus(messageId : String) -> MessageReceipt? {
        ChatManager.getSingleChatMessageDeliveredReceipt(messageId: messageId)
    }
    
    func getSingleChatAcknowledgelStatus(messageId : String) -> MessageReceipt? {
        ChatManager.getSingleChatMessageAcknowledgeReceipt(messageId: messageId)
    }
    
    func groupMessageDeliveredList(messageId : String, groupId : String) -> (deliveredParticipantList : [MessageReceipt], deliveredCount : Int, totalParticipatCount : Int) {
        return GroupManager.shared.getMessageDeliveredListBy(messageId: messageId, groupId: groupId)
    }
    
    func groupMessageSeenList(messageId : String, groupId : String) -> (seenParticipantList : [MessageReceipt], seenCount : Int, totalParticipatCount : Int) {
        return GroupManager.shared.getMessageSeenListBy(messageId: messageId, groupId: groupId)
    }
    
    func getMessageDeliveredDate(deliveryTime : Double) -> String {
        return DateFormatterUtility.shared.milliSecondsToMessageInfoDateFormat(milliSec: deliveryTime)
    }
    
    func sortListByName(receiptList : [MessageReceipt]) -> [MessageReceipt] {
        return receiptList.sorted{ $0.profileDetails?.name.capitalized ?? "" < $1.profileDetails?.name.capitalized ?? "" }
    }
}
