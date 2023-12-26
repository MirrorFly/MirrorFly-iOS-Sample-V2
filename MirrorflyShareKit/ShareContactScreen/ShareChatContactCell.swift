//
//  ShareChatContactCell.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 10/03/23.
//

import Foundation
import UIKit

class ShareChatContactCell: UITableViewCell {

    @IBOutlet weak var contactNumber: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var contactLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
       // selectButton.isSelected = true
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onSelectContact(_ sender: Any) {
//        let button = sender as? UIButton
//        if !(button?.isSelected ?? false) {
//            selectButton.isSelected = true
//        } else {
//            selectButton.isSelected = false
//        }
    }
}
