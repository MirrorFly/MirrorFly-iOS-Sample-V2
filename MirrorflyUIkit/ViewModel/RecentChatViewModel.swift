//
//  RecentChatViewModel.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 09/11/21.
//

import Foundation
import FlyCore
import FlyCommon

class RecentChatViewModel  {
  
    func getRecentChatList(isBackground: Bool, completionHandler:  @escaping ([RecentChat]?)-> Void) {
        if isBackground {
            ChatManager.getRecentChatList { (isSuccess, flyError, resultDict) in
                var flydata = resultDict
                print(flydata.getData())
            }
        } else {
            completionHandler(ChatManager.getRecentChatList())
        }
    }
}
