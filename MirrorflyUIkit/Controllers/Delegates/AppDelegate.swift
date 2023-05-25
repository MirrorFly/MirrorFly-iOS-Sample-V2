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
import PushKit
import RxSwift
import Contacts
import CallKit
import FirebaseRemoteConfig
import AVFoundation
import MirrorFlySDK


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

#if DEBUG

let ISEXPORT = false
#else
let ISEXPORT = true
#endif


var pushChatId: String?

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    var window: UIWindow?
    static var sharedAppDelegateVar: AppDelegate? = nil
    let contactSyncSubject = PublishSubject<Bool>()
    var contactSyncSubscription : Disposable? = nil

    var postNotificationdidEnterBackground : NotificationCenter? = nil
    
    var notificationView: CustomNotificationView?
    var player: AVAudioPlayer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        if !Utility.getBoolFromPreference(key: isMigrationDone) {
//            resetData()
//        }
        
        let groupConfig = try? GroupConfig.Builder.enableGroupCreation(groupCreation: true)
            .onlyAdminCanAddOrRemoveMembers(adminOnly: true)
            .setMaximumMembersInAGroup(membersCount: 200)
            .build()
        assert(groupConfig != nil)
        
        try? ChatSDK.Builder.setAppGroupContainerID(containerID: CONTAINER_ID)
            .setLicenseKey(key: LICENSE_KEY)
            .isTrialLicense(isTrial: !IS_LIVE)
            .setDomainBaseUrl(baseUrl: BASE_URL)
            .setGroupConfiguration(groupConfig: groupConfig!)
            .buildAndInitialize()
        
        ChatManager.enableContactSync(isEnable: ENABLE_CONTACT_SYNC)
        ChatManager.setSignalServer(signalServerUrl: SOCKETIO_SERVER_HOST)
        ChatManager.setMaximumPinningForRecentChat(maxPinChat: 4)
        ChatManager.deleteMediaFromDevice(delete: true)
        
        
        FlyDefaults.isMobileNumberLogin = IS_MOBILE_NUMBER_LOGIN
        FlyDefaults.webLoginUrl = WEB_LOGIN_URL
        if ENABLE_CONTACT_SYNC{
            startObservingContactChanges()
        }
        IQKeyboardManager.shared.enable = true
        GMSServices.provideAPIKey(googleApiKey)
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(ChatViewParentController.self)
        IQKeyboardManager.shared.disabledTouchResignedClasses.append(ChatViewParentController.self)
        IQKeyboardManager.shared.disabledTouchResignedClasses.append(ImageEditController.self)
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(ImageEditController.self)
        NetworkReachability.shared.startMonitoring()
        KeyboardStateListener.shared.start()

        if FlyDefaults.appLockenable || FlyDefaults.appFingerprintenable {
            FlyDefaults.showAppLock = true
        }

        // Clear Push
        clearPushNotifications()
        registerForPushNotifications()
        
        if FlyDefaults.isBlockedByAdmin {
            navigateToBlockedScreen()
        } else {
            navigateTo()
        }
        
        ChatManager.shared.logoutDelegate = self
        ChatManager.shared.adminBlockCurrentUserDelegate = self
        ChatManager.shared.localNotificationDelegate = self
        CallManager.missedCallNotificationDelegate = self
        
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
        ChatManager.setMediaEncryption(isEnable: false)
        ChatManager.hideNotificationContent(hide: false)
        FlyUtils.setAppName(appName: APP_NAME)
        VOIPManager.sharedInstance.updateDeviceToken()
        let licenceKeyForEncryption = String(LICENSE_KEY.prefix(16))
        FlyDefaults.profileIV = licenceKeyForEncryption
        networkMonitor()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
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
        
        if FlyDefaults.isBlockedByAdmin {
            navigateToBlockedScreen()
            return
        }

        if Utility.getBoolFromPreference(key: isLoggedIn) && (FlyDefaults.isLoggedIn) {
//            ChatManager.connect()
        }
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if (current is AuthenticationPINViewController || current is FingerPrintPINViewController) {
            if let vc = current as? FingerPrintPINViewController {
                if vc.isSystemCancel {
                    vc.authenticationWithTouchID()
                }
            }
           return
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(didEnterBackground), object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("#appDelegate applicationDidEnterBackground")
        FlyDefaults.appBackgroundTime = Date()
        postNotificationdidEnterBackground = NotificationCenter.default
        postNotificationdidEnterBackground?.post(name: Notification.Name(didEnterBackground), object: nil)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        contactSyncSubscription?.dispose()

        NetStatus.shared.stopMonitoring()
        if FlyDefaults.appLockenable || FlyDefaults.appFingerprintenable {
            FlyDefaults.showAppLock = true
        }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.CNContactStoreDidChange, object: nil)
    }

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        print("applicationProtectedDataDidBecomeAvailable")
        if (FlyDefaults.appLockenable || FlyDefaults.appFingerprintenable) {
            FlyDefaults.showAppLock = true
            showApplockScreen()
        }
    }

    func showApplockScreen() {
        
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if (current is AuthenticationPINViewController || current is FingerPrintPINViewController) {
           return
        }
        
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let navigationController = window?.rootViewController  as? UINavigationController
        if FlyDefaults.appFingerprintenable  && FlyDefaults.appLockenable && FlyDefaults.showAppLock {
            if !FlyDefaults.faceOrFingerAuthenticationFails {
                let initialViewController = FingerPrintPINViewController(nibName: "FingerPrintPINViewController", bundle: nil)
                initialViewController.modalPresentationStyle = .overFullScreen
                navigationController?.present(initialViewController, animated: false)
            } else {
                let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
                initialViewController.modalPresentationStyle = .overFullScreen
                //navigationController?.present(initialViewController, animated: false)
                navigationController?.pushViewController(initialViewController, animated: false)
            }
        }
        else if FlyDefaults.appLockenable && FlyDefaults.appFingerprintenable == false && FlyDefaults.showAppLock {
            let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
            initialViewController.modalPresentationStyle = .overFullScreen
            //navigationController?.present(initialViewController, animated: false)
            navigationController?.pushViewController(initialViewController, animated: false)
        }
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
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        if token.count == 0 {
            print("Push Status Credentials APNS:")
            return;
        }
        print("#token appDelegate \(token)")
        print("#token application DT => \(token)")
        VOIPManager.sharedInstance.saveAPNSToken(token: token)
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
                let messageId = response.notification.request.content.userInfo["message_id"] as? String ?? ""
                let message = FlyMessenger.getMessageOfId(messageId: messageId)
                if response.notification.request.trigger is UNPushNotificationTrigger {
                    pushChatId = message?.chatUserJid ?? ""
                } else {
                    pushChatId = message?.chatUserJid ?? ""
                    if !FlyDefaults.showAppLock {
                        pushChatId = nil
                        navigateToChatScreen(chatId: message?.chatUserJid ?? "", completionHandler: completionHandler)
                    }
                }
            }
        }else if response.notification.request.content.threadIdentifier == "media-call" {
            pushChatId = "media-call"
            if FlyDefaults.isBlockedByAdmin {
                navigateToBlockedScreen()
            } else {
               
                let navigationController : UINavigationController
                let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                initialViewController.selectedIndex = 2
                navigationController =  UINavigationController(rootViewController: initialViewController)
                
                UIApplication.shared.keyWindow?.rootViewController = navigationController
                UIApplication.shared.keyWindow?.makeKeyAndVisible()
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
        VOIPManager.sharedInstance.saveVOIPToken(token: deviceTokenString)
        Utility.saveInPreference(key: voipToken, value: deviceTokenString)
        VOIPManager.sharedInstance.updateDeviceToken()
    }
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        NSLog("Push VOIP Received with Payload - %@",payload.dictionaryPayload)
        print("#callopt \(FlyUtils.printTime()) pushRegistry voip received")
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
                    navigationController.removeViewController(ChatViewParentController.self)
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
                    navigationController.removeViewController(ChatViewParentController.self)
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
        logoutLocally()
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
        
        AppAlert.shared.showToast(message: "The session has been logged out")
    }
}

// If user blocked by admin in control panel this delegate will be triggered
extension AppDelegate : AdminBlockCurrentUserDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        if isBlocked && CallManager.isOngoingCall() && CallManager.isOneToOneCall() && CallManager.getEndCallerId() == userJid {
            CallManager.disconnectCall()
        }
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        print("AppDelegate didBlockOrUnblockGroup \(groupJid) \(isBlocked)")
        if isBlocked && CallManager.isOngoingCall() && CallManager.getGroupID() == groupJid{
            CallManager.disconnectCall()
        }
    }
    
    func didBlockOrUnblockCurrentUser(userJid: String, isBlocked: Bool) {
        if isBlocked {
            navigateToBlockedScreen()
        } else {
            navigateTo()
        }
    }
    
}

extension AppDelegate {
    
    func logoutLocally(){
           Utility.saveInPreference(key: isProfileSaved, value: false)
           Utility.saveInPreference(key: isLoggedIn, value: false)
           ChatManager.disconnect()
           ChatManager.shared.resetFlyDefaults()
           FlyDefaults.isBlockedByAdmin = false
    }
    
    func navigateToBlockedScreen() {
        logoutLocally()
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
        }else if Utility.getBoolFromPreference(key: isLoggedIn) && FlyDefaults.myMobileNumber != "" {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            UIApplication.shared.keyWindow?.rootViewController =  UINavigationController(rootViewController: initialViewController)
            UIApplication.shared.keyWindow?.makeKeyAndVisible()
        }
    }
}

extension AppDelegate {
    func networkMonitor() {
        NetworkReachability.shared.netStatusChangeHandler = {
            if NetworkReachability.shared.isConnected {
                //ChatManager.shared.startAutoDownload()
            }
        }
    }
}

extension AppDelegate : LocalNotificationDelegate {
    
    func showOrUpdateOrCancelNotification(jid: String, chatMessage: ChatMessage, groupId: String) {
        
        print("#notification \(chatMessage.chatUserJid) \(groupId) \(chatMessage.senderUserJid)")
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if (current is RestoreViewController || current is BackupProgressViewController) {
            return
        }
        if ChatManager.onGoingChatUserJid == chatMessage.senderUserJid || (ChatManager.onGoingChatUserJid == groupId  && groupId != "") {
            
            if !CallManager.isOngoingCall() {
                self.playSound()
            }
            
        } else {
            
            var title = "MirrorFly"
            var userId = chatMessage.chatUserJid
            if !groupId.isEmpty{
                userId = chatMessage.senderUserJid
            }
            //let profileDetails = ChatManager.database.rosterManager.getContact(jid: userId)
            let profileDetails = ContactManager.shared.getUserProfileDetails(for: userId)
            let userName =  FlyUtils.getUserName(jid: profileDetails?.jid ?? "0000000000", name: profileDetails?.name ?? "Fly User", nickName: profileDetails?.nickName ?? "Fly User", contactType: profileDetails?.contactType ?? .unknown)
            title = userName
            var message = chatMessage.messageTextContent
            if chatMessage.isMessageRecalled == true {
                message = "This message was deleted"
            } else {
                switch chatMessage.messageType{
                case .text :
                    message = (message.count > 64) ? message : message
                case .notification:
                    if chatMessage.messageChatType == .groupChat {
                        message = (message.count > 64) ? message : message
                    }
                default :
                    message = chatMessage.messageType.rawValue.capitalized
                }
            }
            var isCarbon = false
            if FlyDefaults.hideNotificationContent{
                let (messageCount, chatCount) = ChatManager.getUNreadMessageAndChatCount()
                var titleContent = emptyString()
                if chatCount == 1{
                    titleContent = "\(messageCount) \(messageCount == 1 ? "message" : "messages")"
                }else{
                    titleContent = "\(messageCount) messages from \(chatCount) chats"
                }
                title = FlyDefaults.appName + " (\(titleContent))"
                message = "New Message"
            }else{
                if groupId.isEmpty{
                    title = userName
                }else{
                    //let profileDetails = ChatManager.database.rosterManager.getContact(jid: groupId)
                    let profileDetails = ContactManager.shared.getUserProfileDetails(for: groupId)
                    title = "\(title) @ \(profileDetails?.name ?? "Fly Group ")"
                }
            }
            
            if chatMessage.senderUserJid == FlyDefaults.myJid{
                isCarbon = true
            }
            if isCarbon {
                message = "Duplicate message"
            }
            
            if !chatMessage.mentionedUsersIds.isEmpty {
                message = ChatUtils.getMentionTextContent(message: message, isMessageSentByMe: chatMessage.isMessageSentByMe, mentionedUsers: chatMessage.mentionedUsersIds).string
            }

            executeOnMainThread {
                self.showCustomNotificationView(title: title , message: message, chatMessage: chatMessage)
            }
        }
    }
}

extension AppDelegate : MissedCallNotificationDelegate {
    
    func onMissedCall(isOneToOneCall: Bool, userJid: String, groupId: String?, callType: String, userList: [String]) {
        
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if (current is CallLogViewController) {
            //Application Badge Count
            var appBadgeCount = UIApplication.shared.applicationIconBadgeNumber
            appBadgeCount = appBadgeCount - FlyDefaults.unreadMissedCallCount
            UIApplication.shared.applicationIconBadgeNumber = appBadgeCount
            //CallLogs Badge Count
            FlyDefaults.unreadMissedCallCount = 0
            NotificationCenter.default.post(name: NSNotification.Name("updateUnReadMissedCallCount"), object: FlyDefaults.unreadMissedCallCount)
        }
        
        var callMode = ""
        if CallManager.getTempRoomID() == nil {
            callMode = (userList.count > 1) ? "group " : ""
        }else{
            callMode = CallManager.getTempIsGroupCall() ? "group " : ""
        }
        let conjuction =  (callMode == "group " || callType == "video call") ? " a " : " an "
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.showCustomNotificationView(title: CallManager.getNameString() , message: "You missed" +  conjuction + callMode + callType, chatMessage: "media-call")
        })
    }
}

extension AppDelegate {
    
    func showCustomNotificationView(title: String, message: String, chatMessage: Any? = nil) {
        
        if self.notificationView != nil {
            self.notificationView?.removeFromSuperview()
        }
        
        let window = UIApplication.shared.keyWindow!
       
        guard let view = Bundle.main.loadNibNamed("CustomNotificationView", owner: self, options: nil)?[0] as? CustomNotificationView else {
            return
        }
        view.frame = CGRect(x: 10, y: window.safeAreaInsets.top - 130, width: (window.bounds.width) - 20, height: 70)
        view.titleLabel.text = title
        view.messageLabel.text = message
        view.accessibilityElements = [chatMessage as Any]
        view.logoImg.applyShadow(1.0, shawdowOpacity: 0.2)
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleUpSwipe(_:)))
        swipeUp.direction = UISwipeGestureRecognizer.Direction.up
        view.addGestureRecognizer(swipeUp)
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 3.0
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.masksToBounds = false
        
        window.addSubview(view)
        notificationView = view
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            if !CallManager.isOngoingCall() {
                
                self.playSound()
                
                if FlyDefaults.vibrationEnable {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
            }
           
        }
        
        UIView.animate(withDuration: 0.5) {
            view.frame = CGRect(x: 10, y:   window.safeAreaInsets.top, width: (window.bounds.width) - 20, height: 70)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            UIView.animate(withDuration: 0.3, delay: 0, options: .transitionFlipFromTop, animations:  {
                view.frame = CGRect(x: 10, y:  window.safeAreaInsets.top - 130, width: (window.bounds.width) - 20, height: 70)
            },completion: {_ in })
        })
    }
        

        @objc func handleUpSwipe(_ recognizer: UISwipeGestureRecognizer) {
            
            print("Swiped on a Notification View")
            UIView.animate(withDuration: 0.3, delay: 0, options: .transitionFlipFromTop, animations:  {
                
                guard let window = UIApplication.shared.keyWindow else {
                    return
                }
                
                self.notificationView?.frame = CGRect(x: 10, y:  window.safeAreaInsets.top - 130, width:window.frame.width - 20, height: 70)
                
            },completion: {_ in
                self.notificationView?.removeFromSuperview()
            })
            
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer?) {
            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true)
            let current = UIApplication.shared.keyWindow?.getTopViewController()
            if (current is ProfileViewController) {
                return
            }
            if (current is CallViewController) {
                (current as! CallViewController).showCallOverlay()
            }
            
            //Redirect to chat page
            if let message = (sender?.view?.accessibilityElements as? [ChatMessage])?.first {
                
                print("Tap on a Notification View \(message)")
                
                if FlyDefaults.isBlockedByAdmin {
                    navigateToBlockedScreen()
                } else {
                    let messageId = message.messageId
                    let message = FlyMessenger.getMessageOfId(messageId: messageId)
                    pushChatId = message?.chatUserJid ?? ""
                    
                    if !FlyDefaults.showAppLock {
                        pushChatId = nil
                        navigateToChatScreen(chatId: message?.chatUserJid ?? "", completionHandler: {})
                    }
                }
            }
            
            //Redirect to call-logs page
            if let message = sender?.view?.accessibilityElements as? [String] {
                print("Tap on a Call View \(message)")
                pushChatId = "media-call"
                if FlyDefaults.isBlockedByAdmin {
                    navigateToBlockedScreen()
                } else {
                    
                    let navigationController : UINavigationController
                    let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                    let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                    initialViewController.selectedIndex = 2
                    navigationController =  UINavigationController(rootViewController: initialViewController)
                    
                    UIApplication.shared.keyWindow?.rootViewController = navigationController
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                }
            }
            
            self.notificationView?.removeFromSuperview()
        }

        func playSound() {
            
            if !(FlyDefaults.selectedNotificationSoundName[NotificationSoundKeys.name.rawValue]?.contains("None") ?? false) && FlyDefaults.notificationSoundEnable {
                
                guard let path = Bundle.main.path(forResource: "wheep", ofType:"mp3") else {
                    return }
                let url = URL(fileURLWithPath: path)

                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.soloAmbient, options: AVAudioSession.CategoryOptions.mixWithOthers)
                    try AVAudioSession.sharedInstance().setActive(true)
                    player = try AVAudioPlayer(contentsOf: url)
                    player?.play()
                    player?.volume = 1.0
                    
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }

}
