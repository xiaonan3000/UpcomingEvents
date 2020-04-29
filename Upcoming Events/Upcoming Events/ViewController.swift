//
//  ViewController.swift
//  Upcoming Events
//
//  Created by Shannon Ma on 4/27/20.
//  Copyright © 2020 Shannon Ma. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var eventDataArray = [EventItem]()
    
    let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy h:mm a"
        return formatter
    }()
    
   
    var eventDataDictionary = [Date : [EventItem]]()
    var sortedDateKeys =  [Date]()
    
    @IBOutlet weak var eventTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.loadJsonData()
    }

    
    func loadJsonData(){
        if let path = Bundle.main.url(forResource: "mock", withExtension: "json"){
            do {
                let data = try Data(contentsOf: path)
                let decoder = JSONDecoder()
               
               
                //November 10, 2018 6:00 PM"
                decoder.dateDecodingStrategy = .formatted(timeFormatter)
                
                let events = try decoder.decode([EventItem].self, from: data)
                                
//                self.eventDataDictionary = Dictionary(grouping: events) { (event) -> Date in
//
//                    let components = Calendar.current.dateComponents([.day, .year, .month], from: event.start)
//                    let date = Calendar.current.date(from: components)
//                    return date!
//                }
               self.eventDataDictionary = events.sorted(by: {$0.start < $1.start }).reduce(into: [Date: [EventItem]]()) { result, event in
                   // make sure there is at least one letter in your string else return
                   let components = Calendar.current.dateComponents([.day, .year, .month], from: event.start)
                   let date = Calendar.current.date(from: components)
                   
                   result[date!, default: []].append(event)
               }
                //Sort  Date Key
                sortedDateKeys = eventDataDictionary.keys.sorted(by: {$0 > $1})
                

            } catch {
                print("error:\(error)")
            }
        }
        self.eventTableView.reloadData()
    }
    
    @IBAction func reloadJsonData(_ sender: Any) {
        self.loadJsonData()
    }

}
extension ViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let customView = UIView.init(frame: CGRect(x: 20, y: 0, width: 248, height: 44.0))
        customView.backgroundColor = .lightGray
    
        let headerTitleLabel = UILabel(frame: customView.frame)
        let dateKey = sortedDateKeys[section]
        headerTitleLabel.text = dateFormatter.string(from: dateKey)
        headerTitleLabel.textColor = .white
        headerTitleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        customView.addSubview(headerTitleLabel)
        return customView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
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
            let startDate = eventForCell.start
            cell.detailTextLabel?.text = timeFormatter.string(from: startDate)
        }
        return cell
    }
}
