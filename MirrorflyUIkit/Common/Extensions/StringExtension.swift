//
//  StringExtension.swift
//  commonDemo
//
//  Created by User on 13/08/21.
//

import Foundation
import UIKit
import Photos

var currentBundle: Bundle!

extension String{
    //Check string is empty
    static var Empty: String {
        return ""
    }
    
    // trim string
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
    
    var isNotEmpty: Bool {
        return !(self.trim().isEmpty)
    }
    
    // To show initial letter when profile image not available
    var initials: String {
        let words = components(separatedBy: .whitespacesAndNewlines)
        //to identify letters
        let letters = CharacterSet.alphanumerics
        var firstChar : String = ""
        var secondChar : String = ""
        var firstCharFoundIndex : Int = -1
        var firstCharFound : Bool = false
        var secondCharFound : Bool = false
        
        for (index, item) in words.enumerated() {
            if item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            for (_, char) in item.unicodeScalars.enumerated() {
                if letters.contains(char) {
                    if !firstCharFound {
                        firstChar = String(char)
                        firstCharFound = true
                        firstCharFoundIndex = index
                    } else if !secondCharFound {
                        secondChar = String(char)
                        if firstCharFoundIndex != index {
                            secondCharFound = true
                        }
                        break
                    } else {
                        break
                    }
                }
            }
        }
        return firstChar.uppercased() + secondChar.uppercased()
    }
    
    //Validate phone number
    func isValidMobileNumber(mobileNumber: String) -> Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: mobileNumber)
    }
    
    //Validate Email
    func isValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
    
    //To check text field or String is blank or not
    var isBlank: Bool {
        get {
            let trimmed = trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return trimmed.isEmpty
        }
    }
    
    //Change localise language
    func localize()->String{
        return NSLocalizedString(self, bundle: currentBundle, comment: "")
        
    }
    
    //Mark:- Localize String varibale
    var localized: String {
        
        guard let path = Bundle.main.path(forResource: LocalizeManager.share.currentlocalization(), ofType: "lproj") else {
            return NSLocalizedString(self, comment: "returns a chosen localized string")
        }
        let bundle = Bundle(path: path)
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
        
    }
    
    var isNumeric: Bool {
        return !(self.isEmpty) && self.allSatisfy { $0.isNumber }
    }
    
    func toPhoneNumber() -> String {
        return self.replacingOccurrences(of: "(\\d{3})(\\d{3})(\\d+)", with: "($1) $2-$3", options: .regularExpression, range: nil)
    }
    
    
    var isNumber: Bool {
        return Int(self) != nil
    }
    
    var isURL : Bool {
        if let url = URL(string: self) {
            if UIApplication.shared.canOpenURL(url as URL) {
                return true
            } else {
                return NSPredicate(format: "SELF MATCHES %@", AppRegex.urlFormat).evaluate(with: self)
            }
        }
        return false
    }
    
    func verifyisUrl (urlString: String?) -> Bool {
        if let urlString = urlString?.lowercased() {
            if let url = NSURL(string: urlString) {
                if UIApplication.shared.canOpenURL(url as URL) {
                    return true
                }
            }
        }
        return false
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "^[\\w\\.-]+@([\\w\\-]+\\.)+[A-Z]{1,4}$"
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    public func getAcronyms(separator: String = "") -> String
    {
        let acronyms = self.components(separatedBy: " ").map({ String($0.first!) }).joined(separator: separator);
        return acronyms;
    }
    
    func utf8DecodedString()-> String {
        let data = self.data(using: .utf8)
        let message = String(data: data!, encoding: .nonLossyASCII) ?? ""
        return message
    }
    
    func utf8EncodedString()-> String {
        let messageData = self.data(using: .nonLossyASCII)
        let text = String(data: messageData!, encoding: .utf8) ?? ""
        return text
    }
}
extension String {
    static func format(strings: [String],
                    boldFont: UIFont = UIFont.boldSystemFont(ofSize: 14),
                    boldColor: UIColor = UIColor.blue,
                    inString string: String,
                    font: UIFont = UIFont.systemFont(ofSize: 14),
                    color: UIColor = UIColor.black) -> NSAttributedString {
        let attributedString =
            NSMutableAttributedString(string: string,
                                    attributes: [
                                        NSAttributedString.Key.font: font,
                                        NSAttributedString.Key.foregroundColor: color])
        let boldFontAttribute = [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: boldColor]
        for bold in strings {
            attributedString.addAttributes(boldFontAttribute, range: (string as NSString).range(of: bold))
        }
        return attributedString
    }
}
