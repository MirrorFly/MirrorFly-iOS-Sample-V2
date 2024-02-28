
//  ChatViewParentController.swift
//  MirrorflyUIkit
//  Created by User on 19/08/21.

import Foundation
import UIKit
import GrowingTextViewHandler_Swift
import IQKeyboardManagerSwift
import MirrorFlySDK
import BSImagePicker
import Photos
import AVFoundation
import Contacts
import ContactsUI
import SDWebImage
import MapKit
import MobileCoreServices
import AVKit
import PhotosUI
import MirrorFlySDK
import XMPPFramework
import MarqueeLabel
import MenuItemKit
import Floaty
import Tatsi
import QCropper
import NicoProgress
import SwiftUI
import PDFKit
import QuickLook
import RxSwift
import UniformTypeIdentifiers
import KMPlaceholderTextView
import BottomSheet


public protocol ShareReloadDelegate {
    func reloadTable()
}

protocol TableViewCellDelegate {
    func openBottomView(indexPath: IndexPath)
}

protocol RefreshMessagesDelegate {
    func refreshMessages(messageIds: Array<String>)
}

protocol ReplyMessagesDelegate {
    func replyMessageObj(message: ChatMessage?,jid: String,messageText: String)
}

class ChatViewParentController: BaseViewController, UITextViewDelegate,
                                UIGestureRecognizerDelegate, UINavigationControllerDelegate,CNContactViewControllerDelegate {
    
    //MARK : Header Design
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var multiSelectionView: UIView!
    @IBOutlet weak var longPressCountLabel: UILabel!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var lastSeenLabel: UILabel!
    @IBOutlet weak var userInfoStack: UIStackView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var searchView: UIView?
    @IBOutlet weak var navigationView: UIView?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var unreadMessageLabel: UILabel!
    @IBOutlet weak var unreadMessageView: UIView!
    @IBOutlet weak var groupMemberLable: MarqueeLabel!
    @IBOutlet weak var starredSearchBarHeightCons: NSLayoutConstraint?
    
    //MARK : Bottom Text Design
    @IBOutlet weak var textToolBarView: UIView?
    @IBOutlet weak var textToolBarViewHeight: NSLayoutConstraint?
    @IBOutlet weak var chatTextView: UIView?
    @IBOutlet weak var messageTextView: MentionTextView!
    @IBOutlet weak var messageTextViewHeight: NSLayoutConstraint?
    @IBOutlet weak var sendButton: UIButton?
    
    @IBOutlet weak var attachmentButton: UIButton!
    //MARK : ReplyView Bottom Text Design
    @IBOutlet weak var replyView: UIView!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint?
    @IBOutlet weak var starredBackButton: UIButton?
    //audio outlets
    @IBOutlet weak var audioImage: UIImageView!
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var audioTimerLabel: UILabel!
    @IBOutlet weak var emptyMessageView: UIView?
    @IBOutlet weak var forwardBottomView: UIView?
    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var forwardButton: UIButton?

    @IBOutlet weak var emptyMessageLabel: UILabel!

    @IBOutlet weak var messageSearchBar: UISearchBar? {
        didSet {
            messageSearchBar?.delegate = self
            messageSearchBar?.setImage(UIImage(), for: .search, state: .normal)
            //messageSearchBar.searchTextField.clearButtonMode = .always
        }
    }

    @IBOutlet weak var messageSearchView: UIView!
    @IBOutlet weak var messageSearchDown: UIButton! {
        didSet {
            let image = UIImage(named: "down_arrow")?.withRenderingMode(.alwaysTemplate)
            messageSearchDown.tintColor = Color.color_3276E2 ?? .blue
            messageSearchDown.setImage(image, for: .normal)
            messageSearchDown.makeCircleView(borderColor: UIColor.clear.cgColor, borderWidth: 0.0)
            isSearchDidChange = false
            messageSearchDown.addTarget(self, action: #selector(tapSearchDown), for: .touchUpInside)
        }
    }
    @IBOutlet weak var messageSearchUp: UIButton! {
        didSet {
            let image = UIImage(named: "up_arrow")?.withRenderingMode(.alwaysTemplate)
            messageSearchUp.tintColor = Color.color_3276E2 ?? .blue
            messageSearchUp.setImage(image, for: .normal)
            messageSearchUp.makeCircleView(borderColor: UIColor.clear.cgColor, borderWidth: 0.0)
            isSearchDidChange = false
            messageSearchUp.addTarget(self, action: #selector(tapSearchUp), for: .touchUpInside)
        }
    }
    @IBOutlet weak var messageSearchViewBottomConstraint: NSLayoutConstraint!

    var scheduleMeetBtn : UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.backgroundColor = Color.color_3276E2 ?? .blue
        return view
    }()
    let scheduleMeetButtonCons = 56
    var scheduleMeetBtnYPosition = CGFloat()
    var keyboardShown = false

    // Forward Local Variable
    var isShowForwardView: Bool = false
    //
    var isShareMediaSelected:Bool = false
    // Delete Local Variable
    private var isDeleteSelected: Bool = false
    private var deleteViewModel: DeleteViewModel?
    private var recentChatViewModel = RecentChatViewModel()
    private var refreshData: RefreshMessagesDelegate? = nil
    
    // Starred Message Local variable
    private var chatViewModel: ChatViewModel?
    private var isStarredMessageSelected: Bool = false
    var isStarredMessagePage:Bool = false
    var selectedMessageId: String? = ""
    var isStarredSearchEnabled: Bool? = false
    var searchMessageId: String = ""
    
    var chatTextViewXib:ChatTextView?
    var growingTextViewHandler:GrowingTextViewHandler?
    var contactNumber: [String] = []
    var contactStatus: [String] = []
    var contactLabel: [String] = []
    let chatManager = ChatManager.shared
    var imagePicker: UIImagePickerController!
    var isSelectOn = false
    var selectedIndexs = [IndexPath]()
    var selectedMessages: [SelectedMessages]? = []
    var alertController : UIAlertController?
    var isPopToRootVC: Bool? = false
    var receivedMediaMessages: [ChatMessage]? = []
    var isShowAudioLoadingIcon: Bool? = false
    var callDurationTimer : Timer?
    var lastSelectedCollection: PHAssetCollection?
    var replyMessagesDelegate: ReplyMessagesDelegate?
    var isImagePicked: Bool = false
    var replyMessageObj: ChatMessage?
    var replyJid: String?
    var messageText: String? {
        didSet {
            executeOnMainThread { [self] in
                messageTextView?.text = messageText
                handleSendButton()
            }
        }
    }
    var replyCloseButtonTapped: Bool? = false
    var ismarkMessagesAsRead: Bool? = false
    var mediaMessagesToSend : [ImageData]?
    var docCurrentIndexPath: IndexPath? = IndexPath()
    var isDocumentOptionSelected: Bool? = false
    let backgroundQueue = DispatchQueue(label: "audioQueue", qos: .userInteractive)
    var longPressActions: [NSObject] = []
    var editMenuInteraction: UIInteraction?
    var starredSearchMessages: [ChatMessage]? = [ChatMessage]()

    var contextMenuIndexPath = IndexPath()
    // If the rememberCollectioSwitch is turned on we return the last known collection, if available.
    var firstView: TatsiConfig.StartView {
        if let lastCollection = self.lastSelectedCollection {
            return .album(lastCollection)
        } else {
            return .userLibrary
        }
    }
    
    //audio
    var audioViewXib: AudioView?
    var audioPlayer:AVAudioPlayer?
    var updater : CADisplayLink! = nil
    var isAudioRecordingGranted = false
    let contactManager = ContactManager.shared
    let toolTipController = UIMenuController.shared
    var contactDetails: [ContactDetails] = []
    var isReplyViewOpen: Bool = false
    var isReplyViewClosed: Bool = false
    var replyMessageId = ""
    var longPressCount: Int = 0
    var isCellLongPressed: Bool = false
    var previousIndexPath : IndexPath = IndexPath()
    var currenAudioIndexPath : IndexPath? = IndexPath(row: -1, section: -1)
    var previousAudioIndexPath : IndexPath? = IndexPath(row: -1, section: -1)
    var currentPreviewIndexPath : IndexPath? = IndexPath(row: 0, section: 0)
    var currentIndexPath: IndexPath = IndexPath()
    private var selectedAssets = [PHAsset]()
    var isNetworkConnected: Bool = true
    var mLatitude : Double = 0.0
    var mLongitude : Double = 0.0
    var toViewLocation = false
    var groupMembers = [GroupParticipantDetail]()
    var multipleSelectionTitle: String? = ""
    
    let documentsSupportedTypes: [String] = [kUTTypeJPEG as String, kUTTypePNG as String,
                                             kUTTypeRTF as String, kUTTypePlainText as String,
                                             kUTTypePDF as String, kUTTypeMP3 as String,
                                             kUTTypePDF as String, kUTTypeText as String,
                                             "com.microsoft.word.doc",
                                             "org.openxmlformats.wordprocessingml.document",
                                             "com.microsoft.powerpoint.​ppt",
                                             "com.microsoft.powerpoint.​ppt","public.data",
                                             "org.openxmlformats.presentationml.presentation",
                                             "com.microsoft.excel.xls","com.apple.application",
                                             "org.openxmlformats.spreadsheetml.sheet",
                                             "com.pkware.zip-archive","public.zip-archive"]
    
    
    //contact
    var contactColor = UIColor()
    
    var isFromGroupInfo: Bool = false
    var isFromBackground: Bool = false
    
    //Mark: Translate Message
    var targetLanguageCode: String?
    
    var selectedChatMessage : ChatMessage? = nil
    
    //Mark : voice recording
    var leftMaximumPosition : CGFloat = 60
    var rightMaximumPosition : CGFloat = 200
    var audioButtonTimer = Timer()
    var recorder = AppAudioRecorder.shared
    var recordedAudioFileName : String = ""
    var recordedAuidoUrl : URL? = nil
    var didTapSendAudioButton : Bool = false
    var isAudioMaximumTimeReached : Bool = false
    var audioRecordingDuration : CGFloat = 0.0
    var currentMessageTextViewHeight : CGFloat = 40
    var currentToolBarViewHeight : CGFloat = 50
    var currentAudioUrl : String? = nil
    var didCallCome : Bool = false
    
    var fetchMessageListParams = FetchMessageListParams()
    var isPreviousMessagesLoadingInProgress = false
    var isNextMessagesLoadingInProgress = false
    var previousMessagesLoadingDone = false
    var nextMessagesLoadingDone = false
    var scrollToTappedMessage = false
    
    var messageDelegate : MessageDelegate? = nil
    
    var availableFeatures = ChatManager.getAvailableFeatures()
    
    var unreadMessagesIdOnMessageReceived = [String]()
    var unreadMessageIdFromDB = [String]()
    @IBOutlet weak var unreadMessageViewBottomConstraint: NSLayoutConstraint!

    //Message search variables
    var foundedIndex = [IndexPath]()
    var currentHighlightedIndexPath: IndexPath?
    var currentHighlightedIndex: Int?
    var messageSearchEnabled = false
    var foundedSearchResult = false
    var isSearchButtonTapped: Bool = false
    var currentSelectedIndexPath: IndexPath?
    var isSearchDidChange: Bool = false
    
    var isMention = false
    var mentionSearch = ""
    var mentionRange: NSRange!
    var mentionUsersList: [String] = []
    var mentionRanges: [(String, NSRange)] = []
    var searchGroupMembers = [GroupParticipantDetail]()

    var groupIdForPrivateChat: String?
    var isFromSearchSelect: Bool = false
    var isFromNotificationSelect: Bool = false
    var lockScreenShown = false
    var isFromContactScreen = false
    var isFromForward = false
    var isFromPrivateChat = false

    var isFromLocalPush = false

    var bottomSheet: InstantScheduledMeetingViewController? = InstantScheduledMeetingViewController()
    var bottomSheetOpened = false
    var isMessageEditing = false
    var editMessageId:String = emptyString()
    var editMessageType: MessageType = .text

    @IBOutlet weak var mentionBaseView: UIView!
    @IBOutlet weak var mentionBottom: NSLayoutConstraint!
    @IBOutlet weak var mentionTableView: UITableView!
    @IBOutlet weak var mentionHeight: NSLayoutConstraint!
    
    var starredMessages = [ChatMessage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkifStarredMessages()
        if isFromContactScreen || isFromForward || isFromGroupInfo || pushNotificationSelected {
            if ChatManager.isPrivateChat(jid: getProfileDetails.jid) {
                //if recent.isPrivateChat {
                    if let group = groupIdForPrivateChat {
                        if ChatManager.isPrivateChat(jid: group) {

                        } else {
                            showLockScreen()
                        }
                    } else if isFromForward && isFromPrivateChat {
                        
                    } else {
                        if lockScreenShown == false {
                            showLockScreen()
                            lockScreenShown = true
                        }
                    }
                //}
            }
        }
    }
    
    @objc internal override func keyboardWillShow(notification: NSNotification) {
        if let value = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let newHeight: CGFloat
            if #available(iOS 11.0, *) {
                newHeight = value.height - view.safeAreaInsets.bottom
            } else {
                newHeight = value.height
            }
            self.containerBottomConstraint.constant = newHeight//
            self.messageSearchViewBottomConstraint.constant = newHeight
            let bottomPadding = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) + 40
            if self.scheduleMeetBtn.center.y > self.view.frame.height - newHeight - (chatTextView?.frame.height ?? 0) - bottomPadding {
                self.scheduleMeetBtn.center.y = self.view.frame.height - newHeight - (chatTextView?.frame.height ?? 0) - bottomPadding
            }
        }
        keyboardShown = true
        unreadMessageViewBottomConstraint.constant = 400
    }
    
    @objc internal override func keyboardWillHide(notification: NSNotification) {
        //chatTableView.contentInset = .zero
        //self.tableViewBottomConstraint.constant = CGFloat(chatBottomConstant)
        keyboardShown = false
        self.containerBottomConstraint.constant = 0.0
        self.unreadMessageViewBottomConstraint.constant = 100
        self.messageSearchViewBottomConstraint.constant = 0
        if self.scheduleMeetBtn.center.y < self.view.frame.height - self.containerBottomConstraint.constant - 30 {
            self.scheduleMeetBtn.center.y = scheduleMeetBtnYPosition
        }
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        if isMessageEditing {
            if let userInfo = notification.userInfo,
               let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                
                // Calculate the new keyboard height
                let newKeyboardHeight = UIScreen.main.bounds.height - endFrame.origin.y - view.safeAreaInsets.bottom
                
                // Update the stored keyboard height
                CM.updateBaseviewPosition(height: (newKeyboardHeight + (self.chatTextView?.bounds.height ?? 0) + 10))
                
                // Handle the keyboard height change, e.g., update your UI layout
                print("Keyboard height: \(newKeyboardHeight)")
            }
           
        }
    }
    
    func checkGalleryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status != .authorized {
            AppPermissions.shared.checkGalleryPermission { phAuthorizationStatus in
                
            }
        }
    }
    
    
    @IBAction func starredBackButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func checkifStarredMessages() {
        chatViewModel = ChatViewModel()
        if !isStarredMessagePage {
            searchGroupMembers = groupMembers.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }).filter({$0.memberJid != AppUtils.getMyJid()})
            mentionBaseView.isHidden = true
            mentionBaseView.addBorder(toSide: .Top, withColor: .lightGray.withAlphaComponent(0.8), andThickness: 0.5)
            mentionTableView.register(UINib(nibName: "MentionTableViewCell",
                                            bundle: nil), forCellReuseIdentifier: "MentionTableViewCell")
            mentionTableView.delegate = self
            mentionTableView.dataSource = self
            setUpUI()
            callDurationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCallDuration), userInfo: nil, repeats: true)
            getInitialMessages()
            loadAudioView()
            handleSendButton()
            audioButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
            videoButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            print("MYJId \(AppUtils.getMyJid())")
            print("username : \(ChatManager.getXMPPDetails().XMPPUsername)")
            checkGalleryPermission()
            chatTextViewXib?.cannotSendMessageView?.isHidden = true
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                let matchingNotifications = notifications.filter({ $0.request.content.threadIdentifier == self.getProfileDetails.jid })
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: matchingNotifications.map({ $0.request.identifier }))
            }
            NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
            
            //MARK: Function call for the Message Translation

           // translateIncomingMessage()
            
            // translateIncomingMessage()
            checkUserBlocked()
            checkUserBlockedByAdmin()
            checkUserBlocked()
            self.navigationController?.removeViewController(MessageInfoViewController.self)
            initializeUnreadMessage()
            checkUnreadMessage()
            self.navigationController?.removeViewController(ProfileViewController.self)
            self.navigationController?.removeViewController(ViewAllMediaController.self)
            self.navigationController?.removeViewController(GroupInfoViewController.self)
            if !isStarredMessagePage {
                let unsentMessage = FlyMessenger.getUnsentMessageOf(id: getProfileDetails.jid)
                if unsentMessage.mentionedUsers.isEmpty && unsentMessage.mentionSearch.isEmpty {
                    messageText = unsentMessage.textContent
                } else {
                    if !unsentMessage.mentionedUsers.isEmpty {
                        var dataArray = [String]()
                        let message = ChatUtils.convertMentionUser(message: unsentMessage.textContent, mentionedUsersIds: unsentMessage.mentionedUsers).replacingOccurrences(of: "\\", with: "", options: .literal, range: nil)
                        dataArray.append(message)
                        dataArray.append(unsentMessage.mentionedUsers.joined(separator: ","))
                        messageTextView?.convertAndInsert(to: dataArray, with: NSRange(location: 0, length: 0))
                        messageTextView?.textViewEnd()
                    } else {
                        messageText = unsentMessage.textContent
                        mentionSearch = unsentMessage.mentionSearch.joined(separator: "")
                        searchGroupMembers = groupMembers.filter{ $0.displayName.lowercased().contains(mentionSearch.lowercased())}.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                        mentionTableView.reloadData()
                        isMention = true
                        mentionRange = NSRange(location: 0, length: 0)
                        self.view.bringSubviewToFront(mentionBaseView)
                        self.viewDidLayoutSubviews()
                        mentionBaseView.isHidden = false
                    }
                }
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            chatTableView.addGestureRecognizer(tap)
        } else {
            registerNibs()
            loadBottomView()
            searchBar?.delegate = self
        }
        chatTableView.dataSource = self
        chatTableView.delegate = self
        if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
            chatTableView.transform = CGAffineTransform(rotationAngle: -.pi)
            chatTableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right:  UIScreen.main.bounds.size.width - CGFloat(constraintsConstant))
        }
        chatTableView.rowHeight = UITableView.automaticDimension
        chatTableView.estimatedRowHeight = UITableView.automaticDimension
        tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
        containerView.bringSubviewToFront(chatTableView)
        configureDefaults()
        deleteViewModel = DeleteViewModel()
    }

    @IBAction func didTapUnreadMessage(_ sender: Any) {
        resetUnreadMessages()
    }

    @objc func updateCallDuration() {
        if !NetworkReachability.shared.isConnected {
            if isNetworkConnected == true {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                isNetworkConnected = false
            }
        } else {
            isNetworkConnected = true
        }
    }
    
    @objc override func didMoveToBackground() {
        print("ChatViewParentController moved to background")
        if !isMessageEditing {
            view.endEditing(true)
        }
        stopPlayer(isBecomeBackGround: true)
        isFromBackground = false
        
        if UIApplication.shared.isKeyboardPresented {
            print("Keyboard presented")
            self.messageTextView?.becomeFirstResponder()
        } else {
            print("Keyboard is not presented")
        }
        if ChatManager.isPrivateChat(jid: getProfileDetails.jid ?? "") {
           // if recent.isPrivateChat {
                CommonDefaults.appLockOnPrivateChat = false
                CommonDefaults.privateChatOnChatScreen = true

            if !CommonDefaults.permissionAlertShown {
                self.view.addLaunchSubview()
            }
            //}
        }
        removeUnreadMessageLabelFromChat()
        if CommonDefaults.privateChatOnChatScreen && !CommonDefaults.showAppLock && (isMessageEditing || editMessageId.isNotEmpty) {
            CM.closeMenu()
        }
    }

    @objc func enteredBackGround() {
        if ChatManager.isPrivateChat(jid: getProfileDetails.jid ?? "") {
            self.view.addLaunchSubview()
        }
    }

    @objc func permissionAlertNotification(notification: Notification) {
        if let status = notification.object as? Bool {
            CommonDefaults.permissionAlertShown = status
        }
    }
    
    @objc override func willCometoForeground() {
        print("ChatViewParentController ABC appComestoForeground")
        self.view.removeLaunchSubview()
        self.viewDidLayoutSubviews()
        self.mentionBaseView.isHidden = !isMention
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if self?.isReplyViewOpen == true {
                self?.view.endEditing(true)
            }
            
            if (chatMessages.count ?? 0) > 0 {
                self?.handleSendButton()
            }
            
            if self?.replyMessageObj != nil && self?.replyJid == self?.getProfileDetails.jid {
                chatMessages.enumerated().forEach { (section,chatMessage) in
                    chatMessage.enumerated().forEach { (row,message) in
                        if message.messageId == self?.replyMessageObj?.messageId {
                            self?.replyMessage(indexPath: IndexPath(row: row, section: section), isMessageDeleted: false, isKeyBoardEnabled: (self?.messageTextView?.becomeFirstResponder() ?? false) ? true : false, isSwipe: false)
                        }
                    }
                }
            }
            
            FlyMessenger.resetFailedMediaMessages(chatUserJid: self?.getProfileDetails.jid ?? "")
            self?.configureDefaults()
            self?.ismarkMessagesAsRead = false
            self?.isFromBackground = true
            self?.getInitialMessages()
            self?.checkUserBlocked()
        }
        if CommonDefaults.privateChatOnChatScreen && !CommonDefaults.showAppLock {
            if lockScreenShown == false {
                showLockScreen()
                lockScreenShown = true
            }
        }
        if !isStarredMessagePage && isMessageEditing {
            messageTextView.becomeFirstResponder()
        }
    }
    
    private func groupPreviousMessages(messages: [ChatMessage]){
        let groupedMessages = Dictionary(grouping: messages) { (element) -> Date in
            var date : Date
            if element.messageChatType == .singleChat {
                date =  DateFormatterUtility.shared.convertMillisecondsToLocalDate(milliSeconds: element.messageSentTime)
            } else {
                date = DateFormatterUtility.shared.convertGroupMillisecondsToLocalDate(milliSeconds: element.messageSentTime)
            }
            return date.reduceToMonthDayYear()
        }
        let sortedKeys = groupedMessages.keys.sorted()
        sortedKeys.forEach { (key) in
            var values = groupedMessages[key]
            values = values?.reversed()
            chatMessages.insert(values ?? [], at: 0)
            DispatchQueue.main.async { [weak self] in
                UIView.performWithoutAnimation {
                    self?.chatTableView?.reloadData()
                }
            }
        }
    }
    
    func groupMessage(messages: [ChatMessage]) -> [[ChatMessage]]  {
        let groupedMessages = Dictionary(grouping: messages) { (element) -> Date in
            let date = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: element.messageSentTime)
            return date.reduceToMonthDayYear()
        }
        print(groupedMessages);
        var sortedMessages: [[ChatMessage]] = [[ChatMessage]]()
        
        let sortedKeys = groupedMessages.keys.sorted().reversed()
        sortedKeys.forEach { (key) in
            let values = groupedMessages[key]
            sortedMessages.append(values ?? [])
        }
        return sortedMessages;
    }
    
    func getInitialMessages()  {
        
        //        getMessages()
        //        return
        
        if !getAllMessages.isEmpty {
            getAllMessages.removeAll()
        }
        if chatMessages.count > 0 {
            chatMessages.removeAll()
        }
        fetchMessageListParams.chatId = getProfileDetails.jid

        fetchMessageListParams.limit = 100
        //        fetchMessageListParams.messageId = "f60e765c4742444e8038067b75f6193c"

        queryInitialMessage()
    }
    
    func queryInitialMessage(shouldScrollToMessage : Bool = false, messageId : String = emptyString()){
        if !shouldScrollToMessage {
            executeOnMainThread {
                self.startLoading(withText: "")
            }
        }
        fetchMessageListQuery = FetchMessageListQuery(fetchMessageListParams: fetchMessageListParams)
        fetchMessageListQuery?.loadMessages { [self] isSuccess, error, data in
            executeOnMainThread {
                self.stopLoading()
            }
            var result = data
            if isSuccess {
                if let chatmessages = result.getData() as? [ChatMessage] {
                    chatMessages.removeAll()
                    getAllMessages.removeAll()
                    setLastMessage(messageId: chatmessages.last?.messageId ?? emptyString())
                    self.groupInitialMessages(messages: chatmessages) {
                        if chatmessages.count <  self.fetchMessageListParams.limit{
                            self.nextMessagesLoadingDone = true
                        }
                        if shouldScrollToMessage{
                            if let indexPath = self.checkReplyMessageAvailability(replyMessageId:messageId).0{
                                self.scrollLogic(indexPath: indexPath)
                            }
                        }
                        if self.messageSearchEnabled {
                            self.processSearch(searchText: self.messageSearchBar?.text ?? "", searchUp: true)
                        }
                    }
                }
            }
        }
    }
    
    /**
     * to configure delegates
     * to initialize
     */
    func configureDefaults() {
        audioPlayer?.delegate = self
        networkMonitor()
    }

    override func viewDidLayoutSubviews() {

//        if let pushId = pushChatId {
//            if let recent = ChatManager.getRechtChat(jid: pushId) {
//                if recent.isPrivateChat {
//                    showLockScreen()
//                }
//            }
//        }

        pushChatId = nil
        if !isStarredMessagePage {
            self.chatTableView.backgroundView = UIImageView(image: UIImage(named: "chat_background"))
        }
        self.mentionBottom.constant = -((self.chatTextView?.bounds.height ?? 0) + 10)
        if getProfileDetails.profileChatType == .groupChat {
            if searchGroupMembers.isEmpty {
                mentionHeight.constant = 0
            } else {
                let groupHeight = CGFloat(searchGroupMembers.count * 50) + (chatTextView?.frame.height ?? 0)
                let groupCustomHeight = CGFloat(containerView.bounds.height/2) + (chatTextView?.frame.height ?? 0)
                print("groupHeight \(groupHeight) groupCustomHeight \(groupCustomHeight)")
                mentionHeight.constant = groupHeight > groupCustomHeight ? groupCustomHeight : groupHeight
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bottomSheet = InstantScheduledMeetingViewController()
        if ChatManager.isPrivateChat(jid: getProfileDetails.jid ?? "") && (isFromContactScreen || pushNotificationSelected || isFromGroupInfo || isFromForward) {
            self.view.addLaunchSubview()
        }
        if isStarredMessagePage == true {
            starredMessages = chatViewModel?.getAllFavouriteList().filter { !(ChatManager.getRechtChat(jid: $0.chatUserJid)?.isPrivateChat ?? false) }.reversed() ?? []
            scheduleMeetBtn.isHidden = true
            showOrHideUnreadMessageView(hide: true)
            headerView.isHidden = true
            chatTextViewXib?.cannotSendMessageView?.isHidden =  true
            forwardBottomView?.isHidden = true
            textToolBarView?.isHidden = true
            chatTextViewXib?.audioRecordView?.isHidden = true
            starredSearchBarHeightCons?.constant = 60
            tableViewBottomConstraint?.constant = isStarredMessagePage ? 10.0 : CGFloat(chatBottomConstant)
            searchView?.isHidden = false
            navigationView?.isHidden = false
            chatTableView?.separatorStyle = .singleLine
            if #available(iOS 13.0, *) {
                chatTableView?.separatorColor = .systemGray5
                chatTableView?.separatorInset = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: -15)
            } else {
                // Fallback on earlier versions
                chatTableView?.separatorColor = .lightGray
                chatTableView?.separatorInset = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: -15)
            }
            navigationController?.navigationBar.isHidden = true
            emptyMessageView?.isHidden = starredMessages.count == 0 ? false : true
            UIView.performWithoutAnimation {
                chatTableView.reloadData()
            }
        } else {
            setupMeetLinkView()
            emptyMessageView?.isHidden = true
            chatTableView?.separatorStyle = .none
            chatTableView?.separatorColor = .none
            replyView.isHidden = true
            navigationView?.isHidden = true
            starredSearchBarHeightCons?.constant = 0
            searchView?.isHidden = true
            ChatManager.setOnGoingChatUser(jid: getProfileDetails.jid)
            print("ChatViewParentController ABC viewWillAppear")
            handleBackgroundAndForground()
            getLastSeen()
            executeInBackground {
                self.markMessagessAsRead()
            }
            headerView.isHidden = false
            navigationController?.setNavigationBarHidden(false, animated: animated)
            setUpHeaderView()
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            navigationController?.navigationBar.isHidden = false
            navigationController?.navigationBar.barTintColor = .white
            NotificationCenter.default.addObserver(self, selector: #selector(self.profileNotification(notification:)), name: Notification.Name(Identifiers.ncProfileUpdate), object: nil)
            audioButton.tag = 101
            videoButton.tag = 102
            audioButton.addTarget(self, action: #selector(makeCall(_:)), for: .touchUpInside)
            videoButton.addTarget(self, action: #selector(makeCall(_:)), for: .touchUpInside)
            menuButton.addTarget(self, action: #selector(didTapMenu(_:)), for: .touchUpInside)
            
            if getProfileDetails.profileChatType == .groupChat {
                getParticipants()
                getGroupMember()
                checkMemberOfGroup()
            }
            forwardBottomView?.isHidden = isShowForwardView == true ? false : true
            lastSeenLabel.isHidden = (getProfileDetails.profileChatType == .groupChat)
            groupMemberLable.isHidden = (getProfileDetails.profileChatType == .singleChat)
            if replyMessageObj != nil && replyJid == getProfileDetails.jid {
                chatMessages.enumerated().forEach { (section,chatMessage) in
                    chatMessage.enumerated().forEach { (row,message) in
                        if message.messageId == replyMessageObj?.messageId {
                            replyView.isHidden = false
                            replyMessage(indexPath: IndexPath(row: row, section: section), isMessageDeleted: false, isKeyBoardEnabled: UIApplication.shared.isKeyboardPresented ? true : false, isSwipe: false)
                        }
                    }
                }
            }
        chatManager.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
        ChatManager.setOnGoingChatUser(jid: getProfileDetails.jid)
        handleBackgroundAndForground()
        getLastSeen()
        
            getUserForAdminBlock()
            availableFeatures = ChatManager.getAvailableFeatures()
            updateSubViews()
        }
        showHideEmptyView()
        checkUserBlockedByAdmin()
        if selectedMessageId?.isNotEmpty == true {
            scrollToSelectedMessage()
        }
        IQKeyboardManager.shared.enableAutoToolbar = false
        chatManager.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
        stopPlayer(isBecomeBackGround: true)
        view.backgroundColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                                       name: NSNotification.Name(didBecomeActive), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enteredBackGround), name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(permissionAlertNotification), name: Notification.Name(FlyConstants.callPermissionAlertShown), object: nil)
        if !isStarredMessagePage {
            let unsentMessage = FlyMessenger.getUnsentMessageOf(id: getProfileDetails.jid)
            if !unsentMessage.mentionSearch.isEmpty {
                for i in 0..<unsentMessage.mentionLocation.count {
                    mentionRanges.append((unsentMessage.mentionSearch[i], NSRange(location: unsentMessage.mentionLocation[i], length: unsentMessage.mentionLength[i])))
                }
                mentionSearch = unsentMessage.mentionSearch.joined(separator: "")
                searchGroupMembers = groupMembers.filter{ $0.displayName.lowercased().contains(mentionSearch.lowercased())}.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                mentionTableView.reloadData()
                isMention = true
                mentionRange = NSRange(location: 0, length: 0)
                self.view.bringSubviewToFront(mentionBaseView)
                self.viewDidLayoutSubviews()
                mentionBaseView.isHidden = false
            }
        }
        if isFromSearchSelect || isFromNotificationSelect {
            if let recent = ChatManager.getRechtChat(jid: getProfileDetails.jid) {
                if recent.isPrivateChat && !CommonDefaults.isInPrivateChat {
                    self.view.addLaunchSubview()
                    showLockScreen()
                    isFromNotificationSelect = false
                }
            }
            isFromSearchSelect = false
        } else if (pushNotificationSelected && CommonDefaults.showAppLock == true) {
//            if CommonDefaults.isInPrivateChat == true {
//                showLockScreen()
//            } else {
//
//            }
            if lockScreenShown == false {
                showLockScreen()
                lockScreenShown = true
            }
        }
        lockScreenShown = false
    }

    @objc func willEnterForeground() {
        if !pushNotificationSelected {
            self.view.removeLaunchSubview()
        }
    }
    
    private func presentPreviewScreen() {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        present(previewController, animated: true)
    }
    
    private func getUserForAdminBlock() -> Bool {
        let profile = ChatManager.profileDetaisFor(jid: getProfileDetails.jid)
        guard let isBlockedByAdmin = profile?.isBlockedByAdmin else { return false }
        executeOnMainThread { [weak self] in
            self?.checkUserForBlocking(jid: self?.getProfileDetails.jid ?? "", isBlocked: isBlockedByAdmin)
        }
        return isBlockedByAdmin
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isStarredMessagePage {
            networkMonitor()
            GroupManager.shared.groupDelegate = self
            ChatManager.shared.adminBlockDelegate = self
            chatManager.connectionDelegate = self
            chatManager.typingStatusDelegate = self
            ChatManager.setOnGoingChatUser(jid: getProfileDetails.jid)
            recorder.appAudioRecorderDelegate = self
            messageDelegate = nil
            ChatManager.shared.availableFeaturesDelegate = self
            getProfileDetails = ChatManager.getContact(jid: getProfileDetails.jid)
            setProfile()
            // Refresh the data updated from other views
//            chatTableView.reloadDataWithoutScroll()
//            getInitialMessages()
//            queryInitialMessage()
            if self.searchMessageId != "" {
                self.scrollToSearchMessage(id: self.searchMessageId)
                self.searchMessageId = ""
                self.chatTableView.endUpdates()
            }
        }
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.availableFeaturesDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissScheduleMeetPopup()
        navigationView?.isHidden = true
        stopPlayer(isBecomeBackGround: true)
        if !isStarredMessagePage {
            selectedMessageId = ""
            headerView.isHidden = true
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            IQKeyboardManager.shared.enableAutoToolbar = true
            NotificationCenter.default.removeObserver(self)
            audioPlayer?.stop()
            selectedAssets = []
            callDurationTimer = nil
            AppActionSheet.shared.dismissActionSeet(animated: true)
            if let _ = messageDelegate as? MessageInfoViewController {
                FlyMessenger.shared.messageEventsDelegate = self
                chatManager.messageEventsDelegate = self
                ContactManager.shared.profileDelegate = self
                GroupManager.shared.groupDelegate = self
                ChatManager.shared.adminBlockDelegate = self
                ChatManager.shared.messageEventsDelegate = self
                chatManager.connectionDelegate = self
                chatManager.typingStatusDelegate = self
                recorder.appAudioRecorderDelegate = self
                ChatManager.shared.availableFeaturesDelegate = self
            } else if navigationController?.topViewController is ImagePreview || navigationController?.topViewController is ImageEditController{
                FlyMessenger.shared.messageEventsDelegate = self
                chatManager.messageEventsDelegate = self
                ContactManager.shared.profileDelegate = self
                GroupManager.shared.groupDelegate = self
                ChatManager.shared.adminBlockDelegate = self
                ChatManager.shared.messageEventsDelegate = self
                chatManager.connectionDelegate = self
                chatManager.typingStatusDelegate = self
                recorder.appAudioRecorderDelegate = self
                ChatManager.shared.availableFeaturesDelegate = self
            } else {
                FlyMessenger.shared.messageEventsDelegate = nil
                chatManager.messageEventsDelegate = nil
                ContactManager.shared.profileDelegate = nil
                GroupManager.shared.groupDelegate = nil
                ChatManager.shared.adminBlockDelegate = nil
                ChatManager.shared.messageEventsDelegate = nil
                chatManager.connectionDelegate = nil
                chatManager.typingStatusDelegate = nil
                recorder.appAudioRecorderDelegate = nil
                ChatManager.shared.availableFeaturesDelegate = nil
            }
        }
        ChatManager.shared.availableFeaturesDelegate = nil
        isFromContactScreen = false
        isFromGroupInfo = false
        isFromForward = false
        pushNotificationSelected = false
        self.view.removeLaunchSubview()
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        hideMultiSelectionView()
    }
    
    func hideMultiSelectionView() {
        isShareMediaSelected = false
        isShowForwardView = false
        if !isStarredMessagePage {
            textToolBarView?.isHidden = false
        } else {
            showHideMutiSelectionView()
        }
        forwardBottomView?.isHidden = true
        selectedMessages?.removeAll()
        UIView.performWithoutAnimation {
            chatTableView.reloadData()
        }

    }

    func showLockScreen() {
        dismissScheduleMeetPopup()
        if CommonDefaults.appFingerprintenable {
            let vc = PrivateChatFingerPrintPINViewController(nibName: "PrivateChatFingerPrintPINViewController", bundle: nil)
            vc.isFromSearchSelect = isFromSearchSelect
            vc.isFromNotificationSelect = isFromNotificationSelect
            vc.isFromContactScreen = isFromContactScreen
            vc.isFromForward = isFromForward
            vc.isFromGroupInfo = isFromGroupInfo
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            let vc = PrivateChatAuthenticationPINViewController(nibName:"PrivateChatAuthenticationPINViewController", bundle: nil)
            vc.isFromSearchSelect = isFromSearchSelect
            vc.isFromNotificationSelect = isFromNotificationSelect
            vc.isFromContactScreen = isFromContactScreen
            vc.isFromForward = isFromForward
            vc.isFromGroupInfo = isFromGroupInfo
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }

    func dismissScheduleMeetPopup() {
        if let vc = UIApplication.shared.keyWindow?.getTopViewController() {
            if vc is InstantScheduledMeetingViewController {
                vc.dismiss(animated: false)
            }
        }
    }

    func showDeletePicker() {
        executeOnMainThread {  [weak self] in
            let isMessageSentByMe = self?.selectedMessages?.filter({$0.chatMessage.isMessageSentByMe == false}).count
            let isMessageRecalled = self?.selectedMessages?.filter({$0.chatMessage.isMessageRecalled == true}).count
            if self?.selectedMessages?.filter({self?.isDeleteForEveryOne(messageSentTime: $0.chatMessage.mediaChatMessage != nil && $0.chatMessage.messageChatType == .singleChat ? (self?.chatManager.getAcknowlegementTime(messageId: $0.chatMessage.messageId, userJid: $0.chatMessage.chatUserJid)) ?? 0.0 : (self?.chatManager.getAcknowlegementTimeForGroup(messageId: $0.chatMessage.messageId)) ?? 0.0) == false}).count ?? 0 == 0 && isMessageSentByMe == 0 && isMessageRecalled == 0 && self?.isStarredMessagePage == false {
                let deletePicker = DeleteMessageForEveryOneAlertController()
                deletePicker.titleLabel?.text = self?.selectedMessages?.count == 1 ? "Are you sure you want to delete selected Message?" : "Are you sure you want to delete selected messages?"
                deletePicker.delegate = self
                deletePicker.deleteMessages = self?.selectedMessages
                deletePicker.deleteForMeButton?.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
                deletePicker.deleteForEveryOneButton?.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
                deletePicker.cancelButton?.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
                deletePicker.modalPresentationStyle = .overFullScreen
                self?.present(deletePicker, animated: true)
            } else {
                let deletePicker = DeleteMessagesForMeAlertController()
                deletePicker.delegate = self
                deletePicker.deleteMessages = self?.selectedMessages
                deletePicker.titleLabel?.text = self?.selectedMessages?.count == 1 ? "Are you sure you want to delete selected Message?" : "Are you sure you want to delete selected messages?"
                deletePicker.deleteForMeButton?.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
                deletePicker.cancelButton?.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
                deletePicker.modalPresentationStyle = .overFullScreen
                self?.present(deletePicker, animated: true)
            }
        }
    }
    
    private func dismiss() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func navigateToBackButton(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        ChatManager.connect()
        resetData()
    }

    func shareMedia(media: [SelectedMessages],_ controller: UIViewController) {
        var type = String()
        ChatManager.disconnect()
        
        var activityItems: [Any] = []
        
        media.forEach { message in
            if (message.chatMessage.messageType == .text || message.chatMessage.messageType == .autoText) {
                    let localPath = message.chatMessage.messageTextContent
                    activityItems.append(localPath)
            } else if message.chatMessage.messageType == .meet {
                let localPath = message.chatMessage.meetChatMessage?.link ?? ""
                activityItems.append(localPath)
            } else {
                switch message.chatMessage.mediaChatMessage?.messageType {
                case .audio:
                    type = "Audio"
                case .video:
                    type = "Video"
                case .image:
                    type = "Image"
                case .document:
                    type = "Document"
                default:
                    return
                }

                if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                    let localPath = directoryURL.appendingPathComponent("FlyMedia/\(type)/\(message.chatMessage.mediaChatMessage?.mediaFileName ?? "")")
                    activityItems.append(localPath)
                }
//                    let localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("FlyMedia/\(type)/\(message.chatMessage.mediaChatMessage?.mediaFileName ?? "")")
//                    activityItems.append(localPath)
                }
        }

        
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = controller.view
        activityController.popoverPresentationController?.sourceRect = controller.view.frame
       
        if #available(iOS 13.0, *) {
            let config =  [UIActivity.ActivityType.print] as? UIActivityItemsConfigurationReading
            activityController.activityItemsConfiguration = config
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 13.0, *) {
            activityController.isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
        
        activityController.completionWithItemsHandler = { (type,completed,items,error) in
            ChatManager.connect()
            self.resetData()
        }

        controller.present(activityController, animated: true, completion: {
            self.clearSharedMessages()
        })
    }
    
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        self.view.endEditing(true)
        switch true {
        case isDeleteSelected:
            //showConfirmationAlert
            showDeletePicker()
        case isShareMediaSelected:
            print("isShareMediaSelected")
            shareMedia(media: selectedMessages ?? [], self)
            break
        case isStarredMessageSelected:
            setStarOrUnStarredMessages()
        case !isStarredMessageSelected && !isDeleteSelected && !isShareMediaSelected:
            alertController = UIAlertController.init(title: "Message" , message: "Do you want to forward selected message?", preferredStyle: .alert)
            let forwardAction = UIAlertAction(title: "Forward", style: .default) { [weak self] (action) in
                self?.forwardMessageNavigation()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
                self?.dismiss(animated: true,completion: nil)
            }
            forwardAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            cancelAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            alertController?.addAction(cancelAction)
            alertController?.addAction(forwardAction)
            executeOnMainThread { [weak self] in
                if let alert = self?.alertController {
                    self?.present(alert, animated: true, completion : {
                    })
                }
            }
        default:
            break
        }
    }

    func forwardMessageNavigation() {
        navicateToSelectForwardList(forwardMessages: selectedMessages ?? [], dismissClosure: showForwardBottomView)
    }
    
    private func isDeleteForEveryOne(messageSentTime: Double) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        // current date
        let date = formatter.string(from: Date())
        let currentDate = formatter.date(from: date)
        // Message sent date
        let messageSentTimeWithSecs = DateFormatterUtility.shared.convertMillisecondsToDateTimeWithSeconds(milliSeconds: messageSentTime)
        let messageSentDate = formatter.date(from: messageSentTimeWithSecs)
        // calcualate diff
        let diffSeconds = currentDate!.timeIntervalSinceReferenceDate - messageSentDate!.timeIntervalSinceReferenceDate
        print("deleteEveryOne diffSeconds",diffSeconds)
        return diffSeconds <= 30 ? true : false
    }
    
    private func deleteMessageForMe() {
        var messageIds = selectedMessages?.compactMap({$0.chatMessage.messageId})
        deleteViewModel?.getDeleteMessageForMe(jid: getProfileDetails.jid ?? "", messageIdList: messageIds ?? [], deleteChatType: getProfileDetails.profileChatType) { [weak self] (isSuccess, error, data) in

            if !isSuccess{
                AppAlert.shared.alert?.dismiss(animated: false)
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                    self?.resetViews()
                }
                return
            }

            //self?.forwardOrDeleteMessages?.removeAll()
            self?.selectedMessages?.removeAll()
                self?.isShowForwardView = false
            if self?.isReplyViewOpen == true && isSuccess {
                messageIds?.forEach { messageId in
                        chatMessages.enumerated().forEach { (section,message) in
                            message.enumerated().forEach { (row,msg) in
                            if self?.currentPreviewIndexPath != nil {
                                if messageId == chatMessages[self?.currentPreviewIndexPath?.section ?? 0][self?.currentPreviewIndexPath?.row ?? 0].messageId {
                                    self?.replyMessage(indexPath: (self?.currentPreviewIndexPath)!, isMessageDeleted: true, isKeyBoardEnabled: false, isSwipe: false)
                                }
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self?.clearMessages()
                self?.dismiss()
            }
        }
    }
    
    private func deleteMessageForEveryOne() {
        var messageIds = selectedMessages?.compactMap({$0.chatMessage.messageId})
        deleteViewModel?.getDeleteMessageForEveryOne(jid: getProfileDetails.jid ?? "", messageIdList: messageIds ?? [], deleteChatType: getProfileDetails.profileChatType) { [weak self] (isSuccess, error, data) in
            
            if !isSuccess{
                AppAlert.shared.alert?.dismiss(animated: false)
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                    self?.resetViews()
                }
                return
            }
            
            //self?.forwardOrDeleteMessages?.removeAll()
            self?.selectedMessages?.removeAll()
            self?.isShowForwardView = false
            if self?.isReplyViewOpen == true && isSuccess {
                messageIds?.forEach { messageId in
                        chatMessages.enumerated().forEach { (section,message) in
                            message.enumerated().forEach { (row,msg) in
                            if self?.currentPreviewIndexPath != nil {
                                if messageId == chatMessages[self?.currentPreviewIndexPath?.section ?? 0][self?.currentPreviewIndexPath?.row ?? 0].messageId {
                                    self?.replyMessage(indexPath: (self?.currentPreviewIndexPath)!, isMessageDeleted: true, isKeyBoardEnabled: false, isSwipe: false)
                                }
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self?.clearMessages()
                self?.dismiss()
            }
        }
    }
    
    private func showForwardBottomView() {
        if isStarredMessagePage {
            UIView.performWithoutAnimation {
                chatTableView.reloadData()
            }
        } else {
            getInitialMessages()
        }
        forwardBottomView?.isHidden = false
    }
    
    private func clearMessages() {
        DispatchQueue.main.async { [weak self] in
            self?.isShowForwardView = false
            self?.showHideForwardView()
            if self?.isStarredMessagePage == true {
                UIView.performWithoutAnimation {
                    self?.chatTableView?.reloadData()
                }
            } else {
                self?.getInitialMessages()
            }
        }
    }
    
    private func clearSharedMessages() {
        selectedMessages?.removeAll()
        clearMessages()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !isStarredMessagePage {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
            NotificationCenter.default.removeObserver(self, name: Notification.Name(FlyConstants.callPermissionAlertShown), object: nil)
            ChatManager.setOnGoingChatUser(jid: "")
            toolTipController.isMenuVisible = false
            if let messageText = messageTextView, let message = messageText.text {
                messageText.textViewEnd()
                if self.getProfileDetails.profileChatType == .groupChat, let mentionMessage = messageText.mentionText {
                    let mentions = mentionRanges.compactMap({$0.1})
                    var length = [Int]()
                    var location = [Int]()
                    if mentions.isEmpty {
                        FlyMessenger.saveUnsentMessage(id: getProfileDetails.jid, message: mentionMessage.isEmpty ? emptyString() : mentionMessage, mentionedUsers: messageText.mentionedUsers, mentionSearch: mentionRanges.compactMap({$0.0}), mentionLocation: location, mentionLength: length)
                    } else {
                        for mention in mentions {
                            location.append(mention.location)
                            length.append(mention.length)
                        }
                        FlyMessenger.saveUnsentMessage(id: getProfileDetails.jid, message: mentionMessage.isEmpty ? emptyString() : mentionMessage, mentionedUsers: messageText.mentionedUsers, mentionSearch: mentionRanges.compactMap({$0.0}), mentionLocation: location, mentionLength: length)
                    }
                } else {
                    FlyMessenger.saveUnsentMessage(id: getProfileDetails.jid, message: message.isEmpty ? emptyString() : message, mentionedUsers: messageText.mentionedUsers, mentionSearch: [])
                }
            }
            resetGroupMention()
            if isMessageEditing {
                CM.closeMenu()
            }
        }
    }
    
    //MARK: - Adding TapGesture for ReplyView
    @objc func replyViewTapGesture(_ sender: UITapGestureRecognizer? = nil) {
        if isStarredMessagePage {
            return
        }
        guard let gesture = sender else {return }
        let indexPath = self.getIndexpathOfCellFromGesture(gesture)
        currentIndexPath = indexPath
        

        if let id = chatMessages[indexPath.section][indexPath.row].replyParentChatMessage?.messageId, let replyMessage = FlyMessenger.getMessageOfId(messageId: id) {


            let (indexPa, shouldPaginate) = checkReplyMessageAvailability(replyMessageId: id)
            if replyMessage.isMessageRecalled == true || replyMessage.isMessageDeleted == true{
                AppAlert.shared.showToast(message: messageNoLongerAvailable)
                return
            }
            if let scrollToRow = indexPa{
                scrollLogic(indexPath: scrollToRow)
            } else if shouldPaginate{
                fetchMessageListParams.messageId = id
                queryInitialMessage(shouldScrollToMessage: true, messageId: id)
            }
        }
        
        if let cell = self.chatTableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = .clear
            isCellLongPressed = false
        }
    }

    func scrollToSearchMessage(id: String) {
        if isStarredMessagePage {
            return
        }
        if let replyMessage = FlyMessenger.getMessageOfId(messageId: id) {
            let (indexPath, shouldPaginate) = checkReplyMessageAvailability(replyMessageId: id)
            if replyMessage.isMessageRecalled == true || replyMessage.isMessageDeleted == true {
                AppAlert.shared.showToast(message: messageNoLongerAvailable)
                return
            }
            if let scrollToRow = indexPath {
                scrollLogic(indexPath: scrollToRow)
            } else if shouldPaginate{
                fetchMessageListParams.messageId = id
                queryInitialMessage(shouldScrollToMessage: true, messageId: id)
            }
        }
    }
    
    public func highlightMessage(messageId : String) {
        queryInitialMessage(shouldScrollToMessage: true, messageId: messageId)
    }
    
    func scrollLogic(indexPath : IndexPath)  {
        print("#check scrollLogic  \(indexPath.section) \(indexPath.row)")
        self.scrollToTappedMessage = true
        chatTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        
        if !previousIndexPath.isEmpty {
            if let cell = self.chatTableView.cellForRow(at: previousIndexPath) {
                cell.contentView.backgroundColor = .clear
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.scrollToTappedMessage = false
            if let cell = self?.chatTableView.cellForRow(at: indexPath) {
                cell.contentView.backgroundColor = Color.cellSelectionColor
                self?.previousIndexPath = indexPath
                self?.updateSelectionColor(indexPath: indexPath)
            }
        }
    }
    
    func checkReplyMessageAvailability(replyMessageId : String) -> (IndexPath?, Bool) {
        var indexpath : IndexPath? = nil
        var shouldPaginate = false
        chatMessages.enumerated().forEach { (section,chatMessage) in
            chatMessage.enumerated().forEach { (index,element) in
                if chatMessage[index].messageId == replyMessageId {
                    indexpath =  IndexPath(row: index, section: section)
                }
            }
        }
        if indexpath == nil && FlyMessenger.getMessageOfId(messageId: replyMessageId) != nil {
            shouldPaginate = true
        }
        return (indexpath,shouldPaginate)
    }

    func configureGesture(view: UIView) {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector( openContextMenu))
        //longPressGesture.minimumPressDuration = 1
        longPressGesture.delegate = self
        view.addGestureRecognizer(longPressGesture)
    }

    func showContextMenu(gestureRecognizer: UILongPressGestureRecognizer) {
        let cell = gestureRecognizer.view ?? UIView()
        //getting IndexPath for view
        let value = cell.accessibilityIdentifier?.components(separatedBy: "_")
        if value?.count == 2 && editMessageId.isEmpty && !isShowForwardView {
            let indexPath = IndexPath(row: Int(value![1]) ?? 0, section: Int(value![0]) ?? 0)
            guard !chatMessages.isEmpty else {return}
            guard let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row] else {
                return
            }
            editMessageId = message.messageId
            editMessageType = message.messageType
            if isStarredMessagePage {
                contextMenuIndexPath = IndexPath(row: indexPath.row, section: 0)
            } else {
                contextMenuIndexPath = IndexPath(row: indexPath.row, section: indexPath.section)
            }

            CM.items = getMenus(message: message, indexPath: indexPath)
            resetGroupMention()
            mentionBaseView.isHidden = true
            CM.showMenu(viewTargeted: cell, delegate: self, animated: true,position: message.isMessageSentByMe ? 1 : 0, self.view)
        }
    }
    
    func selectedStarItem() {
            isShowForwardView = true
            stopAudioPlayer()
            isDeleteSelected = false
            isStarredMessageSelected = true
            currentIndexPath = contextMenuIndexPath
           starredItemAction()
           showHideMutiSelectionView()
        DispatchQueue.main.async { [weak self] in
            UIView.performWithoutAnimation {
                self?.chatTableView.reloadData()
            }
        }
    }
    
    func editSelectedMessage() {
        if let editMessage = ChatManager.getMessageOfId(messageId: editMessageId) {
            if getProfileDetails.isBlocked {
                showBlockUnblockConfirmationPopUp()
                return
            }
            self.resetReplyView(resignFirstResponder: false)
            resetAudioRecording(isCancel: true)
            attachmentButton.setImage(UIImage(named: "edit_close"), for: .normal)
            chatTextViewXib?.audioButton.isHidden = true
            self.isMessageEditing = true
            CM.closeOnlyMenu()
            messageTextView.becomeFirstResponder()
            messageTextView.textColor = .black
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                CM.updateBaseviewPosition(height: (self.containerBottomConstraint.constant + (self.chatTextView?.bounds.height ?? 0) + 10))
                var messageContent = emptyString()
                if editMessage.messageType == .image || editMessage.messageType == .video {
                    if let mediaMessage = editMessage.mediaChatMessage {
                        messageContent =  mediaMessage.mediaCaptionText
                    }
                } else {
                    messageContent = editMessage.messageTextContent
                }
                 
                if editMessage.mentionedUsersIds.isEmpty {
                    self.messageTextView.text = messageContent
                } else {
                    var dataArray = [String]()
                    let message = ChatUtils.convertMentionUser(message: messageContent, mentionedUsersIds: editMessage.mentionedUsersIds).replacingOccurrences(of: "\\", with: "", options: .literal, range: nil)
                    dataArray.append(message)
                    dataArray.append(editMessage.mentionedUsersIds.joined(separator: ","))
                    self.messageTextView.text = ""
                    self.messageTextView.convertAndInsert(to: dataArray, with: self.messageTextView.selectedRange)
                }
                self.growingTextViewHandler?.resizeTextView(true)
                self.resizeMessageTextView()
                self.scheduleMeetBtn.center.y =  (self.scheduleMeetBtn.center.y - 100)
            }
        }
    }
    
    func closeContextMenu() {
        CM.closeAllViews()
    }

    func getMenus(message: ChatMessage,indexPath: IndexPath) -> [ContextMenuItem] {

        var menusList = [ContextMenuItem]()

        previousIndexPath = indexPath
        selectedChatMessage = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]

        let messageStatus =  message.messageStatus
        if  (messageStatus == .delivered || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged) && !getBlockedByAdmin() && selectedChatMessage?.isMessageRecalled == false && !isStarredMessagePage {
            chatTableView.allowsMultipleSelection = false
            menusList.append(ContextMenuItemWithImage(title: MessageActions.reply.rawValue, image: UIImage(named: "ic_reply") ?? UIImage()))
        }
        
        // Share media message
        if message.messageType != .contact && message.messageType != .location {
            if selectedChatMessage?.isMessageRecalled == false && (selectedChatMessage?.mediaChatMessage?.mediaUploadStatus == .uploaded || selectedChatMessage?.mediaChatMessage?.mediaDownloadStatus == .downloaded || selectedChatMessage?.messageType == .meet || selectedChatMessage?.messageType == .autoText || message.messageType == .text && message.messageTextContent.isURL) {
                menusList.append(ContextMenuItemWithImage(title: MessageActions.share.rawValue, image: UIImage(named: "ic_sharemedia") ?? UIImage()))

        }
    }

        

        if (selectedChatMessage?.messageType == .text || ((selectedChatMessage?.messageType == .image || selectedChatMessage?.messageType == .video || selectedChatMessage?.messageType == .meet || selectedChatMessage?.messageType == .autoText) && !(selectedChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false))) && selectedChatMessage?.isMessageRecalled == false {
            menusList.append(ContextMenuItemWithImage(title: MessageActions.copy.rawValue, image: UIImage(named: "ic_copy") ?? UIImage()))
        }
        
        ChatManager.isMessageEditable(messageId: message.messageId, completionHandler: { isSuccess, error, data in
            if isSuccess {
                if AppUtils.shared.calculateEditMessageTimeDifference(message: message) <= 15 {
                    menusList.append(ContextMenuItemWithImage(title: MessageActions.edit.rawValue, image: UIImage(named: "icon-edit") ?? UIImage()))
                }
            }
        })
        
        var flag : Bool = false

        if (messageStatus == .delivered || messageStatus == .sent || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged)  {
            if ((selectedChatMessage?.mediaChatMessage != nil) && selectedChatMessage?.mediaChatMessage?.mediaUploadStatus == .uploaded || selectedChatMessage?.mediaChatMessage?.mediaDownloadStatus == .downloaded) {
                    flag = true

            }
        }
        if (messageStatus == .delivered || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged)  {
            if selectedChatMessage?.mediaChatMessage == nil {
                    flag = true
            }
        }

        if flag {
            if selectedChatMessage?.isMessageRecalled == false {
                menusList.append(ContextMenuItemWithImage(title: MessageActions.forward.rawValue, image: UIImage(named: "ic_forward") ?? UIImage()))
            }
        }
        
        // Starred Message Item
        if availableFeatures.isStarMessageEnabled {
            if selectedChatMessage?.isMessageRecalled == false {
                let isStar = selectedChatMessage?.isMessageStarred ?? false
                menusList.append(ContextMenuItemWithImage(title: isStar ? unStarTitle : MessageActions.star.rawValue, image: !isStar ? UIImage(named: "ic_star") ?? UIImage() : UIImage(named: "Unstar") ?? UIImage()))
            }
        }
        
        if (selectedChatMessage?.mediaChatMessage?.mediaUploadStatus != .uploading && selectedChatMessage?.mediaChatMessage?.mediaDownloadStatus != .downloading && selectedChatMessage?.isMessageSentByMe == true && selectedChatMessage?.messageStatus != .notAcknowledged) {
            if selectedChatMessage?.isMessageRecalled == false && !isStarredMessagePage {
                menusList.append(ContextMenuItemWithImage(title: MessageActions.info.rawValue, image: UIImage(named: "ic_info") ?? UIImage()))
            }
        }
        /// Report message configure
        if availableFeatures.isReportEnabled {
            if let tmepMessage = selectedChatMessage, !tmepMessage.isMessageSentByMe && !getBlockedByAdmin() && !isStarredMessagePage && tmepMessage.isMessageRecalled == false {
                if !(selectedChatMessage?.isMessageSentByMe ?? false) {
                    menusList.append(ContextMenuItemWithImage(title: MessageActions.report.rawValue, image: UIImage(named: "report") ?? UIImage()))
                }
            }
        }

        /// Delete message configure
        if availableFeatures.isDeleteMessageEnabled {
            if selectedChatMessage?.mediaChatMessage?.mediaUploadStatus == .uploading || selectedChatMessage?.mediaChatMessage?.mediaDownloadStatus == .downloading {
            } else {
                menusList.append(ContextMenuItemWithImage(title: MessageActions.delete.rawValue, image: UIImage(named: "ic_deletegroup") ?? UIImage()))
            }
        }
        if !isStarredMessagePage {
            if getProfileDetails.profileChatType == .groupChat {
                if !isParticipantExist().doesExist {
                    menusList.removeAll { action in
                        action.title == MessageActions.reply.rawValue || action.title == MessageActions.forward.rawValue
                    }
                }
            }
        }
        return menusList
    }

    @objc func openContextMenu(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if messageSearchEnabled {
            hideMessageSearchView()
        }
        executeOnMainThread { [weak self] in
            self?.messageTextView?.resignFirstResponder()
            self?.searchBar?.resignFirstResponder()
            self?.showContextMenu(gestureRecognizer: gestureRecognizer)
        }
        return
    }
    
    private func hideMessageSearchView() {
            currentHighlightedIndex = nil
            currentHighlightedIndexPath = nil
            currentSelectedIndexPath = nil
            searchBar?.resignFirstResponder()
            foundedIndex = []
            foundedSearchResult = false
            searchBar?.isHidden = true
            messageSearchView.isHidden = true
            messageSearchEnabled = false
            messageSearchBar?.text = ""
            messageSearchBar?.resignFirstResponder()
            messageSearchBar?.isHidden = true
    }
}

extension ChatViewParentController: ContextMenuDelegate {
    func contextMenuDidSelect(_ contextMenu: ContextMenu, cell: ContextMenuCell, targetedView: UIView, didSelect item: ContextMenuItem, forRowAt index: Int) -> Bool {
        self.dismissScheduleMeetPopup()
        self.view.isUserInteractionEnabled = true
        switch item.title {
        case MessageActions.copy.rawValue:
            self.copyItemAction()
        case MessageActions.share.rawValue:
            self.isShowForwardView = true
            self.stopAudioPlayer()
            self.isDeleteSelected = false
            self.isShareMediaSelected = true
            self.isStarredMessageSelected = false
            self.multipleSelectionTitle = shareTitle
            self.currentIndexPath = contextMenuIndexPath
            self.refreshBubbleImageView(indexPath: contextMenuIndexPath, isSelected: true, title: shareTitle )
            UIView.performWithoutAnimation {
                self.chatTableView.reloadData()
            }
        case MessageActions.delete.rawValue:
            self.isShowForwardView = true
            self.stopAudioPlayer()
            self.isDeleteSelected = true
            self.isStarredMessageSelected = false
            self.isShareMediaSelected = false
            self.currentIndexPath = contextMenuIndexPath
            self.multipleSelectionTitle = deleteTitle
            self.refreshBubbleImageView(indexPath: contextMenuIndexPath, isSelected: true, title: deleteTitle)
            UIView.performWithoutAnimation {
                self.chatTableView.reloadData()
            }
        case MessageActions.reply.rawValue:
            self.replyMessage(indexPath: self.previousIndexPath, isMessageDeleted: false, isKeyBoardEnabled: true, isSwipe: true)
        case MessageActions.report.rawValue:
            self.reportItemAction()
        case MessageActions.info.rawValue:

            self.infoItemAction(dismissClosure: getInitialMessages)

        case MessageActions.forward.rawValue:
            self.isShowForwardView = true
            self.stopAudioPlayer()
            self.isDeleteSelected = false
            self.isStarredMessageSelected = false
            self.isShareMediaSelected = false
            self.currentIndexPath = contextMenuIndexPath
            self.multipleSelectionTitle = forwardTitle
            self.refreshBubbleImageView(indexPath: contextMenuIndexPath, isSelected: true, title: forwardTitle)
            UIView.performWithoutAnimation {
                self.chatTableView.reloadData()
            }
        case MessageActions.star.rawValue:
            isShareMediaSelected = false
            selectedStarItem()
        case MessageActions.unStar.rawValue:
            isShareMediaSelected = false
            selectedStarItem()
            
        case MessageActions.edit.rawValue:
            checkUserBusyStatusEnabled(self) { [weak self] status in
                if status {
                    executeOnMainThread {
                        self?.editSelectedMessage()
                    }
                }
            }
        default:
            break
        }
        self.chatTableView.layoutIfNeeded()
        return true
    }

    func contextMenuDidDeselect(_ contextMenu: ContextMenu, cell: ContextMenuCell, targetedView: UIView, didSelect item: ContextMenuItem, forRowAt index: Int) {

    }

    func contextMenuDidAppear(_ contextMenu: ContextMenu) {

    }

    func contextMenuDidDisappear(_ contextMenu: ContextMenu) {
        self.attachmentButton.setImage(UIImage(named: "ic_send"), for: .normal)
        chatTextViewXib?.audioButton.isHidden = false
        self.isMessageEditing = false
        self.isMention = false
        self.currentSelectedIndexPath = nil
        self.editMessageId = emptyString()
        self.messageTextView?.resignFirstResponder()
        self.messageTextView.text = FlyMessenger.getUnsentMessageOf(id: getProfileDetails.jid).textContent
        self.resetMessageTextView()
        self.handleSendButton()
        self.resizeMessageTextView()
    }

    func contextMenuDidMentionSelect(_ contextMenu: ContextMenu, jid: String, profileDetail: ProfileDetails) {
        if let userId = try? FlyUtils.getIdFromJid(jid: jid) {
            self.mentionDidSelect(userId: userId, profileDetail: profileDetail)
        }
    }

}

//MARK - Chat Grouping Logic
extension ChatViewParentController {
    private func addNewGroupedMessage(messages:  [ChatMessage]) {
        executeOnMainThread { [weak self] in
            guard let strongSelf = self else { return }
            if messages.isEmpty {
            }
        }
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
            print("addNewGroupedMessage=====>")
//                chatTableView?.beginUpdates()
//                chatTableView?.insertSections([0], with: .top)
//                let lastSection = chatTableView?.numberOfSections
//                chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .automatic)
//                chatTableView?.endUpdates()
//                let indexPath = IndexPath(row: 0, section: 0)
//                chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
            UIView.performWithoutAnimation {
                chatTableView.reloadData()
            }
                messageTextView?.text = ""
            }
        }
    
    
    private func groupMessages(messages: [ChatMessage]) -> [[ChatMessage]] {
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
    
    private func groupOldMessages(messages: [ChatMessage]){
        print("#loss groupOldMessages \(messages.count)")
        if messages.count == 0 {
            return
        }
//        let filtered = messages.filter { message in
//            return !getAllMessages.contains{$0.messageId == message.messageId}
//        }
//        getAllMessages.insert(contentsOf: filtered, at: 0)
        getAllMessages.insert(contentsOf: messages, at: 0)
        let values = groupMessages(messages: getAllMessages)
        chatMessages.removeAll()
        chatMessages = values
        executeOnMainThread { [weak self] in
            UIView.performWithoutAnimation {
                self?.chatTableView?.reloadData()
            }
            print("#loss groupOldMessages reload done \(chatMessages.count)")
        }
    }
    
    private func setLastMessage(messageId : String){
        if nextMessagesLoadingDone {
            print("loss if setLastMessage.........")
            fetchMessageListQuery?.setLastMessage(messageId: messageId)
        } else {
            print("loss else setLastMessage.........")
        }
    }
    
    
    private func groupInitialMessages(messages: [ChatMessage], completion : (() -> Void)? = nil){
        print("#scrui #top \(messages.count)")
        chatMessages.removeAll()
        getAllMessages.removeAll()
        getAllMessages.append(contentsOf: messages)
        let values = groupMessages(messages: getAllMessages)
        chatMessages.append(contentsOf: values)
        print("#scrui #top after \(chatMessages.count) \(chatMessages.reduce(0) { $0 + $1.count })")
        executeOnMainThread { [weak self] in
            UIView.performWithoutAnimation {
                self?.chatTableView?.reloadData()
            }
            completion?()
        }
    }
    
    private func groupLatestMessages(messages: [ChatMessage]){
        if messages.isEmpty{
            return
        }
        print("#loss groupLatestMessages \(messages.count)")
        
        print("#scrui #bottom after \(chatMessages.count) \(chatMessages.reduce(0) { $0 + $1.count })")
        executeOnMainThread { [self] in
            chatMessages.removeAll()
            print("#check #scrui #bottom \(messages.count) \(messages.first?.messageTextContent)  \(messages.last?.messageTextContent)")
            getAllMessages.append(contentsOf: messages)
            let values = groupMessages(messages: getAllMessages)
            chatMessages.append(contentsOf: values)
            //https://stackoverflow.com/questions/68560400/insert-rows-into-tableview-onto-without-changing-scroll-position
            let distanceFromOffset = (self.chatTableView.contentSize.height)-(self.chatTableView.contentOffset.y)
            print("#offset before => \(self.chatTableView.contentSize.height) \(self.chatTableView.contentOffset.y)")
            UIView.performWithoutAnimation {
                self.chatTableView.reloadData()
            }
            print("#loss groupLatestMessages reload done \(chatMessages.count)")
            let offset = self.chatTableView.contentSize.height - distanceFromOffset
            self.chatTableView.layoutIfNeeded()
            print("#offset after => \(self.chatTableView.contentSize.height) \(offset)")
            self.chatTableView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
        }
    }
    
    
    // This method append new message on UI when new message is received.
    private func appendNewMessage(message: ChatMessage) {
        if isMessageExist(messageId: message.messageId) {
            return
        }
        var lastSection = 0
        executeOnMainThread { [weak self] in
            self?.setLastMessage(messageId: message.messageId)
            if  chatMessages.count == 0 {
                lastSection = ( self?.chatTableView?.numberOfSections ?? 0)
            }else {
                lastSection = ( self?.chatTableView?.numberOfSections ?? 0) - 1
            }
        }
        isDocumentOptionSelected = message.mediaChatMessage?.messageType == .document ? true : false
        if chatMessages.count == 0 {
            addNewGroupedMessage(messages: [message])
        }else {
            let index = chatMessages[0].firstIndex(where: { $0.messageSentTime < message.messageSentTime})
            chatMessages[0].insert(message, at: index ?? 0)
            getAllMessages.append(message)
            print("appendNewMessage \(lastSection)")
            //chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .right)

//            getAllMessages = getAllMessages.sorted(by: { $0.messageSentTime > $1.messageSentTime })
//            chatMessages.enumerated().forEach { (index, value) in
//                if index == 0 {
//                    chatMessages[index] = value.sorted(by: { $0.messageSentTime > $1.messageSentTime })
            UIView.performWithoutAnimation {
                chatTableView.reloadData()
            }
//                }
//            }
//
//            let indexPath = IndexPath(row: 0, section: 0)
//            chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        if message.messageType != .autoText {
            updateUnreadMessageCount(messageId: message.messageId)
        }
    }
}

// MARK - Base setup
extension ChatViewParentController {
    func setUpUI() {
        getProfileDetails = ChatManager.profileDetaisFor(jid: getProfileDetails.jid)
        setupTableviewLongPressGesture()
        setProfile()
        chatTableView.dataSource = self
        chatTableView.delegate = self
        chatTableView.transform = CGAffineTransform(rotationAngle: -.pi)
        chatTableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.size.width - CGFloat(constraintsConstant))
        registerNibs()
        loadBottomView()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToInfoScreen(sender:)))
        userImage.isUserInteractionEnabled = true
        userImage.addGestureRecognizer(gestureRecognizer)
        userInfoStack.isUserInteractionEnabled = true
        userInfoStack.addGestureRecognizer(gestureRecognizer)
        setUpAudioRecordView()
        lastSeenLabel.isHidden = false
    }
    
    @objc func goToInfoScreen(sender: Any){
        bottomSheet = nil
        if !bottomSheetOpened {
            if getProfileDetails.profileChatType == .singleChat {
                performSegue(withIdentifier: Identifiers.contactInfoViewController, sender: nil)
            } else if getProfileDetails.profileChatType == .groupChat {
                performSegue(withIdentifier: Identifiers.groupInfoViewController, sender: nil)
            }
        }
    }
    
    func setProfile(jid: String? = emptyString()) {
        if getProfileDetails != nil {
            userNameLabel.text = getUserName(jid : getProfileDetails.jid ,name: getProfileDetails.name, nickName: getProfileDetails.nickName, contactType: getProfileDetails.contactType)
            let imageUrl = (getProfileDetails?.thumbImage.isEmpty ?? true) ? getProfileDetails?.image : getProfileDetails.thumbImage
            let urlString = ChatManager.getImageUrl(imageName: imageUrl ?? emptyString())
            print("setProfile \(urlString)")
            var url = URL(string: urlString)
            var placeholder = UIImage()
            let isImageEmpty = getProfileDetails.image.isEmpty
            if getProfileDetails.profileChatType == .groupChat {
                placeholder = UIImage(named: ImageConstant.ic_group_small_placeholder) ?? UIImage()
                if let profileId = jid, let searchMember = searchGroupMembers.filter({$0.memberJid == profileId}).first, let member = searchGroupMembers.filter({$0.memberJid == profileId}).first {
                    if let profile = ChatManager.profileDetaisFor(jid: profileId) {
                        member.profileDetail = profile
                        searchMember.profileDetail = profile
                        mentionTableView.reloadData()
                    }
                }
            }else if getProfileDetails.contactType == .deleted || getProfileDetails.isBlockedByAdmin || getisBlockedMe() || (IS_LIVE && ENABLE_CONTACT_SYNC && getProfileDetails.isItSavedContact == false) {
                placeholder = UIImage(named: "ic_profile_placeholder") ?? UIImage()
                url = URL(string: "")
            } else {
                placeholder = getPlaceholder(name: getUserName(jid : getProfileDetails.jid ,name: getProfileDetails.name, nickName: getProfileDetails.nickName, contactType: getProfileDetails.contactType), color: contactColor)
            }
            if getProfileDetails.contactType == .deleted || getProfileDetails.isBlockedByAdmin || getisBlockedMe() {
                scheduleMeetBtn.isHidden = true
            } else {
                scheduleMeetBtn.isHidden = false
            }
            userImage.sd_setImage(with: url, placeholderImage: placeholder)
        }
    }
    func setUpHeaderView() {
        navigationController?.isNavigationBarHidden = true
        headerView.isHidden = false
        setUpStatusBar()
        chatTableView.dataSource = self
        chatTableView.delegate = self
        chatTableView.transform = CGAffineTransform(rotationAngle: -.pi)
        registerNibs()
    }
    
    func loadAudioView() {
        audioViewXib = Bundle.main.loadNibNamed(Identifiers.audioView, owner: self, options: nil)?[0] as? AudioView
        audioViewXib?.frame =  UIScreen.main.bounds
        audioViewXib?.layoutIfNeeded()
        //view.addSubview(audioViewXib!)
        audioViewXib?.isHidden = true
        view.bringSubviewToFront(audioViewXib!)
        let window = UIApplication.shared.keyWindow
        audioViewXib?.frame = window?.bounds ?? CGRect()
        window?.addSubview(audioViewXib ?? UIView())
    }
    
    func getPlaceholder(name: String , color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(userImage.frame.size.height), font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    func setupTableviewLongPressGesture() {
        if #available(iOS 16.0, *) {
            editMenuInteraction = UIEditMenuInteraction(delegate: self)
            chatTableView.addInteraction(editMenuInteraction!)
        } else {
            // Fallback on earlier versions
        }
        
//        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector( handleCellLongPress))
//        longPressGesture.delegate = self
//        chatTableView.addGestureRecognizer(longPressGesture)
    }
    
    func onMultiSelectionHideAndShow() {
        if(longPressCount > 1) {
            copyButton.isHidden = true
            replyButton.isHidden = true
        }
        else {
            copyButton.isHidden = false
            replyButton.isHidden = false
        }
    }
    
    func showToolTipBar(cell: UITableViewCell) {
//        if #available(iOS 13.0, *) {
//            toolTipController.showMenu(from: cell.contentView, rect: cell.contentView.bounds)
//            toolTipController.isMenuVisible = true
//        } else {
//            toolTipController.setTargetRect(cell.contentView.bounds, in: cell.contentView)
//            toolTipController.setMenuVisible(true, animated: true)
//        }
    }
    
    func navicateToSelectForwardList(forwardMessages: [SelectedMessages],dismissClosure:(() -> Void)?) {
        let destination = ForwardViewController(nibName: Identifiers.forwardVC, bundle: nil)
        destination.pageDismissClosure = { [weak self] in
            self?.dismisForwardAction()
        }
        destination.forwardMessages = forwardMessages
        destination.selectedUserDelegate = self
        destination.refreshProfileDelegate = self
        if !isStarredMessagePage {
            destination.fromJid = getProfileDetails.jid
        }
        if ChatManager.isPrivateChat(jid: getProfileDetails.jid) {
            destination.hidePrivateChatUsers = false
        } else {
            destination.hidePrivateChatUsers = true
        }
        destination.isFromPrivateChat = isFromPrivateChat
        presentViewController(source: self, destination: destination)
    }
    
    fileprivate func presentViewController(source: UIViewController, destination: UIViewController) {
        destination.modalPresentationStyle = .fullScreen
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc func replyItemAction() {
        if let cell = chatTableView.cellForRow(at: previousIndexPath) {
            cell.contentView.backgroundColor = .clear
            replyMessage(indexPath: previousIndexPath, isMessageDeleted: false, isKeyBoardEnabled: true, isSwipe: true)
        }
    }
    
    @objc func reportItemAction() {
        let tempMessage = chatMessages[previousIndexPath.section][previousIndexPath.row]
        if let profileDetails = self.getProfileDetails {
            self.reportFromMessage(chatMessage: tempMessage, profileDetail: profileDetails)
        }
        
        audioPlayer?.pause()
        stopPlayer(isBecomeBackGround: true)
    }
    
    @objc func forwardItemAction() {
        isShowForwardView = true
        isDeleteSelected = false
        isStarredMessageSelected = false
        currentIndexPath = previousIndexPath
        multipleSelectionTitle = forwardTitle
        refreshBubbleImageView(indexPath: previousIndexPath, isSelected: true, title: forwardTitle)
        UIView.performWithoutAnimation {
            chatTableView.reloadData()
        }
    }
    
    @objc func deleteItemAction() {
        isShowForwardView = true
        isDeleteSelected = true
        isStarredMessageSelected = false
        currentIndexPath = previousIndexPath
        multipleSelectionTitle = deleteTitle
        refreshBubbleImageView(indexPath: currentIndexPath, isSelected: true, title: deleteTitle)
        UIView.performWithoutAnimation {
            chatTableView.reloadData()
        }
    }
    
    @objc func starredItemAction() {
        isShowForwardView = true
        isDeleteSelected = false
        isStarredMessageSelected = true
        currentIndexPath = previousIndexPath
        updateFavMessages(indexPath: currentIndexPath)
    }
    
    @objc func copyItemAction() {
        let getMessage = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[previousIndexPath.row] : starredMessages[previousIndexPath.row] : chatMessages[previousIndexPath.section][previousIndexPath.row]
        let board = UIPasteboard.general
        if let chatMessage = getMessage {
            if getMessage?.messageType == .text || getMessage?.messageType == .autoText {
                let textContent = chatMessage.messageTextContent
                if !chatMessage.mentionedUsersIds.isEmpty {
                    let message = ChatUtils.convertMentionUser(message: textContent, mentionedUsersIds: chatMessage.mentionedUsersIds)
                    board.strings = [message, chatMessage.mentionedUsersIds.joined(separator: ",")]
                } else {
                    board.string = textContent
                }
            } else if getMessage?.messageType == .video || getMessage?.messageType == .image {
                let textContent = chatMessage.mediaChatMessage?.mediaCaptionText
                if !chatMessage.mentionedUsersIds.isEmpty {
                    let message = ChatUtils.convertMentionUser(message: textContent ?? emptyString(), mentionedUsersIds: chatMessage.mentionedUsersIds)
                    board.strings = [message, chatMessage.mentionedUsersIds.joined(separator: ",")]
                } else {
                    board.string = textContent ?? emptyString()
                }
            } else if getMessage?.messageType == .meet {
                board.string = getMessage?.meetChatMessage?.link
            }
            AppAlert.shared.showToast(message: "1 \(copyAlert.localized)")
        }
    }
    
    @objc func infoItemAction(dismissClosure:(()->())?) {
        if let audioPlayer = audioPlayer, let audioIndexPath = currenAudioIndexPath, let audioUrl = currentAudioUrl {
            if audioPlayer.isPlaying {
                audioPlayerSetup(indexPath: audioIndexPath, audioUrl: audioUrl)
            }
        }
        if let infoMessage = selectedChatMessage, infoMessage.isMessageSentByMe {
            let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
            let messageInfoVC = storyboard.instantiateViewController(withIdentifier: Identifiers.messageInfoViewController) as! MessageInfoViewController
            messageInfoVC.chatMessage = infoMessage
            messageInfoVC.refreshDelegate = self
            messageInfoVC.profileDetails = getProfileDetails
            messageInfoVC.getProfileDetails = getProfileDetails
            messageInfoVC.fetchMessageListQuery = fetchMessageListQuery
            self.messageDelegate = messageInfoVC as MessageDelegate
            navigationController?.pushViewController(messageInfoVC, animated: true)
            view.endEditing(true)
        }
    }
    
    @objc func handleCellLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if isShowForwardView == false {
            var replyItem: UIMenuItem!
            var forwardItem: UIMenuItem!
            var reportItem: UIMenuItem!
            var deleteItem: UIMenuItem!
            var copyItem: UIMenuItem!
            var infoItem: UIMenuItem!
            var starItem: UIMenuItem!
            var editItem: UIMenuItem!
            longPressActions = []
            messageTextView?.resignFirstResponder()
            
            if( longPressCount == 0 && chatMessages.count > 0) {
                if gestureRecognizer.state == .began {
                    isCellLongPressed = true
                    let touchPoint = gestureRecognizer.location(in:  chatTableView)
                    if let indexPath =  chatTableView.indexPathForRow(at: touchPoint) {
                        previousIndexPath = indexPath
                        selectedChatMessage = chatMessages[indexPath.section ][indexPath.row]
                        
                        let messageStatus =  chatMessages[indexPath.section ][indexPath.row].messageStatus
                        if  (messageStatus == .delivered || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged) && !getBlockedByAdmin() && selectedChatMessage?.isMessageRecalled == false {
                            chatTableView.allowsMultipleSelection = false
                            
                            if #available(iOS 16.0, *) {
                                let menuPoint = CGPoint(x: self.view.center.x, y: touchPoint.y)
                                let configuration = UIEditMenuConfiguration(identifier: "replyConfig", sourcePoint: menuPoint)
                                if let interaction = editMenuInteraction as? UIEditMenuInteraction{
                                    interaction.presentEditMenu(with: configuration)
                                }
                            } else {
                                let replyImage = UIImage(named: "replyIcon")
                                replyItem = UIMenuItem(title: "Reply", image: replyImage) { [weak self] _ in
                                    if let cell = self?.chatTableView.cellForRow(at: indexPath) {
                                        cell.contentView.backgroundColor = .clear
                                        self?.replyMessage(indexPath: indexPath, isMessageDeleted: false, isKeyBoardEnabled: true, isSwipe: true)
                                    }
                                }
                            }
                        }
                        
                        // Starred Message Item
                        if selectedChatMessage?.isMessageRecalled == false {
                            if #available(iOS 16.0, *) {
                                let menuPoint = CGPoint(x: self.view.center.x, y: touchPoint.y)
                                let configuration = UIEditMenuConfiguration(identifier: "starConfig", sourcePoint: menuPoint)
                                if let interaction = editMenuInteraction as? UIEditMenuInteraction{
                                    interaction.presentEditMenu(with: configuration)
                                }
                            } else {
                                let starImage = UIImage(named: "ic_star")
                                starItem = UIMenuItem(title: "", image: starImage) { [weak self] _ in
                                    self?.starredItemAction()
                                }
                            }
                        }
                        // Copy Message Item
                        if (selectedChatMessage?.messageType == .text || ((selectedChatMessage?.messageType == .image || selectedChatMessage?.messageType == .video || selectedChatMessage?.messageType == .autoText) && !(selectedChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false))) && selectedChatMessage?.isMessageRecalled == false {
                            if #available(iOS 16.0, *) {
                                let menuPoint = CGPoint(x: self.view.center.x, y: touchPoint.y)
                                let configuration = UIEditMenuConfiguration(identifier: "copyConfig", sourcePoint: menuPoint)
                                if let interaction = editMenuInteraction as? UIEditMenuInteraction{
                                    interaction.presentEditMenu(with: configuration)
                                }
                            } else {
                                copyItem = UIMenuItem(title: "Copy") { [weak self] _ in
                                    self?.copyItemAction()
                                }
                            }
                        }
                        var flag : Bool = false
                        
                        if (messageStatus == .delivered || messageStatus == .sent || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged)  {
                            if ((chatMessages[indexPath.section][indexPath.row].mediaChatMessage != nil) && chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaUploadStatus == .uploaded || chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus == .downloaded) {
                                flag = true
                                
                            }
                        }
                        if (messageStatus == .delivered || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged)  {
                            if chatMessages[indexPath.section ][indexPath.row].mediaChatMessage == nil {
                                flag = true
                            }
                        }
                        
                        if flag {
                            if selectedChatMessage?.isMessageRecalled == false {
                                if #available(iOS 16.0, *) {
                                    let menuPoint = CGPoint(x: self.view.center.x, y: touchPoint.y)
                                    let configuration = UIEditMenuConfiguration(identifier: "forwardconfig", sourcePoint: menuPoint)
                                    if let interaction = editMenuInteraction as? UIEditMenuInteraction{
                                        interaction.presentEditMenu(with: configuration)
                                    }
                                } else {
                                    forwardItem = UIMenuItem(title: "Forward") { [weak self] _ in
                                        self?.isShowForwardView = true
                                        self?.stopAudioPlayer()
                                        self?.isDeleteSelected = false
                                        self?.currentIndexPath = indexPath
                                        self?.multipleSelectionTitle = forwardTitle
                                        self?.refreshBubbleImageView(indexPath: indexPath, isSelected: true, title: forwardTitle)
                                        UIView.performWithoutAnimation {
                                            self?.chatTableView.reloadData()
                                        }
                                    }
                                }
                            }
                        }
                        if (selectedChatMessage?.mediaChatMessage?.mediaUploadStatus != .uploading && selectedChatMessage?.mediaChatMessage?.mediaDownloadStatus != .downloading && selectedChatMessage?.isMessageSentByMe == true && selectedChatMessage?.messageStatus != .notAcknowledged) {
                            if selectedChatMessage?.isMessageRecalled == false {
                                if #available(iOS 16.0, *) {
                                    let menuPoint = CGPoint(x: self.view.center.x, y: touchPoint.y)
                                    let configuration = UIEditMenuConfiguration(identifier: "infoConfig", sourcePoint: menuPoint)
                                    if let interaction = editMenuInteraction as? UIEditMenuInteraction{
                                        interaction.presentEditMenu(with: configuration)
                                    }
                                } else {
                                    infoItem = UIMenuItem(title: "Info") { [weak self] _ in
                                        self?.infoItemAction(dismissClosure: self?.getInitialMessages)
                                    }
                                }
                            }
                        }
                        /// Report message configure
                        if let tmepMessage = selectedChatMessage, !tmepMessage.isMessageSentByMe && !getBlockedByAdmin() {
                            if !chatMessages[indexPath.section ][indexPath.row].isMessageSentByMe {
                                if #available(iOS 16.0, *) {
                                    let menuPoint = CGPoint(x: self.view.center.x, y: touchPoint.y)
                                    let configuration = UIEditMenuConfiguration(identifier: "reportConfig", sourcePoint: menuPoint)
                                    if let interaction = editMenuInteraction as? UIEditMenuInteraction {
                                        interaction.presentEditMenu(with: configuration)
                                    }
                                } else{
                                    reportItem = UIMenuItem(title: report) { [weak self] _ in
                                        self?.reportItemAction()
                                    }
                                }
                            }
                        }
                        
                        /// Delete message configure
                        
                        if selectedChatMessage?.mediaChatMessage?.mediaUploadStatus == .uploading || selectedChatMessage?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                            deleteItem = nil
                        } else {
                            if #available(iOS 16.0, *) {
                                let menuPoint = CGPoint(x: self.view.center.x, y: touchPoint.y)
                                let configuration = UIEditMenuConfiguration(identifier: "deleteConfig", sourcePoint: menuPoint)
                                if let interaction = editMenuInteraction as? UIEditMenuInteraction{
                                    interaction.presentEditMenu(with: configuration)
                                }
                            } else {
                                deleteItem = UIMenuItem(title: "Delete") { [weak self] _ in
                                    self?.isShowForwardView = true
                                    self?.stopAudioPlayer()
                                    self?.isDeleteSelected = true
                                    self?.currentIndexPath = indexPath
                                    self?.multipleSelectionTitle = deleteTitle
                                    self?.refreshBubbleImageView(indexPath: indexPath, isSelected: true, title: deleteTitle)
                                    UIView.performWithoutAnimation {
                                        self?.chatTableView.reloadData()
                                    }
                                }
                            }
                        }
                        
                        // Edit Message
                        
                        editItem = UIMenuItem(title: "Edit", action: { [weak self] _ in
                            
                        })
                        
                        if getProfileDetails.profileChatType == .groupChat {
                            if !isParticipantExist().doesExist {
                                replyItem = nil
                                forwardItem = nil
                            }
                        }
                        
                        if messageStatus == .notAcknowledged || messageStatus == .sent {
                            infoItem = nil
                        }

                        
                        if messageStatus == .notAcknowledged || messageStatus == .sent {
                            infoItem = nil
                        }
                        
                        let isCarbon = selectedChatMessage?.isCarbonMessage ?? false
                        let isSentByMe = selectedChatMessage?.isMessageSentByMe ?? false
                        
                        if isCarbon && isSentByMe && (selectedChatMessage?.mediaChatMessage?.mediaDownloadStatus != .downloaded) {
                            infoItem = nil
                        }
                        toolTipController.menuItems = []
                        if replyItem != nil {
                            toolTipController.menuItems?.append(replyItem)
                        }
                        
                        if forwardItem != nil {
                            toolTipController.menuItems?.append(forwardItem)
                        }
                        
                        if starItem != nil  {
                            toolTipController.menuItems?.append(starItem)
                        }
                        
                        if copyItem != nil {
                            toolTipController.menuItems?.append(copyItem)
                        }
                        
                        if reportItem != nil {
                            toolTipController.menuItems?.append(reportItem)
                        }
                        
                        if deleteItem != nil {
                            toolTipController.menuItems?.append(deleteItem)
                        }
                        
                        if infoItem != nil {
                            toolTipController.menuItems?.append(infoItem)
                        }
                        
                        if editItem != nil {
                            toolTipController.menuItems?.append(editItem)
                        }
                        
                    if selectedChatMessage?.isMessageRecalled ?? false {
                        if let cell = chatTableView.cellForRow(at: indexPath) as? DeleteForEveryOneViewCell {
                            showToolTipBar(cell: cell)
                        } else if let cell = chatTableView.cellForRow(at: indexPath) as? DeleteForEveryOneReceiverCell {
                            showToolTipBar(cell: cell)
                        }
                        
                        if copyItem != nil {
                            toolTipController.menuItems?.append(copyItem)
                        }
                        
                        if starItem != nil  {
                            toolTipController.menuItems?.append(starItem)
                        }
                        
                        if reportItem != nil {
                            toolTipController.menuItems?.append(reportItem)
                        }
                        
                        if deleteItem != nil {
                            toolTipController.menuItems?.append(deleteItem)
                        }
                        
                        if infoItem != nil {
                            toolTipController.menuItems?.append(infoItem)
                        }
                        
                        if selectedChatMessage?.isMessageRecalled ?? false {
                            if let cell = chatTableView.cellForRow(at: indexPath) as? DeleteForEveryOneViewCell {
                                showToolTipBar(cell: cell)
                            } else if let cell = chatTableView.cellForRow(at: indexPath) as? DeleteForEveryOneReceiverCell {
                                showToolTipBar(cell: cell)
                            }
                        }
                    }
                            switch selectedChatMessage?.messageType {
                            case .audio:
                                switch selectedChatMessage?.isMessageSentByMe ?? false {
                                case true:
                                    if let cell = chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                        showToolTipBar(cell: cell)
                                    }
                                case false:
                                    if let cell = chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                                        showToolTipBar(cell: cell)
                                    }
                                }
                            case .video, .image:
                                switch selectedChatMessage?.isMessageSentByMe ?? false {
                                case true:
                                    if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                                        showToolTipBar(cell: cell)
                                    }
                                case false:
                                    if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                                        showToolTipBar(cell: cell)
                                    }
                                }
                                
                            case .document:
                                switch selectedChatMessage?.isMessageSentByMe ?? false {
                                case true:
                                    if let cell = chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                                        showToolTipBar(cell: cell)
                                    }
                                case false:
                                    if let cell = chatTableView.cellForRow(at: indexPath) as? ReceiverDocumentsTableViewCell {
                                        showToolTipBar(cell: cell)
                                    }
                                }
                                
                            default:
                                if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewParentMessageCell {
                                    showToolTipBar(cell: cell)
                                }
                            }
                        }
                    }
                }
            }
        }
    
        func registerNibs() {
            chatTableView.register(UINib(nibName: Identifiers.chatViewTextOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewTextOutgoingCell)
            chatTableView.register(UINib(nibName: Identifiers.chatViewTextIncomingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewTextIncomingCell)
            chatTableView.register(UINib(nibName: Identifiers.chatViewLocationIncomingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewLocationIncomingCell)
            chatTableView.register(UINib(nibName: Identifiers.chatViewLocationOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewLocationOutgoingCell)
            chatTableView.register(UINib(nibName: Identifiers.chatViewContactIncomingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewContactIncomingCell)
            chatTableView.register(UINib(nibName: Identifiers.chatViewContactOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewContactOutgoingCell)
            chatTableView.register(UINib(nibName: Identifiers.audioSender , bundle: .main), forCellReuseIdentifier: Identifiers.audioSender)
            chatTableView.register(UINib(nibName: Identifiers.audioReceiver , bundle: .main), forCellReuseIdentifier: Identifiers.audioReceiver)
            chatTableView.register(UINib(nibName: Identifiers.imageSender , bundle: .main), forCellReuseIdentifier: Identifiers.imageSender)
            chatTableView.register(UINib(nibName: Identifiers.imageReceiverCell , bundle: .main), forCellReuseIdentifier: Identifiers.imageReceiverCell)
            chatTableView.register(UINib(nibName: Identifiers.videoIncomingCell , bundle: .main), forCellReuseIdentifier: Identifiers.videoIncomingCell)
            chatTableView.register(UINib(nibName: Identifiers.videoOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.videoOutgoingCell)
            chatTableView.register(UINib(nibName: Identifiers.notificationCell , bundle: .main), forCellReuseIdentifier: Identifiers.notificationCell)
            chatTableView.register(UINib(nibName: Identifiers.senderDocumenCell,
                                         bundle: .main), forCellReuseIdentifier: Identifiers.senderDocumenCell)
            chatTableView.register(UINib(nibName: Identifiers.receiverDocumentCell,
                                         bundle: .main), forCellReuseIdentifier: Identifiers.receiverDocumentCell)
            chatTableView.register(UINib(nibName: Identifiers.deleteEveryOneCell,
                                         bundle: .main), forCellReuseIdentifier: Identifiers.deleteEveryOneCell)
            chatTableView.register(UINib(nibName: Identifiers.deleteEveryOneReceiverCell,
                                         bundle: .main), forCellReuseIdentifier: Identifiers.deleteEveryOneReceiverCell)
            chatTableView.register(UINib(nibName: Identifiers.scheduledMeetingSenderCell,
                                         bundle: .main), forCellReuseIdentifier: Identifiers.scheduledMeetingSenderCell)
            chatTableView.register(UINib(nibName: Identifiers.scheduledMeetingReceiverCell,
                                         bundle: .main), forCellReuseIdentifier: Identifiers.scheduledMeetingReceiverCell)
        }
        
        func loadBottomView() {
            chatTextViewXib = Bundle.main.loadNibNamed(Identifiers.chatTextView, owner: self, options: nil)?[0] as? ChatTextView
            chatTextViewXib?.frame =  containerView.bounds
            chatTextViewXib?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            chatTextView?.layer.borderWidth = CGFloat(borderWidth)
            chatTextView?.layer.borderColor = Color.borderColor?.cgColor
            chatTextView?.layer.cornerRadius = CGFloat(cornerRadius)
            messageTextView?.delegate = self
            //messageTextView?.placeholder = startTyping.localized
            messageTextView?.text = (messageText?.isNotEmpty == true && replyJid == getProfileDetails.jid) ? messageText : emptyString()
            growingTextViewHandler = GrowingTextViewHandler(textView: messageTextView ?? UITextView(), heightConstraint: messageTextViewHeight ?? NSLayoutConstraint())
            growingTextViewHandler?.minimumNumberOfLines = chatTextMinimumLines
            growingTextViewHandler?.maximumNumberOfLines = chatTextMaximumLines
            containerView.addSubview(chatTextViewXib!)
            //        chatTextViewXib?.translatesAutoresizingMaskIntoConstraints = true
            //        let guide = self.view.safeAreaLayoutGuide
            //        chatTextViewXib?.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
            //        chatTextViewXib?.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
            //        chatTextViewXib?.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
            //        chatTextViewXib?.layoutIfNeeded()
        }
        
    func getLastSeen() {
        if getProfileDetails.contactType == .deleted || getProfileDetails.isBlockedByAdmin || getBlocked() || getisBlockedMe() {
            lastSeenLabel.text = emptyString()
            lastSeenLabel.isHidden = true
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            ChatManager.getUserLastSeen(for: self.getProfileDetails?.jid ?? "") { isSuccess, flyError, flyData in
                var data  = flyData
                if isSuccess {
                    self.lastSeenLabel.isHidden = false
                    guard let lastSeenTime = data.getData() as? String else {
                        return
                    }
                    if (Int(lastSeenTime) == 0) {
                        self.lastSeenLabel.text = online.localized
                    } else {
                        self.setLastSeen(lastSeenTime: lastSeenTime)
                    }
                } else {
                    print(data.getMessage() as! String)
                    self.lastSeenLabel.isHidden = true
                }
            }
        })
    }
    
    func setLastSeen(lastSeenTime : String){
        let dateFormat = DateFormatter()
        dateFormat.timeStyle = .short
        dateFormat.dateStyle = .short
        dateFormat.doesRelativeDateFormatting = true
        let dateString = dateFormat.string(from: Date(timeIntervalSinceNow: TimeInterval(-(Int(lastSeenTime) ?? 0))))
        
        let timeDifference = "\(NSLocalizedString(lastSeen.localized, comment: "")) \(dateString)"
        let lastSeen = timeDifference.lowercased()
        lastSeenLabel.text = lastSeen
    }
        
        @objc func profileNotification(notification: Notification) {
            if  let jid = notification.userInfo?["jid"] {
                if jid as? String == getProfileDetails.jid {
                    if  let image =  notification.userInfo?["image"] as? String  {
                        getProfileDetails.image = image
                    }
                    if  let thumbImage =  notification.userInfo?["thumbImage"] as? String  {
                        getProfileDetails.thumbImage = thumbImage
                    }
                    if  let name =  notification.userInfo?["name"] as? String  {
                        getProfileDetails.name = name
                    }
                    if  let status =  notification.userInfo?["status"] as? String  {
                        getProfileDetails.status = status
                    }
                    setProfile()
                }
            }
        }
    }

// MARK - Text Delegate
extension ChatViewParentController : QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        var mediaLocalStoragePath = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[docCurrentIndexPath?.row ?? 0].mediaChatMessage?.mediaLocalStoragePath : starredMessages[docCurrentIndexPath?.row ?? 0].mediaChatMessage?.mediaLocalStoragePath : chatMessages[docCurrentIndexPath?.section ?? 0][docCurrentIndexPath?.row ?? 0].mediaChatMessage?.mediaLocalStoragePath
        
        let mediaLocalStorageUrl: URL? = URL(fileURLWithPath: mediaLocalStoragePath ?? "")
        guard let url = mediaLocalStorageUrl else {
            fatalError()
        }
        let preview = CustomPreviewItem(url: url, title: isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[docCurrentIndexPath?.row ?? 0].mediaChatMessage?.mediaFileName : starredMessages[docCurrentIndexPath?.row ?? 0].mediaChatMessage?.mediaFileName : chatMessages[docCurrentIndexPath?.section ?? 0][docCurrentIndexPath?.row ?? 0].mediaChatMessage?.mediaFileName)
        
        return preview
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.growingTextViewHandler?.resizeTextView(true)
        handleSendButton()
        self.resizeMessageTextView()
        if let isNotEmpty =  messageTextView?.text.isNotEmpty,  isNotEmpty {
            ChatManager.sendTypingStatus(to: getProfileDetails.jid, chatType: getProfileDetails.profileChatType)
        }
        if getProfileDetails.profileChatType == .groupChat && !isMention {
            messageTextView.textDidChange(textView)
        }
    }
    
    func resizeMessageTextView() {
        if isReplyViewOpen == true {
            textToolBarViewHeight?.constant = messageTextViewHeight!.constant + 5
            chatTextView?.frame.size.height = messageTextViewHeight!.constant
            tableViewBottomConstraint?.constant = textToolBarViewHeight!.constant + 5 + 80
            currentMessageTextViewHeight = messageTextViewHeight!.constant
            currentToolBarViewHeight = textToolBarViewHeight!.constant
        } else {
            textToolBarViewHeight?.constant = messageTextViewHeight!.constant + 5
            chatTextView?.frame.size.height = messageTextViewHeight!.constant
            tableViewBottomConstraint?.constant = textToolBarViewHeight!.constant + 5
            currentMessageTextViewHeight = messageTextViewHeight!.constant
            currentToolBarViewHeight = textToolBarViewHeight!.constant
            if isMessageEditing {
                CM.updateBaseviewPosition(height: (self.containerBottomConstraint.constant + (self.chatTextView?.bounds.height ?? 0) + 10))
            }
        }
    }
    
    func resetMessageTextView() {
        messageTextViewHeight?.constant = 40
        textToolBarViewHeight?.constant = messageTextViewHeight!.constant
        chatTextView?.frame.size.height = messageTextViewHeight!.constant
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        toolTipController.menuItems = []
        if messageTextView?.textColor == UIColor.lightGray {
            messageTextView?.textColor = UIColor.black
            chatTextView?.translatesAutoresizingMaskIntoConstraints = true
            chatTextView?.sizeToFit()
        }
        if getProfileDetails.profileChatType == .groupChat {
            if (textView.text.last == "@") {
                if !isMessageEditing {
                    mentionBaseView.isHidden = false
                    setGroupmention(range: textView.selectedRange)
                }
            }
        }
//        if let isNotEmpty =  messageTextView?.text.isNotEmpty,  isNotEmpty{
//            ChatManager.sendTypingStatus(to: getProfileDetails.jid, chatType: getProfileDetails.profileChatType)
//        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("textViewDidEndEditing")
        print("textViewDidEndEditing3", messageTextView.textViewEnd())
        toolTipController.menuItems = []
        ChatManager.sendTypingGoneStatus(to: getProfileDetails.jid, chatType: getProfileDetails.profileChatType)
        if isReplyViewOpen == false {
           // textToolBarViewHeight?.constant = CGFloat(chatBottomConstant)
           // tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
            tableViewBottomConstraint?.constant = textToolBarViewHeight!.constant + 5
            if chatMessages.count > 0 {
                guard let indexPath = chatTableView.indexPath(for: chatTableView), chatMessages[indexPath.section][indexPath.row].replyParentChatMessage != nil else { return }
                chatTableView.delegate?.tableView?(chatTableView, didSelectRowAt: indexPath)
            }
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.text.utf16.count > textView.selectedRange.location && isMention {
            textView.selectedRange = NSRange(location: (mentionRange.location+mentionRanges.count+1), length: 0)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print("shouldChangeTextIn \(range) text \(text) textCount \(text.count)" )
        if text.trim().utf16.count > 1 && !isMention {
            if let clipBoardStrings = UIPasteboard.general.strings, !clipBoardStrings.isEmpty, getProfileDetails.profileChatType == .groupChat {
                if "\(clipBoardStrings.joined(separator: " ").utf16)" != "\(text.trim().utf16)" {
                    if getProfileDetails.profileChatType == .groupChat {
                        self.mentionshouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
                    }
                    return true
                } else {
                    if clipBoardStrings.count == 2 {
                        messageTextView.convertAndInsert(to: clipBoardStrings, with: range)
                        UIPasteboard.general.strings = []
                        self.handleSendButton()
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                            let endPosition = self.messageTextView.endOfDocument
                            self.messageTextView.selectedTextRange = self.messageTextView.textRange(from: endPosition, to: endPosition)
                        })
                        return false
                    } else {
                        if getProfileDetails.profileChatType == .groupChat {
                            self.mentionshouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
                        }
                        return true
                    }
                }
            } else if let clipBoardStrings = UIPasteboard.general.strings, !clipBoardStrings.isEmpty, getProfileDetails.profileChatType == .singleChat {
                if "\(clipBoardStrings.joined(separator: " ").utf16)" != "\(text.trim().utf16)" {
                    if getProfileDetails.profileChatType == .groupChat {
                        self.mentionshouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
                    }
                    return true
                } else {
                        textView.insertText(clipBoardStrings[0].replacingOccurrences(of: "`", with: ""))
                    self.handleSendButton()
                    return false
                }
            }
            if getProfileDetails.profileChatType == .groupChat {
                self.mentionshouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
            }
            //return true
        }
        if getProfileDetails.profileChatType == .groupChat {
            self.mentionshouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.getHintsFromTextField), object: textView)
        self.perform(#selector(self.getHintsFromTextField), with: textView, afterDelay: 0.5)
        return true
    }
    
    @objc func getHintsFromTextField(textField: UITextView) {
        print("Hints for textField: \(textField.text ?? "")")
        ChatManager.sendTypingGoneStatus(to: getProfileDetails.jid, chatType: getProfileDetails.profileChatType)
    }
}

// MARK: - Audio functions
extension ChatViewParentController {
    
    func checkMicrophoneAccess(isOpenAudioFile: Bool) {
        // Check Microphone Authorization
        switch AVAudioSession.sharedInstance().recordPermission {
            
        case AVAudioSession.RecordPermission.granted:
            print(#function, " Microphone Permission Granted")
            isAudioRecordingGranted = isOpenAudioFile == true ? false : true
            startRecord(isOpenAudioFile: isOpenAudioFile)
            break
        case AVAudioSession.RecordPermission.denied:
            // Dismiss Keyboard (on UIView level, without reference to a specific text field)
            isAudioRecordingGranted = false
            return
            
        case AVAudioSession.RecordPermission.undetermined:
            print("Request permission here")
            executeOnMainThread { [weak self] in
                
                // Dismiss Keyboard (on UIView level, without reference to a specific text field)
                UIApplication.shared.sendAction(#selector(UIView.endEditing(_:)), to:nil, from:nil, for:nil)
                
                AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                    // Handle granted
                    if granted {
                        self?.startRecord(isOpenAudioFile: isOpenAudioFile)
                        print(#function, " Now Granted")
                    } else {
                        print("Pemission Not Granted")
                        
                    } // end else
                })
            }
            @unknown default:
                print("ERROR! Unknown Default. Check!")
            } // end switch
    }

    
    func stopPlayer(isBecomeBackGround: Bool) {
        stopDisplayLink()
        if let player = audioPlayer {
            if let path = currenAudioIndexPath {
                if let cell = chatTableView.cellForRow(at: path) as? AudioSender {
                    cell.playIcon?.image = UIImage(named: ImageConstant.ic_play)
                }
                else if let cell = chatTableView.cellForRow(at: path) as? AudioReceiver {
                    cell.playImage?.image = UIImage(named: ImageConstant.ic_play_dark)
                }
            
                if player.isPlaying {
                    player.stop()
                }
               
            }
        }
    }
    
    func stopDisplayLink() {
        updater?.invalidate()
        updater = nil
     }
    
    func audioPermission() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default,options: [.defaultToSpeaker,.allowBluetooth,.allowAirPlay])

            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
    }
    
    @objc func audioPlaySliderAction(sender: UISlider) {
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        
        if isStarredMessagePage == true {
            var chatMessage = isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row]
            chatMessage?.audioTrackTime = sender.value
        } else {
            chatMessages[section][row].audioTrackTime = sender.value
        }
        
        if let audioPlayer = audioPlayer {
            audioPlayer.currentTime = TimeInterval(sender.value)
        } else {
            audioPermission()
            audioPlayer?.currentTime = TimeInterval(sender.value)
        }
        
        if let cell = chatTableView.cellForRow(at: indexPath) as? AudioSender {
            cell.autioDuration?.text = FlyUtils.secondsToDurationInString(seconds: Double(sender.value ?? 0.0))
        } else if let cell = chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
            cell.audioDuration?.text = FlyUtils.secondsToDurationInString(seconds: Double(sender.value ?? 0.0))
        }
    }
    
    func playAudio(audioUrl: String) {
        if recorder.isRecording {
          handleAudioRecordMaximumTimeReached()
        }
        stopPlayer(isBecomeBackGround: false)
        if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
            let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Audio", isDirectory: true)
            let fileURL: URL = folderPath.appendingPathComponent(audioUrl)
            if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    audioPlayer = try? AVAudioPlayer(data: data as Data)
                } catch {
                    fatalError()
                }
                audioPlayer?.delegate = self
                updater = CADisplayLink(target: self, selector: #selector( trackAudio))
                updater.frameInterval = 1
                updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
                if isStarredMessagePage {
                    var messageCount = isStarredSearchEnabled == true ? starredSearchMessages?.count ?? 0 : starredMessages.count
                    if previousAudioIndexPath != currenAudioIndexPath {
                        if messageCount > 0 && previousAudioIndexPath?.row != -1 {
                            var messages = isStarredSearchEnabled == true ? starredSearchMessages : starredMessages
                            if messages?.count ?? 0 > previousAudioIndexPath?.row ?? 0 {
                                chatTableView.reloadRows(at: [previousAudioIndexPath ?? IndexPath(row: 0, section: 0)], with: .none)
                            }
                        }
                    }
                } else {
                    if previousAudioIndexPath != currenAudioIndexPath {
                        if chatMessages.count > 0 && previousAudioIndexPath?.section != -1 {
                            if chatMessages[previousAudioIndexPath?.section ?? 0].count > previousAudioIndexPath?.row ?? 0 {
                                chatTableView.reloadRows(at: [previousAudioIndexPath ?? IndexPath(row: 0, section: 0)], with: .none)
                            }
                        }
                    }
                }
                let time = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[currenAudioIndexPath?.row ?? 0].audioTrackTime : starredMessages[currenAudioIndexPath?.row ?? 0].audioTrackTime ?? 0.0 : chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime ?? 0.0

                audioPlayer?.currentTime = TimeInterval(time ?? 0.0)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                previousAudioIndexPath = currenAudioIndexPath ?? IndexPath()
                if let path = currenAudioIndexPath {
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[currenAudioIndexPath?.row ?? 0] : starredMessages[currenAudioIndexPath?.row ?? 0] : chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0]
                    if let cell = chatTableView.cellForRow(at: path) as? AudioSender {
                        cell.playIcon?.image = UIImage(named: ImageConstant.ic_audio_pause)
                        audioPlayingStatus(audioStatus: .playing, chatMessage: message)
                        cell.audioPlaySlider?.maximumValue = Float(audioPlayer?.duration ?? 0.0)
                    } else if let cell = chatTableView.cellForRow(at: path) as? AudioReceiver {
                        cell.playImage?.image = UIImage(named: ImageConstant.ic_audio_pause_gray)
                        audioPlayingStatus(audioStatus: .playing, chatMessage: message)
                        cell.slider?.maximumValue = Float(audioPlayer?.duration ?? 0.0)
                    }
                }
            }
        }
    }
    
    func startRecord(isOpenAudioFile: Bool) {
        openAudioFiles()
    }
    
    func openAudioFiles() {
        executeOnMainThread { [weak self] in
            if let weakSelf = self {
                let pickerViewController = UIDocumentPickerViewController(documentTypes: [(kUTTypeAudio as String)], in: .import)
                pickerViewController.delegate = self
                pickerViewController.allowsMultipleSelection = false
                weakSelf.present(
                    pickerViewController,
                    animated: true,
                    completion: nil
                )
            }
        }
    }
    
    @objc func trackAudio() {
        if let curnTime = audioPlayer?.currentTime {
            if let duration = audioPlayer?.duration {
                let normalizedTime = Float(curnTime * 100.0 / duration)
                let totalTimeString = FlyUtils.secondsToDurationInString(seconds: Double(curnTime))
                if let path = currenAudioIndexPath, isStarredMessagePage ? ( (isStarredSearchEnabled ?? false) ? ((starredSearchMessages ?? []).count > path.row) : starredMessages.count > path.row) : (chatMessages.count > path.section && chatMessages[path.section].count > path.row)  {
                    let chatTempMessage = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[currenAudioIndexPath?.row ?? 0] : starredMessages[currenAudioIndexPath?.row ?? 0] : chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0]
                    if let cell = chatTableView.cellForRow(at: path) as? AudioSender {
                        if chatTempMessage?.mediaChatMessage?.mediaFileName == currentAudioUrl {
                            cell.audioPlaySlider?.value = Float(audioPlayer?.currentTime ?? 0.0)
                            let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[currenAudioIndexPath?.row ?? 0] : starredMessages[currenAudioIndexPath?.row ?? 0] : chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0]
                            message?.audioTrackTime = Float(audioPlayer?.currentTime ?? 0.0)
                            audioPlayingStatus(audioStatus: .playing, chatMessage: message)
                            cell.autioDuration?.text = totalTimeString
                        }
                    } else if let cell = chatTableView.cellForRow(at: path) as? AudioReceiver {
                        if chatTempMessage?.mediaChatMessage?.mediaFileName == currentAudioUrl {
                            cell.slider?.value = Float(audioPlayer?.currentTime ?? 0.0)
                            chatTempMessage?.audioTrackTime = Float(audioPlayer?.currentTime ?? 0.0)
                            audioPlayingStatus(audioStatus: .playing, chatMessage: chatTempMessage)
                            cell.audioDuration?.text = totalTimeString
                        }
                    }
                }
            }
        }
    }
    
    private func audioPlayingStatus(audioStatus : AudioStatus, chatMessage : ChatMessage?) {
        guard let chatMessage = chatMessage else { return }
        chatMessage.audioStatus = audioStatus
    }

    func disableSendButton()  {
        sendButton?.isEnabled = false
    }
    
    func enableSendButton()  {
        sendButton?.isEnabled = true
    }
    
    func handleSendButton() {
        if ((messageTextView?.text.isBlank ?? false) || messageTextView?.text == startTyping.localized) {
            disableSendButton()
        } else {
            if isMessageEditing, let message = ChatManager.getMessageOfId(messageId: editMessageId) {
                var textContent = emptyString()
                if let media = message.mediaChatMessage {
                    textContent =  media.mediaCaptionText
                } else {
                    textContent =  message.messageTextContent
                }
                if let text = messageTextView?.text.trim(), Array(textContent.trim().utf16).elementsEqual(Array(text.utf16)) {
                    disableSendButton()
                } else {
                    enableSendButton()
                }
            } else {
                enableSendButton()
            }
        }
    }
    
    func stopAudioPlayer() {
        self.audioPlayer?.stop()
    }
}

// MARK - Text Delegate
extension ChatViewParentController {
    @IBAction func cancelButton(_ sender: Any) {
        audioImage.image = UIImage(named: ImageConstant.ic_audio_record)
        audioViewXib?.isHidden = true
    }
    
    @IBAction func audioSendButton(_ sender: Any) {
        audioViewXib?.isHidden = true
    }
    
    func sendAudio(fileUrl: URL, isRecorded : Bool) {
        handleAudioIndexPath()
        print("#loss sendAudio \(chatMessages.count)")
        let duration = FlyUtils.getMediaDuration(url: fileUrl) ?? 0
        resetUnreadMessages()
        if fileUrl.pathExtension == "mp3" || fileUrl.pathExtension == "aac" || fileUrl.pathExtension == "wav" || fileUrl.pathExtension == "m4a" {
            MediaUtils.processAudioFile(url: fileUrl) { isSuccess, fileName ,localPath, fileSize, duration, fileKey, errorMessage  in
                print("#media \(duration)")
                if let localPathURL = localPath, isSuccess{
                    var mediaData = MediaData()
                    mediaData.fileName = fileName
                    mediaData.fileURL = localPathURL
                    mediaData.fileSize = fileSize
                    mediaData.duration = duration
                    mediaData.fileKey = fileKey
                    mediaData.mediaType = .audio
                    DispatchQueue.main.async { [weak self] in
                        let audioParams = FileMessageParams(fileUrl: localPathURL, fileName: fileName,fileSize: fileSize, duration: duration, fileKey: fileKey)
                        FlyMessenger.sendMediaFileMessage(messageParams: FileMessage(toId: self?.getProfileDetails.jid ?? emptyString(), messageType: isRecorded == true ? .audioRecorded : .audio, fileMessage : audioParams, replyMessageId:  self?.replyMessageId ?? emptyString())) { [weak self] isSuccess,error,message in
                            if let chatMessage = message {
                                if let jid =  self?.getProfileDetails.jid {
                                    FlyMessenger.saveUnsentMessage(id: jid, message: emptyString())
                                }
                                self?.setLastMessage(messageId: chatMessage.messageId)
                                chatMessage.mediaChatMessage?.mediaUploadStatus = .uploading
                                self?.reloadList(message: chatMessage)
                                self?.replyMessageId = ""
                                self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                                if self?.replyJid == self?.getProfileDetails.jid {
                                    self?.replyMessageObj = nil
                                    self?.isReplyViewOpen = false
                                }
                            }
                            if !isSuccess{
                                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                            }
                        }
                    }
                } else {
                    AppAlert.shared.showToast(message: errorMessage)
                }
            }
        }
    }
    
    func sendDocumentMessage(fileURL: URL) {
        print("#loss sendDocumentMessage \(chatMessages.count)")
        resetUnreadMessages()
        MediaUtils.processDocumentFile(url: fileURL, maxSizeInMB: 2048.0) { isSuccess,localPath,fileSize,fileName,errorMessage in
            if !isSuccess {
                if !errorMessage.isEmpty {
                    AppAlert.shared.showToast(message: errorMessage)
                }
                return
            }
            if let localPathURL = localPath, isSuccess {
                DispatchQueue.main.async { [weak self] in
                    let documentParams = FileMessageParams(fileUrl: localPathURL, fileName: fileName)
                    FlyMessenger.sendMediaFileMessage(messageParams: FileMessage(toId: self?.getProfileDetails.jid ?? "", messageType: .document, fileMessage: documentParams, replyMessageId: self?.replyMessageId), sendMessageListener: {  [weak self] isSuccess, error, message in
                        if let chatMessage = message {
                            if let jid =  self?.getProfileDetails.jid {
                                FlyMessenger.saveUnsentMessage(id: jid, message: emptyString())
                            }
                            self?.setLastMessage(messageId: chatMessage.messageId)
                            chatMessage.mediaChatMessage?.mediaUploadStatus = .uploading
                            self?.reloadList(message: chatMessage)
                            self?.replyMessageId = ""
                            self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                            if self?.replyJid == self?.getProfileDetails.jid {
                                self?.replyMessageObj = nil
                                self?.isReplyViewOpen = false
                            }
                        }
                        
                        if !isSuccess{
                            let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                            AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                        }
                        executeOnMainThread {
                            UIView.performWithoutAnimation {
                                self?.chatTableView.reloadData()
                            }
                        }
                    })
                }
            } else {
                AppAlert.shared.showToast(message: FlyConstants.ErrorMessage.unSupportedFileFormate)
            }
        }
    }
    
    func startAudioRecord() {
        audioViewXib?.isHidden = false
        if isAudioRecordingGranted
        {
            startRecord(isOpenAudioFile: false)
        }else {
            checkMicrophoneAccess(isOpenAudioFile: false)
        }
    }
    
    func uploadFileMessage(uploadFileMessage: ChatMessage) {
        FlyMessenger.uploadFile(chatMessage: uploadFileMessage)
    }
}

// MARK: - Audio Delegates

extension ChatViewParentController:  UIDocumentPickerDelegate {
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        ChatManager.connect()
        if isDocumentOptionSelected == true {
            if controller.documentPickerMode == .import {
                sendDocumentMessage(fileURL: url)
                isDocumentOptionSelected = false
                print("selected file or document \(url)")
            }
            controller.dismiss(animated: true)
        } else {
            if getUserForAdminBlock() {
                return
            }
            let byteCountFormatter = ByteCountFormatter()
            let displaySize = byteCountFormatter.string(fromByteCount: Int64(url.fileSize))
            byteCountFormatter.countStyle = .file
            byteCountFormatter.allowedUnits = [.useMB]
            print("File Size: \(displaySize)")
            let convertBytesIntoMB = Float(displaySize.components(separatedBy: " ").first ?? "") ?? 0.0
            var audioFileInMbFormat : Float = convertBytesIntoMB
            
            // restrict MB format to convert again
            if displaySize.components(separatedBy: " ")[1] != "MB" {
                audioFileInMbFormat = (convertBytesIntoMB / 1024 / 1024)
            }
            
            // allow file only below 30MB
            // no limit for files
            if audioFileInMbFormat <= Float(2048) {
                if currenAudioIndexPath == nil {
                    currenAudioIndexPath = previousAudioIndexPath != nil ? previousAudioIndexPath : nil
                }
                if audioPlayer?.isPlaying == true {
                    if currenAudioIndexPath != nil {
                        if currenAudioIndexPath == IndexPath(row: 0, section: 0) {
                            previousAudioIndexPath = IndexPath(row: 1, section: 0)
                        }
                    }
                }
                if currenAudioIndexPath != nil {
                    let nextRow = (currenAudioIndexPath?.row ?? 0) + 1
                    let indexPath = IndexPath(row: nextRow, section: currenAudioIndexPath?.section ?? 0)
                    currenAudioIndexPath = indexPath
                }
                
                isShowAudioLoadingIcon = true
                sendAudio(fileUrl: url, isRecorded: false)
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.fileSizeLarge)
            }
        }
    }
    
    func markMessagessAsRead() {
        ChatManager.markConversationAsRead(for: [getProfileDetails.jid])
    }
}

extension ChatViewParentController: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlayer(isBecomeBackGround: false)
        if let path = currenAudioIndexPath {
            if let cell = chatTableView.cellForRow(at: path) as? AudioSender {
                cell.playIcon?.image = UIImage(named: ImageConstant.ic_play)
                cell.audioPlaySlider?.value = 0
                let totalTimeString = String(format: "%02d:%02d", 0, 0)
                cell.autioDuration?.text = totalTimeString
                let message = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[path.row] : starredMessages[path.row] : chatMessages[path.section][path.row]
                message?.audioTrackTime = 0
            } else if let cell = chatTableView.cellForRow(at: path) as? AudioReceiver {
                cell.slider?.value = 0
                let message = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[path.row] : starredMessages[path.row] : chatMessages[path.section][path.row]
                message?.audioTrackTime = 0
                let totalTimeString = String(format: "%02d:%02d", 0, 0)
                cell.audioDuration?.text = totalTimeString
                cell.playImage?.image = UIImage(named: ImageConstant.ic_play_dark)
            }
        }
    }
}

//MARK: - Actions
extension ChatViewParentController {
    @IBAction func onBackButton(_ sender: Any) {
        bottomSheet = nil
        if !bottomSheetOpened {
            navigate()
        }
    }

    private func navigate() {
        /// Need to check
        ///
        resetAudioRecording(isCancel: true)
        deleteUnreadNotificationFromDB()
        if isFromLocalPush {
            isFromLocalPush = false
            navigationController?.popToRootViewController(animated: true)
        }
        if isFromGroupInfo == true {
            chatMessages.removeAll()
            getAllMessages.removeAll()
            navigationController?.popToRootViewController(animated: true)
        } else {
            if let navController = navigationController {
                if chatMessages.count > 0 && currentPreviewIndexPath != nil && chatMessages.count >= currentPreviewIndexPath?.section ?? 0 {
                    if chatMessages[currentPreviewIndexPath?.section ?? 0].count > 0 {
                        if replyCloseButtonTapped == false && replyMessageObj != nil {
                            if replyJid == getProfileDetails.jid  {
                                replyMessagesDelegate?.replyMessageObj(message: chatMessages[currentPreviewIndexPath?.section ?? 0][currentPreviewIndexPath?.row ?? 0], jid: getProfileDetails.jid,messageText: messageTextView?.text ?? "")
                            }
                        } else {
                            replyMessagesDelegate?.replyMessageObj(message: nil, jid: "",messageText: messageTextView?.text ?? "")
                        }
                    }
                }
                chatMessages.removeAll()
                getAllMessages.removeAll()
                if isPopToRootVC == true && navController.viewControllers[0]  is MainTabBarController {
                    navController.popToRootViewController(animated: true)
                } else {
                    navController.popViewController(animated: true)
                }
            }
        }
    }
    
    func checkFromGroup() {
        if isFromGroupInfo == true {
            navigationController?.navigationBar.isHidden = true
            navigationController?.popViewController(animated: true)
        } else {
            navigationController?.navigationBar.isHidden = false
            navigationController?.popViewController(animated: true)
        }
    }
                        
    func showOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if availableFeatures.isImageAttachmentEnabled || availableFeatures.isVideoAttachmentEnabled{
            
            alert.addAction(UIAlertAction(title: camera, style: .default, handler: { [weak self] _ in
                self?.checkCameraPermissionAccess(sourceType: .camera)
            }))
            
            alert.addAction(UIAlertAction(title: gallery, style: .default, handler: { [weak self] _ in
                self?.checkForPhotoPermission()
            }))
        }
        
        if availableFeatures.isDocumentAttachmentEnabled {
            
            alert.addAction(UIAlertAction(title: "Document", style: .default, handler: { [weak self] _ in
                self?.isDocumentOptionSelected = true
                self?.openDocument()
            }))
        }
        
        if availableFeatures.isAudioAttachmentEnabled {
            
            alert.addAction(UIAlertAction(title: audio, style: .default, handler: {  [weak self] _ in
                self?.isDocumentOptionSelected = false
                self?.checkMicrophoneAccess(isOpenAudioFile: true)
            }))
            
        }
        
        if availableFeatures.isContactAttachmentEnabled {
            
            alert.addAction(UIAlertAction(title: contact, style: .default, handler: { [weak self] _ in
                self?.onContact()
            }))
        }
        
        if availableFeatures.isLocationAttachmentEnabled {
            
            alert.addAction(UIAlertAction(title: location, style: .default, handler: { [weak self] _ in
                self?.goToMap()
            }))
        }
        
        if availableFeatures.isImageAttachmentEnabled || availableFeatures.isVideoAttachmentEnabled ||  availableFeatures.isDocumentAttachmentEnabled || availableFeatures.isAudioAttachmentEnabled ||  availableFeatures.isContactAttachmentEnabled || availableFeatures.isLocationAttachmentEnabled {
            
            alert.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { (_) in
                
            }))
        }
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func goToMap() {
        if NetworkReachability.shared.isConnected {
            performSegue(withIdentifier: Identifiers.chatScreenToLocation, sender: nil)
        }
        else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    func openDocument() {
        executeOnMainThread { [self] in
            let documentPicker = UIDocumentPickerViewController(documentTypes: self.documentsSupportedTypes, in: .import)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            self.present(documentPicker, animated: true, completion: nil)
            ChatManager.disconnect()
        }
    }
    
    func checkPhotosPermissionForCamera() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            //handle authorized status
            checkMicPermission()
            break
        case .denied, .restricted :
            presentPhotosSettings()
            break
        case .notDetermined:
            // ask for permissions
            AppPermissions.shared.checkGalleryPermission {  [weak self] status in
                switch status {
                case .authorized:
                    self?.checkMicPermission()
                    break
                    // as above
                case .denied, .restricted:
                    self?.presentPhotosSettings()
                    break
                    // as above
                case .notDetermined: break
                    // won't happen but still
                    
                    
                case .limited: break
                    
                @unknown default: break
                    
                }
            }
            
            
        case .limited: break
            
        @unknown default: break
            
        }
    }
    
    func checkMicPermission() {
        AppPermissions.shared.checkMicroPhonePermission { [weak self] status in
            switch status {
            case .granted:
                executeOnMainThread {
                    self?.openCamera()
                }
                break
            case .denied, .undetermined:
                AppPermissions.shared.presentSettingsForPermission(permission: .microPhone, instance: self as Any)
                break
            default:
                AppPermissions.shared.presentSettingsForPermission(permission: .microPhone, instance: self as Any)
                break
            }
        }
    }
    
    func openCamera() {
        executeOnMainThread { [self] in
            
            let mediaTypes = availableFeatures.isImageAttachmentEnabled && availableFeatures.isVideoAttachmentEnabled ? ["public.image", "public.movie"] : availableFeatures.isImageAttachmentEnabled ? ["public.image"] : availableFeatures.isVideoAttachmentEnabled ? ["public.movie"] : ["public.image", "public.movie"]
            
            self.imagePicker =  UIImagePickerController()
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .camera
            self.imagePicker.videoMaximumDuration = TimeInterval(300)
            self.imagePicker.mediaTypes = mediaTypes
            present(self.imagePicker, animated: true, completion: nil)
        }
    }
    
    /**
     *  This function used to check camera Permission
     */
    func checkCameraPermissionAccess(sourceType: UIImagePickerController.SourceType) {
        let authorizationStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        CommonDefaults.permissionAlertShown = false
        switch authorizationStatus {
        case .denied:
            presentCameraSettings()
            break
        case .restricted:
            break
        case .authorized:
            checkPhotosPermissionForCamera()
            break
        case .notDetermined:
            CommonDefaults.permissionAlertShown = true
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                CommonDefaults.permissionAlertShown = false
                if granted {
                    print("Granted access to ")
                    self?.checkPhotosPermissionForCamera()
                } else {
                    print("Denied access to")
                    self?.presentCameraSettings()
                }
            }
            break
        @unknown default:
            print("Permission failed")
        }
    }
    
    func presentCameraSettings() {
        executeOnMainThread {
            let alert = UIAlertController(
                title: "",
                message: cameraAccessDenied.localized,
                preferredStyle: UIAlertController.Style.alert
            )
            
            alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: settings.localized, style: .default, handler: { (alert) -> Void in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    })
                    
                }
            }))
            
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    func checkForPhotoPermission(sender: UIButton? = nil) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            openGallery()
            break
        case .denied, .restricted :
            presentPhotosSettings()
            break
        case .notDetermined:
            // ask for permissions
            AppPermissions.shared.checkGalleryPermission {  [weak self] status in
                switch status {
                case .authorized:
                    self?.openGallery()
                    break
                    // as above
                case .denied, .restricted: break
                    // as above
                case .notDetermined: break
                    // won't happen but still
                    
                    
                case .limited: break
                    
                @unknown default: break
                    
                }
            }
            
            
        case .limited: break
            
        @unknown default: break
            
        }
    }
    func presentPhotosSettings() {
        executeOnMainThread {
            let alert = UIAlertController(
                title: "",
                message: libraryAccessDenied.localized,
                preferredStyle: UIAlertController.Style.alert
            )
            
            alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: settings.localized, style: .default, handler: { (alert) -> Void in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    })
                }
            }))
            
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    func openGallery() {
        
        let imagePicker = ImagePickerController(selectedAssets: selectedAssets ?? [])
        imagePicker.settings.theme.selectionStyle = .numbered
        imagePicker.settings.fetch.assets.supportedMediaTypes = availableFeatures.isImageAttachmentEnabled && availableFeatures.isVideoAttachmentEnabled ? [.image,.video] : availableFeatures.isImageAttachmentEnabled ? [.image] : availableFeatures.isVideoAttachmentEnabled ? [.video] : [.image,.video]
        imagePicker.settings.selection.max = 10
        imagePicker.settings.preview.enabled = true
        let options = imagePicker.settings.fetch.album.options
        imagePicker.settings.fetch.album.fetchResults = [
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options),
            PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options),
        ]
        presentImagePicker(imagePicker, select: { [weak self] (asset) in
            if let strongSelf = self {
                // User selected an asset. Do something with it. Perhaps begin processing/upload?
                if  let assetName = asset.value(forKey: "filename") as? String {
                    let fileExtension = URL(fileURLWithPath: assetName).pathExtension
                    if ChatUtils.checkImageFileFormat(format: fileExtension) {
                        var imageSize = ChatUtils.getImageSize(asset: asset)
                        imageSize = imageSize/(1024*1024)
                        print("image size: ",imageSize)
                        if imageSize >= Float(2048) {
                            AppAlert.shared.showToast(message: ErrorMessage.largeVideoFile)
                            imagePicker.deselect(asset: asset)
                        } else {
                            strongSelf.selectedAssets.append(asset)
                        }
                    } else if asset.mediaType == PHAssetMediaType.video {
                        if MediaUtils.isVideoLimit(asset: asset, videoLimit: 2048) {
                            strongSelf.selectedAssets.append(asset)
                        } else {
                            AppAlert.shared.showToast(message: ErrorMessage.largeVideoFile)
                            imagePicker.deselect(asset: asset)
                        }
                    } else {
                        AppAlert.shared.showToast(message: fileformat_NotSupport)
                        imagePicker.deselect(asset: asset)
                    }
                }
                if imagePicker.selectedAssets.count > 9 {
                    AppAlert.shared.showToast(message: ErrorMessage.restrictedMoreImages)
                }
            }
        }, deselect: { [weak self] (asset) in
            if let strongSelf = self {
                // User deselected an asset. Cancel whatever you did when asset was selected.
                strongSelf.selectedAssets.enumerated().forEach { index , element in
                    if element == asset {
                        strongSelf.selectedAssets.remove(at: index)
                    }
                }
            }
        }, cancel: { [weak self] (assets) in
            // User canceled selection.
            if let strongSelf = self {
                strongSelf.selectedAssets.removeAll()
            }
        }, finish: { [weak self] (assets) in
            // User finished selection assets.
            self?.moveToImageEdit(images: [], isPushVc: true)
        })
    }
    
    @IBAction func onReplyClear(_ sender: Any) {
        replyView.isHidden = true
        isReplyViewOpen = false
    }
    
    @IBAction func onSendButton(_ sender: Any) {
        messageTextView.textViewEnd()
        resetGroupMention()
        mentionBaseView.isHidden = true
        self.isMention = false
        var message = "", mentionedUsers:[String] = []
        if self.getProfileDetails.profileChatType == .groupChat {
            message = self.messageTextView?.mentionText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            mentionedUsers = self.messageTextView?.mentionedUsers ?? []
        } else {
            message = self.messageTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        if((messageTextView?.text.isBlank ?? false) || messageTextView?.text == startTyping.localized) {
            AppAlert.shared.showToast(message: emptyChatMessage.localized)
        }
        else {
            checkUserBusyStatusEnabled(self) { [weak self] status in
                executeOnMainThread {
                    if status {
                        if (!(self?.isMessageEditing ?? false)) {
                            self?.sendTextMessage(message: message, jid: self?.getProfileDetails.jid, mentionedUsersIds: mentionedUsers)
                            self?.resetMessageTextView()
                            self?.resetUnreadMessages()
                            self?.scrollToTableViewBottom()
                        } else {
                            self?.sendEditMessage(message: message, mentionedUsersIds: mentionedUsers)
                        }
                    }
                }
            }
        }
        messageTextView.resetMentionTextView()
    }
    
    func sendEditMessage(message: String, mentionedUsersIds: [String]) {
        if editMessageId.isEmpty { return }
        if editMessageType == .text || editMessageType == .autoText {
            let editMessageParams = EditMessage(messageId: editMessageId, editedTextContent: message, mentionedUsersIds: mentionedUsersIds)
            FlyMessenger.editTextMessage(editMessageParams: editMessageParams) { [weak self] isSuccess, error, textMessage in
                CM.closeMenu()
                if isSuccess {
                    if let indexPath = chatMessages.indices(where: {$0.messageId == textMessage?.messageId}), let message = textMessage {
                        self?.resetMessageTextView()
                        executeOnMainThread {
                            chatMessages[indexPath.section][indexPath.row] = message
                            self?.chatTableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                } else {
                    AppAlert.shared.showToastWithDuration(message: error?.description ?? "", duration: 4)
                }
            }
        } else if editMessageType == .image || editMessageType == .video {
            let editMessageParams = EditMessage(messageId: editMessageId, editedTextContent: message, mentionedUsersIds: mentionedUsersIds)
            FlyMessenger.editMediaCaption(editMessageParams: editMessageParams) { [weak self] isSuccess, error, chatMessage in
                CM.closeMenu()
                if isSuccess {
                    if let indexPath = chatMessages.indices(where: {$0.messageId == chatMessage?.messageId}), let message = chatMessage {
                        self?.resetMessageTextView()
                        executeOnMainThread {
                            chatMessages[indexPath.section][indexPath.row] = message
                            self?.chatTableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                } else {
                    AppAlert.shared.showToastWithDuration(message: error?.description ?? "", duration: 4)
                }
            }
        }
    }
    
    func sendImageMessage(mediaData : MediaData, mentionedUsersIds: [String], completionHandler :  @escaping (ChatMessage) -> Void) {
        print("#loss sendImageMessage \(chatMessages.count)")
        selectedIndexs.removeAll()
        view.endEditing(true)
        resetUnreadMessages()
            let mediaParams = FileMessageParams(fileUrl: mediaData.fileURL, fileName: mediaData.fileName,  caption : mediaData.caption, fileSize: mediaData.fileSize, duration: mediaData.duration, thumbImage: mediaData.base64Thumbnail, fileKey: mediaData.fileKey)
        FlyMessenger.sendMediaFileMessage(messageParams: FileMessage(toId: getProfileDetails.jid, messageType: .image, fileMessage : mediaParams, replyMessageId : replyMessageId, mentionedUsersIds: mentionedUsersIds)) { [weak self] isSuccess, error, sendMessage in
                if let chatMessage = sendMessage {
                    self?.setLastMessage(messageId: chatMessage.messageId)
                    chatMessage.mediaChatMessage?.mediaThumbImage =  mediaData.base64Thumbnail
                    if isSuccess == true {
                    chatMessage.mediaChatMessage?.mediaUploadStatus = .uploading
                    }
                    else {
                        chatMessage.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                    }
                    guard let msg = sendMessage else { return }
                    self?.reloadList(message: msg)
                    self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    if self?.replyJid == self?.getProfileDetails.jid {
                        self?.replyMessageObj = nil
                        self?.isReplyViewOpen = false
                    }
                
                }
            
            if !isSuccess{
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
                executeOnMainThread {
                    UIView.performWithoutAnimation {
                        self?.chatTableView.reloadData()
                    }

                }
               
                completionHandler(sendMessage!)
            }
    }
    
    func reloadList(message: ChatMessage) {
        print("#loss reloadList \(chatMessages.count)")
        if chatMessages.count == 0 {
           addNewGroupedMessage(messages: [message])
        } else {
            chatMessages[0].insert(message, at: 0)
            getAllMessages.append(message)
            chatTableView?.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            let indexPath = IndexPath(row: 0, section: 0)
            executeOnMainThread { [weak self] in
                self?.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
            }
            UIView.performWithoutAnimation {
                chatTableView.reloadData()
            }

            if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                if NetworkReachability.shared.isConnected {
                    cell.setImageCell(message)
                }
            }
            if !NetworkReachability.shared.isConnected {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }

    func moveToImageEdit(images: [ImageData],isPushVc: Bool) {
        
        if getUserForAdminBlock() {
            return
        }
        
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.imageEditController) as! ImageEditController
        controller.id = getProfileDetails.jid
        controller.imageAray = images
        controller.iscamera = false
        controller.delegate = self
        if messageTextView.mentionedUsers.isEmpty {
            controller.captionText = (messageTextView?.text != placeHolder) ? messageTextView?.text : ""
        } else {
            controller.captionText = (messageTextView?.text != placeHolder) ? messageTextView?.mentionText : ""
        }
        controller.textMentioned = messageTextView.mentionedUsers
        controller.selectedAssets = self.selectedAssets
        controller.profileName = getProfileDetails.name
        controller.groupMembers = groupMembers.filter({$0.memberJid != AppUtils.getMyJid()})
        controller.getProfileDetails = getProfileDetails
        navigationController?.navigationBar.isHidden = true
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @objc func quickForwardAction(sender: UIButton) {
        if isStarredMessagePage {
            return
        }
        if isShowForwardView == false {
            let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
            if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
                if selectedMessages?.filter({$0.chatMessage.messageId == chatMessages[indexPath.section][indexPath.row].messageId}).count == 0 {
                    var selectForwardMessage = SelectedMessages()
                    selectForwardMessage.isSelected = true
                    selectForwardMessage.chatMessage = chatMessages[indexPath.section][indexPath.row]
                    selectedMessages?.append(selectForwardMessage)
                }

                navicateToSelectForwardList(forwardMessages: selectedMessages ?? [], dismissClosure: dismisForwardAction)

            }
        }
    }
    func dismisForwardAction() {
        isShareMediaSelected = false
        isShowForwardView = false
        textToolBarView?.isHidden = false
        forwardBottomView?.isHidden = true
        selectedMessages?.removeAll()
        UIView.performWithoutAnimation {
            chatTableView.reloadData()
        }
        dismissKeyboard()
        showHideTextToolBarView()
    }

    override func dismissKeyboard() {
        containerBottomConstraint.constant = 0.0
        self.messageTextView?.resignFirstResponder()
    }
    
    @objc func forwardAction(sender: UIButton) {
        DispatchQueue.main.async { [weak self] in
            if self?.isShowForwardView == true {
                let indexPath = self?.getIndexPath(sender: sender)
                let row = indexPath?.row
                let section = indexPath?.section
                let selectedMessages = self?.selectedMessages
                self?.refreshBubbleImageView(indexPath: IndexPath(row: row ?? 0, section: section ?? 0) , isSelected: !(selectedMessages?.filter({$0.chatMessage.messageId == (self?.isStarredMessagePage == true ? self?.isStarredSearchEnabled == true ? self?.starredSearchMessages?[row ?? 0].messageId : self?.starredMessages[row ?? 0].messageId : chatMessages[section ?? 0][row ?? 0].messageId)}).first?.isSelected ?? false),title: self?.multipleSelectionTitle)
            }
        }
    }
    
    @objc func imageGestureAction(_ sender:AnyObject) {
        let buttonPostion = sender.view.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at: buttonPostion) {
            let message = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
            if message?.mediaChatMessage?.mediaUploadStatus == .uploaded || message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                view.endEditing(true)
                let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.imagePreview) as! ImagePreview
                controller.jid = message?.chatUserJid ?? ""
                controller.messageId = message?.messageId ?? ""
                controller.getProfileDetails = getProfileDetails
                controller.fetchMessageListQuery = fetchMessageListQuery
                self.refreshData = controller as RefreshMessagesDelegate
                controller.navigationController?.isNavigationBarHidden = false
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    @objc func audioAction(sender: UIButton){
        let buttonPostion =  sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at: buttonPostion) {
            if let player = audioPlayer {
                if player.isPlaying {
                    stopPlayer(isBecomeBackGround: false)
                }
            }
            let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
            if  let audioUrl = message?.mediaChatMessage?.mediaFileName {
                if message?.isMessageSentByMe == true {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? AudioSender {
                        if message?.isCarbonMessage == true {
                            switch message?.mediaChatMessage?.mediaDownloadStatus {
                            case .downloaded:
                                cell.playIcon?.isHidden = false
                                cell.playButton?.isHidden = false
                                audioPlayerSetup(indexPath: indexPath, audioUrl: audioUrl)
                            default:
                                break
                            }
                        } else {
                            switch message?.mediaChatMessage?.mediaUploadStatus {
                            case .not_uploaded:
                                if !NetworkReachability.shared.isConnected {
                                    AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
                                    return
                                }
                                cell.playButton?.tag = indexPath.row
                                cell.playButton?.addTarget(self, action: #selector(audioUpload(sender:)), for: .touchUpInside)
                            case .uploaded:
                                cell.playIcon?.isHidden = false
                                cell.playButton?.isHidden = false
                                audioPlayerSetup(indexPath: indexPath, audioUrl: audioUrl)
                            case .uploading:
                                message?.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                                FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { isSuccess in
                                    cell.playIcon?.isHidden = true
                                    cell.playButton?.isHidden = true
                                    cell.uploadCancel?.isHidden = false
                                    cell.updateCancelButton?.isHidden = false
                                    cell.uploadCancel?.image = UIImage(named: ImageConstant.ic_upload)
                                    cell.updateCancelButton?.tag = indexPath.row
                                    cell.nicoProgressBar?.isHidden = true
                                }
                        case .not_available:
                                if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded {
                                downloadUploadedAudio(sender: sender)
                            } else {
                                FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { isSuccess in
                                    cell.playIcon?.isHidden = true
                                    cell.playButton?.isHidden = true
                                    cell.uploadCancel?.isHidden = false
                                    cell.updateCancelButton?.isHidden = false
                                    cell.uploadCancel?.image = UIImage(named: ImageConstant.ic_download)
                                    cell.updateCancelButton?.tag = indexPath.row
                                    cell.nicoProgressBar?.isHidden = true
                                }
                            }
                            default:
                                break
                            }
                        }
                    }
                } else {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                        switch message?.mediaChatMessage?.mediaDownloadStatus {
                        case .downloaded:
                            audioPlayerSetup(indexPath: indexPath, audioUrl: audioUrl)
                        case .not_downloaded:
                            cell.download?.isHidden = false
                            uploadCancelaudioAction(sender: sender)
                        case .downloading:
                            cell.downloadButton?.isHidden = false
                            cell.playBtn?.isHidden = true
                            uploadCancelaudioAction(sender: sender)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
    
    func downloadUploadedAudio(sender: UIButton) {
        
        let indexPath = getIndexPath(sender: sender)
        
        if let message = isStarredMessagePage ? (isStarredSearchEnabled ?? false ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row]) : chatMessages[indexPath.section][indexPath.row] {
            FlyMessenger.downloadMedia(messageId: message.messageId) { (success, error, chatMessage) in
                //                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                //                    cell.getCellFor(message, at: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { (_) in
                //                    }, isShowForwardView: self?.isShowForwardView, isDeletedMessageSelected: self?.isDeleteSelected)
                //                }
            }
        }
    }
    
    func audioPlayerSetup(indexPath: IndexPath, audioUrl: String) {
        if let path = currenAudioIndexPath, indexPath == path {
            stopPlayer(isBecomeBackGround: false)
            previousAudioIndexPath = currenAudioIndexPath
            currenAudioIndexPath = nil
            currentAudioUrl = nil
            let message = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
            audioPlayingStatus(audioStatus: .stoped, chatMessage: message)
            print("test")
            stopDisplayLink()
        }else {
            currenAudioIndexPath = indexPath
            currentAudioUrl = audioUrl
            let message = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
            audioPlayingStatus(audioStatus: .playing, chatMessage: message)
            playAudio(audioUrl: audioUrl)
        }
    }
    
    @objc func longPressGesture(sender: UIGestureRecognizer) {
        isSelectOn = true
        print("longpressed")
        if chatTableView.isEditing {
            return
        }
        if sender.state == .began {
            print("UIGestureRecognizerStateBegan.")
            let touchPoint = sender.location(in: chatTableView)
            if let indexPath = chatTableView.indexPathForRow(at: touchPoint) {
                selectedIndexs.append(indexPath)
                chatTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
                didLongPressActionForIndexPath(index: indexPath, gestureView: sender)
            }
        }
    }
    
    func didLongPressActionForIndexPath(index: IndexPath, gestureView:UIGestureRecognizer) {
        print(index)
        guard gestureView.state == .began,
              let senderView = gestureView.view,
              let _ = gestureView.view?.superview
        else { return }
        
        senderView.becomeFirstResponder()
    }
    
    @IBAction func onAttachButton(_ sender: Any) {
        checkUserBusyStatusEnabled(self) { status in
            if status {
                executeOnMainThread { [weak self] in
                    self?.dismissKeyboard()
                    self?.resetGroupMention()
                    self?.mentionBaseView.isHidden = true
                    if !(self?.isMessageEditing ?? false) {
                        self?.showOptions()
                    } else {
                        CM.closeMenu()
                    }
                }
            }
        }
    }
    
    @IBAction func onReplyButton(_ sender: Any) {
        replyMessage(indexPath: previousIndexPath, isMessageDeleted: false, isKeyBoardEnabled: true, isSwipe: false)
    }

    @IBAction func onCopyButton(_ sender: Any) {
        let getMessage = chatMessages[previousIndexPath.section][previousIndexPath.row]
        let board = UIPasteboard.general
        board.string = getMessage.messageTextContent
        AppAlert.shared.showToast(message: "\(getMessage.messageTextContent) \(copyAlert.localized)")
    }
    
    @IBAction func onLongPressCloseButton(_ sender: Any) {
        headerView.isHidden = false
        longPressCount = 0
        isCellLongPressed = false
    }
    
    @IBAction func onDeleteButton(_ sender: Any) {
    }
    @IBAction func recordAudio(_ sender: Any) {
        messageTextView.resetMentionTextView()
        startAudioRecord()
    }

}

//MARK - segue
extension ChatViewParentController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        bottomSheet = nil
        if segue.identifier == Identifiers.chatScreenToLocation {
            let locationView = segue.destination as! LocationViewController
            if toViewLocation {
                locationView.latitude = mLatitude
                locationView.longitude = mLongitude
                locationView.isForView = toViewLocation
                toViewLocation = false
            }
            locationView.getProfileDetails = getProfileDetails
            locationView.fetchMessageListQuery = fetchMessageListQuery
            locationView.locationDelegate = self
        }
        else if segue.identifier == Identifiers.chatScreenToContact {
            let contactView = segue.destination as! ChatContactViewController
            contactView.contactDelegate = self
            contactView.getContactDetails =  contactDetails
        } else if segue.identifier == Identifiers.contactInfoViewController {
            let contcatInfo =  segue.destination as! ContactInfoViewController
            contcatInfo.contactJid = getProfileDetails.jid
            contcatInfo.getProfileDetails = getProfileDetails
            contcatInfo.fetchMessageListQuery = fetchMessageListQuery
            contcatInfo.delegate = self
            view.endEditing(true)
        } else if segue.identifier == Identifiers.groupInfoViewController {
            let contcatInfo =  segue.destination as! GroupInfoViewController
            contcatInfo.groupID = getProfileDetails.jid
            contcatInfo.currentGroupName = getProfileDetails.name
            contcatInfo.getProfileDetails = getProfileDetails
            contcatInfo.fetchMessageListQuery = fetchMessageListQuery
            contcatInfo.delegate = self
            contcatInfo.groupInfoDelegate = self
            view.endEditing(true)
        }
    }
}

//MARK: - DoubleTap Gesture Handling for Translation

extension ChatViewParentController {
    
    // MARK: - Getting the indexpath of the double tapped cell
    private func getIndexpathOfCellFromGesture (_ gesture:UIGestureRecognizer )-> IndexPath {
        
        let gestureTouchPoint = gesture.location(in: self.chatTableView)
        let indexpath = self.chatTableView.indexPathForRow(at: gestureTouchPoint)
        return indexpath!
    }

        @objc func translationLanguage(_ sender: UITapGestureRecognizer? = nil) {
            
            if !availableFeatures.isTranslationEnabled {
                AppAlert.shared.showAlert(view: self, title: "" , message: FlyConstants.ErrorMessage.forbidden, buttonTitle: "OK")
                return
            }
            
            guard NetworkReachability.shared.isConnected else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                return
            }
            var chatViewParentMessageCell = ChatViewParentMessageCell()
            var receiverImageCell = ReceiverImageCell()
            var chatViewVideoIncomingCell = ChatViewVideoIncomingCell()
            var queryString:String?
            guard let gesture = sender else {return }
            
            let indexPath = self.getIndexpathOfCellFromGesture(gesture)
            
            currentIndexPath = indexPath
            
            let message = chatMessages[indexPath.section][indexPath.row]
            print(message.messageTextContent)
            
            if message.messageType == .text || message.messageType == .autoText {
                
                if message.isMessageTranslated {
                    chatViewParentMessageCell = (self.chatTableView.cellForRow(at: indexPath) as? ChatViewParentMessageCell)!
                    queryString = (chatViewParentMessageCell.translatedTextLabel?.text)!
                } else {
                    chatViewParentMessageCell = (self.chatTableView.cellForRow(at: indexPath) as? ChatViewParentMessageCell)!
                    queryString = (chatViewParentMessageCell.messageLabel?.text)!
                }
            }
            
            if message.messageType == .image {
                if message.isMessageTranslated {
                    receiverImageCell = (self.chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell)!
                    queryString = receiverImageCell.translatedTextLabel?.text
                } else {
                    receiverImageCell = (self.chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell)!
                    queryString = receiverImageCell.caption.text
                }
            }
            
            if message.messageType == .video {
                if message.isMessageTranslated {
                    chatViewVideoIncomingCell = (self.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell)!
                    queryString = chatViewVideoIncomingCell.translatedCaptionLabel.text
                } else {
                    chatViewVideoIncomingCell = (self.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell)!
                    queryString = chatViewVideoIncomingCell.caption.text
                }
           
            }
            
            guard let queryString = queryString else {return}
            
            //MARK: - GoogleApi call for the translation
            FlyTranslationManager.shared.languageTransalation(jid: getProfileDetails.jid, messageId: message.messageId, QueryString: queryString, targetLanguageCode: CommonDefaults.targetLanguageCode, GooogleAPIKey: googleApiKey_Translation){ (translatedText,isSuccess,errorMessage) in
                if isSuccess{
                    print("translatedText-->", translatedText)
                } else
                {
                    print(errorMessage)
                }
            }
            
        }

}

//MARK: - Tableview
extension ChatViewParentController : UITableViewDataSource ,UITableViewDelegate,TableViewCellDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        if isStarredMessagePage {
            return starredMessages.count == 0 ? 0 : 1
        }
        return tableView == mentionTableView ? 1 : chatMessages.count
//        if chatMessages.isEmpty {
//            return 0
//        } else {
//            return chatMessages.count
//        }
    }
    
    func openBottomView(indexPath: IndexPath) {
        if getBlockedByAdmin() || getBlocked() {
            return
        }
        
        if getProfileDetails.profileChatType == .groupChat {
            if !isParticipantExist().doesExist {
                return
            }
        }
        isReplyViewClosed = false
        replyMessage(indexPath: indexPath, isMessageDeleted: false, isKeyBoardEnabled: true, isSwipe: true)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if isStarredMessagePage || tableView == mentionTableView {
            return nil
        }
        if chatMessages.count == 0 {
            return nil
        }
        if let firstMessageInSection = chatMessages[section].first {
            var timeStamp = 0.0
            if firstMessageInSection.messageChatType == .singleChat {
                timeStamp =  firstMessageInSection.messageSentTime
            } else {
                timeStamp = DateFormatterUtility.shared.getGroupMilliSeconds(milliSeconds: firstMessageInSection.messageSentTime)
            }
            
            let dateString = String().fetchMessageDateHeader(for: timeStamp)
            let label = ChatViewHeader()
            label.text = dateString
            let containerView = UIView()
            containerView.addSubview(label)
            print("#section #UI section \(section) \(dateString)")
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
            containerView.transform = CGAffineTransform(rotationAngle: -.pi)
            containerView.isUserInteractionEnabled = false
            return containerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if isStarredMessagePage || tableView == mentionTableView {
            return 0
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isStarredMessagePage {
            return (isStarredSearchEnabled == true ? starredSearchMessages?.count ?? 0 : starredMessages.count )
        }
        return tableView == mentionTableView ? searchGroupMembers.count : chatMessages[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView == mentionTableView ? 70 : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == mentionTableView, !searchGroupMembers.isEmpty  {
            let mentionCell = tableView.dequeueReusableCell(withIdentifier: "MentionTableViewCell", for: indexPath) as? MentionTableViewCell
            guard !searchGroupMembers.isEmpty else { return mentionCell ?? UITableViewCell() }
            if let profileDetail = searchGroupMembers[indexPath.row].profileDetail {
                if profileDetail.contactType == .deleted || profileDetail.isBlockedMe || profileDetail.isBlockedByAdmin || (IS_LIVE && ENABLE_CONTACT_SYNC && profileDetail.isItSavedContact == false) {
                    mentionCell?.userImageView?.image = UIImage(named: "ic_profile_placeholder") ?? UIImage()
                } else {
                    let imageUrl = profileDetail.thumbImage.isEmpty ? profileDetail.image : profileDetail.thumbImage
                    mentionCell?.userImageView.sd_setImage(with: ChatUtils.getUserImaeUrl(imageUrl: imageUrl),
                                                           placeholderImage: UIImage(named: "ic_profile_placeholder"))
                }
            }
            //if let profileDetail = searchGroupMembers[indexPath.row].profileDetail {
            mentionCell?.userNameLabel.text = searchGroupMembers[indexPath.row].displayName
            //}
            return mentionCell ?? UITableViewCell()
        } else if tableView == chatTableView {
            var cell : ChatViewParentMessageCell!
            //Handl
            guard isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?.count ?? 0 > 0 : starredMessages.count > 0 : chatMessages.count > 0 else { return UITableViewCell() }
            let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
            let  textReplyTap = UITapGestureRecognizer(target: self, action: #selector(self.replyViewTapGesture(_:)))
            if message?.isMessageRecalled == true && !isStarredMessagePage {
                if message?.isMessageSentByMe == true {
                    let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.deleteEveryOneCell, for: indexPath) as? DeleteForEveryOneViewCell
                    cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                    cell?.refreshDelegate = self
                    cell?.selectedForwardMessage = selectedMessages
                    if let view = cell?.forwardBubbleView, let image = cell?.forwardCheckBoxImage {
                        image.tag = 10023
                        view.tag = 10024
                    }
                    cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                    cell?.setDeleteForMeMessage(message: message!, isShowForwardMessage: isStarredMessageSelected ? false : isShowForwardView, isDeleteSelected: isDeleteSelected)
                    cell?.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell?.contentView ?? UIView())
                    cell?.backgroundColor = .clear
                    cell?.contentView.backgroundColor = .clear
                    return cell!
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.deleteEveryOneReceiverCell, for: indexPath) as? DeleteForEveryOneReceiverCell
                    cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                    cell?.refreshDelegate = self
                    if let view = cell?.forwardBubbleView, let image = cell?.forwardCheckBoxImage {
                        image.tag = 10023
                        view.tag = 10024
                    }
                    cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                    cell?.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell?.contentView ?? UIView())
                    cell?.selectedForwardMessage = selectedMessages
                    cell?.setDeleteForEveryOneMessage(message: message!, isShowForwardMessage: isStarredMessageSelected ? false : isShowForwardView, isDeleteSelected: isDeleteSelected)
                    if getProfileDetails.profileChatType == .groupChat {
                        if hideSenderNameToGroup(indexPath: indexPath) {
                            cell?.groupNameView?.isHidden = true
                            cell?.groupChatNameLabel?.text = ""
                            cell?.groupNameTopCons?.constant = 0
                            cell?.groupNameBottomCons?.constant = 0
                            cell?.groupChatNameLabel?.isHidden = true
                            cell?.groupNameViewHeightCons?.isActive = false
                            cell?.hideGroupNameViewCons?.isActive = true
                        } else {
                            cell?.groupNameView?.isHidden = false
                            cell?.groupChatNameLabel?.textColor = ChatUtils.getColorForUser(userName: message?.senderUserName)
                            cell?.groupChatNameLabel?.isHidden = false
                            cell?.groupNameTopCons?.constant = 8
                            cell?.groupNameBottomCons?.constant = 8
                            cell?.groupNameViewHeightCons?.isActive = true
                            cell?.hideGroupNameViewCons?.isActive = false
                        }
                    }
                    cell?.backgroundColor = .clear
                    cell?.contentView.backgroundColor = .clear
                    return cell!
                }
            }
            
            switch(message?.messageType) {
            case .text, .meet, .autoText:
                if(message?.isMessageSentByMe == true) {
                    cell = tableView.dequeueReusableCell(withIdentifier: (message?.messageType == .text || message?.messageType == .autoText) ? Identifiers.chatViewTextOutgoingCell : Identifiers.scheduledMeetingSenderCell, for: indexPath) as? ChatViewParentMessageCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell?.refreshDelegate = self
                    cell?.linkDelegate = self
                    cell.selectedForwardMessage = selectedMessages
                    cell.isStarredMessagePage = isStarredMessagePage
                    cell.searchText = searchBar?.text ?? ""
                    cell.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    
                    cell = cell?.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView, fromChat: true, isMessageSearch: messageSearchEnabled, searchText: isStarredMessagePage == true && isStarredSearchEnabled == true ? searchBar?.text ?? "" : messageSearchBar?.text ?? "", profileDetails: getProfileDetails)
                    cell.replyView?.addGestureRecognizer(textReplyTap)
                }
                else {
                    cell = tableView.dequeueReusableCell(withIdentifier: (message?.messageType == .text || message?.messageType == .autoText) ? Identifiers.chatViewTextIncomingCell : Identifiers.scheduledMeetingReceiverCell, for: indexPath) as? ChatViewParentMessageCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell?.refreshDelegate = self
                    cell?.linkDelegate = self
                    cell?.selectedForwardMessage = selectedMessages
                    cell?.isStarredMessagePage = isStarredMessagePage
                    cell.searchText = searchBar?.text ?? ""
                    cell?.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    
                    cell = cell?.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView, fromChat: true, isMessageSearch: messageSearchEnabled, searchText: isStarredMessagePage == true && isStarredSearchEnabled == true ? searchBar?.text ?? "" : messageSearchBar?.text ?? "", profileDetails: getProfileDetails)
                    cell.replyView?.addGestureRecognizer(textReplyTap)
                    
                    //MARK: - Adding Double Tap Gesture for the Incoming Messages
                    
                    if CommonDefaults.isTranlationEnabled {
                        let  tap = UITapGestureRecognizer(target: self, action: #selector(self.translationLanguage(_:)))
                        tap.numberOfTapsRequired = 2
                        cell.addGestureRecognizer(tap)
                    }
                    if !isStarredMessagePage {
                        if getProfileDetails.profileChatType == .groupChat {
                            if hideSenderNameToGroup(indexPath: indexPath) {
                                cell.hideGroupMsgNameView()
                                cell.baseViewTopConstraint.constant = 1
                            } else {
                                cell.groupMsgNameView?.isHidden = false
                                cell.groupMsgSenderName?.textColor = ChatUtils.getColorForUser(userName: message?.senderUserName)
                                cell.baseViewTopConstraint.constant = 3
                            }
                        }
                    } else {
                        cell.hideGroupMsgNameView()
                    }
                }
                
                if isShareMediaSelected == true && message?.messageTextContent.isURL == false && message?.messageType != .meet {
                    cell.forwardButton?.isHidden = true
                    cell.forwardView?.isHidden = true
                }
                cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                
                if let view = cell?.forwardView, let image = cell?.forwardImageView {
                    image.tag = 10023
                    view.tag = 10024
                }
                
                cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell?.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                configureGesture(view: cell?.contentView ?? UIView())
                cell?.refreshDelegate = self
                cell.delegate = self
                cell.selectionStyle = .none
                cell?.backgroundColor = .clear
                cell?.contentView.backgroundColor = .clear
                return cell
                
            case.location:
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onLocationMessage(sender:)))
                if(message?.isMessageSentByMe == true) {
                    cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewLocationOutgoingCell, for: indexPath) as? ChatViewParentMessageCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell.selectedForwardMessage = selectedMessages
                    cell.isStarredMessagePage = isStarredMessagePage
                    cell.showHideStarredMessageView()
                    cell.quickForwardButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView, fromChat: true, isMessageSearch: messageSearchEnabled, searchText: messageSearchBar?.text ?? "", profileDetails: getProfileDetails)
                    
                    cell.locationOutgoingView?.isUserInteractionEnabled = true
                    cell.locationOutgoingView?.addGestureRecognizer(gestureRecognizer)
                    cell?.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell?.contentView ?? UIView())
                }
                else {
                    cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewLocationIncomingCell, for: indexPath) as? ChatViewParentMessageCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell.selectedForwardMessage = selectedMessages
                    cell?.isStarredMessagePage = isStarredMessagePage
                    cell?.showHideStarredMessageView()
                    cell.quickForwardButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView, fromChat: true, isMessageSearch: messageSearchEnabled, searchText: messageSearchBar?.text ?? "", profileDetails: getProfileDetails)
                    if !isStarredMessagePage {
                        if getProfileDetails.profileChatType == .groupChat {
                            if hideSenderNameToGroup(indexPath: indexPath) {
                                cell.hideGroupMsgNameView()
                                cell.baseViewTopConstraint.constant = 1
                            } else {
                                cell.groupMsgNameView?.isHidden = false
                                cell.groupMsgSenderName?.textColor = ChatUtils.getColorForUser(userName: message?.senderUserName)
                                cell.baseViewTopConstraint.constant = 3
                                
                            }
                        } else {
                            cell.hideGroupMsgNameView()
                        }
                    }
                    cell.locationImageView?.addGestureRecognizer(gestureRecognizer)
                    cell.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell?.contentView ?? UIView())
                }
                
                if isShareMediaSelected == true{
                    cell.forwardButton?.isHidden = true
                    cell.forwardView?.isHidden = true
                }
                cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                if let view = cell?.forwardView, let image = cell?.forwardImageView {
                    image.tag = 10023
                    view.tag = 10024
                }
                cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell.delegate = self
                cell?.refreshDelegate = self
                cell.selectionStyle = .none
                cell?.backgroundColor = .clear
                cell?.contentView.backgroundColor = .clear
                cell?.replyView?.addGestureRecognizer(textReplyTap)
                return cell
                
            case .contact:
                if(message?.isMessageSentByMe == true) {
                    cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewContactOutgoingCell, for: indexPath) as? ChatViewParentMessageCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell.selectedForwardMessage = selectedMessages
                    cell.isStarredMessagePage = isStarredMessagePage
                    cell.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    
                    cell.contentView.tag = (indexPath.section * 1000) + indexPath.row
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView, fromChat: true, isMessageSearch: isStarredMessagePage ? isStarredSearchEnabled ?? false : messageSearchEnabled, searchText: isStarredMessagePage ? searchBar?.text ?? "" : messageSearchBar?.text ?? "", profileDetails: getProfileDetails)
                    cell.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell?.contentView ?? UIView())
                }
                else {
                    cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewContactIncomingCell, for: indexPath) as? ChatViewParentMessageCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell.selectedForwardMessage = selectedMessages
                    cell?.isStarredMessagePage = isStarredMessagePage
                    cell?.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView, fromChat: true, isMessageSearch: isStarredMessagePage ? isStarredSearchEnabled ?? false : messageSearchEnabled, searchText: isStarredMessagePage ? searchBar?.text ?? "" : messageSearchBar?.text ?? "", profileDetails: getProfileDetails)!
                    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onsaveContact(sender:)))
                    cell.saveContactButton?.addGestureRecognizer(gestureRecognizer)
                    cell.saveContactButton?.addGestureRecognizer(gestureRecognizer)
                    if !isStarredMessagePage {
                        if getProfileDetails.profileChatType == .groupChat {
                            if hideSenderNameToGroup(indexPath: indexPath) {
                                cell.hideGroupMsgNameView()
                                cell.baseViewTopConstraint.constant = 1
                            } else {
                                cell.groupMsgNameView?.isHidden = false
                                cell.groupMsgSenderName?.textColor = ChatUtils.getColorForUser(userName: message?.senderUserName)
                                cell.baseViewTopConstraint.constant = 3
                            }
                        }
                    } else {
                        cell.hideGroupMsgNameView()
                    }
                    cell.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell?.contentView ?? UIView())
                }
                
                if isShareMediaSelected == true{
                    cell.forwardButton?.isHidden = true
                    cell.forwardView?.isHidden = true
                }
                cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                if let view = cell?.forwardView, let image = cell?.forwardImageView {
                    image.tag = 10023
                    view.tag = 10024
                }
                cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell.quickForwardButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell?.refreshDelegate = self
                cell.selectionStyle = .none
                cell?.delegate = self
                cell?.backgroundColor = .clear
                cell?.contentView.backgroundColor = .clear
                cell?.replyView?.addGestureRecognizer(textReplyTap)
                return cell
                
            case .audio:
                if(message?.isMessageSentByMe == true) {
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.audioSender, for: indexPath) as? AudioSender
                    cell?.selectedForwardMessage = selectedMessages
                    cell?.isShowAudioLoadingIcon = isShowAudioLoadingIcon
                    cell?.isStarredMessagePage = isStarredMessagePage
                    cell?.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell?.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    cell = cell?.getCellFor(message, at: indexPath, isPlaying: currenAudioIndexPath == indexPath ? audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { [weak self] (sliderValue)  in
                        self?.forwardAudio(sliderValue: sliderValue,indexPath:indexPath)
                    }, isShowForwardView: isShowForwardView, isDeleteMessageSelected: isStarredMessageSelected ? true : isDeleteSelected, fromChat: true, isMessageSearch: messageSearchEnabled, searchText: messageSearchBar?.text ?? "")
                    cell?.audioPlaySlider?.value = Float((indexPath == currenAudioIndexPath) ? (audioPlayer?.currentTime ?? 0.0) : 0.0)
                    cell?.updateCancelButton?.tag = indexPath.row
                    cell?.playButton?.tag = indexPath.row
                    cell?.delegate = self
                    cell?.refreshDelegate = self
                    cell?.playButton?.addTarget(self, action: #selector(audioAction(sender:)), for: .touchUpInside)
                    cell?.updateCancelButton?.addTarget(self, action: #selector(uploadCancelaudioAction(sender:)), for: .touchUpInside)
                    cell?.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                    if let view = cell?.forwardView, let image = cell?.forwardImageView {
                        image.tag = 10023
                        view.tag = 10024
                    }
                    cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                    cell?.fwdBtn?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                    if let audioUrl = currentAudioUrl, audioUrl == message?.mediaChatMessage?.mediaFileName {
                        if let minuteSeconds = audioPlayer?.currentTime.minuteSecondMS {
                            cell?.autioDuration?.text = minuteSeconds
                            cell?.audioPlaySlider?.value = Float(audioPlayer?.currentTime ?? 0.0)
                            currenAudioIndexPath = indexPath
                        }
                    }
                    if let mediaFileName = message?.mediaChatMessage?.mediaFileName, let duration = ChatUtils.getAudiofileDuration(mediaFileName: mediaFileName){
                        cell?.audioPlaySlider?.maximumValue = Float(duration)
                    }
                    cell?.audioPlaySlider?.addTarget(self, action: #selector(audioPlaySliderAction(sender:)), for: .valueChanged)
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell?.selectionStyle = .none
                    cell?.backgroundColor = .clear
                    cell?.contentView.backgroundColor = .clear
                    cell?.replyView?.addGestureRecognizer(textReplyTap)
                    cell?.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell?.contentView ?? UIView())
                    return cell ?? UITableViewCell()
                } else {
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.audioReceiver, for: indexPath) as? AudioReceiver
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell?.selectedForwardMessage = selectedMessages
                    cell?.isStarredMessagePage = isStarredMessagePage
                    cell?.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell?.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    cell = cell?.getCellFor(message, at: indexPath, isPlaying: currenAudioIndexPath == indexPath ? audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { [weak self] (sliderValue)  in
                        self?.forwardAudio(sliderValue: sliderValue, indexPath: indexPath)
                    }, isShowForwardView: isShowForwardView, isDeletedMessageSelected: isStarredMessageSelected ? true : isDeleteSelected, fromChat: true, isMessageSearch: messageSearchEnabled, searchText: messageSearchBar?.text ?? "")!
                    cell?.slider?.value = Float((indexPath == currenAudioIndexPath) ? (audioPlayer?.currentTime ?? 0.0) : 0.0)
                    cell?.delegate = self
                    cell?.refreshDelegate = self
                    cell?.downloadButton?.addTarget(self, action:#selector(uploadCancelaudioAction(sender: )), for: .touchUpInside)
                    
                    cell?.playBtn?.addTarget(self, action: #selector(audioAction(sender:)), for: .touchUpInside)
                    cell?.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                    if let view = cell?.forwardView, let image = cell?.forwardImageView {
                        image.tag = 10023
                        view.tag = 10024
                    }
                    cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                    cell?.fwdBtn?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                    cell?.selectionStyle = .none
                    hideSenderNameToGroup(indexPath: indexPath)
                    if !isStarredMessagePage {
                        if getProfileDetails.profileChatType == .groupChat {
                            if hideSenderNameToGroup(indexPath: indexPath) {
                                cell?.hideSenderGroupName()
                                cell?.bubbleImageViewTopConstraint.constant = 1
                            } else {
                                cell?.senderNameContainer?.isHidden = false
                                cell?.senderNameLabel?.textColor = ChatUtils.getColorForUser(userName: message?.senderUserName)
                                cell?.bubbleImageViewTopConstraint.constant = 3
                            }
                        }
                    } else {
                        cell?.hideSenderGroupName()
                    }
                    if let audioUrl = currentAudioUrl, audioUrl == message?.mediaChatMessage?.mediaFileName {
                        if let minuteSeconds = audioPlayer?.currentTime.minuteSecondMS {
                            cell?.audioDuration?.text = FlyUtils.secondsToDurationInString(seconds: Double(audioPlayer?.currentTime ?? 0.0))
                            cell?.slider?.value = Float(audioPlayer?.currentTime ?? 0.0)
                            currenAudioIndexPath = indexPath
                        }
                    }
                    if let mediaFileName = message?.mediaChatMessage?.mediaFileName, let duration = ChatUtils.getAudiofileDuration(mediaFileName: mediaFileName){
                        cell?.slider?.maximumValue = Float(duration)
                    }
                    cell?.slider?.addTarget(self, action: #selector(audioPlaySliderAction(sender:)), for: .valueChanged)
                    cell?.contentView.backgroundColor = .clear
                    cell?.replyView?.addGestureRecognizer(textReplyTap)
                    cell?.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell?.contentView ?? UIView())
                    cell?.backgroundColor = .clear
                    cell?.contentView.backgroundColor = .clear
                    return cell ?? UITableViewCell()
                }
                
            case .image, .video:
                
                let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                print("count nnnn \(message) inexpath \(indexPath.row)")
                if indexPath.row == 0 {
                    print("las row")
                }
                
                if(message?.isMessageSentByMe == true) {
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.videoOutgoingCell, for: indexPath) as! ChatViewVideoOutgoingCell
                    cell.isFromBack = isFromBackground
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell.selectedForwardMessage = selectedMessages
                    cell.isStarredMessagePage = isStarredMessagePage
                    cell.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    print("#verify__ CELL \(message?.mediaChatMessage?.mediaUploadStatus)  (()))  \(message?.mediaChatMessage?.mediaProgressStatus)")
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    cell.downloadButton?.tag = (indexPath.section * 1000) + indexPath.row
//                    cell.downloadButton?.addTarget(self, action: #selector(uploadedMediaDownload(sender:)), for: .touchUpInside)
                    cell.imageContainer.tag = (indexPath.section * 1000) + indexPath.row
                    cell.playButton.tag = (indexPath.section * 1000) + indexPath.row
                    print("fileExists", FileManager.default.fileExists(atPath: message?.mediaChatMessage?.mediaLocalStoragePath ?? ""))
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView, isDeleteMessageSelected: isStarredMessageSelected == true ? true : isDeleteSelected, fromChat: true, isMessageSearch: isStarredMessagePage == true && isStarredSearchEnabled == true ? true : messageSearchEnabled, searchText: isStarredMessagePage == true && isStarredSearchEnabled == true ? searchBar?.text ?? "" :  messageSearchBar?.text ?? "", profileDetails: getProfileDetails)!
//                    cell.downloadButton?.addTarget(self, action: #selector(uploadedMediaDownload(sender:)), for: .touchUpInside)
                    cell.playButton.addTarget(self, action: #selector(playVideoGestureAction(sender:)), for: .touchUpInside)
                    cell.imageContainer?.tag = indexPath.row
                    cell.imageContainer?.isUserInteractionEnabled = (message?.messageType == .image) ? true : false
                    cell.imageGeasture.addTarget(self, action: #selector(imageGestureAction(_:)))
                    cell.cancelUploadButton.addTarget(self, action: #selector(cancelVideoUpload(sender:)), for: .touchUpInside)
                    cell.retryButton?.tag = (indexPath.section * 1000) + indexPath.row
                    cell.downloadButton?.tag = (indexPath.section * 1000) + indexPath.row
                    if message?.isCarbonMessage == true {
                        cell.downloadButton?.addTarget(self, action: #selector(videoDownload(sender:)), for: .touchUpInside)
                        cell.cancelUploadButton.addTarget(self, action: #selector(cancelVideoDownload(sender:)), for: .touchUpInside)
                    } else {
                        cell.cancelUploadButton.addTarget(self, action: #selector(cancelVideoUpload(sender:)), for: .touchUpInside)
                        cell.retryButton?.addTarget(self, action: #selector(retryVideoUpload(sender:)), for: .touchUpInside)
                    }
                    
                    
                    cell.quickFwdBtn?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                    
                    cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                    if let view = cell.forwardView, let image = cell.forwardImageView {
                        image.tag = 10023
                        view.tag = 10024
                    }
                    cell.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                    cell.delegate = self
                    cell.refreshDelegate = self
                    cell.selectionStyle = .none
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .clear
                    cell.replyView?.addGestureRecognizer(textReplyTap)
                    cell.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell.contentView)
                    return cell
                }else {
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.videoIncomingCell, for: indexPath) as! ChatViewVideoIncomingCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell.selectedForwardMessage = selectedMessages
                    cell.isStarredMessagePage = isStarredMessagePage
                    cell.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView, isDeleteMessageSelected: isStarredMessageSelected ? true : isDeleteSelected, fromChat: true, isMessageSearch: isStarredMessagePage == true && isStarredSearchEnabled == true ? true : messageSearchEnabled, searchText: isStarredSearchEnabled == true ? searchBar?.text ?? "" : messageSearchBar?.text ?? "", profileDetails: getProfileDetails)!
                    
                    //MARK: - Double tap gesture for VideoIncomingCel
                    if CommonDefaults.isTranlationEnabled {
                        let  tapVideoCaption = UITapGestureRecognizer(target: self, action: #selector(self.translationLanguage(_:)))
                        tapVideoCaption.numberOfTapsRequired = 2
                        cell.captionView.isUserInteractionEnabled = true
                        cell.captionView.addGestureRecognizer(tapVideoCaption)
                    }
                    cell.downloadButton.tag = (indexPath.section * 1000) + indexPath.row
                    cell.downloadButton.addTarget(self, action: #selector(videoDownload(sender:)), for: .touchUpInside)
                    cell.playButton.addTarget(self, action: #selector(playVideoGestureAction(sender:)), for: .touchUpInside)
                    cell.imageContainer?.tag = indexPath.row
                    cell.imageContainer?.isUserInteractionEnabled = (message?.messageType == .image) ? true : false
                    cell.imageGeasture.addTarget(self, action: #selector(imageGestureAction(_:)))
                    cell.progressButton.addTarget(self, action: #selector(cancelVideoDownload(sender:)), for: .touchUpInside)
                    cell.quickForwardButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                    
                    cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                    if let view = cell.forwardView, let image = cell.forwardImageView {
                        image.tag = 10023
                        view.tag = 10024
                    }
                    cell.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                    cell.delegate = self
                    cell.refreshDelegate = self
                    cell.selectionStyle = .none
                    if !isStarredMessagePage {
                        if getProfileDetails.profileChatType == .groupChat {
                            if hideSenderNameToGroup(indexPath: indexPath) {
                                cell.senderNameView.isHidden = true
                                cell.bubbleImageTopConstraint.constant = 1
                            } else {
                                cell.senderNameView.isHidden = false
                                cell.senderGroupNameLabel.textColor = ChatUtils.getColorForUser(userName: message?.senderUserName)
                                cell.bubbleImageTopConstraint.constant = 3
                            }
                        }
                    } else {
                        cell.senderNameView.isHidden = true
                    }
                    cell.replyView?.addGestureRecognizer(textReplyTap)
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .clear
                    cell.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell.contentView)
                    return cell
                }
                
            case .document:
                if(message?.isMessageSentByMe ==  true) {
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.senderDocumenCell,
                                                             for: indexPath) as! SenderDocumentsTableViewCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell.delegate = self
                    cell.refreshDelegate = self
                    cell.selectionStyle = .none
                    cell.contentView.backgroundColor = .clear
                    cell.selectedForwardMessage = selectedMessages
                    cell.isStarredMessagePage = isStarredMessagePage
                    cell.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                    cell.uploadButton?.tag = (indexPath.section * 1000) + indexPath.row
                    cell.viewDocumentButton?.tag = (indexPath.section * 1000) + indexPath.row
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView,isDeletedMessageSelected: (isStarredMessageSelected ?? false) ? true : isDeleteSelected, fromChat: true, isMessageSearch: isStarredMessagePage == true && isStarredSearchEnabled == true ? true : messageSearchEnabled, searchText: isStarredSearchEnabled == true ? searchBar?.text ?? "" :   messageSearchBar?.text ?? "")!
                    if let view = cell.forwardView, let image = cell.forwardImageView {
                        image.tag = 10023
                        view.tag = 10024
                    }
                    cell.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                    cell.uploadButton?.addTarget(self, action: #selector(uploadDownloadDocuments(sender: )), for: .touchUpInside)
                    cell.fwdButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                    cell.viewDocumentButton?.addTarget(self, action: #selector(viewDocument(sender:)), for: .touchUpInside)
                    cell.replyView?.addGestureRecognizer(textReplyTap)
                    cell.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .clear
                    configureGesture(view: cell.contentView)
                    return cell
                } else {
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.receiverDocumentCell,
                                                             for: indexPath) as! ReceiverDocumentsTableViewCell
                    if !isStarredMessagePage && !(isStarredSearchEnabled ?? false) {
                        cell.transform = CGAffineTransform(rotationAngle: -.pi)
                    }
                    cell.delegate = self
                    cell.refreshDelegate = self
                    cell.selectionStyle = .none
                    cell.contentView.backgroundColor = .clear
                    cell.selectedForwardMessage = selectedMessages
                    cell.isStarredMessagePage = isStarredMessagePage
                    cell.showHideStarredMessageView()
                    let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    if isStarredMessagePage {
                        cell.setUserProfileInfo(message: message, isBlocked: false)
                    }
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView,isDeletedOrStarredSelected: isStarredMessageSelected ? true : isDeleteSelected, fromChat: true, isMessageSearch: isStarredMessagePage == true && isStarredSearchEnabled == true ? true : messageSearchEnabled, searchText: isStarredSearchEnabled == true ? searchBar?.text ?? "" : messageSearchBar?.text ?? "")!
                    cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                    cell.downloadButton?.tag = (indexPath.section * 1000) + indexPath.row
                    
                    cell.viewDocumentButton?.tag = (indexPath.section * 1000) + indexPath.row
                    if let view = cell.forwardView, let image = cell.forwardImageView {
                        image.tag = 10023
                        view.tag = 10024
                    }
                    cell.viewDocumentButton?.tag = (indexPath.section * 1000) + indexPath.row
                    cell.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                    cell.downloadButton?.addTarget(self, action: #selector(uploadDownloadDocuments(sender:)), for: .touchUpInside)
                    cell.fwdButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                    cell.viewDocumentButton?.addTarget(self, action: #selector(viewDocument(sender:)), for: .touchUpInside)
                    if !isStarredMessagePage {
                        if getProfileDetails.profileChatType == .groupChat {
                            if hideSenderNameToGroup(indexPath: indexPath) {
                                cell.groupSenderNameView?.isHidden = true
                            } else {
                                cell.groupSenderNameView?.isHidden = false
                            }
                        }
                    } else {
                        cell.groupSenderNameView?.isHidden = true
                    }
                    cell.replyView?.addGestureRecognizer(textReplyTap)
                    cell.contentView.accessibilityIdentifier = "\(indexPath.section)_\(indexPath.row)"
                    configureGesture(view: cell.contentView)
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .clear
                    return cell
                }
                
            case .notification:
                if isStarredMessagePage {
                    return UITableViewCell()
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.notificationCell, for: indexPath) as! NotificationCell
                cell.transform = CGAffineTransform(rotationAngle: -.pi)
                var message = chatMessages[indexPath.section][indexPath.row].messageTextContent
                if chatMessages[indexPath.section][indexPath.row].messageId == getUnreadMessageId() {
                    print("#unreadcount 2 \(getUnreadMessageId())")
                    cell.notificationLabel.text = ChatManager.getMessageOfId(messageId: getUnreadMessageId())?.messageTextContent
                    cell.backgroundColor = Color.color_D6D6D6
                    cell.notificationLabel.textColor = Color.color_565656
                    cell.notificationLabel.backgroundColor = .clear
                    cell.background.backgroundColor = .clear
                } else {
                    cell.notificationLabel.text = message
                    cell.backgroundColor = .clear
                    cell.notificationLabel.textColor = Color.chatDateHeaderText
                    cell.background.backgroundColor = Color.chatDateHeaderBackground
                }
                cell.selectionStyle = .none
                cell.contentView.backgroundColor = .clear
                return cell
            @unknown default:
                break
            }
            return UITableViewCell()
        } else {
            return UITableViewCell()
        }
    }
    

    func updateSelectionColor(indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if let cell = self?.chatTableView.cellForRow(at: indexPath) {
                cell.contentView.backgroundColor = .clear
            }
            self?.scrollToTappedMessage = false
        }
    }
    
    func forwardAudio(sliderValue : Float,indexPath: IndexPath) {
        audioPlayer?.currentTime = TimeInterval(sliderValue)
        chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime = sliderValue
    }
    
    func checkforStar(selectedMessages :[SelectedMessages]) -> Bool {
        if selectedMessages.filter({$0.chatMessage.isMessageStarred == false}).count > 0 {
            return true
        } else {
            return false
        }
    }
    
    func openChat(index: Int) {
        let profile = isStarredSearchEnabled == true ? starredSearchMessages?[index] : starredMessages[index]
        let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
        let profileDetails = ProfileDetails(jid: profile?.chatUserJid ?? "")
        let getProfileDetails = ChatManager.profileDetaisFor(jid: profile?.chatUserJid ?? "")
        profileDetails.name = getProfileDetails?.name ?? ""
        profileDetails.nickName = getProfileDetails?.nickName ?? ""
        profileDetails.image = getProfileDetails?.image ?? ""
        profileDetails.profileChatType = getProfileDetails?.profileChatType ?? .singleChat
        if profile?.isDeletedUser ?? false {
            profileDetails.contactType = .deleted
        }else{
            profileDetails.contactType = getProfileDetails?.isItSavedContact == true ? .live : .unknown
        }
        profileDetails.isBlockedByAdmin = getProfileDetails?.isBlockedByAdmin ?? false
        vc?.getProfileDetails = profileDetails
        let color = getColor(userName: getProfileDetails?.name ?? "")
        vc?.contactColor = color
        vc?.replyMessageObj = replyMessageObj
        vc?.replyJid = replyJid
        vc?.ismarkMessagesAsRead = true
        vc?.selectedMessageId = profile?.messageId
        vc?.isStarredMessagePage = false
        vc?.navigationController?.modalPresentationStyle = .overFullScreen
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isStarredMessagePage {
            stopAudioPlayer()
            openChat(index: indexPath.row)
        }
        if tableView == mentionTableView {
            if let profileDetail = searchGroupMembers[indexPath.row].profileDetail, let Jid = searchGroupMembers[indexPath.row].profileDetail?.jid {
                if let userId = try? FlyUtils.getIdFromJid(jid: Jid) {
                    self.mentionDidSelect(userId: userId, profileDetail: profileDetail)
                }
            }
        }
    }
    
    func mentionDidSelect(userId: String, profileDetail: ProfileDetails) {
        let selected = FlyUtils.getGroupUserName(profile: profileDetail)

        if let lastRange = mentionRanges.last {
            messageTextView.text = messageTextView.text.replacing("", range: NSRange(location: mentionRange.location, length: ((lastRange.1.location+1) - mentionRange.location)))
        } else {
            messageTextView.text = messageTextView.text.replacing("", range: NSRange(location: mentionRange.location, length: 1))
        }
        messageTextView.insert(to: selected, with: mentionRange ,userId: userId)

        mentionBaseView.isHidden = true
        mentionRange = nil
        mentionSearch = ""
        self.isMention = false
        getGroupMember()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        chatTableView.deselectRow(at: indexPath, animated: true)
        if isCellLongPressed {
            isCellLongPressed = false
        }
    }
    
}


//// Location Sharing Methods

extension ChatViewParentController {
    @objc func onLocationMessage(sender: UIGestureRecognizer) {
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }
        guard let indexPath =  chatTableView.indexPathForRow(at: sender.location(in:  chatTableView)) else {
            return
        }
        
        print("indexPath.row: \(indexPath.row)")
        let message = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
        let selectedLatitude = message?.locationChatMessage?.latitude ?? 0
        let selectedLongitude = message?.locationChatMessage?.longitude ?? 0
        
        toViewLocation = true
        mLatitude = selectedLatitude
        mLongitude = selectedLongitude
        view.endEditing(true)
        goToMap()
    }
    
    @objc func onsaveContact(sender: UIGestureRecognizer) {
        guard let indexPath =  chatTableView.indexPathForRow(at: sender.location(in:  chatTableView)) else {
            return
        }
        
        print("indexPath.row: \(indexPath.row)")
       let message = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
        print("onsaveContact \(message?.contactChatMessage?.contactName) \(message?.contactChatMessage?.contactPhoneNumbers)")
        if let contactNumbers : [String] = message?.contactChatMessage?.contactPhoneNumbers as? [String] {
            redirectToContact(contactName: message?.contactChatMessage?.contactName ?? "", contactNumber:contactNumbers)
        }
    }
    
    func redirectToContact(contactName: String, contactNumber: [String]) {
        let newContact = CNMutableContact()
        contactNumber.forEach { contact in
            newContact.phoneNumbers.append(CNLabeledValue(label: "home", value: CNPhoneNumber(stringValue: contact)))
        }
        newContact.givenName = contactName
        let contactVC = CNContactViewController(forUnknownContact: newContact)
        contactVC.contactStore = CNContactStore()
        contactVC.delegate = self
        contactVC.allowsActions = false
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.tintColor = Color.primaryAppColor
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
    
    @objc func replyMessage(indexPath: IndexPath,isMessageDeleted: Bool,isKeyBoardEnabled: Bool,isSwipe: Bool) {
        dismissScheduleMeetPopup()
        self.view.isUserInteractionEnabled = true
        if isStarredMessagePage || getProfileDetails.isBlocked || getProfileDetails.isBlockedByAdmin {
            return
        }
        if messageSearchEnabled {
            hideMessageSearchView()
        }
        if !isShowForwardView {
            let messageStatus =  chatMessages[indexPath.section][indexPath.row].messageStatus
            if  (messageStatus == .delivered || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged) {
                if (longPressCount == 0 && !indexPath.isEmpty) {
                    if isSwipe == true {
                        currentPreviewIndexPath = indexPath
                    }
                    isReplyViewOpen = true
                    let message =  chatMessages[currentPreviewIndexPath?.section ?? 0][currentPreviewIndexPath?.row ?? 0]
                    let senderInfo = contactManager.getUserProfileDetails(for: message.senderUserJid)
                    message.isMessageDeleted = isMessageDeleted
                    replyMessageObj = message
                    replyJid = getProfileDetails.jid
//                    messageText = messageTextView?.text ?? ""
                    replyView.isHidden = false
                    replyCloseButtonTapped = false
                    replyMessageId = message.messageId
                    chatTextViewXib?.closeButton?.addTarget(self, action: #selector(closeButtontapped(sender:)), for: .touchUpInside)
                    chatTextViewXib?.setupUI()
                    chatTextViewXib?.setSenderReceiverMessage(message: message, contactType: senderInfo?.contactType ?? .unknown)
                    tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    tableViewBottomConstraint?.constant = (tableViewBottomConstraint?.constant ?? 0) + 40 + textToolBarViewHeight!.constant
                    if isKeyBoardEnabled == true {
                        messageTextView?.becomeFirstResponder()
                    }
                    chatTextViewXib?.setNeedsLayout()
                    chatTextViewXib?.layoutIfNeeded()
                }
            }
        }
    }
    
    @objc func closeButtontapped(sender: UIButton) {
        resetReplyView(resignFirstResponder: true)
        isReplyViewClosed = true
    }
    
    func resetReplyView(resignFirstResponder: Bool) {
        replyView.isHidden = true
        isReplyViewOpen = false
        longPressCount = 0
        isCellLongPressed = false
        
        if resignFirstResponder {
            messageTextView?.resignFirstResponder()
            replyMessageId = ""
            replyMessageObj = nil
            replyCloseButtonTapped = false
            if messageTextView.text != "" {
                messageText = messageTextView.text
            } else {
                messageText = ""
            }
        }
        tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
        tableViewBottomConstraint?.constant = textToolBarViewHeight!.constant + 5
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
    }
}

extension ChatViewParentController : UIImagePickerControllerDelegate, EditImageDelegate {
    
    func sendMedia(media: [MediaData]) {
        if getUserForAdminBlock() {
            return
        }
        media.forEach { item in
            if item.mediaType == .video {
                self.sendVideoMessage(mediaData: item, mentionedUsersIds: item.mentionedUsers) { chatMessage in }
            } else if item.mediaType == .image{
                self.sendImageMessage(mediaData: item, mentionedUsersIds: item.mentionedUsers) { chatMessage in }
            }
            
        }
        self.replyMessageId = ""
        self.messageTextView.text = ""
        self.containerBottomConstraint.constant = 0.0
    }
    
    
  func insertVideoAndImage(images: [ImageData],count: Int) {
      
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        switch mediaType {
        case kUTTypeImage:
            guard let selectedImage = info[.originalImage] as? UIImage else {
                return
            }

            if picker.sourceType == .camera {
                FlyUtils.saveImage(customFolder: FlyUtils.uploadedImageVideoAlbum, image: selectedImage, imageName: "") { status in
                    executeOnMainThread {
                        self.fetchCustomAlbumPhotos(albumName: FlyUtils.uploadedImageVideoAlbum)
                    }
                }
            } else {
                if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                    self.selectedAssets = [asset]
                    self.moveToImageEdit(images: [], isPushVc: false)
                }
                else {
                    UIImageWriteToSavedPhotosAlbum(selectedImage, self,#selector(image(_:didFinishSavingWithError:contextInfo:)),nil)
                }
            }

        case kUTTypeMovie:
            // Handle video selection result
            print("Selected media is video \(info.keys)")
            guard let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
                       //self.saveVideo(at: mediaURL)
            FlyUtils.saveVideo(customFolder: FlyUtils.uploadedImageVideoAlbum, videoFileUrl: mediaURL, completion: { [weak self] isSuccess in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                if let asset = fetchResult{
                    self?.selectedAssets = [asset]
                }
                DispatchQueue.main.async { [weak self] in
                    self?.moveToImageEdit(images: [], isPushVc: true)
                }
            })
            
        default:
            print("Mismatched type: \(mediaType)")
        }
    }

    func fetchCustomAlbumPhotos(albumName: String) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let firstObject = collection.firstObject {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions).lastObject
            if let asset = fetchResult {
                self.selectedAssets = [asset]
                self.moveToImageEdit(images: [], isPushVc: false)
            }
        }
    }
    
    private func saveVideo(at mediaUrl: URL) {
        FlyUtils.saveVideo(customFolder: FlyUtils.uploadedImageVideoAlbum, videoFileUrl: mediaUrl, completion: { isSuccess in
            let videoURL = mediaUrl
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { saved, error in
                if saved {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                    if let asset = fetchResult{
                        self.selectedAssets = [asset]
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.moveToImageEdit(images: [], isPushVc: true)
                    }
                }
            }
                
        })
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions).lastObject
            if let asset = fetchResult{
                self.selectedAssets = [asset]
            }
            self.moveToImageEdit(images: [], isPushVc: false)
        }
    }
}

extension ChatViewParentController  {
    
    override func onMessageTranslated(message: ChatMessage, jid: String) {
        chatMessages[currentIndexPath.section][currentIndexPath.row] = message
        self.chatTableView.reloadRows(at: [currentIndexPath], with: UITableView.RowAnimation.none)
    }
    
    override func onMessageReceived(message: ChatMessage, chatJid: String) {
        if !isStarredMessagePage {
            print("onMessageReceived  \(getProfileDetails.jid ?? "") = \(message.chatUserJid) \(message.isMessageSentByMe)")
            let toMardAsRead = (messageDelegate == nil)
            handleWhileRecevingMessage(message: message, chatJid: chatJid, markAsRead: toMardAsRead)
            processSearch(searchText: messageSearchBar?.text ?? "", searchUp: true)
        }
    }
    
    override func onMessageEdited(message: ChatMessage) {
        if let indexpath = chatMessages.indices(where: {$0.messageId == message.messageId}) {
            executeOnMainThread { [weak self] in
                if let getMessage = ChatManager.getMessageOfId(messageId: message.messageId) {
                    chatMessages[indexpath.section][indexpath.row] = getMessage
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.chatTableView.reloadRows(at: [indexpath], with: .automatic)
                    }
                }
            }
        }
    }
    
    func handleWhileRecevingMessage(message: ChatMessage, chatJid: String, markAsRead : Bool = true){
        handleAudioIndexPath()
        executeOnMainThread { [weak self] in
            if (self?.getProfileDetails.jid == message.chatUserJid){
                self?.selectedIndexs.removeAll()
                self?.removeUnreadMessageLabelFromChat()
                if AppUtils.getMyJid() != chatJid {
                    self?.appendNewMessage(message: message)
                } else if AppUtils.getMyJid() == chatJid && message.chatUserJid == self?.getProfileDetails.jid {
                    if self?.getProfileDetails.profileChatType == .singleChat {
                        self?.appendNewMessage(message: message)
                    } else if self?.getProfileDetails.profileChatType == .groupChat {
                        if !(self?.isMessageExist(messageId: message.messageId) ?? false) {
                            self?.appendNewMessage(message: message)
                        }
                    }
                }
            }
            executeOnMainThread { [weak self] in
                self?.chatTableView.reloadDataWithoutScroll()
            }
        }
    }
    
    private func handleAudioIndexPath() {
        if currenAudioIndexPath == nil {
            currenAudioIndexPath = previousAudioIndexPath != nil ? previousAudioIndexPath : nil
        }
        if audioPlayer?.isPlaying == true {
            if currenAudioIndexPath != nil {
                if currenAudioIndexPath == IndexPath(row: 0, section: 0) {
                    previousAudioIndexPath = IndexPath(row: 1, section: 0)
                }
            }
        }
        if currenAudioIndexPath != nil {
            let nextRow = (currenAudioIndexPath?.row ?? 0) + 1
            let indexPath = IndexPath(row: nextRow, section: currenAudioIndexPath?.section ?? 0)
            currenAudioIndexPath = indexPath
        }
    }
    
    override func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        print("#lag onMessageStatusUpdated \(messageId) \(chatJid) \(status)")

        if isStarredMessagePage {
            let message = isStarredSearchEnabled == true ? starredSearchMessages : starredMessages
            if let row = message?.firstIndex(where: {$0.messageId == messageId}) {
                message?[row].messageStatus = status
                chatTableView.reloadDataWithoutScroll()
            }
        } else {
            if getProfileDetails.jid != chatJid{
                return
            }

            if let indexpath = chatMessages.indices(where: {$0.messageId == messageId}) {
                if chatMessages.count > 0 {
                    if let message = ChatManager.getMessageOfId(messageId: messageId) {
                        executeOnMainThread{ [weak self] in
                            chatMessages[indexpath.section][indexpath.row] = message
                            self?.chatTableView.reloadRows(at: [indexpath], with: .none)
                        }
                    }
                }
            }
//            
//            if messageId == editMessageId && status == .acknowledged {
//                ChatManager.isMessageEditable(messageId: messageId, completionHandler: { isSuccess, error, data in
//                    if isSuccess {
//                       let menu = ContextMenuItemWithImage(title: MessageActions.edit.rawValue, image: UIImage(named: "icon-edit") ?? UIImage())
//                        CM.items.insert(menu, at: 0)
//                        CM.tableView.reloadData()
//                        if let indexpath = chatMessages.indices(where: {$0.messageId == messageId}), let cell = self.chatTableView.cellForRow(at: indexpath) {
//                                CM.updateTargetedImage(viewTargeted: cell)
//                        }
//                    }
//                })
//            }

            if let indexpath = chatMessages.indices(where: {$0.messageId == messageId}) {
                executeOnMainThread { [weak self] in
                    if chatMessages.count ?? 0 > 0 && chatMessages.count ?? 0 > indexpath.row {
                        if let cell = self?.chatTableView.cellForRow(at: indexpath) as? SenderImageCell {
                            if status == .acknowledged || status == .received || status == .delivered || status == .seen {
                                cell.uploadView?.isHidden = true
                                cell.progressView?.isHidden = true
                                cell.retryButton?.isHidden = true
                            } else if status == .sent {
                                cell.nicoProgressBar?.isHidden = false
                                cell.uploadView?.isHidden = true
                            }
                        }

                    }
                }
            }
        }
        
        messageDelegate?.whileUpdatingMessageStatus(messageId: messageId, chatJid: chatJid, status: status)
    }
    //
    override func onMediaStatusUpdated(message: ChatMessage) {
        print("#track onMediaStatusUpdated \(message.messageId) down : \(message.mediaChatMessage?.mediaDownloadStatus.description) up : \(message.mediaChatMessage?.mediaUploadStatus.description)")
            if let indexPath = isStarredMessagePage ? isStarredSearchEnabled == true ? IndexPath(row: starredSearchMessages?.firstIndex(where: {$0.messageId == message.messageId}) ?? 0, section: 0)  : IndexPath(row: starredMessages.firstIndex(where: {$0.messageId == message.messageId}) ?? 0, section: 0) : chatMessages.indexPath(where: {$0.messageId == message.messageId}), isValidIndex(row: indexPath.row, section: indexPath.section)  {
                let isCarbon = message.isMessageSentByMe && message.isCarbonMessage
                switch message.messageType {
                case .audio:
                    if isCarbon {
                        updateForCarbonAudio(message: message, index: indexPath)
                    } else {
                        updateForAudioStatus(message: message, index: indexPath)
                    }
                    break
                case .video, .image:
                    if isCarbon {
                        updateCarbonVideoAndImage(message: message, index: indexPath)
                    } else {
                        updateVideoAndImageStatus(message: message, index: indexPath)
                    }
                    break
                case .document:
                    if isCarbon {
                        updateCarbonDocument(message: message, index: indexPath)
                    } else {
                        updateDocumentStatus(message: message, index: indexPath)
                    }
                    break
                @unknown default:
                    break
                }
            }
        }
    
    override func onMediaStatusFailed(error: String, messageId: String, errorCode: Int) {
        var starredIndexPath: IndexPath? = nil
        starredIndexPath = isStarredSearchEnabled == true ? IndexPath(row: starredSearchMessages?.firstIndex(where: {$0.messageId == messageId}) ?? 0, section: 0) : IndexPath(row: starredMessages.firstIndex(where: {$0.messageId == messageId}) ?? 0, section: 0)
        if let indexPath = isStarredMessagePage ? starredIndexPath : chatMessages.indexPath(where: {$0.messageId == messageId}){
            print("onMediaStatusFailed \(error) \(messageId) \(indexPath)")
            guard let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row] else {
                return
            }
            if message.isMessageSentByMe {
                if isStarredMessagePage {
                    if isStarredSearchEnabled ?? false {
                        let uploadStatus = starredSearchMessages?[indexPath.row].mediaChatMessage?.mediaUploadStatus
                        starredSearchMessages?[indexPath.row].mediaChatMessage?.mediaUploadStatus = uploadStatus == .not_available ? .not_available : .failed
                    } else {
                        let uploadStatus = starredMessages[indexPath.row].mediaChatMessage?.mediaUploadStatus
                        starredMessages[indexPath.row].mediaChatMessage?.mediaUploadStatus = uploadStatus == .not_available ? .not_available : .failed
                    }
                } else {
                    let uploadStatus = chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaUploadStatus
                    chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaUploadStatus = uploadStatus == .not_available ? .not_available : .failed
                    if let index = getAllMessages.firstIndex(where: { $0.messageId == message.messageId }) {
                        let uploadStatus = getAllMessages[index].mediaChatMessage?.mediaUploadStatus
                        getAllMessages[index].mediaChatMessage?.mediaUploadStatus = uploadStatus == .not_available ? .not_available : .failed
                    }
                }
            } else {
                if isStarredMessagePage {
                    if isStarredSearchEnabled ?? false {
                        starredSearchMessages?[indexPath.row].mediaChatMessage?.mediaDownloadStatus = .failed
                    } else {
                        starredMessages[indexPath.row].mediaChatMessage?.mediaDownloadStatus = .failed
                    }
                } else {
                    chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus = .failed
                    if let index = getAllMessages.firstIndex(where: { $0.messageId == message.messageId }) {
                        getAllMessages[index].mediaChatMessage?.mediaDownloadStatus = .failed
                    }
                }
            }
            
            guard let updatedMessage = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row] else {
                return
            }
            
            switch updatedMessage.messageType {
            case .video, .image:
                onVideoAndImageUploadFailed(message: updatedMessage, indexPath: indexPath)
            case .audio:
                onAudioUploadFailed(message: updatedMessage, indexPath: indexPath)
            case .document:
                onDocumentUploadFailed(message: updatedMessage, indexPath: indexPath)
            default:
                break
            }
            if errorCode == 204 {
                AppAlert.shared.showToast(message: ErrorMessage.fileNoLongerExists)
            }
            self.chatTableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    override func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        print("#track onMediaProgressChanged \(message.messageId) down : \(message.mediaChatMessage!.mediaDownloadStatus.description) up : \(message.mediaChatMessage!.mediaUploadStatus.description) :: \(progressPercentage)")
        
        if let indexPath = isStarredMessagePage ? isStarredSearchEnabled == true ? IndexPath(row: starredSearchMessages?.firstIndex(where: {$0.messageId == message.messageId}) ?? 0, section: 0)  : IndexPath(row: starredMessages.firstIndex(where: {$0.messageId == message.messageId}) ?? 0, section: 0) : chatMessages.indexPath(where: {$0.messageId == message.messageId}), isValidIndex(row: indexPath.row, section: indexPath.section) {
            let progressMessage = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
            if progressMessage?.mediaChatMessage != nil {
                switch message.messageType {
                case .audio :
                    updateForAudioProgress(message: isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] ?? ChatMessage() : starredMessages[indexPath.row] : message, progressPercentage: progressPercentage, index: indexPath)
                case .video, .image:
                    updateVideoAndImageProgress(message: isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] ?? ChatMessage() : starredMessages[indexPath.row] : message, progressPercentage: progressPercentage, index: indexPath)
                case .document:
                    updateDocumentProgress(message: isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] ?? ChatMessage() : starredMessages[indexPath.row] : message, progressPercentage: progressPercentage, index: indexPath)
                default:
                    break
                }
            }
        }
    }
    
    func updateForImageWithCarbon(message: ChatMessage, index: IndexPath) {
        if message.isMessageSentByMe {
            chatMessages[index.section][index.row] = message
            if let cell = chatTableView.cellForRow(at: index) as? SenderImageCell {
                if let localPath = message.mediaChatMessage?.mediaFileName {
                    guard let directoryURL: URL = FlyUtils.getGroupContainerIDPath() else { return }
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                              let data = NSData(contentsOf: fileURL)
                          let image = UIImage(data: data! as Data)
                        cell.imageContainer?.image = image
                      }
                } else {
                    if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                    }
                }
                cell.getCellFor(message, at: index, isShowForwardView: isShowForwardView)
                if  (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message.mediaChatMessage?.mediaDownloadStatus == .failed   || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || isShowForwardView == true || message.messageStatus == .sent) {
                    cell.fwdView?.isHidden = true
                    cell.fwdButton?.isHidden = true
                } else {
                    cell.fwdView?.isHidden = false
                    cell.fwdButton?.isHidden = false
                }
            }
        }
    }
    
    func updateForImageStatus(message: ChatMessage, index: IndexPath) {
        if message.isMessageSentByMe {
            chatMessages[index.section][index.row] = message
            if let cell = chatTableView.cellForRow(at: index) as? SenderImageCell {
                if let localPath = message.mediaChatMessage?.mediaFileName {
                    guard let directoryURL: URL = FlyUtils.getGroupContainerIDPath() else { return }
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                              let data = NSData(contentsOf: fileURL)
                          let image = UIImage(data: data! as Data)
                        cell.imageContainer?.image = image
                      }
                } else {
                    if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                    }
                }

                if  (message.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message.mediaChatMessage?.mediaUploadStatus == .failed || message.mediaChatMessage?.mediaUploadStatus == .uploading || message.messageStatus == .notAcknowledged || isShowForwardView == true || message.messageStatus == .sent) {
                    cell.fwdView?.isHidden = true
                    cell.fwdButton?.isHidden = true
                } else {
                    cell.fwdView?.isHidden = false
                    cell.fwdButton?.isHidden = false
                }
                cell.getCellFor(message, at: index, isShowForwardView: isShowForwardView)
            }
            
        } else {
            chatMessages[index.section][index.row] = message
            if let cell = chatTableView.cellForRow(at: index) as? ReceiverImageCell {
                if let localPath = message.mediaChatMessage?.mediaFileName {
                    guard let directoryURL: URL = FlyUtils.getGroupContainerIDPath() else { return }
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                        let data = NSData(contentsOf: fileURL)
                        if let image = UIImage(data: data! as Data) {
                            // save image in local folder
                            let imageName = fileURL.lastPathComponent
                            cell.imageContainer?.image = image

                        }
                    }
                }else {
                    if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                }
                }
                
                if  (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message.mediaChatMessage?.mediaDownloadStatus == .failed  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || isShowForwardView == true) {
                    cell.fwdView?.isHidden = true
                    cell.fwdIcon?.isHidden = true
                } else {
                    cell.fwdView?.isHidden = false
                    cell.fwdIcon?.isHidden = false
                }
                
                cell.downloadView.isHidden = true
                cell.progressView.isHidden = true
                cell.downoadButton.isHidden = true
                cell.filseSize.text = ""
                cell.close.isHidden = true
            }
        }
    }
    
    func updateForAudioStatus(message: ChatMessage, index: IndexPath) {
        print("#uploadAUD updateForAudioStatus \(message.mediaChatMessage!.mediaFileName) \(message.mediaChatMessage!.mediaUploadStatus.description) \(message.mediaChatMessage!.mediaDownloadStatus.description)")
        if message.isMessageSentByMe {
            if let cell = chatTableView.cellForRow(at: index) as? AudioSender , let status = message.mediaChatMessage?.mediaUploadStatus {
                if isStarredMessagePage == true {
                    if isStarredSearchEnabled == true {
                        starredSearchMessages?[index.row] = message
                    } else {
                        starredMessages[index.row] = message
                    }
                } else {
                    chatMessages[index.section][index.row] = message
                }
                cell.uploadCancel?.image = status == .uploading  ? UIImage(named: ImageConstant.ic_audioUploadCancel) : UIImage(named: ImageConstant.ic_upload)
                cell.uploadCancel?.isHidden = status == .uploaded
                cell.updateCancelButton?.isHidden = false
                cell.playIcon?.isHidden = status != .uploaded
                cell.playButton?.isHidden = status != .uploaded
                cell.nicoProgressBar.isHidden = status != .uploading
                if status == .uploading && cell.nicoProgressBar.subviews.isEmpty{
                    cell.nicoProgressBar.addSubview(cell.newProgressBar)
                }
                cell.playButton?.addTarget(self, action: #selector(audioAction(sender:)), for: .touchUpInside)
                cell.newProgressBar.setProg(per: CGFloat(message.mediaChatMessage?.mediaProgressStatus ?? 0))
                cell.showHideForwardView(message: message, isShowForwardView: isShowForwardView, isDeleteMessageSelected: isDeleteSelected)
                if  (message.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message.mediaChatMessage?.mediaUploadStatus == .failed || message.mediaChatMessage?.mediaUploadStatus == .uploading || message.messageStatus == .notAcknowledged || isShowForwardView == true) {
                    cell.fwdViw?.isHidden = true
                    cell.fwdBtn?.isHidden = true
                } else {
                    cell.fwdViw?.isHidden = false
                    cell.fwdBtn?.isHidden = false
                }
                cell.message = message
            }
        }else{
            if let cell = chatTableView.cellForRow(at: index) as? AudioReceiver , let status = message.mediaChatMessage?.mediaDownloadStatus {
                if isStarredMessagePage == true {
                    if isStarredSearchEnabled == true {
                        starredSearchMessages?[index.row] = message
                    } else {
                        starredMessages[index.row] = message
                    }
                } else {
                    chatMessages[index.section][index.row] = message
                }
                cell.download?.image = status == .downloading ? UIImage(named: ImageConstant.ic_download_cancel) : UIImage(named: ImageConstant.ic_download)
                cell.download?.isHidden = status == .downloaded
                cell.playImage?.isHidden = status != .downloaded
                cell.playBtn?.isHidden = status != .downloaded
                cell.nicoProgressBar?.isHidden = status != .downloading
                if status == .downloading && cell.nicoProgressBar.subviews.isEmpty{
                    cell.nicoProgressBar.addSubview(cell.newProgressBar)
                }
                cell.newProgressBar.setProg(per: CGFloat(message.mediaChatMessage?.mediaProgressStatus ?? 0))
                cell.playBtn?.addTarget(self, action: #selector(audioAction(sender:)), for: .touchUpInside)
                cell.showHideForwardView(message: message, isShowForwardView: isShowForwardView, isDeletedMessageSelected: isDeleteSelected)
                if (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message.mediaChatMessage?.mediaDownloadStatus == .failed  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || isShowForwardView == true) {
                    cell.fwdViw?.isHidden = true
                    cell.fwdBtn?.isHidden = true
                } else {
                    cell.fwdViw?.isHidden = false
                    cell.fwdBtn?.isHidden = false
                }
                cell.message = message
                self.chatTableView.reloadRows(at: [index], with: .none)
            }
        }
    }
    
    func updateForCarbonAudio(message: ChatMessage, index: IndexPath) {
        if message.isMessageSentByMe && message.isCarbonMessage == true {
            if let cell = chatTableView.cellForRow(at: index) as? AudioSender {
                
                if (message.mediaChatMessage?.mediaDownloadStatus == .downloaded) {
                    chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .downloaded
                    chatMessages[index.section][index.row].mediaChatMessage?.mediaFileName = message.mediaChatMessage?.mediaFileName ?? ""
                    chatMessages[index.section][index.row].mediaChatMessage?.mediaLocalStoragePath = message.mediaChatMessage?.mediaLocalStoragePath ?? ""
                    cell.playButton?.isHidden = false
                    cell.playButton?.addTarget(self, action: #selector(audioAction(sender:)), for: .touchUpInside)
                    cell.updateCancelButton?.isHidden = true
                    cell.message = message
                }
                
                cell.uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                cell.playIcon?.isHidden = false
                cell.uploadCancel?.isHidden = true
                if  (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message.mediaChatMessage?.mediaDownloadStatus == .failed  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || isShowForwardView == true) {
                    cell.fwdViw?.isHidden = true
                    cell.fwdBtn?.isHidden = true
                    
                    if (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded) {
                        chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                    }
                } else {
                    cell.fwdViw?.isHidden = false
                    cell.fwdBtn?.isHidden = false
                }
                
               
                self.chatTableView.reloadRows(at: [index], with: .none)
            }
        }
    }
    
    func updateForImageProgress(message: ChatMessage, progressPercentage: Float, index: IndexPath) {
        if message.isMessageSentByMe {
            if let cell = chatTableView.cellForRow(at: index) as? SenderImageCell {
                if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                    cell.nicoProgressBar?.isHidden = false
                    cell.retryButton?.isHidden = false
                    cell.uploadView?.isHidden = true
                    cell.progressView?.isHidden = false
                }
            }
        } else if let cell = chatTableView.cellForRow(at: index) as? ReceiverImageCell {
                cell.downloadView.isHidden = true
                if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                }
                cell.progressBar?.isHidden = false
                cell.progressView.isHidden = false
                cell.downloadView?.isHidden = true
                cell.downoadButton?.isHidden = true
                cell.filseSize.text = ""
                cell.close.isHidden = false
            }
       }
    
    func updateForAudioProgress(message: ChatMessage, progressPercentage: Float, index: IndexPath) {
        print("progressPercentage", progressPercentage)
        print("#uploadAUD updateForAudioProgress \(progressPercentage) \(message.mediaChatMessage!.mediaFileName) \(message.mediaChatMessage!.mediaUploadStatus.description) \(message.mediaChatMessage!.mediaDownloadStatus.description)")
        if message.isMessageSentByMe {
            if let cell = chatTableView.cellForRow(at: index) as? AudioSender {
                cell.uploadCancel?.isHidden = false
                cell.uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                cell.playIcon?.isHidden = true
                cell.playButton?.isHidden = true
                cell.updateCancelButton?.isHidden = false
                cell.newProgressBar.setProg(per: CGFloat(progressPercentage))
                cell.nicoProgressBar?.isHidden = false

                if message.mediaChatMessage?.mediaUploadStatus == .uploading && isShowForwardView == true && progressPercentage < 100 {
                    cell.forwardView?.isHidden = true
                    cell.forwardLeadingCons?.constant = 0
                    cell.forwardButton?.isHidden = true
                }
            }
        }else{
            if let cell = chatTableView.cellForRow(at: index) as? AudioReceiver {
                cell.download?.image = UIImage(named: ImageConstant.ic_download_cancel)
                cell.nicoProgressBar?.isHidden = false
                cell.download?.isHidden = false
                cell.playImage?.isHidden = true
                cell.playBtn?.isHidden = true
                cell.downloadButton?.isHidden = false
                cell.newProgressBar.setProg(per: CGFloat(progressPercentage))
                if message.mediaChatMessage?.mediaDownloadStatus == .downloading && isShowForwardView == true && progressPercentage < 100 {
                    cell.forwardView?.isHidden = true
                    cell.forwardLeadingCons?.constant = 0
                    cell.bubbleLeadingCons?.constant = 0
                    cell.forwardButton?.isHidden = true
                }
            }
        }
    }
    
    func updateDocumentStatus(message: ChatMessage, index: IndexPath) {
        if message.isMessageSentByMe {
            if let cell = chatTableView.cellForRow(at: index) as? SenderDocumentsTableViewCell, let status =  message.mediaChatMessage?.mediaUploadStatus {
                if isStarredMessagePage == true {
                    if isStarredSearchEnabled == true {
                       starredSearchMessages?[index.row] = message
                    } else {
                        starredMessages[index.row] = message
                    }
                } else {
                    chatMessages[index.section][index.row] = message
                }
                cell.uploadCancelImage?.isHidden = status == .uploaded
                cell.uploadCancelImage?.image =  status == .uploading  ? UIImage(named: ImageConstant.ic_uploadCancel) : UIImage(named: ImageConstant.ic_upload)
                cell.nicoProgressBar?.isHidden = status != .uploading
                cell.uploadButton?.isHidden = status == .uploaded
                if status != .uploading{
                    cell.newProgressBar.removeFromSuperview()
                }else if cell.nicoProgressBar.subviews.isEmpty{
                    cell.nicoProgressBar.addSubview(cell.newProgressBar)
                }
                cell.newProgressBar.setProg(per: CGFloat(message.mediaChatMessage?.mediaProgressStatus ?? 0))
                if  (message.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message.mediaChatMessage?.mediaUploadStatus == .failed || message.mediaChatMessage?.mediaUploadStatus == .uploading || message.messageStatus == .notAcknowledged || message.messageStatus == .sent || isShowForwardView == true) {
                    cell.fwdButton?.isHidden = true
                    cell.forwardButton?.isHidden = true
                } else {
                    cell.fwdButton?.isHidden = false
                    cell.forwardButton?.isHidden = false
                }
                cell.viewDocumentButton?.isHidden = message.isCarbonMessage ? message.mediaChatMessage?.mediaDownloadStatus != .downloaded : message.mediaChatMessage?.mediaUploadStatus != .uploaded
                cell.message = message
            }
        } else {
            if let cell = chatTableView.cellForRow(at: index) as? ReceiverDocumentsTableViewCell , let status =  message.mediaChatMessage?.mediaDownloadStatus{
                if isStarredMessagePage == true {
                    if isStarredSearchEnabled == true {
                       starredSearchMessages?[index.row] = message
                    } else {
                       starredMessages[index.row] = message
                    }
                } else {
                    chatMessages[index.section][index.row] = message
                }
                cell.downloadImageView?.isHidden = status == .downloaded
                cell.downloadImageView?.image = status == .downloading ?  UIImage(named: ImageConstant.ic_download_cancel) : UIImage(named: ImageConstant.ic_download)
                if isStarredMessagePage {
                    if isStarredSearchEnabled == true {
                        starredSearchMessages?[index.row] = message
                    } else {
                        var messages = starredMessages
                        messages[index.row] = message
                    }
                } else {
                    chatMessages[index.section][index.row] = message
                }
                cell.downloadImageView?.isHidden = status == .downloaded
                cell.nicoProgressBar.isHidden = status != .downloading
                cell.downloadView?.isHidden = status == .downloading
                cell.nicoProgressBar?.isHidden = status != .downloading
                cell.downloadButton?.isHidden = status == .downloaded
                if status == .downloading{
                    if cell.nicoProgressBar.subviews.isEmpty{
                        cell.nicoProgressBar.addSubview(cell.newProgressBar)
                    }
                }else{
                    cell.newProgressBar.removeFromSuperview()
                }
                cell.newProgressBar.setProg(per: CGFloat(message.mediaChatMessage?.mediaProgressStatus ?? 0))
                if (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message.mediaChatMessage?.mediaDownloadStatus == .failed  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || message.messageStatus == .received || isShowForwardView == true) {
                    cell.fwdButton?.isHidden = true
                    cell.forwardButton?.isHidden = true
                } else {
                    cell.fwdButton?.isHidden = false
                    cell.forwardButton?.isHidden = false
                }
                if message.mediaChatMessage?.mediaDownloadStatus == .downloaded{
                    cell.viewDocumentButton?.isHidden = false
                    cell.viewDocumentButton?.addTarget(self, action: #selector(viewDocument(sender:)), for: .touchUpInside)
                    cell.forwardButton?.isHidden = true
                }
                cell.message = message
            }
        }
    }
    
    override func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        if isReplyViewOpen == true {
            messageIds.forEach { messageId in
                    chatMessages.enumerated().forEach { (section,message) in
                        message.enumerated().forEach { (row,msg) in
                            if currentPreviewIndexPath != nil {
                            if messageId == chatMessages[currentPreviewIndexPath?.section ?? 0][currentPreviewIndexPath?.row ?? 0].messageId {
                                replyMessage(indexPath: (currentPreviewIndexPath)!, isMessageDeleted: true, isKeyBoardEnabled: false, isSwipe: false)
                            }
                        }
                    }
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.stopLoading()
            self?.clearMessages()
        }
    }
    
    override func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        stopAudioPlayer()
        if isReplyViewOpen == true {
            messageIds.forEach { messageId in
                    chatMessages.enumerated().forEach { (section,message) in
                        message.enumerated().forEach { (row,msg) in
                            if currentPreviewIndexPath != nil {
                            if messageId == chatMessages[currentPreviewIndexPath?.section ?? 0][currentPreviewIndexPath?.row ?? 0].messageId {
                                replyMessage(indexPath: (currentPreviewIndexPath)!, isMessageDeleted: true, isKeyBoardEnabled: false, isSwipe: false)
                            }
                        }
                    }
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.refreshData?.refreshMessages(messageIds: messageIds)
            self?.stopLoading()
            self?.clearMessages()
        }
    }

    override func showOrUpdateOrCancelNotification() {
        super.showOrUpdateOrCancelNotification()
    }
    
    override func onMessagesCleared(toJid: String, deleteType: String?) {
        if deleteType == "0" {
            self.navigationController?.popViewController(animated: true)
        } else {
            if !isStarredMessagePage {
                if toJid == getProfileDetails.jid {
                    getInitialMessages()
                    executeOnMainThread { [weak self] in
                        UIView.performWithoutAnimation {
                            UIView.performWithoutAnimation {
                                self?.chatTableView.reloadData()
                            }
                        }
                    }
                    resetUnreadMessages()
                }
            } else {
                UIView.performWithoutAnimation {
                    UIView.performWithoutAnimation {
                        chatTableView.reloadData()
                    }
                }
            }
        }
    }
    
    override func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {
        executeOnMainThread { [weak self] in
            if self?.isStarredMessagePage ?? false {
                self?.showHideEmptyView()
                UIView.performWithoutAnimation {
                    UIView.performWithoutAnimation {
                        self?.chatTableView.reloadData()
                    }
                }
            }else{
                if let indexPath = chatMessages.indexPath(where: {$0.messageId == messageId}) {
                    chatMessages[indexPath.section][indexPath.row].isMessageStarred = favourite
                    self?.chatTableView.reloadRows(at: [indexPath], with: .none)
                }
            }
            
        }
    }
    
    override func clearAllConversationForSyncedDevice() {
        getInitialMessages()
        executeOnMainThread { [weak self] in
            UIView.performWithoutAnimation {
                UIView.performWithoutAnimation {
                    self?.chatTableView.reloadData()
                }
            }
        }
        resetUnreadMessages()
    }
}

extension Array where Element : Collection, Element.Index == Int {
    func indexPath(where predicate: (Element.Iterator.Element) -> Bool) -> IndexPath? {
        for (i, row) in  enumerated() {
            if let j = row.firstIndex(where: predicate) {
                return IndexPath(indexes: [i, j])
            }
        }
        return nil
    }
}

extension Array where Element : Collection, Element.Index == Int {
    func indices(where predicate: (Element.Iterator.Element) -> Bool) -> IndexPath? {
        for (i, row) in self.enumerated() {
            if let j = row.firstIndex(where: predicate) {
                return IndexPath(row: j, section: i)
            }
        }
        return nil
    }
}


//MARK - Send Messages
extension ChatViewParentController {
    func sendTextMessage(message: String,jid: String?, mentionedUsersIds: [String]) {
        var lastSection = 0
        if  chatMessages.count == 0 {
            lastSection = ( chatTableView?.numberOfSections ?? 0)
        }else {
            lastSection = ( chatTableView?.numberOfSections ?? 0) - 1
        }
        
        //Reply Message
        var getReplyId: String = ""
        if( isReplyViewOpen) {
            getReplyId =  replyMessageId
            isReplyViewOpen = false
        }
        let messageParams = TextMessage(toId:  getProfileDetails.jid, messageText: message, replyMessageId: getReplyId, mentionedUsersIds: mentionedUsersIds)
        FlyMessenger.sendTextMessage(messageParams: messageParams) { [weak self] isSuccess, error, textMessage in
            guard let self else {return}
                if isSuccess {
                    print("loss SendText.........")
                    if chatMessages.count == 0 {
                        if let message = textMessage {
                            self.setLastMessage(messageId: message.messageId)
                            self.addNewGroupedMessage(messages: [message])
                        }
                    } else {
                        if let message = textMessage {
                            self.setLastMessage(messageId: message.messageId)
                            if let firstMessageInSection = chatMessages[0].first {
                                
                                var timeStamp = 0.0
                                if firstMessageInSection.messageChatType == .singleChat {
                                    timeStamp =  firstMessageInSection.messageSentTime
                                } else {
                                    timeStamp = DateFormatterUtility.shared.getGroupMilliSeconds(milliSeconds: firstMessageInSection.messageSentTime)
                                }
                                if String().fetchMessageDateHeader(for: timeStamp) == "TODAY" {
                                    chatMessages[0].insert(message, at: 0)
                                    self.chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .right)
                                    let indexPath = IndexPath(row: 0, section: 0)
                                    self.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
                                    self.chatTableView.reloadDataWithoutScroll()
                                    self.scrollToTableViewBottom()
                                } else {
                                    let (indexPa, shouldPaginate) = self.checkReplyMessageAvailability(replyMessageId: message.messageId)
                                    if let scrollToRow = indexPa {
                                        self.scrollLogic(indexPath: scrollToRow)
                                    } else if shouldPaginate{
                                        self.fetchMessageListParams.messageId = emptyString()
                                        self.queryInitialMessage(shouldScrollToMessage: true)
                                    }
                                }
                            }
                            self.messageTextView?.text = ""
                            self.replyMessageId = ""
                            self.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                            self.handleSendButton()
                            if self.replyJid == self.getProfileDetails.jid {
                                self.replyMessageObj = nil
                                self.isReplyViewOpen = false
                            }
                        }
                    }
                }
        }
    }
    
    func onContact() {
        requestContactAccess()
    }
}

//MARK - Contacts Delegate
extension ChatViewParentController: ContactDelegate {
    func didSendPressed(contactDetails: ContactDetails,jid: String?) {
        
        if getUserForAdminBlock() {
            return
        }
        
        var lastSection = 0
        if  chatMessages.count == 0 {
            lastSection = ( chatTableView?.numberOfSections ?? 0)
        }else {
            lastSection = ( chatTableView?.numberOfSections ?? 0) - 1
        }
        
        print("didSendPressed \(contactDetails.contactName)  \(contactDetails.contactNumber)")
        let messageParams = FileMessage(toId: getProfileDetails.jid, messageType: .contact, contactMessage: ContactMessageParams(name: contactDetails.contactName, numbers: contactDetails.contactNumber), replyMessageId: replyMessageId)
        FlyMessenger.sendMediaFileMessage(messageParams: messageParams){ [weak self] isSuccess,error,message  in
            if isSuccess {
                if let jid =  self?.getProfileDetails.jid {
                    FlyMessenger.saveUnsentMessage(id: jid, message: emptyString())
                }
                self?.setLastMessage(messageId: message!.messageId)
                self?.view.endEditing(true)
                if  chatMessages.count == 0 {
                    self?.addNewGroupedMessage(messages: [message!])
                }else{
                    chatMessages[0].insert(message!, at: 0)
                    self?.chatTableView?.beginUpdates()
                    self?.chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .none)
                    self?.chatTableView?.endUpdates()
                    let indexPath = IndexPath(row: 0, section: 0)
                    self?.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
                    self?.messageTextView?.text = ""
                    self?.replyMessageId = ""
                    self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    if self?.replyJid == self?.getProfileDetails.jid {
                        self?.replyMessageObj = nil
                        self?.isReplyViewOpen = false
                    }
                }
            }
            else {
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
        }
    }
}

//MARK - Location Delegate
extension ChatViewParentController: LocationDelegate {
    func didSendPressed(latitude: Double, longitude: Double,jid: String?) {
        
        if getUserForAdminBlock() {
            return
        }
        
        var lastSection = 0
        if  chatMessages.count == 0 {
            lastSection = ( chatTableView?.numberOfSections ?? 0)
        }else {
            lastSection = ( chatTableView?.numberOfSections ?? 0) - 1
        }
        let messageParams = FileMessage(toId: getProfileDetails.jid, messageType: .location, locationMessage: LocationMessageParams(latitude: latitude, longitude: longitude), replyMessageId: replyMessageId)
        FlyMessenger.sendMediaFileMessage(messageParams: messageParams){ [weak self]isSuccess,error,message in
            if isSuccess {
                if let jid =  self?.getProfileDetails.jid {
                    FlyMessenger.saveUnsentMessage(id: jid, message: emptyString())
                }
                self?.setLastMessage(messageId: message!.messageId)
                self?.view.endEditing(true)
                if chatMessages.count == 0 {
                    self?.addNewGroupedMessage(messages: [message!])
                }else{
                    chatMessages[0].insert(message!, at: 0)
                    self?.chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .none)
                    let indexPath = IndexPath(row: 0, section: 0)
                    self?.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
                    self?.messageTextView?.text = ""
                    self?.replyMessageId = ""
                    self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    self?.dismissKeyboard()
                    if self?.replyJid == self?.getProfileDetails.jid {
                        self?.replyMessageObj = nil
                        self?.isReplyViewOpen = false
                    }
                }
            }
            else {
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
        }
    }
}

extension ChatViewParentController : ConnectionEventDelegate {
    func onConnectionFailed(error: FlyError) {
        
    }
    
    func onReconnecting() {
        
    }
    
    func onConnected() {
        self.getLastSeen()
        markMessagessAsRead()
        print("ChatViewParentController ConnectionEventDelegate onConnected")
    }
    func onDisconnected() {
        print("ChatViewParentController ConnectionEventDelegate onDisconnected")
    }
    
}

extension ChatViewParentController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {
        print("ChatViewParentController ProfileEventsDelegate userCameOnline \(jid)")
        if !isStarredMessagePage {
            if jid ==  getProfileDetails.jid && getProfileDetails.contactType != .deleted {
                lastSeenLabel.isHidden = false
                lastSeenLabel.text = online.localized
            }
            else if getProfileDetails.contactType == .deleted   {
                if jid ==  getProfileDetails.jid{
                    lastSeenLabel.isHidden = true
                }
            }
        }
    }
    
    func userWentOffline(for jid: String) {
        print("ChatViewParentController ProfileEventsDelegate userWentOffline \(jid)")
        if !isStarredMessagePage {
            if jid ==  getProfileDetails.jid {
                getLastSeen()
                //setLastSeen(lastSeenTime: "0")
            }
        }
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        if !isStarredMessagePage {
            if let profile = ChatManager.profileDetaisFor(jid : getProfileDetails.jid) {
                self.getProfileDetails = profile
                setProfile()
                checkUserBlockedByAdmin()
                checkUserBlocked()
                getLastSeen()
            }
            if isReplyViewOpen {
                if let replyMessageUserJid = replyMessageObj?.senderUserJid, let profileDetails = contactManager.getUserProfileDetails(for: replyMessageUserJid){
                    chatTextViewXib?.titleLabel?.text = (replyMessageObj?.isMessageSentByMe ?? false) ? "You" : getUserName(jid: replyMessageUserJid, name: profileDetails.name, nickName: profileDetails.nickName, contactType: profileDetails.contactType)
                }
            }
            if getProfileDetails.profileChatType == .groupChat{
                getInitialMessages()
            }
        }
    }
    
    func blockedThisUser(jid: String) {
        if !isStarredMessagePage {
            if jid == getProfileDetails.jid {
                scheduleMeetBtn.isHidden = true
                getProfileDetails.isBlocked = true
                if isMessageEditing {
                    CM.closeMenu()
                }
            }
            checkUserBlocked()
            setProfile()
        }
    }
    
    func unblockedThisUser(jid: String) {
        if !isStarredMessagePage {
            if jid == getProfileDetails.jid {
                scheduleMeetBtn.isHidden = false
                getProfileDetails.isBlocked = false
                if editMessageId.isNotEmpty {
                    editSelectedMessage()
                }
            }
            checkUserBlocked()
            setProfile()
        }
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        if !isStarredMessagePage {
            checkUserBlocked()
            setProfile()
        }

    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        print("userUpdatedTheirProfile \(jid)")
        if !isStarredMessagePage {
            fetchGroupMembers()
            let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil, userInfo: profile as [AnyHashable : Any])
            if jid ==  getProfileDetails.jid {
                getProfileDetails = profileDetails
                setProfile()
                getLastSeen()
            }
            messageDelegate?.whileUpdatingTheirProfile(for: jid, profileDetails: profileDetails)
        } else {
            UIView.performWithoutAnimation {
                UIView.performWithoutAnimation {
                    chatTableView.reloadData()
                }
            }
        }
    }
    
    func userBlockedMe(jid: String) {
        if !isStarredMessagePage {
            getLastSeen()
            setProfile(jid: jid)
        } else {
            UIView.performWithoutAnimation {
                UIView.performWithoutAnimation {
                    chatTableView.reloadData()
                }
            }
        }
    }
    
    func userUnBlockedMe(jid: String) {
        if !isStarredMessagePage {
            getLastSeen()
            setProfile(jid: jid)
        } else {
            UIView.performWithoutAnimation {
                UIView.performWithoutAnimation {
                    chatTableView.reloadData()
                }
            }
        }
    }
    
    func hideUserLastSeen() {
        if !isStarredMessagePage {
            getLastSeen()
        }
    }
    
    func getUserLastSeen() {
  
    }
    
    func userDeletedTheirProfile(for jid : String , profileDetails:ProfileDetails){
        if !isStarredMessagePage {
            if getProfileDetails.jid == jid{
                getProfileDetails = profileDetails
                setProfile()
                lastSeenLabel.text = emptyString()
                lastSeenLabel.isHidden = true
            }
            if isReplyViewOpen && (replyMessageObj?.senderUserJid == jid) {
                chatTextViewXib?.titleLabel?.text = (replyMessageObj?.isMessageSentByMe ?? false) ? "You" : getUserName(jid: jid, name: profileDetails.name, nickName: profileDetails.nickName, contactType: profileDetails.contactType)
            }
            if getProfileDetails.profileChatType == .groupChat{
                getInitialMessages()
                fetchGroupMembers()
                if let index = groupMembers.firstIndex(where: { participant in
                    participant.memberJid == jid
                }){
                    groupMembers.remove(at: index)
                    setGroupMemberInHeader()
                }
                mentionTableView.reloadData()
            }
        }
    }
    
    func fetchGroupMembers() {
        if getProfileDetails.profileChatType == .groupChat{
            getParticipants()
            getGroupMember()
            checkMemberOfGroup()
        }
    }
}

//MARK - Selecting Contact will show Contact Picker
extension ChatViewParentController: CNContactPickerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupCustomAppearance() {
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = UIColor(red: 175.0/255.0, green: 22.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UINavigationBar.appearance().barStyle = .black
    }
    
    func setupDefaultAppearance() {
        UINavigationBar.appearance().tintColor = nil
        UINavigationBar.appearance().barTintColor = nil
        UINavigationBar.appearance().titleTextAttributes = nil
        UINavigationBar.appearance().barStyle = .default
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let contactName = CNContactFormatter.string(from: contact, style: .fullName) else {
            return
        }
        contactNumber = []
        contactStatus = []
        contactLabel = []
        for number in contact.phoneNumbers {
            guard let mobileNumber = number.value.value(forKey: "digits") as? String else {
                return
            }
          
            if number.label != nil {
                if let label : String? = CNLabeledValue<NSString>.localizedString(forLabel: number.label!){
                    contactLabel.append(label ?? "")
                } else {
                    contactLabel.append("")
                }
            } else {
                contactLabel.append("")
            }
            
            contactNumber.append(mobileNumber)
            contactStatus.append(contactSelect)
        }
        var imageData : Data?
        if contact.imageDataAvailable {
            imageData = contact.imageData
        }
        
        if contactNumber.count > 0 {
            contactDetails = [ContactDetails.init(contactName: contactName, contactNumber: contactNumber, contactLabel: contactLabel, status:  contactStatus, imageData: imageData)]
            performSegue(withIdentifier: Identifiers.chatScreenToContact, sender: nil)
        }
        else {
            AppAlert.shared.showToast(message: noContactNumberAlert.localized)
        }
    }
}

//MARK : - Contact Permission
extension ChatViewParentController {
    func requestContactAccess()  {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            showContactPicker()
        case .denied:
            showSettingsAlertForContacts()
        case .restricted, .notDetermined:
            CNContactStore().requestAccess(for: .contacts) { [weak self] granted, error in
                if granted {
                    self?.showContactPicker()
                }
            }
        }
    }
    
    func showSettingsAlertForContacts() {
        let alert = UIAlertController(title: nil, message: contactDenyAlert.localized, preferredStyle: .alert)
        if
            let settings = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settings) {
            alert.addAction(UIAlertAction(title: okButton.localized, style: .default) { action in
                UIApplication.shared.open(settings)
            })
        }
        alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel) { action in
            
        })
        present(alert, animated: true)
    }
    
    func showContactPicker() {
        executeOnMainThread {  [weak self] in
            let contactPicker = CNContactPickerViewController()
            self?.setupDefaultAppearance()
            contactPicker.delegate = self
            contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
            self?.present(contactPicker, animated: true)
        }
    }
}
//MARK: Video
extension ChatViewParentController {
    
    func sendVideoMessage (mediaData : MediaData, mentionedUsersIds: [String], completionHandler :  @escaping (ChatMessage) -> Void) {
        print("#loss sendVideoMessage \(chatMessages.count)")
        selectedIndexs.removeAll()
        let tempReplyMessageId = replyMessageId
        view.endEditing(true)
        resetUnreadMessages()
        let mediaParams = FileMessageParams(fileUrl: mediaData.fileURL, fileName: mediaData.fileName, caption: mediaData.caption, fileSize: mediaData.fileSize, duration: mediaData.duration, thumbImage: mediaData.base64Thumbnail, fileKey: mediaData.fileKey)
        FlyMessenger.sendMediaFileMessage(messageParams: FileMessage(toId: self.getProfileDetails.jid ?? "", messageType: .video, fileMessage : mediaParams,replyMessageId: tempReplyMessageId, mentionedUsersIds: mentionedUsersIds)){ [weak self] isSuccess,error,message in
            if let chatMessage = message {
                self?.setLastMessage(messageId: chatMessage.messageId)
                chatMessage.mediaChatMessage?.mediaUploadStatus = isSuccess == true ? .uploading : .not_uploaded
                chatMessage.mediaChatMessage?.mediaCaptionText = mediaData.caption
                guard let msg = message else { return }
                self?.reloadList(message: msg)
                self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                if self?.replyJid == self?.getProfileDetails.jid {
                    self?.replyMessageObj = nil
                    self?.isReplyViewOpen = false
                }
            
            }
            
            if !isSuccess{
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
            executeOnMainThread {
                UIView.performWithoutAnimation {
                    self?.chatTableView.reloadData()
                }

            }
                completionHandler(message!)
            }
        }
    
    func loadVideoData(phAsset: PHAsset, slowMotionVideoUrl : URL? ,completion: @escaping (Data?)->()) {
        guard phAsset.mediaType == .video else {
            return completion(nil)
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        PHCachingImageManager().requestAVAsset(forVideo: phAsset, options: options) { (avAsset, _, _) in
            if let composition =  avAsset as? AVComposition {
                if let tempUrl = slowMotionVideoUrl {
                    var videoData: Data?
                    do {
                        videoData = try Data(contentsOf: tempUrl)
                    } catch {
                        fatalError()
                    }
                    completion(videoData)
                }
            } else {
                guard let avUrlAsset = avAsset as? AVURLAsset else {
                    return
                }
                var videoData: Data?
                do {
                    videoData = try Data(contentsOf: avUrlAsset.url)
                } catch {
                    fatalError()
                }
                completion(videoData)
            }
        }
    }
    @objc func uploadedMediaDownload(sender: UIButton) {
        
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        
        let chatMessage = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[row] : starredMessages[row] : chatMessages[section][row]
        
        if NetworkReachability.shared.isConnected {
            if let indexPath = chatMessages.indexPath(where: {$0.messageId == chatMessage?.messageId}) {
                if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                    cell.downloadButton?.isHidden = true
                    cell.downloadView?.isHidden = true
                    cell.progressView.isHidden = false
                    cell.progressLoader?.isHidden = false
                }
            }
            FlyMessenger.downloadMedia(messageId: chatMessage?.messageId ?? "") { isSuccess, error, chatMessage in
                
            }
        }
    }
    
    @objc func videoDownload(sender: UIButton){
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        let chatMessage = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[row] : starredMessages[row] : chatMessages[section][row]
        if NetworkReachability.shared.isConnected {
            if chatMessage?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || chatMessage?.mediaChatMessage?.mediaDownloadStatus == .failed {
                chatMessage?.mediaChatMessage?.mediaDownloadStatus = .downloading
                if let indexPath = chatMessages.indexPath(where: {$0.messageId == chatMessage?.messageId}) {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                        cell.playButton.isHidden = true
                        cell.downloadView.isHidden = true
                        cell.downloadButton.isHidden = true
                        cell.progressView.isHidden = false
                        cell.progressLoader?.isHidden = false
                        cell.fileSizeLabel.isHidden = false
                        cell.showHideForwardView(message: chatMessage, isDeletedSelected: isDeleteSelected, isShowForwardView: isShowForwardView)
                    } else if chatMessage?.isCarbonMessage == true && chatMessage?.isMessageSentByMe == true {
                        if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                            cell.playButton.isHidden = true
                            cell.downloadView?.isHidden = true
                            cell.downloadButton?.isHidden = true
                            cell.progressView.isHidden = false
                            cell.progressLoader?.isHidden = false
                            cell.downloadLabel?.isHidden = true
                            cell.retryButton?.isHidden = true
                            cell.retryLabel?.isHidden = true
                        }
                    }
                }
                chatMessage?.mediaChatMessage?.mediaDownloadStatus = .downloading
                FlyMessenger.downloadMedia(messageId: chatMessage?.messageId ?? "") { [weak self] isSuccess, error, message in                    print("videoDownload \(success) \(error)")
                    if message?.messageType == .image {
                        if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                            cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView, isDeleteMessageSelected: self?.isDeleteSelected, profileDetails: self?.getProfileDetails ?? ProfileDetails(jid: AppUtils.getMyJid()))
                        }
                    }
                }
            }
        }
        else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
        
    }
    
    @objc func retryVideoUpload(sender: UIButton){
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        let chatMessage = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[row] : starredMessages[row] : chatMessages[section][row]
        if NetworkReachability.shared.isConnected {
            if isStarredMessagePage {
                var messages = isStarredSearchEnabled == true ? starredSearchMessages : starredMessages
                if let row = messages?.firstIndex(where: {$0.messageId == chatMessage?.messageId}) {
                    var indexPath = IndexPath(row: row, section: 0)
                    if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                        chatMessage?.mediaChatMessage?.mediaUploadStatus = .uploading
                        cell.playButton.isHidden = true
                        cell.uploadView.isHidden = true
                        cell.retryButton?.isHidden = true
                        cell.progressView.isHidden = false
                        cell.progressLoader.isHidden = false
                        cell.showHideForwardView(message: chatMessage, isShowForwardView: isShowForwardView, isDeleteMessageSelected: isDeleteSelected)
                        FlyMessenger.uploadMedia(messageId: chatMessage?.messageId ?? "") { isSuccess, error, chatMessage in
                            print("retryVideoUpload \(success) \(error)")
                        }
                    }
                }
            } else {
                if let indexPath = chatMessages.indexPath(where: {$0.messageId == chatMessage?.messageId}) {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                        chatMessage?.mediaChatMessage?.mediaUploadStatus = .uploading
                        cell.playButton.isHidden = true
                        cell.uploadView.isHidden = true
                        cell.retryButton?.isHidden = true
                        cell.progressView.isHidden = false
                        cell.progressLoader.isHidden = false
                        cell.showHideForwardView(message: chatMessage, isShowForwardView: isShowForwardView, isDeleteMessageSelected: isDeleteSelected)
                        FlyMessenger.uploadMedia(messageId: chatMessage?.messageId ?? "") { isSuccess, error, chatMessage in
                            print("retryVideoUpload \(success) \(error)")
                        }
                    }
                }
            }
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
        
    }
    
    @objc func cancelVideoUpload(sender: UIButton) {
        print("cancelVideoUpload")
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[row] : starredMessages[row] : chatMessages[section][row]
        FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { [weak self] isSuccess in
            if let indexPath = chatMessages.indexPath(where: {$0.messageId == message?.messageId}) {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                    message?.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                    cell.progressView.isHidden = true
                    cell.retryLabel.isHidden = false
                    cell.retryButton?.isHidden = false
                    cell.uploadView.isHidden = false
                }
                
            }
        }
    }
    
    @objc func cancelVideoDownload(sender : UIButton){
        print("cancelVideoDownload")
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        let message = isStarredMessagePage ? starredMessages[row] : chatMessages[section][row]
        FlyMessenger.cancelMediaUploadOrDownload(messageId: message.messageId) { [weak self] isSuccess in
            executeOnMainThread {
                let indexPath = self?.isStarredSearchEnabled == true ? IndexPath(row: self?.starredSearchMessages?.firstIndex(where: {$0.messageId == message.messageId}) ?? 0, section: 0) : IndexPath(row: self?.starredMessages.firstIndex(where: {$0.messageId == message.messageId}) ?? 0, section: 0)
                if let indexPath = (self?.isStarredMessagePage ?? false ? indexPath : chatMessages.indexPath(where: {$0.messageId == message.messageId})) {
                    if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                        self?.updateMessage(chatMessage: message, indexPath: indexPath)?.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                        cell.progressView.isHidden = true
                        cell.playButton.isHidden = true
                        cell.downloadView.isHidden = false
                        cell.downloadButton.isHidden = false
                        cell.fileSizeLabel.isHidden = false
                    } else if message.isMessageSentByMe && message.isCarbonMessage {
                        if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                            self?.updateMessage(chatMessage: message, indexPath: indexPath)?.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                            cell.progressView.isHidden = true
                            cell.playButton.isHidden = true
                            cell.downloadView?.isHidden = false
                            cell.downloadButton?.isHidden = false
                            cell.downloadLabel?.isHidden = false
                            cell.uploadView?.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
        @objc func playVideoGestureAction(sender : UIButton) {
            view.endEditing(true)
            let indexPath = getIndexPath(sender: sender)
            let row = indexPath.row
            let section = indexPath.section
            var message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[row] : starredMessages[row] : chatMessages[section][row]
            if !isStarredMessagePage {
                if let indexPath = chatMessages.indexPath(where: {$0.messageId == message?.messageId}) {
                    var message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
                    let videoUrl = URL(fileURLWithPath: message?.mediaChatMessage?.mediaLocalStoragePath ?? "")
                    playVideo(view: self, asset: videoUrl)
                }
            } else {
                let row = indexPath.row
                let section = indexPath.section
                var chatMessages = isStarredSearchEnabled == true ? starredSearchMessages : starredMessages
                if let indexPath = chatMessages?.firstIndex(where: {$0.messageId == message?.messageId}) {
                    let message = isStarredSearchEnabled == true ? starredSearchMessages?[indexPath] : starredMessages[indexPath]
                    let videoUrl = URL(fileURLWithPath: message?.mediaChatMessage?.mediaLocalStoragePath ?? "")
                    playVideo(view: self, asset: videoUrl)
                }
                let message = chatMessages?[row]
                let videoUrl = URL(fileURLWithPath: message?.mediaChatMessage!.mediaLocalStoragePath ?? "")
                print("videoGestureAction B \(videoUrl)")
                playVideo(view: self, asset: videoUrl)
            }
        }

    func playVideo (view:UIViewController, asset:URL) {
        
        executeOnMainThread {
            let player = AVPlayer(url: asset)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            view.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
    }
    

    func updateVideoAndImageProgress(message: ChatMessage, progressPercentage: Float, index: IndexPath) {
        print("#verify__ updateVideoAndImageProgress id : \(message.messageId) \(message.mediaChatMessage!.mediaUploadStatus) **** \(message.mediaChatMessage!.mediaProgressStatus)")
        executeOnMainThread { [weak self] in
            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoOutgoingCell {
                    if message.isCarbonMessage {
                        var mediaDownloadStatus = self?.isStarredMessagePage ?? false ? self?.starredMessages[index.row].mediaChatMessage?.mediaDownloadStatus : chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus
                        mediaDownloadStatus = .downloading
                    } else {
                        if self?.isStarredMessagePage ?? false {
                            self?.starredMessages[index.row].mediaChatMessage?.mediaUploadStatus = .uploading
                            self?.starredMessages[index.row].mediaChatMessage?.mediaProgressStatus = Int(progressPercentage)
                        }else{
                            chatMessages[index.section][index.row].mediaChatMessage?.mediaUploadStatus = .uploading
                            chatMessages[index.section][index.row].mediaChatMessage?.mediaProgressStatus = Int(progressPercentage)
                        }
                    }
                  
                    if (message.mediaChatMessage?.mediaThumbImage) != nil {
                        if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                            ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                        }
                        print("updateVideoProgress  progressPercentage \(progressPercentage)")
                    }
                    cell.progressLoader.isHidden = false
                    cell.uploadView.isHidden = true
                    cell.playButton.isHidden = true
                    cell.retryButton?.isHidden = true
                    if cell.progressLoader.subviews.isEmpty{
                        cell.progressLoader.addSubview(cell.newProgressBar)
                    }
                    cell.newProgressBar.isHidden = false
                    cell.progressView.isHidden = false
                    cell.newProgressBar.setProg(per: CGFloat(progressPercentage))
                    if message.mediaChatMessage?.mediaUploadStatus == .uploading && self?.isShowForwardView == true && progressPercentage < 100 {

                        cell.forwardView?.isHidden = true
                        cell.forwardLeadingCOns?.constant = 0
                        cell.forwardButton?.isHidden = true
                    }
                }
            }else {
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoIncomingCell {
                   
                    message.mediaChatMessage?.mediaDownloadStatus = .downloading
                    if (message.mediaChatMessage?.mediaThumbImage) != nil {
                        if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                            ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                        }
                    }
                    let progrss = message.mediaChatMessage?.mediaProgressStatus ?? 0
                    cell.progressLoader.isHidden = false
                    if cell.progressLoader.subviews.isEmpty{
                        cell.progressLoader.addSubview(cell.newProgressBar)
                    }
                    cell.newProgressBar.isHidden = false
                    cell.newProgressBar.setProg(per: CGFloat(progressPercentage))
                    cell.playButton.isHidden = true
                    cell.downloadView.isHidden = true
                    cell.downloadButton.isHidden = true
                    cell.fileSizeLabel.isHidden = true
                    cell.progressView.isHidden =  false
                    if message.mediaChatMessage?.mediaDownloadStatus == .downloading && self?.isShowForwardView == true && progressPercentage < 100 {
                        cell.forwardView?.isHidden = true
                        cell.forwardLeadingCons?.constant = 0
                        cell.bubbleLeadingCons?.constant = 0
                        cell.forwardButton?.isHidden = true
                    }
                }
            }
        }
    }
    

    func updateCarbonVideoAndImage(message: ChatMessage, index: IndexPath) {
        executeOnMainThread { [weak self] in

            if message.isMessageSentByMe && message.isCarbonMessage == true && !(self?.isStarredMessagePage ?? false) {
                print("updateVideoStatus message.isMessageSentByMe")
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoOutgoingCell {

                    chatMessages[index.section][index.row].mediaChatMessage?.mediaUploadStatus = .uploaded
                    
                    if (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded) {
                        chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                    } else if (message.mediaChatMessage?.mediaDownloadStatus == .downloading) {
                        chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .downloading
                    }else {
                        chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .downloaded
                        chatMessages[index.section][index.row].mediaChatMessage?.mediaLocalStoragePath = message.mediaChatMessage?.mediaLocalStoragePath ?? ""
                    }
                    
                    if message.messageType == .image {
                        executeOnMainThread {
                            cell.imageContainer?.image = ImageConverter().base64ToImage(message.mediaChatMessage?.mediaThumbImage ?? "")
                        }
                    }
                    else {
                        if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                            ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                        }
                    }
                    
                    if (message.mediaChatMessage?.mediaDownloadStatus == .downloaded) {
                        cell.progressView.isHidden = true
                        cell.retryButton?.isHidden = true
                        cell.uploadView.isHidden = true
                        cell.downloadView?.isHidden = true
                        cell.downloadImage?.isHidden = true
                        cell.downloadLabel?.isHidden = true
                        cell.downloadButton?.isHidden = true
                        cell.playButton.isHidden =  message.messageType == .video ? false : true
                    }
                        
                    
                    if (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message.mediaChatMessage?.mediaDownloadStatus == .failed || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged
                        || self?.isShowForwardView == true) {
                        cell.quickfwdView?.isHidden = true
                        cell.quickFwdBtn?.isHidden = true
                    } else {
                        cell.quickfwdView?.isHidden = false
                        cell.quickFwdBtn?.isHidden = false
                    }
                    self?.chatTableView.reloadRows(at: [index], with: .none)
                }
            }else if (self?.isStarredMessagePage ?? false){
                executeOnMainThread { [weak self] in
                    self?.chatTableView.reloadDataWithoutScroll()
                }
            }
        }
    }
    
    func updateCarbonDocument(message: ChatMessage, index: IndexPath) {
        executeOnMainThread { [weak self] in
            if message.isMessageSentByMe && message.isCarbonMessage == true {
                print("updateVideoStatus message.isMessageSentByMe")
                if let cell = self?.chatTableView.cellForRow(at: index) as? SenderDocumentsTableViewCell {
                    chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .downloaded
                    chatMessages[index.section][index.row].mediaChatMessage?.mediaLocalStoragePath = message.mediaChatMessage?.mediaLocalStoragePath ?? ""
                    
                    cell.nicoProgressBar?.isHidden = true
                    
                    if (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message.mediaChatMessage?.mediaDownloadStatus == .failed  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged
                        || self?.isShowForwardView == true) {
                        cell.forwardView?.isHidden = true
                        cell.forwardButton?.isHidden = true
                    } else {
                        cell.forwardView?.isHidden = false
                        cell.forwardButton?.isHidden = false
                    }
                    self?.chatTableView.reloadRows(at: [index], with: .none)
                }
            }
        }
    }
    

    func updateVideoAndImageStatus(message: ChatMessage, index: IndexPath) {
        print("#verify__ updateVideoAndImageStatus id: \(message.messageId) \(message.mediaChatMessage?.mediaDownloadStatus) **** \(message.mediaChatMessage?.mediaProgressStatus)")
        executeOnMainThread { [weak self] in

            if message.isMessageSentByMe {
                print("updateVideoStatus message.isMessageSentByMe")
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoOutgoingCell {
                    if self?.isStarredMessagePage == true {
                        if self?.isStarredSearchEnabled == true {
                            self?.starredSearchMessages?[index.row] = message
                        } else {
                            self?.starredMessages[index.row] = message
                        }
                    } else {
                        chatMessages[index.section][index.row] = message
                    }
                    if message.messageType == .image {
                        executeOnMainThread {
                            cell.imageContainer?.image = ImageConverter().base64ToImage(message.mediaChatMessage?.mediaThumbImage ?? "")
                        }
                    }
                    else {
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                    }
                    }
                    
                    cell.retryButton?.isHidden = message.mediaChatMessage?.mediaUploadStatus == .uploaded || message.mediaChatMessage?.mediaUploadStatus == .uploading
                    cell.uploadView.isHidden =  message.mediaChatMessage?.mediaUploadStatus == .uploaded || message.mediaChatMessage?.mediaUploadStatus == .uploading
                    cell.playButton.isHidden = message.messageType == .video ? message.mediaChatMessage?.mediaUploadStatus != .uploaded : true
                    if message.mediaChatMessage?.mediaUploadStatus == .uploading{
                        cell.progressLoader.isHidden = false
                        if cell.progressLoader.subviews.isEmpty{
                            cell.progressLoader.addSubview(cell.newProgressBar)
                        }
                        cell.newProgressBar.isHidden = false
                        cell.progressView.isHidden = false
                        cell.newProgressBar.setProg(per: CGFloat(message.mediaChatMessage?.mediaProgressStatus ?? 0))
                    }else{
                        cell.newProgressBar.isHidden = true
                        cell.progressLoader.isHidden = true
                        cell.progressView.isHidden = true
                    }
                    if (message.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message.mediaChatMessage?.mediaUploadStatus == .failed || message.mediaChatMessage?.mediaUploadStatus == .uploading || message.messageStatus == .notAcknowledged
                        || self?.isShowForwardView == true) {
                            cell.quickfwdView?.isHidden = true
                            cell.quickFwdBtn?.isHidden = true
                        } else {
                            cell.quickfwdView?.isHidden = false
                            cell.quickFwdBtn?.isHidden = false
                        }
                    self?.updateMediaMessageStatus(statusImage: cell.msgStatus, messageStatus: message.messageStatus)
                    cell.message = message
                }
            }else {
                if message.mediaChatMessage?.mediaProgressStatus == 100 {
                    message.mediaChatMessage?.mediaDownloadStatus = .downloaded
                }
                print("updateVideoStatus else")
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoIncomingCell {
                    
                    if self?.isStarredMessagePage == true {
                        if self?.isStarredSearchEnabled == true {
                            self?.starredSearchMessages?[index.row] = message
                        } else {
                            self?.starredMessages[index.row] = message
                        }
                    } else {
                        chatMessages[index.section][index.row] = message
                    }
                    if message.messageType == .image {
                        executeOnMainThread {
                            cell.imageContainer.image = ImageConverter().base64ToImage(message.mediaChatMessage?.mediaThumbImage ?? "")
                        }
                    }
                    
                    cell.downloadView.isHidden = message.mediaChatMessage?.mediaDownloadStatus == .downloaded ||  message.mediaChatMessage?.mediaDownloadStatus == .downloading
                    cell.downloadButton.isHidden = message.mediaChatMessage?.mediaDownloadStatus == .downloaded ||  message.mediaChatMessage?.mediaDownloadStatus == .downloading
                    cell.showHideForwardView(message: message, isDeletedSelected: self?.isStarredMessageSelected == true ? true : self?.isDeleteSelected, isShowForwardView: self?.isShowForwardView)
                    cell.playButton.isHidden = message.messageType == .video ? message.mediaChatMessage?.mediaDownloadStatus != .downloaded : true
                    if message.mediaChatMessage?.mediaDownloadStatus == .downloading{
                        cell.progressLoader.isHidden = false
                        cell.fileSizeLabel.isHidden = true
                        if cell.progressLoader.subviews.isEmpty{
                            cell.progressLoader.addSubview(cell.newProgressBar)
                        }
                        cell.newProgressBar.isHidden = false
                        cell.progressView.isHidden = false
                        cell.newProgressBar.setProg(per: CGFloat(message.mediaChatMessage?.mediaProgressStatus ?? 0))
                    }else{
                        cell.progressLoader.isHidden = true
                        cell.newProgressBar.isHidden = true
                        cell.progressView.isHidden =  true
                        cell.fileSizeLabel.isHidden = false
                        if let fileSize = message.mediaChatMessage?.mediaFileSize{
                            cell.fileSizeLabel.text = "\(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))"
                        }
                    }
                    if  message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message.mediaChatMessage?.mediaDownloadStatus == .failed  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || self?.isShowForwardView == true || self?.isStarredMessagePage == true {
                        cell.quickForwardView?.isHidden = true
                        cell.quickForwardButton?.isHidden = true
                    } else {
                        cell.quickForwardView?.isHidden = false
                        cell.quickForwardButton?.isHidden = false
                    }
                    
                    if message.mediaChatMessage?.mediaDownloadStatus == .downloaded && message.messageType == .image{
                        if let localPath = message.mediaChatMessage?.mediaFileName {
                            if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                                let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                                let fileURL: URL = folderPath.appendingPathComponent(localPath)
                                if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                                    cell.imageContainer?.sd_setImage(with: fileURL)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func onVideoAndImageUploadFailed(message : ChatMessage, indexPath : IndexPath) {
    
        executeOnMainThread { [weak self] in

            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                    }
                    if message.isCarbonMessage {
                        cell.mediaStatusForCorbon(message: message)
                    } else {
                        cell.mediaStatus(message: message)
                    }
//                    if message.isCarbonMessage {
//                        cell.progressLoader.isHidden = true
//                        cell.progressView.isHidden = true
//                        cell.playButton.isHidden = true
//
//                        cell.downloadLabel?.isHidden = false
//                        cell.downloadButton?.isHidden = false
//                        cell.downloadView?.isHidden = false
//                        cell.downloadImage?.isHidden = false
//                    } else {
//                        cell.progressLoader.isHidden = true
//                        cell.progressView.isHidden = true
//                        cell.playButton.isHidden = true
//
//                        cell.retryLabel.isHidden = false
//                        cell.retryButton?.isHidden = false
//                        cell.uploadView.isHidden = false
//                        cell.uploadImage.isHidden = false
//                    }
                    self?.updateMediaMessageStatus(statusImage: cell.msgStatus, messageStatus: message.messageStatus)
                    self?.chatTableView.reloadRows(at: [indexPath], with: .none)
                }
            }else {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                    if (self?.isStarredMessagePage ?? false){
                        print("isStarredMessagePage,,,,,,.........")
                    } else{
                        chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus = .failed
                    }
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                    }
                    cell.progressView.isHidden = true
                    cell.downloadView.isHidden = false
                    cell.downloadButton.isHidden = false
                    cell.fileSizeLabel.isHidden = false
                    cell.playButton.isHidden = true
                    if let fileSize = message.mediaChatMessage?.mediaFileSize{
                        cell.fileSizeLabel.text = "\(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))"
                    }else {
                        cell.fileSizeLabel.text = ""
                    }
                }
            }
        }
    }
    
    func updateDocumentProgress(message: ChatMessage, progressPercentage: Float, index: IndexPath) {
        executeOnMainThread { [weak self] in
            print("uploadingProgress Document \(progressPercentage)")
            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: index) as? SenderDocumentsTableViewCell {
                    if message.isCarbonMessage {
                        var mediaDownloadStatus = self?.isStarredMessagePage ?? false ? self?.starredMessages[index.row].mediaChatMessage?.mediaDownloadStatus : chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus
                        mediaDownloadStatus = .downloading
                    } else {
                        if self?.isStarredMessagePage ?? false {
                            self?.starredMessages[index.row].mediaChatMessage?.mediaUploadStatus = .uploading
                            self?.starredMessages[index.row].mediaChatMessage?.mediaProgressStatus = Int(progressPercentage)
                        }else{
                            chatMessages[index.section][index.row].mediaChatMessage?.mediaUploadStatus = .uploading
                            chatMessages[index.section][index.row].mediaChatMessage?.mediaProgressStatus = Int(progressPercentage)
                        }
                    }
                    print("updateDocumentProgress  progressPercentage \(progressPercentage)")
                    cell.uploadCancelImage?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                    cell.uploadCancelImage?.isHidden = false
                    cell.uploadButton?.isHidden = false
                    cell.nicoProgressBar?.isHidden = false
                    if cell.newProgressBar.subviews.isEmpty{
                        cell.nicoProgressBar.addSubview(cell.newProgressBar)
                    }
                    cell.newProgressBar.setProg(per: CGFloat(progressPercentage))
                    if message.mediaChatMessage?.mediaUploadStatus == .uploading && self?.isShowForwardView == true && progressPercentage < 100 {
                        cell.forwardView?.isHidden = true
                        cell.forwardButton?.isHidden = true
                    }
                }
            } else {
                print("updateDocumentProgress else \(progressPercentage)")
                if let cell = self?.chatTableView.cellForRow(at: index) as? ReceiverDocumentsTableViewCell {
                    cell.downloadImageView?.image = UIImage(named: ImageConstant.ic_download_cancel)
                    cell.downloadButton?.isHidden = false
                    cell.downloadImageView?.isHidden = false
                    cell.nicoProgressBar.isHidden = false
                    cell.newProgressBar.removeFromSuperview()
                    cell.nicoProgressBar.addSubview(cell.newProgressBar)
                    cell.newProgressBar.setProg(per: CGFloat(progressPercentage))
                    cell.downloadView?.isHidden = false
                    if message.mediaChatMessage?.mediaDownloadStatus == .downloading && self?.isShowForwardView == true && progressPercentage < 100 {
                        cell.forwardView?.isHidden = true
                        cell.forwardButton?.isHidden = true
                        cell.bubbleLeadingCons?.isActive = true
                        cell.bubbleLeadingCons?.constant = 20
                    }
                }
            }
        }
    }
    
    func onAudioUploadFailed(message : ChatMessage, indexPath : IndexPath) {
        isShowAudioLoadingIcon = false
        executeOnMainThread { [weak self] in
            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                    if message.isCarbonMessage {
                        cell.stopDownload()
                    } else {
                        cell.stopUpload()
                    }
                    cell.updateMediaStatus(message: message, indexPath: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false)
                    self?.updateMediaMessageStatus(statusImage: cell.status ?? UIImageView(), messageStatus: message.messageStatus)
                }
            } else {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                    if (self?.isStarredMessagePage ?? false){
                        print("isStarredMessagePage,,,,,,.........")
                    } else {
                        chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus = .failed
                    }
                    cell.stopDownload()
                }
            }
        }
    }
    
    func onDocumentUploadFailed(message: ChatMessage, indexPath: IndexPath) {
        executeOnMainThread { [weak self] in
            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                    if message.isCarbonMessage {
                        cell.stopDownload()
                    } else {
                        cell.stopUpload()
                    }
                    cell.updateMediaStatus(message: message, indexPath: indexPath)
                    self?.updateMediaMessageStatus(statusImage: cell.messageStatusImage ?? UIImageView(),
                                                   messageStatus: message.messageStatus)
                }
            } else {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ReceiverDocumentsTableViewCell {
                    cell.stopDownload()
                    if (self?.isStarredMessagePage ?? false){
                        print("isStarredMessagePage,,,,,,.........")
                    } else{
                        chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus = .failed
                    }
                }
            }
        }
    }
    
    func updateMediaMessageStatus(statusImage : UIImageView, messageStatus : MessageStatus) {
        switch messageStatus {
        case .notAcknowledged:
            statusImage.image = UIImage.init(named: ImageConstant.ic_hour)
            statusImage.accessibilityLabel = notAcknowledged.localized
        break
        case .sent:
            statusImage.image = UIImage.init(named: ImageConstant.ic_hour)
            statusImage.accessibilityLabel = sent.localized
            break
        case .acknowledged:
            statusImage.image = UIImage.init(named: ImageConstant.ic_sent)
            statusImage.accessibilityLabel = acknowledged.localized
            break
        case .delivered:
            statusImage.image = UIImage.init(named: ImageConstant.ic_delivered)
            statusImage.accessibilityLabel = delivered.localized
            break
        case .seen:
            statusImage.image = UIImage.init(named: ImageConstant.ic_seen)
            statusImage.accessibilityLabel = seen.localized
            break
        case .received:
            statusImage.image = UIImage.init(named: ImageConstant.ic_delivered)
            statusImage.accessibilityLabel = delivered.localized
            break
        default:
            statusImage.image = UIImage.init(named: ImageConstant.ic_hour)
            statusImage.accessibilityLabel = notAcknowledged.localized
            break
        }
    }
}

extension ChatViewParentController {
    
    @objc func makeCall(_ sender : UIButton){
        print("#callopt \(FlyUtils.printTime()) makeCall from \(AppUtils.getMyJid())")
        if CallManager.isAlreadyOnAnotherCall(){
            AppAlert.shared.showToast(message: "You’re already on call, can't make new MirrorFly call")
            return
        }
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        var callType = CallType.Audio
        if sender.tag == 102 {
            callType = .Video
        }
        if getProfileDetails.profileChatType == .groupChat {
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
            controller.modalPresentationStyle = .fullScreen
            controller.makeCall = true
            controller.isMultiSelect = true
            controller.callType = callType
            controller.hideNavigationbar = true
            controller.groupJid = getProfileDetails.jid
            controller.getProfileDetails = getProfileDetails
            controller.fetchMessageListQuery = fetchMessageListQuery
            self.navigationController?.pushViewController(controller, animated: true)
        } else if getProfileDetails.profileChatType == .singleChat{
            if getProfileDetails.contactType != .deleted {
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: [getProfileDetails.jid], callType: callType, onCompletion: { isSuccess, message in
                    if(!isSuccess){
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                    }
                })
            }
        }
    }
}
// Typing Delegate
extension ChatViewParentController : TypingStatusDelegate {
    func onChatTypingStatus(userJid: String, status: TypingStatus) {
        print("ChatViewParentController onChatTypingStatus \(status) userJid \(userJid)")
        executeOnMainThread { [weak self] in
            if userJid == self?.getProfileDetails.jid{
                if status == TypingStatus.composing {
                    self?.lastSeenLabel.text = typing.localized
                } else if status == TypingStatus.gone {
                    self?.getLastSeen()
                }
            }
        }
    }
    
    func onGroupTypingStatus(groupJid: String, groupUserJid: String, status: TypingStatus) {
        executeOnMainThread { [weak self] in
            if groupJid == self?.getProfileDetails.jid && groupUserJid != AppUtils.getMyJid() {
                if status == TypingStatus.composing {
                    let user = self?.groupMembers.filter({$0.memberJid == groupUserJid}).first
                    let name = getUserName(jid: user?.profileDetail?.jid ?? "", name: user?.profileDetail?.name ?? "", nickName: user?.profileDetail?.nickName ?? "", contactType: user?.profileDetail?.contactType ?? .unknown)
                    self?.groupMemberLable.text = name + " " + isText + " " + typing.localized
                } else if status == TypingStatus.gone {
                    self?.setGroupMemberInHeader()
                }
            }
        }
    }
}

extension ChatViewParentController : GroupEventsDelegate {
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        getGroupMember()
        checkMemberOfGroup()
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        checkMemberOfGroup()
    }
    
    func didFetchGroupProfile(groupJid: String) {
        getGroupMember()
        checkMemberOfGroup()
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        if FlyUtils.isValidGroupJid(groupJid: getProfileDetails.jid) && getProfileDetails.jid == groupJid {
            let group = GroupManager.shared.getAGroupFromLocal(groupJid: groupJid)
            executeOnMainThread { [weak self] in
                self?.getProfileDetails.nickName = (group?.name ?? group?.nickName) ?? ""
                self?.getProfileDetails.name = (group?.name ?? group?.nickName) ?? ""
                self?.getProfileDetails.image = group?.image ?? ""
                self?.getProfileDetails.thumbImage = group?.thumbImage ?? ""
                self?.setProfile()
            }
        }
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        
    }
    
    func didRevokedAdminAccess(groupJid: String, revokedAdminMemberJid: String, revokedByMemberJid: String) {
        checkMemberOfGroup()
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        checkMemberOfGroup()
    }
    
    func didCreateGroup(groupJid: String) {
        getGroupMember()
        checkMemberOfGroup()
    }
    
    func didFetchGroups(groups: [ProfileDetails]) {
        
    }
    
    func didFetchGroupMembers(groupJid: String) {
        getGroupMember()
        checkMemberOfGroup()
    }
    
    func didReceiveGroupNotificationMessage(message: ChatMessage) {
        onMessageReceived(message: message, chatJid: message.chatUserJid)
    }
    
}

//MARK : Group
extension ChatViewParentController {
    
    func checkMemberOfGroup() {
        if !isStarredMessagePage {
            if getProfileDetails.profileChatType == .groupChat {
                if !(availableFeatures.isGroupChatEnabled) {
                    chatTextViewXib?.cannotSendMessageView?.isHidden =  false
                    chatTextViewXib?.blockedMessageLabel?.text = "Feature unavailable for your plan"
                    disableForBlocking(disable: true)
                    return
                }
                
                let result = isParticipantExist()
                if !result.doesExist && editMessageId.isNotEmpty {
                    CM.closeMenu()
                }
                print("ChatViewParentController Group isExist \(result.doesExist) \(result.message)")
                chatTextViewXib?.cannotSendMessageView?.isHidden = result.doesExist ? true : false
                disableForBlocking(disable: result.doesExist ? false : true)
                scheduleMeetBtn.isHidden = !result.doesExist
                groupMembers = GroupManager.shared.getGroupMemebersFromLocal(groupJid: getProfileDetails.jid).participantDetailArray.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                if mentionSearch.isEmpty {
                    searchGroupMembers = mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                } else {
                    searchGroupMembers = mentionArrayFilter().filter{ $0.displayName.lowercased().contains(mentionSearch.lowercased())}.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                }
                mentionTableView.reloadData()

            }
        }
    }
    
    func isParticipantExist() -> (doesExist : Bool, message : String) {
       return GroupManager.shared.isParticiapntExistingIn(groupJid: getProfileDetails.jid, participantJid: AppUtils.getMyJid())
    }
    
    func getGroupMember() {
        print("getGrouMember")
        groupMembers = [GroupParticipantDetail]()
        groupMembers =  GroupManager.shared.getGroupMemebersFromLocal(groupJid: getProfileDetails.jid).participantDetailArray.filter({$0.memberJid != AppUtils.getMyJid()})
        print("getGrouMember \(groupMembers.count)")
        if mentionSearch.isEmpty {
            searchGroupMembers = mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
        } else {
            searchGroupMembers = mentionArrayFilter().filter{ $0.displayName.lowercased().contains(mentionSearch.lowercased())}.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
        }
        mentionTableView.reloadData()
        setGroupMemberInHeader()
    }
    
    func getParticipants() {
        GroupManager.shared.getParticipants(groupJID: getProfileDetails.jid)
    }
    
    func setGroupMemberInHeader() {
        executeOnMainThread { [weak self] in
            var memberList = [String]()
            let members = self?.groupMembers ?? [GroupParticipantDetail]()
            for (index, member) in members.enumerated() {
                let profileDetail = member.profileDetail
                let myProfile = self?.contactManager.getUserProfileDetails(for: AppUtils.getMyJid())
                if myProfile?.jid != profileDetail?.jid {
                    let participantName = getUserName(jid : profileDetail?.jid ?? "" ,name: profileDetail?.name ?? "", nickName: profileDetail?.nickName ?? "", contactType: profileDetail?.contactType ?? .live)
                    memberList.append(participantName)
                }
            }

            members.forEach { member in
                if AppUtils.getMyJid() == member.profileDetail?.jid {
                    memberList.append("You ")
                }
            }

            self?.groupMemberLable.type = .continuous
            self?.groupMemberLable.animationCurve = .linear
            self?.groupMemberLable.speed = .duration(45)
            self?.groupMemberLable.text = memberList.joined(separator: ", ")
            
            print("setGroupMemberInHeader \(memberList)")
        }

    }
    
    func hideSenderNameToGroup(indexPath: IndexPath) -> Bool{
        let section = indexPath.section
        let row = indexPath.row
        let totalCount = isStarredMessagePage ? starredMessages.count : chatMessages[section].count
        print("handleSenderNameToGroup section \(section) row \(row) totalCount \(totalCount)")
     
        if isStarredMessagePage {
            return true
        }
        if row < totalCount-1 && row > 0 {
            
            let currentMessage = isStarredMessagePage ? starredMessages[row] : chatMessages[section][row]
            let nextMessage = isStarredMessagePage ? starredMessages[row + 1] : chatMessages[section][row + 1]
            let previousMessage = isStarredMessagePage ? starredMessages[row - 1] : chatMessages[section][row - 1]
            
            let currentJid = currentMessage.senderUserJid
            let nextJid = nextMessage.senderUserJid
            let previousJid = previousMessage.senderUserJid
            
            print("handleSenderNameToGroup \(currentJid) \(nextJid) \(previousJid)")
            if !currentMessage.isMessageSentByMe {
                print("handleSenderNameToGroup \(currentMessage.messageTextContent) \(nextMessage.messageTextContent) \(previousMessage.messageTextContent)")
                if currentJid == nextJid && currentJid != previousJid {
                    return true
                }
                
                if currentJid == nextJid && currentJid == previousJid {
                    return true
                }
            }
        } else {
            let currentMessage = isStarredMessagePage ? starredMessages[row] : chatMessages[section][row]
            if row == 0 && totalCount > 1 && !currentMessage.isMessageSentByMe {
                
                let nextMessage = isStarredMessagePage ? starredMessages[row + 1] : chatMessages[section][row + 1]
                if currentMessage.senderUserJid == nextMessage.senderUserJid {
                    return true
                }
            }
        }
        
        return false
    }
    
   
}

// handle message views
extension ChatViewParentController {
    func handleChatBubble(indexPath : IndexPath) {
        let currentMessage = isStarredMessagePage ? starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
        print("handleChatBubble Section \(indexPath.section) Row \(indexPath.row) \(currentMessage.messageTextContent)")
        
    }
}
extension ChatViewParentController : RefreshBubbleImageViewDelegate {
    func refreshBubbleImageView(indexPath: IndexPath,isSelected: Bool,title: String?) {
        
        switch isSelected {
        case true:
            if selectedMessages?.filter({$0.chatMessage.messageId == (isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row].messageId : starredMessages[indexPath.row].messageId : chatMessages[indexPath.section][indexPath.row].messageId)}).count == 0 {
                var selectedForwardMessage = SelectedMessages()
                selectedForwardMessage.isSelected = isSelected
                selectedForwardMessage.chatMessage = (isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] ?? ChatMessage() : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row])
                let totalCount = selectedMessages?.count ?? 0
                if totalCount >= 10 && isShareMediaSelected {
                    AppAlert.shared.showToast(message: cannotShareMoreThan10)
                    return
                }
                selectedMessages?.append(selectedForwardMessage)
                if let cell = chatTableView.cellForRow(at: indexPath), let forwardImageView = cell.viewWithTag(10023) as? UIImageView, let forwardView = cell.viewWithTag(10024) {
                    forwardImageView.image = UIImage(named: "forwardSelected")
                    forwardImageView.isHidden = false
                    forwardView.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
                }
            }
        case false:
            selectedMessages?.enumerated().forEach { (index,item) in
                if item.chatMessage.messageId == (isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row].messageId : starredMessages[indexPath.row].messageId : chatMessages[indexPath.section][indexPath.row].messageId) {
                    selectedMessages?.remove(at: index)
                    return
                }
            }
            if let cell = chatTableView.cellForRow(at: indexPath), let forwardImageView = cell.viewWithTag(10023) as? UIImageView, let forwardView = cell.viewWithTag(10024) {
                forwardImageView.isHidden = true
                forwardView.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
            }
        }
        executeOnMainThread { [self] in
            chatTableView.beginUpdates()
            chatTableView.endUpdates()
        }
        let isStar = checkforStar(selectedMessages: selectedMessages ?? [])
        forwardButton?.setTitle(isStarredMessageSelected ? !isStar ? unStarTitle : isDeleteSelected ? deleteTitle : title : title, for: .normal)
        forwardButton?.isHidden = selectedMessages?.count ?? 0 > 0 ? false : true
        showHideForwardView() //shareTitle
    }
    
    private func showHideForwardView() {
        forwardBottomView?.isHidden = (isShowForwardView == true) ? false : true
        textToolBarView?.isHidden = isShowForwardView == true ? true : false
        if isStarredMessagePage {
            showHideMutiSelectionView()
        }
    }
}

extension ChatViewParentController : SendSelectecUserDelegate {
    func sendSelectedUsers(selectedUsers: [Profile],completion: @escaping (() -> Void)) {
        guard let messageIds = selectedMessages?.map({$0.chatMessage.messageId}) else { return  }
        let jids = selectedUsers.map({$0.jid})
        print("Jids:",jids)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self?.isStarredMessagePage == false {
                if jids.filter({$0 == self?.getProfileDetails.jid}).count > 0 {
                    self?.getInitialMessages()
                } else {
                    UIView.performWithoutAnimation {
                        self?.chatTableView?.reloadData()
                    }
                }
            } else {
                UIView.performWithoutAnimation {
                    self?.chatTableView?.reloadData()
                }
            }
        }
        messageTextView?.resignFirstResponder()
        selectedMessages?.removeAll()
        isShowForwardView = false
        showHideForwardView()
        executeOnMainThread {
            completion()
        }
    }
}

extension ChatViewParentController: ShowMailComposeDelegate {
    func showMailComposer(mail: String){
        // Build the URL from its components
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = mail
        

        guard let url = components.url else {
            NSLog("Failed to create mailto URL")
            return
        }

        UIApplication.shared.open(url) { success in
          
        }
    }
}


// MARK Network change detecting
extension ChatViewParentController {
    func networkMonitor() {
        if !NetworkReachability.shared.isConnected {
            executeOnMainThread { [weak self] in
                self?.lastSeenLabel.text = waitingForNetwork
            }
        }
        NetworkReachability.shared.netStatusChangeHandler = { [weak self] in
            print("networkMonitor \(NetworkReachability.shared.isConnected)")
            if !NetworkReachability.shared.isConnected {
                executeOnMainThread {
                    self?.lastSeenLabel.text = waitingForNetwork
                }
            }
        }
    }
}
// MARK: Image cancel and upload methods
extension ChatViewParentController {
    @objc func cancelOrUploadImages(sender: UIButton) {
        
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        
        let message = chatMessages[indexPath.section][indexPath.row]
        if message.isMessageSentByMe {
            if message.mediaChatMessage?.mediaUploadStatus == .uploading {
                message.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                chatMessages[indexPath.section][indexPath.row] = message
                if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                    cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView)
                }
                FlyMessenger.cancelMediaUploadOrDownload(messageId: message.messageId) { [weak self] isSuccess in
                    if message.messageType == .image {
                        executeOnMainThread { [weak self] in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView)
                            }
                        }
                    }
                }
            } else if message.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message.mediaChatMessage?.mediaUploadStatus == .failed {
                imageUpload(sender: sender)
            } else if message.mediaChatMessage?.mediaUploadStatus == .uploaded {
                if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                    cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView)
                }
            }
        }
    }
    
    private func imageUpload(sender: UIButton,completion: @escaping (Bool?)->()) {
        let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
            let message = chatMessages[indexPath.section][indexPath.row]
            if NetworkReachability.shared.isConnected {
                FlyMessenger.uploadMedia(messageId: message.messageId) { isSuccess, error, chatMessage in
                    completion(true)
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
    
    @objc func imageUpload(sender: UIButton) {
            imageUpload(sender: sender) { isSuccess in
        }
    }
}


// MARK: Audio cancel and upload methods
extension ChatViewParentController {
    @objc func audioUpload(sender: UIButton) {
        audioUpload(sender: sender) { isSuccess in
        }
    }
    
    private func audioUpload(sender: UIButton,completion: @escaping (Bool?)->()) {
        let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
            let message = isStarredMessagePage ? starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
            if NetworkReachability.shared.isConnected {
                executeOnMainThread {
                    FlyMessenger.uploadMedia(messageId: message.messageId) { isSuccess, error, chatMessage in
                        completion(true)
                    }
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
    
    @objc func uploadCancelaudioAction(sender: UIButton) {
        isShowAudioLoadingIcon = false
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        if indexPath.section < (isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?.count ?? 0 : starredMessages.count : chatMessages.count) {
            let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
            print("indexPath",indexPath)
            if message?.isMessageSentByMe == true {
                executeOnMainThread { [weak self] in
                    if message?.isCarbonMessage == true {
                        if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                            message?.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                            if let chatMessage = message {
                                if self?.isStarredMessagePage == true {
                                    if self?.isStarredSearchEnabled == true {
                                        self?.starredSearchMessages?[indexPath.row] = chatMessage
                                    } else {
                                        var messagList = self?.starredMessages
                                        messagList?[indexPath.row] = chatMessage
                                    }
                                } else {
                                    chatMessages[indexPath.section][indexPath.row] = chatMessage
                                }
                            }
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                cell.getCellFor(message, at: indexPath, isPlaying: false, audioClosureCallBack: { sliderValue in
                                }, isShowForwardView: self?.isShowForwardView, isDeleteMessageSelected: self?.isDeleteSelected)
                                cell.stopDownload()
                            }
                            print("cancelIndex",message?.messageId)
                            FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { isSuccess in
//                                executeOnMainThread {
//                                    if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
//                                        cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
//                                        self?.chatTableView?.reloadRows(at: [indexPath], with: .none)
//                                    }
//                                }
                            }
                        } else if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed {
                            message?.mediaChatMessage?.mediaDownloadStatus = .downloading
                            if let chatMessage = message {
                                if self?.isStarredMessagePage == true {
                                    if self?.isStarredSearchEnabled == true {
                                        self?.starredSearchMessages?[indexPath.row] = chatMessage
                                    } else {
                                        var messagList = self?.starredMessages
                                        messagList?[indexPath.row] = chatMessage
                                    }
                                } else {
                                    chatMessages[indexPath.section][indexPath.row] = chatMessage
                                }
                            }
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                cell.getCellFor(message, at: indexPath, isPlaying: false, audioClosureCallBack: { sliderValue in
                                }, isShowForwardView: self?.isShowForwardView, isDeleteMessageSelected: self?.isDeleteSelected)
                            }
                            FlyMessenger.downloadMedia(messageId: message?.messageId ?? "") { isSuccess, error, chatMessage in
                                executeOnMainThread { [weak self] in
                                    if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                        cell.getCellFor(message, at: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { (_) in
                                        }, isShowForwardView: self?.isShowForwardView, isDeleteMessageSelected: self?.isDeleteSelected)
                                    }
                                }
                            }
                        } else {
                            if let _ = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                self?.chatTableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    } else {
                        if message?.mediaChatMessage?.mediaUploadStatus == .uploading {
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                cell.stopUpload()
                            }
                            message?.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                            if let chatMessage = message {
                                if self?.isStarredMessagePage == true {
                                    if self?.isStarredSearchEnabled == true {
                                        self?.starredSearchMessages?[indexPath.row] = chatMessage
                                    } else {
                                        var messagList = self?.starredMessages
                                        messagList?[indexPath.row] = chatMessage
                                    }
                                } else {
                                    chatMessages[indexPath.section][indexPath.row] = chatMessage
                                }
                            }
                            print("cancelIndex",message?.messageId)
                            FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { isSuccess in
                                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                    cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                    self?.chatTableView?.reloadRows(at: [indexPath], with: .none)
                                }
                            }
                        } else if message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message?.mediaChatMessage?.mediaUploadStatus == .failed {
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                cell.startUpload()
                                message?.mediaChatMessage?.mediaUploadStatus = .uploading
                                if let chatMessage = message {
                                    if self?.isStarredMessagePage == true {
                                        if self?.isStarredSearchEnabled == true {
                                            self?.starredSearchMessages?[indexPath.row] = chatMessage
                                        } else {
                                            var messagList = self?.starredMessages
                                            messagList?[indexPath.row] = chatMessage
                                        }
                                    } else {
                                        chatMessages[indexPath.section][indexPath.row] = chatMessage
                                    }
                                }
                                cell.showHideForwardView(message: message, isShowForwardView: self?.isShowForwardView, isDeleteMessageSelected: self?.isDeleteSelected)
                                self?.audioUpload(sender: sender) { [weak self] isSuccess in
                                    if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                        cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                        cell.getCellFor(message, at: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { (_) in
                                        }, isShowForwardView: self?.isShowForwardView, isDeleteMessageSelected: self?.isDeleteSelected)
                                    }
                                }
                            }
                        } else if message?.mediaChatMessage?.mediaUploadStatus == .not_available {
                            FlyMessenger.downloadMedia(messageId: message?.messageId ?? "") { isSuccess, error, chatMessage in
                                executeOnMainThread { [weak self] in
                                    if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                        cell.getCellFor(message, at: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { (_) in
                                        }, isShowForwardView: self?.isShowForwardView, isDeleteMessageSelected: self?.isDeleteSelected)
                                    }
                                }
                            }
                        } else {
                            if let _ = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                self?.chatTableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    }
                }
            } else {
                executeOnMainThread { [weak self] in
                    self?.audioPermission()
                    if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                        if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                            cell.stopDownload()
                        }
                        message?.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                     
                        if self?.isStarredMessagePage == true {
                            if self?.isStarredSearchEnabled == true {
                                    self?.starredSearchMessages?[indexPath.row].mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                                } else {
                                    let message = self?.starredMessages
                                    message?[indexPath.row].mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                                }
                            } else {
                                chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                            }
                        
                        FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { isSuccess in
                            executeOnMainThread {
                                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                                    cell.stopDownload()
                                }
                            }
                        }
                    } else if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed {
                        message?.mediaChatMessage?.mediaDownloadStatus = .downloading
                        if let chatMessage = message {
                            if self?.isStarredMessagePage == true {
                                if self?.isStarredSearchEnabled == true {
                                    self?.starredSearchMessages?[indexPath.row] = chatMessage
                                } else {
                                    var messagList = self?.starredMessages
                                    messagList?[indexPath.row] = chatMessage
                                }
                            } else {
                                chatMessages[indexPath.section][indexPath.row] = chatMessage
                            }
                        }
                        if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                            cell.startDownload()
                            cell.showHideForwardView(message: message, isShowForwardView: self?.isShowForwardView, isDeletedMessageSelected: self?.isDeleteSelected)
                        }
                        FlyMessenger.downloadMedia(messageId: message?.messageId ?? "") { [weak self] isSuccess, error, chatMessage in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                                cell.getCellFor(message, at: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { (_) in
                                }, isShowForwardView: self?.isShowForwardView, isDeletedMessageSelected: self?.isDeleteSelected)
                            }
                        }
                    } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                        self?.chatTableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }
        }
    }
}

/// Document Upload and Download Methods

extension ChatViewParentController: UIDocumentInteractionControllerDelegate {
    
    @objc func viewDocument(sender: UIButton) {
        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        let message = isStarredMessagePage == true ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
        if (message?.messageStatus == .acknowledged || (message?.isMessageSentByMe == true ? message?.messageStatus == .delivered : (message?.messageStatus == .delivered && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded)) || (message?.isMessageSentByMe == true ? message?.messageStatus == .seen : (message?.messageStatus == .seen && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded || message?.messageStatus == .received && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded)))  {
            docCurrentIndexPath = indexPath
            presentPreviewScreen()
        }
    }
    
    @objc
    func uploadDownloadDocuments(sender: UIButton) {
        
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }

        let indexPath = getIndexPath(sender: sender)
        let row = indexPath.row
        let section = indexPath.section
        let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row]
        if message?.isMessageSentByMe == true {
            if message?.isCarbonMessage == true {
                if message?.mediaChatMessage?.mediaDownloadStatus == .downloading{
                    message?.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                    if let chatMessage = message {
                        if isStarredMessagePage {
                            if isStarredSearchEnabled == true {
                                starredSearchMessages?[indexPath.row] = chatMessage
                            } else {
                                var messagList = starredMessages
                                messagList[indexPath.row] = chatMessage
                            }
                        } else {
                            chatMessages[indexPath.section][indexPath.row] = chatMessage
                        }
                    }
                    if let cell = chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                        cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView,isDeletedMessageSelected: isDeleteSelected)
                    }
                    FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { [weak self] isSuccess in
                        if message?.messageType == .image {
                            executeOnMainThread { [weak self] in
                                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                                    cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView,isDeletedMessageSelected: self?.isDeleteSelected)
                                }
                            }
                        }
                    }
                } else if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed {
                    message?.mediaChatMessage?.mediaDownloadStatus = .downloading
                    if let chatMessage = message {
                        if isStarredMessagePage {
                            if isStarredSearchEnabled == true {
                                starredSearchMessages?[indexPath.row] = chatMessage
                            } else {
                                var messagList = starredMessages
                                messagList[indexPath.row] = chatMessage
                            }
                        } else {
                            chatMessages[indexPath.section][indexPath.row] = chatMessage
                        }
                    }
                    if let cell = self.chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                        cell.getCellFor(message, at: indexPath, isShowForwardView: self.isShowForwardView,isDeletedMessageSelected: self.isDeleteSelected)
                    }
                    FlyMessenger.downloadMedia(messageId: message?.messageId ?? "") { isSuccess, error, chatMessage in
                    }
                } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                        cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView,isDeletedMessageSelected: isDeleteSelected)
                    }
                }
            } else {
                if message?.mediaChatMessage?.mediaUploadStatus == .uploading{
                    message?.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                    if let chatMessage = message {
                        if isStarredMessagePage {
                            if isStarredSearchEnabled == true {
                                starredSearchMessages?[indexPath.row] = chatMessage
                            } else {
                                var messagList = starredMessages
                                messagList[indexPath.row] = chatMessage
                            }
                        } else {
                            chatMessages[indexPath.section][indexPath.row] = chatMessage
                        }
                    }
                    if let cell = chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                        cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView,isDeletedMessageSelected: isDeleteSelected)
                    }
                    FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { [weak self] isSuccess in
                        if message?.messageType == .image {
                            executeOnMainThread { [weak self] in
                                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                                    cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView,isDeletedMessageSelected: self?.isDeleteSelected)
                                }
                            }
                        }
                    }
                } else if message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message?.mediaChatMessage?.mediaUploadStatus == .failed {
                    documentUpload(sender: sender)
                } else if message?.mediaChatMessage?.mediaUploadStatus == .uploaded {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? SenderDocumentsTableViewCell {
                        cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView,isDeletedMessageSelected: isDeleteSelected)
                    }
                } else if message?.mediaChatMessage?.mediaUploadStatus == .not_available {
                    FlyMessenger.downloadMedia(messageId: message?.messageId ?? "") { isSuccess, error, chatMessage in

                    }
                }
            }
        } else {
            executeOnMainThread { [weak self] in
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ReceiverDocumentsTableViewCell {
                    if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                        executeOnMainThread {
                            cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView,isDeletedOrStarredSelected: self?.isDeleteSelected)
                        }
                        message?.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                        if let chatMessage = message {
                            if self?.isStarredMessagePage == true {
                                if self?.isStarredSearchEnabled == true {
                                    self?.starredSearchMessages?[indexPath.row] = chatMessage
                                } else {
                                    var messagList = self?.starredMessages
                                    messagList?[indexPath.row] = chatMessage
                                }
                            } else {
                                chatMessages[indexPath.section][indexPath.row] = chatMessage
                            }
                        }
                        FlyMessenger.cancelMediaUploadOrDownload(messageId: message?.messageId ?? "") { isSuccess in

                            executeOnMainThread {
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView,isDeletedOrStarredSelected: self?.isDeleteSelected)
                            }
                        }
                    } else if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed {
                        cell.startDownload()
                        message?.mediaChatMessage?.mediaDownloadStatus = .downloading
                        if let chatMessage = message {
                            if self?.isStarredMessagePage == true {
                                if self?.isStarredSearchEnabled == true {
                                    self?.starredSearchMessages?[indexPath.row] = chatMessage
                                } else {
                                    var messagList = self?.starredMessages
                                    messagList?[indexPath.row] = chatMessage
                                }
                            } else {
                                chatMessages[indexPath.section][indexPath.row] = chatMessage
                            }
                        }
                        FlyMessenger.downloadMedia(messageId: message?.messageId ?? "") { isSuccess, error, chatMessage in
                            executeOnMainThread {
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView,isDeletedOrStarredSelected: self?.isDeleteSelected)
                                cell.getCellFor(chatMessage, at: indexPath, isShowForwardView: self?.isShowForwardView,isDeletedOrStarredSelected: self?.isDeleteSelected)
                            }
                        }
                    } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                        cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView,isDeletedOrStarredSelected: self?.isDeleteSelected)
                    }
                }
            }
        }
    }
    
    @objc
    func documentUpload(sender: UIButton) {
        documentUpload(sender: sender) { isSuccess in
        }
    }
    
    private func documentUpload(sender: UIButton, completion: @escaping (Bool?)->()) {
        let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
            guard let message = isStarredMessagePage ? isStarredSearchEnabled == true ? starredSearchMessages?[indexPath.row] : starredMessages[indexPath.row] : chatMessages[indexPath.section][indexPath.row] else {
                return
            }
            if NetworkReachability.shared.isConnected {
                FlyMessenger.uploadMedia(messageId: message.messageId) { isSuccess, error, chatMessage in
                    completion(true)
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
}

extension ChatViewParentController {
    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                break
            case .success:
                setProfile()
            case .failed:
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
}

extension UIApplication {
    /// Checks if view hierarchy of application contains `UIRemoteKeyboardWindow` if it does, keyboard is presented
    var isKeyboardPresented: Bool {
        if let keyboardWindowClass = NSClassFromString("UIRemoteKeyboardWindow"),
           self.windows.contains(where: { $0.isKind(of: keyboardWindowClass) }) {
            return true
        } else {
            return false
        }
    }
}

// To handle user blocked by admin
extension ChatViewParentController {
    
    func checkUserForBlocking(jid : String , isBlocked : Bool) {
        if getProfileDetails.jid == jid && getProfileDetails.profileChatType == .singleChat {
            getProfileDetails.isBlockedByAdmin = isBlocked
            checkUserBlockedByAdmin()
            checkUserBlocked()
            getLastSeen()
            setProfile()
        } else if isBlocked && getProfileDetails.jid == jid && getProfileDetails.profileChatType == .groupChat {
            view.endEditing(true)
            AppAlert.shared.showToast(message: groupNoLongerAvailable)
            navigate()
        }
        AppActionSheet.shared.dismissActionSeet(animated: true)
    }
    
    func getBlockedByAdmin() -> Bool {
        return !isStarredMessagePage ? getProfileDetails.isBlockedByAdmin : false
    }
    
    func getBlocked() -> Bool {
        return ChatManager.getContact(jid: getProfileDetails.jid)?.isBlocked ?? false
    }
    
    func getisBlockedMe() -> Bool {
        return ChatManager.getContact(jid: getProfileDetails.jid)?.isBlockedMe ?? false
    }
    
    func checkUserBlockedByAdmin() {
        let isBlocked = getBlockedByAdmin()
        disableForBlocking(disable: isBlocked)
        hideSendMessageView(isHidden: isBlocked)
        if isBlocked {
            view.endEditing(true)
        }
        scheduleMeetBtn.isHidden = isBlocked
    }
    
    func checkUserBlocked()  {
        if !isStarredMessagePage {
            if getProfileDetails.profileChatType == .singleChat {
                let isBlocked = getBlocked()
                videoButton.isEnabled = isBlocked ? false : true
                audioButton.isEnabled = isBlocked ? false : true
                menuButton.isEnabled = true
                chatTextViewXib?.cannotSendMessageView?.isHidden = isBlocked ? false : true
                if isBlocked {
                    scheduleMeetBtn.isHidden = true
                    showUserIsBlocked()
                    resetReplyView(resignFirstResponder: true)
                }
                getLastSeen()
            }
            
            if getBlockedByAdmin() {
                checkUserBlockedByAdmin()
            }
        }
    }
    
    func disableForBlocking(disable : Bool) {
        videoButton.isEnabled = !disable
        audioButton.isEnabled = !disable
    }
    
    func hideSendMessageView(isHidden : Bool) {
        if !isStarredMessagePage {
            if getProfileDetails.profileChatType == .groupChat {
                let result = isParticipantExist()
                chatTextViewXib?.cannotSendMessageView?.isHidden = result.doesExist ? true : false
                if !(availableFeatures.isGroupChatEnabled) {
                    chatTextViewXib?.cannotSendMessageView?.isHidden =  false
                    chatTextViewXib?.blockedMessageLabel?.text = "Feature unavailable for your plan"
                    disableForBlocking(disable: true)
                    return
                }
                chatTextViewXib?.blockedMessageLabel.text = youCantSendMessagesToThiGroup
            } else {
                chatTextViewXib?.cannotSendMessageView?.isHidden = !isHidden
                chatTextViewXib?.blockedMessageLabel.text = thisUerIsNoLonger
            }
        }
    }
    
    @objc func handleUnblock(gesture: UITapGestureRecognizer) {
        showBlockUnblockConfirmationPopUp()
    }
    
}

extension ChatViewParentController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkUserForBlocking(jid: userJid, isBlocked: isBlocked)
        if getProfileDetails.profileChatType == .groupChat {
            checkMemberOfGroup()
            getGroupMember()
        }
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        checkUserForBlocking(jid: groupJid, isBlocked: isBlocked)
    }

}

// Reporting user or message
extension ChatViewParentController {
    
    private func showBlockUnblockConfirmationPopUp() {
        
        if availableFeatures.isBlockEnabled {
            //showConfirmationAlert
            let username = getUserName(jid : getProfileDetails.jid ,name: getProfileDetails.name, nickName: getProfileDetails.nickName, contactType: getProfileDetails.contactType)
            let alertViewController = UIAlertController.init(title: nil , message: (getBlocked() ) ? "Unblock \(username)?" : "Block \(username)?", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
                self?.dismiss(animated: true,completion: nil)
            }
            let blockAction = UIAlertAction(title: getBlocked() ? ChatActions.unblock.rawValue : ChatActions.block.rawValue, style: .default) { [weak self] (action) in
                if !NetworkReachability.shared.isConnected {
                    AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
                    return
                }
                if !(self?.getBlocked() ?? false) {
                    self?.blockUser()
                } else {
                    self?.UnblockUser()
                }
                self?.resetReplyView(resignFirstResponder: true)
            }
            alertViewController.addAction(cancelAction)
            alertViewController.addAction(blockAction)
            alertViewController.preferredAction = cancelAction
            present(alertViewController, animated: true)
        } else {
            AppAlert.shared.showAlert(view: self, title: "" , message: FlyConstants.ErrorMessage.forbidden, buttonTitle: "OK")
            return
        }
    }
    
    @objc func didTapMenu(_ sender : UIButton) {
//        var values : [String] = getProfileDetails.profileChatType == .singleChat ? [ChatActions.clearAllConversation.rawValue, ChatActions.emailChat.rawValue, ChatActions.report.rawValue, ChatActions.search.rawValue,(getBlocked()) ? ChatActions.unblock.rawValue : ChatActions.block.rawValue] : [ChatActions.clearAllConversation.rawValue, ChatActions.emailChat.rawValue, ChatActions.report.rawValue, ChatActions.search.rawValue]
        
        var values : [String] = []
        
        if getProfileDetails.profileChatType == .singleChat {
            
            if(availableFeatures.isClearChatEnabled){
                values.append(ChatActions.clearAllConversation.rawValue)
            }
            values.append(ChatActions.emailChat.rawValue)
            if(availableFeatures.isReportEnabled){
                values.append(ChatActions.report.rawValue)
            }
            values.append( ChatActions.search.rawValue)
            if(availableFeatures.isBlockEnabled){
                values.append((getBlocked()) ? ChatActions.unblock.rawValue : ChatActions.block.rawValue)
            }
        } else {
            
            if(availableFeatures.isClearChatEnabled){
                values.append(ChatActions.clearAllConversation.rawValue)
            }
            values.append(ChatActions.emailChat.rawValue)
            if(availableFeatures.isReportEnabled){
                values.append(ChatActions.report.rawValue)
            }
            values.append( ChatActions.search.rawValue)
        }
        
        
        if getBlockedByAdmin() {
            values = values.filter({$0 == ChatActions.clearAllConversation.rawValue})
        }
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }
        AppActionSheet.shared.showActionSeet(title: chatActions, message: "", actions: actions) { [weak self] didCancelTap, tappedOption in
            if !didCancelTap {
                switch tappedOption {
                case ChatActions.report.rawValue:
                    if self?.getProfileDetails.contactType == .deleted {
                        AppAlert.shared.showToast(message: unableToReportDeletedUser)
                        return
                    }
                    
                    print("\(tappedOption)")
                    if ChatUtils.isMessagesAvailableFor(jid: self?.getProfileDetails.jid ?? "") {
                        if let profileDetails = self?.getProfileDetails {
                            self?.reportForJid(profileDetails: profileDetails)
                        }
                    } else {
                        AppAlert.shared.showToast(message: noMessgesToReport)
                    }
                case (self?.getBlocked() ?? false) ? ChatActions.unblock.rawValue : ChatActions.block.rawValue:
                    if !NetworkReachability.shared.isConnected {
                        AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
                        return
                    }
                    self?.showBlockUnblockConfirmationPopUp()
                case ChatActions.clearAllConversation.rawValue:
                    self?.showClearChatPicker()

                case ChatActions.search.rawValue:
                    self?.messageSearchEnabled = true
                    self?.messageSearchBar?.isHidden = false
                    self?.messageSearchView.isHidden = false
                    self?.resetReplyView(resignFirstResponder: false)
                    self?.messageSearchBar?.becomeFirstResponder()
                case ChatActions.emailChat.rawValue:
                    if chatMessages.count == 0 {
                        AppAlert.shared.showToast(message: thereIsNoConversation)
                        return
                    }
                    self?.exportChatToEmail()
                default:
                    print(" \(tappedOption)")
                }
            }
        }
    }
    
    func showClearChatConfirm() {
        
        if !FlyMessenger.checkMessagesAvailableTo(jid: getProfileDetails.jid) {
            AppAlert.shared.showToast(message: thereIsNoConversation)
            return
        }
        
        AppAlert.shared.showAlert(view: self, title: message, message: clearChatMessage, buttonOneTitle: clearAll, buttonTwoTitle: cancelUppercase, buttonOneColor: Color.color_FD3B2F, cancelWhenTapOutside: true)
        AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
            if result == 0 {
                ChatManager.clearChat(toJid: self?.getProfileDetails.jid ?? "", chatType: ChatType(rawValue: (self?.getProfileDetails.profileChatType)!.rawValue) ?? ChatType.singleChat, clearChatExceptStarred: false) { isSuccess, error, data in
                    if !isSuccess{
                        AppAlert.shared.alert?.dismiss(animated: false)
                        let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                        AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                        AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                            
                        }
                        return
                    } else {
                        executeOnMainThread {
                            self?.unreadMessagesIdOnMessageReceived = []
                            self?.resetReplyView(resignFirstResponder: true)
                            self?.showOrHideUnreadMessageView(hide: true)
                            chatMessages.removeAll()
                            UIView.performWithoutAnimation {
                                self?.chatTableView.reloadData()
                            }
                            AppAlert.shared.onAlertAction = nil
                        }
                    }
                }
            }
        }
    }
    
    @objc func clearAllMessageWithoutStarred() {

        ChatManager.clearChat(toJid: getProfileDetails.jid ?? "", chatType: ChatType(rawValue: (getProfileDetails.profileChatType).rawValue) ?? ChatType.singleChat, clearChatExceptStarred: true) { isSuccess, error, data in
            if !isSuccess{
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK")
                return
            } else {
                executeOnMainThread { [weak self] in
                    self?.resetData()
                }
            }
        }
        unreadMessagesIdOnMessageReceived = []
    }
    
    @objc func clearAllMessageWithStarred() {

        ChatManager.clearChat(toJid: getProfileDetails.jid ?? "", chatType: ChatType(rawValue: (getProfileDetails.profileChatType).rawValue) ?? ChatType.singleChat, clearChatExceptStarred: false) { isSuccess, error, data in
            if !isSuccess{
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK")
                return
            } else {
                executeOnMainThread { [weak self] in
                    self?.resetData()
                }
            }
        }
        unreadMessagesIdOnMessageReceived = []
    }
    
    func resetData() {
        resetReplyView(resignFirstResponder: true)
        showOrHideUnreadMessageView(hide: true)
        chatMessages.removeAll()
        getInitialMessages()
        AppAlert.shared.onAlertAction = nil
    }
    
    func checkIsMessageStarred() -> Bool {
        var isMessageStarred: [Bool] = []
        chatMessages.forEach { chatMessages in
            isMessageStarred += chatMessages.map({$0.isMessageStarred == true})
        }
        return isMessageStarred.filter({$0 == true}).count > 0
    }
    
    func showClearChatPicker() {
        if checkIsMessageStarred() == false {
           showClearChatConfirm()
        }
        if !FlyMessenger.checkMessagesAvailableTo(jid: getProfileDetails.jid) {
            AppAlert.shared.showToast(message: thereIsNoConversation)
            return
        }
        executeOnMainThread {  [weak self] in
                let deletePicker = DeleteMessageForEveryOneAlertController()
                deletePicker.titleLabel?.text = "Are you sure you want to clear the chat?"
                deletePicker.delegate = self
            deletePicker.isClearAllPopup = true
            deletePicker.isMessageStarred = self?.checkIsMessageStarred()
            deletePicker.deleteForEveryOneButton?.addTarget(self, action: #selector(self?.clearAllMessageWithoutStarred), for: .touchUpInside)
            deletePicker.deleteForMeButton?.addTarget(self, action: #selector(self?.clearAllMessageWithStarred), for: .touchUpInside)
                deletePicker.deleteForMeButton?.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
                deletePicker.deleteForEveryOneButton?.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
                deletePicker.cancelButton?.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
                deletePicker.modalPresentationStyle = .overFullScreen
                self?.present(deletePicker, animated: true)
        }
    }
    
    func showUserIsBlocked() {
            chatTextViewXib?.blockedMessageLabel.attributedText = {
                let attributedString = NSMutableAttributedString(string: "You have blocked \(getUserName(jid : getProfileDetails.jid ,name: getProfileDetails.name, nickName: getProfileDetails.nickName, contactType: getProfileDetails.contactType)).",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: Color.primaryTextColor2,
                                                                              NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
                
                attributedString.append(NSAttributedString(string: "Unblock",
                                                           attributes: [NSAttributedString.Key.foregroundColor: Color.recentChaTimeBlueColor,
                                                                        NSAttributedString.Key.font: UIFont.font15px_appMedium(),
                                                                        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]))
                return attributedString
            }()
            chatTextViewXib?.blockedMessageLabel.numberOfLines = 0
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleUnblock))
            chatTextViewXib?.blockedMessageLabel.addGestureRecognizer(tap)
            chatTextViewXib?.blockedMessageLabel.isUserInteractionEnabled = true
            chatTextViewXib?.blockedMessageLabel.textAlignment = .center
        }
    
    //MARK: BlockUser
    private func blockUser() {
        do {
            try ContactManager.shared.blockUser(for: getProfileDetails.jid) { isSuccess, error, data in
                
                if isSuccess {
                    executeOnMainThread { [weak self] in
                        self?.checkUserBlocked()
                        self?.setProfile()
                        if let getProfileDetails = self?.getProfileDetails {
                            let username = getUserName(jid : getProfileDetails.jid ,name: getProfileDetails.name, nickName: getProfileDetails.nickName, contactType: getProfileDetails.contactType)
                            AppAlert.shared.showToast(message: "\(username) has been Blocked")
                        }
                    }
                }else {
                    let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                    AppAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK")
                    return
                }
            }
        } catch let error as NSError {
            print("block user error: \(error)")
        }
    }
    
    //MARK: UnBlockUser
    private func UnblockUser() {
        do {
            try ContactManager.shared.unblockUser(for: getProfileDetails.jid) { isSuccess, error, data in
                if isSuccess {
                    executeOnMainThread { [weak self] in
                        self?.checkUserBlocked()
                        self?.setProfile()
                        if let getProfileDetails = self?.getProfileDetails {
                            let username = getUserName(jid : getProfileDetails.jid ,name: getProfileDetails.name, nickName: getProfileDetails.nickName, contactType: getProfileDetails.contactType)
                            AppAlert.shared.showToast(message: "\(username) has been Unblocked")
                        }
                    }
                } else {
                    let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                    AppAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK")
                    return
                }
            }
        } catch let error as NSError {
            print("block user error: \(error)")
        }
    }
    
    func didTapReportInMessage(chatMessge : ChatMessage) {
        if let profileDetails = self.getProfileDetails {
            self.reportFromMessage(chatMessage: chatMessge, profileDetail: profileDetails)
        }
    }
}

extension ChatViewParentController : RefreshProfileInfo {
    func refreshProfileDetails(profileDetails:ProfileDetails?) {
        if getProfileDetails.jid == profileDetails?.jid{
            getProfileDetails = profileDetails
            setProfile()
            setGroupMemberInHeader()
        }
    }
}

extension ChatViewParentController : GroupInfoDelegate {
    func didComefromGroupInfo() {
        getInitialMessages()
    }
}

extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }
    
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
    
    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}

//Handling Audio Recording View
extension ChatViewParentController {

    private func showAudioRecordingUI(show : Bool) {
        if let chatTextView = chatTextViewXib {
            chatTextView.audioRecordView?.isHidden = !show
            intializeSlideTrailling()
            if show {
                showAudioRecording()
            }
        }
    }
    
    
    private func setUpAudioRecordView() {
        if let chatTextView = chatTextViewXib {
            
            chatTextView.audioRecordView?.isHidden = true
            
            chatTextView.audioRecordingInfoView.layer.cornerRadius = 20
            chatTextView.audioRecordingInfoView.layer.borderWidth = 0.5
            chatTextView.audioRecordingInfoView.layer.borderColor = Color.borderColor?.cgColor
            
            let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onTouchSlideCancel(_:)))
            chatTextView.audioSlideCancelView.addGestureRecognizer(gestureRecognizer)
            chatTextView.audioSlideCancelView.isUserInteractionEnabled = true
            
            chatTextView.audioHiddenRecordButton.addTarget(self, action: #selector(didTapAudioAnimatedButton(sender:)), for: .touchUpInside)
            chatTextView.audioRecordButton.addTarget(self, action: #selector(didTapAudioAnimatedButton(sender:)), for: .touchUpInside)
            chatTextView.audioSendButton.addTarget(self, action: #selector(didTapAudioSendButton(sender:)), for: .touchUpInside)
            chatTextView.audioCancelButton.addTarget(self, action: #selector(didTapAudioCancelButton(sender:)), for: .touchUpInside)
            chatTextView.audioButton.addTarget(self, action: #selector(didTapAudioButton(sender:)), for: .touchUpInside)
            addObserverForEnterBackground()
        }
    }
    
    @objc private func didTapAudioAnimatedButton(sender : UIButton) {
        handleAudioRecordMaximumTimeReached()
    }
    
    @objc private func didTapAudioSendButton(sender : UIButton) {
        
        if audioRecordingDuration < 1.0 {
            AppAlert.shared.showToast(message: recordingIsTooSmall)
            resetAudioRecording(isCancel: true)
            return
        }
        
        if isAudioMaximumTimeReached {
            isAudioMaximumTimeReached = false
            showAudioRecordingUI(show: false)
            if let recordedAuidoUrl = recordedAuidoUrl {
                sendAudio(fileUrl: recordedAuidoUrl, isRecorded: true)
            }
            resetAudioRecording(isCancel: false)
        } else {
            didTapSendAudioButton = true
            recorder.stopRecording()
        }
        
        messageTextView?.text = ""
        resetMessageTextView()
        tableViewBottomConstraint?.constant = 55
    }
    
    @objc private func didTapAudioCancelButton(sender : UIButton) {
        resetAudioRecording(isCancel: true)
    }
    
    
    @objc private func didTapAudioButton(sender : UIButton) {
        resetGroupMention()
        mentionBaseView.isHidden = true
        let didCallCome = didCallCome
        checkUserBusyStatusEnabled(self) { [weak self] status in
            executeOnMainThread {
                if status {
                    if CallManager.isOngoingCall() || CallManager.checkForActiveCall() || didCallCome {
                        AppAlert.shared.showToast(message: cannotRecordAudioDuringCall)
                        return
                    }
                    self?.checkForMicroPhonePermission()
                    self?.view.endEditing(true)
                }
            }
        }
    }
    
    private func checkForMicroPhonePermission() {
        AppPermissions.shared.checkMicroPhonePermission { [weak self] status in
            switch status {
            case .granted:
                executeOnMainThread {
                    self?.audioPermission()
                    self?.showAudioRecordingUI(show: true)
                }
                break
            case .denied, .undetermined:
                AppPermissions.shared.presentSettingsForPermission(permission: .microPhone, instance: self as Any)
                break
            default:
                AppPermissions.shared.presentSettingsForPermission(permission: .microPhone, instance: self as Any)
                break
            }
        }
    }
    
    private func showAudioRecording() {
        if let chatTextView = chatTextViewXib {
            disableIdleTimer(disable: true)
            if let audioPlayer = audioPlayer, let audioIndexPath = currenAudioIndexPath, let audioUrl = currentAudioUrl {
                if audioPlayer.isPlaying {
                    audioPlayerSetup(indexPath: audioIndexPath, audioUrl: audioUrl)
                }
            }
            chatTextView.audioDurationMicIcon.isHidden = true
            chatTextView.audioCancelButton.isHidden = true
            chatTextView.audioSendButton.isHidden = true
            chatTextView.audioSlideCancelView.isHidden = false
            chatTextView.audioRecordButton.isHidden = false
            chatTextView.audioHiddenRecordButton.isHidden = false
            
            invalidateAnimationTimer()
            audioButtonTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(animateAudioRecordButton), userInfo: nil, repeats: true)
            RunLoop.main.add(audioButtonTimer, forMode: RunLoop.Mode.common)
            intializeSlideTrailling()
            
            rightMaximumPosition = chatTextView.audioRecordingInfoView.viewWidth - (chatTextView.audioSlideViewWidth.constant + chatTextView.audioSlideViewTrailing.constant)
            
            chatTextView.audioDurationLeading.constant = 0
            chatTextView.audioDurionMicLeading.constant = 0
            
            recorder.record()
            resetMessageTextView()
            
            if isReplyViewOpen {
                tableViewBottomConstraint?.constant = 135
            } else  {
                tableViewBottomConstraint?.constant = 50
            }
           
        }
        
    }
    
    private func invalidateAnimationTimer() {
        audioButtonTimer.invalidate()
    }
    
    @objc private func animateAudioRecordButton() {
        if let chatTextView = chatTextViewXib {
            UIButton.animate(withDuration: 0.5, animations: {() -> Void in
                chatTextView.audioRecordButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }, completion: {(_ finished: Bool) -> Void in
                UIView.animate(withDuration: 0.5, animations: {() -> Void in
                    chatTextView.audioRecordButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                })
            })
        }
    }
    
    private func udpateAudioRcordingTime(duration : CGFloat) {
        if let chatTextView = chatTextViewXib {
            chatTextView.audioDurationLabel.text = duration.timeStringFormatter
        }
    }
    
    private func resetAudioRecording(isCancel : Bool) {
        if isCancel {
            didTapSendAudioButton = false
            recorder.stopRecording()
            recorder.deleteRecording(name: recordedAudioFileName)
        }
        recordedAudioFileName = ""
        disableIdleTimer(disable: false)
        audioRecordingDuration = 0.0
        if let chatTextView = chatTextViewXib {
            chatTextView.audioDurationLabel.text = "00:00"
        }
        invalidateAnimationTimer()
        showAudioRecordingUI(show: false)
        
        if((messageTextView?.text.isBlank ?? false) || messageTextView?.text == startTyping.localized) {
            messageTextViewHeight!.constant = 40
            textToolBarViewHeight!.constant = 50
        } else {
            messageTextViewHeight!.constant = currentMessageTextViewHeight
            textToolBarViewHeight!.constant = currentToolBarViewHeight
        }
    
        resizeMessageTextView()
    }
    
    private func intializeSlideTrailling() {
        if let chatTextView = chatTextViewXib {
            chatTextView.audioSlideViewTrailing.constant = 8
        }
    }
    
    private func handleAudioRecordMaximumTimeReached() {
        isAudioMaximumTimeReached = true
        recorder.stopRecording()
        showAudioCancelling()
    }
    
    private func showAudioCancelling() {
        invalidateAnimationTimer()
        if let chatTextView = chatTextViewXib {
            
            chatTextView.audioDurationLeading.constant = 7
            chatTextView.audioDurionMicLeading.constant = 17
            
            chatTextView.audioDurationMicIcon.isHidden = false
            chatTextView.audioCancelButton.isHidden = false
            chatTextView.audioSendButton.isHidden = false
            
            chatTextView.audioRecordButton.isHidden = true
            chatTextView.audioHiddenRecordButton.isHidden = true
            chatTextView.audioSlideCancelView.isHidden = true
        }
    }
    
    private func addObserverForEnterBackground() {
        NotificationCenter.default.addObserver(self, selector: #selector(didiAppEnterBackground(_:)), name: Notification.Name(rawValue: didEnterBackground), object: nil)
    }
    
    @objc private func didiAppEnterBackground(_ notification : Notification) {
        handleAudioRecordMaximumTimeReached()
        AppActionSheet.shared.dismissActionSeet(animated: true)
    }
    
    @objc private func onTouchSlideCancel(_ gestureRecognizer: UIGestureRecognizer) {
        if let touchedView = gestureRecognizer.view {
            if gestureRecognizer.state == .changed {
                let locationInView = gestureRecognizer.location(in: touchedView)
                
                var newPos = touchedView.frame.origin.x + locationInView.x
                
                // limit the scrolls to the edges of the parent view
                if newPos < leftMaximumPosition {
                    newPos = leftMaximumPosition
                } else if newPos > rightMaximumPosition {
                    newPos = rightMaximumPosition
                }
                
                touchedView.frame.origin.x = newPos
                
                //                  let diff = 100.0 - touchedView.frame.origin.x
                //                  cancelTxt.alpha = diff / 100
                
                if newPos == leftMaximumPosition {
                    debugPrint("cancel Audio recording")
                    touchedView.frame.origin.x = rightMaximumPosition
                    gestureRecognizer.state = .ended
                    resetAudioRecording(isCancel: true)
                }
                
            } else if gestureRecognizer.state == .ended {
                touchedView.frame.origin.x = rightMaximumPosition
            }
            
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
}

extension ChatViewParentController : AppAudioRecorderDelegate {
    func whileRunningTimer(duration: CGFloat) {
        executeOnMainThread { [weak self] in
            self?.udpateAudioRcordingTime(duration: duration)
            self?.audioRecordingDuration = duration
            if duration == audioRecordingMximumDuration {
                AppAlert.shared.showToast(message: recordingReachedMaximumTime)
                self?.handleAudioRecordMaximumTimeReached()
            }
            print("AppAudioRecorderDelegate whileRunningTimer \(duration)")
        }
    }
    
    func didStartRecording(fileName: String) {
        checkAudioRecording()
        recordedAudioFileName = fileName
        print("AppAudioRecorderDelegate didStartRecording \(fileName)")
    }
    
    func didFinishRecording(url: URL) {
        print("AppAudioRecorderDelegate didFinishRecording \(url.absoluteString)")
        checkAudioRecording()
        if isAudioMaximumTimeReached {
            recordedAuidoUrl = url
        } else if didTapSendAudioButton {
            sendAudio(fileUrl : url, isRecorded: true)
            didTapSendAudioButton = false
            resetAudioRecording(isCancel: false)
        }
       
    }
    
    func didErrorOccur() {
        print("AppAudioRecorderDelegate didErrorOccur")
    }
    
    func checkAudioRecording() {
        if recorder.isRecording == true {
            audioButton.isUserInteractionEnabled = false
            videoButton.isUserInteractionEnabled = false
        } else {
            audioButton.isUserInteractionEnabled = true
            videoButton.isUserInteractionEnabled = true
        }
    }
    
}

extension ChatViewParentController {
    override func didCallAnswered() {
        print("ChatViewParentController UI didCallAnswered")
        didCallCome = false
        if recorder.isRecording {
            handleAudioRecordMaximumTimeReached()
        }
    }
    
    override func whileDialing() {
        print("ChatViewParentController UI whileDialing")
        didCallCome = false
    }
    
    override func didCallDisconnected() {
        print("ChatViewParentController UI didCallDisconnected")
        didCallCome = false
    }
    
    override func whileIncoming() {
        print("ChatViewParentController UI whileIncoming")
        didCallCome = true
        if recorder.isRecording {
            handleAudioRecordMaximumTimeReached()
        }
    }
}


extension ChatViewParentController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isStarredMessagePage {
            let position  = scrollView.contentOffset.y
            print("#scroll previousMessagesLoadingDone y \(position) \(chatTableView.contentSize.height) || \(scrollView.frame.size.height) \(chatTableView.contentSize.height * 0.7)")
            
            if position > (chatTableView.contentSize.height/5) {
                DispatchQueue.main.async { [weak self] in
                    self?.handleUnreadMessageWhileScrolling()
                }
                if previousMessagesLoadingDone{
                    return
                }
                if !previousMessagesLoadingDone && !isPreviousMessagesLoadingInProgress{
                    backgroundQueue.async { [weak self] in
                        self?.loadPreviousMessage()
                    }
                    
                    isPreviousMessagesLoadingInProgress = true
                    previousMessagesLoadingDone = false
                }
            }
            
            if position < (chatTableView.contentSize.height * 0.7) {
                
                print("#scroll #load #bottom  \(position)  \(scrollView.frame.size.height)")
                DispatchQueue.main.async { [weak self] in
                    self?.handleUnreadMessageWhileScrolling()
                }
                if nextMessagesLoadingDone{
                    return
                }
                if !nextMessagesLoadingDone && !isNextMessagesLoadingInProgress && !scrollToTappedMessage{
                    backgroundQueue.async { [weak self] in
                        self?.loadNextMessage()
                    }
                    isNextMessagesLoadingInProgress = true
                    nextMessagesLoadingDone = false
                }
            }
        }
    }
    
    public func loadPreviousMessage(){
        fetchMessageListQuery?.setFirstMessage(messageId: chatMessages.last?.last?.messageId ?? emptyString())
        fetchMessageListQuery?.loadPreviousMessages(completionHandler: {[weak self] isSuccess, error, data in
            guard let self else {return}
            var result = data
            if isSuccess{
                print("#scroll loadPreviousMessages success")
                if let chatMessages = result.getData() as? [ChatMessage]{
                    self.groupOldMessages(messages: chatMessages)
                    if self.availableFeatures.isChatHistoryEnabled && CommonDefaults.chatHistoryEnabled {
                        if chatMessages.isEmpty {
                            self.previousMessagesLoadingDone = true
                        } else {
                            self.previousMessagesLoadingDone = false
                        }
                    } else if chatMessages.count < self.fetchMessageListParams.limit {
                        self.previousMessagesLoadingDone = true
                    }
                }
            }
            if !(self.fetchMessageListQuery?.hasPreviousMessages() ?? false){
                self.previousMessagesLoadingDone = true
            }
            self.isPreviousMessagesLoadingInProgress = false
        })
    }
    
    
    public func loadNextMessage(){
        fetchMessageListQuery?.loadNextMessages(completionHandler: {[weak self] isSuccess, error, data in
            var result = data
            if isSuccess{
                print("#scroll loadNextMessages success")
                if let chatMessages = result.getData() as? [ChatMessage]{
                    self?.groupLatestMessages(messages: chatMessages)
                }
            }
            if !(self?.fetchMessageListQuery?.hasNextMessages() ?? false){
                self?.nextMessagesLoadingDone = true
            }
            self?.isNextMessagesLoadingInProgress = false
        })
    }
    
}

class CustomPreviewItem: NSObject, QLPreviewItem {
     
     var previewItemURL: URL?
     var previewItemTitle: String?
     
     init(url: URL?, title: String?) {
         previewItemURL = url
         previewItemTitle = title
     }
}

extension ChatViewParentController : DeleteMessageButtonAction {
    func clearAllWithStarred() {
        clearAllMessageWithStarred()
    }
    
    func clearAllWithOutStarred() {
        clearAllMessageWithoutStarred()
    }
    
    func deleteForEveryOneButtonTapped() {
        messageTextView?.resignFirstResponder()
        deleteMessageForEveryOne()
        stopAudioPlayer()
    }
    
    func closeButtonTapped() {
        dismiss()
    }
    
    func deleteForMeButtonTapped() {
        messageTextView?.resignFirstResponder()
        if isStarredMessagePage {
            isStarredDeleteMessageForMe()
        } else {
            deleteMessageForMe()
        }
        stopAudioPlayer()
    }
}

extension ChatViewParentController {
    private func updateFavMessages(indexPath: IndexPath) {
        multipleSelectionTitle = starTitle
        refreshBubbleImageView(indexPath: indexPath, isSelected: true,title: multipleSelectionTitle)
    }
    
    private func showHideEmptyView() {
        if isStarredMessagePage {
            if isStarredSearchEnabled ?? false && starredSearchMessages?.count == 0 {
                self.emptyMessageLabel.text = "No results found"
            } else {
                self.emptyMessageLabel.text = "No Messages found"
            }
            self.emptyMessageView?.isHidden = isStarredSearchEnabled == true ? starredSearchMessages?.count == 0 ? false : true : starredMessages.count == 0 ? false : true
        } else {
            self.emptyMessageView?.isHidden = true
        }
    }
    
    private func showHideTextToolBarView() {
        if isStarredMessagePage {
            textToolBarView?.isHidden = true
        }
    }
    
    private func setStarOrUnStarredMessages() {
        if selectedMessages?.count == 0 {
            return
        }
        
        if isStarredMessagePage {
            tableViewBottomConstraint?.constant = 0
            chatTextView?.isHidden = true
        }
        
        let isStar = checkforStar(selectedMessages: selectedMessages ?? [])
        let messageIds = selectedMessages?.compactMap({$0.chatMessage.messageId})
        let chatUserId = selectedMessages?.compactMap({$0.chatMessage.chatUserJid}).first ?? ""
        messageIds?.enumerated().forEach({ (index,messageId) in
            chatViewModel?.updateFavouriteStatus(messageId: messageId, chatUserId: chatUserId, isFavourite: isStar, chatType: isStarredMessagePage ? .singleChat : getProfileDetails.profileChatType) { [weak self] (isSuccess, flyError, resDict) in
                
                if isSuccess {
                    
                    chatMessages.enumerated().forEach { (section,messages) in
                        messages.enumerated().forEach { (row,message) in
                            if message.messageId == messageId {
                                chatMessages[section][row].isMessageStarred = isStar
                                self?.chatTableView?.reloadRows(at: [IndexPath(row: row, section: section)], with: .none)
                            }
                        }
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.selectedMessages?.removeAll()
                        self?.isShowForwardView = false
                        self?.showHideForwardView()
                        UIView.performWithoutAnimation {
                            self?.chatTableView.reloadData()
                        }
                        self?.showHideEmptyView()
                    }
                }else {
                    let message = AppUtils.shared.getErrorMessage(description: flyError?.description ?? "")
                    AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                    
                }
            }
            
            
        })
    }
}

@available(iOS 16.0, *)
extension ChatViewParentController: UIEditMenuInteractionDelegate {
    
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration,
                             suggestedActions: [UIMenuElement]) -> UIMenu? {
        let configID = configuration.identifier as! String
        switch configID {
        case "replyConfig":
            let replyElement = UIAction(title: "Reply", subtitle: nil, image: UIImage(systemName: "replyIcon"), identifier: nil,
                                        discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: .on, handler: { [weak self] action in
                self?.replyItemAction()
            })
            longPressActions.append(replyElement)
        case "forwardconfig":
            let forwardElement = UIAction(title: "Forward", subtitle: nil, image: nil, identifier: nil,
                                          discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: .on, handler: { [weak self] action in
                self?.forwardItemAction()
                self?.stopAudioPlayer()
            })
            longPressActions.append(forwardElement)
        case "starConfig":
            let forwardElement = UIAction(title: "Star", subtitle: nil, image: nil, identifier: nil,
                                          discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: .on, handler: { [weak self] action in
                self?.starredItemAction()
                self?.stopAudioPlayer()
            })
            longPressActions.append(forwardElement)
        case "copyConfig":
            let infoElement = UIAction(title: "Copy", subtitle: nil, image: nil, identifier: nil,
                                         discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: .on, handler: { [weak self] action in
                self?.copyItemAction()
            })
            longPressActions.append(infoElement)
        case "reportConfig":
            let reportElement = UIAction(title: "Report", subtitle: nil, image: nil, identifier: nil,
                                         discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: .on, handler: { [weak self] action in
                self?.reportItemAction()
            })
            longPressActions.append(reportElement)
        case "deleteConfig":
            let deleteElement = UIAction(title: "Delete", subtitle: nil, image: nil, identifier: nil,
                                         discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: .on, handler: { [weak self] action in
                self?.deleteItemAction()
                self?.stopAudioPlayer()
            })
            longPressActions.append(deleteElement)
        case "infoConfig":
            let infoElement = UIAction(title: "Info", subtitle: nil, image: nil, identifier: nil,
                                       discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: .on, handler: { [weak self] action in
                self?.infoItemAction(dismissClosure: self?.getInitialMessages)
            })
            longPressActions.append(infoElement)
        default:
            break
        }
        return UIMenu(children: longPressActions as! [UIMenuElement])
    }
    
}

extension ChatViewParentController : RefreshChatDelegate {
    func refresh() {
        executeOnMainThread { [weak self] in
            UIView.performWithoutAnimation {
                self?.chatTableView.reloadData()
            }
        }
    }
}

extension ChatViewParentController {

    func checkUserBusyStatusEnabled(_ controller: UIViewController, completion: @escaping (Bool)->()) {
        if ChatManager.shared.isBusyStatusEnabled() && getProfileDetails.profileChatType == .singleChat {
            let alertController = UIAlertController.init(title: "Disable busy Status. Do you want to continue?" , message: "", preferredStyle: .alert)
            let forwardAction = UIAlertAction(title: "Yes", style: .default) {_ in
                if NetStatus.shared.isConnected {
                    ChatManager.shared.enableDisableBusyStatus(!ChatManager.shared.isBusyStatusEnabled()) {
                        isSuccess,error,data in
                        var result = data
                        if isSuccess {
                            completion(isSuccess)
                        } else {
                            AppAlert.shared.showToast(message: result.getMessage() as! String)
                            completion(false)
                        }
                    }
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            }
            let cancelAction = UIAlertAction(title: "No", style: .cancel) { [weak controller] (action) in
                controller?.dismiss(animated: true,completion: nil)
                completion(false)
            }
            forwardAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            cancelAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            alertController.addAction(cancelAction)
            alertController.addAction(forwardAction)
            executeOnMainThread { [weak controller] in
                controller?.present(alertController, animated: true)
            }
        } else {
            completion(true)
        }
    }
}

extension ChatViewParentController : AvailableFeaturesDelegate {
    
    func didUpdateAvailableFeatures(features: AvailableFeaturesModel) {
        
        availableFeatures = features
        
        if !isStarredMessagePage {
            updateSubViews()
        }else{
            if !availableFeatures.isStarMessageEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    AppAlert.shared.showAlert(view: self!, title: "" , message: FlyConstants.ErrorMessage.forbidden, buttonTitle: "OK")
                }
                navigationController?.popViewController(animated: true)
            }
        }

        let tabCount =  MainTabBarController.tabBarDelegagte?.currentTabCount()
        
        if (!(availableFeatures.isGroupCallEnabled || availableFeatures.isOneToOneCallEnabled) && tabCount == 5) {
            MainTabBarController.tabBarDelegagte?.removeTabAt(index: 2)
        }else {
            
            if ((availableFeatures.isGroupCallEnabled || availableFeatures.isOneToOneCallEnabled) && tabCount ?? 0 < 5){
                MainTabBarController.tabBarDelegagte?.resetTabs()
            }
        }
    }
    func resetViews(){
        
        isShareMediaSelected = false
        isShowForwardView = false
        if !isStarredMessagePage {
            textToolBarView?.isHidden = false
        } else {
            showHideMutiSelectionView()
        }
        forwardBottomView?.isHidden = true
        selectedMessages?.removeAll()
        UIView.performWithoutAnimation {
            chatTableView.reloadData()
        }
    }
}

extension ChatViewParentController {
    
    func updateSubViews() {
        
        checkMemberOfGroup()
        chatTextViewXib?.audioButton.isHidden = (!(availableFeatures.isAudioAttachmentEnabled) || self.isMessageEditing) ? true : false
        attachmentButton.isHidden = (!(availableFeatures.isAttachmentEnabled) || (!(availableFeatures.isImageAttachmentEnabled) && !(availableFeatures.isVideoAttachmentEnabled) && !(availableFeatures.isAudioAttachmentEnabled) && !(availableFeatures.isLocationAttachmentEnabled) && !(availableFeatures.isContactAttachmentEnabled) && !(availableFeatures.isDocumentAttachmentEnabled))) ? true : false

        if (!availableFeatures.isOneToOneCallEnabled || !availableFeatures.isGroupCallEnabled) {
            scheduleMeetBtn.removeFromSuperview()
        }
        if (availableFeatures.isOneToOneCallEnabled || availableFeatures.isGroupCallEnabled) {
            self.view.addSubview(scheduleMeetBtn)
            self.view.bringSubviewToFront(scheduleMeetBtn)
        }
        
        if self.presentedViewController as? UIAlertController != nil && !(availableFeatures.isAttachmentEnabled){
            self.dismiss()
        }
        
        if getProfileDetails.profileChatType == .groupChat {
            audioButton.isHidden = !(availableFeatures.isGroupCallEnabled) ? true : false
            videoButton.isHidden = !(availableFeatures.isGroupCallEnabled) ? true : false
            
        }else {
            audioButton.isHidden = !(availableFeatures.isOneToOneCallEnabled) ? true : false
            videoButton.isHidden = !(availableFeatures.isOneToOneCallEnabled) ? true : false
        }
        
    }
    
    
    func getIndexPath(sender: UIView) -> IndexPath {
        
        let currentIndex = chatTableView.indexPathForView(sender)
        return currentIndex ?? IndexPath()
    }
}

// For unread messages
extension ChatViewParentController {
    
    private func initializeUnreadMessage() {
        showOrHideUnreadMessageView(hide: true)
        unreadMessageView.roundCorners(corners: [.allCorners], radius: 20)
        unreadMessageIdFromDB = ChatManager.shared.getUnreadMessages(toJid: getProfileDetails.jid, messageId: getUnreadMessageId())
    }
    
    private func handleUnreadMessageWhileScrolling() {
        if let indexPath = chatTableView.indexPathsForVisibleRows?.first {
            if chatMessages.count > 0 {
                if indexPath.row < chatMessages[indexPath.section].count {
                    print("#handleUnreadMessageWhileScrolling Section \(indexPath.section) Row \(indexPath.row) Count \(chatMessages[indexPath.section].count)")
                    let messageId = chatMessages[indexPath.section][indexPath.row].messageId
                    if unreadMessagesIdOnMessageReceived.contains(messageId) {
                        unreadMessagesIdOnMessageReceived = unreadMessagesIdOnMessageReceived.filter({$0 != messageId})
                    }
                    
                    if unreadMessageIdFromDB.contains(messageId) {
                        unreadMessageIdFromDB = unreadMessageIdFromDB.filter({$0 != messageId})
                    }
                    setUnreadCountInUnreadView()
                }
            }
        }
    }
    
    private func resetUnreadMessages(){
        showOrHideUnreadMessageView(hide: true)
      //  deleteUnreadNotificationFromDB()
        unreadMessagesIdOnMessageReceived.removeAll()
        removeUnreadMessageLabelFromChat()
        if chatTableView.visibleCells.isEmpty || chatMessages.isEmpty {
            return
        }
        let indexPath = IndexPath(row: 0, section: 0)
        chatTableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    private func removeUnreadMessageLabelFromChat() {
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == getUnreadMessageId()}) {
            chatMessages[indexPath.section].remove(at: indexPath.row)
            chatTableView.deleteRows(at: [indexPath], with: .none)
            deleteUnreadNotificationFromDB()
            UIView.performWithoutAnimation {
                chatTableView.reloadData()
            }
        }
    }
    
    private func deleteUnreadNotificationFromDB() {
        FlyMessenger.shared.deleteUnreadMessageSeparatorOfAConversation(jid: getProfileDetails.jid)
    }
    
    private func isUnreadMessagesExist() -> Bool {
       return ChatManager.shared.checkUnreadNotificationMessage(chatUserJid: getProfileDetails.jid)
    }
    
    private func getUnreadMessageId() -> String {
        return ChatManager.shared.getUnreadNotificationMessageId(chatUserJid: getProfileDetails.jid)
    }
    
    private func showOrHideUnreadMessageView(hide : Bool) {
        unreadMessageView.isHidden = hide
    }
     
    private func getUnreadMessagesFromDB() -> [String] {
        return ChatManager.shared.getUnreadMessages(toJid: getProfileDetails.jid, messageId: getUnreadMessageId())
    }
    
    private func getUnreadMessages() -> [String]{
        return unreadMessageIdFromDB
    }
    
    private func checkUnreadMessage() {
        if isUnreadMessagesExist() {
            if let indexPath = getIndexPathOfUnreadMessageLabel() {
                executeOnMainThread { [weak self] in
                    self?.chatTableView.scrollToRow(at: indexPath, at: .top, animated: false)
                    self?.setUnreadCountInUnreadView()
                    self?.chatTableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        } else {
            showOrHideUnreadMessageView(hide: true)
        }
    }
    
    private func getIndexPathOfUnreadMessageLabel() -> IndexPath? {
        return chatMessages.indexPath(where: {$0.messageId == getUnreadMessageId()})
    }
    
    private func setUnreadCountInMessage() {
        let unreadMessageId = getUnreadMessageId()
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == unreadMessageId}) {
            chatMessages[indexPath.section][indexPath.row].messageTextContent = "\(getUnreadMessages().count) New messages"
        }
    }
    
    private func updateUnreadMessageCount(messageId : String) {
        if let indexPath = chatTableView.indexPathsForVisibleRows?.first {
            if indexPath.row > 0 {
                if !unreadMessagesIdOnMessageReceived.contains(messageId) {
                    unreadMessagesIdOnMessageReceived.append(messageId)
                    handleUnreadMessageWhileScrolling()
                    setUnreadCountInUnreadView()
                } else {
                    unreadMessagesIdOnMessageReceived = unreadMessagesIdOnMessageReceived.filter({$0 != messageId})
                    setUnreadCountInUnreadView()
                }
            }
        }
    }
    
    private func setUnreadCountInUnreadView() {
        let unreadCount = unreadMessagesIdOnMessageReceived.count
        unreadMessageLabel.text = "\(unreadCount) New messages"
        
        if unreadMessageView.isHidden && unreadCount > 0 {
            showOrHideUnreadMessageView(hide: false)
        } else if unreadCount == 0  && !unreadMessageView.isHidden {
            showOrHideUnreadMessageView(hide: true)
        }
        
        if unreadMessagesIdOnMessageReceived.isEmpty {
            showOrHideUnreadMessageView(hide: true)
        }
    }
}

extension ChatViewParentController {
    
    func scrollToSelectedMessage() {
        if selectedMessageId?.isNotEmpty == true {
            let indexPath = chatMessages.indexPath(where: {$0.messageId == selectedMessageId})
            if chatMessages.count > 0 && indexPath != nil {
                chatTableView.scrollToRow(at: indexPath!, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    if let cell = self?.chatTableView.cellForRow(at: indexPath!) {
                        cell.contentView.backgroundColor = Color.cellSelectionColor
                        self?.updateSelectionColor(indexPath: indexPath!)
                    }
                }
            }
        }
    }
}

extension ChatViewParentController {
    private func isStarredDeleteMessageForMe() {
        selectedMessages?.forEach({ message in
            deleteViewModel?.getDeleteMessageForMe(jid: message.chatMessage.chatUserJid , messageIdList: [message.chatMessage.messageId], deleteChatType: message.chatMessage.messageChatType) { [weak self] (isSuccess, error, data) in
                
                if !isSuccess{
                    AppAlert.shared.alert?.dismiss(animated: false)
                    let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                    AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                    AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                        self?.resetViews()
                    }
                    return
                }else {
                    // self?.unArchiveChatOnEvents(jids: [message.chatMessage.chatUserJid])
                    self?.isShowForwardView = false
                    DispatchQueue.main.async {
                        self?.clearMessages()
                        self?.dismiss()
                        self?.showHideEmptyView()
                    }
                }
            }
        })
        DispatchQueue.main.async {
            self.selectedMessages?.removeAll()
        }
    }
    
    private func showHideMutiSelectionView() {
        if isShowForwardView == true {
            tableViewBottomConstraint?.constant = 50.0
        } else {
            tableViewBottomConstraint?.constant = 10.0
        }
    }
}
    
//Message Search

extension ChatViewParentController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if isStarredMessagePage {
            if searchText.trim().count > 0 {
                if searchText.trim().isEmpty {
                    UIView.performWithoutAnimation {
                        chatTableView?.reloadData()
                    }
                    isStarredSearchEnabled = false
                } else {
                    isStarredSearchEnabled = true
                    starredSearchMessages = starredMessages.filter({
                        
                        let receiverName = getUserName(jid : $0.chatUserJid ,name: ChatManager.profileDetaisFor(jid: $0.chatUserJid )?.name ?? "", nickName: ChatManager.profileDetaisFor(jid: $0.chatUserJid )?.nickName ?? "", contactType: ChatManager.profileDetaisFor(jid: $0.chatUserJid )?.contactType ?? .local)
                        let senderName = getUserName(jid : $0.chatUserJid ,name: ChatManager.profileDetaisFor(jid: $0.senderUserJid)?.name ?? "", nickName: ChatManager.profileDetaisFor(jid: $0.senderUserJid )?.nickName ?? "", contactType: ChatManager.profileDetaisFor(jid: $0.senderUserJid )?.contactType ?? .local)
                        
                        let myName = ContactManager.getMyProfile().name
                        
                        return ((myName == senderName ? "" : senderName.lowercased()).localizedCaseInsensitiveContains(searchText.lowercased()) ||
                                (myName == receiverName ? "" : receiverName.lowercased()).localizedCaseInsensitiveContains(searchText.lowercased()) ||
                                "You".localizedCaseInsensitiveContains(searchText.lowercased()) ||
                                $0.mediaChatMessage?.mediaCaptionText.lowercased().localizedCaseInsensitiveContains(searchText.lowercased()) ?? false ||
                                $0.messageTextContent.lowercased().localizedCaseInsensitiveContains(searchText.lowercased()) ||
                                ($0.contactChatMessage != nil && $0.contactChatMessage?.contactName.lowercased().localizedCaseInsensitiveContains(searchText.lowercased()) ?? false) ||
                                ($0.mediaChatMessage != nil && $0.mediaChatMessage?.messageType == .document &&  $0.mediaChatMessage?.mediaFileName.lowercased().localizedCaseInsensitiveContains(searchText.lowercased()) ?? false))
                    })
                }
                chatTableView.scrollsToTop = true
                UIView.performWithoutAnimation {
                    chatTableView.reloadData()
                }
            } else {
                isStarredSearchEnabled = false
                UIView.performWithoutAnimation {
                    chatTableView?.reloadData()
                }
            }
            showHideEmptyView()
            
            
        } else {
            showHideEmptyView()
            currentHighlightedIndex = nil
            currentSelectedIndexPath = nil
            currentHighlightedIndexPath = nil
            isSearchDidChange = true
            processSearch(searchText: searchText.trim().lowercased(), searchUp: true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        isSearchButtonTapped = true
        scrollMessageToIndex(foundedIndex: foundedIndex,messageIndex: currentHighlightedIndex ?? 0)
    }
    
    private func refreshChatMessages() {
        isStarredSearchEnabled = false
        searchBar?.resignFirstResponder()
        searchBar?.setShowsCancelButton(false, animated: true)
        searchBar?.text = ""
        starredSearchMessages?.removeAll()
        UIView.performWithoutAnimation {
            chatTableView?.reloadData()
        }
        chatTableView?.tableFooterView = nil
    }
    
    func scrollToTableViewTop() {
        if isStarredMessagePage {
            self.chatTableView?.setContentOffset(.zero, animated: false)
        }
    }
    
    func scrollToTableViewBottom() {
        if !isStarredMessagePage && !chatMessages.isEmpty {
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: 0, section: 0)
                self.chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if isStarredMessagePage {
            refreshChatMessages()
        } else {
            currentHighlightedIndex = nil
            currentSelectedIndexPath = nil
            currentHighlightedIndexPath = nil
            searchBar.resignFirstResponder()
            foundedIndex = []
            foundedSearchResult = false
            searchBar.isHidden = true
            messageSearchView.isHidden = true
            messageSearchEnabled = false
            messageSearchBar?.text = ""
            if messageTextView.text != "" {
                messageText = messageTextView.text
            }
            
            if replyJid == getProfileDetails.jid && !isReplyViewClosed {
                isReplyViewOpen = true
                resizeMessageTextView()
                replyView.isHidden = false
            }
            UIView.performWithoutAnimation {
                chatTableView.reloadData()
            }
        }
        showHideEmptyView()
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if searchBar.text?.trim().count ?? 0 <= 1 {
            isStarredSearchEnabled = false
            UIView.performWithoutAnimation {
                chatTableView.reloadData()
            }
        }
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if isStarredMessagePage {
            scrollToTableViewTop()
        }
        showHideTextToolBarView()
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func processSearch(searchText: String, searchUp: Bool) {
        executeOnMainThread { [self] in
            if searchText.count > 0 {
                foundedIndex = []
                chatMessages.enumerated().forEach({ (section,messages) in
                    messages.enumerated().forEach({ (row,message) in
                        if (message.messageTextContent.localizedCaseInsensitiveContains(searchText) || message.mediaChatMessage?.mediaCaptionText.localizedCaseInsensitiveContains(searchText) ?? false ||
                            (message.mediaChatMessage?.messageType == .document && message.mediaChatMessage?.mediaFileName.localizedCaseInsensitiveContains(searchText) ?? false) ||
                            message.contactChatMessage?.contactName.localizedCaseInsensitiveContains(searchText) ?? false || message.replyParentChatMessage?.messageTextContent.localizedCaseInsensitiveContains(searchText) ?? false || (message.messageType == .meet && message.meetChatMessage?.link.localizedCaseInsensitiveContains(searchText) ?? false)) && !message.isMessageRecalled && message.messageType != .notification {
                            foundedIndex.append(IndexPath(row: row, section: section))
                        }
                    })
                })
                if foundedIndex.count > 0 {
                    foundedSearchResult = true
                    UIView.performWithoutAnimation {
                        chatTableView.reloadData()
                    }
                    print("Scrolling Index2: \(0)")
                    isSearchButtonTapped = false
                    scrollMessageToIndex(foundedIndex: foundedIndex, messageIndex: currentHighlightedIndex ?? 0)
                } else {
                    foundedSearchResult = false
                    UIView.performWithoutAnimation {
                        chatTableView.reloadData()
                    }
                    if searchUp {
                        self.searchUp()
                    } else {
                        self.searchDown()
                    }
                }
            } else {
                foundedSearchResult = false
                currentHighlightedIndex = nil
                currentSelectedIndexPath = nil
                currentHighlightedIndexPath = nil
                chatTableView.reloadDataWithoutScroll()
            }
        }
    }
    
    @objc private func tapSearchUp() {
        isSearchDidChange = false
        isSearchButtonTapped = true
        searchUp()
    }
    
    @objc private func tapSearchDown() {
        isSearchDidChange = false
        isSearchButtonTapped = true
        searchDown()
    }
    
    @objc func searchUp() {
        if !isSearchDidChange {
            if #available(iOS 13.0, *) {
                messageSearchUp.backgroundColor = .opaqueSeparator
            } else {
                messageSearchUp.backgroundColor = .lightText
                // Fallback on earlier versions
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { [weak self] in
                self?.messageSearchUp.backgroundColor = .clear
            }
        }
        executeOnMainThread { [self] in
            if foundedIndex.count == (currentHighlightedIndex ?? 0)+1 || foundedIndex.count == 0 {
                if !previousMessagesLoadingDone && !isPreviousMessagesLoadingInProgress{
                    print("#scroll #load started")
                    isPreviousMessagesLoadingInProgress = true
                    previousMessagesLoadingDone = false
                    backgroundQueue.async { [weak self] in
                        self?.loadPreviousMessage()
                    }
                }
            }
        }
        if let index = currentHighlightedIndex {
            if foundedIndex.count > index+1 {
                currentHighlightedIndex! += 1
                scrollMessageToIndex(foundedIndex: foundedIndex, messageIndex: currentHighlightedIndex ?? 0)
            } else {
                if foundedIndex.count == (currentHighlightedIndex ?? 0)+1 {
                    if !isSearchDidChange {
                        messageSearchBar?.resignFirstResponder()
                    }
                    if foundedIndex.isEmpty {
                        AppAlert.shared.showToast(message: "No messages found")
                    } else {
                        scrollMessageToIndex(foundedIndex: foundedIndex, messageIndex: 0)
                    }
                }
            }
        } else {
            if currentHighlightedIndex == 0 {
                scrollMessageToIndex(foundedIndex: foundedIndex, messageIndex: 0)
            } else {
                if foundedIndex.count == 0 || foundedIndex.count == (currentHighlightedIndex ?? 0)+1 {
                    if !isSearchDidChange {
                        messageSearchBar?.resignFirstResponder()
                    }
                    AppAlert.shared.showToast(message: "No messages found")
                }
            }
        }
    }
    
    func scrollMessageToIndex(foundedIndex: [IndexPath], messageIndex: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            if foundedIndex.count > 0 {
                self?.currentHighlightedIndex = messageIndex
                self?.currentHighlightedIndexPath = foundedIndex[messageIndex]
                self?.chatTableView.scrollToRow(at: foundedIndex[messageIndex], at: .top, animated: true)
                if ((self?.isSearchButtonTapped) == true) && (self?.isStarredMessagePage == false) {
                    self?.currentSelectedIndexPath = self?.foundedIndex[messageIndex]
                    self?.updateCellSelection(indexPath: foundedIndex[messageIndex])
                }
            }
        }
    }
    
    private func updateCellSelection(indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let cell = self?.chatTableView.cellForRow(at: indexPath) {
                cell.contentView.backgroundColor = Color.cellSelectionColor
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if let cell = self?.chatTableView.cellForRow(at: indexPath) {
                cell.contentView.backgroundColor = .clear
            }
        }
    }
    
    @objc func searchDown() {
        if !isSearchDidChange {
            if #available(iOS 13.0, *) {
                messageSearchDown.backgroundColor = .opaqueSeparator
            } else {
                messageSearchDown.backgroundColor = .lightText
                // Fallback on earlier versions
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5 ) { [weak self] in
                self?.messageSearchDown.backgroundColor = .clear
            }
        }
        if currentHighlightedIndex == 0 {
            if !nextMessagesLoadingDone && !isNextMessagesLoadingInProgress{
                print("#scroll  #bottom #load started")
                isNextMessagesLoadingInProgress = true
                nextMessagesLoadingDone = false
                backgroundQueue.async { [weak self] in
                    self?.loadNextMessage()
                }
            }
        }
        
        if let index = currentHighlightedIndex {
            if foundedIndex.count > 0 {
                print("Scrolling Index1: \(index-1)")
                if index > 0 {
                    scrollMessageToIndex(foundedIndex: foundedIndex, messageIndex: index-1)
                } else if currentHighlightedIndexPath == IndexPath(row: 0, section: 0) || currentHighlightedIndexPath?.row == currentHighlightedIndex || foundedIndex.count == 1 || currentSelectedIndexPath == foundedIndex[0] {
                    if foundedIndex.count == 0 || currentHighlightedIndex == 0 {
                        if !isSearchDidChange {
                            messageSearchBar?.resignFirstResponder()
                        }
                        if foundedIndex.isEmpty {
                            AppAlert.shared.showToast(message: "No messages found")
                        } else {
                            scrollMessageToIndex(foundedIndex: foundedIndex, messageIndex: 0)
                        }
                    }
                } else if index == 0 {
                    scrollMessageToIndex(foundedIndex: foundedIndex, messageIndex: 0)
                }
            }  else {
                if foundedIndex.count == 0 || currentHighlightedIndex == 0 {
                    if !isSearchDidChange {
                        messageSearchBar?.resignFirstResponder()
                    }
                    AppAlert.shared.showToast(message: "No messages found")
                }
            }
        } else {
            if foundedIndex.count == 0 || currentHighlightedIndex == 0 {
                if !isSearchDidChange {
                    messageSearchBar?.resignFirstResponder()
                }
                AppAlert.shared.showToast(message: "No messages found")
            }
        }
    }
}

// hanlde export chat to email
extension ChatViewParentController {
    func exportChatToEmail() {
        
        let concurrentQueue = DispatchQueue(label: "swiftlee.concurrent.queue", attributes: .concurrent)
        
        concurrentQueue.async {
            executeOnMainThread {  [weak self] in
                self?.startLoading(withText: pleaseWait)
            }
        }
        
        concurrentQueue.async {
            ChatManager.shared.exportChatConversationToEmail(jid: self.getProfileDetails.jid) { chatDataModel in
                var dataToShare = [Any]()
                
                //dataToShare.append(chatDataModel.subject)
                dataToShare.append(chatDataModel.messageContent)
                chatDataModel.mediaAttachmentsUrl.forEach { url in
                    dataToShare.append(url)
                }
                executeOnMainThread { [weak self] in
                    self?.stopLoading()
                    let ac = UIActivityViewController(activityItems: dataToShare, applicationActivities: nil)
                    self?.present(ac, animated: true)
                }
                
            }
        }
    }
}

extension ChatViewParentController {
    func updateMessage(chatMessage: ChatMessage,indexPath: IndexPath) -> ChatMessage? {
        if isStarredMessagePage {
            if isStarredSearchEnabled == true {
                starredSearchMessages?[indexPath.row] = chatMessage
                if let message = starredSearchMessages?[indexPath.row] {
                    return message
                }
            } else {
                var messagList = starredMessages
                messagList[indexPath.row] = chatMessage
                return messagList[indexPath.row]
            }
        } else {
            chatMessages[indexPath.section][indexPath.row] = chatMessage
            return chatMessages[indexPath.section][indexPath.row]
        }
        return nil
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        view.endEditing(true)
    }
}

extension ChatViewParentController {
    func mentionshouldChangeTextIn(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) {
        if text == " " && (text.count == 1) && isMention {
            mentionRanges.append((text, NSRange(location: range.location, length: text.utf16.count)))
            mentionSearch = mentionRanges.compactMap({$0.0}).joined(separator: "")
            searchGroupMembers = mentionSearch.isEmpty ? mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }) : mentionArraySearchFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
            self.viewDidLayoutSubviews()
            reloadMentionTableview()
        } else {
            if text.trim().utf16.isEmpty {
                if isMention, text != "@" {
                    mentionRanges = mentionRanges.filter({ $0.1 != range})
                    mentionSearch = mentionRanges.compactMap({$0.0}).joined(separator: "")
                    let textviewString: String = "\(textView.text.utf16)"
                    if mentionSearch.isEmpty, textviewString.substringFromNSRange(range) == "@" {
                        resetGroupMention()
                        mentionBaseView.isHidden = true
                        CM.reloadMentionTableview(height: (self.containerBottomConstraint.constant + (self.chatTextView?.bounds.height ?? 0) + 10), members: [])
                        self.viewDidLayoutSubviews()
                    } else {
                        searchGroupMembers = mentionSearch.isEmpty ? mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }) : mentionArraySearchFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                        updateGroupmention()
                    }
                } else {
                    searchGroupMembers.removeAll()
                    self.viewDidLayoutSubviews()
                    reloadMentionTableview()
                }
            } else {
                if text == "@" && !isMention {
                    if range.location == 0 {
                        mentionRange = range
                        setGroupmention(range: range)
                        reloadMentionTableview()
                        self.viewDidLayoutSubviews()
                    } else if textView.text.substringFromNSRange(NSRange(location: range.location-1, length: 1)) == " " {
                        mentionRange = range
                        setGroupmention(range: range)
                        reloadMentionTableview()
                        self.viewDidLayoutSubviews()
                    }
                } else if isMention && text != "@" {
                    mentionRanges.append((text, NSRange(location: range.location, length: text.utf16.count)))
                    mentionSearch = mentionRanges.compactMap({$0.0}).joined(separator: "")
                    searchGroupMembers = mentionArraySearchFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                    updateGroupmention()
                } else {
                    searchGroupMembers.removeAll()
                    CM.reloadMentionTableview(height: (self.containerBottomConstraint.constant + (self.chatTextView?.bounds.height ?? 0) + 10), members: [])
                    self.viewDidLayoutSubviews()
                    resetGroupMention()
                }
            }
        }
        messageTextView.shouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
    }
    
    func updateGroupmention() {
        mentionBaseView.isHidden = false
        if searchGroupMembers.isEmpty {
            self.viewDidLayoutSubviews()
            if isMessageEditing {
                CM.reloadMentionTableview(height: (self.containerBottomConstraint.constant + (self.chatTextView?.bounds.height ?? 0) + 10), members: searchGroupMembers)
            }
        } else {
            reloadMentionTableview()
            self.viewDidLayoutSubviews()
        }
    }
    
    func setGroupmention(range: NSRange) {
        resetGroupMention()
        searchGroupMembers = mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
        mentionTableView.reloadData()
        isMention = true
        mentionRange = range
        if isMessageEditing {
            isMention = true
            CM.showMentionView(height: (self.containerBottomConstraint.constant + (self.chatTextView?.bounds.height ?? 0) + 10), members: mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }))
            return
        }
        self.view.bringSubviewToFront(mentionBaseView)
        self.viewDidLayoutSubviews()
        mentionBaseView.isHidden = false
    }
    
    func reloadMentionTableview() {
        if isMessageEditing {
            CM.reloadMentionTableview(height: (self.containerBottomConstraint.constant + (self.chatTextView?.bounds.height ?? 0) + 10), members: searchGroupMembers)
        } else {
            self.mentionTableView.reloadData()
        }
    }
    
    func resetGroupMention() {
        mentionSearch = ""
        mentionRange = nil
        mentionRanges.removeAll()
        isMention = false
    }
    
    func mentionArrayFilter() -> [GroupParticipantDetail] {
        groupMembers.filter({ $0.memberJid != AppUtils.getMyJid() && $0.profileDetail?.isBlockedByAdmin == false && $0.profileDetail?.contactType != .deleted })
    }
    
    func mentionArraySearchFilter() -> [GroupParticipantDetail] {
        groupMembers.filter({ $0.displayName.lowercased().contains(mentionSearch.lowercased()) && $0.memberJid != AppUtils.getMyJid() && $0.profileDetail?.isBlockedByAdmin == false && $0.profileDetail?.contactType != .deleted })
    }
}

extension ChatViewParentController: LinkDelegate {
    
    func pushToJoinCallView(callLink: String) {
        
        self.navigateToJoinCall(callLink: callLink)
    }
    
    func showAlreadyInCallAlert(callLink: String) {
        
        let currentCallLink = getCallLinkID(callLink: callLink)
        let onGoingCallLink = CallManager.getCallLink()
        
        if onGoingCallLink == currentCallLink {
        
            CallUIViewController.sharedInstance.callViewTapGestureAction(nil)
            
        }else {
            
            let alertController = UIAlertController.init(title: "You're already in a call" , message: "Do you want to leave your call to join this one?", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default) {_ in
                
                CallManager.disconnectCall()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.navigateToJoinCall(callLink: callLink)
                }
                
            }
            let cancelAction = UIAlertAction(title: "CANCEL", style: .default) { _ in
                
            }
            okAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            cancelAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            executeOnMainThread {
                self.present(alertController, animated: true)
            }
        }
    }
    
    func getCallLinkID(callLink: String) -> String {
        
        let ch = Character("/")
        let result = callLink.split(separator: ch)
        return String(describing: result.last ?? "")
    }
    
    func navigateToJoinCall(callLink: String) {
        
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        
        self.dismissKeyboard()
        
        let callLinkID = getCallLinkID(callLink: callLink)
        let id = callLinkID.components(separatedBy: "\n").first ?? callLinkID
        
        CallManager.setupJoinCallViaLink()
        
        let storyboard = UIStoryboard(name: "Call", bundle: nil)
        let joinCall = storyboard.instantiateViewController(withIdentifier: "JoinCallViaLinkViewController") as! JoinCallViaLinkViewController
        joinCall.callLink = callLinkID
        joinCall.getProfileDetails = getProfileDetails
        joinCall.fetchMessageListQuery = fetchMessageListQuery
        joinCall.callLink = id
        self.navigationController?.pushViewController(joinCall, animated: true)
        
    }
    
    
}

//MARK: - Schedule Meeting

extension ChatViewParentController: SendMeetLinkMessage {

    func userDeleted(userId: String, profile: MirrorFlySDK.ProfileDetails) {
        self.view.isUserInteractionEnabled = true
        userDeletedTheirProfile(for: userId, profileDetails: profile)
    }
    
    func isBlocked(userId: String, isBlocked: Bool) {
        self.view.isUserInteractionEnabled = true
        checkUserForBlocking(jid: userId, isBlocked: isBlocked)
        if userId == getProfileDetails.jid && getProfileDetails.profileChatType == .groupChat {
            checkMemberOfGroup()
            getGroupMember()
        }
    }
    
    func ondismissed() {
        self.view.isUserInteractionEnabled = true
        if !isStarredMessagePage {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                GroupManager.shared.groupDelegate = self
                ChatManager.shared.adminBlockDelegate = self
                chatManager.connectionDelegate = self
                chatManager.typingStatusDelegate = self
                ChatManager.setOnGoingChatUser(jid: getProfileDetails.jid)
                recorder.appAudioRecorderDelegate = self
                ChatManager.shared.availableFeaturesDelegate = self
                ContactManager.shared.profileDelegate = self
            }

            checkUserBlockedByAdmin()
            checkUserBlocked()
            setProfile()
            checkMemberOfGroup()
        }
    }

    func sendMeetMessage(link: String, time: Int) {
        self.resetMessageTextView()
        self.view.isUserInteractionEnabled = true
        if !NetworkReachability.shared.isConnected {
            executeOnMainThread {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
        FlyMessenger.sendMeetMessage(messageParams: MeetMessage(toId:  self.getProfileDetails.jid ?? emptyString(), title: "Sample Title", link: link, scheduledDateTime: time, replyMessageId: self.replyMessageId)) { [weak self] isSuccess, error, message in
            guard let self else {return}
            if isSuccess {
                if chatMessages.count == 0 {
                    if let message = message {
                        self.setLastMessage(messageId: message.messageId)
                        self.addNewGroupedMessage(messages: [message])
                    }
                } else {
                    if let message = message {
                        self.setLastMessage(messageId: message.messageId)
                        if let firstMessageInSection = chatMessages[0].first {

                            var timeStamp = 0.0
                            if firstMessageInSection.messageChatType == .singleChat {
                                timeStamp =  firstMessageInSection.messageSentTime
                            } else {
                                timeStamp = DateFormatterUtility.shared.getGroupMilliSeconds(milliSeconds: firstMessageInSection.messageSentTime)
                            }
                            if String().fetchMessageDateHeader(for: timeStamp) == "TODAY" {
                                chatMessages[0].insert(message, at: 0)
                                self.chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .right)
                                let indexPath = IndexPath(row: 0, section: 0)
                                self.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
                                self.chatTableView.reloadDataWithoutScroll()
                                self.scrollToTableViewBottom()
                            } else {
                                let (indexPa, shouldPaginate) = self.checkReplyMessageAvailability(replyMessageId: message.messageId)
                                if let scrollToRow = indexPa {
                                    self.scrollLogic(indexPath: scrollToRow)
                                } else if shouldPaginate{
                                    self.fetchMessageListParams.messageId = emptyString()
                                    self.queryInitialMessage(shouldScrollToMessage: true)
                                }
                            }
                        }
                        self.messageTextView?.text = ""
                        self.replyMessageId = ""
                        self.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                        self.handleSendButton()
                        if self.replyJid == self.getProfileDetails.jid {
                            self.replyMessageObj = nil
                            self.isReplyViewOpen = false
                        }
                    }
                }
            }
        }
    }


    @objc func scheduleMeetingTap(_ sender: UITapGestureRecognizer) {
        callLinkViewTapped()
    }

    func setupMeetLinkView() {
        let frame = CGRect(x: (Int(view.bounds.maxX) - 68), y:  (Int(view.bounds.maxY) - 160), width: scheduleMeetButtonCons, height: scheduleMeetButtonCons)
        scheduleMeetBtn.frame = frame
        scheduleMeetBtnYPosition = frame.center.y
        let imageView = UIImageView(frame: CGRect(x: 16, y: 16, width: 24, height: 24))
        imageView.image = UIImage(named: "meetChat")
        imageView.contentMode = .scaleAspectFit
        scheduleMeetBtn.addSubview(imageView)
        scheduleMeetBtn.cornerRadius(radius: scheduleMeetBtn.frame.height/2, width: 0.5, color: .clear)
        let tap = UITapGestureRecognizer(target: self, action: #selector(scheduleMeetingTap))
        scheduleMeetBtn.addGestureRecognizer(tap)
        self.view.addSubview(scheduleMeetBtn)
        self.view.bringSubviewToFront(scheduleMeetBtn)
        self.scheduleMeetBtn.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragAndDrop)))

        if (!ChatManager.getAvailableFeatures().isOneToOneCallEnabled || !ChatManager.getAvailableFeatures().isGroupCallEnabled || getProfileDetails.contactType == .deleted || getBlocked()) {
            scheduleMeetBtn.isHidden = true
        }
    }

    @objc func dragAndDrop(gesture: UIPanGestureRecognizer){

        let window = UIApplication.shared.windows.first
        let bottomPadding = (window?.safeAreaInsets.bottom ?? 0) + 30
        let topPadding = (window?.safeAreaInsets.top ?? 0) + 30

        var location = gesture.location(in: self.view)

        if self.containerBottomConstraint.constant > 0 {
            if location.y < (topPadding < CGFloat(scheduleMeetButtonCons) ? CGFloat(scheduleMeetButtonCons) : topPadding) {
                location = CGPoint(x: location.x, y: (topPadding < CGFloat(scheduleMeetButtonCons) ? CGFloat(scheduleMeetButtonCons) : topPadding))
            } else if (self.view.frame.height - (self.containerBottomConstraint.constant + bottomPadding)) < location.y {
                location = CGPoint(x: location.x, y: self.view.frame.height - (self.containerBottomConstraint.constant + bottomPadding))
            }
        } else {
            if location.y < (topPadding < CGFloat(scheduleMeetButtonCons) ? CGFloat(scheduleMeetButtonCons) : topPadding) {
                location = CGPoint(x: location.x, y: (topPadding < CGFloat(scheduleMeetButtonCons) ? CGFloat(scheduleMeetButtonCons) : topPadding))
            } else if (self.view.frame.height - bottomPadding) < location.y {
                location = CGPoint(x: location.x, y: self.view.frame.height - bottomPadding)
            }
        }
        let draggedView = gesture.view
        draggedView?.center = location

        scheduleMeetBtnYPosition = location.y

        if gesture.state == .ended {
            if self.scheduleMeetBtn.frame.midX >= self.view.layer.frame.width / 2 {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.scheduleMeetBtn.center.x = self.view.layer.frame.width - 40
                }, completion: nil)
            }else{
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.scheduleMeetBtn.center.x = 40
                }, completion: nil)
            }
        }
    }

    func callLinkViewTapped() {
        if NetworkReachability.shared.isConnected{
            if bottomSheet != nil {
                bottomSheet = InstantScheduledMeetingViewController()
            }
            self.showShareLinkSheet(link: emptyString())
        }else{
            executeOnMainThread {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }

    func showShareLinkSheet(link : String){
        checkUserBusyStatusEnabled(self) { [self] status in
            executeOnMainThread {
                if status {
                    if let sheet = bottomSheet {
                        self.bottomSheetOpened = true
                        self.view.endEditing(false)
                        self.view.isUserInteractionEnabled = false
                        resetAudioRecording(isCancel: true)
                        sheet.callLinkDelegate = self
                        sheet.meetMessageDelegate = self
                        sheet.getProfileDetails = self.getProfileDetails
                        let delay = keyboardShown ? 0.8 : 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            presentBottomSheetInsideNavigationController(viewController: sheet,configuration: BottomSheetConfiguration(
                                cornerRadius: 16,
                                pullBarConfiguration: .hidden,
                                shadowConfiguration: .default
                            ),canBeDismissed: {
                                true
                            },dismissCompletion: {
                                self.view.isUserInteractionEnabled = true
                                self.bottomSheetOpened = false
                            })
                            self.view.isUserInteractionEnabled = true
                            self.bottomSheetOpened = false
                        }
                    }
                }
            }
        }
    }
    
    func isValidIndex(row : Int, section : Int) -> Bool {
        return isStarredMessagePage ? (isStarredSearchEnabled == true ? (starredSearchMessages?.count ?? 0) > row : starredMessages.count > row) : (chatMessages.count > section && chatMessages[section].count > row)
    }

}
