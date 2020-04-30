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
    //Use a unique id to identify events with same title and start/end date
    //var createdDate = Date()
    var id: String = UUID().uuidString
    
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
        self.loadDataForDisplay("mock")
    }

    func loadDataForDisplay(_ fileName: String){
        guard let path = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Can't find \(fileName).json file")
            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            let eventsData = parseJSON(data)
            if eventsData.count == 0{
                //No events
                self.eventTableView.isHidden = true
                self.noEventLabel.isHidden = false
            }else{
                self.eventTableView.isHidden = false
                self.noEventLabel.isHidden = true
                
                //Validate events data
                var validEvents = eventsData.filter({$0.start <=  $0.end})
                //Sort events by start date
                validEvents.sort(by: { $0.start < $1.start})
                
                //get a set of conflicting Event items
                self.conflictingEventsSet = getConflictingEventsSet(validEvents)
                
                //Group sorted Event by Date
                self.groupedEventDict = groupEventsData(eventsData)
                
                //Sort Keys by Date Componenet, cloest to current date
                let today = Date()
                sortedDateKeys = groupedEventDict.keys.sorted(by: {
                    let t1 = abs($0.timeIntervalSince(today))
                    let t2 = abs($1.timeIntervalSince(today))
                    return t1 <= t2
                })
                
                self.eventTableView.reloadData()
            }
        }catch {
            print("Data content error:\(error)")
        }
    }
    
    func parseJSON(_ data: Data) -> [EventItem]{
        do {
            let decoder = JSONDecoder()  //November 10, 2018 6:00 PM"
            decoder.dateDecodingStrategy = .formatted(longDateFormatter)
            //Decode json data to EventItem
            let events = try decoder.decode([EventItem].self, from: data)
            return events
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
    
    //Fot test purpose - switch json data file
    @IBAction func reloadJsonData(_ sender: Any) {
        let alertController = UIAlertController(title: "Load another JSON File?", message: nil, preferredStyle:.alert)
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter file name"
        })
        alertController.addAction(UIAlertAction(title: "OK", style: .default)
        { action -> Void in
            // Put your code here
            let tf = alertController.textFields![0]
            let fileName = tf.text ?? ""
            if fileName.isEmpty == false{
                self.loadDataForDisplay(fileName)
            }
        })
        self.present(alertController, animated: false, completion: nil)
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
