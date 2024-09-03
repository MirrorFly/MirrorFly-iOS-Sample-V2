//
//  BaseViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 08/08/22.
//

import Foundation
import UIKit
import MirrorFlySDK

public protocol MessageDelegate {
    func whileUpdatingMessageStatus(messageId: String, chatJid: String, status: MessageStatus)
    func whileUpdatingTheirProfile(for jid: String, profileDetails: ProfileDetails)
}

public protocol RefreshChatDelegate {
    func refresh()
}

public func print(items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { "*\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
}

class BaseViewController : UIViewController {
    
    private let TAG = "BaseViewController"
    var getProfileDetails: ProfileDetails!
    var messages : [ChatMessage]  = []
    var fetchMessageListQuery : FetchMessageListQuery? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CallManager.setMobileCallActionDelegate(delegate: self)
        ChatManager.shared.messageEventsDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CallManager.setMobileCallActionDelegate(delegate: nil)
    }
    
    func disableIdleTimer(disable : Bool) {
        UIApplication.shared.isIdleTimerDisabled = disable
    }
    
    func keyboardShowHide() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
    }
    
    func requestLogout() {
        startLoading(withText: pleaseWait)
        
        ChatManager.logoutApi { [weak self] isSuccess, flyError, flyData in
            
            if isSuccess {
                CommonDefaults.appLockPassword = ""
                CommonDefaults.appLockenable = false
                CommonDefaults.appFingerprintenable = false

                ChatManager.getPrivateChatList { isSuccess, error, data in
                    if let list = data["data"] as? [RecentChat] {
                        for chat in list {
                            ChatManager.setPrivateChat(jid: chat.jid, isPrivate: false)
                        }
                    }
                }

                UIApplication.shared.applicationIconBadgeNumber = 0
                self?.stopLoading()
                Utility.saveInPreference(key: isProfileSaved, value: false)
                Utility.saveInPreference(key: isLoggedIn, value: false)
                if ENABLE_CHAT_HISTORY && CommonDefaults.chatHistoryEnabled {
                    Utility.saveInPreference(key: isRecentChatLoad, value: false)
                }
                ChatManager.disconnect()
                CallManager.disconnectCall()
                ChatManager.resetXmppResource()
                var controller : OTPViewController?
                if #available(iOS 13.0, *) {
                    controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "OTPViewController")
                } else {
                   
                    controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OTPViewController") as? OTPViewController
                }
                let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                if let navigationController = window?.rootViewController  as? UINavigationController, let otpViewController = controller {
                    navigationController.popToRootViewController(animated: false)
                    navigationController.pushViewController(otpViewController, animated: false)
                }
                

            }else{
                print("Logout api error : \(String(describing: flyError))")
                self?.stopLoading()
            }
        }
    }

}


/**
 * General call action Delegate to detect from mobile (other applications)
 * It is not used to application call actions
 */
extension BaseViewController : MobileCallActionDelegate {
    @objc func didCallAnswered() {
        print("\(TAG) didCallAnswered")
    }
    
    @objc func whileDialing() {
        print("\(TAG) whileDialing")
    }
    
    @objc func didCallDisconnected() {
        print("\(TAG) didCallDisconnected")
    }
    
    @objc func whileIncoming() {
        print("\(TAG) whileIncoming")
    }
}

// Base view to update message and message details from other views with inherite base view controller
extension BaseViewController: MessageEventsDelegate {
    func onMessageReceived(message: MirrorFlySDK.ChatMessage, chatJid: String) {
        if let profileDerails = self.getProfileDetails, (profileDerails.jid == message.chatUserJid) {
            self.appendMessage(message: message)
        }
    }
    
    func onMessageEdited(message: MirrorFlySDK.ChatMessage) {
        if let indexpath = chatMessages.indices(where: {$0.messageId == message.messageId}) {
            chatMessages[indexpath.section][indexpath.row] = message
        }
    }
    
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MirrorFlySDK.MessageStatus) {
        if chatMessages.isEmpty { return }
        if let indexpath = chatMessages.indices(where: {$0.messageId == messageId}) {
            if let message = ChatManager.getMessageOfId(messageId: messageId) {
                chatMessages[indexpath.section][indexpath.row] = message
            }
        }
    }
    
    func onMediaStatusUpdated(message: MirrorFlySDK.ChatMessage) {
        if chatMessages.isEmpty { return }
        let isCarbon = message.isMessageSentByMe && message.isCarbonMessage
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == message.messageId}) {
            if isCarbon {
                if let mediaDownloadStatus = message.mediaChatMessage?.mediaDownloadStatus {
                    chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus = mediaDownloadStatus
                }
            } else {
                if let mediaUploadStatus = message.mediaChatMessage?.mediaUploadStatus {
                    chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaUploadStatus = mediaUploadStatus
                }
            }
        }
    }
    
    func onMediaStatusFailed(error: String, messageId: String, errorCode: Int) {
        if chatMessages.isEmpty { return }
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == messageId}), let message = ChatManager.getMessageOfId(messageId: messageId) {
            let isCarbon = message.isMessageSentByMe && message.isCarbonMessage
            if isCarbon {
                if let mediaDownloadStatus = message.mediaChatMessage?.mediaDownloadStatus {
                    chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus = mediaDownloadStatus
                }
            } else {
                if let mediaUploadStatus = message.mediaChatMessage?.mediaUploadStatus {
                    chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaUploadStatus = mediaUploadStatus
                }
            }
        }
    }
    
    func onMediaProgressChanged(message: MirrorFlySDK.ChatMessage, progressPercentage: Float) {
        if chatMessages.isEmpty { return }
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == message.messageId}) {
            if let mediaProgressStatus = message.mediaChatMessage?.mediaProgressStatus {
                chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaProgressStatus = mediaProgressStatus
            }
        }
    }
    
    func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        if chatMessages.isEmpty { return }
        getAllInitialMessages()
    }
    
    func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        if chatMessages.isEmpty { return }
        messageIds.forEach { messageId in
            if let indexPath = chatMessages.indexPath(where: {$0.messageId == messageId}), let getMessage = ChatManager.getMessageOfId(messageId: messageId) {
                chatMessages[indexPath.section][indexPath.row] = getMessage
            }
        }
    }
    
    func showOrUpdateOrCancelNotification() {
        
    }
    
    func onMessagesCleared(toJid: String, deleteType: String?) {
        if toJid == getProfileDetails.jid {
            getAllInitialMessages()
        }
    }
    
    func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {
        if chatMessages.isEmpty { return }
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == messageId}) {
            chatMessages[indexPath.section][indexPath.row].isMessageStarred = favourite
        }
    }
    
    func onMessageTranslated(message: MirrorFlySDK.ChatMessage, jid: String) {
        if chatMessages.isEmpty { return }
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == message.messageId}) {
            chatMessages[indexPath.section][indexPath.row] = message
        }
    }
    
    func clearAllConversationForSyncedDevice() {
        getAllInitialMessages()
    }
    
    func getAllInitialMessages() {
        return
        guard let jid = getProfileDetails?.jid else {
            return
        }
        var fetchMessageListParams = FetchMessageListParams()
        fetchMessageListParams.chatId = jid
        fetchMessageListParams.limit = 100
        fetchMessageListQuery = FetchMessageListQuery(fetchMessageListParams: fetchMessageListParams)
        fetchMessageListQuery?.loadMessages { [self] isSuccess, error, data in
            var result = data
            if isSuccess {
                if let chatmessages = result.getData() as? [ChatMessage] {
                    chatMessages.removeAll()
                    getAllMessages.removeAll()
                    getAllMessages.append(contentsOf: messages)
                    let values = groupAMessage(messages: getAllMessages)
                    chatMessages.append(contentsOf: values)
                }
            }
        }
    }
    
    func groupAMessage(messages: [ChatMessage]) -> [[ChatMessage]] {
        var chatMessages  = [ [ChatMessage]]()
        let groupedMessages = Dictionary(grouping: messages) { (element) -> Date in
            let date : Date
            if element.messageChatType == .singleChat {
                date = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: element.messageSentTime)
            } else {
                date = DateFormatterUtility.shared.convertGroupMillisecondsToDateTime(milliSeconds: element.messageSentTime)
            }
            return date.reduceToMonthDayYear()
        }
        let sortedKeys = groupedMessages.keys.sorted()
        sortedKeys.forEach { (key) in
            if let  values = groupedMessages[key] {
                print("#section keys \(key) \(values.count) \(chatMessages.count) ")
                chatMessages.insert(values.reversed() , at: 0)
            }
        }
        return chatMessages
    }
}

extension BaseViewController {
    
    // To check whether the message is exist or not
    func isMessageExist(messageId : String) -> Bool{
        let tempMessages = chatMessages.reversed()
        for (index, messageArray) in tempMessages.enumerated() {
            print("isMessageExist \(index)")
            for message in messageArray {
                if messageId == message.messageId {
                    print("isMessageExist if messageId == message.messageId")
                    return true
                }
            }
            if index > 1 {
                return false
            }
        }
        return false
    }
    
    // Append new message to message array
    private func appendMessage(message: ChatMessage) {
        if isMessageExist(messageId: message.messageId) {
            return
        }
        executeOnMainThread { [weak self] in
            self?.fetchMessageListQuery?.setLastMessage(messageId: message.messageId)
        }
        if chatMessages.count == 0 {
            addGroupedMessage(messages: [message])
        } else {
            let index = chatMessages[0].firstIndex(where: { $0.messageSentTime < message.messageSentTime})
            chatMessages[0].insert(message, at: index ?? 0)
           // getAllMessages.append(message)
        }
    }
    
    // Group a message by day
    private func addGroupedMessage(messages:  [ChatMessage]) {
        let groupedMessages = Dictionary(grouping: messages) { (element) -> Date in
            let messageDate = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: element.messageSentTime)
            return messageDate.reduceToMonthDayYear()
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let sortedKeys = groupedMessages.keys.sorted()
        sortedKeys.forEach { (key) in
            let values = groupedMessages[key]
            chatMessages.append(values ?? [])
        }
    }
}
