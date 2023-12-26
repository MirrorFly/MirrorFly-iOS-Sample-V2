//
//  StarredReceiverView.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya on 07/12/22.
//

import Foundation
import UIKit

class StarredReceiverView : UIView {
    @IBOutlet weak var messsageReceivedLabel: UILabel?
    @IBOutlet weak var MessageReceiverLabel: UILabel?
    @IBOutlet weak var profileImageView: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
