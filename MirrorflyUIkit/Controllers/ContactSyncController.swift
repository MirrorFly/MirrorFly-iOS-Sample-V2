//
//  ContactSyncController.swift
//  MirrorflyUIkit
//
//  Created by User on 04/02/22.
//

import UIKit
import Contacts
import RxSwift
import MirrorFlySDK

class ContactSyncController: UIViewController {
    
    @IBOutlet weak var progressInfoLabel: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var syncImage: UIImageView!
    var internetObserver = PublishSubject<Bool>()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncImage.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)), name:  Notification.Name(NetStatus.networkNotificationObserver), object: nil)
        progressInfoLabel.text = ""
        userName.text = ContactManager.getMyProfile().name
        
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .authorized || authorizationStatus == .denied{
            executeOnMainThread { [weak self] in
                self?.startSyncingContacts()
            }
        } else {
            progressInfoLabel.text = "Waiting for Contact permission"
            CNContactStore().requestAccess(for: .contacts){ [weak self] (access, error)  in
                executeOnMainThread { [weak self] in
                    self?.startSyncingContacts()
                }
            }
        }
        
        internetObserver.throttle(.seconds(2), latest: false ,scheduler: MainScheduler.instance).subscribe { [weak self] event in
            switch event {
            case .next(let data):
                print("#contact next ")
                if data {
                    AppAlert.shared.showToast(message: "Connected to internet")
                    self?.progressInfoLabel.text = "Contact sync is in progress"
                    self?.startSyncingContacts()
                }else{
                    self?.progressInfoLabel.text = ""
                    self?.syncImage.stopRotating()
                }
            case .error(let error):
                print("#contactSync error \(error.localizedDescription)")
            case .completed:
                print("#contactSync completed")
            }
            
        }.disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.viewControllers.removeAll(where: { viewControllers in
            !viewControllers.isKind(of: MainTabBarController.self)
        })
    }
    
    @objc func networkChange(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            let isNetworkAvailable = notification.userInfo?[NetStatus.isNetworkAvailable] as? Bool ?? false
            print("#contact networkChange ")
            self?.internetObserver.on(.next(isNetworkAvailable))
        }
    }
    
    func syncProgressUiUpdate(){
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .authorized {
            progressInfoLabel.text = "Contact sync is in progress"
            syncImage.isHidden = false
            syncImage.startRotating(duration: 1)
        } else if authorizationStatus == .denied {
            progressInfoLabel.text = "Contact permission denied"
            syncImage.isHidden = true
        } else {
            progressInfoLabel.text = "Contact read contact permission"
            syncImage.isHidden = true
        }
    }
    
    func startSyncingContacts(initialSync : Bool = true) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .authorized{
            ContactSyncManager.updateContactPermission(isDeined: false)
            ContactSyncManager.needContactSync(isSync: true)
        } else if authorizationStatus == .denied{
            ContactSyncManager.updateContactPermission(isDeined: true)
            ContactSyncManager.needContactSync(isSync: false)
        }
        if NetworkReachability.shared.isConnected{
            executeOnMainThread {
                self.syncProgressUiUpdate()
            }
            ContactSyncManager.shared.syncContacts(){ [weak self] (isSuccess, flyError, flyData)  in
                executeOnMainThread {
                    if isSuccess{
                        Utility.saveInPreference(key: isLoginContactSyncDone, value: true)
                        if authorizationStatus == .authorized{
                            AppAlert.shared.showToast(message: "Contacts synced successfully  ")
                            self?.progressInfoLabel.text = "Contacts Synced"
                            self?.syncImage.stopRotating()
                        }
                        self?.moveToDashboard()
                    }else{
                        Utility.saveInPreference(key: isLoginContactSyncDone, value: false)
                        self?.progressInfoLabel.text = "Contact sync failed"
                        self?.syncImage.stopRotating()
                        AppAlert.shared.showToast(message: "Contact sync failure \(flyError?.localizedDescription)")
                    }
                }
            }
        } else {
            progressInfoLabel.text = "Internet not available"
            AppAlert.shared.showToast(message: "Enable internet to sync contacts")
        }
    }
    
    func contactPermissionDenied(){
        AppAlert.shared.showToast(message: "Contact permission denied")
        moveToDashboard()
    }
    
    func moveToDashboard(){
        DispatchQueue.main.async { [weak self] in
            Utility.saveInPreference(key: isLoginContactSyncDone, value: true)
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let mainTabBarController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
            self?.navigationController?.pushViewController(mainTabBarController, animated: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
    }
}

extension UIView {
    
    func startRotating(duration: CFTimeInterval = 3, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            if self?.layer.animation(forKey: "transform.rotation.z") != nil {
                return
            }
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            let direction = clockwise ? 1.0 : -1.0
            animation.toValue = NSNumber(value: .pi * 2 * direction)
            animation.duration = duration
            animation.isCumulative = true
            animation.repeatCount = repeatCount
            self?.layer.add(animation, forKey:"transform.rotation.z")
        }
    }
    
    func stopRotating() {
        self.layer.removeAnimation(forKey: "transform.rotation.z")
    }
}
