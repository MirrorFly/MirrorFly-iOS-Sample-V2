//
//  ContactUsController.swift
//  MirrorflyUIkit
//
//  Created by User on 22/04/22.
//

import UIKit
import MirrorFlySDK

class ContactUsController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var sendBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
        titleTextField.borderStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        descriptionTextView.delegate = self
        titleTextField.delegate = self
        sendBtn.titleLabel?.font =  AppFont.Bold.size(14)
    }
    

    @IBAction func onBackBtnTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= 100

    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= 512
    }
    

    @IBAction func sendBtnTapped(_ sender: Any) {
        let title = titleTextField.text ?? ""
        let description = descriptionTextView.text ?? ""
        if title.isEmpty || description.isEmpty{
            AppAlert.shared.showToast(message: "Enter valid title and description")
            return
        }
        ContactManager.shared.sendContactUsInfo(title: title, description: description) { isSuccess, error, data in
            if isSuccess{
                AppAlert.shared.showToast(message: "Thank you for contacting us!")
                self.navigationController?.popViewController(animated: true)
            }else{
                let message = data["message"] as? String ?? ""
                AppAlert.shared.showToast(message: message)
            }
        }
    }
}
