//
//  CustomNotificationView.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 24/03/23.
//

import UIKit

class CustomNotificationView: UIView {
    
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
