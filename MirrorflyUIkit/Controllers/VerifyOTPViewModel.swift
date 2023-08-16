//  VerifyOTPViewModel.swift
//  MirrorFly
//  Created by User on 19/05/21.
import Foundation
import FirebaseAuth
import Alamofire
import MirrorFlySDK

class VerifyOTPViewModel : NSObject
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
    func registration(uniqueIdentifier: String, isForceRegister: Bool, userType: String? = nil, completionHandler:  @escaping ([String: Any]?, String?)-> Void) {
        let deviceToken = Utility.getStringFromPreference(key: googleToken)
        var voipToken = Utility.getStringFromPreference(key: voipToken)
        print(deviceToken, mobileNumber)
        voipToken = voipToken.isEmpty ? deviceToken : voipToken
        
        if ChatManager.getAppConfigDetails().baseURL.isEmpty {
            ChatManager.initializeSDK(licenseKey: LICENSE_KEY) { licenseSuccess, error, data in
                if licenseSuccess {
                    try! ChatManager.registerApiService(for: uniqueIdentifier, deviceToken: deviceToken, voipDeviceToken: voipToken, isExport: ISEXPORT, isForceRegister: isForceRegister, userType: userType) { isSuccess, flyError, flyData in
                        var data = flyData
                        if isSuccess {
                            if  data["newLogin"] as? Bool ?? false{
                                CallLogManager().deleteCallLogs()
                                ChatManager.deleteAllChatTags()
                                iCloudmanager().deleteLoaclBackup()
                                Utility.saveInPreference(key: "clLastPageNumber", value: "1")
                                Utility.saveInPreference(key: "clLastTotalPages", value: "0")
                                Utility.saveInPreference(key: "clLastTotalRecords", value: "0")

                            }
                            completionHandler(data, nil)
                        }else{
                            
                            let err = flyError?.description ?? ""
                            let error = err.contains("405") ? err : data.getMessage()
                            //let error = data.getMessage()
                            completionHandler(data, error as? String)
                        }
                    }
                }else{
                    completionHandler(data, error as? String)
                }
            }
        }else{
            try! ChatManager.registerApiService(for: uniqueIdentifier, deviceToken: deviceToken, voipDeviceToken: voipToken, isExport: ISEXPORT, isForceRegister: isForceRegister, userType: userType) { isSuccess, flyError, flyData in
                var data = flyData
                if isSuccess {
                    if  data["newLogin"] as? Bool ?? false{
                        CallLogManager().deleteCallLogs()
                        ChatManager.deleteAllChatTags()
                        iCloudmanager().deleteLoaclBackup()
                        Utility.saveInPreference(key: "clLastPageNumber", value: "1")
                        Utility.saveInPreference(key: "clLastTotalPages", value: "0")
                        Utility.saveInPreference(key: "clLastTotalRecords", value: "0")

                    }
                    completionHandler(data, nil)
                }else{
                    
                    let err = flyError?.description ?? ""
                    let error = err.contains("405") ? err : data.getMessage()
                    //let error = data.getMessage()
                    completionHandler(data, error as? String)
                }
            }
        }
    }
    
    func initializeChatCredentials() {
        ChatManager.updateAppLoggedIn(isLoggedin: true)
        RootViewController.sharedInstance.initCallSDK()
        VOIPManager.sharedInstance.updateDeviceToken()
    }
}
