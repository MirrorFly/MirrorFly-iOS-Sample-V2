//
//  iCloudmanager.swift
//  FlyCore
//
//  Created by Gowtham on 22/11/22.
//

import Foundation
import MirrorFlySDK
import CloudKit
import Alamofire

enum autoBackupOption : String {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

public class iCloudmanager {
    
    public var query: NSMetadataQuery!
    public var iCloudDelegate: iCloudEventDelegate?
    private var backgroundQueue : DispatchQueue!
    private var cancelUpload = false
    private var fileSize: Int64?
    let networkManager = NetworkReachabilityManager.default
    var isUpload = false
    var isFileEncryptionEnabled = false
    private static let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.mirrorfly.qa"
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInitiated
        return operationQueue
    }()
    
    public init() {
        backgroundQueue = DispatchQueue.init(label: "iCloudBackgroundQueue")
        initialiseQuery(filename: generateBackupFileName())
        addNotificationObservers()
       // BackupManager.shared.backupDelegate = self
    }
    
    func initialiseQuery(filename: String) {
        query = NSMetadataQuery.init()
        query.operationQueue = iCloudmanager.operationQueue
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, filename)
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.start()
    }
    
    // add notifiaction to observe download and upload progress
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidStartGathering, object: query, queue: query.operationQueue) { (notification) in
            executeOnMainThread {
                print(notification.debugDescription)
                self.processCloudFiles()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query, queue: query.operationQueue) { (notification) in
            executeOnMainThread {
                print(notification.debugDescription)
                self.processCloudFiles()
            }
        }
        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: nil, using: { notification in
            executeOnMainThread {
                print(notification.debugDescription)
                self.processCloudFiles()
            }
        })
        
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidStartGathering, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: nil)
    }

    // Upload backup file from local document directory to iCloud
    public func uploadBackupFile(fileUrl: String) {
        if fileUrl.isEmpty { return }
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            iCloudDelegate?.fileUploadDownloadError(error: ErrorMessage.noInternet)
            return
        }
        if !cancelUpload {
            isUpload = true
            backgroundQueue.async { [weak self] in
                print("#backupDidFinish progressFinished uploadBackupFile \(fileUrl)")
                if let backupUrl = URL(string: fileUrl) {
                    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: ICLOUD_CONTAINER_ID) else {
                        self?.iCloudDelegate?.fileUploadDownloadError(error: containerError)
                        return
                    }
                    do {
                        self?.getFileSize(fileURL: backupUrl)
                        var backupCloudFileURL = containerURL.appendingPathComponent("Documents")
                        
                        if !FileManager.default.fileExists(atPath: containerURL.path) {
                            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
                        }
                        print("#BackupIcloud #uploadBackupFile backupUrl \(backupUrl)")
                        
                        backupCloudFileURL = backupCloudFileURL.appendingPathComponent(self?.generateBackupFileName() ?? "")
                        print("#BackupIcloud #uploadBackupFile backupCloudFileURL \(backupCloudFileURL)")
                        CommonDefaults.isBackupCompleted = false
                        self?.uploadFileToiCloud(dataFile: backupUrl, fileToUpload: backupCloudFileURL)
                        self?.query.operationQueue?.addOperation({
                            _ = self?.query.start()
                            self?.query.enableUpdates()
                        })
                    } catch let error {
                        print("#BackupIcloud Failed to move file dir : \(error)")
                    }
                }
            }
        } else {
            cancelUpload = false
        }
    }
    
    func uploadFileToiCloud(dataFile: URL, fileToUpload: URL) {
        guard let iCloudURL = getiCloudUrl() else {
            print("#BackupIcloud #uploadFileToiCloud iCloud is not available")
            return
        }

        let fileManager = FileManager.default

        // Check if the file exists in iCloud, and remove it if it does
        if fileManager.fileExists(atPath: iCloudURL.path) {
            do {
                try fileManager.removeItem(at: iCloudURL)
                print("#BackupIcloud #uploadFileToiCloud Existing file removed successfully")
            } catch {
                print("#BackupIcloud #uploadFileToiCloud Failed to remove existing file: \(error.localizedDescription)")
                return
            }
        }

        // Copy the new file to iCloud
        do {
            try fileManager.copyItem(at: dataFile, to: iCloudURL)
            print("#BackupIcloud #uploadFileToiCloud File uploaded successfully")
        } catch {
            print("#BackupIcloud #uploadFileToiCloud Upload failed: \(error.localizedDescription)")
        }
    }
    
    public func deleteiCloudBackupFile() {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: ICLOUD_CONTAINER_ID) else {
            return
        }
        let backupCloudFileURL = containerURL.appendingPathComponent("Documents").appendingPathComponent(generateBackupFileName())
        if FileManager.default.fileExists(atPath: backupCloudFileURL.path) {
            do {
                try FileManager.default.removeItem(at: backupCloudFileURL)
            } catch {
                
            }
        } else {
            
        }
    }
    
    // Download backup file from iCloud to local document directory

    public func downloadBackupFile() {
        if NetworkReachability.shared.isConnected {
            backgroundQueue.async { [weak self] in
                guard let backupCloudFileURL = FileManager.default.url(forUbiquityContainerIdentifier: ICLOUD_CONTAINER_ID) else { return }
                var containerURL = backupCloudFileURL.appendingPathComponent("Documents")
                containerURL = containerURL.appendingPathComponent(self?.generateBackupFileName() ?? "")
                do {
                    self?.query.operationQueue?.addOperation({
                        self?.query.start()
                        self?.query.enableUpdates()
                    })
                    if FileManager.default.fileExists(atPath: containerURL.path) {
                        self?.movetoLocalFile(iCloudUrl: containerURL)
                        self?.checkLastBackupDetails()
                    } else {
                        try FileManager.default.startDownloadingUbiquitousItem(at: containerURL)
                        self?.checkLastBackupDetails()
                    }
                } catch let error as NSError {
                    print("#BackupIcloud Failed to download iCloud file : \(error)")
                }
            }
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    public func movetoLocalFile(iCloudUrl: URL) {
        do {
            if let backupUrl = getLocalBackupUrl() {
                print("#BackupIcloud #movetoLocalFile backupUrl \(backupUrl)")
                print("#BackupIcloud #movetoLocalFile iCloudUrl \(iCloudUrl)")

                let fileManager = FileManager.default

                // Check if the destination (backupUrl) exists
                if fileManager.fileExists(atPath: backupUrl.path) {
                    print("#BackupIcloud #movetoLocalFile fileExists, removing existing file")
                    do {
                        try fileManager.removeItem(at: backupUrl)
                    } catch {
                        print("#BackupIcloud ❌ Failed to remove existing file: \(error.localizedDescription)")
                    }
                } else {
                    // Ensure that the parent directory exists before copying
                    let backupDirectory = backupUrl.deletingLastPathComponent()
                    if !fileManager.fileExists(atPath: backupDirectory.path) {
                        do {
                            try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true, attributes: nil)
                            print("#BackupIcloud #movetoLocalFile Created backup directory")
                        } catch {
                            print("#BackupIcloud ❌ Failed to create directory: \(error.localizedDescription)")
                        }
                    }
                }

                // Now, copy the iCloud file to the local backup
                do {
                    print("#BackupIcloud #movetoLocalFile Copying file...")
                    try fileManager.copyItem(at: iCloudUrl, to: backupUrl)
                    print("#BackupIcloud ✅ File copied successfully to \(backupUrl.path)")
                } catch {
                    print("#BackupIcloud ❌ movetoLocalFileError: \(error.localizedDescription)")
                }
            }

        } catch let error {
            print("#BackupIcloud movetoLocalFileError", error)
        }
    }
    
    public func getLocalBackupUrl() -> URL? {
        var documentDirectoryUrl = FlyUtils.getGroupContainerIDPath()
        documentDirectoryUrl = documentDirectoryUrl?.appendingPathComponent("iCloudBackup")
        return documentDirectoryUrl?.appendingPathComponent(generateBackupFileName())
    }
    
    public func deleteLoaclBackup() {
        do {
            if let url = getLocalBackupUrl(), FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(atPath: url.path)
            }
        } catch {
            
        }
    }
    
    public func getiCloudUrl() -> URL? {
        var backupCloudFileURL = FileManager.default.url(forUbiquityContainerIdentifier: ICLOUD_CONTAINER_ID)
        backupCloudFileURL = backupCloudFileURL?.appendingPathComponent("Documents").appendingPathComponent(generateBackupFileName())
        return backupCloudFileURL
    }
    
    public func getFileSize(fileURL: URL) {
        do {
            let fileattr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let getFileSize = fileattr[FileAttributeKey.size] as! Int64
            fileSize = getFileSize
        } catch {
            
        }
    }
    
    public func checkiCloudAccess() -> Bool {
       return FileManager.default.ubiquityIdentityToken != nil
    }
    
    // To check last uploaded backup file details
    public func checkLastBackupDetails() {
        if let backupCloudFileURL = getiCloudUrl() {
            if FileManager.default.fileExists(atPath: backupCloudFileURL.path) {
                do {
                    try FileManager.default.startDownloadingUbiquitousItem(at: backupCloudFileURL)
                    let resources = try backupCloudFileURL.resourceValues(forKeys:[.fileSizeKey])
                    let fileDate = try backupCloudFileURL.resourceValues(forKeys:[.contentModificationDateKey])
                    if let fileSize = resources.fileSize {
                        executeOnMainThread {
                            self.iCloudDelegate?.lastiCloudBackupDetails(date: fileDate.contentModificationDate ?? Date(), size: self.fileSizeCalculation(bytes: Int64(fileSize)), isBackupAvailable: true)
                        }
                    }
                } catch let error {
                    print("BackupDetailsError===>", error)
                }
            } else {
                self.iCloudDelegate?.lastiCloudBackupDetails(date: Date(), size: emptyString(), isBackupAvailable: false)
            }
        }
    }
    
    public func checkAutoBackupSchedule() {
        if Utility.getAutoBackupIsOn() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            if let backupDate = dateFormatter.date(from: Utility.getAutoBackupDate()) {
                let timeAgo = Int(Date().timeIntervalSince(backupDate))
                let minute = 60, hour = 60 * minute, day = 24 * hour, week = 7 * day, month = 4 * week
                let getSchedule = Utility.getAutoBackupSchedule()
                if getSchedule == autoBackupOption.daily.rawValue, timeAgo < week, timeAgo > day { 
                    startSchedulebackup()
                } else if getSchedule == autoBackupOption.weekly.rawValue, timeAgo < month {
                    startSchedulebackup()
                } else if getSchedule == autoBackupOption.monthly.rawValue, timeAgo > month {
                    startSchedulebackup()
                }
            }
        }
    }
    
    func startSchedulebackup() {
        let network = Utility.getAutoBackupNetwork()
        if let isWiFi = networkManager?.isReachableOnEthernetOrWiFi {
            if network == "Wi-Fi", isWiFi {
                BackupManager.shared.startBackup(enableEncryption: true)
            } else {
                BackupManager.shared.startBackup(enableEncryption: true)
            }
            Utility.setAutoBackupDate()
        }
    }
    
    public func cancelBackup() {
        cancelUpload = true
        self.iCloudDelegate?.fileUploadDownloadError(error: "Backup cancelled")
    }
    
    func calculateProgressSize(percent: Double) -> String {
        let roundof = percent.roundTo0f()
        let value = (Int(roundof) ?? 0) * Int(fileSize ?? 0)
        let bytes = value / 100
        return fileSizeCalculation(bytes: Int64(bytes))
    }
    
    func processCloudFiles() {
        if query.results.count == 0 { return }
        var fileItem: NSMetadataItem?
        var fileURL: URL?
        
        for item in query.results {
            guard let item = item as? NSMetadataItem else { continue }
            guard let fileItemURL = item.value(forAttribute: NSMetadataItemURLKey) as? URL else { continue }
            if fileItemURL.lastPathComponent.contains(generateBackupFileName()) {
                fileItem = item
                fileURL = fileItemURL
            }
        }
        
        let fileValues = try? fileURL?.resourceValues(forKeys: [URLResourceKey.ubiquitousItemIsUploadingKey, URLResourceKey.ubiquitousItemIsDownloadingKey, URLResourceKey.ubiquitousItemUploadingErrorKey])
        if let fileUploadProgress = fileItem?.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey) as? Double {
            self.getFileSize(fileURL: fileURL!)
            CommonDefaults.isBackupCompleted = false
            iCloudDelegate?.fileUploadProgressDidReceive(completed: fileUploadProgress, completedSize: calculateProgressSize(percent: fileUploadProgress), totalSize: fileSizeCalculation(bytes: fileSize))
        }
        if let fileDownloadProgress = fileItem?.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Double {
            iCloudDelegate?.fileDownloadProgressDidReceive(completed: "\(fileDownloadProgress)")
        }
        if let failed = fileItem?.value(forAttribute: NSMetadataUbiquitousItemUploadingErrorKey) as? String {
            print("failed===>", failed)
            iCloudDelegate?.fileUploadDownloadError(error: FlyConstants.ErrorMessage.storageError)
        }
        
        if let fileUploaded = fileItem?.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? Bool, fileUploaded == true, fileValues?.ubiquitousItemIsUploading == false {
            CommonDefaults.isBackupCompleted = true
                iCloudDelegate?.fileUploadDidFinish()
                checkLastBackupDetails()
        }
        if let error = fileValues?.ubiquitousItemUploadingError {
            if error.code == NSUbiquitousFileNotUploadedDueToQuotaError {
                iCloudDelegate?.fileUploadDownloadError(error: FlyConstants.ErrorMessage.storageError)
            } else {
                iCloudDelegate?.fileUploadDownloadError(error: error.localizedDescription)
            }
        }
        
        if let fileDownloaded = fileItem?.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) {
            if let isDownloading = fileDownloaded as? Bool, isDownloading == false {
                movetoLocalFile(iCloudUrl: (fileURL)!)
                checkLastBackupDetails()
            }
        } else if let error = fileValues?.ubiquitousItemDownloadingError {
            iCloudDelegate?.fileUploadDownloadError(error: error.localizedDescription)
        }
    }
    
    func fileSizeCalculation(bytes: Int64?) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes ?? 0, countStyle: .file)
    }
}

extension iCloudmanager: BackupEventDelegate {
    public func backupProgressDidReceive(completedCount: String, completedSize: String) {
        
    }
    
    public func backupDidFinish(fileUrl: String) {
        uploadBackupFile(fileUrl: fileUrl)
    }
    
    public func backupDidFailed(errorMessage: String) {
        
    }
}

extension iCloudmanager {
    private func generateBackupFileName() -> String {
        let fileExtension = isFileEncryptionEnabled ? "crypto7" : "txt"
        return "Backup_\(ChatManager.getXMPPDetails().XMPPUsername).\(fileExtension)"
    }
}
