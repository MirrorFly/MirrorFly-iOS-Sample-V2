//
//  ShareKitProfile.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 28/02/23.
//

import Foundation
import MirrorFlySDK

struct Profile {
    var profileName: String?
    var jid: String = ""
    var isSelected: Bool?
}

protocol RefreshProfileInfo {
    func refreshProfileDetails(profileDetails:ProfileDetails?)
}

enum ChatActions : String, CaseIterable {
    case clearAllConversation = "Clear All Conversation"
    case emailChat = "Email Chat"
    case report = "Report"
    case search = "Search"
    case block = "Block"
    case unblock = "Unblock"
}

enum InvalidType: String {
    case size = "size"
    case format = "format"
}

struct ShareMedia {
    var toJid: String
    var media: [MediaData]
}

struct ShareData {
    var contentType: MessageType?
    var url: URL?
    var data: Data?
    var thumbImage: UIImage?
    var isFromFile: Bool?
    var invalidType: InvalidType?
    var image: UIImage?
}

struct ContactDetails {
    var contactName: String
    var contactNumber: [String]
    var contactLabel: [String]
    var status: [String]
    var imageData : Data?
}
