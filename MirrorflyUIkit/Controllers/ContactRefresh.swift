//
//  ContactRefresh.swift
//  MirrorflyUIkit
//
//  Created by User on 12/10/21.
//

import Foundation
import MirrorFlySDK

class ContactRefresh: NSObject, ConnectionEventDelegate {
    
    func onConnectionFailed(error: FlyError) {
        
    }
    
    func onReconnecting() {
        
    }
    
    
    public func setDelegate() {
        ChatManager.shared.connectionDelegate = self
        }
    
    func onConnected() {
        let contactViewModel = ContactViewModel()
        contactViewModel.getContacts(fromServer: true)
        { (profiles, error) in
            NotificationCenter.default.post(name: Notification.Name(Identifiers.ncContactRefresh), object: nil, userInfo:nil)
        }
    }
    
    func onDisconnected() {
        
    }
    
}
