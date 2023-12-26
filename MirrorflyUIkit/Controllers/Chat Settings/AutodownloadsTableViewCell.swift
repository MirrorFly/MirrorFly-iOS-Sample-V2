//
//  AutodownloadsTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by Ramakrishnan on 01/11/22.
//

import UIKit

class AutodownloadsTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    @IBOutlet weak var viewoutlet: UIView!
    @IBOutlet weak var labeltitle: UILabel!
    @IBOutlet weak var selectedImageoutlet: UIImageView!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
    }

}
