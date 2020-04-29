//
//  EventItem.swift
//  Upcoming Events
//
//  Created by Shannon Ma on 4/27/20.
//  Copyright © 2020 Shannon Ma. All rights reserved.
//

import UIKit

class EventItem: Codable{
   
    var title: String
    var start: Date
    var end: Date
    
//    var startDate: Date? {
//        return dateFormatter.date(from: start)
//    }
//
//    var endDate: Date?{
//        return dateFormatter.date(from: end)
//    }
    
//    init(_ title: String, startDate: String, endDate:String) {
//        self.title = title
//        self.start = startDate
//        self.end = endDate
//    }
//{"title": "Nap Break", "start": "November 8, 2018 12:56 PM", "end": "November 8, 2018 1:30 PM"},
//    enum CodingKeys: String, CodingKey {
//        case title = "title"
//        case start = "start"
//        case end = "end"
//        
//    }
}
