//
//  iCloudEventDelegate.swift
//  FlyCore
//
//  Created by Gowtham on 25/11/22.
//

import Foundation

public protocol iCloudEventDelegate {
    func fileUploadProgressDidReceive(completed: Double, completedSize: String, totalSize: String)
    func fileUploadDidFinish()
    func fileDownloadProgressDidReceive(completed: String)
    func fileUploadDownloadError(error: String)
    func lastiCloudBackupDetails(date: Date, size: String, isBackupAvailable: Bool)
}

public enum iCloudStatus {
    case available, noAccount, restricted, couldNotDetermine, temporarilyUnavailable, unknown
}
