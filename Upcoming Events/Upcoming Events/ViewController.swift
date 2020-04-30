//
//  ViewController.swift
//  Upcoming Events
//
//  Created by Shannon Ma on 4/27/20.
//  Copyright © 2020 Shannon Ma. All rights reserved.
//

import UIKit

struct EventItem: Codable, Hashable{
    var title: String
    var start: Date
    var end: Date
    //Use a unique id to identify events
    let id: String = UUID().uuidString
    
    var startDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy h:mm a"
        return formatter.string(from: self.start)
    }
    
    var endDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy h:mm a"
        return formatter.string(from: self.end)
    }
    
    enum CodingKeys: String, CodingKey {
        case title, start, end
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var noEventLabel: UILabel!
    @IBOutlet weak var eventTableView: UITableView!
    
    var groupedEventDict = [Date : [EventItem]]()
    var sortedDateKeys =  [Date]()
    var conflictingEventsSet : Set<EventItem>  = []
    
    let shortDateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()
    
    let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy h:mm a"
        return formatter
    }()
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadDataForDisplay("mock")
    }

    func loadDataForDisplay(_ fileName: String){
        guard let path = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Can't find \(fileName).json file")
            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            var eventsData = parseJSON(data)
            if eventsData.count == 0{
                //No events
                self.eventTableView.isHidden = true
                self.noEventLabel.isHidden = false
            }else{
                self.eventTableView.isHidden = false
                self.noEventLabel.isHidden = true
                
                //Sort events by start date
                eventsData.sort(by: { $0.start < $1.start})
                
                //Group sorted Event by Date
                self.groupedEventDict = groupEventsData(eventsData)
                
                //Get a set of conflicting Event items
                self.conflictingEventsSet = getConflictingEventsSet(eventsData)
                
                //Sort Keys by Date Componenet, cloest to current date
                sortedDateKeys = groupedEventDict.keys.sorted(by: {$0 < $1})
                
                self.eventTableView.reloadData()
                
                //Scroll to current and upcoming date sections
                if let sectionIndex = sortedDateKeys.firstIndex(where: {$0.timeIntervalSinceNow > 0}) {
                    self.eventTableView.scrollToRow(at: IndexPath(row: 0, section: sectionIndex), at: .top, animated: false)
                }
            }
        }catch {
            print("Data content error:\(error)")
        }
    }
    
    func parseJSON(_ data: Data) -> [EventItem]{
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(longDateFormatter) //November 10, 2018 6:00 PM"
            //Decode json data to EventItem
            let events = try decoder.decode([EventItem].self, from: data)
            let validEvents = events.filter({$0.start <  $0.end})
            return validEvents
        } catch {
            print("JSON Decoding Error:\(error)")
            return []
        }
    }
    
    func groupEventsData(_ sortedEvents: [EventItem]) -> [Date: [EventItem]]{
        //Group events by Start Date
        let groupedDict = sortedEvents.reduce(into: [Date: [EventItem]]()) { result, event in
            // Sort events under the same date group by their start dates
            let components = Calendar.current.dateComponents([.day, .year, .month], from: event.start)
            let date = Calendar.current.date(from: components)
            result[date!, default: []].append(event)
        }
        return groupedDict
    }
    
    
    //Events need to be sorted by start time before check for conflicts
    //Return a set of conflicting event items
    func getConflictingEventsSet(_ sortedEvents: [EventItem]) -> Set<EventItem>{
        var conflictEvents : Set<EventItem> = []
        //If sortedEvent has 0 or only 1 event, return empty set
        if sortedEvents.count <= 1{
            return conflictEvents
        }
        //Start with first event item's time interval
        var intervalTaken: DateInterval =  DateInterval(start:sortedEvents[0].start, end: sortedEvents[0].end)
        //Starting compare with next event
        for i in 1...sortedEvents.count-1{
            
            let event = sortedEvents[i]
            if (intervalTaken.end > event.start)
            {
                //Found conflicting - get overlapping interval
                intervalTaken = DateInterval(start: intervalTaken.start, end: max(event.end, intervalTaken.end))
                let previousEvent = sortedEvents[i-1]
                
                //Insert conflicting events into Set (no duplicate)
                conflictEvents.insert(previousEvent)
                conflictEvents.insert(event)
            }else{
                //Not overlapping, start a new interval
                intervalTaken = DateInterval(start: event.start, end: event.end)
            }
        }
        return conflictEvents
    }

}

extension ViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let customView = UIView.init(frame: CGRect(x: 20, y: 0, width: 248, height: 44.0))
        customView.backgroundColor = .lightGray
    
        //Header title shows MMMdd, yyyy
        let headerTitleLabel = UILabel(frame: customView.frame)
        let dateKey = sortedDateKeys[section]
        headerTitleLabel.text = shortDateFormatter.string(from: dateKey)
        headerTitleLabel.textColor = .white
        headerTitleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        customView.addSubview(headerTitleLabel)
        return customView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
   
}

extension ViewController: UITableViewDataSource{
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = sortedDateKeys[section]
        if let values = groupedEventDict[key]{
            return values.count
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedDateKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .value1, reuseIdentifier: "EventCell")
        let key = sortedDateKeys[indexPath.section]
        if let values = groupedEventDict[key]{
            let eventForCell = values[indexPath.row]
            cell.textLabel?.text = eventForCell.title
            
            //Cell details label shows start and end time
            let startDate = eventForCell.start
            let endDate = eventForCell.end
            cell.detailTextLabel?.text = "\(timeFormatter.string(from: startDate)) - \(timeFormatter.string(from: endDate))"
           
            //Display overlapping event in red text
            let isOverlapping = self.conflictingEventsSet.contains(eventForCell)
            cell.detailTextLabel?.textColor = isOverlapping ? UIColor.red  : UIColor.darkGray
        }
        return cell
    }
}
