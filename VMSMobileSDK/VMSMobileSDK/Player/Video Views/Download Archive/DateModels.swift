

import Foundation

class Day {
    let date: Date
    let number: String
    var isSelected: Bool
    let isWithinDisplayedMonth: Bool
    var isToday: Bool
    var lessThanToday: Bool
    
    init(date: Date, number: String, isSelected: Bool, isWithinDisplayedMonth: Bool, isToday: Bool, lessThanToday: Bool) {
        self.date = date
        self.number = number
        self.isSelected = isSelected
        self.isWithinDisplayedMonth = isWithinDisplayedMonth
        self.isToday = isToday
        self.lessThanToday = lessThanToday
    }
}

struct MonthMetadata {
    let numberOfDays: Int
    let firstDay: Date
    let firstDayWeekday: Int
}

class ArchiveDay {
    let date: Date
    let number: String
    var isSelected: Bool
    let isWithinDisplayedMonth: Bool
    var isToday: Bool
    var enabled: Bool
    
    init(
        date: Date,
        number: String,
        isSelected: Bool,
        isWithinDisplayedMonth: Bool,
        isToday: Bool,
        enabled: Bool
    ) {
        self.date = date
        self.number = number
        self.isSelected = isSelected
        self.isWithinDisplayedMonth = isWithinDisplayedMonth
        self.isToday = isToday
        self.enabled = enabled
    }
}
