//
//  UserDefaults.swift
//  MirrorFly
//
//  Created by User on 18/05/21.
//

import UIKit
import MirrorFlySDK
import Alamofire
import CommonCrypto

class Utility: NSObject{
    
    class func saveInPreference (key : String , value : Any) {
        var stringaValue = ""
        if let boolString = value as? Bool{
            stringaValue = boolString ? "true" : "false"
        }else if let value = value as? String{
            stringaValue  = value
        }
        if let encryptedData = encryptDecryptFlyDefaults(key: key, data:  Data(stringaValue.utf8), encrypt: true){
            UserDefaults.standard.setValue(encryptedData, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
    
    class func getStringFromPreference(key : String) -> String {
        if let value =  UserDefaults.standard.object(forKey: key) {
            if let encryptedData = value as? Data{
                if let decryptedData = encryptDecryptFlyDefaults(key: key, data:  encryptedData, encrypt: false){
                    return String(data: decryptedData, encoding: .utf8)!
                }
            }else if let oldValue = value as? String {
                saveInPreference(key: key, value: oldValue)
                return oldValue
            }
        }
        return ""
    }
    
    class func getBoolFromPreference(key : String) -> Bool {
        if let value = UserDefaults.standard.object(forKey: key) {
            if let encryptedData =  value as? Data{
                if let decryptedData = encryptDecryptFlyDefaults(key: key, data:  encryptedData, encrypt: false){
                    return (String(data: decryptedData, encoding: .utf8)! == "true" )
                }
            } else if let oldValue = value as? Bool {
                saveInPreference(key: key, value: oldValue)
                return oldValue
            }
        }
        return false
    }
    
    class func setAutoBackupDetails(isOn: Bool) {
        UserDefaults.standard.setValue(isOn, forKey: "isAutoBackup")
        if isOn {
            UserDefaults.standard.setValue(Date().description.localizedLowercase, forKey: "autoBackupDate")
        }
        UserDefaults.standard.synchronize()
    }
    
    class func setAutoBackupDate() {
        UserDefaults.standard.setValue(Date().description.localizedLowercase, forKey: "autoBackupDate")
    }
    
    class func setAutoBackupOver(isOn: Bool) {
        UserDefaults.standard.setValue(isOn, forKey: "isAutoBackupOver")
        UserDefaults.standard.synchronize()
    }
    
    class func setAutoBackupSchedule(schedule: String) {
        UserDefaults.standard.setValue(schedule, forKey: "autoBackupSchedule")
        UserDefaults.standard.synchronize()
    }
    
    class func setAutoBackupNetwork(over: String) {
        UserDefaults.standard.setValue(over, forKey: "autoBackupNetwork")
        UserDefaults.standard.synchronize()
    }
    
    class func getAutoBackupIsOn() -> Bool {
        return UserDefaults.standard.object(forKey: "isAutoBackup") as? Bool ?? false
    }
    
    class func getAutoBackupOverIsOn() -> Bool {
        return UserDefaults.standard.object(forKey: "isAutoBackupOver") as? Bool ?? false
    }
    
    class func getAutoBackupSchedule() -> String {
        return UserDefaults.standard.object(forKey: "autoBackupSchedule") as? String ?? "Daily"
    }
    
    class func getAutoBackupDate() -> String {
        return UserDefaults.standard.object(forKey: "autoBackupDate") as? String ?? ""
    }
    
    class func getAutoBackupNetwork() -> String {
        return UserDefaults.standard.object(forKey: "autoBackupNetwork") as? String ?? "Wi-Fi"
    }
    
    class func timeString(time: TimeInterval) -> String {
        let minute = Int(time) / 60 % 60
        let second = Int(time) % 60

        // return formated string
        return String(format: "%02i:%02i", minute, second)
    }
    
    class func secondsToMinutesSeconds (seconds : Int32) -> String {
        let minute = (seconds % 3600) / 60
        let second = (seconds % 3600) % 60
        
      return String(format: "%02i:%02i", minute, second)
    }
    
    class func currentMillisecondsToTime(milliSec: Double) -> String{
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(milliSec)/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = chatTimeFormat
        return dateFormatter.string(from: dateVar)
    }
    
    class func removeCharFromString(string: String, char: String) ->String {
        let strValue = string.replacingOccurrences(of: char, with: "", options: NSString.CompareOptions.literal, range: nil)
        return strValue

    }
 
    public class func appendBaseURL(restEnd : String) -> String {
        var restEndUrl:String = ""
        
        if (!restEnd.hasPrefix("http://") && !restEnd.hasPrefix("https://")) {
            restEndUrl = ChatManager.getAppConfigDetails().baseURL + restEnd
        }
        return restEndUrl
    }
    
    public class func IntialLetter(name : String , imageView: UIImageView , colorCode : String, frameSize : Int, fontSize : CGFloat)
    {
        let lblNameInitialize = UILabel()
        lblNameInitialize.frame.size = CGSize(width: frameSize, height: frameSize)
        lblNameInitialize.textColor = UIColor.white
        lblNameInitialize.font = AppFont.Bold.size(fontSize)
        let wordArray = name.split(separator: " ")
        if wordArray.count >= 2 {
            let firstTwoChar = String(wordArray[0].first!).uppercased() + String(wordArray[1].first!).uppercased()
            lblNameInitialize.text = firstTwoChar
        }else{
            lblNameInitialize.text = String(name.prefix(2)).uppercased()
        }
        lblNameInitialize.textAlignment = NSTextAlignment.center
        UIGraphicsBeginImageContext(CGSize(width: frameSize, height: frameSize))
        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        imageView.backgroundColor = getColor(userName: name)
        imageView.contentMode = .center
        UIGraphicsEndImageContext()
    }
    
    public class func download(token : String , profileImage : UIImageView?, uniqueId : String, name : String, colorCode : String, frameSize: Int, fontSize : CGFloat,notify: Bool = false,completion : @escaping () -> Void) {
        let imageCache = ImageCache.shared
        if let profileImage = profileImage{
            if token == "" {
                IntialLetter(name: name, imageView: profileImage, colorCode: colorCode,frameSize: frameSize,fontSize: fontSize)
            }else{
                if let cachedImage = imageCache.object(forKey: token as NSString) {
                    profileImage.clipsToBounds = true
                    profileImage.contentMode = .scaleAspectFill
                    profileImage.image = cachedImage
                }else{
                    IntialLetter(name: name, imageView: profileImage, colorCode: colorCode,frameSize: frameSize,fontSize: fontSize)
                    var endPoint = String()
                    if token.contains("https"){
                        let arr = token.components(separatedBy: "/")
                        let baseUrl = "\(arr[6])".components(separatedBy: ".")
                        endPoint = appendBaseURL(restEnd: "media/" + "\(baseUrl[0])" + ".")
                    }else{
                        let baseUrl = "media/" + token
                        endPoint = appendBaseURL(restEnd: baseUrl)
                    }
                    var localFileName : String = ""
                    let destination: DownloadRequest.Destination = { _, _ in
                        let localPath = attachmentsDocumentDirectory()
                        localFileName = generateUniqueId()
                        let localFilePath = localPath.appendingPathComponent(localFileName)
                        return (localFilePath, [.removePreviousFile, .createIntermediateDirectories])
                    }
                    let headers: HTTPHeaders
                    headers = [
                        "Content-Type": "application/json",
                        "Authorization": ChatManager.getAppConfigDetails().authtoken,
                        "messageID" : ""
                    ]
                    AF.download(endPoint, method: .get, headers: headers, to: destination)
                        .responseData { [self] (response) in
                            if response.error == nil{
                                if response.response?.statusCode == 200 {
                                    DispatchQueue.main.async {
                                        if let uiImage = UIImage(contentsOfFile: response.fileURL?.relativePath ?? ""){
                                            imageCache.setObject(uiImage, forKey: token as NSString)
                                            if notify {
                                                completion()
                                            }else{
                                                profileImage.contentMode = .scaleAspectFill
                                                profileImage.image = imageCache.object(forKey: token as NSString)
                                            }
                                        }
                                    }
                                }else if response.response?.statusCode == 401{
                                    ChatManager.refreshToken {  isSuccess,error,data  in
                                        if isSuccess {
                                            self.download(token: token, profileImage: profileImage, uniqueId: uniqueId,name: name,colorCode: colorCode,frameSize: frameSize,fontSize: fontSize, completion: completion)
                                        }
                                    }
                                }
                                
                            }else{
                                print(response.description)
                            }
                        }
                }
            }
        }
        
    }

    public class func refreshToken(onCompletion: @escaping (_ isSuccess: Bool) -> Void) {
        ChatManager.refreshToken { isSuccess, error, data in
            onCompletion(isSuccess)
        }
    }

    
    public class func color(fromHexString hexString: String?) -> UIColor? {
        if (hexString?.count ?? 0) != 0 {
            let hexint = Int(intFromHexString(hexStr: hexString!))
            let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
            let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
            let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
            // Create color object, specifying alpha as well
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return color
        } else {
            return UIColor.black
        }
    }
    
    public class func intFromHexString(hexStr: String) -> UInt32 {
        var hexInt: UInt32 = 0
        // Create scanner
        let scanner: Scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        // Scan hex value
        scanner.scanHexInt32(&hexInt)
        return hexInt
    }
    
    public static func attachmentsDocumentDirectory() -> URL {
        var customFolder = "FlyMedia"
        customFolder = customFolder + "/" + "Image"
        let fileManager = FileManager.default
        let documentsFolder = FlyUtils.getGroupContainerIDPath()
        let localPath = documentsFolder!.appendingPathComponent(customFolder)
        let folderExists = (try? localPath.checkResourceIsReachable()) ?? false
        do {
            if !folderExists {
                try fileManager.createDirectory(at: localPath, withIntermediateDirectories: true)
            }
        } catch { print(error) }
        
        return localPath
    }
    
    public static func generateUniqueId() -> String {
        return UUID.init().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
    
    
    class func clearUserDefaults(){
        let defaults = UserDefaults.standard
        let dictionary =  defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    
    class func encryptDecryptFlyDefaults(key:String, data : Data, encrypt : Bool, iv : String = "ddc0f15cc2c90fca") -> Data?{
        guard let key = FlyEncryption.sha256(key, length: 32) else {
            return data
        }
        guard let flyEncryption = FlyEncryption(encryptionKey: key, initializationVector: iv ) else {
            return data
        }
        
        if encrypt {
            guard let encryptedData  = flyEncryption.crypt(data: data, option: CCOperation(kCCEncrypt)) else {
                return data
            }
            print("#ud encrypt \(key)  \(encryptedData)")
            return encryptedData
        } else {
            guard let decryptedData  = flyEncryption.crypt(data: data, option:  CCOperation(kCCDecrypt)) else {
                return nil
            }
            print("#ud decrypt \(key)  \(decryptedData)")
            return decryptedData
        }
    }
    
}
extension TimeInterval {
    var minuteSecondMS: String {
        return String(format:"%d:%02d", minute, second)
    }
    var minute: Int {
        return Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        return Int(truncatingRemainder(dividingBy: 60))
    }
}

extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}

public class ImageCache {
    
    private init() {}
    
    public static let shared = NSCache<NSString, UIImage>()
    
}


extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}
