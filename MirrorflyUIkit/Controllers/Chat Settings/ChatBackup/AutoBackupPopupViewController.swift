//
//  AutoBackupPopupViewController.swift
//  UiKitQa
//
//  Created by Gowtham on 20/12/22.
//

import UIKit

class AutoBackupPopupViewController: UIViewController {

    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var optionBaseView: UIView!
    @IBOutlet weak var wifiButton: UIButton!
    @IBOutlet weak var cellularButton: UIButton!
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
        let network = Utility.getAutoBackupNetwork()
        if network == "Wi-Fi" {
            wifiButton.titleLabel?.font = AppFont.Bold.size(14)
            cellularButton.titleLabel?.font = AppFont.Regular.size(14)
            wifiButton.titleLabel?.textColor = Color.backupOptionGreenColor
        } else {
            wifiButton.titleLabel?.font = AppFont.Regular.size(14)
            cellularButton.titleLabel?.font = AppFont.Bold.size(14)
            cellularButton.titleLabel?.textColor = Color.backupOptionGreenColor
        }
    }
    
    @IBAction func wifiAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }
    
    @IBAction func cellularAction(_ sender: UIButton) {
        setOption(text: sender.titleLabel?.text)
    }
    
    func setOption(text: String?) {
        if let selectedText = text {
            self.delegate.optionDidselect(option: selectedText, isBackupOption: false)
            Utility.setAutoBackupNetwork(over: selectedText)
        }
        self.dismiss(animated: true)
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        setOption(text: Utility.getAutoBackupNetwork())
    }
    
    private func addGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tap.delegate = self
        backgroundView.addGestureRecognizer(tap)
    }
    
    @objc func tapAction() {
        self.dismiss(animated: true)
    }
}
extension AutoBackupPopupViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.optionBaseView) == true {
            return false
        }
        return true
    }
}
