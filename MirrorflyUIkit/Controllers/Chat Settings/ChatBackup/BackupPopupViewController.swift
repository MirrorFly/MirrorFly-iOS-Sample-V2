//
//  BackupPopupViewController.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 15/11/22.
//

import UIKit

class BackupPopupViewController: UIViewController {

    @IBOutlet weak var optionBaseView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var dailyButton: UIButton!
    @IBOutlet weak var weeklyButton: UIButton!
    @IBOutlet weak var monthlyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    public var delegate: BackupOptionDelegate!
    public var seletedOption = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        optionBaseView.layer.cornerRadius = 5
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addGestures()
    }
    
    func setupUI() {
        let schedule = Utility.getAutoBackupSchedule()
        if schedule == autoBackupOption.daily.rawValue {
            dailyButton.titleLabel?.font = AppFont.Bold.size(14)
            weeklyButton.titleLabel?.font = AppFont.Regular.size(14)
            monthlyButton.titleLabel?.font = AppFont.Regular.size(14)
            dailyButton.titleLabel?.textColor = Color.backupOptionGreenColor
        } else if schedule == autoBackupOption.weekly.rawValue {
            dailyButton.titleLabel?.font = AppFont.Regular.size(14)
            weeklyButton.titleLabel?.font = AppFont.Bold.size(14)
            monthlyButton.titleLabel?.font = AppFont.Regular.size(14)
            weeklyButton.titleLabel?.textColor = Color.backupOptionGreenColor
        } else {
            dailyButton.titleLabel?.font = AppFont.Regular.size(14)
            weeklyButton.titleLabel?.font = AppFont.Regular.size(14)
            monthlyButton.titleLabel?.font = AppFont.Bold.size(14)
            monthlyButton.titleLabel?.textColor = Color.backupOptionGreenColor
        }
        cancelButton.titleLabel?.font = AppFont.Regular.size(14)
    }
    
    @objc func tapAction() {
        self.dismiss(animated: true)
    }
    
    @IBAction func dailyAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }
    
    @IBAction func weeklyAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }
    
    @IBAction func monthlyAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        setOption(text: Utility.getAutoBackupSchedule())
    }
    
    func setOption(text: String?) {
        if let selectedText = text {
            self.delegate.optionDidselect(option: selectedText, isBackupOption: true)
            Utility.setAutoBackupSchedule(schedule: selectedText)
        }
        self.dismiss(animated: true)
    }
    
    private func addGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tap.delegate = self
        backgroundView.addGestureRecognizer(tap)
    }
}
extension BackupPopupViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.optionBaseView) == true {
            return false
        }
        return true
    }
}
