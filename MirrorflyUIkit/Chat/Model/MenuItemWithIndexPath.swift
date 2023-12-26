//
//  MenuItemWithIndexPath.swift
//  MirrorflyUIkit
//
//  Created by User on 17/09/21.
//

import Foundation
import UIKit

class MenuItemWithIndexPath: UIMenuItem {
    var indexPath: IndexPath?
    
    init(title: String, action: Selector, indexPath: IndexPath) {
        super.init(title: title, action: action)
        self.indexPath = indexPath
    }
}
