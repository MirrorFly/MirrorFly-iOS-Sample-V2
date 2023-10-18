//
//  MainTabBarController.swift
//  MirrorflyUIkit
//
//  Created by User on 11/08/21.
//

import UIKit
import MirrorFlySDK
import Contacts
import MirrorFlySDK

class MainTabBarController: UITabBarController{
    @IBOutlet weak var chatTabBars: UITabBar?
    
    var tabViewControllers : [UIViewController] = []
    
    static var isConnected = false
    
    var shouldShowCallTab = false
    
    var avilableFeatures = ChatManager.getAvailableFeatures()
    
    static var tabBarDelegagte : TabBarDelegate? = nil

    static var privateChatTabBarDelegate : PrivateChatSwitchDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        if let vcs = self.viewControllers{
            tabViewControllers = vcs
        }
        MainTabBarController.tabBarDelegagte = self
        MainTabBarController.privateChatTabBarDelegate = self
        shouldShowCallTab = avilableFeatures.isOneToOneCallEnabled || avilableFeatures.isGroupCallEnabled
        if !shouldShowCallTab{
            setupUI()
            removeTabAt(index:2)
        }else{
            resetTabs()
        }
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUnReadMissedCallCount(notification:)), name: NSNotification.Name("updateUnReadMissedCallCount"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateMessageUnreadCount(notification:)), name: NSNotification.Name("updateMessageUnreadCount"), object: nil)
        handleBackgroundAndForground()
        navigateToAuthentication()

    }

    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(didBecomeActive), object: nil)
    }

    func navigateToAuthentication() {

        if pushNotificationSelected {
            if let pushId = pushChatId {
                if ChatManager.isPrivateChat(jid: pushId) {
                    return
                }
            }
        }

        if (CommonDefaults.appLockenable || CommonDefaults.appFingerprintenable) {
            let secondsDifference = Calendar.current.dateComponents([.minute, .second], from: CommonDefaults.appBackgroundTime, to: Date())
            if secondsDifference.second ?? 0 > 32 || secondsDifference.minute ?? 0 > 0 {
                CommonDefaults.showAppLock = true
                CommonDefaults.appLockOnPrivateChat = false
                CommonDefaults.privateChatOnChatScreen = false
            }
        }

        if CommonDefaults.appFingerprintenable  && CommonDefaults.appLockenable && CommonDefaults.showAppLock {
            if CommonDefaults.showPrivateLockRecent {
                showLockScreen()
            } else {
                let current = UIApplication.shared.keyWindow?.getTopViewController()
                if (current is AuthenticationPINViewController || current is FingerPrintPINViewController) {
                    if let vc = current as? FingerPrintPINViewController {
                        vc.authenticationWithTouchID()
                    }
                    return
                }

                if !CommonDefaults.faceOrFingerAuthenticationFails {
                    let initialViewController = FingerPrintPINViewController(nibName: "FingerPrintPINViewController", bundle: nil)
                    let navigationController =  UINavigationController(rootViewController: initialViewController)
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.navigationController?.pushViewController(initialViewController, animated: false)
                } else {
                    let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
                    initialViewController.login = true
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.navigationController?.pushViewController(initialViewController, animated: false)
                }
            }
        }
        else if CommonDefaults.appLockenable && CommonDefaults.appFingerprintenable == false && CommonDefaults.showAppLock {
            if CommonDefaults.showPrivateLockRecent {
                showLockScreen()
            } else {
                let current = UIApplication.shared.keyWindow?.getTopViewController()
                if (current is AuthenticationPINViewController || current is FingerPrintPINViewController) {
                    if let vc = current as? FingerPrintPINViewController {
                        vc.authenticationWithTouchID()
                    }
                    return
                }
                
                let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
                initialViewController.login = true
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.pushViewController(initialViewController, animated: false)
            }
        } else if CommonDefaults.showPrivateLockRecent {
            if !pushNotificationSelected {
                showLockScreen()
            }
        }
    }

    func showLockScreen() {
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if (current is PrivateChatAuthenticationPINViewController || current is PrivateChatFingerPrintPINViewController) {
            if let vc = current as? PrivateChatFingerPrintPINViewController {
                vc.authenticationWithTouchID()
            }
           return
        }
        if CommonDefaults.appFingerprintenable {
            let vc = PrivateChatFingerPrintPINViewController(nibName: "PrivateChatFingerPrintPINViewController", bundle: nil)
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            let vc = PrivateChatAuthenticationPINViewController(nibName:"PrivateChatAuthenticationPINViewController", bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSelection()
        saveMyJidAsContacts()
        ChatManager.shared.connectionDelegate = self
        updateUnReadMissedCallBadgeCount()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Utility.saveInPreference(key: "safeAreaHeight", value: "\(view.safeAreaLayoutGuide.layoutFrame.height)")
        Utility.saveInPreference(key: "safeAreaWidth", value: "\(view.safeAreaLayoutGuide.layoutFrame.width)")
    }
    
    // MARK: - Functions
    func setupUI() {
        self.chatTabBars?.backgroundColor = Color.navigationColor
        navigationController?.setNavigationBarHidden(true, animated: true)
        guard let items = tabBar.items else { return }
        items[0].title = chat
        items[1].title = contact
        items[2].title = call
        items[3].title = profile
        items[4].title = setting
        //Mark:- You can also set any custom fonts in the code
        let fontAttributes = [NSAttributedString.Key.font: UIFont.font12px_appLight()]
        UITabBarItem.appearance().setTitleTextAttributes(fontAttributes, for: .normal)
        self.chatTabBars?.backgroundColor = Color.navigationColor
    }
    
    func saveMyJidAsContacts() {
        let profileData = ProfileDetails(jid: AppUtils.getMyJid())
        profileData.name = ContactManager.getMyProfile().name
        profileData.nickName = ContactManager.getMyProfile().nickName
        profileData.mobileNumber  = ContactManager.getMyProfile().mobileNumber
        profileData.email = ContactManager.getMyProfile().email
        profileData.status = ContactManager.getMyProfile().status
        profileData.image = ContactManager.getMyProfile().image
        
//        FlyDatabaseController.shared.rosterManager.saveContact(profileDetailsArray: [profileData], chatType: .singleChat, contactType: .live, saveAsTemp: false, calledBy: "")
    }
    
    @objc override func willCometoForeground() {
        updateUnReadMissedCallBadgeCount()
        navigateToAuthentication()
    }
    
    @objc func updateUnReadMissedCallCount(notification: NSNotification) {
        updateUnReadMissedCallBadgeCount()
    }
    
    @objc func updateMessageUnreadCount(notification: NSNotification) {
        executeOnMainThread {
            if let count = notification.object as? Int {
                if let item : UITabBarItem = self.chatTabBars?.items?[0] {
                    item.badgeValue = (count == 0) ? nil : "\(count)"
                }
            }
        }
    }
    
    func updateUnReadMissedCallBadgeCount() {
        
        if let item : UITabBarItem = chatTabBars?.items?[2] {
            let missedCallCount = CallLogManager.getUnreadMissedCallCount()
            item.badgeValue = (missedCallCount == 0) ? nil : "\(missedCallCount)"
        }
    }
    
}

extension MainTabBarController : ConnectionEventDelegate {
    
    func onConnectionFailed(error: FlyError) {
        
    }
    
    func onReconnecting() {
        
    }
    
    func onConnected() {
        if ContactSyncManager.getFriendListSyncStatus() {
            ContactSyncManager.getRegisterdUsers()
        }
        
    }
    
    func onDisconnected() {
        
    }
}

extension MainTabBarController : UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateSelection()
      }

      func updateSelection() {
        let normalFont = UIFont.font12px_appLight()
        let selectedFont = UIFont.font12px_appMedium()
        viewControllers?.forEach {
          let selected = $0 == self.selectedViewController
          $0.tabBarItem.setTitleTextAttributes([.font: selected ? selectedFont : normalFont], for: .normal)
        }
      }

}


extension MainTabBarController : TabBarDelegate{
    
    func currentTabCount() -> Int {
        self.viewControllers?.count ?? 0
    }

    
    func removeTabAt(index: Int) {
        avilableFeatures = ChatManager.getAvailableFeatures()
        if let vcs =  self.viewControllers{
            self.viewControllers?.remove(at: index)
            self.viewControllers = self.viewControllers
        }
    }
    
    func resetTabs(){
        avilableFeatures = ChatManager.getAvailableFeatures()
        self.viewControllers = tabViewControllers
        setupUI()
    }
    
}

extension MainTabBarController: PrivateChatSwitchDelegate {
    func moveToRecentInTabBar() {
        self.selectedIndex = 0
        NotificationCenter.default.post(name: Notification.Name("PrivateChatSwitch"), object: nil)
    }
}

public protocol TabBarDelegate {
    
    func removeTabAt(index : Int)
    
    func resetTabs()
    
    func currentTabCount() -> Int
}


public protocol PrivateChatSwitchDelegate {

    func moveToRecentInTabBar()

}
