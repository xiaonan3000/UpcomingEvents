//
//  Upcoming_EventsTests.swift
//  Upcoming EventsTests
//
//  Created by Shannon Ma on 4/29/20.
//  Copyright © 2020 Shannon Ma. All rights reserved.
//

import XCTest
@testable import Upcoming_Events

class Upcoming_EventsTests: XCTestCase {
    var eventUnitTest: ViewController!
    
    private let containRepeatingItems = """
[{"title": "Conflict Event 1", "start": "November 10, 2018 6:00 PM", "end": "November 10, 2018 7:00 PM"}, {"title": "Conflict Event 2", "start": "November 8, 2018 12:56 PM", "end": "November 8, 2018 1:30 PM"}, {"title": "Repeating Event", "start": "November 6, 2018 5:00 PM", "end": "November 6, 2018 10:00 PM"}, {"title": "Repeating Event", "start": "November 6, 2018 5:00 PM", "end": "November 6, 2018 10:00 PM"}, {"title": "Same Interval 5", "start": "November 7, 2018 12:00 PM", "end": "November 7, 2018 2:30 PM"}, {"title": "Same Interval 6", "start": "November 7, 2018 12:00 PM", "end": "November 7, 2018 2:30 PM"},{"title": "Non-conflict 7", "start": "November 1, 2018 12:00 PM", "end": "November 1, 2018 2:30 PM"},{"title": "Non conflict 8", "start": "November 2, 2018 12:00 PM", "end": "November 3, 2018 1:00 AM"}]
"""
     private let containInvalidItems = """
    [{"title": "Bad End Date", "start": "November 7, 2021 12:00 PM", "end": "November 7, 2018 2:30 PM"},{"title": "DATA no conflict", "start": "November 1, 2018 12:00 PM", "end": "November 1, 2018 2:30 PM"},{"title": "Smae Start & End Date", "start": "November 2, 2020 12:00 PM", "end": "November 2, 2020 12:00 PM"}]
    """
      
    
    override func setUp() {
        eventUnitTest = UIStoryboard(name: "Main", bundle: nil)
        .instantiateInitialViewController() as? ViewController
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadJsonDataToEventItems() {
        let data = Data(containRepeatingItems.utf8)
    
        let events = self.eventUnitTest.parseJSON(data)
        XCTAssertEqual(events.count, 8)
        
        let firstEvent = events.first
        XCTAssertNotNil(firstEvent)
        XCTAssertEqual(firstEvent!.title, "Conflict Event 1")
        
        let formatter = eventUnitTest.longDateFormatter
        XCTAssertEqual(formatter.string(from: firstEvent!.start), "November 10, 2018 6:00 PM")
        XCTAssertEqual(formatter.string(from: firstEvent!.end), "November 10, 2018 7:00 PM")
        
        let emptyData = Data("Bad Data Content".utf8)
        let emptyEvent = self.eventUnitTest.parseJSON(emptyData)
        XCTAssertEqual(emptyEvent.count, 0)
    }

    func testGroupEventsByDate(){
        let testEvents = makeTestEvents(containRepeatingItems)
        let eventDict = self.eventUnitTest.groupEventsData(testEvents)
        XCTAssertEqual(eventDict.count, 6)
        
        let dateKey = longDateForSting("November 6, 2018 5:00 PM") ?? Date()
        let events = eventDict[dateKey]
        XCTAssertNotNil(events)
        XCTAssertEqual(events!.count, 2) //Identical items
    }
    
    func testCheckConflictingEvent() {
        let testEvents = makeTestEvents(containRepeatingItems)
        let conflictingSet = self.eventUnitTest.getConflictingEventsSet(testEvents)
        XCTAssertEqual(conflictingSet.count, 4)
      
        let repeatingEvents = conflictingSet.filter{$0.title == "Repeating Event"}
        XCTAssertEqual(repeatingEvents.count, 2)
        
        let nonConflictEvents = conflictingSet.filter{$0.title == "Non-conflict 7"}
       XCTAssertEqual(nonConflictEvents.count, 0)
    }
}

extension Upcoming_EventsTests {
   
    func makeTestEvents(_ jsonString: String) -> [EventItem] {
        let data = Data(jsonString.utf8)
        let events = self.eventUnitTest.parseJSON(data)
        //Validate events data
        var validEvents = events.filter({$0.start <=  $0.end})
        //Sort events by start date
        validEvents.sort(by: { $0.start < $1.start})
        return validEvents
    }
    
    func longDateForSting(_ input: String)->Date?{
        let formatter = eventUnitTest.longDateFormatter
        return formatter.date(from: input)
    }
}
