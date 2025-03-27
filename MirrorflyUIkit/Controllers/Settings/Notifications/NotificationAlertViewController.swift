//
//  NotificationAlertViewController.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 19/10/22.
//

import UIKit
import MirrorFlySDK
import AVFoundation
import AudioToolbox

enum NotificationAlertTitle : String , CaseIterable{
    
    case NotificationSound = "Notification Sound"
    case NotificationPopUP = "Notification Popup"
    case Vibration = "Vibration"
    case MuteNotification = "Mute Notification"
    
}
class NotificationAlertViewController: UIViewController {
    
    @IBOutlet weak var notificationAlertTable: UITableView!
    
    let selectedCellHeight: CGFloat = 70.0
    private var NotificationList = NotificationAlertTitle.allCases
    override func viewDidLoad() {
        super.viewDidLoad()
        self.notificationAlertTable.register(UINib(nibName: Identifiers.chatSettingsTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.chatSettingsTableViewCell)
        self.notificationAlertTable.delegate = self
        self.notificationAlertTable.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        ChatManager.shared.muteEventDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ChatManager.shared.muteEventDelegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    @IBAction func onTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension NotificationAlertViewController : UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NotificationList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ChatSettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatSettingsTableViewCell, for: indexPath) as! ChatSettingsTableViewCell
        
        switch self.NotificationList[indexPath.row]{
            
        case .NotificationSound:
            cell.lblTitle.text = self.NotificationList[indexPath.row].rawValue
            cell.helpTextLabel.text = playSoundsForIncomingMessages
            cell.selectedImageView.image =  CommonDefaults.notificationSoundEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
            cell.separaterView.isHidden = true
            cell.helpTextView.isHidden = true
            
        case .NotificationPopUP:
            cell.lblTitle.text = self.NotificationList[indexPath.row].rawValue
            cell.helpTextLabel.text = showingPopUpforIncomingMessages
            cell.selectedImageView.image = CommonDefaults.notificationPopUPEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
            cell.separaterView.isHidden = true
            cell.helpTextView.isHidden = true
          
            
        case .Vibration:
            cell.lblTitle.text = self.NotificationList[indexPath.row].rawValue
            cell.helpTextLabel.text = vibrateWhenANewMessageArrivesWhileApplicationArrives
            cell.selectedImageView.image = CommonDefaults.vibrationEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
            cell.separaterView.isHidden = true
            cell.helpTextView.isHidden = true
       
        case .MuteNotification:
            cell.lblTitle.text = self.NotificationList[indexPath.row].rawValue
            cell.helpTextLabel.text = thisWillMuteAllNotificationsAlertsForIncomingMessages
            cell.selectedImageView.image = CommonDefaults.muteNotificationEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
            cell.separaterView.isHidden = true
            cell.helpTextView.isHidden = true
       
        default:
            break
        }
        cell.setCell(isArchive: false)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.NotificationList[indexPath.row]{
            
        case .NotificationSound:
            CommonDefaults.notificationSoundEnable = !CommonDefaults.notificationSoundEnable
            if CommonDefaults.notificationSoundEnable == true  {
                CommonDefaults.muteNotificationEnable = false
                CommonDefaults.notificationPopUPEnable = true
                muteSetting()
            }
            break
        case .NotificationPopUP:
            CommonDefaults.notificationPopUPEnable = !CommonDefaults.notificationPopUPEnable
            if CommonDefaults.notificationPopUPEnable == false {
                CommonDefaults.notificationSoundEnable = false
                CommonDefaults.muteNotificationEnable = true
            }
            else if CommonDefaults.notificationPopUPEnable == true {
                CommonDefaults.notificationSoundEnable = true
                CommonDefaults.muteNotificationEnable = false
            }
            CommonDefaults.vibrationEnable = false
            muteSetting()
            break
        case .Vibration:
            //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            CommonDefaults.vibrationEnable = !CommonDefaults.vibrationEnable
            if CommonDefaults.vibrationEnable == true {
                CommonDefaults.muteNotificationEnable = false
                CommonDefaults.notificationPopUPEnable = true
                muteSetting()
            }
        case .MuteNotification:
            CommonDefaults.muteNotificationEnable = !CommonDefaults.muteNotificationEnable
            if CommonDefaults.muteNotificationEnable == true {
                CommonDefaults.vibrationEnable = false
                CommonDefaults.notificationSoundEnable = false
                CommonDefaults.notificationPopUPEnable = false
            }
            else {
                CommonDefaults.notificationSoundEnable = true
                CommonDefaults.notificationPopUPEnable = true
            }
            muteSetting()
            
            break
            
        }
        self.notificationAlertTable.reloadData()
    }
    
    
}

extension NotificationAlertViewController : MuteEventDelegate {
    func onMuteStatusUpdated(isSuccess: Bool, message: String, jidList: [String], muteStatus: Bool) {
        
    }
    
    func didUpdateMuteSettings(isSuccess: Bool, message: String, isMuteStatus: Bool) {
        if isSuccess {
            CommonDefaults.muteNotificationEnable = isMuteStatus
            if CommonDefaults.muteNotificationEnable == true {
                CommonDefaults.vibrationEnable = false
                CommonDefaults.notificationSoundEnable = false
                CommonDefaults.notificationPopUPEnable = false
            }
            else {
                CommonDefaults.notificationSoundEnable = true
                CommonDefaults.notificationPopUPEnable = true
                CommonDefaults.vibrationEnable = true
            }
            executeOnMainThread { [weak self] in
                self?.notificationAlertTable.reloadData()
            }
        }
    }
    
    private func muteSetting() {
        ChatManager.updateMuteSettingStatus(muteStatus: CommonDefaults.muteNotificationEnable)
    }
    
}
