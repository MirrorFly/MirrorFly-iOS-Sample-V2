//
//  MediaCell.swift
//  MirrorflyUIkit
//
//  Created by John on 01/11/22.
//

import UIKit

class MediaCell: UICollectionViewCell {

    @IBOutlet weak var playIcon: UIImageView!
    @IBOutlet weak var mediaImage: UIImageView!
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var centerAudioIconView: UIView!
    @IBOutlet weak var centerAudioIcon: UIImageView!
    @IBOutlet weak var audioDuration: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        centerAudioIconView.layer.cornerRadius = 22.5
    }

}
