//
//  GroupReceivedMessageHeader.swift
//  MirrorflyUIkit
//
//  Created by John on 06/12/21.
//

import UIKit

class GroupReceivedMessageHeader: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.font = UIFont.font14px_appSemibold()
    }

}
