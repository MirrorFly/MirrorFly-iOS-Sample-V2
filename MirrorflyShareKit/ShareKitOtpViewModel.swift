//
//  OTPViewModel.swift
//  MirrorflyUIkit
//
//  Created by User on 24/08/21.
//

import Foundation
import FirebaseAuth
class ShareOTPViewModel : NSObject
{
    func requestOtp(phoneNumber: String, completionHandler:  @escaping (String?, Error?)-> Void) {
        do {
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
                print("\(TAG) ShareOTPViewModel requestOtp \(error.debugDescription)")
                completionHandler(verificationID,error)
            }
        } catch(let error) {
            print("\(TAG) shareKit \(error)")
        }
        
    }
    
    
}
