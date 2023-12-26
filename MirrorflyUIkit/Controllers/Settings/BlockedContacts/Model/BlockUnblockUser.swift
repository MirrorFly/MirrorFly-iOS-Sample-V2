//
//  BlockUnblockUser.swift
//  UiKitQa
//
//  Created by Amose Vasanth on 02/12/22.
//

import Foundation
import MirrorFlySDK

class BlockUnblockViewModel: NSObject {

    static func unblockUser(jid: String,  completionHandler : @escaping FlyCompletionHandler) {
        do {
            try ContactManager.shared.unblockUser(for: jid) { isSuccess, error, data in
                completionHandler(isSuccess,error,data)
            }
        } catch let error as NSError {
            print("block user error: \(error)")
        }
    }

}
