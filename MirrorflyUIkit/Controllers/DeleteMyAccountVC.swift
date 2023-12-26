//
//  DeleteMyAccountVC.swift
//  MirrorflyUIkit
//
//  Created by User on 04/05/22.
//

import UIKit
import MirrorFlySDK

class DeleteMyAccountVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var countryCodeStackVIew: UIStackView!
    @IBOutlet weak var mobileNumberField: UITextField!
    @IBOutlet weak var countryNameStackView: UIStackView!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var countryCodeLabel: UILabel!
    
    private var otpViewModel = OTPViewModel()
    
    var countryArray = [Country]()
    var accountNumberCount = 8
    var countryDialCode = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
        continueBtn.titleLabel?.font =  AppFont.Medium.size(15)
        mobileNumberField.delegate = self
        let countryNameGesture = UITapGestureRecognizer(target: self, action: #selector(navigateToCountryPicker(_:)))
        let countryCodeGesture = UITapGestureRecognizer(target: self, action: #selector(navigateToCountryPicker(_:)))
        countryNameStackView.addGestureRecognizer(countryNameGesture)
        countryCodeStackVIew.addGestureRecognizer(countryCodeGesture)
        otpViewModel.getCountryData(completionHandler: { (countryArray) in
            if let countries = countryArray, countries.count > 0 {
                self.countryArray  = countries
                DispatchQueue.main.async { [weak self] in
                    let countryCode = Locale.current.regionCode
                    if let country = self?.countryArray.first(where: {$0.code == countryCode}) {
                        self?.countryNameLabel.text = country.name
                        self?.countryDialCode = country.dial_code.replacingOccurrences(of: "+", with: "")
                    } else {
                        self?.countryNameLabel.text = self?.countryArray[0].name
                        self?.countryDialCode = self?.countryArray[0].dial_code.replacingOccurrences(of: "+", with: "") ?? "1"
                    }
                    self?.countryCodeLabel.text = self?.countryDialCode
                }
            }
        })
        mobileNumberField.keyboardType = .phonePad
        if let accountNumber = ContactManager.getMyProfile().mobileNumber.components(separatedBy: " ").last?.replacingOccurrences(of: "+", with: ""){
            accountNumberCount = accountNumber.count
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= accountNumberCount

    }
    
    @IBAction func backBtnTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func continueBtnTapped(_ sender: Any) {
        guard let mobileNumber = mobileNumberField.text else {
            return
        }
        if !mobileNumber.isEmpty{
            
            let accountCountryCode = ContactManager.getMyProfile().mobileNumber.replacingOccurrences(of: mobileNumber, with: "").replacingOccurrences(of: "+", with: "").replacingOccurrences(of: " ", with: "")
            let accountNumber = ContactManager.getMyProfile().mobileNumber.substring(from: accountCountryCode.count).replacingOccurrences(of: "+", with: "").replacingOccurrences(of: " ", with: "")
            
            if mobileNumber == accountNumber{
                if accountCountryCode == countryDialCode{
                    if NetStatus.shared.isConnected{
                        let storyboard : UIStoryboard = UIStoryboard(name: Storyboards.profile, bundle: nil)
                        let country = storyboard.instantiateViewController(withIdentifier: Identifiers.dmaReasonVC) as! DMAReasonVC
                        self.navigationController?.pushViewController(country, animated: true)
                    }else{
                        AppAlert.shared.showAlert(view: self, title: "" , message: ErrorMessage.noInternet, buttonTitle: "OK")
                    }
                }else{
                    AppAlert.shared.showAlert(view: self, title: "" , message: "The Country code you selected doesn't match your account.", buttonTitle: "OK")
                }
            }else{
                AppAlert.shared.showAlert(view: self, title: "" , message: ErrorMessage.numberDoesntMatch, buttonTitle: "OK")
            }
        }else{
            AppAlert.shared.showAlert(view: self, title: "" , message: ErrorMessage.enterMobileNumber, buttonTitle: "OK")
        }
    }
    
    @objc func navigateToCountryPicker(_ sender: UITapGestureRecognizer){
        self.closeKeyboard()
        let storyboard : UIStoryboard = UIStoryboard(name: Storyboards.main, bundle: nil)
        let country = storyboard.instantiateViewController(withIdentifier: Identifiers.countryPicker) as! CountryPickerViewController
        country.countryArray = countryArray
        country.delegate = self
        self.navigationController?.pushViewController(country, animated: true)
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
}

extension DeleteMyAccountVC: CountryPickerDelegate {
    func selectedCountry(country: Country) {
        countryNameLabel.text = country.name.capitalized
        countryDialCode = country.dial_code.replacingOccurrences(of: "+", with: "")
        countryCodeLabel.text = countryDialCode
    }
}
