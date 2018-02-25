//
//  AddTransactionTableViewController.swift
//  Btc
//
//  Created by Akshit Talwar on 25/02/2018.
//  Copyright © 2018 atalw. All rights reserved.
//

import UIKit
import Firebase

class AddTransactionTableViewController: UITableViewController {

    var coin: String!
    // tradingPairs: [(coin, currency)]
    var tradingPairs: [(String, String)] = []
    // markets: [currency: [(marketName, dbTableTitle)]
    var allMarkets: [String: [String: String]] = [:]
    var currentTradingPairMarkets: [String: String] = [:]
    var databaseRef: DatabaseReference!
    
    var currentTradingPair: (String, String)!
    var currentExchange: (String, String)!
    
    @IBOutlet weak var tradingPairCell: UITableViewCell!
    @IBOutlet weak var currentTradingPairLabel: UILabel!
    @IBOutlet weak var currentExchangeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        databaseRef = Database.database().reference().child(coin)
        
        databaseRef.observeSingleEvent(of: .childAdded, with: {(snapshot) -> Void in
            if let dict = snapshot.value as? [String : AnyObject] {
                for (title, data) in dict {
                    if title != "name" && title != "rank" {
                        self.tradingPairs.append((self.coin, title))
                        self.allMarkets[title] = [:]
                        if let markets = data["markets"] as? [String: String] {
//                            print(markets)
                            self.allMarkets[title] = markets
                        }
                        self.allMarkets[title]!["None"] = "none"
                    }
                }
                self.updateLabels()
            }
        })
    }
    
    func updateLabels() {
        for (coin, currency) in tradingPairs {
            if GlobalValues.currency == currency {
                self.currentTradingPair = (coin, currency)
                self.currentTradingPairLabel.text = "\(coin)-\(currency)"
                
                if let markets = allMarkets[currency] as? [String: String] {
                    self.currentTradingPairMarkets = markets
                    self.currentExchange = ("None", "none")
                    self.currentExchangeLabel.text = currentExchange.0
                }
                
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateCurrentTradingPair(pair: (String, String)) {
        self.currentTradingPair = pair
        self.currentTradingPairLabel.text = "\(pair.0)-\(pair.1)"
        
        if let markets = allMarkets[pair.1] as? [String: String] {
            currentTradingPairMarkets = markets
            self.currentExchange = ("None", "none")
            self.currentExchangeLabel.text = currentExchange.0
        }
    }
    
    func updateCurrentExchange(exchange: (String, String)) {
        self.currentExchange = exchange
        self.currentExchangeLabel.text = exchange.0
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let destinationVC = segue.destination as? TradingPairTableViewController {
            destinationVC.parentController = self
            destinationVC.tradingPairs = self.tradingPairs
        }
        else if let destinationVc = segue.destination as? AvailableExchangesTableViewController {
            destinationVc.parentController = self
            destinationVc.markets = self.currentTradingPairMarkets
        }
        
    }

}
