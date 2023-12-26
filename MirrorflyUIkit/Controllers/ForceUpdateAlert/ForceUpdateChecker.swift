//
//  ForceUpdateChecker.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya on 30/01/23.
//

import Foundation
import Firebase
import FirebaseRemoteConfig

protocol OnUpdateNeededListener {
    func onUpdateNeeded(updateUrl : String)
    func onNoUpdateNeeded()
}

class ForceUpdateChecker {

    static let TAG = "ForceUpdateChecker"

    static let FORCE_UPDATE_STORE_URL = "iOS_force_update_store_url"
    static let FORCE_UPDATE_CURRENT_VERSION = "iOS_remote_Update_Version"
    static let FORCE_UPDATE_REQUIRED = "iOS_remote_Update_IsNeed"
    static let FORCE_UPDATE_TITLE = "iOS_remote_title"
    static let FORCE_UPDATE_DESCRIPTION = "iOS_remote_description"

    var listener : OnUpdateNeededListener

    init(listener : OnUpdateNeededListener) {
        self.listener = listener
    }

    func checkIsNeedUpdate(){
        let remoteConfig = RemoteConfig.remoteConfig()
        let forceRequired = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_REQUIRED].boolValue

        print("\(ForceUpdateChecker.TAG) : forceRequired : \(forceRequired)")
        
        if(forceRequired == true){

            let currentVersion = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_CURRENT_VERSION].stringValue
            print("\(ForceUpdateChecker.TAG) : currentVersion: \(currentVersion!)")

            if(currentVersion != nil){
                let appVersion = getAppVersion()

                if( currentVersion != appVersion){

                    let url = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_STORE_URL].stringValue
                    if(url != nil){
                        listener.onUpdateNeeded(updateUrl: url! )
                    }
                }
                else {
                    listener.onNoUpdateNeeded()
                }
            }
            else {
                listener.onNoUpdateNeeded()
            }
        } else {
            listener.onNoUpdateNeeded()
        }
    }
    
    func setTitleAndDescription() -> (String?,String?) {
        let remoteConfig = RemoteConfig.remoteConfig()
        let title = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_TITLE].stringValue
        let description = remoteConfig[ForceUpdateChecker.FORCE_UPDATE_DESCRIPTION].stringValue
        return (title,description)
    }

    func getAppVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
