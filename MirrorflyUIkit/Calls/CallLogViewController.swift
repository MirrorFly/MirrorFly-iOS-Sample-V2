//
//  CallLogViewController.swift
//  MirrorFlyiOS-SDK
//
//  Created by User on 14/07/21.
//

import UIKit
import MirrorFlySDK
import Floaty
import RxSwift


public protocol refreshCallLogDelegate {
    func refreshCallLog()
}

class CallLogViewController: UIViewController {
    
    @IBOutlet weak var callLogTableView: UITableView!
    let callLogManager = CallLogManager()
    var callLogArray = [CallLog]()
    var allCallLogArray = [CallLog]()
    var seletedCallLog: CallLog!
    let button = UIButton(type: UIButton.ButtonType.custom) as UIButton
    var isClearAll = Bool()
    @IBOutlet weak var deleteAllBtn: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var selectionLabel: UILabel!
    fileprivate var shownImagesCount = 4
    var layoutNumberOfColomn: Int = 2
    let imageArr = NSMutableArray()
    var groupCallViewController : GroupCallViewController?
    var floaty : Floaty? = nil
    var internetObserver = PublishSubject<Bool>()
    let disposeBag = DisposeBag()
    var callLogsTotalPages = 0
    var callLogsTotalRecords = 0
    var pageNumber = 1
    var isLoadingInProgress = false
    var isSearchEnabled = false
    @IBOutlet weak var callLogSearchBar: UISearchBar! {
        didSet {
            callLogSearchBar.delegate = self
        }
    }

    @IBOutlet weak var noCallLogView: UIView!
    @IBOutlet weak var searchCallLogLabel: UILabel!
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
                                    #selector(CallLogViewController.handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.gray
        return refreshControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
        NotificationCenter.default.addObserver(self, selector: #selector(updateCallCount), name: NSNotification.Name("updateCallCount"), object: nil)
        noCallLogView.isHidden = false
        // Do any additional setup after loading the view.
        internetObserver.throttle(.seconds(4), latest: false ,scheduler: MainScheduler.instance).subscribe { [weak self] event in
            switch event {
            case .next(let data):
                print("#calllogs next ")
                guard let self = self else{
                    return
                }
                if data {
                    self.resumeLoading()
                }
            case .error(let error):
                print("#calllogs error \(error.localizedDescription)")
            case .completed:
                print("#calllogs completed")
            }
            
        }.disposed(by: disposeBag)
        callLogTableView.addSubview(refreshControl)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longpressAction))
        callLogTableView.addGestureRecognizer(longPress)
    }
   
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.navigationBar.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)),
                                               name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)

        if !isSearchEnabled {
            callLogArray = CallLogManager.getAllCallLogs()
            allCallLogArray = callLogArray
            noCallLogView.isHidden = !callLogArray.isEmpty
            deleteAllBtn.isHidden = callLogArray.isEmpty
            self.updateButtons()
        }
        
        if let lastPageNumber = Int(Utility.getStringFromPreference(key: "clLastPageNumber")), let logsTotalPages = Int(Utility.getStringFromPreference(key: "clLastTotalPages")), let logsTotalRecords = Int(Utility.getStringFromPreference(key: "clLastTotalRecords"))  {
            
            pageNumber = lastPageNumber
            callLogsTotalPages = logsTotalPages
            callLogsTotalRecords = logsTotalRecords
            
        }
       
        callLogManager.syncCallLogs { isSuccess, error, data in
            if isSuccess {
                print(data)
            }
        }
        self.updateButtons()
        if let fab = floaty{
            fab.removeFromSuperview()
        }
        floaty = Floaty(frame:  CGRect(x: (view.bounds.maxX - 68), y:  (view.bounds.maxY - 160), width: 56, height: 56))
        floaty?.respondsToKeyboard = false
        floaty?.addItem("", icon: UIImage(named: "audio_call")!, handler: { item in
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
            controller.modalPresentationStyle = .fullScreen
            controller.makeCall = true
            controller.isMultiSelect = true
            controller.callType = .Audio
            controller.hideNavigationbar = true
            controller.isInvite = false
            self.navigationController?.pushViewController(controller, animated: true)
            self.floaty?.close()
        })
        floaty?.addItem("", icon: UIImage(named: "VideoType")!, handler: { item in
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
            controller.modalPresentationStyle = .fullScreen
            controller.makeCall = true
            controller.isMultiSelect = true
            controller.callType = .Video
            controller.hideNavigationbar = true
            controller.isInvite = false
            self.navigationController?.pushViewController(controller, animated: true)
            self.floaty?.close()
        })
        if let floaty = floaty {
            floaty.overlayColor = UIColor(white: 1, alpha: 0.0)
            view.addSubview(floaty)
        }
        callLogTableView.tableFooterView = UIView()
        callLogTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.adminBlockDelegate = self
        ChatManager.shared.availableFeaturesDelegate = self
        CallManager.callLogDelegate = self
        CallViewController.refreshDelegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.callLogsBadgeCountUpdation()
        }
        if !isSearchEnabled {
            self.startLoading(withText: "")
            executeInBackground { [weak self] in
                guard let self else {return}
                self.callLogArray = CallLogManager.getAllCallLogs()
                self.allCallLogArray = self.callLogArray
                executeOnMainThread {
                    self.noCallLogView.isHidden = !self.callLogArray.isEmpty
                    self.deleteAllBtn.isHidden = self.callLogArray.isEmpty
                    self.updateButtons()
                    self.callLogTableView.reloadData()
                    self.stopLoading()
                }
                if self.callLogArray.isEmpty {
                    if NetworkReachability.shared.isConnected {
                        executeInBackground { [weak self] in
                            guard let self else {return}
                            self.fetchCallLogsFromServer()
                        }
                    }
                }
            }
        } else {
            noCallLogView.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)

        ChatManager.shared.availableFeaturesDelegate = nil
//        //Application Badge Count
//        var appBadgeCount = UIApplication.shared.applicationIconBadgeNumber
//        appBadgeCount = appBadgeCount - FlyDefaults.unreadMissedCallCount
//        UIApplication.shared.applicationIconBadgeNumber = appBadgeCount
//        //CallLogs Badge Count
        callLogsBadgeCountUpdation()
        
        CallManager.callLogDelegate = nil
        CallViewController.refreshDelegate = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let floaty = floaty {
            floaty.close()
            floaty.removeFromSuperview()
        }
        NotificationCenter.default.removeObserver(self, name: Notification.Name("PrivateChatAlertView"), object: nil)
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        if NetworkReachability.shared.isConnected {
          fetchCallLogsFromServer()
        }else {
            refreshControl.endRefreshing()
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    @IBAction func clearButtonAction(_ sender: UIButton) {
        print("clearButtonAction")
        callLogArray.indices.forEach({ callLogArray[$0].isSelected = false })
        allCallLogArray.indices.forEach({ callLogArray[$0].isSelected = false })
        callLogTableView.reloadData()
        self.updateButtons()
    }
    
    func fetchCallLogsFromServer(){
        refreshControl.startRotating()
        callLogManager.getCallLogs(pageNumber: 1) { isSuccess, error, data in
            if isSuccess {
                if let callLogs = data["data"] as? [String : Any]{

                    if let totalPages = callLogs["totalPages"] as? Int ,let totalRecords = callLogs["totalRecords"] as? Int {
                        self.callLogsTotalPages = totalPages
                        self.callLogsTotalRecords = totalRecords
                        self.pageNumber += 1

                        Utility.saveInPreference(key: "clLastPageNumber", value: "\(self.pageNumber)")
                        Utility.saveInPreference(key: "clLastTotalPages", value: "\(self.callLogsTotalPages)")
                        Utility.saveInPreference(key: "clLastTotalRecords", value: "\(self.callLogsTotalRecords)")
                    }

                    if !self.isSearchEnabled {
                        self.callLogArray = CallLogManager.getAllCallLogs()
                        self.noCallLogView.isHidden = !self.callLogArray.isEmpty
                    }
                    self.allCallLogArray = self.callLogArray
                    self.updateButtons()
                    self.callLogTableView.reloadData()

                }
            } else {
                if !NetworkReachability.shared.isConnected{
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }else{
                    var flyData = data
                    if let message = flyData.getMessage() as? String{
                        print("#error \(message)")
                    }
                }
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc func updateCallCount() {
        //postUnSyncedLogs()
        callLogArray = CallLogManager.getAllCallLogs()
        if let lastCallLog = callLogArray.first {
            FlyCallUtils.sharedInstance.setConfigUserDefaults("\(lastCallLog.callReceivedTime)", withKey: "LastMissedCallTime")
        }
        self.setMissedCallCount()
    }
    
    private func getIsBlockedByMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    @IBAction func deleteAllCallLogs(_ sender: Any) {
        AppAlert.shared.showAlert(view: self, title: message, message: self.getSelectedLogs().isEmpty ? clearCalllog : clearSelectedCalllog, buttonOneTitle: clearAll, buttonTwoTitle: cancelUppercase, buttonOneColor: Color.color_FD3B2F, cancelWhenTapOutside: true)
        AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
            if result == 0 {
               self?.deleteCallLogs(isClearAll: true)
            }
        }
    }
    
    func callLogsBadgeCountUpdation() {
        
        //Application Badge Count
        var appBadgeCount = UIApplication.shared.applicationIconBadgeNumber
        appBadgeCount = appBadgeCount - CallLogManager.getUnreadMissedCallCount()
        UIApplication.shared.applicationIconBadgeNumber = appBadgeCount
        //CallLogs Badge Count
        CallLogManager.resetUnreadMissedCallCount()
        NotificationCenter.default.post(name: NSNotification.Name("updateUnReadMissedCallCount"), object: CallLogManager.getUnreadMissedCallCount())
    }
    
}



// MARK: Table View Methods
extension CallLogViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //callLogArray = CallLogManager.getAllCallLogs()
        print("calllog array issss" , callLogArray)
//        if CallLogArray.count == 0{
//            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
//            noDataLabel.text          = "No call log history found \n Any new calls will appear here "
//            noDataLabel.textColor     = UIColor.black
//            noDataLabel.numberOfLines = 0
//            noDataLabel.textAlignment = .center
//            noDataLabel.lineBreakMode = .byWordWrapping
//            tableView.backgroundView  = noDataLabel
//            tableView.separatorStyle  = .none
//        }
        return callLogArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let memberCell = tableView.dequeueReusableCell(withIdentifier: "CCFCallLogListCell") as? CCFCallLogListCell
        memberCell?.callInitiateBtn.isUserInteractionEnabled = true
        memberCell?.callInitiateBtn.tag = indexPath.row
        memberCell?.callInitiateBtn.makeCircleView(borderColor: UIColor.clear.cgColor, borderWidth: 0.0)
        memberCell?.callInitiateBtn.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        let callLog = callLogArray[indexPath.row]
        let isGroupCall =  (callLog.groupId?.count ?? 0 != 0)
        if callLog.callMode == .ONE_TO_ONE || isGroupCall {
            memberCell?.groupView.isHidden = true
            memberCell?.userImageView.isHidden = false
            var jidString = String()
            if callLog.fromUserId == FlyDefaults.myJid {
                jidString = callLog.toUserId
            } else {
                jidString = callLog.fromUserId
            }
            let jid =  (callLog.groupId?.count ?? 0 == 0) ? jidString : callLog.groupId!
            if let contact = callLog.userProfileList.first(where: {$0?.jid == jid}), let contact {
                memberCell?.contactNamelabel.attributedText = getAttributedUserName(name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), searchText: (callLogSearchBar.text ?? "").trim())
                memberCell?.userImageView.layer.cornerRadius = (memberCell?.userImageView.frame.size.height)!/2
                memberCell?.userImageView.layer.masksToBounds = true
                let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                memberCell?.userImageView.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType,contactType: contact.contactType, jid: contact.jid, isBlockedByAdmin: ContactManager.shared.getUserProfileDetails(for: contact.jid)?.isBlockedByAdmin ?? false)
                if getIsBlockedByMe(jid: jid) {
                    memberCell?.userImageView.image = UIImage(named: "ic_profile_placeholder")
                }
            } else {
                memberCell?.contactNamelabel.text = "Deleted User"
                memberCell?.userImageView.layer.cornerRadius = (memberCell?.userImageView.frame.size.height)!/2
                memberCell?.userImageView.layer.masksToBounds = true
                memberCell?.userImageView.image = UIImage(named: "ic_profile_placeholder")
            }
        }else{
            memberCell?.imgOne.layer.cornerRadius = (memberCell?.imgOne.frame.size.height)! / 2
            memberCell?.imgOne.layer.masksToBounds = true
            
            memberCell?.imgThree.layer.cornerRadius = (memberCell?.imgThree.frame.size.height)! / 2
            memberCell?.imgThree.layer.masksToBounds = true
            
            memberCell?.imgTwo.layer.cornerRadius = (memberCell?.imgTwo.frame.size.height)! / 2
            memberCell?.imgTwo.layer.masksToBounds = true
            
            memberCell?.imgFour.layer.cornerRadius = (memberCell?.imgFour.frame.size.height)! / 2
            memberCell?.imgFour.layer.masksToBounds = true
            
            memberCell?.groupView.isHidden = false
            memberCell?.userImageView.isHidden = true
            var userList = callLog.userList
            userList.removeAll { jid in
                jid == FlyDefaults.myJid
            }
            if callLog.groupId?.count ?? 0 > 0 {
                memberCell?.contactNamelabel.attributedText =  getAttributedUserName(name: callLog.displayName, searchText: (callLogSearchBar.text ?? "").trim())
            } else {
                memberCell?.contactNamelabel.attributedText =  getAttributedUserName(name: callLog.displayName, searchText: (callLogSearchBar.text ?? "").trim())
            }
            if callLog.userProfileList.count == 0 {
                
            } else if callLog.userProfileList.count == 1 {
                
            } else if callLog.userProfileList.count == 2 {
                memberCell?.imgTwo.isHidden = true
                memberCell?.leadingConstant.constant = 10
                memberCell?.imgThree.isHidden = true
                memberCell?.imgFour.isHidden = false
                memberCell?.plusCountLbl.isHidden = true
                for i in 0...callLog.userProfileList.count - 1{
                    if let contact = callLog.userProfileList[i]{
                        let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                        if i == 0{
                            memberCell?.imgOne.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                        }
                        if i == 1{
                            memberCell?.imgFour.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)

                        }
                    }
                }
                
            } else if callLog.userProfileList.count == 3 {
                for i in 0...callLog.userProfileList.count - 1{
                    if let contact = callLog.userProfileList[i]{
                        let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                        if i == 0{
                            memberCell?.imgOne.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                        }
                        if i == 1{
                            memberCell?.imgThree.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                        }

                        if i == 2{
                            memberCell?.imgFour.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                        }
                    }
                }
                memberCell?.imgTwo.isHidden = true
                memberCell?.leadingConstant.constant = 15
                memberCell?.imgThree.isHidden = false
                memberCell?.imgFour.isHidden = false
                memberCell?.plusCountLbl.isHidden = true
                
            } else if callLog.userProfileList.count == 4 {
                if let contact = callLog.userProfileList[0]{
                    let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                    memberCell?.imgOne.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType),contactType: contact.contactType, jid: contact.jid)
                }
                if let contact = callLog.userProfileList[1]{
                    let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                    memberCell?.imgTwo.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType),contactType: contact.contactType, jid: contact.jid)
                }
                if let contact = callLog.userProfileList[2]{
                    let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                    memberCell?.imgThree.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType),contactType: contact.contactType, jid: contact.jid)
                }
                if let contact = callLog.userProfileList[3]{
                    let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                    memberCell?.imgFour.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType),contactType: contact.contactType, jid: contact.jid)
                }
                memberCell?.imgTwo.isHidden = false
                memberCell?.leadingConstant.constant = 0
                memberCell?.imgThree.isHidden = false
                memberCell?.imgFour.isHidden = false
                memberCell?.plusCountLbl.isHidden = true
            }
            else if callLog.userProfileList.count > 4 {
                memberCell?.imgOne.isHidden = false
                memberCell?.imgTwo.isHidden = false
                memberCell?.imgThree.isHidden = false
                memberCell?.imgFour.isHidden = false
                memberCell?.leadingConstant.constant = 0
                memberCell?.plusCountLbl.isHidden = false
                memberCell?.plusCountLbl.text =  "+ " + "\(userList.count - 4)"
                
                if let contact = callLog.userProfileList[0]{
//                    executeInBackground {
                        let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                        memberCell?.imgOne.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType),contactType: contact.contactType, jid: contact.jid)
//                    }
                }
                if let contact = callLog.userProfileList[1]{
//                    executeInBackground {
                        let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                        memberCell?.imgTwo.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType),contactType: contact.contactType, jid: contact.jid)
//                    }
                }
                if let contact = callLog.userProfileList[2]{
//                    executeInBackground {
                        let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                        memberCell?.imgThree.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType),contactType: contact.contactType, jid: contact.jid)
//                    }
                }
                if let contact = callLog.userProfileList[3]{
//                    executeInBackground {
                        let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                        memberCell?.imgFour.loadFlyImage(imageURL: profileImage, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType),contactType: contact.contactType, jid: contact.jid)
//                    }
                }
            }
            
        }
        let time = callLog.callReceivedTime
        let todayTimeStamp = FlyCallUtils.generateTimestamp()
        memberCell?.callDateandTimeLabel.text = self.callLogTime(time, currentTime: todayTimeStamp)
        memberCell?.callDurationLbl.text = self.callLogDuration(callLog.callAttendedTime, endTime: callLog.callEndedTime)
        print(callLog.callReceivedTime)
        print(callLog.callEndedTime)
        
        if callLog.callType == .Audio {
            memberCell?.callInitiateBtn.setImage(UIImage.init(named: "audio_call"), for: .normal)
        } else {
            memberCell?.callInitiateBtn.setImage(UIImage.init(named: "VideoType"), for: .normal)
        }
        if callLog.callState == .IncomingCall {
            memberCell?.callStatusBtn.image = UIImage.init(named: "incomingCall")
        } else if callLog.callState == .OutgoingCall {
            memberCell?.callStatusBtn.image = UIImage.init(named: "outGoing")
        } else {
            memberCell?.callStatusBtn.image = UIImage.init(named: "missedCall")
        }
        if callLog.isSelected {
            memberCell?.backgroundColor = Color.recentChatSelectionColor
            memberCell?.groupView.backgroundColor = Color.recentChatSelectionColor
            memberCell?.plusCountLbl.backgroundColor = Color.recentChatSelectionColor
        } else {
            memberCell?.backgroundColor = .clear
            memberCell?.groupView.backgroundColor = .clear
            memberCell?.plusCountLbl.backgroundColor = .white
        }
        return memberCell!
    }

    func getAttributedUserName(name: String, searchText: String) -> NSMutableAttributedString {
        if isSearchEnabled {
            let range = (name.lowercased() as NSString).range(of: searchText.lowercased())
            let mutableAttributedString = NSMutableAttributedString.init(string: name)
            mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: Color.color_3276E2 ?? .black, range: range)
            return mutableAttributedString
        } else {
            let range = (name as NSString).range(of: searchText)
            return NSMutableAttributedString.init(string: name)
        }
    }
    
    private func isGroupOrUserBlocked(callLog : CallLog) -> Bool {
        if let tempGroupJid = callLog.groupId, ChatManager.isUserOrGroupBlockedByAdmin(jid: tempGroupJid) {
            AppAlert.shared.showToast(message: groupNoLongerAvailable)
            return true
        } else if ChatManager.isUserOrGroupBlockedByAdmin(jid: callLog.toUserId) {
            AppAlert.shared.showToast(message: thisUerIsNoLonger)
            return true
        }
        return false
    }
    
    @objc func buttonClicked(sender: UIButton) {

        if #available(iOS 13.0, *) {
            sender.backgroundColor = .opaqueSeparator
        } else {
            sender.backgroundColor = .lightText
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5 ) { [weak self] in
            sender.backgroundColor = .clear
        }

        let buttonRow = sender.tag
        print(buttonRow)
        let callLog = callLogArray[buttonRow]

        if callLog.callMode == .ONE_TO_ONE {
            var jidString = String()
            if callLog.fromUserId == FlyDefaults.myJid {
                jidString = callLog.toUserId
            } else {
                jidString = callLog.fromUserId
            }
            if let contact = ChatManager.getContact(jid: jidString) {
                if contact.isBlocked {
                    let alertViewController = UIAlertController.init(title: "\(ChatActions.unblock.rawValue)?" , message: "\(ChatActions.unblock.rawValue) \(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType))?", preferredStyle: .alert)

                    let cancelAction = UIAlertAction(title: cancelUppercase, style: .cancel) { [weak self] (action) in
                        self?.dismiss(animated: true,completion: nil)
                    }
                    let blockAction = UIAlertAction(title: ChatActions.unblock.rawValue, style: .default) { [weak self] (action) in
                        self?.unblockUser(contact: contact, callLog : callLog)
                    }
                    alertViewController.addAction(cancelAction)
                    alertViewController.addAction(blockAction)
                    alertViewController.preferredAction = cancelAction
                    present(alertViewController, animated: true)
                } else {
                    initiateCall(callLog: callLog)
                }
            }
        } else {
            initiateCall(callLog: callLog)
        }
    }

    //MARK: UnBlockUser
    private func unblockUser(contact: ProfileDetails, callLog: CallLog) {
        BlockUnblockViewModel.unblockUser(jid: contact.jid) { [weak self] isSuccess, error, data in
            if isSuccess {
                self?.initiateCall(callLog: callLog)
            }
        }
    }

    func initiateCall(callLog: CallLog) {
        if isGroupOrUserBlocked(callLog: callLog) {
            return
        }

        if CallManager.isAlreadyOnAnotherCall(){
            AppAlert.shared.showToast(message: "You’re already on call, can't make new MirrorFly call")
            return
        }
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        if callLog.callMode == .ONE_TO_ONE {
            var jidString = String()
            if callLog.fromUserId == FlyDefaults.myJid {
                jidString = callLog.toUserId
            }else{
                jidString = callLog.fromUserId
            }
            var callUserProfiles = [ProfileDetails]()

            if let contact = callLog.userProfileList.first(where: {$0?.jid == jidString}), let contact
            {
                if contact.contactType != .deleted{
                    callUserProfiles.append(contact)
                }
            }
            if callLog.callType == .Audio {
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Audio, groupId: callLog.groupId ?? emptyString(), onCompletion: { isSuccess, message in
                    if(!isSuccess){
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                    }
                })
            } else{
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Video,groupId: callLog.groupId ?? emptyString(), onCompletion: { isSuccess, message in
                    if(!isSuccess){
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                    }
                })
            }
        } else {
            let fullNameArr = callLog.userList
            var callUserProfiles = [ProfileDetails]()
            for JID in fullNameArr{
                if let contact = ChatManager.getContact(jid: JID){
                    if contact.contactType != .deleted{
                        callUserProfiles.append(contact)
                    }
                }
            }
            if callLog.callType == .Audio {
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Audio, groupId: callLog.groupId ?? emptyString(), onCompletion: { isSuccess, message in
                    if(!isSuccess){
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                    }
                    
                })
            } else{
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Video, groupId: callLog.groupId ?? emptyString(), onCompletion: { isSuccess, message in
                    if(!isSuccess){
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                    }
                    
                })
            }
        }
    }

    
    func callLogTime(_ callTime: Double, currentTime: String?) -> String? {
        let aDateFormatter = DateFormatter()
        aDateFormatter.dateFormat = "yyyy-MM-dd"
        aDateFormatter.timeZone = NSTimeZone(abbreviation: "GMT") as TimeZone?
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss a"
        df.timeZone = NSTimeZone.local
        df.dateStyle = .medium
        df.timeStyle = .short
        df.doesRelativeDateFormatting = true
        let timeInterval = TimeInterval(callTime / 1000000)
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateString = "\( self.getOnlyDateOrTime(from: date, withTime: false) ?? ""), \(self.getOnlyDateOrTime(from: date, withTime: true) ?? "")"
        return dateString
    }
    
    func getOnlyDateOrTime(from date: Date?, withTime: Bool) -> String? {
        // set last message date/time
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.local
        if withTime {
            dateFormatter.dateFormat = "HH:mm"
            dateFormatter.timeStyle = .short
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.dateStyle = .medium
        }
        dateFormatter.doesRelativeDateFormatting = true
        var dateString: String? = nil
        if let date = date {
            dateString = dateFormatter.string(from: date)
        }
        return dateString
    }
    
    func callLogDuration(_ startTime: Double, endTime: Double) -> String? {
        if startTime > 1 && endTime > 1 {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd hh:mm:ss a"
            df.timeZone = NSTimeZone.local
            df.dateStyle = .medium
            df.timeStyle = .short
            df.doesRelativeDateFormatting = true
            let timeInterval = TimeInterval(startTime / 1000000)
            let startdate = Date(timeIntervalSince1970: timeInterval)
            let timeInterval1 = TimeInterval(endTime / 1000000)
            let enddate = Date(timeIntervalSince1970: timeInterval1)
            var distanceBetweenDates: TimeInterval? = nil
            if let startdate = startdate as? Date{
                distanceBetweenDates = enddate.timeIntervalSince(startdate)
            }
            return string(from: distanceBetweenDates ?? 0.0)
        } else {
            return ""
        }
    }
    
    func string(from interval: TimeInterval) -> String? {
        let ti = Int(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = ti / 3600
        if hours > 0 {
            return String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
        } else {
            return String(format: "%02ld:%02ld", minutes, seconds)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return YES if you want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            seletedCallLog = callLogArray[indexPath.row]
            print(seletedCallLog)
            deleteCallLogs(isClearAll: false)
            callLogTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        seletedCallLog = callLogArray[indexPath.row]
        
        if isGroupOrUserBlocked(callLog: seletedCallLog) {
            return
        }
        if getSelectedLogs().isEmpty {
            if seletedCallLog.callMode == .ONE_TO_ONE && (seletedCallLog.groupId?.isEmpty ?? true) && ContactManager.shared.getUserProfileDetails(for: (seletedCallLog.fromUserId == FlyDefaults.myJid) ? seletedCallLog.toUserId :  seletedCallLog.fromUserId) != nil{
                let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
                var jidString = String()
                if seletedCallLog.fromUserId == FlyDefaults.myJid {
                    jidString = seletedCallLog.toUserId
                } else {
                    jidString = seletedCallLog.fromUserId
                }
                let profileDetails = ContactManager.shared.getUserProfileDetails(for: jidString)
                vc?.getProfileDetails = profileDetails
                let color = getColor(userName: ChatManager.getRechtChat(jid: jidString)?.profileName ?? "")
                vc?.contactColor = color

                vc?.isStarredMessagePage = false
                navigationController?.modalPresentationStyle = .overFullScreen
                navigationController?.pushViewController(vc!, animated: true)
            }else{
                if !(seletedCallLog.groupId?.isEmpty ?? true) && ContactManager.shared.getUserProfileDetails(for: seletedCallLog.groupId!) == nil{
                    return
                }
                let storyboard = UIStoryboard(name: "Call", bundle: nil)
                groupCallViewController = storyboard.instantiateViewController(withIdentifier: "GroupCallViewController") as? GroupCallViewController
                groupCallViewController?.callLog = seletedCallLog
                var name = seletedCallLog.displayName
                if !(seletedCallLog.groupId?.isEmpty ?? true){
//                    if let contact = ChatManager.getContact(jid: seletedCallLog.groupId!){
//                        name = contact.name
//                    }
                    
                    groupCallViewController?.isGroup = true
                }
//                else{
//                    let contactArr = NSMutableArray()
//                    for JID in fullNameArr{
//                        if let contact = ChatManager.getContact(jid: JID){
//                            contactArr.add(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
//                        }
//                    }
//                    name = contactArr.componentsJoined(by: ",")
//                }
                groupCallViewController?.groupCallName = name
                let time = seletedCallLog.callReceivedTime
                let todayTimeStamp = FlyCallUtils.generateTimestamp()
                groupCallViewController?.callTime = self.callLogTime(time, currentTime: todayTimeStamp)!
                groupCallViewController?.callDuration = self.callLogDuration(seletedCallLog.callReceivedTime, endTime: seletedCallLog.callEndedTime)!
                self.navigationController?.pushViewController(groupCallViewController!, animated: true)
            }
        } else {
            let isSelected = callLogArray[indexPath.row].isSelected
            callLogArray[indexPath.row].isSelected = !isSelected
            if let index = allCallLogArray.firstIndex(where: { $0.callLogId == callLogArray[indexPath.row].callLogId}) {
                allCallLogArray[index].isSelected = !isSelected
            }
            self.updateButtons()
            let cell = callLogTableView.cellForRow(at: indexPath) as? CCFCallLogListCell
            cell?.backgroundColor = !isSelected ? Color.recentChatSelectionColor : .clear
            cell?.groupView.backgroundColor = !isSelected ? Color.recentChatSelectionColor : .clear
            cell?.plusCountLbl.backgroundColor = !isSelected ? Color.recentChatSelectionColor : .white
        }
    }
    
    
    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {
    
        return UIView()
    }
    
    
    func tableView(_ tableView: UITableView,
                   heightForFooterInSection section: Int) -> CGFloat {
        return 90
    }

    func tableView(_ tableView: UITableView,
                   viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension CallLogViewController {
    
    func setMissedCallCount(){
        let missedCallCount = CallLogManager.getMissedCallCount()
        if (missedCallCount != 0) {
            print(missedCallCount)
        } else {
            print("No missed calls")
        }
        NotificationCenter.default.post(name: NSNotification.Name("missedCallCount"), object: missedCallCount)
        callLogTableView.reloadData()
    }
    
    func deleteCallLogs(isClearAll: Bool) {
        if isClearAll {
            if self.getSelectedLogs().isEmpty {
                ChatManager.deleteCallLog(isClearAll: true, callLogIds: [self.callLogArray.first?.callLogId ?? emptyString()]) { isSuccess, error, data in
                    self.updateButtons()
                    self.callLogArray = CallLogManager.getAllCallLogs()
                    self.allCallLogArray = self.callLogArray
                    self.callLogTableView.reloadData()
                    self.callLogsBadgeCountUpdation()
                }
            } else {
                let calllogIds = self.getSelectedLogs().compactMap({ $0.callLogId })
                ChatManager.deleteCallLog(isClearAll: false, callLogIds: calllogIds) { isSuccess, error, data in
                    self.callLogArray = CallLogManager.getAllCallLogs()
                    self.allCallLogArray = self.callLogArray
                    self.updateButtons()
                    self.callLogTableView.reloadData()
                }
            }
        } else {
            ChatManager.deleteCallLog(isClearAll: false, callLogIds: [self.seletedCallLog.callLogId]) { isSuccess, error, data in
                self.callLogArray = CallLogManager.getAllCallLogs()
                self.allCallLogArray = self.callLogArray
                self.updateButtons()
                self.callLogTableView.reloadData()
            }
        }
    }

    func refreshTableview() {
        callLogArray.removeAll()
        callLogArray = allCallLogArray
        if isSearchEnabled {
            noCallLogView.isHidden = true
            searchCallLogLabel.isHidden = !callLogArray.isEmpty
        } else {
            noCallLogView.isHidden = !callLogArray.isEmpty
            searchCallLogLabel.isHidden = true
        }
        callLogTableView.reloadData()
    }

    func refreshToken(onCompletion: @escaping (_ isSuccess: Bool) -> Void) {

        VOIPManager.sharedInstance.refreshToken { isSuccess in
            if isSuccess{
                FlyCallUtils.sharedInstance.setConfigUserDefaults(FlyDefaults.authtoken, withKey: "token")
                onCompletion(true)
            }else{
                onCompletion(false)
            }
        }
    }
    @objc func longpressAction(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.began {
            let touchPoint = sender.location(in: callLogTableView)
            if let indexPath = callLogTableView.indexPathForRow(at: touchPoint) {
                callLogArray[indexPath.row].isSelected = true
                if let index = allCallLogArray.firstIndex(where: { $0.callLogId == callLogArray[indexPath.row].callLogId}) {
                    allCallLogArray[index].isSelected = true
                }
                let cell = callLogTableView.cellForRow(at: indexPath) as? CCFCallLogListCell
                cell?.backgroundColor = Color.recentChatSelectionColor
                cell?.groupView.backgroundColor = Color.recentChatSelectionColor
                cell?.plusCountLbl.backgroundColor = Color.recentChatSelectionColor
                self.updateButtons()
            }
        }
    }
    
    
    func getSelectedLogs() -> [CallLog] {
        self.callLogArray.filter({ $0.isSelected == true })
    }
    
    func updateButtons() {
        self.selectionLabel.text = " \(self.getSelectedLogs().count)"
        self.clearButton.isHidden = self.getSelectedLogs().isEmpty
        self.selectionLabel.isHidden = self.getSelectedLogs().isEmpty
        self.deleteAllBtn.isHidden = self.callLogArray.isEmpty
        self.deleteAllBtn.setTitle(self.getSelectedLogs().isEmpty ? "DeleteAll" : "", for: .normal)
        self.deleteAllBtn.setImage(self.getSelectedLogs().isEmpty ? UIImage() : UIImage(named: "ic_delete"), for: .normal)
        
        if self.callLogArray.isEmpty {
            callLogsBadgeCountUpdation()
        }
    
    }
}

extension CallLogViewController : ProfileEventsDelegate{
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        callLogTableView.reloadData()
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        callLogTableView.reloadData()
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        callLogTableView.reloadData()
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        callLogTableView.reloadData()
    }
    
    func userBlockedMe(jid: String) {
       // getsyncedLogs()
        callLogManager.getCallLogs(pageNumber: 1) { isSuccess, error, data in
            if isSuccess {
                self.callLogTableView.reloadData()
            }
        }
    }
    
    func userUnBlockedMe(jid: String) {
       // getsyncedLogs()
        callLogManager.getCallLogs(pageNumber: 1) { isSuccess, error, data in
            if isSuccess {
                self.callLogTableView.reloadData()
            }
        }
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        callLogTableView.reloadData()
    }
    
    
}


class CCFCallLogListCell: UITableViewCell {
    ///  This object is used display the contact name in list
    @IBOutlet var contactNamelabel: UILabel!
    /// It is used to differentiate mail contact and phone contact
    ///  This object is used to display the contact profile image in list
    @IBOutlet var userImageView: UIImageView!
    ///  This object is used to make multiple selection from the listed contact
    @IBOutlet weak var callStatusBtn: UIImageView!
    @IBOutlet var callInitiateBtn: UIButton!
    ///  This object is used to make delete member from the listed contact
    @IBOutlet weak var callDateandTimeLabel: UILabel!
    
    @IBOutlet weak var leadingConstant: NSLayoutConstraint!
    @IBOutlet weak var plusCountLbl: UILabel!
    @IBOutlet weak var groupView: UIView!
    @IBOutlet weak var imgFour: UIImageView!
    @IBOutlet weak var imgThree: UIImageView!
    @IBOutlet weak var imgTwo: UIImageView!
    @IBOutlet weak var imgOne: UIImageView!
    @IBOutlet weak var callDurationLbl: UILabel!
    override class func awakeFromNib() {
        super.awakeFromNib()
       
    }
}


extension CallLogViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if ((scrollView.contentOffset.y + scrollView.frame.size.height) > scrollView.contentSize.height){
            
            if !isPaginationCompleted() && !isLoadingInProgress && !isSearchEnabled{
                print("call next page")
                self.loadNextPage()
            }
        }
    }
    
    func loadNextPage() {
        
        callLogTableView?.tableFooterView = createTableFooterView()
        isLoadingInProgress = true
        callLogManager.getCallLogs(pageNumber: pageNumber) { isSuccess, error, data in
            if isSuccess {
                
                if let callLogs = data["data"] as? [String : Any]{
                    
                    if let totalPages = callLogs["totalPages"] as? Int ,let totalRecords = callLogs["totalRecords"] as? Int {
                        
                        self.callLogsTotalPages = totalPages
                        self.callLogsTotalRecords = totalRecords
                        self.pageNumber += 1
                        
                        Utility.saveInPreference(key: "clLastPageNumber", value: "\(self.pageNumber)")
                        Utility.saveInPreference(key: "clLastTotalPages", value: "\(self.callLogsTotalPages)")
                        Utility.saveInPreference(key: "clLastTotalRecords", value: "\(self.callLogsTotalRecords)")
                    }
                    
                    self.callLogTableView?.tableFooterView = nil
                    self.isLoadingInProgress = false
                    self.callLogArray = CallLogManager.getAllCallLogs()
                    self.allCallLogArray = self.callLogArray
                    self.callLogTableView.reloadData()
                    
                }
            } else {
                if !NetworkReachability.shared.isConnected{
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }else{
                    var flyData = data
                    if let message = flyData.getMessage() as? String{
                        print("#error \(message)")
                    }
                }
            }
        }
    }
    
    public func isPaginationCompleted() -> Bool {
        if (callLogsTotalPages < pageNumber) || callLogArray.count == callLogsTotalRecords {
            return true
        }
        return false
    }
    
    public func createTableFooterView() -> UIView{
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64))
        let spinner = UIActivityIndicatorView()
        spinner.center = footerView.center
        footerView.addSubview(spinner)
        spinner.startAnimating()
        return footerView
    }
    
    @objc func networkChange(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            let isNetworkAvailable = notification.userInfo?[NetStatus.isNetworkAvailable] as? Bool ?? false
            self?.internetObserver.on(.next(isNetworkAvailable))
        }
    }
    
    func resumeLoading() {
        if isLoadingInProgress || !isPaginationCompleted() {
            self.loadNextPage()
        }
    }

    func refreshCallLogs() {
        isSearchEnabled = false
        callLogSearchBar.resignFirstResponder()
        callLogSearchBar.setShowsCancelButton(false, animated: true)
        refreshTableview()
        callLogSearchBar.text = ""
    }
    
}

extension CallLogViewController : AvailableFeaturesDelegate {
    
    func didUpdateAvailableFeatures(features: AvailableFeaturesModel) {
        
        let tabCount =  MainTabBarController.tabBarDelegagte?.currentTabCount()
        
        if (!(features.isGroupCallEnabled || features.isOneToOneCallEnabled) && tabCount == 5) {
            MainTabBarController.tabBarDelegagte?.removeTabAt(index: 2)
            
        }else {
            
            if ((features.isGroupCallEnabled || features.isOneToOneCallEnabled) && tabCount ?? 0 < 5){
                MainTabBarController.tabBarDelegagte?.resetTabs()
            }
            
        }
    }
}

extension CallLogViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        callLogTableView.reloadData()
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
    
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        callLogTableView.reloadData()
    }

}

extension CallLogViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trim().count > 0 {
            callLogArray = allCallLogArray.filter{
                return $0.displayName.localizedCaseInsensitiveContains(searchText.trim())
            }
        } else {
            callLogArray = allCallLogArray
        }
        callLogTableView.reloadData()
        searchCallLogLabel.isHidden = !callLogArray.isEmpty
        noCallLogView.isHidden = true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchCallLogLabel.isHidden = true
        refreshCallLogs()
        deleteAllBtn.isHidden = callLogArray.isEmpty
        noCallLogView.isHidden = !callLogArray.isEmpty
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchEnabled = true
        scrollToTableViewTop()
        refreshTableview()
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func scrollToTableViewTop() {
        callLogTableView.setContentOffset(.zero, animated: false)
    }
}

extension CallLogViewController : CallLogDelegate {
    
    func clearAllCallLog() {
        executeOnMainThread {
            self.deleteAllBtn.isHidden = true
            self.callLogSearchBar.resignFirstResponder()
            self.callLogSearchBar.text = ""
            self.callLogArray = CallLogManager.getAllCallLogs()
            self.allCallLogArray = self.callLogArray
            self.updateButtons()
            self.refreshCallLogs()
        }
    }
    
    func deleteCallLogs(callLogId : String) {
        if let index = callLogArray.firstIndex(where: {$0.callLogId == callLogId}), !callLogArray.isEmpty {
            executeOnMainThread {
//                self.callLogArray.remove(at: index)
//                self.allCallLogArray.remove(at: index)
                self.callLogTableView.reloadData()
                self.updateButtons()
                self.noCallLogView.isHidden = !self.callLogArray.isEmpty
            }
        }
    }
    
    func callLogUpdate(calllogId : String) {
        
    }
}

//Call log refresh delegate
extension CallLogViewController: refreshCallLogDelegate {

    func refreshCallLog() {
        executeOnMainThread { [weak self] in
            guard let self else {return}
            self.callLogArray.removeAll()
            self.callLogArray = CallLogManager.getAllCallLogs()
            self.allCallLogArray.forEach { log in
                if let index = self.callLogArray.firstIndex(where: {$0.callLogId == log.callLogId}) {
                    self.callLogArray[index] = log
                }
            }
            self.allCallLogArray = self.callLogArray
            self.callLogTableView.reloadData()
            self.noCallLogView.isHidden = !self.callLogArray.isEmpty
            self.updateButtons()
        }
    }

}
