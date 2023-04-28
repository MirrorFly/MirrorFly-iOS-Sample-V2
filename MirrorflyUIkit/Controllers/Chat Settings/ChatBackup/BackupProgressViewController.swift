//
//  BackupProgressViewController.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 21/11/22.
//

import UIKit
import MirrorFlySDK

class BackupProgressViewController: UIViewController {

    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    var delegate: BackupOptionDelegate?
    var isDownload = false
    var iCloudManager = iCloudmanager()

    override func viewDidLoad() {
        super.viewDidLoad()
        startbackup()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification
                    , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification
                    , object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicatorView.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        BackupManager.shared.backupDelegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        BackupManager.shared.backupDelegate = nil
    }

    @objc func willEnterForeground() {
        BackupManager.shared.backupDelegate = self
    }
    
    @objc func didEnterBackground() {
        BackupManager.shared.backupDelegate = nil
    }
    
    func startbackup() {
        BackupManager.shared.startBackup()
    }

}
extension BackupProgressViewController: BackupEventDelegate {
    
    func backupProgressDidReceive(completedCount: String, completedSize: String) {
        progressLabel.text = "Please wait a moment (\(completedCount)%)"
    }
    
    func backupDidFinish(fileUrl: String) {
        print(fileUrl)
        self.delegate?.progressFinished(url: fileUrl, isDownload: isDownload)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.dismiss(animated: true)
        }
    }
    func backupDidFailed(errorMessage: String) {
        self.delegate?.progressFailed(errorMessage: errorMessage)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.dismiss(animated: true)
        }
    }
    
    
}
