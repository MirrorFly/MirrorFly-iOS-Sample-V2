//
//  ShareCallLinkViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 08/08/23.
//

import UIKit
import MirrorFlySDK

class ShareCallLinkViewController: UIViewController {
    
    
    @IBOutlet weak var shareStack: UIStackView!
    
    @IBOutlet weak var meetLink: UILabel!
    
    @IBOutlet weak var copyImage: UIImageView!
    
    @IBOutlet weak var joinBtn: UIButton!
    
    @IBOutlet weak var inviteContactButton: UIButton!
    
    @IBOutlet weak var shareBtn: UIButton!
    
    var link : String? = nil
    
    var callLinkDelegate : CallLinkDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        loadLink()
        //meetLink.text = link ?? emptyString()
        copyImage.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(copyToClipBoard))
        copyImage.addGestureRecognizer(tap)
        shareBtn.layer.borderColor = UIColor(named: "color_3276E2")?.cgColor ?? UIColor.systemBlue.cgColor
        inviteContactButton.layer.borderColor = UIColor(named: "color_3276E2")?.cgColor ?? UIColor.systemBlue.cgColor
        shareStack.isHidden = true
        preferredContentSize =  CGSize(width: UIScreen.main.bounds.width, height: 260)
    }

    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)),name:Notification.Name(NetStatus.networkNotificationObserver),object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
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
        if NetStatus.shared.isConnected{
            CallManager.createMeetLink { isSuccess, error, result in
                var data = result
                if isSuccess {
                    executeOnMainThread { [self] in
                        link = "\(WEB_LOGIN_URL)\(data.getData() as? String ?? emptyString())"
                        meetLink.text = link ?? emptyString()
                        copyImage.isHidden = false
                        joinBtn.backgroundColor = Color.color_3276E2
                        joinBtn.isUserInteractionEnabled = true
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

    
    @IBAction func joinMeeting(_ sender: Any) {
        if let link = link, !link.isEmpty{
            if !NetworkReachability.shared.isConnected {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                return
            }
            if  !CallManager.isAlreadyOnAnotherCall() && !CallManager.isOngoingCall(){
                CallManager.setupJoinCallViaLink()
            }
            dismiss(animated: true)
            callLinkDelegate?.didJoinClicked(link: link)
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
}

protocol CallLinkDelegate {
    func didJoinClicked(link :String)
}
