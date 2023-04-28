//
//  BackupViewController.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 11/11/22.
//
import Foundation
import UIKit
import MirrorFlySDK
import MobileCoreServices

public protocol BackupOptionDelegate {
    func optionDidselect(option: String, isBackupOption: Bool)
    func progressFailed(errorMessage: String)
    func progressFinished(url: String, isDownload: Bool)
}
class BackupViewController: UIViewController {
    @IBOutlet weak var backupButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var autoBackupSwitch: UISwitch!
    @IBOutlet weak var autoBackupOverSwitch: UISwitch!
    
    @IBOutlet weak var scheduleBaseView: UIView!
    @IBOutlet weak var autoBackupHeight: NSLayoutConstraint!
    
    @IBOutlet weak var baseHeight: NSLayoutConstraint!
    @IBOutlet weak var backupDateLabel: UILabel!
    @IBOutlet weak var backupSizeLabel: UILabel!
    
    @IBOutlet weak var optionsTitleLabel: UILabel!
    @IBOutlet weak var overOptionsLabel: UILabel!
    
    @IBOutlet weak var uploadProgressLabel: UILabel!
    
    @IBOutlet weak var restoreProgressView: UIProgressView!
    @IBOutlet weak var restoreProgressLabel: UILabel!
    @IBOutlet weak var localBackupBaseView: UIStackView!
    
    
    var iCloudManager = iCloudmanager()
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        initialSetup(isAutoBackup: Utility.getAutoBackupIsOn())
        setupiCloud()
        if FlyDefaults.isBackupInProgress {
            presentProgressController()
        } else if !FlyDefaults.isBackupCompleted {
            progressView.isHidden = false
            cancelButton.isHidden = false
            uploadProgressLabel.isHidden = false
            backupButton.isHidden = true
        }
    }
   
    func initialSetup(isAutoBackup: Bool) {
        progressView.isHidden = true
        restoreProgressView.isHidden = true
        restoreProgressLabel.isHidden = true
        cancelButton.isHidden = true
        uploadProgressLabel.isHidden = true
        backupButton.isHidden = false
        localBackupBaseView.isHidden = false
      //  networkOptionButton.setTitle(Utility.getAutoBackupNetwork(), for: .normal)
        self.optionsTitleLabel.text = Utility.getAutoBackupSchedule()
        if iCloudManager.checkiCloudAccess() {
            autoBackupSwitch.setOn(isAutoBackup, animated: true)
            if isAutoBackup {
                self.scheduleBaseView.isHidden = false
                self.autoBackupHeight.constant = 130
                self.baseHeight.constant = 200
            } else {
                self.scheduleBaseView.isHidden = true
                self.autoBackupHeight.constant = 0
                self.baseHeight.constant = 70
            }
           
        } else {
            autoBackupSwitch.setOn(false, animated: true)
            self.scheduleBaseView.isHidden = true
            self.autoBackupHeight.constant = 0
            self.baseHeight.constant = 70
        }

        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupSwitchUI(uiSwitch: autoBackupSwitch)
       // setupSwitchUI(uiSwitch: autoBackupOverSwitch)
        backupButton.titleLabel?.font = AppFont.Medium.size(14)
        backupButton.alpha = FlyDefaults.isBackupInProgress ? 0.5 : 1
        backupButton.isUserInteractionEnabled = FlyDefaults.isBackupInProgress ? false : true
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        BackupManager.shared.restoreDelegate = self

    }
    
    func setupSwitchUI(uiSwitch: UISwitch) {
        uiSwitch.transform = CGAffineTransform(scaleX: 0.60, y: 0.60)
        uiSwitch.layer.borderColor = uiSwitch.isOn ? Color.muteSwitchColor.cgColor : UIColor.darkGray.cgColor
        uiSwitch.thumbTintColor = uiSwitch.isOn ? Color.muteSwitchColor : UIColor.darkGray
        uiSwitch.layer.borderWidth = 2
        uiSwitch.layer.cornerRadius = uiSwitch.bounds.height/2
        uiSwitch.decreaseThumb()
    }
    
    func setupiCloud() {
        iCloudManager.iCloudDelegate = self
        if iCloudManager.checkiCloudAccess() {
            iCloudManager.downloadBackupFile()
        } else {
            AppAlert.shared.showToast(message: iCloudNotAvailable)
        }
    }
    
    @IBAction func backupButtonAction(_ sender: UIButton) {
        if iCloudManager.checkiCloudAccess() {
            if BackupManager.shared.checkIfMessageAvailable() {
                self.progressView.setProgress(0, animated: false)
                progressView.isHidden = false
                cancelButton.isHidden = false
                uploadProgressLabel.isHidden = false
                backupButton.isHidden = true
                presentProgressController()
            } else {
                AppAlert.shared.showToast(message: noBackupMessage)
            }
        } else {
            instructionPopup()
        }
    }
    
    func presentProgressController() {
        let backupPopupVc = BackupProgressViewController(nibName: Identifiers.backupProgressViewController, bundle: nil)
        backupPopupVc.delegate = self
        backupPopupVc.isDownload = false
        backupPopupVc.modalPresentationStyle = .overCurrentContext
        backupPopupVc.modalTransitionStyle = .crossDissolve
        self.present(backupPopupVc, animated: true)
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backupOptionsPopup(_ sender: UITapGestureRecognizer) {
        executeOnMainThread {
            let backupPopupVc = BackupPopupViewController(nibName: Identifiers.backupPopupViewController, bundle: nil)
            backupPopupVc.delegate = self
            backupPopupVc.seletedOption = self.optionsTitleLabel.text ?? Utility.getAutoBackupSchedule()
            backupPopupVc.modalPresentationStyle = .overCurrentContext
            backupPopupVc.modalTransitionStyle = .crossDissolve
            self.present(backupPopupVc, animated: true)
        }
    }
    
    @IBAction func cancelBuckupAction(_ sender: UIButton) {
        self.progressView.setProgress(0, animated: true)
        self.progressView.isHidden = true
        self.cancelButton.isHidden = true
        self.uploadProgressLabel.isHidden = true
        self.backupButton.isHidden = false
        self.iCloudManager.deleteLoaclBackup()
    }
    
    @IBAction func autoBackupSwitchAction(_ sender: UISwitch) {
        if iCloudManager.checkiCloudAccess() {
            Utility.setAutoBackupDetails(isOn: sender.isOn)
            animateView(isHide: sender.isOn)
            self.viewDidLayoutSubviews()
        } else {
            sender.setOn(false, animated: true)
            instructionPopup()
        }
    }
    
    @IBAction func autoBackupOverSwitchAction(_ sender: UISwitch) {
        Utility.setAutoBackupOver(isOn: sender.isOn)
        self.viewDidLayoutSubviews()
    }
    
    private func animateView(isHide: Bool) {
        
        UIView.animate(withDuration: 0.3, animations: {
            if isHide {
                self.autoBackupHeight.constant = 130
                self.baseHeight.constant = 200
            } else {
                self.scheduleBaseView.isHidden = true
                self.autoBackupHeight.constant = 0
                self.baseHeight.constant = 70
            }
            self.view.layoutIfNeeded()
        }) { status in
            if status, isHide {
                self.scheduleBaseView.isHidden =  false
            }
        }
    }
    
    @IBAction func downloadAction(_ sender: UIButton) {
        if BackupManager.shared.checkIfMessageAvailable() {
            let backupPopupVc = BackupProgressViewController(nibName: Identifiers.backupProgressViewController, bundle: nil)
            backupPopupVc.delegate = self
            backupPopupVc.isDownload = true
            backupPopupVc.modalPresentationStyle = .overCurrentContext
            backupPopupVc.modalTransitionStyle = .crossDissolve
            self.present(backupPopupVc, animated: true)
        } else {
            AppAlert.shared.showToast(message: noBackupMessage)
        }
    }
    
    @IBAction func restoreAction(_ sender: UIButton) {
        openDocument()
    }
    
    func openDocument() {
        executeOnMainThread { [self] in
            let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeText as String], in: .import)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            self.present(documentPicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func networkOptionPopup(_ sender: UITapGestureRecognizer) {
        executeOnMainThread {
            let backupPopupVc = AutoBackupPopupViewController(nibName: Identifiers.autoBackupPopupViewController, bundle: nil)
            backupPopupVc.delegate = self
            backupPopupVc.seletedOption = self.overOptionsLabel.text ?? ""
            backupPopupVc.modalPresentationStyle = .overCurrentContext
            backupPopupVc.modalTransitionStyle = .crossDissolve
            self.present(backupPopupVc, animated: true)
        }
    }
    
    
    func instructionPopup() {
        AppAlert.shared.showToast(message: iCloudNotAvailable)
        if let instructionVc = UIStoryboard.init(name: Storyboards.backupRestore, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.restoreInstructionViewController) as? RestoreInstructionViewController {
            self.present(instructionVc, animated: true)
        }
    }
}
extension BackupViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        BackupManager.shared.restoreMessages(url: url)
        executeOnMainThread {
            self.restoreProgressView.isHidden = false
            self.restoreProgressLabel.isHidden = false
            self.localBackupBaseView.isHidden = true
        }
    }
}
extension BackupViewController: BackupOptionDelegate {
    
    func optionDidselect(option: String, isBackupOption: Bool) {
        if isBackupOption {
            optionsTitleLabel.text = option
        } else {
            overOptionsLabel.text = option
        }
        self.viewDidLayoutSubviews()
    }
    
    func progressFailed(errorMessage: String) {
        executeOnMainThread {
            self.progressView.isHidden = true
            self.cancelButton.isHidden = true
            self.uploadProgressLabel.isHidden = true
            self.backupButton.isHidden = false
            AppAlert.shared.showToast(message: errorMessage)
        }
    }
    
    func progressFinished(url: String, isDownload: Bool) {
        executeOnMainThread {
            if isDownload {
                AppAlert.shared.showToast(message: backupSuccess)
            } else {
                self.iCloudManager.uploadBackupFile(fileUrl: url)
            }
        }
    }
    
}

extension BackupViewController: RestoreEventDelegate {
    
    func restoreProgressDidReceive(completedCount: Double, completedPercentage: String, completedSize: String) {
        executeOnMainThread {
            self.restoreProgressView.setProgress(Float(completedCount), animated: true)
            self.restoreProgressLabel.text = "Restoring messages (\(completedPercentage)%)"
        }
    }
    
    func restoreDidFinish() {
        executeOnMainThread {
            self.restoreProgressView.isHidden = true
            self.restoreProgressLabel.isHidden = true
            self.localBackupBaseView.isHidden = false
            AppAlert.shared.showToast(message: restoreSuccess)
        }
    }
    
    func restoreDidFailed(errorMessage: String) {
        executeOnMainThread {
            self.restoreProgressView.isHidden = true
            self.restoreProgressLabel.isHidden = true
            self.localBackupBaseView.isHidden = false
            AppAlert.shared.showToast(message: errorMessage)
        }
    }
    
    
}

extension BackupViewController: iCloudEventDelegate {

    func fileUploadProgressDidReceive(completed: Double, completedSize: String, totalSize: String) {
        executeOnMainThread {
            self.uploadProgressLabel.text = "Uploading: \(completedSize) of \(totalSize) (\(completed.roundTo0f())%)"
            self.progressView.setProgress(Float(completed/100), animated: true)
        }
    }
    
    func fileUploadDidFinish() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            executeOnMainThread {
                //            AppAlert.shared.showToast(message: backupUploadSuccess)
                self.progressView.setProgress(0, animated: false)
                self.progressView.isHidden = true
                self.cancelButton.isHidden = true
                self.uploadProgressLabel.isHidden = true
                self.backupButton.isHidden = false
                self.iCloudManager.deleteLoaclBackup()
            }
        }
    }
    
    func fileDownloadProgressDidReceive(completed: String) {
        
    }
    
    func fileUploadDownloadError(error: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            executeOnMainThread {
                self.progressView.isHidden = true
                self.cancelButton.isHidden = true
                self.uploadProgressLabel.isHidden = true
                self.backupButton.isHidden = false
                if error != FlyConstants.ErrorMessage.storageError {
                    AppAlert.shared.showToast(message: error)
                } else {
                    AppAlert.shared.showAlert(view: self, title: "", message: iCloudStorageError, buttonTitle: "ok")
                }
                self.progressView.setProgress(0, animated: false)
            }
        }
    }
    
    func lastiCloudBackupDetails(date: Date, size: String, isBackupAvailable: Bool) {
        if isBackupAvailable {
            DispatchQueue.main.async {
                self.setBackupDate(date: date)
                self.backupSizeLabel.text = size
            }
        }
    }
    
    func setBackupDate(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.locale = .current
        dateFormatter.timeStyle = .short
        let getTime = dateFormatter.string(from: date)
        let getDate = self.convertToString(dateString: date.description.localizedLowercase, formatIn: "yyyy-MM-dd HH:mm:ss Z", formatOut: "dd MMM yyyy")
        self.backupDateLabel.text = "\(getDate) | \(getTime)"
    }
    
    func convertToString(dateString: String, formatIn : String, formatOut : String) -> String {

        let dateFormater = DateFormatter()
        dateFormater.timeZone = NSTimeZone(abbreviation: "UTC") as TimeZone?
        dateFormater.dateFormat = formatIn
        let date = dateFormater.date(from: dateString)

        dateFormater.timeZone = NSTimeZone.system

        dateFormater.dateFormat = formatOut
        let timeStr = dateFormater.string(from: date!)
        return timeStr
     }
}
extension UISwitch {
    
    func decreaseThumb() {
        if let thumb = self.subviews[0].subviews[1].subviews[2] as? UIImageView {
            thumb.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }
    }
}
extension DispatchQueue {
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
    
}
