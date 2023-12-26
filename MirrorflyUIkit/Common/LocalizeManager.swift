//
//  LocalizeManage.swift
//  MirrorflyUIkit
//
//  Created by User on 16/08/21.
//

import UIKit

enum Language : String, Codable, CaseIterable {
    case english = "en"
    case arabic = "ar"
    var code : String {
        switch self {
        case .english:
            return "en"
        case .arabic:
            return "ar"
        }
    }
 
    static var count: Int{ return 2 }
}


class LocalizeManager {
    
    static var share = LocalizeManager()
    var selectedLanguage : Language = .english
    
    func changeLocalization(language:Language) {
        Utility.saveInPreference(key: "Language", value: language.rawValue)
    }
    
    func currentlocalization() -> String {
        let savedLocale = Utility.getStringFromPreference(key: "Language")
        return savedLocale.isEmpty ? Language.english.rawValue : savedLocale
    }
    
    func currentLanguage() -> String{
        
        switch currentlocalization() {
        case Language.english.rawValue:
            return english.localize()
        case Language.arabic.rawValue:
            return arabic.localize()
        default:
            return String.Empty
        }
    }
    
    func setLocalization(language : Language){
        
        if let path = Bundle.main.path(forResource: language.code, ofType: "lproj"), let bundle = Bundle(path: path) {
                        let attribute : UISemanticContentAttribute = language == .arabic ? .forceRightToLeft : .forceLeftToRight
                        UIView.appearance().semanticContentAttribute = attribute
            selectedLanguage = language
            currentBundle = bundle
        } else {
            currentBundle = .main
        }
    }
}
