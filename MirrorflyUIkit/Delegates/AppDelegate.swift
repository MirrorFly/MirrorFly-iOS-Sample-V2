//
//  AppDelegate.swift
//  MirrorflyUIkit
//
//  Created by User on 20/05/21.
//

import UIKit
import IQKeyboardManagerSwift
import UserNotifications
import Firebase
import FirebaseMessaging
import IQKeyboardManagerSwift
import GoogleMaps
import FlyCommon
import FlyCore
import PushKit
import FlyCall
import RxSwift
import Contacts


let BASE_URL = "https://api-preprod-sandbox.mirrorfly.com/api/v1/"
let LICENSE_KEY = "XXXXXXXXXXXXXXXX"
let XMPP_DOMAIN = "xmpp-preprod-sandbox.mirrorfly.com"
let XMPP_PORT = 5222
let SOCKETIO_SERVER_HOST = "https://signal-preprod-sandbox.mirrorfly.com"
let JANUS_URL = "wss://janus.mirrorfly.com"
let CONTAINER_ID = "group.com.mirrorfly.qa"
let ENABLE_CONTACT_SYNC = false
let IS_LIVE = false
let WEB_LOGIN_URL = "https://webchat-preprod-sandbox.mirrorfly.com/"
let IS_MOBILE_NUMBER_LOGIN = false
let APP_NAME = "UiKitQa"
let ICLOUD_CONTAINER_ID = "iCloud.com.mirrorfly.qa"

let isMigrationDone = "isMigrationDone"

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    var window: UIWindow?
    static var sharedAppDelegateVar: AppDelegate? = nil
    let contactSyncSubject = PublishSubject<Bool>()
    var contactSyncSubscription : Disposable? = nil
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        if !Utility.getBoolFromPreference(key: isMigrationDone) {
//            resetData()
//        }
        CallManager.setAppGroupContainerId(id: CONTAINER_ID )
        FlyDefaults.isTrialLicense = !IS_LIVE
        FlyDefaults.licenseKey = LICENSE_KEY
        FlyDefaults.baseURL = BASE_URL
        FlyDefaults.profileIV = "5RYyc9b32qTIkPMG"
        FlyDefaults.isMobileNumberLogin = IS_MOBILE_NUMBER_LOGIN
        if ENABLE_CONTACT_SYNC{
            startObservingContactChanges()
        }
        print(Utility.getStringFromPreference(key: username),Utility.getStringFromPreference(key: password))
        print(FlyDefaults.myXmppPassword,FlyDefaults.myXmppUsername )
        print(FlyDefaults.myJid)
        print(FlyDefaults.authtoken)
        IQKeyboardManager.shared.enable = true
        GMSServices.provideAPIKey(googleApiKey)
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(ChatViewParentController.self)
        NetworkReachability.shared.startMonitoring()
        
        // Clear Push
        clearPushNotifications()
        registerForPushNotifications()
        
        if FlyDefaults.isBlockedByAdmin {
            navigateToBlockedScreen()
        } else {
            navigateTo()
        }
        
        let groupConfig = try? GroupConfig.Builder.enableGroupCreation(groupCreation: true)
            .onlyAdminCanAddOrRemoveMembers(adminOnly: true)
            .setMaximumMembersInAGroup(membersCount: 200)
            .build()
        assert(groupConfig != nil)
        
        ChatManager.shared.logoutDelegate = self
        ChatManager.shared.adminBlockCurrentUserDelegate = self
        
        try? ChatSDK.Builder.enableContactSync(isEnable: ENABLE_CONTACT_SYNC)
            .setDomainBaseUrl(baseUrl: BASE_URL)
            .signalServer(signalServerUrl: SOCKETIO_SERVER_HOST)
            .setMaximumPinningForRecentChat(maxPinChat: 4)
            .setGroupConfiguration(groupConfig: groupConfig!)
            .deleteMediaFromDevice(delete: true)
            .setAppGroupContainerID(containerID: CONTAINER_ID)
            .buildAndInitialize()
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { val, error in
                }
            )
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        if Utility.getBoolFromPreference(key: isLoggedIn) {
            VOIPManager.sharedInstance.updateDeviceToken()
            RootViewController.sharedInstance.initCallSDK()
        }
        // Added this line so that we can start receing contact updates
        let contactPermissionStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        if contactPermissionStatus == .authorized || contactPermissionStatus == .denied{
            FlyDefaults.isContactPermissionSkipped = false
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.CNContactStoreDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contactsDidChange), name: NSNotification.Name.CNContactStoreDidChange, object: nil)
        
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        NetworkReachability.shared.stopMonitoring()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let deviceToken = fcmToken {
            print(deviceToken)
            Utility.saveInPreference(key: googleToken, value: deviceToken)
        }
    }
    
    class func sharedAppDelegate() -> AppDelegate? {
        let userInfoBlock = {
            // Code for the method goes here
            sharedAppDelegateVar = UIApplication.shared.delegate as? AppDelegate
        }
        Thread.isMainThread ? userInfoBlock() : DispatchQueue.main.async(execute: userInfoBlock)
        
        return sharedAppDelegateVar
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("#appDelegate applicationDidBecomeActive")
        if Utility.getBoolFromPreference(key: isLoggedIn) && (FlyDefaults.isLoggedIn) {
            ChatManager.makeXMPPConnection()
            NSLog("#sync request from  applicationDidBecomeActive")
            if FlyDefaults.isContactSyncNeeded || ContactSyncManager.shared.isContactPermissionChanged() {
                ContactSyncManager.shared.syncContacts(){ isSuccess,_,_ in
                    print("#sync #contactSync status => \(isSuccess)")
                }
            }
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("#appDelegate applicationDidEnterBackground")
        if (FlyDefaults.isLoggedIn) {
            ChatManager.disconnectXMPPConnection()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        contactSyncSubscription?.dispose()
        NetStatus.shared.stopMonitoring()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.CNContactStoreDidChange, object: nil)
    }
    

}

// MARK:- Push Notifications
extension AppDelegate : UNUserNotificationCenterDelegate {
    /// Register for APNS Notifications
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    FlyUtils.setBaseUrl(BASE_URL)
                }
            }
        }
        registerForVOIPNotifications()
    }
    /// This method is used to clear notifications and badge count
    func clearPushNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        if token.count == 0 {
            print("Push Status Credentials APNS:")
            return;
        }
        print("#token appDelegate \(token)")
        print("#token application DT => \(token)")
        FlyCallUtils.sharedInstance.setConfigUserDefaults(token, withKey: "updatedTokenAPNS")
        Utility.saveInPreference(key: googleToken, value: token)
        VOIPManager.sharedInstance.updateDeviceToken()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Push didFailToRegisterForRemoteNotificationsWithError)")
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Push userInfo \(userInfo)")
        completionHandler(.noData)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.threadIdentifier.contains(XMPP_DOMAIN){
            if FlyDefaults.isBlockedByAdmin {
                navigateToBlockedScreen()
            } else {
                navigateToChatScreen(chatId: response.notification.request.content.threadIdentifier, completionHandler: completionHandler)
            }
        }
    }
}
// MARK:- VOIP Notifications
extension AppDelegate : PKPushRegistryDelegate {
    func registerForVOIPNotifications() {
        let pushRegistry = PKPushRegistry(queue: .main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
        //print out the VoIP token. We will use this to test the nofications.
        NSLog("VoIP Token: \(pushCredentials)")
        let deviceTokenString = pushCredentials.token.reduce("") { $0 + String(format: "%02X", $1) }
        print("#token pushRegistry VT => \(deviceTokenString)")
        print(deviceTokenString)
        FlyCallUtils.sharedInstance.setConfigUserDefaults(deviceTokenString, withKey: "updatedTokenVOIP")
        Utility.saveInPreference(key: voipToken, value: deviceTokenString)
        VOIPManager.sharedInstance.updateDeviceToken()
    }
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        NSLog("Push VOIP Received with Payload - %@",payload.dictionaryPayload)
        VOIPManager.sharedInstance.processPayload(payload.dictionaryPayload)
    }
}


extension AppDelegate {
    
    func startObservingContactChanges(){
        contactSyncSubscription = contactSyncSubject.throttle(.seconds(3), latest: false ,scheduler: MainScheduler.instance).subscribe(onNext: { bool in
            if bool{
                if !FlyDefaults.isContactPermissionSkipped{
                    ContactSyncManager.shared.syncContacts(){ isSuccess,_,_ in
                       print("#contact Sync status => \(isSuccess)")
                    }
                }
            }
        })
    }
    
    
    @objc func contactsDidChange(notification: NSNotification){
        print("#contact #appdelegate @contactsDidChange")
        if Utility.getBoolFromPreference(key: isLoggedIn) && ENABLE_CONTACT_SYNC {
            FlyDefaults.isContactSyncNeeded = true
            contactSyncSubject.onNext(true)
        }
    }
    
    
    func navigateToChatScreen(chatId : String,completionHandler: @escaping () -> Void){
        var dismisLastViewController = false
        if let profileDetails = ContactManager.shared.getUserProfileDetails(for: chatId) , chatId != FlyDefaults.myJid{
            if #available(iOS 13, *) {
                guard let rootViewController = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else {
                    completionHandler()
                    return
                }
                
                if let rootVC = rootViewController as? UINavigationController{
                    if let currentVC = rootVC.children.last, currentVC.isKind(of: ChatViewParentController.self){
                        dismisLastViewController = true
                    }
                }
                
                if let chatViewController =  UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController, let navigationController = rootViewController as? UINavigationController{
                    chatViewController.getProfileDetails = profileDetails
                    let color = getColor(userName: getUserName(jid: profileDetails.jid,name: profileDetails.name, nickName: profileDetails.nickName, contactType: profileDetails.contactType))
                    chatViewController.contactColor = color
                    if dismisLastViewController{
                        navigationController.popViewController(animated: false)
                    }
                    navigationController.pushViewController(chatViewController, animated: !dismisLastViewController)
                }
                completionHandler()
            } else {
                if let rootVC = self.window?.rootViewController as? UINavigationController {
                    if let currentVC = rootVC.children.last, currentVC.isKind(of: ChatViewParentController.self){
                        rootVC.popViewController(animated: true)
                    }
                }
                if let chatViewController =  UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController, let navigationController = self.window?.rootViewController as? UINavigationController{
                    chatViewController.getProfileDetails = profileDetails
                    let color = getColor(userName: getUserName(jid: profileDetails.jid,name: profileDetails.name, nickName: profileDetails.nickName, contactType: profileDetails.contactType))
                    chatViewController.contactColor = color
                    if dismisLastViewController{
                        navigationController.popViewController(animated: false)
                    }
                    navigationController.pushViewController(chatViewController, animated: !dismisLastViewController)
                }
                completionHandler()
            }
        }
    }
    
    func resetData(){
        print("#migration resetData")
        Utility.clearUserDefaults()
        FlyConstants.suiteName = CONTAINER_ID
        ChatManager.shared.resetFlyDefaults()
        let fileManager:FileManager = FileManager.default
        if let realmPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CONTAINER_ID)?.appendingPathComponent("Realm").path {
            if let fileList = try? FileManager.default.contentsOfDirectory(atPath: realmPath){
                for path in fileList {
                    let fullPath = realmPath + "/" + path
                    if fileManager.fileExists(atPath: fullPath){
                        try! fileManager.removeItem(atPath: fullPath)
                        print("#migration #files \(fullPath) deleted")
                    }else{
                        print("#migration #files \(fullPath) unable to delete")
                    }
                }
            }
        }
        Utility.saveInPreference(key: isMigrationDone, value: true)
    }

}
// If a user logged in a new device this delegate will be triggered.otpViewController
extension AppDelegate : LogoutDelegate {
    func didReceiveLogout() {
        print("AppDelegate LogoutDelegate ===> LogoutDelegate")
        Utility.saveInPreference(key: isProfileSaved, value: false)
        Utility.saveInPreference(key: isLoggedIn, value: false)
        ChatManager.disconnectXMPPConnection()
        ChatManager.shared.clearAllTablesInDB()
        ChatManager.shared.resetFlyDefaults()
        var controller : OTPViewController?
        if #available(iOS 13.0, *) {
            controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "OTPViewController")
        } else {
            // Fallback on earlier versions
            controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OTPViewController") as? OTPViewController
        }
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let navigationController = window?.rootViewController  as? UINavigationController, let otpViewController = controller {
            navigationController.popToRootViewController(animated: false)
            navigationController.navigationBar.isHidden = true
            navigationController.pushViewController(otpViewController, animated: false)
        }
    }
}

// If user blocked by admin in control panel this delegate will be triggered
extension AppDelegate : AdminBlockCurrentUserDelegate {
    func didBlockOrUnblockCurrentUser(userJid: String, isBlocked: Bool) {
        if isBlocked {
            navigateToBlockedScreen()
        } else {
            navigateTo()
        }
    }
    
}

extension AppDelegate {
    
    func navigateToBlockedScreen() {
        if CallManager.isOngoingCall() {
            CallManager.disconnectCall()
        }
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "BlockedByAdminViewController") as! BlockedByAdminViewController
        UIApplication.shared.keyWindow?.rootViewController =  UINavigationController(rootViewController: initialViewController)
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
    }
    
    func navigateTo() {
        if Utility.getBoolFromPreference(key: isProfileSaved) {
            let navigationController : UINavigationController
            if ENABLE_CONTACT_SYNC {
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
            UIApplication.shared.keyWindow?.rootViewController = navigationController
            UIApplication.shared.keyWindow?.makeKeyAndVisible()
        }else if Utility.getBoolFromPreference(key: isLoggedIn) {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            UIApplication.shared.keyWindow?.rootViewController =  UINavigationController(rootViewController: initialViewController)
            UIApplication.shared.keyWindow?.makeKeyAndVisible()
        }
    }
}
