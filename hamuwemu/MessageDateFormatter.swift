//
//  MessageDateFormatter.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-17.
//

import Foundation

struct MessageDateFormatter {
    public static let shared = MessageDateFormatter()
    
    public let iso8601FormatterWithMilliseconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private let iso8601FormatterWithoutMilliseconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions =  [.withInternetDateTime]
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EdMMM", options: 0, locale: .current)
        //        formatter.timeStyle = .short
        return formatter
    }()
    
    let messageTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        //                    formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Initializer
    
    private init() {}
    
    public func string(from date: Date) -> String {
        configureDateFormatter(for: date)
        return dateFormatter.string(from: date)
    }
    
    // *****************************************
    // MARK: - ISO8601 helper
    // *****************************************
    func getDateFrom(DateString8601 dateString:String) -> Date?
    {
        if let date = iso8601FormatterWithMilliseconds.date(from: dateString)  {
            return date
        }
        if let date = iso8601FormatterWithoutMilliseconds.date(from: dateString)  {
            return date
        }
        return nil
    }
    
    func configureDateFormatter(for date: Date) {
        switch true {
        case Calendar.current.isDateInToday(date) || Calendar.current.isDateInYesterday(date):
            dateFormatter.doesRelativeDateFormatting = true
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
        case Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear):
            dateFormatter.dateFormat = "EEEE"
        case Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year):
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EdMMM", options: 0, locale: .current)
        default:
            dateFormatter.dateFormat = "MMM d, yyyy"
        }
    }
    
    func removeTimeStamp(fromDate: Date) -> Date {
        guard let date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: fromDate)) else {
            fatalError("Failed to strip time from Date object")
        }
        return date
    }
}
