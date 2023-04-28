//
//  UILabelExtension.swift
//  MirrorflyUIkit
//
//  Created by John on 19/04/22.
//

import Foundation
import UIKit

extension UILabel {
    
    func underLine(text : String) {
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.thick.rawValue]
        let underlineAttributedString = NSAttributedString(string: text, attributes: underlineAttribute)
        self.attributedText = underlineAttributedString
    }
    
        func indexOfAttributedTextCharacterAtPoint(point: CGPoint) -> Int {
            assert(self.attributedText != nil, "This method is developed for attributed string")
            let textStorage = NSTextStorage(attributedString: self.attributedText!)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)
            let textContainer = NSTextContainer(size: self.frame.size)
            textContainer.lineFragmentPadding = 0
            textContainer.maximumNumberOfLines = self.numberOfLines
            textContainer.lineBreakMode = self.lineBreakMode
            layoutManager.addTextContainer(textContainer)

            let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            return index
        }
    func setImage(image: UIImage, with text: String) {
      let attachment = NSTextAttachment()
      attachment.image = image
      attachment.bounds = CGRect(x: 0, y: 0, width: 40, height: 30)
      let attachmentStr = NSAttributedString(attachment: attachment)

      let mutableAttributedString = NSMutableAttributedString()
      mutableAttributedString.append(attachmentStr)

      let textString = NSAttributedString(string: text, attributes: [.font: self.font])
      mutableAttributedString.append(textString)

      self.attributedText = mutableAttributedString
    }
}
