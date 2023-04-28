//
//  StarredSenderView.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya on 07/12/22.
//

import Foundation
import UIKit

class StarredSenderView : UIView {
    @IBOutlet weak var profileImageView: UIImageView?
    @IBOutlet weak var messageSenderLabel: UILabel?
    @IBOutlet weak var messageSendTime: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
     
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
