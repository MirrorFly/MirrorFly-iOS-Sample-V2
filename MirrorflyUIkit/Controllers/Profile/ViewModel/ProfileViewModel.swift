//
//  ProfileViewModel.swift
//  MirrorflyUIkit
//
//  Created by User on 17/08/21.
//

import Foundation
import MirrorFlySDK
import Alamofire

class ProfileViewModel {
    var profileModel: ProfileModel!
    
    var emailId: String {
        return profileModel.emailId
    }
    var mobileNumber: String {
        return profileModel.mobileNumber
    }
    var userStatus: String {
        return profileModel.userStatus
    }
    
    typealias ProfileCallBack = (_ status: Bool, _ message: String) -> Void
    var profileCallback:ProfileCallBack?
    
    func updateProfileWith(userName: String, emailId: String, mobileNumber: String) {
        let trimmedUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUserName.isBlank {
            self.profileCallback?(false, emptyUserName.localized)
        }
        else if trimmedUserName.count >  userNameMaxLength{
            self.profileCallback?(false, userNameValidation.localized)
        }
        else if trimmedUserName.count <  userNameMinLength{
            self.profileCallback?(false, userNameMinValidation.localized)
        }
        else if emailId.isBlank {
            self.profileCallback?(false, emptyEmail.localized)
        }
        else if !emailId.isValidEmail(email: emailId) {
            self.profileCallback?(false, emailValidation.localized)
        }
        else {
            self.profileCallback?(true, "")
        }
    }
    
    //MARK:- loginCompletionHandler
    func profileCompletionHandler(callBack: @escaping ProfileCallBack) {
        self.profileCallback = callBack
    }
    
    //MARK:- Contact sync
    func contactSync() {
        return
        let  apiService =  ApiService()
        let params = ["licenseKey": ChatManager.getAppConfigDetails().licenseKey]
        let url = ChatManager.getAppConfigDetails().baseURL + "contacts/sandbox/" + syncContacts
        let headers: HTTPHeaders
        let authtoken = ChatManager.getAppConfigDetails().authtoken
        headers = [
            FlyConstants.authorization: authtoken, "content-type": "application/json"]
        print(headers)
        print(params)
        apiService.post(withEndPoint: url, params: params, headers: headers).responseJSON { [weak self] (response) in
            if response.response?.statusCode == 401 {
                ChatManager.refreshToken(completionHandler: { isSuccess,flyError,flyData  in
                    if isSuccess {
                        self?.contactSync()
                    }
                })
                return
            }
            switch response.result {
            case .success(let JSON):
                guard let responseDictionary = JSON as?[String : Any]  else{
                    return
                }
                if !Utility.getBoolFromPreference(key: firstTimeSandboxContactSyncDone) {
                    ChatManager.sendRegisterUpdate { isSuccess, error, data in
                        if isSuccess{
                            Utility.saveInPreference(key: firstTimeSandboxContactSyncDone, value: true)
                        }
                    }
                }
                ContactManager.shared.getRegisteredUsers(fromServer: true) { isSuccess, error, data in }
                print("success \(responseDictionary)")
                break
            case .failure(let error):
                print("Faill \(error.localizedDescription)")
                break
            }
        }
    }
}
