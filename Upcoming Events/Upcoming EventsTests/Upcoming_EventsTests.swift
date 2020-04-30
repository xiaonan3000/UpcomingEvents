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

    override func setUp() {
        eventUnitTest = UIStoryboard(name: "Main", bundle: nil)
        .instantiateInitialViewController() as? ViewController
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadJsonDataToEventItems() {
        let data = Data(recentDayData.utf8)
        let events = self.eventUnitTest.parseJSON(data)
        XCTAssertEqual(events.count, 4)
        
        let firstEvent = events.first
        XCTAssertNotNil(firstEvent)
        XCTAssertEqual(firstEvent!.title, "TEST DATA 1")
        
        let formatter = eventUnitTest.longDateFormatter
        XCTAssertEqual(formatter.string(from: firstEvent!.start), "April 10, 2020 6:00 PM")
        XCTAssertEqual(formatter.string(from: firstEvent!.end), "April 10, 2020 7:00 PM")
    }
    
    func testLoadInvalidData(){
        let noData = Data("".utf8)
        let noEvents = self.eventUnitTest.parseJSON(noData)
        XCTAssertEqual(noEvents.count, 0)
        
        let data = Data(invalidItems.utf8) //Three event with only one valid
        let events = self.eventUnitTest.parseJSON(data)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first!.title, "Valid Event")
    }

    func testGroupEventsByDate(){
        let testEvents = makeTestEvents(repeatingItems)
        let eventDict = self.eventUnitTest.groupEventsData(testEvents)
        XCTAssertEqual(eventDict.count, 3)
    }
    
    func testGroupRepeatingEvents(){
        let testEvents = makeTestEvents(repeatingItems)
        let eventDict = self.eventUnitTest.groupEventsData(testEvents)
        
        let formatter = eventUnitTest.shortDateFormatter
        let dateKey = formatter.date(from: "June 6, 2021")
        let events = eventDict[dateKey!]
        XCTAssertNotNil(events)
        XCTAssertEqual(events!.count, 2) //Two Repeating Items
    }
    
    func testCheckConflictingEvent() {
        let testEvents = makeTestEvents(repeatingItems)
        let conflictingSet = self.eventUnitTest.getConflictingEventsSet(testEvents)
        XCTAssertEqual(conflictingSet.count, 2)
      
        XCTAssertTrue(conflictingSet.contains{$0.title == "Repeating Event"})
        XCTAssertFalse(conflictingSet.contains{$0.title == "Non-conflict 5"})
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
}

private let recentDayData = """
[
   {
      "title":"TEST DATA 1",
      "start":"April 10, 2020 6:00 PM",
      "end":"April 10, 2020 7:00 PM"
   },
   {
      "title":"TEST DATA 2",
      "start":"May 8, 2020 12:56 PM",
      "end":"May 8, 2020 1:30 PM"
   },
   {
      "title":"24hrs Event",
      "start":"November 7, 2020 12:00 PM",
      "end":"November 8, 2020 12:00 PM"
   },
   {
      "title":"Full Day Event",
      "start":"November 8, 2020 12:00 PM",
      "end":"November 9, 2020 12:30 AM"
   }
]
"""
private let repeatingItems = """
[
   {
      "title":"Conflict Event 1",
      "start":"May 10, 2019 6:00 PM",
      "end":"May 10, 2019 7:00 PM"
   },
   {
      "title":"Conflict Event 2",
      "start":"May 8, 2019 12:56 PM",
      "end":"May 8, 2019 1:30 PM"
   },
   {
      "title":"Repeating Event",
      "start":"June 6, 2021 5:00 PM",
      "end":"June 6, 2021 10:00 PM"
   },
   {
      "title":"Repeating Event",
      "start":"June 6, 2021 5:00 PM",
      "end":"June 6, 2021 10:00 PM"
   }
]
"""

private let invalidItems = """
[
  {
      "title":"Bad End Date",
      "start":"November 7, 2021 12:00 PM",
      "end":"November 7, 2018 2:30 PM"
  },
  {
      "title":"Valid Event",
      "start":"November 1, 2018 12:00 PM",
      "end":"November 1, 2018 2:30 PM"
  },
  {
      "title":"Same Start & End Date",
      "start":"November 2, 2020 12:00 PM",
      "end":"November 2, 2020 12:00 PM"
  }
]
"""
