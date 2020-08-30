//
//  NoteDateFomatter.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-22.
//

import Foundation
 
class NoteDateFomatter: DateFormatter {
    var preferedStyle: Style?
    let calender = Calendar.current
    override func string(from date: Date) -> String {
        var style = preferedStyle
        if style == nil {
            let styles = styleFromDate(from: date)
            styles.forEach {
                if let lastStyle = style {
                    if $0.rawValue < lastStyle.rawValue { style = $0 }
                } else {
                    style = $0
                }
            }
        }
        
        return stringFromStyle(style: style, date: date)
    }
    
    func stringFromStyle(style: Style?, date: Date) -> String {
        let compareCompoment = Calendar.current.dateComponents([.minute], from: date, to: Date())
        guard let style = style else {
            let dateFormater = DateFormatter()
            dateFormater.dateFormat = ~"date_full"
            return dateFormater.string(from: date)
        }
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = ~"date_time"
        
        let weekdayFormater = DateFormatter()
        weekdayFormater.dateFormat = ~"date_weekday"
        
        switch style {
        case .recently:
            return ~"date_recently"
        case .soon:
            return ~"date_soon"
        case .withinAnHourBefore:
            return l("date_minutes_ago", compareCompoment.minute ?? 0)
        case .withinAnHourAfter:
            return l("date_minutes_later", -(compareCompoment.minute ?? 0))
        case .today:
            return l("date_today", dateFormater.string(from: date))
        case .yesturday:
            return l("date_yesturday", dateFormater.string(from: date))
        case .tomorrow:
            return l("date_tomorrow", dateFormater.string(from: date))
        case .thisWeek:
            return l("date_this", weekdayFormater.string(from: date), dateFormater.string(from: date))
        case .lastWeek:
            return l("date_last", weekdayFormater.string(from: date), dateFormater.string(from: date))
        case .nextWeek:
            return l("date_next", weekdayFormater.string(from: date), dateFormater.string(from: date))
        case .thisYear:
            let dateFormater = DateFormatter()
            dateFormater.dateFormat = ~"date_month_day"
            return dateFormater.string(from: date)
        }
    }
    
    func styleFromDate(from date: Date) -> [Style] {
        var styles: [Style] = []
        let dateCompoment = calendar.dateComponents([.weekOfYear, .day, .month, .year], from: date)
        let nowCompoment = Calendar.current.dateComponents([.weekOfYear, .day, .month, .year], from: Date())
        let compareCompoment = Calendar.current.dateComponents([.minute], from: date, to: Date())
        
        if nowCompoment.year == dateCompoment.year {
            styles.append(.thisYear)
            
            if dateCompoment.weekOfYear == nowCompoment.weekOfYear {
                styles.append(.thisWeek)
            }
            
            if dateCompoment.day == nowCompoment.day, dateCompoment.month == nowCompoment.month {
                styles.append(.today)
            }
        }
        
        if let dateNextWeek = calender.date(byAdding: .day, value: 7, to: date) {
            let dateNextWeekCompoment = calendar.dateComponents([.weekOfYear, .year], from: dateNextWeek)
            
            if dateNextWeekCompoment.year == nowCompoment.year, dateNextWeekCompoment.weekOfYear == nowCompoment.weekOfYear {
                styles.append(.lastWeek)
            }
        }
        
        if let dateLastWeek = calender.date(byAdding: .day, value: -7, to: date) {
            let dateLastWeekCompoment = calendar.dateComponents([.weekOfYear, .year], from: dateLastWeek)
            
            if dateLastWeekCompoment.year == nowCompoment.year, dateLastWeekCompoment.weekOfYear == nowCompoment.weekOfYear {
                styles.append(.nextWeek)
            }
        }
        
        
        if let dateNextDay = calender.date(byAdding: .hour, value: 24, to: date) {
            let dateNextDayCompoment = calendar.dateComponents([.day, .month, .year], from: dateNextDay)
            
            if dateNextDayCompoment.year == nowCompoment.year, dateNextDayCompoment.month == nowCompoment.month, dateNextDayCompoment.day == nowCompoment.day {
                styles.append(.yesturday)
            }
        }
        
        if let dateLastDay = calender.date(byAdding: .hour, value: -24, to: date) {
            let dateLastDayCompoment = calendar.dateComponents([.day, .month, .year], from: dateLastDay)
            
            if dateLastDayCompoment.year == nowCompoment.year, dateLastDayCompoment.month == nowCompoment.month, dateLastDayCompoment.day == nowCompoment.day {
                styles.append(.tomorrow)
            }
        }
        
        if let minuteCompoment = compareCompoment.minute {
            if minuteCompoment < 60, minuteCompoment > 0 {
                styles.append(.withinAnHourBefore)
            }
            if minuteCompoment > -60, minuteCompoment <= 0 {
                styles.append(.withinAnHourAfter)
            }
            if minuteCompoment < 2, minuteCompoment >= 0 {
                styles.append(.recently)
            }
            if minuteCompoment > -2, minuteCompoment < 0 {
                styles.append(.soon)
            }
        }
        
        return styles
    }
}

extension NoteDateFomatter {
    enum Style: Int {
        case recently = 0
        case soon = 1
        case withinAnHourBefore = 2
        case withinAnHourAfter = 3
        case today = 4
        case yesturday = 5
        case tomorrow = 6
        case thisWeek = 7
        case lastWeek = 8
        case nextWeek = 9
        case thisYear = 10
    }
}
