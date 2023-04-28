//
//  RestoreViewController.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 21/11/22.
//

import UIKit
import MirrorFlySDK

class RestoreViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    @IBOutlet weak var autoBackupViewHeight: NSLayoutConstraint!
    @IBOutlet weak var autoBackupView: UIView!
    @IBOutlet weak var autoBackupSwitch: UISwitch!
    
    @IBOutlet weak var optionBaseView: UIView!
    
    @IBOutlet weak var instructionsView: UIView!
    @IBOutlet weak var instructionsHeight: NSLayoutConstraint!
    
    @IBOutlet weak var progressView: UIView!
    
    @IBOutlet weak var backupOptionLabel: UILabel!
    @IBOutlet weak var autoBackupTitleLabel: UILabel!
    @IBOutlet weak var optionView: UIView!
    
    @IBOutlet weak var optionHeight: NSLayoutConstraint!
    
    @IBOutlet weak var databaseImageView: UIImageView!
    @IBOutlet weak var phoneImageview: UIImageView!
    
    @IBOutlet weak var restoreProgress: UIProgressView!
    
    @IBOutlet weak var restoreImageView: UIImageView!
    
    @IBOutlet weak var restoreProgressLabel: UILabel!
    @IBOutlet weak var backupHeadLabel: UILabel!
    @IBOutlet weak var backupTimeLabel: UILabel!
    @IBOutlet weak var backupSizeLabel: UILabel!
    @IBOutlet weak var backupDescLabel: UILabel!
    
    @IBOutlet weak var animationImage1: UIImageView!
    @IBOutlet weak var animationImage2: UIImageView!
    @IBOutlet weak var animationImage3: UIImageView!
    @IBOutlet weak var animationImage4: UIImageView!
    var imageList: [UIImage?] = [UIImage(named: "page_image1"), UIImage(named: "page_image2"), UIImage(named: "page_image3"), UIImage(named: "page_image4")]
    var isSkip = false
    var backupUrl: URL?
    var iCloudManager = iCloudmanager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        autoBackupSwitch.transform = CGAffineTransform(scaleX: 0.60, y: 0.60)
        autoBackupSwitch.layer.borderColor = autoBackupSwitch.isOn ? Color.muteSwitchColor.cgColor : UIColor.darkGray.cgColor
        autoBackupSwitch.thumbTintColor = autoBackupSwitch.isOn ? Color.muteSwitchColor : UIColor.darkGray
        autoBackupSwitch.layer.borderWidth = 2
        autoBackupSwitch.layer.cornerRadius = autoBackupSwitch.bounds.height/2
        skipButton.layer.cornerRadius = skipButton.bounds.height/2
        autoBackupSwitch.decreaseThumb()
        databaseImageView.applyShadow()
        phoneImageview.applyShadow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stopLoading()
        setupiCloud()
        progressView.isHidden = true
        self.navigationController?.isNavigationBarHidden = true
        let isAutoBackup = Utility.getAutoBackupIsOn()
        autoBackupSwitch.setOn(isAutoBackup, animated: true)
        backupOptionLabel.text = Utility.getAutoBackupSchedule()
        self.optionBaseView.isHidden =  isAutoBackup ? false : true
        self.autoBackupTitleLabel.isHidden = isAutoBackup ? false : true
        self.optionHeight.constant = isAutoBackup ? 40 : 0
    }
    
    func setupiCloud() {
        BackupManager.shared.restoreDelegate = self
        iCloudManager.iCloudDelegate = self
        setupiCloudDetials(isAvailable: false)
        restoreButton.alpha = 0.4
        restoreButton.isUserInteractionEnabled = false
        if iCloudManager.checkiCloudAccess() {
            self.instructionsView.isHidden = true
            self.instructionsHeight.constant = 0
            iCloudManager.downloadBackupFile()
        } else {
            AppAlert.shared.showToast(message: iCloudNotAvailable)
        }
    }
    
    func setupiCloudDetials(isAvailable: Bool) {
        if isAvailable {
            executeOnMainThread {
                self.backupHeadLabel.text = backupFound
                self.backupDescLabel.text = backupFoundDescription
                self.instructionsView.isHidden = true
                self.backupSizeLabel.isHidden = false
                self.backupTimeLabel.isHidden = false
                self.instructionsHeight.constant = 0
            }
        } else {
            executeOnMainThread {
                self.backupSizeLabel.isHidden = true
                self.backupTimeLabel.isHidden = true
                self.backupHeadLabel.text = nobBackupFound
                self.backupDescLabel.text = noBackupFoundDescription
            }
        }
      
    }
    
    @IBAction func instructionAction(_ sender: UITapGestureRecognizer) {
    }
    
    @IBAction func restoreButtonAction(_ sender: UIButton) {
        executeOnMainThread {
            self.titleLabel.text = restoring
            self.autoBackupView.isHidden = true
            self.autoBackupViewHeight.constant = 0
            sender.isHidden = true
            self.progressView.isHidden = false
            self.skipButton.backgroundColor = Color.color_3276E2
            self.skipButton.setTitleColor(.white, for: .normal)
            self.makeAnimation()
        }
        if let getUrl = backupUrl {
            BackupManager.shared.restoreMessages(url: getUrl)
        }
    }
    
    @IBAction func skipButtonAction(_ sender: UIButton) {
        isSkip = true
        profileNavigation()
    }
    
    func profileNavigation() {
        if let profileVc = UIStoryboard.init(name: Storyboards.profile, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.profileViewController) as? ProfileViewController {
            profileVc.getMobileNumber = FlyDefaults.myMobileNumber
            self.navigationController?.pushViewController(profileVc, animated: true)
            navigationController?.viewControllers.removeAll(where: { viewControllers in
                !viewControllers.isKind(of: ProfileViewController.self)
            })
        }
    }
    
    @IBAction func autoBackupSwitchAction(_ sender: UISwitch) {
        Utility.setAutoBackupDetails(isOn: sender.isOn)
        animateView(isHide: sender.isOn)
        self.viewDidLayoutSubviews()
    }
    
    private func animateView(isHide: Bool) {
        
        UIView.animate(withDuration: 0.3, animations: {
            if isHide {
                self.optionHeight.constant = 40
            } else {
                self.optionBaseView.isHidden = true
                self.autoBackupTitleLabel.isHidden = true
                self.optionHeight.constant = 0
            }
            self.view.layoutIfNeeded()
        }) { status in
            if status, isHide {
                self.autoBackupTitleLabel.isHidden = false
                self.optionBaseView.isHidden = false
            }
        }
    }
    
    @IBAction func optionsPopup(_ sender: UITapGestureRecognizer) {
        let backupPopupVc = BackupPopupViewController(nibName: Identifiers.backupPopupViewController, bundle: nil)
        backupPopupVc.delegate = self
        backupPopupVc.seletedOption = backupOptionLabel.text ?? ""
        backupPopupVc.modalPresentationStyle = .overCurrentContext
        backupPopupVc.modalTransitionStyle = .crossDissolve
        self.present(backupPopupVc, animated: true)
    }
    
    func makeAnimation() {
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDuration), userInfo: nil, repeats: true)
    }
    
    @objc func updateDuration() {
        imageList.rearrange(from: 0, to: 3)
        animationImage1.image = imageList[0]
        animationImage2.image = imageList[1]
        animationImage3.image = imageList[2]
        animationImage4.image = imageList[3]
    }
    
}
extension Array {
    mutating func rearrange(from: Int, to: Int) {
        insert(remove(at: from), at: to)
    }
}

extension RestoreViewController: BackupOptionDelegate {
    
    func progressFailed(errorMessage: String) {
        
    }
    
    func progressFinished(url: String, isDownload: Bool) {
        
    }
    
    func optionDidselect(option: String, isBackupOption: Bool) {
        backupOptionLabel.text = option
    }
    
}
extension RestoreViewController: RestoreEventDelegate {

    func restoreDidFailed(errorMessage: String) {
        executeOnMainThread {
            self.titleLabel.text = "Restoring"
            self.autoBackupView.isHidden = true
            self.autoBackupViewHeight.constant = 0
            self.restoreButton.isHidden = false
            self.progressView.isHidden = true
            AppAlert.shared.showToast(message: errorMessage)
        }
    }
    
    func restoreProgressDidReceive(completedCount: Double, completedPercentage: String, completedSize: String) {
        restoreProgress.setProgress(Float(completedCount), animated: true)
        self.restoreProgressLabel.text = "Restoring messages (\(completedPercentage)%)"
    }
    
    func restoreDidFinish() {
        AppAlert.shared.showToast(message: restoreSuccess)
        if let url = backupUrl, FileManager.default.fileExists(atPath: url.path) {
           try? FileManager.default.removeItem(atPath: url.path)
        }
        iCloudManager.deleteLoaclBackup()
        if !isSkip {
            DispatchQueue.main.asyncAfter(deadline: .now() +  1) { [weak self] in
                self?.profileNavigation()
            }
        }
    }
    
}

extension RestoreViewController: iCloudEventDelegate {
    
    func fileUploadProgressDidReceive(completed: Double, completedSize: String, totalSize: String) {
        
    }
    
    func fileUploadDidFinish() {
        
    }
    
    func fileDownloadProgressDidReceive(completed: String) {
        self.backupHeadLabel.text = backupDownloading
        self.backupDescLabel.text = backupFoundDescription
        self.instructionsView.isHidden = true
        self.instructionsHeight.constant = 0
    }
    
    func fileUploadDownloadError(error: String) {
        
    }
    
    func lastiCloudBackupDetails(date: Date, size: String, isBackupAvailable: Bool) {
        executeOnMainThread {
            if isBackupAvailable {
                self.restoreButton.isUserInteractionEnabled = true
                self.restoreButton.alpha = 1
                self.setupiCloudDetials(isAvailable: true)
                self.backupTimeLabel.text = date.timeAgoDisplay()
                self.backupSizeLabel.text = "Size: \(size)"
                self.backupUrl = self.iCloudManager.getLocalBackupUrl()
            } else {
                self.restoreButton.isUserInteractionEnabled = false
                //AppAlert.shared.showToast(message: nobBackupFound)
            }
        }
    }
}
