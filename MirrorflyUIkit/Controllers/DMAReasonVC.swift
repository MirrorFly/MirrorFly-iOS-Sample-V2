//
//  DMAReasonVC.swift
//  MirrorflyUIkit
//
//  Created by User on 05/05/22.
//

import UIKit
import MirrorFlySDK

class DMAReasonVC: UIViewController {

    @IBOutlet weak var reasonField: UITextField!
    @IBOutlet weak var feedbackField: UITextField!
    @IBOutlet weak var dmaBtn: UIButton!
    var alertController : UIAlertController? = nil
    var selectedRow = 0
    
    let reasons = ["I am changing my device", "I am changing my phone number", "MirrorFly is missing a feature", "MirrorFly is not working", "Other"]
    
    let pickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
        feedbackField.delegate = self
        pickerView.delegate = self
        pickerView.dataSource = self
        reasonField.inputView = pickerView
        reasonField.tintColor = .clear
        reasonField.attributedPlaceholder = NSAttributedString(string: "Select a reason", attributes: [NSAttributedString.Key.foregroundColor : UIColor(named: "PrimaryTextColor2") ?? UIColor.lightGray])
        feedbackField.attributedPlaceholder = NSAttributedString(string: "Tell us how we can improve", attributes: [NSAttributedString.Key.foregroundColor : UIColor(named: "PrimaryTextColor2") ?? UIColor.lightGray])
        dmaBtn.isHidden = true
        dmaBtn.titleLabel?.font =  AppFont.Medium.size(15)
        reasonField.addDoneOnKeyboardWithTarget(self, action: #selector(doneButtonClicked))
    }
    

    @IBAction func backBtnTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func dmaBtnTapped(_ sender: Any) {
        let title = "Proceed to delete your account?"
        let message = "Deleting your account is permanent. Your data cannot be recovered if you reactivate your Mirrorfly account in future."
        alertController =  UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController?.setValue(NSAttributedString(string: title, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold),NSAttributedString.Key.foregroundColor : UIColor.black]), forKey: "attributedTitle")
        alertController?.setValue(NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular),NSAttributedString.Key.foregroundColor : UIColor.black]), forKey: "attributedMessage")
        let okAction = UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            let feedBack = self?.feedbackField.text ?? emptyString()
            let reason = self?.reasonField.text ?? emptyString()
            if NetStatus.shared.isConnected{
                if CallManager.isOngoingCall(){
                    CallManager.disconnectCall()
                }
                iCloudmanager().deleteiCloudBackupFile()
                ContactManager.shared.deleteMyAccountRequest(reason: reason, feedback: feedBack) { isSuccess, error, data in
                    let message = data["message"] as? String ?? ""
                    if isSuccess{
                        CommonDefaults.appLockPassword = ""
                        CommonDefaults.appLockenable = false
                        Utility.saveInPreference(key: firstTimeSandboxContactSyncDone, value: false)
                        CallLogManager().deleteCallLogs()
                        ChatManager.deleteAllRecentChats()
                        //CallLogs Badge Count
                        CallLogManager.resetUnreadMissedCallCount()
                        UIApplication.shared.applicationIconBadgeNumber = 0
                        AppAlert.shared.showToast(message: "Your Mirrorfly account has been deleted.")
                    }else{
                        AppAlert.shared.showToast(message: message)
                    }
                }
            }else{
                if let self = self{
                    AppAlert.shared.showAlert(view: self, title: "" , message: ErrorMessage.noInternet, buttonTitle: "OK")
                }
            }
        }
        alertController!.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
           
        }
        alertController?.preferredAction = okAction
        alertController!.addAction(cancelAction)
        present(alertController!, animated: true)
    }
}

extension DMAReasonVC : UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return reasons.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return reasons[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row
    }
    
}

extension DMAReasonVC : UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= 250

    }
    
    @objc func doneButtonClicked(_ sender: Any) {
        
            dmaBtn.isHidden = false
            reasonField.text = reasons[selectedRow]
            reasonField.resignFirstResponder()
        }
}
