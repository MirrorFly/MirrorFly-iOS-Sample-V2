//
//  NotificationTonesListViewController.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 29/12/22.
//

import UIKit
import AVFoundation
import MirrorFlySDK

class NotificationTonesListViewController: UIViewController {

    let notificationViewModel = NotificationViewModel()

    var player: AVAudioPlayer?
    var soundList: [[String: String]] = []
    var selectedNotificationSoundName = [String:String]()
    var previousindex = 0
    var selectedIndex = 0
    let defaultSoundId = 1002

    @IBOutlet weak var notificationTonesListView: UITableView! {
        didSet {
            notificationTonesListView.delegate = self
            notificationTonesListView.dataSource = self
            notificationTonesListView.register(UINib(nibName: Identifiers.notificationToneListCell, bundle: nil), forCellReuseIdentifier: Identifiers.notificationToneListCell)
        }
    }

    @IBOutlet weak var headerView: UIView!

    override func viewWillLayoutSubviews() {
        headerView.roundCorners(corners: [.topRight, .topLeft], radius: 15)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        selectedNotificationSoundName = CommonDefaults.selectedNotificationSoundName
        soundList = notificationViewModel.getSystemSounds()

        if let id = soundList.filter({ $0 == selectedNotificationSoundName }).first {
            if let index = soundList.firstIndex(of: id) {
                selectedIndex = index
                notificationTonesListView.reloadData()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let scrollIndex = index == 0 ? index : index-1
                    self.notificationTonesListView.scrollToRow(at: IndexPath(row: scrollIndex, section: 0), at: .top, animated: false)
                }
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        AudioServicesDisposeSystemSoundID(SystemSoundID(defaultSoundId))
        player?.stop()
        selectedNotificationSoundName = CommonDefaults.selectedNotificationSoundName
        self.dismiss(animated: false)
    }
    
    @IBAction func saveAction(_ sender: UIButton) {
        AudioServicesDisposeSystemSoundID(SystemSoundID(defaultSoundId))
        player?.stop()
        CommonDefaults.selectedNotificationSoundName = selectedNotificationSoundName
        self.dismiss(animated: false)
    }

    func playSound(name: [String:String]) {
        if name[NotificationSoundKeys.name.rawValue] == "Default" {
            player?.stop()
            AudioServicesPlaySystemSound(SystemSoundID(defaultSoundId))
        } else if name[NotificationSoundKeys.name.rawValue] != "Default" && name[NotificationSoundKeys.name.rawValue] != "None" {
            AudioServicesDisposeSystemSoundID(SystemSoundID(defaultSoundId))
            if let url = Bundle.main.url(forResource: name[NotificationSoundKeys.file.rawValue], withExtension: name[NotificationSoundKeys.extensions.rawValue]) {
                do {
                    player = try AVAudioPlayer(contentsOf: url)
                    guard let player = player else { return }

                    player.prepareToPlay()
                    player.play()

                } catch let error as NSError {
                    print(error.description)
                }
            }
        }
    }

}

extension NotificationTonesListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soundList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.notificationToneListCell) as? NotificationToneListCell else {
            return UITableViewCell()
        }
        cell.toneNameLabel.text = soundList[indexPath.row][NotificationSoundKeys.name.rawValue]
        cell.headerLabel.isHidden = indexPath.row == 0 ? false : true

        cell.seperatorLine.isHidden = indexPath.row == 0 ? false : true

        if selectedNotificationSoundName == soundList[indexPath.row] {
            cell.toneNameLabel.textColor = .black
            cell.toneNameLabel.font = UIFont(name: "SFUIDisplay-Medium", size: 16)
            cell.selectedImageView.image = UIImage(named: "ic_tickmark")
        } else {
            cell.toneNameLabel.textColor = Color.recentChatTextColor
            cell.toneNameLabel.font = UIFont(name: "SFUIDisplay-Regular", size: 16)
            cell.selectedImageView.image = nil
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        playSound(name: soundList[indexPath.row])
        selectedNotificationSoundName = soundList[indexPath.row]

        previousindex = selectedIndex
        selectedIndex = indexPath.row

        tableView.reloadRows(at: [IndexPath(row: previousindex, section: 0), IndexPath(row: selectedIndex, section: 0)], with: .none)
    }

}
