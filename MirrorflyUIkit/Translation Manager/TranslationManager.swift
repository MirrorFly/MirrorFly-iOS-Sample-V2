//
//  TranslationManager.swift
//  GoogleTranslationApp
//
//  Created by User on 08/04/22.
//

import Foundation
import UIKit
import Alamofire

struct Constants {
    static let BaseUrl = "https://translation.googleapis.com/language/translate/v2/languages?"
    static let translateBaseUrl = "https://translation.googleapis.com/language/translate/v2/"
    
}



struct LanguageSelection : Decodable {
    
    var language : String?
    var name : String?
}



class TranslationManager: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public func supportedTranslationLanguages(TargetLanguageCode: String,GooogleAPIKey: String,complete: @escaping (_ languageList:[LanguageSelection],_ success: Bool,_ error: String) -> ()){
        
        let baseUrl = Constants.BaseUrl
        let parameters = [
            "target": "en",
            "key": "AIzaSyCdwzAZR6tx8KB-2dMn0KzSI1V0LpsYdH0"]
        
        AF.request(baseUrl,
                   method: .get,
                   parameters: parameters,
                   headers: nil)
            .validate(statusCode: 200..<500)
            .responseJSON(completionHandler: { (response) in
                switch response.result {
                case .success(let data):
                    switch response.response?.statusCode {
                    case 200, 204:
                        /// Handle success, parse JSON data
                        do {
                            debugPrint("AFData--->", data)
                            guard let dataLang = data as?[String:Any],let data = dataLang["data"] as? [String: Any],let languages = data["languages"] as? [[String: String]] else {
                                print("data error")
                                return
                            }
                            var langugaesList = [LanguageSelection]()
                            for item in languages{
                                print("language--->", item["language"]!)
                                print("name--->", item["name"]!)
                                
                                var tempLang = LanguageSelection()
                                tempLang.language = item["language"]!
                                tempLang.name = item["name"]!
                                langugaesList.append(tempLang)
                                
                            }
                            print("langugaesList-->", langugaesList)
                            complete(langugaesList,true,"")
                        }
                        catch _ {
                            /// Handle json decode error
                            complete([],false,"Json decode failure")
                        }
                    default:
                        /// Handle unknown error
                        complete([],false,"unknown Error")
                    }
                case .failure(_):
                    /// Handle request failure
                    complete([],false,"URLRequest failure")
                }
            })
    }
    
    public func languageTransalation(QueryString: String,TargetLanguageCode: String,GooogleAPIKey: String,complete: @escaping (_ translatedText: String,_ success: Bool,_ error: String) -> ()){
        
        let baseUrl = Constants.translateBaseUrl
        var parameters = [String: String]()
        parameters["key"] = GooogleAPIKey
        parameters["q"] = QueryString
        parameters["target"] = TargetLanguageCode
        parameters["format"] = "text"
        
        AF.request(baseUrl,
                 method: .post,
                 parameters: parameters,
                 headers: nil)
        .validate(statusCode: 200..<500)
        .responseJSON(completionHandler: { (response) in
            switch response.result {
                       case .success(let data):
                           switch response.response?.statusCode {
                           case 200, 204:
                               /// Handle success, parse JSON data
                               do {
                                   debugPrint("AFData--->", data)
                                   guard let dataLang = data as?[String:Any],let data = dataLang["data"] as? [String: Any],let translation = data["translations"] as? [[String: Any]],let translatedDict = translation[0] as? [String:String] else {
                                       print("data error")
                                       return
                                   }
                                
                                   let translatedText = translatedDict["translatedText"]
                                   complete(translatedText!,true,"")
                               }
                               catch _ {
                                   /// Handle json decode error
                                   complete("Failed",false,"Json decode failure")
                               }
                           default:
                               /// Handle unknown error
                               debugPrint("AFData--->", data)
                               complete("failed",false,"Translation failed, please check inputs")
                           }
            case .failure(_):
                           /// Handle request failure
                           complete("failed",false,"URLRequest failure")
                       }
                   })
    }
    
}



