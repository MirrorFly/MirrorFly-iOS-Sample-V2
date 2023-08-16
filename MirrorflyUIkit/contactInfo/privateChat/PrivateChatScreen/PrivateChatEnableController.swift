//
//  PrivateChatEnableController.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 20/07/23.
//

import UIKit
import MirrorFlySDK
import Lottie

protocol PrivateChatDelegate {
    func onPasswordSet()
    func onPrivateChatAlertSelected(option: String)
    func onPrivateChatAuthenticated()
    func pinChanged()
}

class PrivateChatEnableController: UIViewController {

    @IBOutlet weak var lockChatView: UIView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(lockChatTapped))
            lockChatView.addGestureRecognizer(tap)
        }
    }


    @IBOutlet weak var headerImage: UIImageView! {
        didSet {
            headerImage.cornerRadius(radius: 40, width: 0, color: .clear)
        }
    }
    @IBOutlet weak var selectSwitch: UISwitch! {
        didSet {
            selectSwitch.isOn = ChatManager.isPrivateChat(jid: chatJid)
            selectSwitch.transform = CGAffineTransform(scaleX: 0.50, y: 0.50)
        }
    }



    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var optionBaseView: UIView!
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var animateImageView: LottieAnimationView!

    public var seletedOption = ""


    var chatJid: String = ""
    var isChatPrivateChanged = false

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        setupUI()
    }

    override func viewDidDisappear(_ animated: Bool) {
    }

    override func viewWillAppear(_ animated: Bool) {
        addGestures()
        isChatPrivateChanged = false
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("PrivateChatEnable"), object: nil)
        selectSwitch.isOn = ChatManager.isPrivateChat(jid: chatJid)
    }

    @objc func methodOfReceivedNotification(notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("PrivateChatEnable"), object: nil)
        if isChatPrivateChanged == false {
            showAlert()
            ChatManager.setPrivateChat(jid: chatJid, isPrivate: !ChatManager.isPrivateChat(jid: chatJid))
            isChatPrivateChanged = true
        }
        selectSwitch.isOn = ChatManager.isPrivateChat(jid: chatJid)
    }

    func showAlert() {
        ChatManager.getPrivateChatList(completionHandler: { isSuccess, error, data in
            if isSuccess {
                if (data["data"] as? [RecentChat] ?? []).count == 0 {
                    self.backgroundView.isHidden = false
                }
            }
        })
    }

    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func switchAction(_ sender: UISwitch) {
        handleSwitch(isOn: sender.isOn)
    }

    @objc func lockChatTapped(sender: UITapGestureRecognizer) {
        //handleSwitch(isOn: !selectSwitch.isOn)
    }

    func handleSwitch(isOn: Bool) {
        if isOn {
            if CommonDefaults.appLockPassword == "" {
                let vc = AppLockPasswordViewController(nibName:Identifiers.appLockPasswordViewController, bundle: nil)
                vc.isFromPrivateChat = true
                vc.privateChatDelegate = self
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                if CommonDefaults.appFingerprintenable {
                    let vc = PrivateChatFingerPrintPINViewController(nibName: "PrivateChatFingerPrintPINViewController", bundle: nil)
                    vc.isFromPrivateChat = true
                    vc.privateChatDelegate = self
                    self.navigationController?.pushViewController(vc, animated: false)
                } else {
                    let vc = PrivateChatAuthenticationPINViewController(nibName:"PrivateChatAuthenticationPINViewController", bundle: nil)
                    vc.isFromPrivateChat = true
                    vc.privateChatDelegate = self
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        } else {
            if CommonDefaults.appFingerprintenable {
                let vc = PrivateChatFingerPrintPINViewController(nibName: "PrivateChatFingerPrintPINViewController", bundle: nil)
                vc.isFromPrivateChat = true
                vc.privateChatDelegate = self
                self.navigationController?.pushViewController(vc, animated: false)
            } else {
                let vc = PrivateChatAuthenticationPINViewController(nibName:"PrivateChatAuthenticationPINViewController", bundle: nil)
                vc.isFromPrivateChat = true
                vc.privateChatDelegate = self
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func setupUI() {
        optionBaseView.layer.cornerRadius = 10
        viewButton.titleLabel?.font = AppFont.Regular.size(14)
        cancelButton.titleLabel?.font = AppFont.Regular.size(14)

        animateImageView.contentMode = .scaleAspectFit
        animateImageView.loopMode = .loop
        animateImageView.play()
    }

    @IBAction func viewAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }

    @IBAction func cancelAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }

    func setOption(text: String?) {
        if let selectedText = text {
            if selectedText == "View" {
                self.navigationController?.popToRootViewController(animated: true)
                NotificationCenter.default.post(name: Notification.Name("PrivateChatAlertView"), object: nil)
            }
        }
        backgroundView.isHidden = true
    }

    private func addGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tap.delegate = self
        backgroundView.addGestureRecognizer(tap)
    }

    @objc func tapAction() {
        self.navigationController?.popViewController(animated: false)
    }

}

extension PrivateChatEnableController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.optionBaseView) == true {
            return false
        }
        return true
    }
}

extension PrivateChatEnableController: PrivateChatDelegate {
    func pinChanged() {
        if isChatPrivateChanged == false {
            showAlert()
            ChatManager.setPrivateChat(jid: chatJid, isPrivate: !ChatManager.isPrivateChat(jid: chatJid))
            isChatPrivateChanged = true
        }
        selectSwitch.isOn = ChatManager.isPrivateChat(jid: chatJid)
    }

    func onPrivateChatAuthenticated() {

    }

    func onPrivateChatAlertSelected(option: String) {
        if option == "View" {
            self.navigationController?.popToRootViewController(animated: true)
            NotificationCenter.default.post(name: Notification.Name("PrivateChatAlertView"), object: nil)
        }
    }

    func onPasswordSet() {
        if isChatPrivateChanged == false {
            showAlert()
            ChatManager.setPrivateChat(jid: chatJid, isPrivate: !ChatManager.isPrivateChat(jid: chatJid))
            isChatPrivateChanged = true
        }
        selectSwitch.isOn = ChatManager.isPrivateChat(jid: chatJid)
    }
}
