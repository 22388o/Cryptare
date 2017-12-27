//
//  PortfolioSummaryViewController.swift
//  Btc
//
//  Created by Akshit Talwar on 19/12/2017.
//  Copyright © 2017 atalw. All rights reserved.
//

import UIKit

class PortfolioSummaryViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    let dateFormatter = DateFormatter()

    let portfolioEntriesConstant = "portfolioEntries"


    var dict: [String: [[String: Any]]] = [:]
    var coins: [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "YYYY-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        tableView.delegate = self
        tableView.dataSource = self
        
        
        self.addLeftBarButtonWithImage(UIImage(named: "icons8-menu")!)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dict = [:]
        coins = []
        initalizePortfolioEntries()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func initalizePortfolioEntries() {
        //        defaults.removeObject(forKey: "portfolioEntries")
        
        if let data = defaults.data(forKey: portfolioEntriesConstant) {
            let portfolioEntries = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[Int:Any]]
            print(portfolioEntries)
            dict = [:]
            print(portfolioEntries.count)
            for index in 0..<portfolioEntries.count {
                let firstElement = portfolioEntries[index][0] as? String
                let secondElement = portfolioEntries[index][1] as? String
                let thirdElement = portfolioEntries[index][2] as? Double
                let fourthElement = portfolioEntries[index][3] as? String
                if let coin = firstElement, let type = secondElement, let coinAmount = thirdElement, let date = dateFormatter.date(from: fourthElement as! String) {
                    if dict[coin] == nil {
                        dict[coin] = []
                    }
                    dict[coin]!.append(["type": type, "coinAmount": coinAmount, "date": date])
                }
            }
        }
        
        for coin in dict.keys {
            coins.append(coin)
        }
        
        tableView.reloadData()
    }
}

extension PortfolioSummaryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioSummaryCell") as? PortfolioSummaryTableViewCell
        
        cell!.coinSymbolLabel.text = "\(coins[indexPath.row])"
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let targetViewController = storyboard?.instantiateViewController(withIdentifier: "coinDetailPortfolioController") as! PortfolioViewController
        
        targetViewController.coin = coins[indexPath.row]
        targetViewController.portfolioData = dict[coins[indexPath.row]]!
        
        self.navigationController?.pushViewController(targetViewController, animated: true)

    }
}
