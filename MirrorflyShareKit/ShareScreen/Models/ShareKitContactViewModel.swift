//
//  ShareKitContactViewModel.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 28/02/23.
//

import Foundation
import MirrorFlySDK

class ContactViewModel : NSObject
{

    override init() {
        super.init()

    }
    func getContacts(fromServer: Bool, removeContacts : [String] = [],completionHandler:  @escaping ([ProfileDetails]?, String?)-> Void) {
        if fromServer{
            syncContacts()
        }
        guard let myJid = try? FlyUtils.getMyJid() else {
            return
        }
        ContactManager.shared.getRegisteredUsers(fromServer: fromServer) {  isSuccess, flyError, flyData in
            var data  = flyData
            if isSuccess {
                if  let  contactsList = data.getData() as? [ProfileDetails]  {
                    var filteredContact = contactsList.filter( {$0.profileChatType != .groupChat && $0.jid != myJid && $0.isBlockedByAdmin == false})
                    filteredContact.removeAll { pd in
                        removeContacts.contains(pd.jid)
                    }
                    completionHandler(filteredContact, nil)
                }else {
                    completionHandler(nil, data.getMessage() as? String)
                }
            } else{
                completionHandler(nil, data.getMessage() as? String)
            }
        }
    }

    func syncContacts(){
        ContactSyncManager.shared.syncContacts() { isSuccess, error, data in
            if isSuccess{
                print("#contact sync SUCCESS")
            }else {
                print("#contact sync Failed \(error?.localizedDescription)")
            }
        }
    }
}
