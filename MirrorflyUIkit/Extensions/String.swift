//
//  String.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 09/11/21.
//

import Foundation
import UIKit

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
    
    func toDate(withFormat format: String)-> Date?{
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Tehran")
            dateFormatter.locale = Locale(identifier: "fa-IR")
            dateFormatter.calendar = Calendar(identifier: .indian)
            dateFormatter.dateFormat = format
            let date = dateFormatter.date(from: self)
            return date
        }
}

