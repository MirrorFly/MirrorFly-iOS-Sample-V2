//  VerifyOTPViewModel.swift
//  MirrorFly
//  Created by User on 19/05/21.
import Foundation
import FirebaseAuth
import Alamofire
import MirrorFlySDK

class ShareVerifyOTPViewModel : NSObject
{
    private var apiService : ApiService!
    
    override init() {
        super.init()
        apiService =  ApiService()
    }
    
    func verifyOtp(verificationId: String, verificationCode: String, completionHandler:  @escaping (AuthDataResult?, Error?)-> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: verificationCode)
        Auth.auth().signIn(with: credential) { (authResult, error) in
            completionHandler(authResult, error)
        }
    }
    
    func validateUser(params: NSDictionary, completionHandler:  @escaping (VerifyToken?, Error?)-> Void)  {
        let Baseurl = ChatManager.getAppConfigDetails().baseURL
        let url = Baseurl + verifyUser
        print("verifyOTPViewModel.validateUser \(url)")
        apiService.post(withEndPoint: url, params: params as? Parameters, headers: nil).responseJSON { (response) in
            switch response.result {
            case .success:
                let jsonData = response.data
                print("verifyOTPViewModel.validateUser \(response) \(jsonData)")
                do{
                    let userData = try JSONDecoder().decode(VerifyToken.self, from: jsonData!)
                    completionHandler(userData,nil)
                }catch {
                    completionHandler(nil,error)
                }
                break
            case .failure( let error):
                completionHandler(nil,error)
                break
            }
        }
        
    }
    
}
