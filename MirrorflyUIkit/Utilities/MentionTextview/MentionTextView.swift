//
//  MentionTextView.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 02/01/23.
//

import Foundation
import UIKit
import MirrorFlySDK


public enum ParserPattern: String {
    case mention = "\\[([\\w\\d\\sㄱ-ㅎㅏ-ㅣ가-힣.]{1,})\\]"
}

public enum MentionDeleteType {
    case cancel  // cancel mention(changed text)
    case delete  // delete mention
}

public class MentionTextView: UITextView {
    
    @IBInspectable public var highlightColor: UIColor = Color.muteSwitchColor
    @IBInspectable public var prefixMention: String = "@"
    public var pattern: ParserPattern = .mention
    
    var replaceValues: (oldText: String?, range: NSRange?, replacementText: String?) = (nil, nil, nil)
    
    var highlightUsers: [(String, NSRange)] = []
    var highlightCustomUsers: [(String, NSRange)] = []
    var mentionedNames: [String] = []
    var mentionedUsers: [String] = []
    
    public var deleteType: MentionDeleteType = .delete
    
    public var serverMessage: String = ""
    
    public var mentionText: String? {
        get {
            var replaceText = self.text
            replaceText = replaceText?.replacingOccurrences(of: "\\", with: "\\\\")
            replaceText = replaceText?.replacingOccurrences(of: "[", with: "\\[")
            replaceText = replaceText?.replacingOccurrences(of: "]", with: "\\]")


            if highlightUsers.count > 0 {
                for maps in highlightUsers.reversed() {
                    replaceText = replaceText?.replacing("@[?]", range: maps.1)
                }

                return replaceText
            }

            return replaceText
        } set {
            let (matchText, matchUsers) = self.parse(newValue, pattern: pattern, template: "$1", prefixMention: prefixMention)

            self.text = matchText

            if let matchUsers = matchUsers {
                highlightUsers.removeAll()
                for (user, range) in matchUsers {
                    highlightUsers.append((user, range))
                }

                refresh()
            }
        }
    }
    
    // MARK: override
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
       // delegate = self
        
        self.autocorrectionType = .no
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
      //  delegate = self
        
        self.autocorrectionType = .no
    }
    
}

// MARK: - Highlight
extension MentionTextView {
    public func insert(to user: String?, with nsrange: NSRange? = nil, userId: String, isCaption: Bool = false) {
        guard let user = user else { return }
        
        guard user.utf16.count > 0 else { return }
        
        var nsrange = nsrange ?? self.selectedRange
        
        var rangeLength = nsrange.length
        if nsrange.location + nsrange.length > text.utf16.count {
            rangeLength = nsrange.length - (nsrange.location + nsrange.length - text.utf16.count)
        }
        nsrange = NSRange.init(location: min(text.utf16.count, nsrange.location), length: rangeLength)
        guard let range = self.text.rangeFromNSRange(nsrange) else {
            return
        }
        let userName = "\(prefixMention)\(user) "
        replaceValues = (text, nsrange, userName)
        
        let uniqueId = AppUtils.shared.getRandomString(length: 8)
        
        self.text = self.text.replacingCharacters(in: range, with: userName)

        self.textDidChange(self)
        
        let insertRange = NSRange.init(location: nsrange.location, length: user.utf16.count + 2)
        highlightUsers.append((user, insertRange))
        highlightCustomUsers.append((userId, insertRange))

        highlightUsers.sort(by: { (lhs, rhs) -> Bool in
            return lhs.1.location < rhs.1.location
        })
        highlightCustomUsers.sort(by: { (lhs, rhs) -> Bool in
            return lhs.1.location < rhs.1.location
        })
        self.selectedRange = NSMakeRange(insertRange.location + insertRange.length, 0)
        
        if isCaption {
            self.textViewEnd()
        }
        refresh()
    }
    
    func convertAndInsert(to user: [String], with nsrange: NSRange? = nil, isCaption: Bool = false) {
        let mentionUsers:[String] = user[1].isEmpty ? [] : user[1].components(separatedBy: ",")
        var textString = user[0]
        var copyMessage = self.text.replacing(textString, range: nsrange!)
        print("convertAndInsert: \(highlightUsers)")
        print("convertAndInsert: \(highlightUsers)")

        var newUsers: [(String, NSRange)] = []
        for oldUser in highlightUsers {
            if (nsrange?.location ?? 0) < oldUser.1.location {
                let count = mentionUsers.isEmpty ? (textString.utf16.count) : (textString.utf16.count-2)
                newUsers.append((oldUser.0, NSRange(location: (oldUser.1.location+(count)), length: (oldUser.1.length))))
            } else {
                newUsers.append((oldUser.0, oldUser.1))
            }
        }
        highlightUsers = newUsers
        
        var newUsers2: [(String, NSRange)] = []

        for oldUser in highlightCustomUsers {
            if (nsrange?.location ?? 0) < oldUser.1.location {
                let count = mentionUsers.isEmpty ? (textString.utf16.count) : (textString.utf16.count-3)
                newUsers2.append((oldUser.0, NSRange(location: (oldUser.1.location+(count)), length: (oldUser.1.length))))
            } else {
                newUsers2.append((oldUser.0, oldUser.1))
            }
        }
        highlightCustomUsers = newUsers2
        
        for users in mentionUsers {
            if let slices = textString.slice(from: "`", to: "`") {
                let mentionRange = (textString as NSString).range(of: "`\(slices)`")
                let mentionRange2 = (copyMessage as NSString).range(of: "@`\(slices)`")
                if users != FlyDefaults.myXmppUsername {
                    highlightUsers.append((slices, NSRange(location: mentionRange2.location, length: mentionRange2.length-2)))
                    highlightCustomUsers.append((users, NSRange(location: mentionRange2.location, length: mentionRange2.length-2)))
                }
                textString = textString.replacing(slices, range: mentionRange)
                copyMessage = copyMessage.replacing("@\(slices)", range: mentionRange2)
            }
        }
        self.text = copyMessage
        
        highlightUsers.sort(by: { (lhs, rhs) -> Bool in
            return lhs.1.location < rhs.1.location
        })
        highlightCustomUsers.sort(by: { (lhs, rhs) -> Bool in
            return lhs.1.location < rhs.1.location
        })
        print("convertAndInsert:2 \(highlightUsers)")
        print("convertAndInsert:2 \(highlightCustomUsers)")
        
        if isCaption {
            self.textViewEnd()
        }

        refresh(nsrange: NSRange(location: self.text.utf16.count, length: 0))
    }
    
    func refresh(nsrange: NSRange? = nil) {
        // get current cursor position
        let selectedRange = nsrange ?? self.selectedRange
        
        // set attributed text
        let attributedText = NSMutableAttributedString()
        attributedText.appendText(text, font: self.font!, color: UIColor.black)
        
        for range in highlightUsers {
            if range.1.length + range.1.location <= text.utf16.count {
                attributedText.addAttributes(self.font!, color: highlightColor, range: range.1)
//                attributedText.addAttributes(self.font!, color: Color.mentionColor!, range: NSRange(location: range.1.location, length: 1))
            }
        }
        
        self.attributedText = attributedText
        
        // set cursor position
 //       if nsrange != nil {
        self.selectedRange = selectedRange//NSRange(location: self.text.utf16.count, length: 0)
//        } else {
//            self.selectedRange = selectedRange
//        }
    }
    
    public func textViewEnd() {
        mentionedUsers.removeAll()
        for userId in highlightCustomUsers {
            mentionedUsers.append(userId.0)
        }
    }
    
    public func shouldChangeTextIn(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) {
        replaceValues = (textView.text, range, text)
    }
    
    public func textDidChange(_ textView: UITextView, isCaption: Bool = false) {
        defer {
            replaceValues = (nil, nil, nil)
            refresh()
            if isCaption {
                textViewEnd()
            }
        }
        
        guard let range = replaceValues.range else {
            return
        }
        
        guard let replacementText = replaceValues.replacementText else {
            return
        }
        
        if replacementText.utf16.count > 0 {
            // insert Text
            
            // If the length does not change even after adding text
            // (If you add neutral or vertical, it is entered, but it does not actually affect the overall length)
            if replaceValues.oldText?.utf16.count == textView.text.utf16.count && range.length == 0 {
                return
            }
            
            var newUsers: [(String, NSRange)] = []
            var newUsers2: [(String, NSRange)] = []

            for oldUser in highlightUsers {
                
                if range.location < oldUser.1.location + oldUser.1.length && range.location + range.length > oldUser.1.location {
                    continue
                } else {
                    if range.location + range.length <= oldUser.1.location {
                        let newRange = NSRange.init(location: max(0, oldUser.1.location + (replacementText.utf16.count - range.length)), length: oldUser.1.length)
                        newUsers.append((oldUser.0, newRange))
                    } else {
                        newUsers.append(oldUser)
                    }
                }
            }
            
            for oldUser in highlightCustomUsers {
                
                if range.location < oldUser.1.location + oldUser.1.length && range.location + range.length > oldUser.1.location {
                    continue
                } else {
                    if range.location + range.length <= oldUser.1.location {
                        let newRange = NSRange.init(location: max(0, oldUser.1.location + (replacementText.utf16.count - range.length)), length: oldUser.1.length)
                        newUsers2.append((oldUser.0, newRange))
                    } else {
                        newUsers2.append(oldUser)
                    }
                }
            }

            highlightCustomUsers = newUsers2
            highlightUsers = newUsers
        } else {
            // remove Text

            // If the length remains unchanged even after erasing
            // (Even if you delete a neutral or a species, it doesn't actually delete them.) << only unicode case.
            if replaceValues.oldText?.utf16.count == textView.text.utf16.count {
                return
            }
            
            // Check whether a mention is included while deleting text.
            // If my mention is included, remove the mention
            // otherwise pull forward as much as the text to delete the location of the mention.
            var newUsers: [(String, NSRange)] = []
            var newUsers2: [(String, NSRange)] = []

            var removeRange = range
            var removeRange2 = range
            
            for oldUser in highlightUsers {
                if removeRange.location >= oldUser.1.location + oldUser.1.length {
                    // The starting point of erasing is behind my mention (not affected by erasing)
                    newUsers.append(oldUser)
                } else if removeRange.location >= oldUser.1.location && removeRange.location < oldUser.1.location + oldUser.1.length {
                    // The starting point to erase is inside my mention (removing the existing mention)
                    
                    if deleteType == .delete, let removeIndex = highlightUsers.firstIndex(where: { $0.1 == oldUser.1 }) {
                        if oldUser.1.length > removeRange.length {
                            let range = NSRange(location: oldUser.1.location, length: oldUser.1.length - removeRange.length)
                            self.text = self.text.replacing("", range: range)
                            removeRange = oldUser.1
                        }
                    }
                    
                    continue
                } else {
                    // The starting point to erase is in front of my mention
                    
                    // Determining whether the end point to be erased is in or out of my mention (only the mention that was applied at this time is removed).
                    if removeRange.location + removeRange.length > oldUser.1.location {
                        continue
                    } else {
                        // Erasing the mention from my front
                        // As much as you erase, the mention is positioned forward.
                        let newRange = NSRange(location: max(0, oldUser.1.location - removeRange.length), length: oldUser.1.length)
                        newUsers.append((oldUser.0, newRange))
                    }
                }
            }
            
            for oldUser in highlightCustomUsers {
                if removeRange2.location >= oldUser.1.location + oldUser.1.length {
                    // The starting point of erasing is behind my mention (not affected by erasing)
                    newUsers2.append(oldUser)
                } else if removeRange.location >= oldUser.1.location && removeRange2.location < oldUser.1.location + oldUser.1.length {
                    // The starting point to erase is inside my mention (removing the existing mention)
                    
                    if deleteType == .delete, let removeIndex = highlightUsers.firstIndex(where: { $0.1 == oldUser.1 }) {
                        if oldUser.1.length > removeRange.length {
                            let range = NSRange(location: oldUser.1.location, length: oldUser.1.length - removeRange2.length)
                            self.text = self.text.replacing("", range: range)
                            removeRange2 = oldUser.1
                        }
                    }
                    
                    continue
                } else {
                    // The starting point to erase is in front of my mention
                    
                    // Determining whether the end point to be erased is in or out of my mention (only the mention that was applied at this time is removed).
                    if removeRange2.location + removeRange2.length > oldUser.1.location {
                        continue
                    } else {
                        // Erasing the mention from my front
                        // As much as you erase, the mention is positioned forward.
                        let newRange = NSRange(location: max(0, oldUser.1.location - removeRange.length), length: oldUser.1.length)
                        newUsers2.append((oldUser.0, newRange))
                    }
                }
            }

            highlightCustomUsers = newUsers2
            highlightUsers = newUsers
        }
        
        highlightUsers.sort(by: { (lhs, rhs) -> Bool in
            return lhs.1.location < rhs.1.location
        })
        
        highlightCustomUsers.sort(by: { (lhs, rhs) -> Bool in
            return lhs.1.location < rhs.1.location
        })
    }
    
}

//extension MentionTextView: UITextViewDelegate {
//    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        replaceValues = (textView.text, range, text)
//        return true
//    }
//
//    public func textViewDidChange(_ textView: UITextView) {
//        defer {
//            replaceValues = (nil, nil, nil)
//            refresh()
//        }
//
//        guard let range = replaceValues.range else {
//            return
//        }
//
//        guard let replacementText = replaceValues.replacementText else {
//            return
//        }
//
//        if replacementText.utf16.count > 0 {
//            // insert Text
//
//            // If the length does not change even after adding text
//            // (If you add neutral or vertical, it is entered, but it does not actually affect the overall length)
//            if replaceValues.oldText?.utf16.count == textView.text.utf16.count && range.length == 0 {
//                return
//            }
//
//            var newUsers: [(String, NSRange)] = []
//            for oldUser in highlightUsers {
//
//                if range.location < oldUser.1.location + oldUser.1.length && range.location + range.length > oldUser.1.location {
//                    continue
//                } else {
//
//                    if range.location + range.length <= oldUser.1.location {
//                        let newRange = NSRange.init(location: max(0, oldUser.1.location + (replacementText.utf16.count - range.length)), length: oldUser.1.length)
//                        newUsers.append((oldUser.0, newRange))
//                    } else {
//                        newUsers.append(oldUser)
//                    }
//                }
//            }
//
//            highlightUsers = newUsers
//        } else {
//            // remove Text
//
//            // If the length remains unchanged even after erasing
//            // (Even if you delete a neutral or a species, it doesn't actually delete them.) << only unicode case.
//            if replaceValues.oldText?.utf16.count == textView.text.utf16.count {
//                return
//            }
//
//            // Check whether a mention is included while deleting text.
//            // If my mention is included, remove the mention
//            // otherwise pull forward as much as the text to delete the location of the mention.
//            var newUsers: [(String, NSRange)] = []
//            var removeRange = range
//
//            for oldUser in highlightUsers {
//                if removeRange.location >= oldUser.1.location + oldUser.1.length {
//                    // The starting point of erasing is behind my mention (not affected by erasing)
//                    newUsers.append(oldUser)
//                } else if removeRange.location >= oldUser.1.location && removeRange.location < oldUser.1.location + oldUser.1.length {
//                    // The starting point to erase is inside my mention (removing the existing mention)
//
//                    if deleteType == .delete {
//                        let range = NSRange(location: oldUser.1.location, length: oldUser.1.length - removeRange.length)
//                        self.text = self.text.replacing("", range: range)
//
//                        removeRange = oldUser.1
//                    }
//
//                    continue
//                } else {
//                    // The starting point to erase is in front of my mention
//
//                    // Determining whether the end point to be erased is in or out of my mention (only the mention that was applied at this time is removed).
//                    if removeRange.location + removeRange.length > oldUser.1.location {
//                        continue
//                    } else {
//                        // Erasing the mention from my front
//                        // As much as you erase, the mention is positioned forward.
//                        let newRange = NSRange(location: max(0, oldUser.1.location - removeRange.length), length: oldUser.1.length)
//                        newUsers.append((oldUser.0, newRange))
//                    }
//                }
//            }
//
//            highlightUsers = newUsers
//        }
//
//        highlightUsers.sort(by: { (lhs, rhs) -> Bool in
//            return lhs.1.location < rhs.1.location
//        })
//    }
//}
extension String {
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

extension NSAttributedString {
    func stringWithString(stringToReplace: String, replacedWithString newStringPart: String) -> NSMutableAttributedString
    {
        let mutableAttributedString = mutableCopy() as! NSMutableAttributedString
        let mutableString = mutableAttributedString.mutableString
        while mutableString.contains(stringToReplace) {
            let rangeOfStringToBeReplaced = mutableString.range(of: stringToReplace)
            mutableAttributedString.replaceCharacters(in: rangeOfStringToBeReplaced, with: newStringPart)
        }
        return mutableAttributedString
    }
}

extension String {
    func rangeFromNSRange(_ nsRange : NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }
    
    func substringFromNSRange(_ nsRange : NSRange) -> String {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return self }
        return String(self[from..<to])
    }
    func replacing(_ withString: String, range: NSRange) -> String {
        if let textRange = self.rangeFromNSRange(range) {
            return self.replacingCharacters(in: textRange, with: withString)
        }
        
        return self
    }
}
extension NSMutableAttributedString {
    
    @discardableResult public func appendText(_ text: String, font: UIFont, color: UIColor) -> NSMutableAttributedString {
        let attributes = [NSAttributedString.Key.foregroundColor: color,
                          NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        self.append(attributedText)
        
        return self
    }
    
    @discardableResult public func addAttributes(_ font: UIFont, color: UIColor, range: NSRange) -> NSMutableAttributedString {
        let attributes = [NSAttributedString.Key.foregroundColor: color,
                          NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any]
        self.addAttributes(attributes, range: range)
        
        return self
    }
    
    @discardableResult public func addBGAttributes(_ font: UIFont, color: UIColor, range: NSRange) -> NSMutableAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: color,
                          NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any]
        self.addAttributes(attributes, range: range)
        
        return self
    }
}
extension Array where Element: Hashable {
    func getDifference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
extension String {
    
    func replacingRanges(_ ranges: [NSRange], with insertions: [String]) -> String {
        var copy = self
        copy.replaceRanges(ranges, with: insertions)
        return copy
    }
    
    mutating func replaceRanges(_ ranges: [NSRange], with insertions: [String]) {
        var pairs = Array(zip(ranges, insertions))
        pairs.sort(by: { $0.0.upperBound > $1.0.upperBound })
        for (range, replacementText) in pairs {
            guard let textRange = Range(range, in: self) else { continue }
            replaceSubrange(textRange, with: replacementText)
        }
    }
    
}
extension UIView {
    func parse(_ text: String?, pattern: ParserPattern, template: String, prefixMention: String = "@") -> (String?, [(String, NSRange)]?) {
        guard var matchText = text else {
            return (nil, nil)
        }
        
        var matchUsers: [(String, NSRange)] = []
        
        while true {
            guard let match = matchText.getFirstElements(pattern) else {
                break
            }
            
            let firstFindedText = matchText.substringFromNSRange(match.range)
            
            let data = firstFindedText.replacingOccurrences(of: pattern.rawValue, with: template, options: .regularExpression, range: firstFindedText.range(of: firstFindedText))
            
            if data.count > 0 {
                matchText = matchText.replacing(pattern: pattern, range: match.range, withTemplate: "\(prefixMention)\(template)")
                
                let matchRange = NSRange(location: match.range.location, length: data.utf16.count + 1)
                matchText = matchText.replacing("\(prefixMention)\(data)", range: matchRange)
                
                matchUsers.append((data, matchRange))
            }
        }
        
        // print("\(matchText)")

        // replacing
        matchText = matchText.replacingOccurrences(of: "\\[", with: "[")
        matchText = matchText.replacingOccurrences(of: "\\]", with: "]")
        matchText = matchText.replacingOccurrences(of: "\\\\", with: "\\")
        
        
        if matchUsers.count > 0 {
            return (matchText, matchUsers)
        }
        
        return (matchText, nil)
    }
}
extension String {
    func getElements(_ pattern: ParserPattern = .mention) -> [NSTextCheckingResult] {
        guard let elementRegex = try? NSRegularExpression(pattern: pattern.rawValue, options: [.caseInsensitive]) else {
            return []
        }
        
        return elementRegex.matches(in: self, options: [], range: NSRange(0..<self.utf16.count))
    }
    
    func getFirstElements(_ pattern: ParserPattern = .mention) -> NSTextCheckingResult? {
        guard let elementRegex = try? NSRegularExpression(pattern: pattern.rawValue, options: [.caseInsensitive]) else {
            return nil
        }
        
        return elementRegex.firstMatch(in: self, options: [], range: NSRange(0..<self.utf16.count))
    }
    
    func replacing(pattern: ParserPattern = .mention, range: NSRange? = nil, withTemplate: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern.rawValue, options: [.caseInsensitive]) else {
            return self
        }
        
        if let range = range {
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: withTemplate)
        } else {
            return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(0..<self.utf16.count), withTemplate: withTemplate)
        }
    }
    
}
extension MentionTextView {

    private class PlaceholderLabel: UILabel { }

    private var placeholderLabel: PlaceholderLabel {
        if let label = subviews.compactMap( { $0 as? PlaceholderLabel }).first {
            return label
        } else {
            let label = PlaceholderLabel(frame: .zero)
            label.font = font
            label.textColor = .lightGray
            addSubview(label)
            return label
        }
    }

    @IBInspectable
    var placeholder: String {
        get {
            return subviews.compactMap( { $0 as? PlaceholderLabel }).first?.text ?? ""
        }
        set {
            let placeholderLabel = self.placeholderLabel
            placeholderLabel.text = newValue
            placeholderLabel.numberOfLines = 0
            let width = frame.width - textContainer.lineFragmentPadding * 2
            let size = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            placeholderLabel.frame.size.height = size.height
            placeholderLabel.frame.size.width = width
            placeholderLabel.frame.origin = CGPoint(x: textContainer.lineFragmentPadding, y: textContainerInset.top)

            textStorage.delegate = self
        }
    }

    func resetMentionTextView() {
        mentionedUsers.removeAll()
        highlightUsers.removeAll()
        highlightCustomUsers.removeAll()
    }
}

extension MentionTextView: NSTextStorageDelegate {

    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        if editedMask.contains(.editedCharacters) {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }

}
