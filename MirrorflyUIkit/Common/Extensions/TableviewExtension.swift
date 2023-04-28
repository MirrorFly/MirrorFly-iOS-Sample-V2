//
//  tableViewExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 18/09/21.
//

import UIKit

extension UITableView {
    func scrollToBottomRow() {
        DispatchQueue.main.async { [weak self] in
            guard let this = self else { return }
            guard this.numberOfSections > 0 else { return }
            
            // Make an attempt to use the bottom-most section with at least one row
            var section = max(this.numberOfSections - 1, 0)
            var row = max(this.numberOfRows(inSection: section) - 1, 0)
            var indexPath = IndexPath(row: row, section: section)
            
            // Ensure the index path is valid, otherwise use the section above (sections can
            // contain 0 rows which leads to an invalid index path)
            while !this.indexPathIsValid(indexPath) {
                section = max(section - 1, 0)
                row = max(this.numberOfRows(inSection: section) - 1, 0)
                indexPath = IndexPath(row: row, section: section)
                
                // If we're down to the last section, attempt to use the first row
                if indexPath.section == 0 {
                    indexPath = IndexPath(row: 0, section: 0)
                    break
                }
            }
            
            // In the case that [0, 0] is valid (perhaps no data source?), ensure we don't encounter an
            // exception here
            guard this.indexPathIsValid(indexPath) else { return }
            this.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        let row = indexPath.row
        return section < self.numberOfSections && row < self.numberOfRows(inSection: section)
    }
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width:  bounds.size.width, height: ( bounds.size.height/2)))
        messageLabel.text = message
        if #available(iOS 13.0, *) {
            messageLabel.textColor = .systemGray
        } else {
            messageLabel.textColor = .gray
        }
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        messageLabel.sizeToFit()
        backgroundView = messageLabel
    }
    
    func restore() {
        backgroundView = nil
    }
}


extension UITableView {
    
    func isLast(for indexPath: IndexPath) -> Bool {
        
        let indexOfLastSection = numberOfSections > 0 ? numberOfSections - 1 : 0
        let indexOfLastRowInLastSection = numberOfRows(inSection: indexOfLastSection) - 1
        
        return indexPath.section == indexOfLastSection && indexPath.row == indexOfLastRowInLastSection
    }
}



extension Dictionary {
    /// Merge and return a new dictionary
    func merge(with: Dictionary<Key,Value>) -> Dictionary<Key,Value> {
        var copy = self
        for (k, v) in with {
            // If a key is already present it will be overritten
            copy[k] = v
        }
        return copy
    }
    
    /// Merge in-place
    mutating func append(with: Dictionary<Key,Value>) {
        for (k, v) in with {
            // If a key is already present it will be overritten
            self[k] = v
        }
    }
}

extension UITableView {
    func indexPath(for view: UIView) -> IndexPath? {
        self.indexPathForRow(at: view.convert(.zero, to: self))
    }
}

extension UITableView {
    func reloadDataWithoutScroll() {
        DispatchQueue.main.async {
            let lastScrollOffset = self.contentOffset
            self.beginUpdates()
            self.reloadData()
            self.endUpdates()
            self.layer.removeAllAnimations()
            self.setContentOffset(lastScrollOffset, animated: false)
        }
    }
}

extension UITableView {
 
   func indexPathForView(_ view: UIView) -> IndexPath? {
       let center = view.center
       let viewCenter = self.convert(center, from: view.superview)
       let indexPath = self.indexPathForRow(at: viewCenter)
       return indexPath
   }
}

