//
//  DateExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 27/08/21.
//

import Foundation
extension Date {
    static func dateFromCustomString(customString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: customString) ?? Date()
    }
    
    func reduceToMonthDayYear() -> Date {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)
        let year = calendar.component(.year, from: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: "\(month)/\(day)/\(year)") ?? Date()
    }
    
    func toDate(withFormat format: String)-> Date?{
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Tehran")
            dateFormatter.locale = Locale(identifier: "fa-IR")
            dateFormatter.calendar = Calendar(identifier: .indian)
            dateFormatter.dateFormat = format
            let date = dateFormatter.date(from: format)
            return date
    }
    
    func getTimeFormat() -> String {
        let dateFormatter = DateFormatter()
        let locale = NSLocale.current
        let formatter : String = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:locale)!
        if formatter.contains("a") {
            //phone is set to 12 hours format
            dateFormatter.dateFormat = "hh:mm a"
        } else {
            //phone is set to 24 hours format
            dateFormatter.dateFormat = "HH:mm"
        }
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let formattedDate = dateFormatter.string(from: self)
        return formattedDate.lowercased()
    }
    
    func localDate() -> Date {
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: self))
        guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: self) else {return self}
        return localDate
    }
    
    func timeAgoDisplay() -> String {
 
        let secondsAgo = Int(Date().timeIntervalSince(self))

           let minute = 60
           let hour = 60 * minute
           let day = 24 * hour
           let week = 7 * day
           let month = 4 * week

           let quotient: Int
           let unit: String
           if secondsAgo < minute {
               quotient = secondsAgo
               unit = "second"
           } else if secondsAgo < hour {
               quotient = secondsAgo / minute
               unit = "mintues"
           } else if secondsAgo < day {
               quotient = secondsAgo / hour
               unit = "hour"
           } else if secondsAgo < week {
               quotient = secondsAgo / day
               unit = "day"
           } else if secondsAgo < month {
               quotient = secondsAgo / week
               unit = "week"
           } else {
               quotient = secondsAgo / month
               unit = "month"
           }
           return "\(quotient) \(unit)\(quotient == 1 ? "" : "s") ago"
    }
}
