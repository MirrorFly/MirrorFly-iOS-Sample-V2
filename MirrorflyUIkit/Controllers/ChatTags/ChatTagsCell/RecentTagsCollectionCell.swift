//
//  RecentTagsCollectionCell.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 27/02/23.
//

import UIKit

class RecentTagsCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var borderView: UIView!
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        borderView.cornerRadius(radius: 6, width: 1.0, color: Color.borderColor ?? .gray)
//    }
    
    func setupCell(title: String, isSelected: Bool){
        
        titleLabel.text = title
        borderView.cornerRadius(radius: 6, width: 1.0, color: (isSelected ? Color.color_3276E2 : Color.borderColor) ?? .gray)
    }
}
