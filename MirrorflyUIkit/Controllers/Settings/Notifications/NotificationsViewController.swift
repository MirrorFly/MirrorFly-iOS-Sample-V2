//
//  NotificationsViewController.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 19/10/22.
//

import UIKit
import MirrorFlySDK
import PhoneNumberKit
import AVFoundation
import MediaPlayer

enum Notificationarray: String, CaseIterable{
    case notificationAlert = "Notification Alert"
    case notificationTone = "Notification Tone"
    case notificationNotWorking = "Notification Not Working ?"
}

class NotificationsViewController: UIViewController{

    let selectedCellHeight: CGFloat = 70.0


    @IBOutlet weak var notificationTableView: UITableView!

    private var NotificationList = Notificationarray.allCases
    override func viewDidLoad() {
        super.viewDidLoad()

        notificationTableView.register(UINib(nibName: Identifiers.notificationTableViewCell, bundle: nil),
                                            forCellReuseIdentifier: Identifiers.notificationTableViewCell)
        notificationTableView.delegate = self
        notificationTableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        notificationTableView.reloadData()
    }

    @IBAction func onTapBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

extension NotificationsViewController : UITableViewDelegate,UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.NotificationList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell : NotificationTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.notificationTableViewCell, for: indexPath) as! NotificationTableViewCell
        switch self.NotificationList[indexPath.row] {
        case .notificationAlert :
            cell.titlelabel.text = self.NotificationList[indexPath.row].rawValue
            cell.detailLabel.text = chooseAlertTypeforIncomingMessages
            break

        case .notificationTone:
            cell.titlelabel.text = self.NotificationList[indexPath.row].rawValue
            cell.detailLabel.text = FlyDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]
            break

        case .notificationNotWorking:
            cell.titlelabel.text = self.NotificationList[indexPath.row].rawValue
            cell.detailLabel.text = learnMoreInOurHelpCentre
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return selectedCellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.NotificationList[indexPath.row]{
        case .notificationAlert:
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier:Identifiers.notificationAlertViewController) as? NotificationAlertViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case .notificationTone:
            let toneVC = NotificationTonesListViewController(nibName: Identifiers.notificationTonesListViewController, bundle: nil)
            toneVC.modalPresentationStyle = .fullScreen
            self.present(toneVC, animated: false)
        case .notificationNotWorking:
            if NetworkReachability.shared.isConnected {
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier:Identifiers.notificationWebViewController) as? NotificationWebViewController {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
            print("NotificationNotWorking")
            break
        }
    }
}
