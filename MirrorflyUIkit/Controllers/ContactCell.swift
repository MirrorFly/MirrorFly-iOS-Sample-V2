//
//  ContactCell.swift
//  MirrorflyUIkit
//
//  Created by User on 28/08/21.
//

import UIKit
import MirrorFlySDK
import SDWebImage

class ContactCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    func setupUI() {
        profile.layer.cornerRadius = 27.5
        profile.clipsToBounds = true
        profileView.layer.cornerRadius = 27.5
        profileView.clipsToBounds = true
        name.font = UIFont.font14px_appSemibold()
        status.font = UIFont.font12px_appRegular()
    }
    
    // MARK: SetTextColor whileSearch
    func setTextColorWhileSearch(searchText: String,profile: ProfileDetails) {
        let profileName =  getUserName(jid : profile.jid ,name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
        if let range = profileName.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive])  {
            let convertedRange = NSRange(range, in: profileName.capitalized)
            let attributedString = NSMutableAttributedString(string: profileName.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
            name?.attributedText = attributedString
        } else {
            name?.text = profileName.capitalized
            name?.textColor = Color.userNameTextColor
        }
        
        if let range = profile.status.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]), ENABLE_CONTACT_SYNC  {
            let convertedRange = NSRange(range, in: profile.status.capitalized)
            let attributedString = NSMutableAttributedString(string: profile.status.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
            status?.attributedText = attributedString
        } else {
            status?.text = profile.status.capitalized
            status?.textColor = Color.userStatusTextColor
        }
    }
    
    func setLastContentTextColor(searchText: String,profile: ProfileDetails) {
        if let range = profile.status.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]), ENABLE_CONTACT_SYNC  {
            let convertedRange = NSRange(range, in: profile.status.capitalized)
            let attributedString = NSMutableAttributedString(string: profile.status.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
            if profile.isBlockedMe {
                status?.text = ""
            } else {
                status?.attributedText = attributedString
            }
        } else {
            status?.text = profile.isBlockedMe ? "" : profile.status
            status?.textColor = Color.userStatusTextColor
        }
    }
        
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setImage(imageURL: String, name: String, color: UIColor) {
        let urlString = ChatManager.getImageUrl(imageName: imageURL)
        let url = URL(string: urlString)
        profile.sd_setImage(with: url, placeholderImage: getPlaceholder(name: name, color: color))
    }
    
    func getPlaceholder(name: String , color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(profile.frame.size.height), font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
}
