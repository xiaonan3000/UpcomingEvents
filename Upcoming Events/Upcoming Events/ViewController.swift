//
//  ViewController.swift
//  Upcoming Events
//
//  Created by Shannon Ma on 4/27/20.
//  Copyright © 2020 Shannon Ma. All rights reserved.
//

import UIKit

struct EventItem: Codable{
    var title: String
    var start: Date
    var end: Date
}

struct ConflictRange{
    var start: Date
    var end: Date
}

class ViewController: UIViewController {

    var eventDataArray = [EventItem]()
    var conflictsDict = [Date: ConflictRange]()
    
    let shortDateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()
    
    let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy h:mm a"
        return formatter
    }()
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
   
    var eventDataDictionary = [Date : [EventItem]]()
    var sortedDateKeys =  [Date]()
    
    @IBOutlet weak var eventTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        self.loadJsonData()
    }

    
    func loadJsonData(){
        if let path = Bundle.main.url(forResource: "mock", withExtension: "json"){
            do {
                let data = try Data(contentsOf: path)
                let decoder = JSONDecoder()  //November 10, 2018 6:00 PM"
                decoder.dateDecodingStrategy = .formatted(longDateFormatter)
                //Write json data to EventItem
                let events = try decoder.decode([EventItem].self, from: data)
                
                self.eventDataDictionary = events.sorted(by: {$0.start < $1.start }).reduce(into: [Date: [EventItem]]()) { result, event in
                    // Sort events under the same date group by their start dates
                    let components = Calendar.current.dateComponents([.day, .year, .month], from: event.start)
                    let date = Calendar.current.date(from: components)
                    result[date!, default: []].append(event)
                }
           
            } catch {
                print("JSON decoding Error:\(error)")
            }
        }
        //Sort Date Key
        sortedDateKeys = eventDataDictionary.keys.sorted(by: {$0 > $1})
        self.checkConflictEvents()
        self.eventTableView.reloadData()
    }
    
    //Finding Overlapping time frames
    func checkConflictEvents(){
        for dateKey in sortedDateKeys{
            if let eventList = eventDataDictionary[dateKey],  eventList.count > 1 {
                for i in 0...eventList.count-2{
                    let first = eventList[i]
                    let next  = eventList[i+1]
                    //Events are already sorted by start time
                    if (first.end > next.start)
                    {
                        if let range = conflictsDict[dateKey]{
                            if range.start > next.start{
                                conflictsDict[dateKey]!.start = next.start
                            }
                            if range.end < first.end{
                                conflictsDict[dateKey]!.start = first.end
                            }
                        }else{
                            conflictsDict[dateKey] = ConflictRange.init(start: next.start, end: first.end)
                        }
                    }   
                }
            }
        }
    }
    
    
    @IBAction func reloadJsonData(_ sender: Any) {
        self.loadJsonData()
        
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
        if let values = eventDataDictionary[key]{
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
        if let values = eventDataDictionary[key]{
            let eventForCell = values[indexPath.row]
            cell.textLabel?.text = eventForCell.title
            
            //Cell details label shows start and end time
            let startDate = eventForCell.start
            let endDate = eventForCell.end
           
            cell.detailTextLabel?.text = "\(timeFormatter.string(from: startDate)) - \(timeFormatter.string(from: endDate))"
        
            //Conflicting event
            if let conflictInterval = conflictsDict[key]{
                let isOverlapping = (eventForCell.start...eventForCell.end).overlaps(conflictInterval.start...conflictInterval.end)
                cell.detailTextLabel?.textColor = isOverlapping ? UIColor.red  : UIColor.darkGray
            }
        }
        return cell
    }
}
