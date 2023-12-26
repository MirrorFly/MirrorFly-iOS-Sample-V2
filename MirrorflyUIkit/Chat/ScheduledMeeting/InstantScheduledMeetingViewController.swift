//
//  InstantScheduledMeetingViewController.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 14/09/23.
//

import UIKit
import MirrorFlySDK

protocol SendMeetLinkMessage {
    func sendMeetMessage(link: String, time: Int)
    func ondismissed()
    func isBlocked(userId: String, isBlocked: Bool)
    func userDeleted(userId: String, profile: ProfileDetails)
}

class InstantScheduledMeetingViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var menuView: UIView! {
        didSet {
            menuView.cornerRadius(radius: 16, width: 0.5, color: .clear)
            menuView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }

    init() {
        super.init(nibName: String(describing: InstantScheduledMeetingViewController.self), bundle: nil)
        modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var selectSwitch: UISwitch! {
        didSet {
            selectSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        }
    }
    @IBOutlet weak var mainView: UIView!

    @IBOutlet weak var shareStack: UIStackView!

    @IBOutlet weak var meetLink: UILabel!

    @IBOutlet weak var copyImage: UIImageView!

    @IBOutlet weak var joinBtn: UIButton!

    @IBOutlet weak var inviteContactButton: UIButton!

    @IBOutlet weak var shareBtn: UIButton!

    @IBOutlet weak var instantMeetMainView: UIStackView!

    @IBOutlet weak var scheduleMeetingView: UIStackView!

    @IBOutlet weak var scheduleTimeView: UIView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(showCalendar))
            scheduleTimeView.addGestureRecognizer(tap)
        }
    }

    @IBOutlet weak var scheduleDateLabel: UILabel!

    @IBOutlet weak var scheduleTimeLabel: UILabel!

    @IBOutlet weak var scheduleMeetingBtn: UIButton!

    @IBOutlet weak var calendarImage: UIImageView!

    @IBOutlet weak var pickerView: UIView! {
        didSet {
            pickerView.cornerRadius(radius: 10, width: 0.5, color: .clear)
        }
    }

    @IBOutlet weak var datePicker: UIDatePicker!

    
    var link : String? = nil

    var callLinkDelegate : LinkDelegate? = nil
    var meetMessageDelegate : SendMeetLinkMessage? = nil

    var currentMeetingDate = Date()
    var replyMessageId = String()
    var getProfileDetails: ProfileDetails!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadLink()
        hideScheduleMeetingView()
        //meetLink.text = link ?? emptyString()
        copyImage.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(copyToClipBoard))
        copyImage.addGestureRecognizer(tap)
        let scheduleTap = UITapGestureRecognizer(target: self, action: #selector(showCalendar))
        calendarImage.addGestureRecognizer(scheduleTap)
        shareBtn.layer.borderColor = UIColor(named: "color_3276E2")?.cgColor ?? UIColor.systemBlue.cgColor
        inviteContactButton.layer.borderColor = UIColor(named: "color_3276E2")?.cgColor ?? UIColor.systemBlue.cgColor
        shareStack.isHidden = true
        pickerView.isHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.view.backgroundColor = .clear
        self.datePicker.minimumDate = Date()
    }

    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)),name:Notification.Name(NetStatus.networkNotificationObserver),object: nil)
    }

    @objc func networkChange(_ notification: NSNotification) {
        if link == nil {
            loadLink()
        }
    }

    func loadLink() {
        joinBtn.backgroundColor = UIColor.init(hex: "A8A8A8")
        joinBtn.isUserInteractionEnabled = false
        copyImage.isHidden = true
        selectSwitch.isUserInteractionEnabled = false
        if NetworkReachability.shared.isConnected{
            CallManager.createMeetLink { isSuccess, error, result in
                var data = result
                if isSuccess {
                    executeOnMainThread { [self] in
                        link = "\(WEB_LOGIN_URL)\(data.getData() as? String ?? emptyString())"
                        meetLink.text = link
                        copyImage.isHidden = false
                        joinBtn.backgroundColor = Color.color_3276E2
                        joinBtn.isUserInteractionEnabled = true
                        selectSwitch.isUserInteractionEnabled = true
                    }
                }else{
                    executeOnMainThread {[self] in
                        AppAlert.shared.showToast(message: data.getMessage() as? String ?? emptyString())
                    }
                }
            }
        }else{
            executeOnMainThread {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        GroupManager.shared.groupDelegate = self
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.adminBlockDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        GroupManager.shared.groupDelegate = nil
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: self.menuView.bounds.height)
        }
    }

    func hideScheduleMeetingView() {
        scheduleMeetingBtn.isHidden = true
        scheduleTimeView.isHidden = true
        instantMeetMainView.isHidden = false
    }

    func hideInstantMeetingView() {
        scheduleMeetingBtn.isHidden = false
        scheduleTimeView.isHidden = false
        instantMeetMainView.isHidden = true
    }

    @IBAction func scheduleSwitch(_ sender: UISwitch) {
        datePicker.setDate(Date(), animated: true)
        datePicker.minimumDate = Date()
        currentMeetingDate = Date()
        setDate(date: currentMeetingDate)
        if sender.isOn {
            hideInstantMeetingView()
        } else {
            hideScheduleMeetingView()
        }
    }


    @IBAction func joinMeeting(_ sender: Any) {
        if let link = link, !link.isEmpty{
            if !NetworkReachability.shared.isConnected {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                return
            }
            if  !CallManager.isAlreadyOnAnotherCall() && !CallManager.isOngoingCall(){
                CallManager.setupJoinCallViaLink()
            }
            self.dismiss(animated: false)
            if !CallManager.isOngoingCall() && !CallManager.isAlreadyOnAnotherCall() {
                callLinkDelegate?.pushToJoinCallView(callLink: link)
            }else {
                callLinkDelegate?.showAlreadyInCallAlert(callLink: link)
            }
        }
    }

    @IBAction func scheduleMeeting(_ sender: UIButton) {
        //Convert current date and selected date to time interval with respect to minutes
        let currentTimeStamp = Int64(Date().timeIntervalSince1970 * 1000)/60000
        let selectedTimeStamp = Int64(currentMeetingDate.timeIntervalSince1970 * 1000)/60000

        if currentTimeStamp <= selectedTimeStamp {
            let time = Int(currentMeetingDate.millisecondsSince1970)
            meetMessageDelegate?.sendMeetMessage(link: link ?? "", time: time)
            meetMessageDelegate?.ondismissed()
            self.dismiss(animated: false)
        } else {
            AppAlert.shared.showToast(message: "Please check your selected date and time.")
        }

    }

    @IBAction func shareLink(_ sender: Any) {
    }

    @IBAction func inviteContacts(_ sender: Any) {
    }

    @objc func copyToClipBoard(sender: UIButton) {
        if let link = link, !link.isEmpty{
            let board = UIPasteboard.general
            board.string = link
            AppAlert.shared.showToast(message: "Link copied to clipboard")
        }
    }

    @objc func showCalendar(sender: UITapGestureRecognizer) {
        showPicker()
        scheduleMeetingView.isHidden = true
        scheduleMeetingBtn.isHidden = true
    }

    func showPicker() {
        pickerView.isHidden = false
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
    }

    @objc func datePickerValueChanged(_ sender: UIDatePicker){
        setDate(date: sender.date)
    }

    @IBAction func pickerOkAction(_ sender: UIButton) {
        pickerView.isHidden = true
        currentMeetingDate = datePicker.date
        setDate(date: currentMeetingDate)
        scheduleMeetingView.isHidden = false
        scheduleMeetingBtn.isHidden = false
    }

    @IBAction func pickerCancelAction(_ sender: UIButton) {
        pickerView.isHidden = true
        setDate(date: currentMeetingDate)
        datePicker.setDate(currentMeetingDate, animated: true)
        scheduleMeetingView.isHidden = false
        scheduleMeetingBtn.isHidden = false
    }

    func setDate(date: Date) {
        scheduleTimeLabel.text = DateFormatterUtility.shared.getTimeFormat(date: date)
        scheduleDateLabel.text = date.getDateString(format: "dd/MM/yyyy")
    }

    func isParticipantExist() -> (doesExist : Bool, message : String) {
       return GroupManager.shared.isParticiapntExistingIn(groupJid: getProfileDetails.jid, participantJid: AppUtils.getMyJid())
    }

}

extension InstantScheduledMeetingViewController : GroupEventsDelegate {
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
    }

    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        if !isParticipantExist().doesExist {
            meetMessageDelegate?.ondismissed()
            self.dismiss(animated: false)
        }
    }

    func didFetchGroupProfile(groupJid: String) {
    }

    func didUpdateGroupProfile(groupJid: String) {
    }

    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {

    }

    func didRevokedAdminAccess(groupJid: String, revokedAdminMemberJid: String, revokedByMemberJid: String) {

    }

    func didDeleteGroupLocally(groupJid: String) {

    }

    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        if !isParticipantExist().doesExist {
            meetMessageDelegate?.ondismissed()
            self.dismiss(animated: false)
        }
    }

    func didCreateGroup(groupJid: String) {
    }

    func didFetchGroups(groups: [ProfileDetails]) {

    }

    func didFetchGroupMembers(groupJid: String) {
    }

    func didReceiveGroupNotificationMessage(message: ChatMessage) {
    }

}

extension InstantScheduledMeetingViewController: ProfileEventsDelegate {
    func userCameOnline(for jid: String) {

    }

    func userWentOffline(for jid: String) {

    }

    func userProfileFetched(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails?) {

    }

    func myProfileUpdated() {

    }

    func usersProfilesFetched() {

    }

    func blockedThisUser(jid: String) {
        if getProfileDetails.profileChatType == .singleChat {
            if ChatManager.getContact(jid: getProfileDetails.jid)?.isBlocked ?? false {
                meetMessageDelegate?.ondismissed()
                self.dismiss(animated: false)
            }
        }
    }

    func unblockedThisUser(jid: String) {

    }

    func usersIBlockedListFetched(jidList: [String]) {

    }

    func usersBlockedMeListFetched(jidList: [String]) {

    }

    func userUpdatedTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {

    }

    func userBlockedMe(jid: String) {

    }

    func userUnBlockedMe(jid: String) {

    }

    func hideUserLastSeen() {

    }

    func getUserLastSeen() {

    }

    func userDeletedTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {
        meetMessageDelegate?.ondismissed()
        meetMessageDelegate?.userDeleted(userId: jid, profile: profileDetails)
        self.dismiss(animated: false)
    }


}

extension InstantScheduledMeetingViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        if userJid == getProfileDetails.jid {
            if isBlocked {
                meetMessageDelegate?.ondismissed()
                meetMessageDelegate?.isBlocked(userId: userJid, isBlocked: isBlocked)
                self.dismiss(animated: false)
            }
        }
    }

    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {

    }

    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        if groupJid == getProfileDetails.jid {
            if isBlocked {
                meetMessageDelegate?.ondismissed()
                meetMessageDelegate?.isBlocked(userId: groupJid, isBlocked: isBlocked)
                self.dismiss(animated: false)
            }
        }
    }

}
