//
//  ViewAllMediaModel.swift
//  MirrorflyUIkit
//
//  Created by John on 03/11/22.
//

import Foundation
import MirrorFlySDK
import SwiftLinkPreview

struct LinkModel {
    var title : String = ""
    var description : String = ""
    var image : String = ""
    var domain : String = ""
    var url : String = ""
    var linkMessage = LinkMessage()
    var section = 0
    var row = 0
}

class ViewAllMediaViewModel {
    func getTimeStampForHeader(chatMessage : ChatMessage) -> String {
        var timeStamp = 0.0
        if chatMessage.messageChatType == .singleChat {
            timeStamp =  chatMessage.messageSentTime
        } else {
            timeStamp = DateFormatterUtility.shared.getGroupMilliSeconds(milliSeconds: chatMessage.messageSentTime)
        }
        return String().fetchHeaderDateForViewAllMedia(for: timeStamp)
    }
    
    func checkToMessageDelete(messageIds: Array<String>, jid : String) -> Bool {
        if messageIds.count > 0 {
            if let chatMessage = ChatManager.getMessageOfId(messageId: messageIds[0]) {
                if chatMessage.chatUserJid == jid {
                    return true
                }
            }
        }
        return false
    }
    
    
    func removeDeletedOrCleardMessages(chatMessages : [[ChatMessage]], messaeIds: Array<String>) -> [[ChatMessage]] {
        var chatMessages = chatMessages
        var indexToRemove = [Int]()
        chatMessages.enumerated().forEach { (index, value) in
            messaeIds.forEach { messageId in
                chatMessages[index] =  chatMessages[index].filter({ $0.messageId != messageId})
            }
            if chatMessages[index].isEmpty {
                indexToRemove.append(index)
            }
        }
        
        indexToRemove.forEach { index in
            chatMessages.remove(at: index)
        }
        
        return chatMessages
    }
    
    func removeDeletedOrCleardLinkMessages(linkModels : [[LinkModel]], messaeIds: Array<String>) -> [[LinkModel]] {
        var linkModels = linkModels
        var indexToRemove = [Int]()
        linkModels.enumerated().forEach { (index, value) in
            messaeIds.forEach { messageId in
                linkModels[index] =  linkModels[index].filter({ $0.linkMessage.chatMessage.messageId != messageId})
            }
            if linkModels[index].isEmpty {
                indexToRemove.append(index)
            }
        }
        
        indexToRemove.forEach { index in
            linkModels.remove(at: index)
        }
        
        return linkModels
    }

    func whileReceivingNewMessage(chatMessage : ChatMessage, completionHandler : @escaping (_ linkModels : LinkModel) -> Void) {
        var links = [String]()
        if chatMessage.messageType == .text || chatMessage.messageType == .autoText {
            links = ChatUtils.getLinksFrom(text: chatMessage.messageTextContent)
        } else if  chatMessage.messageType == .video || chatMessage.messageType == .image {
            links = ChatUtils.getLinksFrom(text: chatMessage.mediaChatMessage?.mediaCaptionText ?? "")
        }
        if links.count > 0 {
            links.forEach { link in
                var linkMessage = LinkMessage()
                linkMessage.link = link
                linkMessage.chatMessage = chatMessage
                var linkModel = LinkModel()
                linkModel.linkMessage = linkMessage
                linkModel.row = 0
                linkModel.section = 0
                linkModel.title = link
                linkModel.description = link
                linkModel.domain = self.getDomain(urlString: link)
                completionHandler(linkModel)
            }
        }
    }
    
    
}


// media (video audio image) functions
extension ViewAllMediaViewModel {
    
    func getVideoAudioImageMessage(jid : String, completionHandler : @escaping FlyCompletionHandler){
        ChatManager.getVideoImageAudioMessageGroupByMonth(jid: jid) { isSuccess,error,data  in
           completionHandler(isSuccess,error,data)
        }
    }
    
    private func getThumbImage(chatMessage : ChatMessage) -> UIImage? {
        if let thumbImage = chatMessage.mediaChatMessage?.mediaThumbImage {
            let converter = ImageConverter()
            return  converter.base64ToImage(thumbImage)
        }
        return nil
    }
    
    func getImage(chatMessage : ChatMessage) -> UIImage {
        var uiImage = UIImage()
        var isThumbImage = false
        if let localPath = chatMessage.mediaChatMessage?.mediaFileName {
            if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                let fileURL: URL = folderPath.appendingPathComponent(localPath)
                if FileManager.default.fileExists(atPath:fileURL.relativePath) {
                    let data = NSData(contentsOf: fileURL)
                    uiImage = UIImage(data: data! as Data) ?? UIImage()
                }else {
                    isThumbImage = true
                }
            }
        } else {
           isThumbImage = true
        }
        
        if isThumbImage {
            if let thumImage = getThumbImage(chatMessage: chatMessage) {
                uiImage = thumImage
            }
        }
        
        return uiImage
    }
    
    func getMediaCount(chatMessages : [[ChatMessage]]) -> String {
        let mediaCount = getVideoImageAudioCount(chatMessages: chatMessages)
        let videoCount = mediaCount.videoCount
        let imageCount = mediaCount.imageCount
        let audioCount = mediaCount.audioCount
        return "\(imageCount) \(photos), \(videoCount) \(videos), \(audioCount) \(audios) "
    }
    
    private func getVideoImageAudioCount(chatMessages : [[ChatMessage]]) -> (videoCount : Int, imageCount : Int, audioCount : Int) {
        var videoCount = 0
        var imageCount = 0
        var audioCount = 0
        
        chatMessages.forEach { chatMessagesArray in
            let video = chatMessagesArray.filter{($0.messageType == .video)}.count
            let image = chatMessagesArray.filter{($0.messageType == .image)}.count
            let audio = chatMessagesArray.filter{($0.messageType == .audio)}.count
            
            videoCount = videoCount + video
            imageCount = imageCount + image
            audioCount = audioCount + audio
        }
        
        return (videoCount, imageCount, audioCount)
    }
    
    func getMediaDuration(duration : Int32) -> String {
        let duration = Int(duration)
        return "\(duration.msToSeconds.minuteSecondMS)"
    }
    
    func getVideoUrl(chatMessage : ChatMessage?) -> URL? {
      return  URL(fileURLWithPath: chatMessage?.mediaChatMessage?.mediaLocalStoragePath ?? "")
    }
    
    func getAudioUrl(chatMessage : ChatMessage?) -> URL? {
        return ChatUtils.getAudioURL(audioFileName: chatMessage?.mediaChatMessage?.mediaFileName ?? "")
    }
   
}

// Document functions
extension ViewAllMediaViewModel {
    func getDocumentMessage(jid : String, completioHandler : @escaping FlyCompletionHandler) {
        ChatManager.getDocumentMessageGroupByMonth(jid: jid) { isSuccess,error,data  in
            completioHandler(isSuccess,error,data)
        }
    }
    func getDocumentDate(chatMessage: ChatMessage?) -> String {
        guard let messageSentTime = chatMessage?.messageSentTime else {
            return ""
        }
        return DateFormatterUtility.shared.convertMilliSecondsToDocumentDate(milliSeconds: messageSentTime)
    }
    
    func getDocumentCount(chatMessage : [[ChatMessage]]) -> String{
        var count = 0
        chatMessage.forEach { chatMessages in
            count += chatMessages.count
        }
        return "\(count) \(count > 1 ? doucmentSMedia : document)"
    }
    
    func getDocumentFileSize(chatMessage: ChatMessage?) -> String {
        guard let fileSize = chatMessage?.mediaChatMessage?.mediaFileSize else {
           return ""
        }
        return "\(fileSize.byteSize)"
    }
}

// Link functions
extension ViewAllMediaViewModel {
    func getLinkMessage(jid : String, completionHandler : @escaping FlyCompletionHandler) {
        ChatManager.getLinkMessageGroupByMonth(jid: jid) { isSuccess,error,result  in
            
            var resultDict : [String: Any] = [:]
            
            if isSuccess {
                var data = result
                if let linkMessages = data.getData() as? [[LinkMessage]] {
                    
                    var linkModels = [[LinkModel]]()
                    var section = 0
                    linkMessages.forEach { linkMessageArray in
                        var linkModelArray = [LinkModel]()
                        var row = 0
                        linkMessageArray.forEach { linkMessage in
                            var linkModel = LinkModel()
                            let urlLink = linkMessage.link
                            linkModel.linkMessage = linkMessage
                            linkModel.row = row
                            linkModel.section = section
                            linkModel.title = urlLink
                            linkModel.description = urlLink
                            linkModel.domain = self.getDomain(urlString: urlLink)
                            linkModelArray.append(linkModel)
                            row += 1
                        }
                        linkModels.append(linkModelArray)
                        section += 1
                    }
                    resultDict.addData(data: linkModels)
                }
                
                completionHandler(isSuccess,error,resultDict)
            } else {
                completionHandler(isSuccess,error,resultDict)
            }
        }
    }

    func getLinkCount(linkModels : [[LinkModel]]) -> String{
        var count = 0
        linkModels.forEach { linkModelArray in
            count += linkModelArray.count
        }
        return "\(count) \(count > 1 ? links : link)"
    }
    
    func processLink(linkModelList : [[LinkModel]], completionHandler : @escaping (_ linkModel : LinkModel) -> Void) {
        let group = DispatchGroup()
        linkModelList.forEach { linkModelArray in
            linkModelArray.forEach { linkModel in
                group.enter()
                let slp = SwiftLinkPreview(cache: InMemoryCache())
                slp.preview(linkModel.linkMessage.link,
                onSuccess: { result in
                    print("Link Preview \(result)")
                    self.getLinkResult(linkModel: linkModel, response: result, completionHandler: completionHandler)
                    group.leave()
                },
                onError: { error in print("\(error)")
                    self.getLinkResult(linkModel: linkModel, response: nil, completionHandler: completionHandler)
                    group.leave()
                })
            }
        }
        
    }
    
    private func getLinkResult(linkModel : LinkModel, response : Response?, completionHandler : @escaping (_ linkModel : LinkModel) -> Void) {
        var tempLinkModel = LinkModel()
        let urlLink = linkModel.linkMessage.link
        tempLinkModel.title = response?.title ?? urlLink
        tempLinkModel.description = response?.description ?? urlLink
        tempLinkModel.image = (response?.image?.isURL ?? false) ? response?.image ?? "" : (response?.icon?.isURL ?? false) ? response?.icon ?? "" : ""
        tempLinkModel.domain = response?.canonicalUrl ?? getDomain(urlString: urlLink)
        tempLinkModel.section = linkModel.section
        tempLinkModel.row = linkModel.row
        tempLinkModel.linkMessage = linkModel.linkMessage
        completionHandler(tempLinkModel)
    }
    
    private func getDomain(urlString : String) -> String {
       return URL(string: urlString)?.host ?? ""
    }
}
