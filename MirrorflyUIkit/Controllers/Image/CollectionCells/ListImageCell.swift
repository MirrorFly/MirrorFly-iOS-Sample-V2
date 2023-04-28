//
//  ListImageCell.swift
//  MirrorflyUIkit
//
//  Created by User on 01/09/21.
//

import UIKit
class ListImageCell: UICollectionViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var cellImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    func setBorder() {
        cellView.layer.borderWidth = 1.5
        cellView.layer.borderColor = (Color.imageSelection)?.cgColor
        cellView.clipsToBounds = true
    }
    
    func removeBorder() {
        cellView.layer.borderWidth = 1.5
        cellView.layer.borderColor =  UIColor.clear.cgColor
        cellView.clipsToBounds = true
    }
}
