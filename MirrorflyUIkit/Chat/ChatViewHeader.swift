//
//  ChatViewHeader.swift
//  MirrorflyUIkit
//
//  Created by User on 27/08/21.
//

import Foundation
import UIKit

class ChatViewHeader: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = Color.chatDateHeaderBackground
        textColor = Color.chatDateHeaderText
        textAlignment = .center
        translatesAutoresizingMaskIntoConstraints = false // enables auto layout
        font = UIFont.font9px_appRegular()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let originalContentSize = super.intrinsicContentSize
        let height = originalContentSize.height + 12
        layer.cornerRadius = height / 2
        layer.masksToBounds = true
        return CGSize(width: originalContentSize.width + 20, height: height)
    }
    
}


class ContactPreviewHeader: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        textColor = .black
        textAlignment = .left
        translatesAutoresizingMaskIntoConstraints = false
        font = UIFont.font18px_appSemibold()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    
}
