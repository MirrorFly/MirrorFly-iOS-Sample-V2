//
//  SceneDelegate.swift
//  MirrorflyUIkit
//
//  Created by User on 20/05/21.
//

import UIKit
import MirrorFlySDK
import FirebaseRemoteConfig

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var remoteConfig: RemoteConfig!
    static var sharedAppDelegateVar: SceneDelegate? = nil
    
    var postNotificationdidEnterBackground : NotificationCenter? = nil

    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        BackupManager.shared.backupDelegate = self
        if CommonDefaults.appLockenable || CommonDefaults.appFingerprintenable {
            CommonDefaults.showAppLock = true
        }

        if ContactManager.isBlockedByAdmin() {
            navigateToBlockedScreen()
        } else if Utility.getBoolFromPreference(key: isProfileSaved) {
            let navigationController : UINavigationController
            if IS_LIVE {
                if !Utility.getBoolFromPreference(key: isLoginContactSyncDone){
                    let storyboard = UIStoryboard.init(name: Storyboards.profile, bundle: nil)
                    let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.contactSyncController) as! ContactSyncController
                    navigationController =  UINavigationController(rootViewController: initialViewController)
                }else{
                    let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                    let initialViewController =  storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                    navigationController =  UINavigationController(rootViewController: initialViewController)
                }
            }else{
                let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                navigationController =  UINavigationController(rootViewController: initialViewController)
            }
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
        }else if Utility.getBoolFromPreference(key: isLoggedIn) && ContactManager.getMyProfile().mobileNumber != "" {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            self.window?.rootViewController =  UINavigationController(rootViewController: initialViewController)
            self.window?.makeKeyAndVisible()
        }
        
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
            guard let _ = (scene as? UIWindowScene) else { return }
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    class func sharedAppDelegate() -> SceneDelegate? {
        let userInfoBlock = {
            // Code for the method goes here
            sharedAppDelegateVar = UIApplication.shared.delegate as? SceneDelegate
        }
        Thread.isMainThread ? userInfoBlock() : DispatchQueue.main.async(execute: userInfoBlock)
        
        return sharedAppDelegateVar
    }

    @available(iOS 13.0, *)
    func sceneDidDisconnect(_ scene: UIScene) {
        if CommonDefaults.appLockenable || CommonDefaults.appFingerprintenable {
            CommonDefaults.showAppLock = true
        }
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    @available(iOS 13.0, *)
    func sceneDidBecomeActive(_ scene: UIScene) {
//        print("#scene sceneDidBecomeActive \(FlyDefaults.isLoggedIn)")
        if ContactManager.isBlockedByAdmin() {
            navigateToBlockedScreen()
            return
        }
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if (current is AuthenticationPINViewController || current is FingerPrintPINViewController || current is PrivateChatAuthenticationPINViewController || current is PrivateChatFingerPrintPINViewController) {
            if let vc = current as? FingerPrintPINViewController  {
                if vc.isSystemCancel {
                    vc.authenticationWithTouchID()
                }
            } else if let vc = current as? PrivateChatFingerPrintPINViewController  {
                if vc.isSystemCancel {
                    vc.authenticationWithTouchID()
                }
            }
           return
        }
        NotificationCenter.default.post(name: NSNotification.Name(didBecomeActive), object: nil)
        //setup remote config
        setupRemoteConfig()
        ForceUpdateChecker(listener: self).checkIsNeedUpdate()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(didEnterBackground), object: nil)
        if CommonDefaults.isBackupCompleted {
            iCloudmanager().checkAutoBackupSchedule()
        } else {
            iCloudmanager().uploadBackupFile(fileUrl: BackupManager.shared.getBackupFilePath()?.absoluteString ?? emptyString())
        }
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }


    @available(iOS 13.0, *)
    func sceneWillResignActive(_ scene: UIScene) {
        //FlyDefaults.appBackgroundTime = Date()
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        NetworkReachability.shared.startMonitoring()

        if (CommonDefaults.appLockenable || CommonDefaults.appFingerprintenable) {
            let secondsDifference = Calendar.current.dateComponents([.minute, .second], from: CommonDefaults.appBackgroundTime, to: Date())
            if secondsDifference.second ?? 0 > 32 || secondsDifference.minute ?? 0 > 0 {
                CommonDefaults.showAppLock = true
                CommonDefaults.appLockOnPrivateChat = false
                CommonDefaults.privateChatOnChatScreen = false
            }
        }
//        print("#scene sceneWillEnterForeground \(FlyDefaults.isLoggedIn)")
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    @available(iOS 13.0, *)
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("#scene sceneDidEnterBackground")
        CommonDefaults.appBackgroundTime = Date()
        postNotificationdidEnterBackground = NotificationCenter.default
        postNotificationdidEnterBackground?.post(name: Notification.Name(didEnterBackground), object: nil)

        if CommonDefaults.isInPrivateChat {
            if CommonDefaults.appLockOnPrivateChat || CommonDefaults.privateChatOnChatScreen {
                CommonDefaults.showPrivateLockRecent = false
            } else {
                CommonDefaults.showPrivateLockRecent = true
            }
            if let controller = UIApplication.shared.keyWindow?.getTopViewController() {
                if controller.isKind(of: UIAlertController.self) || controller.isKind(of: UIActivityViewController.self) || controller.isKind(of: GroupInfoOptionsViewController.self) {
                    controller.dismiss(animated: false)
                }
            }
        } else {
            CommonDefaults.showPrivateLockRecent = false
        }
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

@available(iOS 13.0, *)
extension SceneDelegate {
    func navigateToBlockedScreen() {
        Utility.saveInPreference(key: isProfileSaved, value: false)
        Utility.saveInPreference(key: isLoggedIn, value: false)
        ChatManager.disconnect()
        ChatManager.shared.resetFlyDefaults()
        if CallManager.isOngoingCall() {
            CallManager.disconnectCall()
        }
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "BlockedByAdminViewController") as! BlockedByAdminViewController
        self.window?.rootViewController =  UINavigationController(rootViewController: initialViewController)
        self.window?.makeKeyAndVisible()
    }
}

//Mark:- RemoteConfig Setup
@available(iOS 13.0, *)
extension SceneDelegate {
    func setupRemoteConfig(){
        
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        var expirationDuration = 60
        
        remoteConfig?.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { [weak self] (status, error) in
            if status == .success {
                print("config fetch done")
                self?.remoteConfig?.activate()
                self?.setVersionDetails()
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
        }
    }
    
    func setVersionDetails() {
        let isUpdateNeed = remoteConfig?.configValue(forKey: "iOS_remote_Update_IsNeed").boolValue
        let liveAppVersion = remoteConfig?.configValue(forKey: "iOS_remote_Update_Version").stringValue
        let remoteStoreURL = remoteConfig?.configValue(forKey: "iOS_force_update_store_url").stringValue
        let remoteTitle = remoteConfig?.configValue(forKey: "iOS_remote_title").stringValue
        let remote_Description = remoteConfig?.configValue(forKey: "iOS_remote_description").stringValue
        
        //set in app defaults
        let defaults : [String : Any] = [
            ForceUpdateChecker.FORCE_UPDATE_REQUIRED : isUpdateNeed ?? false,
            ForceUpdateChecker.FORCE_UPDATE_CURRENT_VERSION : liveAppVersion ?? "",
            ForceUpdateChecker.FORCE_UPDATE_STORE_URL : remoteStoreURL ?? "",
            ForceUpdateChecker.FORCE_UPDATE_TITLE : remoteTitle ?? "",
            ForceUpdateChecker.FORCE_UPDATE_DESCRIPTION : remote_Description ?? ""
        ]
        remoteConfig?.setDefaults(defaults as? [String : NSObject])
    }
}

@available(iOS 13.0, *)
extension SceneDelegate : OnUpdateNeededListener {
    func onUpdateNeeded(updateUrl: String) {
        let initialViewController = ForceUpdateAlertViewController(nibName: "ForceUpdateAlert", bundle: nil)
        initialViewController.modalPresentationStyle = .overFullScreen
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if current is ForceUpdateAlertViewController {
           return
        }
        current?.present(initialViewController, animated: true,completion: nil)
    }
    
    func onNoUpdateNeeded() {
        print("onNoUpdateNeeded()")
    }
}
extension SceneDelegate: BackupEventDelegate {
    func backupProgressDidReceive(completedCount: String, completedSize: String) {
        
    }
    
    func backupDidFinish(fileUrl: String) {
        Utility.setAutoBackupDate()
        iCloudmanager().uploadBackupFile(fileUrl: fileUrl)
    }
    
    func backupDidFailed(errorMessage: String) {
        
    }
    
    
}
