//
//  QRCodeScannerViewModel.swift
//  MirrorflyUIkit
//
//  Created by John on 17/01/22.
//

import Foundation
import MirrorFlySDK

class QRCodeScannerViewModel : NSObject{
    
    override init() {
        super.init()
    }
    
    func decryptQRCodeData(qrData : String, completionHandler : @escaping (_ isSuccess : Bool,_ message : String) -> Void) {
        WebLoginsManager.shared.handleQrCodeData(qrCodeString: qrData) { [weak self] isSuccess, Message in
            if isSuccess {
                print("QRCodeScannerViewModel isSuccess")
                self?.saveWebLoginInfo(qrData: qrData)
            }
            completionHandler(isSuccess,Message)
        }
    }
    
    func getSocketId(completionHandler : @escaping (_ isSuccess : Bool,_ message : String) -> Void) {
        WebLoginsManager.shared.getSocketId { isSuccess, message in
                completionHandler(isSuccess,message)
        }
    }
    
    func saveWebLoginInfo(qrData : String) {
        WebLoginsManager.shared.saveWebLogin(qrData: qrData)
    }
    
    func getWebLogins() -> [WebLoginInfo?] {
        return WebLoginsManager.shared.getWebLogins()
    }
    
    func getRecentWebLogin() -> [WebLoginInfo?] {
        return []
    }
    
    func resetConnection() {
        WebLoginsManager.shared.reset()
    }
    
    func logoutFromAllDevice() {
        WebLoginsManager.shared.logoutFromDevices()
    }
    
}
