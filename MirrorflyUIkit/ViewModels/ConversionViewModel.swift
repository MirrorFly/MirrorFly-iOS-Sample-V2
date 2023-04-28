//
//  ConversionViewModel.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya on 02/11/22.
//

import Foundation
import MirrorFlySDK

class ChatViewModel  {
    
    //MARK: Update starred and unstarred messages
    func updateFavouriteStatus(messageId: String,chatUserId: String,isFavourite:Bool,chatType: ChatType,completionHandler : @escaping FlyCompletionHandler) {
        ChatManager.updateFavouriteStatus(messageId: messageId, chatUserId: chatUserId, isFavourite: isFavourite, chatType: chatType) { (isSuccess, error, data) in
            if isSuccess {
                completionHandler(isSuccess, nil, data)
            } else {
                completionHandler(isSuccess, error, [:])
            }
            
        }
    }
    
    //MARK: Get all favourite messages
    func getAllFavouriteList() -> [ChatMessage] {
        return ChatManager.getFavouriteMessages()
    }
}
