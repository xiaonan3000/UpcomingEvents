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
        //MixAll data has 6 events and one is invalid
        let data = Data(TestJSONData.mixAll.utf8)
        let events = self.eventUnitTest.parseJSON(data)
        XCTAssertEqual(events.count, 5)
        
        let firstEvent = events.first
        XCTAssertNotNil(firstEvent)
        XCTAssertEqual(firstEvent!.title, "Non-Conflict 1")
        XCTAssertEqual(firstEvent!.startDateString, "April 7, 2020 9:00 PM")
        XCTAssertEqual(firstEvent!.endDateString, "April 7, 2020 10:30 PM")
        
        let secondEvent = events[1]
        XCTAssertEqual(secondEvent.title, "Conflict 24hrs")
        XCTAssertEqual(secondEvent.startDateString, "May 21, 2020 12:00 PM")
        XCTAssertEqual(secondEvent.endDateString, "May 22, 2020 12:00 PM")
        
        let thirdEvent = events[2]
        XCTAssertEqual(thirdEvent.title, "Conflict 3")
        XCTAssertEqual(thirdEvent.startDateString, "May 22, 2020 10:00 AM")
        XCTAssertEqual(thirdEvent.endDateString, "May 22, 2020 12:00 PM")
        
        let fourthEvent = events[3]
        XCTAssertEqual(fourthEvent.title, "Identical Event")
        XCTAssertEqual(fourthEvent.startDateString, "June 6, 2020 5:00 PM")
        XCTAssertEqual(fourthEvent.endDateString, "June 6, 2020 10:00 PM")
        
        let lastEvent = events[4]
        XCTAssertEqual(lastEvent.title, "Identical Event")
        XCTAssertEqual(lastEvent.startDateString, "June 6, 2020 10:00 PM")
        XCTAssertEqual(secondEvent.endDateString, "June 6, 2020 10:00 PM")
    }
    
    func testLoadEmptyData(){
        let noData = Data(TestJSONData.EmptyData.utf8)
        let noEvents = self.eventUnitTest.parseJSON(noData)
        XCTAssertEqual(noEvents.count, 0)
    }
    
    func testLoadInvalidEvent(){
        let data = Data(TestJSONData.invalidDateEvent.utf8)
        let events = self.eventUnitTest.parseJSON(data)
        XCTAssertEqual(events.count, 0)
    }

    func testGroupEventsByDate(){
        let testEvents = makeTestEvents(TestJSONData.mixAll)
        let eventDict = self.eventUnitTest.groupEventsData(testEvents)
        XCTAssertEqual(eventDict.count, 4)
        let lastEvent = testEvents.last
        XCTAssertNotNil(lastEvent)
        XCTAssertEqual(lastEvent!.title, "Identical Event")
        XCTAssertEqual(lastEvent!.startDateString, "June 6, 2020 5:00 PM")
        XCTAssertEqual(lastEvent!.endDateString, "June 6, 2020 10:00 PM")
    }
    
    func testGroupIdenticalEvents(){
        let testEvents = makeTestEvents(TestJSONData.identicalPair)
        let eventDict = self.eventUnitTest.groupEventsData(testEvents)
        
        let formatter = eventUnitTest.shortDateFormatter
        let dateKey = formatter.date(from: "June 6, 2020")
        let events = eventDict[dateKey!]
        XCTAssertNotNil(events)
        XCTAssertEqual(events!.count, 2) //Two identical Items
    }
    
    func testGroupEventsOfInvalidData(){
        let testEvents = makeTestEvents(TestJSONData.invalidDateEvent)
        let eventDict = self.eventUnitTest.groupEventsData(testEvents)
        XCTAssertEqual(eventDict.count, 0)
    }
    
    func testCheckConflictInNonConflictingData() {
        let testEvents = makeTestEvents(TestJSONData.nonConflict)
        let conflictingSet = self.eventUnitTest.getConflictingEventsSet(testEvents)
        XCTAssertEqual(conflictingSet.count, 0)
        
    }
    
    func testCheckConflictEventInvalidData(){
        let testEvents = makeTestEvents(TestJSONData.EmptyData)
        let conflictingSet = self.eventUnitTest.getConflictingEventsSet(testEvents)
        XCTAssertEqual(conflictingSet.count, 0)
    }
    
    func testCheckConflictEvents(){
        let testEvents = makeTestEvents(TestJSONData.conflictingEvents)
        let conflictingSet = self.eventUnitTest.getConflictingEventsSet(testEvents)
        XCTAssertEqual(conflictingSet.count, 3)
        XCTAssertTrue(conflictingSet.contains{$0.title == "Conflict 1"})
        XCTAssertTrue(conflictingSet.contains{$0.title == "Conflict 2"})
        XCTAssertTrue(conflictingSet.contains{$0.title == "Conflict 3 Two Days"})
    }
    
    func testCheckConflictMixEvents(){
        let testEvents = makeTestEvents(TestJSONData.mixAll)
        let conflictingSet = self.eventUnitTest.getConflictingEventsSet(testEvents)
        XCTAssertEqual(conflictingSet.count, 4)
        XCTAssertTrue(conflictingSet.contains{$0.title == "Identical Event"})
        XCTAssertTrue(conflictingSet.contains{$0.title == "Conflict 24hrs"})
        XCTAssertFalse(conflictingSet.contains{$0.title == "Non-Conflict 1"})
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

fileprivate struct TestJSONData{
    //Empty JSON Data
    static let EmptyData = """
    [
        {
        }
    ]
    """
    //Four Non Conflict events
    static let nonConflict = """
    [
       {
          "title":"Non Conflict 1",
          "start":"April 10, 2020 6:00 PM",
          "end":"April 10, 2020 7:00 PM"
       },
       {
          "title":"Non Conflict 2",
          "start":"May 8, 2020 12:56 PM",
          "end":"May 8, 2020 1:30 PM"
       },
       {
          "title":"Non Conflict 3",
          "start":"November 7, 2020 12:00 PM",
          "end":"November 8, 2020 12:00 PM"
       },
       {
          "title":"Non Conflict 4",
          "start":"November 8, 2020 12:00 PM",
          "end":"November 9, 2020 12:30 AM"
       }
    ]
    """
    //Two identical Event
    static let identicalPair = """
    [
       {
          "title":"Identical Event",
          "start":"June 6, 2020 5:00 PM",
          "end":"June 6, 2020 10:00 PM"
       },
       {
          "title":"Identical Event",
          "start":"June 6, 2020 5:00 PM",
          "end":"June 6, 2020 10:00 PM"
       }
    ]
    """
    //Two invalid event
    static let invalidDateEvent = """
    [
      {
          "title":"Bad End Date",
          "start":"November 7, 2020 12:00 PM",
          "end":"November 7, 2018 2:30 PM"
      },
      {
          "title":"Same Start & End Date",
          "start":"November 2, 2020 12:00 PM",
          "end":"November 2, 2020 12:00 PM"
      }
    ]
    """
    //Three events conflicting
    static let conflictingEvents = """
       [
         {
             "title":"Conflict 1",
             "start":"May 1, 2020 12:00 PM",
             "end":"May 1, 2020 11:00 PM"
         },
         {
             "title":"Conflict 2",
             "start":"May 1, 2020 10:00 AM",
             "end":"May 1, 2020 1:00 PM"
         },
         {
            "title":"Conflict 3 Two Days",
            "start":"May 1, 2020 10:00 AM",
            "end":"May 2, 2020 10:00 PM"
         }
       ]
       """
    //One conflict pair, one non- conflict, one invalid, one pair identical
    static let mixAll = """
    [
      {
          "title":"Non-Conflict 1",
          "start":"April 7, 2020 9:00 PM",
          "end":"April 7, 2020 10:30 PM"
       },
       {
           "title":"Conflict 24hrs",
           "start":"May 21, 2020 12:00 PM",
           "end":"May 22, 2020 12:00 PM"
        },
        {
           "title":"Conflict 3",
           "start":"May 22, 2020 10:00 AM",
           "end":"May 22, 2020 12:00 PM"
        },
        {
           "title":"Invalid Date Event",
           "start":"November 7, 2021 12:00 PM",
           "end":"November 7, 2018 2:30 PM"
        },
        {
            "title":"Identical Event",
            "start":"June 6, 2020 5:00 PM",
            "end":"June 6, 2020 10:00 PM"
        },
        {
            "title":"Identical Event",
            "start":"June 6, 2020 5:00 PM",
            "end":"June 6, 2020 10:00 PM"
        }
    ]
    """
}

