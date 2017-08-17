//
//  SecondViewController.swift
//  Btc
//
//  Created by Akshit Talwar on 02/07/2017.
//  Copyright © 2017 atalw. All rights reserved.
//

import UIKit

import Alamofire
import AlamofireRSSParser

public enum NetworkResponseStatus {
    case success
    case error(string: String?)
}


class SecondViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var allNewsData : [NewsData] = [];
    
    @IBAction func refreshButton(_ sender: Any) {
        self.getNews()
    }
    
    @IBOutlet weak var indiaButton: UIButton!
    @IBOutlet weak var worldwideButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        self.indiaButton.setBackgroundColor(color: UIColor.white, forState: .selected)
//        self.worldwideButton.setBackgroundColor(color: UIColor.white, forState: .selected)
        
//        self.indiaButton.layer.cornerRadius = 5
//        self.worldwideButton.layer.cornerRadius = 5
        
//        self.indiaButton.layer.borderWidth = 1
//        self.indiaButton.layer.borderColor = UIColor.white.cgColor
//        self.indiaButton.layer.masksToBounds = true
        
//        self.indiaButton.setButtonBorder(color: UIColor.white, forState: .selected)
//        self.worldwideButton.setButtonBorder(color: UIColor.white, forState: .selected)
//
//        self.indiaButton.setButtonBorder(color: UIColor.clear, forState: .normal)
//        self.worldwideButton.setButtonBorder(color: UIColor.clear, forState: .normal)
        
//        self.indiaButton.setBackgroundColor(color: UIColor.clear, forState: .normal)
//        self.worldwideButton.setBackgroundColor(color: UIColor.clear, forState: .normal)
        
        self.indiaButton.isSelected = true
        self.worldwideButton.isSelected = false
        
        self.indiaButton.setTitleColor(UIColor.white, for: .selected)
        self.worldwideButton.setTitleColor(UIColor.white, for: .selected)
        
        self.indiaButton.contentMode = .center
        self.worldwideButton.contentMode = .center
        
        self.getNews()
        
        self.indiaButton.addTarget(self, action: #selector(newsButtonTapped), for: .touchUpInside)
        self.worldwideButton.addTarget(self, action: #selector(newsButtonTapped), for: .touchUpInside)


        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)

    }
    
    func newsButtonTapped() {
        self.indiaButton.isSelected = !self.indiaButton.isSelected
        self.worldwideButton.isSelected = !self.worldwideButton.isSelected
        self.getNews()
    }
    
    func getNews() {
        self.allNewsData = []
        self.tableView.reloadData()
        if (self.indiaButton.isSelected) {
            self.getIndiaNews()
        }
        else if (self.worldwideButton.isSelected) {
            self.getWorldwideNews()
        }

    }
    func appMovedToBackground() {
        if let row = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: row, animated: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getIndiaNews() {
        self.getRSSFeedResponse(path: "https://news.google.com/news/rss/search/section/q/bitcoin%20india/bitcoin%20india?hl=en&ned=us") { (rssFeed: RSSFeed?, status: NetworkResponseStatus) in
            for item in (rssFeed?.items)! {
                let newsData = NewsData(title: item.title!, pubDate: item.pubDate!, link: item.link!)
                self.allNewsData.append(newsData)
            }
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()
        }
    }
    
    func getWorldwideNews() {
        self.getRSSFeedResponse(path: "https://news.google.com/news/rss/search/section/q/bitcoin/bitcoin?hl=en&ned=us") { (rssFeed: RSSFeed?, status: NetworkResponseStatus) in
            for item in (rssFeed?.items)! {
                let newsData = NewsData(title: item.title!, pubDate: item.pubDate!, link: item.link!)
                self.allNewsData.append(newsData)
            }
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()
        }
    }
    
    

    
    public func getRSSFeedResponse(path: String, completionHandler: @escaping (_ response: RSSFeed?,_ status: NetworkResponseStatus) -> Void) {
        Alamofire.request(path).responseRSS() { response in
            if let rssFeedXML = response.result.value {
                // Successful response - process the feed in your completion handler
                completionHandler(rssFeedXML, .success)
            } else {
                // There was an error, so feel free to handle it in your completion handler
                completionHandler(nil, .error(string: response.result.error?.localizedDescription))
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) ->  Int {
        return allNewsData.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath) as! CustomNewsTableViewCell
        let entry = allNewsData[indexPath.row]
        cell.title.text = entry.title
        
        let timeInMilliSeconds = entry.pubDate.timeIntervalSinceNow
        let time = floor(abs(timeInMilliSeconds)/3600)
        let intTime = Int(time)
        if time < 24 {
            cell.pubDate.text = "\(intTime)h ago"
        }
        else {
            let dateString = entry.pubDate.description
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            if let date = dateFormatter.date(from: dateString) {
                dateFormatter.dateFormat = "dd/MM/yy"
                cell.pubDate.text = dateFormatter.string(from: date)
            }
        }
        
        cell.link = entry.link
        return cell
    }

}

extension UIButton {
    
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
//        UIGraphicsGetCurrentContext()!.radi
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    }
    
    func setButtonBorder(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let context = UIGraphicsGetCurrentContext();
        
        context?.setStrokeColor(color.cgColor)
        context?.setLineWidth(1);
        context?.stroke(CGRect(x: 0, y: 0, width: 1, height: 1))
//        context?.
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    
    }
}

