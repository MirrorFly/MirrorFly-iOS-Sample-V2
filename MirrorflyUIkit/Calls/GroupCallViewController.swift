//
//  GroupCallViewController.swift
//  MirrorFlyiOS-SDK
//
//  Created by User on 20/07/21.
//

import UIKit
import MirrorFlySDK

class GroupCallViewController: UIViewController {
    
    @IBOutlet weak var imgOneLeading: NSLayoutConstraint!
    var callLog: CallLog!
    var callUserProfiles = [ProfileDetails]()
    var groupCallName = String()
    var callTime = String()
    var callDuration = String()
    let callLogManager = CallLogManager()
    @IBOutlet weak var groupCallNameLbl: UILabel!
    @IBOutlet weak var callDurationLbl: UILabel!
    @IBOutlet weak var callTimeLbl: UILabel!
    @IBOutlet weak var groupDetailTblView: UITableView! {
        didSet {
            groupDetailTblView.separatorStyle = .none
        }
    }
    @IBOutlet weak var callStateImg: UIImageView!
    @IBOutlet weak var callInitiateBtn: UIButton!
    @IBOutlet weak var imgOne: UIImageView!
    @IBOutlet weak var imgTwo: UIImageView!
    @IBOutlet weak var imgThree: UIImageView!
    @IBOutlet weak var imgFour: UIImageView!
    @IBOutlet weak var plusCountLbl: UILabel!
    var isGroup = false
    @IBOutlet weak var imgeOneHeight: NSLayoutConstraint!
    @IBOutlet weak var imgOneWidth: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
        var userList = callLog.userList
        userList.removeAll { jid in
            jid == AppUtils.getMyJid()
        }
        let fullNameArr = userList
        if isGroup{
            callLog.userProfileList.removeLast()
        }
        callUserProfiles = callLog.userProfileList.compactMap({$0})
        imgOne.layer.cornerRadius = imgOne.frame.size.height / 2
        imgOne.layer.masksToBounds = true
        
        imgThree.layer.cornerRadius = imgThree.frame.size.height / 2
        imgThree.layer.masksToBounds = true
        
        imgTwo.layer.cornerRadius = imgTwo.frame.size.height / 2
        imgTwo.layer.masksToBounds = true
        
        imgFour.layer.cornerRadius = imgFour.frame.size.height / 2
        imgFour.layer.masksToBounds = true
        
        
        if isGroup{
            imgOneWidth.constant = 60
            imgeOneHeight.constant = 60
            imgOne.layer.cornerRadius = 30
            imgOne.layer.masksToBounds = true
            imgTwo.isHidden = true
            imgThree.isHidden = true
            imgFour.isHidden = true
            plusCountLbl.isHidden = true
            if let contact = ChatManager.getContact(jid: callLog.groupId!) {
                imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType ,contactType: contact.contactType, jid: contact.jid)
            }
        }else{
            loadImagesForMutiUserCall()
        }
        
        if callLog.callType == .Audio {
            callInitiateBtn.setImage(UIImage.init(named: "audio_call"), for: .normal)
        } else {
            callInitiateBtn.setImage(UIImage.init(named: "VideoType"), for: .normal)
        }
        if callLog.callState == .IncomingCall {
            callStateImg.image = UIImage.init(named: "incomingCall")
        } else if callLog.callState == .OutgoingCall {
            callStateImg.image = UIImage.init(named: "outGoing")
        } else {
            callStateImg.image = UIImage.init(named: "missedCall")
        }
        groupCallNameLbl.text = groupCallName
        callDurationLbl.text = callDuration
        callTimeLbl.text = callTime
        groupDetailTblView.tableFooterView = UIView()
        groupDetailTblView.reloadData()
        callInitiateBtn.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        // memberCell?.contactNamelabel.text = contactArr.componentsJoined(by: ",")
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ContactManager.shared.profileDelegate = self
        CallManager.callLogDelegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        CallManager.callLogDelegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        ChatManager.deleteCallLog(isClearAll: false, callLogIds: [callLog.callLogId]) { isSuccess, error, data in
            if isSuccess {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc func buttonClicked(sender: UIButton) {
        if CallManager.isAlreadyOnAnotherCall(){
            AppAlert.shared.showToast(message: "You’re already on call, can't make new MirrorFly call")
            return
        }
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        let fullNameArr = callLog.userList
        let callUserProfiles = callLog.userProfileList
        if callLog.callType == .Audio {
            RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0?.jid}, callType: .Audio, groupId: callLog.groupId ?? emptyString(), onCompletion: { isSuccess, message in
                if(!isSuccess){
                    let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                    AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                }
            })
        } else {
            RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0?.jid}, callType: .Video, groupId: callLog.groupId ?? emptyString(), onCompletion: { isSuccess, message in
                if(!isSuccess){
                    let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                    AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                }
            })
        }
    }
    
    func loadImagesForMutiUserCall(){
        var userList = callLog.userList
        userList.removeAll { jid in
            jid == AppUtils.getMyJid()
        }
        
        if callLog.userProfileList.count == 2 {
            imgTwo.isHidden = true
            imgOneLeading.constant = 10
            imgThree.isHidden = true
            imgFour.isHidden = false
            plusCountLbl.isHidden = true
            
            if let contact = callLog.userProfileList[0]{
                imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[1] {
                imgFour.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
        } else if callLog.userProfileList.count == 3{
            if let contact = callLog.userProfileList[0]{
                imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[1] {
                imgThree.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[2] {
                imgFour.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            imgTwo.isHidden = true
            imgOneLeading.constant = 15
            imgThree.isHidden = false
            imgFour.isHidden = false
            plusCountLbl.isHidden = true
            
        }else if callLog.userProfileList.count == 4{
            if let contact = callLog.userProfileList[0]{
                imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[1] {
                imgTwo.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[2] {
                imgThree.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[3] {
                imgFour.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            imgTwo.isHidden = false
            imgThree.isHidden = false
            imgFour.isHidden = false
            plusCountLbl.isHidden = true
            
        }else if callLog.userProfileList.count != 0{
            imgOne.isHidden = false
            imgTwo.isHidden = false
            imgThree.isHidden = false
            imgFour.isHidden = false
            plusCountLbl.isHidden = false
            plusCountLbl.text =  "+ " + "\(userList.count - 4)"
            if let contact = callLog.userProfileList[0]{
                imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[1] {
                imgTwo.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[2] {
                imgThree.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
            if let contact = callLog.userProfileList[3] {
                imgFour.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
            }
        }
    }
}

extension GroupCallViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return callUserProfiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let memberCell = tableView.dequeueReusableCell(withIdentifier: "CCFGroupCallLogListCell") as? CCFGroupCallLogListCell
        let contact = callUserProfiles[indexPath.row]
        memberCell?.userImageView.layer.cornerRadius = (memberCell?.userImageView.frame.size.height)!/2
        memberCell?.userImageView.layer.masksToBounds = true
        memberCell?.userImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
        memberCell?.contactNamelabel.text = getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
        return memberCell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
}

extension GroupCallViewController : ProfileEventsDelegate {
    
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        var userList = callLog.userList
        userList.removeAll { jid in
            jid == AppUtils.getMyJid()
        }
        callUserProfiles.removeAll()
        let contactArr = NSMutableArray()
        for contact in callLog.userProfileList {
            if let contact {
                contactArr.add(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
            }
        }
        if isGroup{
            groupCallNameLbl.text = groupCallName
        }else{
            groupCallNameLbl.text = contactArr.componentsJoined(by: ",")
            loadImagesForMutiUserCall()
        }
        groupDetailTblView.reloadData()
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        
    }
    
    func userBlockedMe(jid: String) {
        
    }
    
    func userUnBlockedMe(jid: String) {
        
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        if let index = callUserProfiles.firstIndex(where: { pd in pd.jid == jid }) {
            callUserProfiles[index] = profileDetails
            let indexPath = IndexPath(item: index, section: 0)
            groupDetailTblView?.reloadRows(at: [indexPath], with: .fade)
            let contactArr = NSMutableArray()
            for contact in callUserProfiles{
                contactArr.add(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
            }
            if !isGroup{
                groupCallNameLbl.text = contactArr.componentsJoined(by: ",")
                loadImagesForMutiUserCall()
            }
        }
    }
    
    
}

extension GroupCallViewController: CallLogDelegate {
    func clearAllCallLog() {
        executeOnMainThread {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func deleteCallLogs(callLogId: String) {
        executeOnMainThread {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func callLogUpdate(calllogId: String) {
        
    }
    
    
}

class CCFGroupCallLogListCell: UITableViewCell {
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
    
    @IBOutlet weak var callDurationLbl: UILabel!
    override class func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

