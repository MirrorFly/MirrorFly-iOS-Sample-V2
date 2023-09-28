//
//  Identifiers.swift
//  commonDemo
//
//  Created by User on 13/08/21.
//

import Foundation

//MARK: - Identifiers
enum Identifiers {
    
    //MARK: - Profile Identifiers
    static let profileImageFullView = "profileImageFullView"
    static let editStatusView = "editStatusView"
    static let statusCell = "statusCell"
    
    static let contactTableViewCell = "ContactTableViewCell"
    static let verifyOTPViewController = "VerifyOTPViewController"
    static let mainTabBarController = "MainTabBarController"
    static let backupViewController = "BackupViewController"
    static let restoreViewController = "RestoreViewController"
    static let backupPopupViewController = "BackupPopupViewController"
    static let autoBackupPopupViewController = "AutoBackupPopupViewController"
    static let backupProgressViewController = "BackupProgressViewController"
    static let restoreInstructionViewController = "RestoreInstructionViewController"
    static let profileViewController = "ProfileViewController"
    static let country = "CountryCell"
    static let countryPicker = "CountryPicker"
    static let noContacts = "NoContacts"
    static let contactCell = "ContactCell"
    static let contactViewController = "ContactViewController"
    static let dmaReasonVC = "DMAReasonVC"
    static let privateChatPopupViewController = "PrivateChatPopupViewController"
    
    //MARK: - Chat
    static let chatTextView =  "ChatTextView"
    static let chatViewTextIncomingCell = "ChatViewTextIncomingCell"
    static let chatViewTextOutgoingCell = "ChatViewTextOutgoingCell"
    static let otpNextToProfile = "otpNextToProfile"
    static let chatViewParentController = "ChatViewParentController"
    static let deleteChatAlert = "DeleteAlertViewController"
    
    //MARK: - Image
    static let imageEditController = "ImageEditController"
    static let editImageCell = "EditImageCell"
    static let listImageCell = "ListImageCell"
    static let imageCell = "ImageCell"
    static let imagePreview = "ImagePreview"
    static let imageSender = "SenderImageCell"
    static let imageReceiverCell = "ReceiverImageCell"
    
    //MARK: - APPLOCKPIN
    static let appLockTableViewCell = "AppLockTableViewCell"
    static let authenticationPINViewController = "AuthenticationPINViewController"
    static let appLockPasswordViewController = "AppLockPasswordViewController"
    static let changeAppLockViewController = "ChangeAppLockViewController"
    static let pinEnteredCollectionViewCell = "PINenteredCollectionViewCell"
    static let authenticationPINCollectionViewCell = "AuthenticationPINCollectionViewCell"
    static let AppLockDescriptionCell = "AppLockDescriptionCell"
    
    //MARK: - Audio
    static let audioSender = "AudioSender"
    static let audioReceiver = "AudioReceiver"
    static let audioView =  "AudioView"
    
    //MARK: - StarredMessages
    static let starredSenderView = "StarredSenderView"
    static let starredReceiverView =  "StarredReceiverView"
    
    static let chatViewLocationIncomingCell = "ChatViewLocationIncomingCell"
    static let chatViewLocationOutgoingCell = "ChatViewLocationOutgoingCell"
    static let chatScreenToLocation = "ChatScreenToLocation"
    static let locationViewController = "LocationViewController"
    static let chatViewContactIncomingCell = "ChatViewContactIncomingCell"
    static let chatViewContactOutgoingCell = "ChatViewContactOutgoingCell"
    static let chatScreenToContact = "ChatScreenToContact"
    static let chatContactCell = "ChatContactCell"
    
    //MARK: - Recent Chat
    static let recentChatCell =  "RecentChatCell"
    static let recentChatToChatScreen = "RecentChatToChatScreen"
    static let ArchiveChatTableViewCell = "ArchiveChatTableViewCell"
    static let ArchivedChatViewController = "ArchivedChatViewController"
    static let ArchivedListTableViewCell = "ArchivedListTableViewCell"
    
    //MARK: - Profile Update
    
    static let ncProfileUpdate =  "ncProfileUpdate"
    static let ncContactRefresh =  "ncContactRefresh"
    
    //MARK: Video
    static let videoIncomingCell = "ChatViewVideoIncomingCell"
    static let videoOutgoingCell = "ChatViewVideoOutgoingCell"
    

    //MARK: group
    static let createNewGroup = "NewGroupViewController"
    static let addParticipants = "AddParticipantsViewController"
    static let participantCell = "ParticipantCell"
    static let groupCreationPreview = "GroupCreationPreview"
    
    //MARK: notification
    static let notificationCell = "NotificationCell"
    static let noResultFound = "NoResultFoundCell"
    
    //MARK: Notification Tone
    static let notificationSoundTableViewCell = "NotificationSoundTableViewCell"
    static let notificationTableViewCell = "NotificationTableViewCell"
    static let notificationAlertViewController = "NotificationAlertViewController"
    static let notificationWebViewController = "NotificationWebViewController"
    static let notificationTonesListViewController = "NotificationTonesListViewController"
    static let notificationToneListCell = "NotificationToneListCell"
    
    //MARK: ForwardMessage
    static let forwardCell = "ForwardTableViewCell"
    static let forwardVC = "ForwardViewController"
    
    //MARK: QrCodeScanner
    static let qrCodeScaner = "QRCodeScanner"
    static let webSettingsCell = "WebSettingsCell"
    
    //ContactInfo
    static let contactInfoCell = "ContactInfoCell"
    static let viewAllMediaCell = "ViewAllMediaCell"
    static let muteNotificationCell = "MuteNotificationCell"
    static let contactImageCell = "ContactImageCell"
    static let contactInfoViewController = "ContactInfoViewController"
    static let viewUserImageController = "ViewUserImamgeController"
    static let contactSyncController = "ContactSyncController"
    static let groupInfoViewController = "GroupInfoViewController"
    static let groupMembersTableViewCell = "GroupMembersTableViewCell"
    static let groupOptionsTableViewCell = "GroupOptionsTableViewCell"
    static let updateGroupInfoViewController = "UpdateGroupInfoViewController"
    static let messageInfoViewController = "MessageInfoViewController"
    static let groupInfoOptionsViewController = "GroupInfoOptionsViewController"
    static let groupInfoOptionsTableViewCell = "GroupInfoOptionsTableViewCell"
    static let privateChatCell = "PrivateChatCell"
    static let shareCallLinkViewController = "ShareCallLinkViewController"
    
    //MARK: ChatSettings
    static let chatSettingsTableViewCell = "ChatSettingsTableViewCell"

    static let chatBackupTableViewCell = "ChatBackupTableViewCell"
    static let chatBackupPopupTableViewCell = "BackupPopupTableViewCell"
    static let restoreInstructionsTableViewCell = "RestoreInstructionsTableViewCell"
    static let clearAllChatTableViewCell = "ClearAllChatTableViewCell"

    static let LanguageSelectionTableViewCell = "LanguageSelectionTableViewCell"
    static let LanguageSelectionViewController = "LanguageSelectionViewController"

    static let BusyStatusHeaderCell = "BusyStatusHeaderCell"
    
    /// MARK: Documents Cells
    static let senderDocumenCell = "SenderDocumentsTableViewCell"
    static let receiverDocumentCell = "ReceiverDocumentsTableViewCell"
    
    /// MARK: DeleteMessage Cells
    static let deleteEveryOneCell = "DeleteForEveryOneViewCell"
    static let deleteEveryOneReceiverCell = "DeleteForEveryOneReceiverCell"
    
    // MARK: Message Info
    static let messageInfoDivider = "MessageInfoDivider"
    static let singleMessageInfoCell = "SingleMessageInfoCell"
    static let groupDividerCell = "GroupDividerCell"
    static let groupHeaderCell = "GroupHeaderCell"
    static let inforDeliveredCell = "DeliveredCell"
    static let notDelivered = "NotDeliveredCell"
    
    // view All Media
    static let viewAllMediaVC = "ViewAllMediaController"
    static let mediaCell = "MediaCell"
    static let mediaSectionHeader = "SectionHeaderView"
    static let mediaSectionFooter = "SectionFooterView"
    static let documentCell = "DocumentTableViewCell"
    static let headerSectionCell = "HeaderSectionCell"
    static let footerSectionCell = "FooterSectionCell"
    static let linkCell = "LinkCell"
}

//MARK: - Storyboards
enum Storyboards {
    static let main = "Main"
    static let chat = "Chat"
    static let profile = "Profile"
    static let backupRestore = "BackupRestore"
    static let call = "Call"
}
