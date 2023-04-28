//
//  NotificationNameExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 16/08/21.
//

import Foundation

//NotificationCenter.default.post(name: .statusUpdated, object: nil)
extension Notification.Name {
    static let statusUpdated = Notification.Name("status_updated")
}
