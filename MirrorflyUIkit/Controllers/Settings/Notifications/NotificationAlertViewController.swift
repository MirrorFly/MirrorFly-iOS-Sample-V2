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
            cell.selectedImageView.image =  FlyDefaults.notificationSoundEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
            cell.separaterView.isHidden = true
            cell.helpTextView.isHidden = true
            
        case .NotificationPopUP:
            cell.lblTitle.text = self.NotificationList[indexPath.row].rawValue
            cell.helpTextLabel.text = showingPopUpforIncomingMessages
            cell.selectedImageView.image = FlyDefaults.notificationPopUPEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
            cell.separaterView.isHidden = true
            cell.helpTextView.isHidden = true
          
            
        case .Vibration:
            cell.lblTitle.text = self.NotificationList[indexPath.row].rawValue
            cell.helpTextLabel.text = vibrateWhenANewMessageArrivesWhileApplicationArrives
            cell.selectedImageView.image = FlyDefaults.vibrationEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
            cell.separaterView.isHidden = true
            cell.helpTextView.isHidden = true
       
        case .MuteNotification:
            cell.lblTitle.text = self.NotificationList[indexPath.row].rawValue
            cell.helpTextLabel.text = thisWillMuteAllNotificationsAlertsForIncomingMessages
            cell.selectedImageView.image = FlyDefaults.muteNotificationEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
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
            FlyDefaults.notificationSoundEnable = !FlyDefaults.notificationSoundEnable
            if FlyDefaults.notificationSoundEnable == true  {
                FlyDefaults.muteNotificationEnable = false
                FlyDefaults.notificationPopUPEnable = true
            }
            break
        case .NotificationPopUP:
            FlyDefaults.notificationPopUPEnable = !FlyDefaults.notificationPopUPEnable
            if FlyDefaults.notificationPopUPEnable == false {
                FlyDefaults.vibrationEnable = false
                FlyDefaults.notificationSoundEnable = false
                FlyDefaults.muteNotificationEnable = false
            }
            else if FlyDefaults.notificationPopUPEnable == true {
                
            }
            
            break
        case .Vibration:
            //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            FlyDefaults.vibrationEnable = !FlyDefaults.vibrationEnable
            if FlyDefaults.vibrationEnable == true {
                FlyDefaults.muteNotificationEnable = false
                FlyDefaults.notificationPopUPEnable = true
            }
        case .MuteNotification:
            FlyDefaults.muteNotificationEnable = !FlyDefaults.muteNotificationEnable
            if FlyDefaults.muteNotificationEnable == true {
                FlyDefaults.vibrationEnable = false
                FlyDefaults.notificationSoundEnable = false
                FlyDefaults.notificationPopUPEnable = true
            }
            else {
                FlyDefaults.notificationSoundEnable = true
                FlyDefaults.notificationPopUPEnable = true
            }
            break
            
        }
        self.notificationAlertTable.reloadData()
    }
    
    
}
