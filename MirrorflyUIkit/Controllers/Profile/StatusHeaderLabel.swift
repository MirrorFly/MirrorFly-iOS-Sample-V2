//
//  StatusHeaderLabel.swift
//  MirrorflyUIkit
//
//  Created by User on 21/09/21.
//

import Foundation
import UIKit

class StatusHeaderLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        textColor = Color.primaryTextColor
        textAlignment = .left
        translatesAutoresizingMaskIntoConstraints = false // enables auto layout
        font = UIFont.font18px_appSemibold()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
