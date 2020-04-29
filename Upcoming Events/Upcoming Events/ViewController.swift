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
    var createdDate = Date()
    
    enum CodingKeys: String, CodingKey {
        case title, start, end
    }
}

class ViewController: UIViewController {

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
        formatter.dateFormat = "MMMM dd, yyyy h:mm a"
        return formatter
    }()
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
   
 
    
    @IBOutlet weak var noEventLabel: UILabel!
    @IBOutlet weak var eventTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadDataForDisplay()
    }

    func loadDataForDisplay(){
        let eventsData = parseDataToEvents("mock")
        
        if eventsData.count == 0{
            //No events
            self.eventTableView.isHidden = true
            self.noEventLabel.isHidden = false
        }else{
            self.eventTableView.isHidden = false
            self.noEventLabel.isHidden = true
            
            let sortedEvents = eventsData.sorted(by: {$0.start < $1.start })
            
            self.conflictingEventsSet = getConflictingEventsSet(sortedEvents)
            
            //Group sorted Event by Date
            self.groupedEventDict = groupEventsData(sortedEvents)
            
            //Sort Keys by Date Componenet
            sortedDateKeys = groupedEventDict.keys.sorted(by: {$0 > $1})
            self.eventTableView.reloadData()
        }
    }
    
    func parseDataToEvents(_ fileName: String) -> [EventItem]{
        guard let path = Bundle.main.url(forResource: fileName, withExtension: "json") else {
                print("Can't find \(fileName).json file")
                return []
        }
        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()  //November 10, 2018 6:00 PM"
            decoder.dateDecodingStrategy = .formatted(longDateFormatter)
            //Decode json data to EventItem
            let events = try decoder.decode([EventItem].self, from: data)
            return events
            
        } catch {
            print("JSON decoding Error:\(error)")
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
    
    
     //Events need to be sorted by start time
    //Return a set of event item
    func getConflictingEventsSet(_ sortedEvents: [EventItem]) -> Set<EventItem>{
        var conflictEvents : Set<EventItem> = []
        var intervalTaken: DateInterval =  DateInterval(start:sortedEvents[0].start, end: sortedEvents[0].end)
        for i in 1...sortedEvents.count-1{
            let event = sortedEvents[i]
           
            if (intervalTaken.end > event.start)
            {
                //Overlapping
                intervalTaken = DateInterval(start: intervalTaken.start, end: max(event.end, intervalTaken.end))
                let previousEvent = sortedEvents[i-1]
                conflictEvents.insert(previousEvent)
                conflictEvents.insert(event)
            }else{
                //start a new interval
                intervalTaken = DateInterval(start: event.start, end: event.end)
            }
        }
        return conflictEvents
    }
    
    @IBAction func reloadJsonData(_ sender: Any) {
        self.loadDataForDisplay()
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
