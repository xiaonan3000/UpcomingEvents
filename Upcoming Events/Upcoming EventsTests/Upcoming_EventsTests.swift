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
        let fileName = "testEvents"
        
        let events = self.eventUnitTest.parseJSON(fileName)
       
        XCTAssertEqual(events.count, 5)
        
        let firstEvent = events.first
        XCTAssertNotNil(firstEvent)
        XCTAssertEqual(firstEvent!.title, "TEST DATA 1")
        
        let formatter = eventUnitTest.longDateFormatter
        XCTAssertEqual(formatter.string(from: firstEvent!.start), "November 10, 2018 6:00 PM")
        XCTAssertEqual(formatter.string(from: firstEvent!.end), "November 10, 2018 7:00 PM")

    }

    func testGroupEventsByDate(){
        var testEvents = makeTestEvents()
        testEvents.sort(by: {$0.start < $1.start})
        let events = self.eventUnitTest.groupEventsData(testEvents)
        XCTAssertEqual(events.count, 3)
    }
    
    func testCheckConflictingEvent() {
        var testEvents = makeTestEvents()
        testEvents.sort(by: {$0.start < $1.start})
        let conflictingSet = self.eventUnitTest.getConflictingEventsSet(testEvents)
        XCTAssertEqual(conflictingSet.count, 4)
    }
}

extension Upcoming_EventsTests {
    func makeTestEvents() -> [EventItem] {
        var testEvents = [EventItem]()
        
        let currentDate = Date()
        let nextDay = currentDate.addingTimeInterval(3600*24)
        let thirdDay = currentDate.addingTimeInterval(3600*48)
        
        //First two events conflicting each other
        let event1 = EventItem(title: "Event 1 conflicting Event 2 ", start: currentDate, end: currentDate.addingTimeInterval(3600*12))
        testEvents.append(event1)
        let event2 = EventItem(title: "Event 2", start: currentDate, end: currentDate.addingTimeInterval(3600*2))
        testEvents.append(event2)
        
        //Second pair of events has identical title, start and end date
        let startDate = currentDate.addingTimeInterval(3600*12)
        let endDate = startDate.addingTimeInterval(3600*1)
        let event3 = EventItem(title: "Test Identical Title and Date Conflicting Item", start: startDate, end: endDate)
        testEvents.append(event3)
        let event4 = EventItem(title: "Test Identical Title and DateConflicting Item", start: startDate, end: endDate)
        testEvents.append(event4)
        
        //Last two events is not conflicting
        let event5 = EventItem(title: "Non Conflicting Event 5", start: nextDay, end: nextDay.addingTimeInterval(3600*1))
        testEvents.append(event5)
        let event6 = EventItem(title: "Non Conflicting Event 6", start: thirdDay.addingTimeInterval(3600*12), end: thirdDay.addingTimeInterval(3600*14))
        testEvents.append(event6)
        
        return testEvents
    }
}
