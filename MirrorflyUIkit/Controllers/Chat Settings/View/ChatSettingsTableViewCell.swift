//
//  ChatSettingsTableViewCell.swift
//  UiKitQa
//
//  Created by User on 11/04/22.
//
import UIKit

class ChatSettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var doubleTapHeight: NSLayoutConstraint!
    @IBOutlet weak var separaterView: UIView!
    
    @IBOutlet weak var defaultLanguageHeight: NSLayoutConstraint!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var helpTextLabel: UILabel!
    @IBOutlet weak var selectedImageMainView: UIView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var helpTextView: UIView!
    @IBOutlet weak var ChooseLangugaeLabel: UILabel!
    @IBOutlet weak var defaultLanguageLabel: UILabel!
    @IBOutlet weak var doubleTapLabel: UILabel!
    @IBOutlet weak var formaImageView: UIImageView!
    @IBOutlet weak var selectSwitch: UISwitch! {
        didSet {
            selectSwitch.transform = CGAffineTransform(scaleX: 0.50, y: 0.50)
        }
    }
    @IBOutlet weak var switchMainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setCell(isArchive: Bool) {
        switchMainView.isHidden = !isArchive
        selectedImageMainView.isHidden = isArchive
    }
    
}

