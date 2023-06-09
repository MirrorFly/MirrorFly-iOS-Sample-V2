//
//  DateFormatterUtility.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 19/11/21.
//

import Foundation

class DateFormatterUtility: NSObject {
    
    //Singleton class
    static let shared = DateFormatterUtility()
    
     func currentMillisecondsToLocalTime(milliSec: Double) -> String{
        let dateVar = Date.init(timeIntervalSince1970: milliSec/1000000)
        let dateFormatter = DateFormatter()
         
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = chatTimeFormat
        return dateFormatter.string(from: dateVar)
    }
    
    func milliSecondsToMessageInfoDateFormat(milliSec: Double) -> String {
        let dateVar = Date.init(timeIntervalSince1970: milliSec/1000000)
        let dateFormatter = DateFormatter()
         
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "dd MMM, hh:mm a"
        dateFormatter.amSymbol = "am"
        dateFormatter.pmSymbol = "pm"
        return dateFormatter.string(from: dateVar)
    }
    
    func currentMillisecondsToLocalDateAndTime(milliSec: Double) -> Date{
        let dateVar = Date.init(timeIntervalSince1970: milliSec/1000000)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let strDate = dateFormatter.string(from: dateVar)
        
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        return  dateFormatter.date(from: strDate) ?? Date()
    }
    
    func currentMillisecondsToUTCDateAndTime(milliSec: Double) -> Date{
        let dateVar = Date.init(timeIntervalSince1970: milliSec/1000000)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let strDate = dateFormatter.string(from: dateVar)
        dateFormatter.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        return  dateFormatter.date(from: strDate) ?? Date()
    }
    
    func convertMillisecondsToLocalDate(milliSeconds: Double)  -> Date {
        let date = Date(timeIntervalSince1970:  milliSeconds/1000000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        let strDate = dateFormatter.string(from: date)
//        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        guard let str = dateFormatter.date(from: strDate) else {
            return Date()
        }
        return str
    }
    
    func convertMillisecondsToLocalTime(milliSeconds: Double)  -> String {
        let date = Date(timeIntervalSince1970: milliSeconds/1000000)
        return utcToLocal(date: date)
    }
    
    func utcToLocal(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.timeZone = TimeZone.current
        let formatter : String = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:NSLocale.current)!
        if formatter.contains("a") {
            //phone is set to 12 hours format
            dateFormatter.dateFormat = "hh:mm a"
        } else {
            //phone is set to 24 hours format
            dateFormatter.dateFormat = "HH:mm"
        }
        return dateFormatter.string(from: date)
    }
    
    func convertToMilliseconds(milliSeconds: Double)  -> String {
        let date = Date(timeIntervalSince1970: milliSeconds/1000000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        dateFormatter.locale = NSLocale.current
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    
        let formatter : String = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:NSLocale.current)!
        if formatter.contains("a") {
            //phone is set to 12 hours format
            dateFormatter.dateFormat = "hh:mm a"
        } else {
            //phone is set to 24 hours format
            dateFormatter.dateFormat = "HH:mm"
        }
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone.current
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate.lowercased()
    }
    
    
    func convertMillisecondsdToTime(milliSeconds: Double)  -> Date {
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: (Double(timeStamp) / 1000.0))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        guard let str = utcToLocalTime(dateStr:dateFormatter.string(from: date2)) else {
            return Date()
        }
        return dateFormatter.date(from: str) ?? Date()
        
    }
    
    func getCurrentTimeSeconds() -> Double {
        let date = Date()
        let calendar = Calendar.current
        let second = calendar.component(.second, from: date)
        return Double(second)
    }

    func getTimeSeconds(millSeconds : Double) -> Double {
        let calendar = Calendar.current
        let second = calendar.component(.second, from: millSeconds.dateFromMilliseconds())
        return Double(second)
    }
    
    func getTimeFormatWithoutLowerCase(date: Date) -> String {
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
        dateFormatter.timeZone = TimeZone.current
       // dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate
    }
    
    func getTimeFormat(date: Date) -> String {
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
        dateFormatter.timeZone = TimeZone.current
       // dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate.lowercased()
    }
    
    
    func convertMillisecondsToDateTime(milliSeconds: Double)  -> Date {
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: (Double(timeStamp) / 1000.0))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        guard let str = utcToLocal(dateStr:dateFormatter.string(from: date2)) else {
            return Date()
        }
        return dateFormatter.date(from: str) ?? Date()
    }
    
    func convertMillisecondsToDateTimeWithSeconds(milliSeconds: Double)  -> String {
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: (Double(timeStamp) / 1000.0))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return dateFormatter.string(from: date2)
    }
    
    func getGroupMilliSeconds(milliSeconds : Double) -> Double {
        var sec = "\(milliSeconds)"
        var milli = milliSeconds
        if sec.contains(".") && sec.count == 15 {
            let index = sec.firstIndex(of: ".")!
            sec.insert(contentsOf: "000", at: index)
            milli = Double(sec) ?? milli
            return milli
        }
        return milliSeconds
    }
    
    func convertGroupMillisecondsToDateTime(milliSeconds: Double)  -> Date {
        let milli = getGroupMilliSeconds(milliSeconds: milliSeconds)
        let timeStamp = milli / 1000
        let date2 = Date(timeIntervalSince1970: (Double(timeStamp) / 1000.0))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-DD"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        guard let str = groupUtcToLocal(dateStr:dateFormatter.string(from: date2)) else {
            return Date()
        }
        return dateFormatter.date(from: str) ?? Date()
    }
    
    func groupUtcToLocal(dateStr: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-DD"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = dateFormatter.date(from: dateStr) {
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.string(from: date)
        }
        return nil
    }
    
    func convertMillisecondsToTime(milliSeconds: Double)  -> Date {
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: (Double(timeStamp) / 1000.0))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        guard let str = utcToLocalTime(dateStr:dateFormatter.string(from: date2)) else {
            return Date()
        }
        return dateFormatter.date(from: str) ?? Date()
        
    }
    
    func utcToLocalTime(dateStr: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = dateFormatter.date(from: dateStr) {
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.string(from: date)
        }
        return nil
    }
    
    func utcToLocal(dateStr: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = dateFormatter.date(from: dateStr) {
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.string(from: date)
        }
        return nil
    }
    
    func convertMillisecondsToWebLoginTime(milliSeconds: Double)  -> String {
        // Date
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: Double(timeStamp/1000))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let time = convertMillisecondsToTime(milliSeconds: milliSeconds).getTimeFormat()
 
        return  dateFormatter.string(from: date2) + " " + time
    }
    
    func convertMillisecondsToSentTime(milliSeconds: Double)  -> String {
        // Date
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: Double(timeStamp/1000))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let time = convertMillisecondsToTime(milliSeconds: milliSeconds).getTimeFormat()
 
        return  dateFormatter.string(from: date2)
    }
    
    func convertTimeToDate(millSec: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let item = millSec.dateFromMilliseconds().getTimeFormat()
        let date = dateFormatter.date(from: item)
        print("Start: \(date)")
        return date?.getTimeFormat() ?? ""
    }
    
    func convertGroupMillisecondsToLocalDate(milliSeconds: Double)  -> Date {
        let milli = getGroupMilliSeconds(milliSeconds: milliSeconds)
        let date = Date(timeIntervalSince1970: milli/1000000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let strDate = dateFormatter.string(from: date)
        
        dateFormatter.timeZone = TimeZone.current
        guard let str = dateFormatter.date(from: strDate) else {
            return Date()
        }
        return str
    }
    
    func convertMilliSecondsToDocumentDate(milliSeconds: Double) -> String {
        let dateVar = Date.init(timeIntervalSince1970: milliSeconds/1000000)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "dd/MM/yy"
        return  dateFormatter.string(from: dateVar)
    }
    
}

extension Double {
    func dateFromMilliseconds() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self)/1000)
    }
}

extension Date {
    func isTodayDate() -> Bool {
        return NSCalendar.current.isDateInToday(self)
    }
}

