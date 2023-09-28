//
//  NotificationService.swift
//  notificationextention
//
//  Created by User on 10/11/21.
//

import UserNotifications
import AVFoundation
import AudioToolbox
import MirrorFlySDK

let LICENSE_KEY = "xxxxxxxxx"
let CONTAINER_ID = "xxxxxxxxx"
let IS_LIVE = false
let APP_NAME = "UiKit"


let isHideNotificationContent = false

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    var notificationIDs = [String]()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        let payloadType = bestAttemptContent?.userInfo["type"] as? String
        ChatManager.setAppGroupContainerId(id: CONTAINER_ID)
        ChatManager.initializeSDK(licenseKey: LICENSE_KEY) { isSuccess, error, data in
        }
        print("#push-api withContentHandler received")
        if payloadType == "media_call" {
            NotificationExtensionSupport.shared.didReceiveNotificationRequest(request.content.mutableCopy() as? UNMutableNotificationContent, appName: APP_NAME, onCompletion: { [self] bestAttemptContent in
                if isHideNotificationContent {
                    bestAttemptContent?.title = APP_NAME
                } else {
                    if let userInfo = bestAttemptContent?.userInfo["message_id"] {
                        bestAttemptContent?.title = encryptDecryptData(key: userInfo as? String ?? "", data: bestAttemptContent?.title ?? "", encrypt: false)
                        print("Push Show title: \(bestAttemptContent?.title ?? "") body: \(bestAttemptContent?.body ?? ""), ID - \(userInfo)")
                    }
                }
                self.bestAttemptContent = bestAttemptContent
                contentHandler(self.bestAttemptContent!)
            })
        } else if payloadType == "adminblock" {
            ChatSDK.Builder.initializeDelegate()
            NotificationMessageSupport.shared.handleAdminBlockNotification(request.content.mutableCopy() as? UNMutableNotificationContent) {  bestAttemptContent in
                contentHandler(bestAttemptContent!)
            }
        } else {
            /// Handle Push messages
            ChatSDK.Builder.initializeDelegate()
            NotificationMessageSupport.shared.didReceiveNotificationRequest(request.content.mutableCopy() as? UNMutableNotificationContent, appName: APP_NAME ,onCompletion: { [self] bestAttemptContents in
            let userId = (request.content.userInfo["group_id"] as? String ?? "").isEmpty ? request.content.userInfo["from_user"] as? String ?? "" : request.content.userInfo["group_id"] as? String ?? ""
            self.checkForDeliveredNotification(userId, isGroup: !((request.content.userInfo["group_id"] as? String ?? "").isEmpty)) { notification in
                if let notify = notification {
                    //for list in notification {
                        self.removeNotification(notify)
                //}
                }
            }
                FlyLog.DLog(param1: "#notification request ID", param2: "\(request.identifier)")
                let center = UNUserNotificationCenter.current()
                let (messageCount, chatCount) = ChatManager.getUnreadMessageAndChatCountForUnmutedUsers()
                if isHideNotificationContent {
                    var titleContent = emptyString()
                    if chatCount == 1{
                        titleContent = "\(messageCount) \(messageCount == 1 ? "message" : "messages")"
                    } else {
                        titleContent = "\(messageCount) messages from \(chatCount) chats"
                    }
                    bestAttemptContents?.title = APP_NAME + " (\(titleContent))"
                    bestAttemptContents?.body = "New Message"
                } else {
                    if let userInfo = bestAttemptContents?.userInfo["message_id"] {
                        print("Push Show title: \(bestAttemptContents?.title ?? "") body: \(bestAttemptContents?.body ?? ""), ID - \(userInfo)")
                        FlyLog.DLog(param1: "NotificationMessageSupport id ", param2: "\(bestAttemptContents?.title ?? "") body: \(bestAttemptContents?.body ?? "")")
                    }
                }
                var canVibrate = true
                let isMuted = ContactManager.shared.getUserProfileDetails(for: bestAttemptContents?.userInfo["from_user"] as? String ?? "")?.isMuted ?? false
                if !isMuted || !(ChatManager.isArchivedSettingsEnabled() && ChatManager.getRechtChat(jid: bestAttemptContents?.userInfo["from_user"] as? String ?? "")?.isChatArchived ?? false){
                    bestAttemptContents?.badge = messageCount as? NSNumber
                }

                let chatType = (bestAttemptContents?.userInfo["chat_type"] as? String ?? "")
                let messageId = (self.bestAttemptContent?.userInfo["message_id"] as? String ?? "").components(separatedBy: ",").last ?? ""

                self.bestAttemptContent = bestAttemptContents
                guard let myJid = try? FlyUtils.getMyJid() else {
                    return
                }

                if ChatManager.getMessageOfId(messageId: messageId)?.senderUserJid == myJid && (chatType == "chat" || chatType == "normal") {
                    if !FlyUtils.isValidGroupJid(groupJid: ChatManager.getMessageOfId(messageId: messageId)?.chatUserJid) {
                        self.bestAttemptContent?.title = "You"
                    }
                    canVibrate = false
                    self.bestAttemptContent?.sound = .none
                } else if ChatManager.getMessageOfId(messageId: messageId)?.senderUserJid != myJid {
                    if isMuted || (ChatManager.isArchivedSettingsEnabled() && ChatManager.getRechtChat(jid: bestAttemptContents?.userInfo["from_user"] as? String ?? "")?.isChatArchived ?? false) {
                        self.bestAttemptContent?.sound = .none
                        canVibrate = false
                    } else if !(CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("Default") ?? false) && !(CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("None") ?? false) && CommonDefaults.notificationSoundEnable  {
                        self.bestAttemptContent?.sound = UNNotificationSound(named: UNNotificationSoundName((CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.file.rawValue] ?? "") + "." + (CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.extensions.rawValue] ?? "")))
                    } else if CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("Default") ?? false && CommonDefaults.notificationSoundEnable {
                        self.bestAttemptContent?.sound = .default
                    } else if CommonDefaults.notificationSoundEnable == false || CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("None") ?? false {
                        self.bestAttemptContent?.sound = CommonDefaults.vibrationEnable ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "1-second-of-silence.mp3"))  : nil
                    }
                } else if self.bestAttemptContent?.userInfo["sent_from"] as? String ?? "" == myJid && self.bestAttemptContent?.userInfo["group_id"] != nil {
                    self.bestAttemptContent?.sound = nil
                    canVibrate = false
                } else if self.bestAttemptContent?.userInfo["sent_from"] as? String ?? "" != myJid && self.bestAttemptContent?.userInfo["group_id"] != nil {
                    if !(CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("Default") ?? false) && !(CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("None") ?? false) && CommonDefaults.notificationSoundEnable  {
                        self.bestAttemptContent?.sound = UNNotificationSound(named: UNNotificationSoundName((CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.file.rawValue] ?? "") + "." + (CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.extensions.rawValue] ?? "")))
                    } else if CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("Default") ?? false && CommonDefaults.notificationSoundEnable {
                        self.bestAttemptContent?.sound = .default
                    } else if CommonDefaults.notificationSoundEnable == false || CommonDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("None") ?? false {
                        self.bestAttemptContent?.sound = CommonDefaults.vibrationEnable ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "1-second-of-silence.mp3"))  : nil
                    }
                }
                if let message = ChatManager.getMessageOfId(messageId: messageId), !message.mentionedUsersIds.isEmpty {
                    self.bestAttemptContent?.body = convertMentionUser(message: message.messageTextContent, mentionedUsersIds: message.mentionedUsersIds)
                }

                let groupId = self.bestAttemptContent?.userInfo["group_id"] as? String ?? ""
                if let chat = ChatManager.getRechtChat(jid: groupId.isEmpty ? self.bestAttemptContent?.userInfo["from_user"] as? String ?? "" : groupId) {
                    if chat.isPrivateChat {
                        self.bestAttemptContent?.title = APP_NAME
                        let (messageCount, _) = ChatManager.getUnreadPrivateChatMessageAndChatCount()
                        self.bestAttemptContent?.body = "\(messageCount) new message"
                    }
                }

                contentHandler(self.bestAttemptContent!)

                //Commented for private flydefaults
                //FlyDefaults.lastNotificationId = request.identifier
            })
        }
    }


    func checkForDeliveredNotification(_ ID: String, isGroup: Bool, completionHandler: @escaping (UNNotification?) -> Void) {
        var foundNotification: UNNotification?
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            for notification in notifications {

                if isGroup {
                    if notification.request.content.userInfo["group_id"] as? String == ID && ChatManager.isPrivateChat(jid: ID) {
                        foundNotification = notification
                    }
                } else {
                    if notification.request.content.userInfo["from_user"] as? String == ID && ChatManager.isPrivateChat(jid: ID) {
                        foundNotification = notification
                    }
                }
            }
            completionHandler(foundNotification)
        }
    }


    func removeNotification(_ notification: UNNotification) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
    }

    func convertMentionUser(message: String, mentionedUsersIds: [String]) -> String {
        var replyMessage = message

        for user in mentionedUsersIds {
            let JID = user + "@" + ChatManager.getXMPPDetails().XMPPDomain
            let myJID = try? FlyUtils.getMyJid()
            if let profileDetail = ContactManager.shared.getUserProfileDetails(for: JID) {
                let userName = "@\(FlyUtils.getGroupUserName(profile: profileDetail))"
                let mentionRange = (replyMessage as NSString).range(of: "@[?]")
                replyMessage = replyMessage.replacing(userName, range: mentionRange)
            }
        }
        return replyMessage
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
extension String {
    func replacing(_ withString: String, range: NSRange) -> String {
        if let textRange = self.rangeFromNSRange(range) {
            return self.replacingCharacters(in: textRange, with: withString)
        }
        
        return self
    }
    func rangeFromNSRange(_ nsRange : NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }
    
    func substringFromNSRange(_ nsRange : NSRange) -> String {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return self }
        return String(self[from..<to])
    }
}
