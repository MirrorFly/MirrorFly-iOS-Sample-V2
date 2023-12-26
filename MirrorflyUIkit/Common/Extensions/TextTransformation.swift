//
//  TextTransformation.swift
//  MirrorflyUIkit
//
//  Created by User on 18/09/21.
//

import Foundation
import UIKit

extension String {
    
    func fetchMessageDateHeader(for lastMessageTime : Double) -> String {
        let calendar = Calendar.current
        let date =  DateFormatterUtility.shared.convertMillisecondsToLocalDate(milliSeconds: lastMessageTime)
        
        if calendar.isDateInToday(date) {
            return "TODAY".localized
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY".localized
        } else {
            let currentWeek = Calendar.current.component(Calendar.Component.weekOfYear, from: Date())
            let datesWeek = Calendar.current.component(Calendar.Component.weekOfYear, from: date)
            if currentWeek == datesWeek {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
                formatter.locale = Locale(identifier: "en_US")
                let strDate: String = formatter.string(from: date)
                return strDate.capitalized
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM, yyyy"
                formatter.locale = Locale(identifier: "en_US")
                let strDate: String = formatter.string(from: date)
                return strDate.capitalized
            }
        }
    }
    
    func fetchHeaderDateForViewAllMedia(for lastMessageTime : Double) -> String {
        let date =  DateFormatterUtility.shared.convertMillisecondsToLocalDate(milliSeconds: lastMessageTime)
        
        let currentMonth = Calendar.current.component(Calendar.Component.month, from: Date())
        let messageMonth = Calendar.current.component(Calendar.Component.month, from: date)
        if currentMonth == messageMonth {
            return "Recent"
        } else if (currentMonth - messageMonth) == 1 {
            return "Last Month"
        } else {
            let currentYear = Calendar.current.component(Calendar.Component.year, from: Date())
            let messageYear = Calendar.current.component(Calendar.Component.year, from: date)
            var formatString = "MMM, yyyy"
            if currentYear == messageYear {
                formatString = "MMMM"
            }
            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            formatter.locale = Locale(identifier: "en_US")
            let strDate: String = formatter.string(from: date)
            return strDate.capitalized
        }
    }
    
    func fetchMessageDateHeader(for date : Date) -> String {
        
        var secondsAgo = Int(Date().timeIntervalSince(date))
        if secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let twoDays = 2 * day
        let oneDay = 1 * day
        
        if secondsAgo < oneDay  {
            
            return "TODAY".localized
            
        } else if secondsAgo < twoDays {
            let day = secondsAgo/day
            if day == 1 {
                return "YESTERDAY".localized
            }else{
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
                formatter.locale = Locale(identifier: "en_US")
                let strDate: String = formatter.string(from: date)
                return strDate.uppercased()
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM, yyyy"
            formatter.locale = Locale(identifier: "en_US")
            let strDate: String = formatter.string(from: date)
            return strDate
        }
    }
    
    func fetchMessageDate(for lastMessageTime : Double) -> String {
        let date = DateFormatterUtility.shared.convertMillisecondsToLocalDate(milliSeconds: lastMessageTime)
        var secondsAgo = Int(Date().timeIntervalSince(date))
        if secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let weekDays = 7 * day
        let twoDays = 2 * day
        let oneDay = 1 * day
        
        if secondsAgo < oneDay  {
            let time = DateFormatterUtility.shared.convertMillisecondsToLocalTime(milliSeconds: lastMessageTime)
            return  time
            
        } else if secondsAgo < twoDays {
            let day = secondsAgo/day
            if day == 1 {
                return "YESTERDAY".localized
            }
        } else if secondsAgo < weekDays {
            let formatter = DateFormatter()
            formatter.dateFormat = "eee"
            formatter.locale = Locale(identifier: "en_US")
            let strDate: String = formatter.string(from: date)
            return strDate.capitalized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            formatter.locale = Locale(identifier: "en_US")
            let strDate: String = formatter.string(from: date)
            return strDate.capitalized
        }
        return ""
    }
}



