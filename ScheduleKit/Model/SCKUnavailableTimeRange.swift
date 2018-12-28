/*
 *  SCKUnavailableTimeRange.swift
 *  ScheduleKit
 *
 *  Created:    Guillem Servera on 31/12/2014.
 *  Copyright:  © 2014-2019 Guillem Servera (https://github.com/gservera)
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

import Foundation

/// This type can be used to represent (and to make persistent copies of) a break or
/// unavailable time range within a day being represented by a subclass of @c
/// `SCKGridView`. These values are conform to the `Hashable` and `NSSecureCoding`
/// protocols.
@objcMembers public class SCKUnavailableTimeRange: NSObject, NSSecureCoding {

    public fileprivate(set) var weekday: Int
    public fileprivate(set) var startHour: Int
    public fileprivate(set) var startMinute: Int
    public fileprivate(set) var endHour: Int
    public fileprivate(set) var endMinute: Int

    /// Initializes a new `SCKUnavailableTimeRange` object representing a concrete
    /// time range within a day. Fails for ranges with negative duration.
    ///
    /// - parameter weekday:     A weekday index for `SCKWeekView` or -1 for 
    ///                          `SCKDayView`. Default is -1. Values are 0 based
    ///                          with 0 meaning the first displayed weekday (may
    ///                          very depending on the user's locale).
    /// - parameter startHour:   The time range's starting hour. Default is 0.
    /// - parameter startMinute: The time range's starting minute. Default is 0.
    /// - parameter endHour:     The time range's ending hour. Default is 0.
    /// - parameter endMinute:   The time range's ending minute. Default is 0.
    ///
    /// - returns: The initialized `SCKUnavailableTimeRange` struct.
    public init?(weekday: Int = -1, startHour: Int = 0, startMinute: Int = 0, endHour: Int = 0, endMinute: Int = 0) {
        let end = endHour * 3600 + endMinute * 60
        let start = startHour * 3600 + startMinute * 60
        guard TimeInterval(end - start) > 0 else {
            return nil
        }

        self.weekday = weekday
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }

    private var length: TimeInterval {
        let end = endHour * 3600 + endMinute * 60
        let start = startHour * 3600 + startMinute * 60
        return TimeInterval(end - start)
    }

    // MARK: Date interval transforming

    /// Calculates all the date intervals that match the unavailable time range in
    /// a greater date interval.
    ///
    /// - Parameter dateInterval: The testing boundaries.
    /// - Returns: An array of date intervals matching the defined range.
    @available(OSX 10.12, *)
    public func matchingOccurrences(in dateInterval: DateInterval) -> [DateInterval] {
        var intervals: [DateInterval] = []

        var unavailableRangeComponents = DateComponents()
        unavailableRangeComponents.hour = startHour
        unavailableRangeComponents.minute = startMinute
        if weekday != -1 {
            var convertedWeekday = weekday + sharedCalendar.firstWeekday + 7
            while convertedWeekday > 7 {
                convertedWeekday -= 7
            }
            unavailableRangeComponents.weekday = convertedWeekday
        }
        let length = self.length
        let safetyOffset = dateInterval.start.addingTimeInterval(-length+1)
        sharedCalendar.enumerateDates(startingAfter: safetyOffset,
                                      matching: unavailableRangeComponents,
                                      matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date, date < dateInterval.end else {
                stop = true
                return
            }
            intervals.append(DateInterval(start: date, duration: length))
        }
        return intervals
    }
    
    
    /// Calculates all the date intervals that match the unavailable time range in
    /// a greater date interval.
    ///
    /// - Parameter startDate: The testing start date.
    /// - Parameter endDate: The testing end date.
    /// - Returns: An array of date intervals matching the defined range.
    @available(OSX, deprecated: 10.12, message: "_DateInterval is unavailable in macOS 10.12, use native DateInterval instead.")
    public func matchingOccurrences(between startDate: Date, and endDate: Date) -> [_DateInterval] {
        var intervals: [_DateInterval] = []
        
        var unavailableRangeComponents = DateComponents()
        unavailableRangeComponents.hour = startHour
        unavailableRangeComponents.minute = startMinute
        if weekday != -1 {
            var convertedWeekday = weekday + sharedCalendar.firstWeekday + 7
            while convertedWeekday > 7 {
                convertedWeekday -= 7
            }
            unavailableRangeComponents.weekday = convertedWeekday
        }
        let length = self.length
        let safetyOffset = startDate.addingTimeInterval(-length+1)
        sharedCalendar.enumerateDates(startingAfter: safetyOffset,
                                      matching: unavailableRangeComponents,
                                      matchingPolicy: .nextTime) { date, _, stop in
                                        guard let date = date, date < endDate else {
                                            stop = true
                                            return
                                        }
                                        intervals.append(_DateInterval(start: date, duration: length))
        }
        return intervals
    }

    // MARK: - Equatable and hashable

    public override var hash: Int {
        return weekday.hashValue ^ startHour.hashValue ^ startMinute.hashValue ^ endHour.hashValue ^ endMinute.hashValue
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let obj = object as? SCKUnavailableTimeRange else {
            return false
        }
        return (self.weekday == obj.weekday
            && self.startHour == obj.startHour && self.startMinute == obj.startMinute
            && self.endHour == obj.endHour && self.endMinute == obj.endMinute)
    }

    // MARK: - NSSecureCoding

    private static let weekdayKey     = "BreakWeekday"
    private static let startHourKey   = "BreakSH"
    private static let startMinuteKey = "BreakSM"
    private static let endHourKey     = "BreakEH"
    private static let endMinuteKey   = "BreakEM"

    public static var supportsSecureCoding: Bool {
        return true
    }

    public required init?(coder aDecoder: NSCoder) {
        weekday     = aDecoder.decodeInteger(forKey: SCKUnavailableTimeRange.weekdayKey)
        startHour   = aDecoder.decodeInteger(forKey: SCKUnavailableTimeRange.startHourKey)
        startMinute = aDecoder.decodeInteger(forKey: SCKUnavailableTimeRange.startMinuteKey)
        endHour     = aDecoder.decodeInteger(forKey: SCKUnavailableTimeRange.endHourKey)
        endMinute   = aDecoder.decodeInteger(forKey: SCKUnavailableTimeRange.endMinuteKey)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(weekday, forKey: SCKUnavailableTimeRange.weekdayKey)
        aCoder.encode(startHour, forKey: SCKUnavailableTimeRange.startHourKey)
        aCoder.encode(startMinute, forKey: SCKUnavailableTimeRange.startMinuteKey)
        aCoder.encode(endHour, forKey: SCKUnavailableTimeRange.endHourKey)
        aCoder.encode(endMinute, forKey: SCKUnavailableTimeRange.endMinuteKey)
    }
}
