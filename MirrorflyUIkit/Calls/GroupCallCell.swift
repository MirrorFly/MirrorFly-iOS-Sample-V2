//
//  GroupCallCollectionViewCell.swift
//  GroupCallUI
//
//  Created by Vasanth Kumar on 19/05/21.
//

import UIKit
import WebRTC

class GroupCallCell: UICollectionViewCell {
    
    static let identifier = "GroupCallCell"
    
    @IBOutlet weak var contentVIew: UIView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var foreGroundView: UIView!
    @IBOutlet var statusLable: UILabel!
    @IBOutlet var audioIconImageView: UIImageView!
    @IBOutlet weak var callActionsView: UIView!
    @IBOutlet weak var videoBaseView: UIImageView!
    @IBOutlet weak var videoMuteImage: UIImageView!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        executeOnMainThread {
            for view in self.videoBaseView.subviews {
                view.frame = CGRect(x: 0, y: 0, width: self.videoBaseView.bounds.width, height: self.videoBaseView.bounds.height)
            }
        }
    }
}
