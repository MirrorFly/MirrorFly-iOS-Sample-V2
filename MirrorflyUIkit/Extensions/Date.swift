//
//  Date.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 11/11/21.
//

import Foundation

extension Date {
    func getTimeFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let formattedDate = formatter.string(from: self)
        return formattedDate
    }
}
