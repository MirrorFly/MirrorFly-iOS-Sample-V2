//
//  OTPViewModel.swift
//  MirrorflyUIkit
//
//  Created by User on 24/08/21.
//

import Foundation
import FirebaseAuth
class OTPViewModel : NSObject
{
    func getCountryData(completionHandler: @escaping ([Country]?) -> Void) {
        var countryArray = [Country]()
        if let task = mainUrl  {
            URLSession.shared.dataTask(with: task) {
                (data,reponse,error) in
                guard let dats = data else { return}
                do{
                    countryArray = try JSONDecoder().decode([Country].self, from: dats)
                    completionHandler(countryArray)
                }
                catch{
                    completionHandler(countryArray)
                }
            }.resume()
        }
    }
    
    func requestOtp(phoneNumber: String, completionHandler:  @escaping (String?, Error?)-> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            completionHandler(verificationID,error)
        }
    }
    
    
}
