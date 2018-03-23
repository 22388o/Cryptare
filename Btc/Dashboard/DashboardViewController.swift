//
//  DashboardViewController.swift
//  Btc
//
//  Created by Akshit Talwar on 19/08/2017.
//  Copyright © 2017 atalw. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds
import SwiftReorder

class DashboardViewController: UIViewController {
    
    var parentController: MainViewController!
    
    let dateFormatter = DateFormatter()
    let defaults = UserDefaults.standard

    let dashboardFavouritesKey = "dashboardFavourites"
    var favouritesTab: Bool!
    
    var coins: [String] = []
    let greenColour = UIColor.init(hex: "#35CC4B")
    let redColour = UIColor.init(hex: "#e74c3c")
    
    var graphController: GraphViewController! // child view controller
    
    var coinData: [String: [String: Any]] = [:]
    var changedRow = 0
    
    @IBOutlet weak var tableView: UITableView!
    
    var databaseRef: DatabaseReference!
    var listOfCoins: DatabaseReference!
    var coinRefs: [DatabaseReference] = []
    
//    let searchController = UISearchController(searchResultsController: nil)
    var coinSearchResults = [String]()

    @IBOutlet weak var header24hrChangeLabel: UILabel!
    @IBOutlet weak var headerCurrentPriceLabel: UILabel!
    
    @IBOutlet weak var bannerView: GADBannerView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
        
        let removeAdsPurchased: Bool = UserDefaults.standard.bool(forKey: "removeAdsPurchased")
        if removeAdsPurchased == false {
            bannerView.load(GADRequest())
            bannerView.delegate = self
        }
        else {
            bannerView.isHidden = true
        }
        
        if currentReachabilityStatus == .notReachable {
            let alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in }  )
            //            self.present(alert, animated: true){}
            present(alert, animated: true, completion: nil)
        }
        
        if !favouritesTab {
            self.setupCoinRefs()
        }
        else {
            self.getFavourites()
            
            if coins.count == 0 {
                let messageLabel = UILabel()
                messageLabel.text = "No coins added to your favourites"
                messageLabel.textColor = UIColor.black
                messageLabel.numberOfLines = 0;
                messageLabel.textAlignment = .center
                messageLabel.sizeToFit()
                
                tableView.backgroundView = messageLabel
            }
            else {
                tableView.backgroundView = nil
                self.setupCoinRefs()
            }
        }
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        
        databaseRef = Database.database().reference()
        
        listOfCoins = databaseRef.child("coins")
        
        if !favouritesTab {
            listOfCoins.queryLimited(toLast: 1).observeSingleEvent(of: .childAdded, with: {(snapshot) -> Void in
                if let dict = snapshot.value as? [String: AnyObject] {
                    let sortedDict = dict.sorted(by: { ($0.1["rank"] as! Int) < ($1.1["rank"] as! Int)})
                    self.coins = []
                    GlobalValues.coins = []
                    for index in 0..<sortedDict.count {
                        self.coins.append(sortedDict[index].key)
                        GlobalValues.coins.append((sortedDict[index].key, sortedDict[index].value["name"] as! String))
                    }
                    self.setupCoinRefs()
                }
            })
        }
        else {
            // for reorder
            tableView.reorder.delegate = self
//            self.getFavourites()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        databaseRef.removeAllObservers()
        listOfCoins.removeAllObservers()
        
        for coinRef in coinRefs {
            coinRef.removeAllObservers()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let destinationViewController = segue.destination
        if let graphController = destinationViewController as? GraphViewController {
//            graphController.parentControler = self
            self.graphController = graphController
        }
    }
    
    func getFavourites() {
        self.coins = []
        var favourites: [String] = []
        if let favouritesDefaults = defaults.object(forKey: "dashboardFavourites") {
            favourites = favouritesDefaults as! [String]
        }
        self.coins = favourites
    }
    
    
    func setupCoinRefs() {
        let currency = GlobalValues.currency!
        coinData = [:]
        for coin in self.coins {
            self.coinData[coin] = [:]
            self.coinData[coin]!["rank"] = 0
            self.coinData[coin]!["currentPrice"] = 0.0
            self.coinData[coin]!["timestamp"] = 0.0
            self.coinData[coin]!["volume24hrs"] = 0.0
            self.coinData[coin]!["percentageChange24hrs"] = 0.0
            self.coinData[coin]!["priceChange24hrs"] = 0.0
        }
        coinRefs = []
        for coin in self.coins {
            self.coinRefs.append(self.databaseRef.child(coin))
        }
        
        for coinRef in self.coinRefs {
            coinRef.observeSingleEvent(of: .childAdded, with: {(snapshot) -> Void in
                if let dict = snapshot.value as? [String : AnyObject] {
                    if let index = self.coinRefs.index(of: coinRef) {
                        let coin = self.coins[index]
                        self.changedRow = index
                        self.updateCoinDataStructure(coin: coin, dict: dict)
                    }
                }
                    
            })
            
            coinRef.observe(.childChanged, with: {(snapshot) -> Void in
                if let dict = snapshot.value as? [String : AnyObject] {
                    if let index = self.coinRefs.index(of: coinRef) {
                        let coin = self.coins[index]
                        self.changedRow = index
                        self.updateCoinDataStructure(coin: coin, dict: dict)
                    }
                }
            })
        }
    }
    
    func updateCoinDataStructure(coin: String, dict: [String: Any]) {
        self.coinData[coin]!["rank"] = dict["rank"] as! Int
        
        if let currencyData = dict[GlobalValues.currency!] as? [String: Any] {
            if self.coinData[coin]!["oldPrice"] == nil {
                self.coinData[coin]!["oldPrice"] = 0.0
            }
            else {
                self.coinData[coin]!["oldPrice"] = self.coinData[coin]!["currentPrice"]
            }
            self.coinData[coin]!["currentPrice"] = currencyData["price"] as! Double
            self.coinData[coin]!["volume24hrs"] = currencyData["vol_24hrs_currency"]
            let percentage = currencyData["change_24hrs_percent"] as! Double
            let roundedPercentage = Double(round(1000*percentage)/1000)
            self.coinData[coin]!["percentageChange24hrs"] = roundedPercentage
            self.coinData[coin]!["priceChange24hrs"] = currencyData["change_24hrs_fiat"] as! Double
            self.coinData[coin]!["timestamp"] = currencyData["timestamp"] as! Double
            self.tableView.reloadData()
        }
        
    }
    
    func isFiltering() -> Bool {
        return parentController.searchController.isActive && !searchBarIsEmpty()
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return parentController.searchController.searchBar.text?.isEmpty ?? true
    }
    
   
    
}

extension DashboardViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return coinSearchResults.count
        }
        return coins.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if favouritesTab {
            if let spacer = tableView.reorder.spacerCell(for: indexPath) {
                return spacer
            }
        }
        
        var coin: String
        if isFiltering() {
            coin = coinSearchResults[indexPath.row]
        }
        else {
            coin = coins[indexPath.row]
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "coinCell") as? CoinTableViewCell
        
        cell!.coinRank.text = "\(self.coinData[coin]?["rank"] as! Int)"
        cell!.coinRank.adjustsFontSizeToFitWidth = true
        
        cell!.coinSymbolLabel.text = coin
        cell!.coinSymbolLabel.adjustsFontSizeToFitWidth = true
        
        if coin == "IOT" {
            cell!.coinSymbolImage.image = UIImage(named: "miota")
        }
        else {
            cell!.coinSymbolImage.image = UIImage(named: coin.lowercased())
        }
        cell!.coinSymbolImage.contentMode = .scaleAspectFit
        
        for (symbol, name) in GlobalValues.coins {
            if symbol == coin {
                cell!.coinNameLabel.text = name
            }
        }
        
        
        var colour: UIColor
        let currentPrice = self.coinData[coin]?["currentPrice"] as! Double
        let oldPrice = self.coinData[coin]?["oldPrice"] as? Double ?? 0.0
        
        if  currentPrice > oldPrice {
            colour = self.greenColour
        }
        else if currentPrice < oldPrice {
            colour = self.redColour
        }
        else {
            colour = UIColor.black
        }
        
        cell!.coinCurrentValueLabel.adjustsFontSizeToFitWidth = true
        cell!.coinCurrentValueLabel.text = currentPrice.asCurrency
        if changedRow == indexPath.row {
            UILabel.transition(with:  cell!.coinCurrentValueLabel, duration: 0.1, options: .transitionCrossDissolve, animations: {
                cell!.coinCurrentValueLabel.textColor = colour
            }, completion: { finished in
                UILabel.transition(with:  cell!.coinCurrentValueLabel, duration: 1.5, options: .transitionCrossDissolve, animations: {
                    cell!.coinCurrentValueLabel.textColor = UIColor.black
                }, completion: nil)
            })
            
            changedRow = -1
        }
        
        
        self.dateFormatter.dateFormat = "h:mm a"
        let timestamp = self.coinData[coin]?["timestamp"] as! Double
        cell!.coinTimestampLabel.text =  self.dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
        cell!.coinTimestampLabel.adjustsFontSizeToFitWidth = true
        
        let percentageChange = self.coinData[coin]?["percentageChange24hrs"] as! Double
        cell!.coinPercentageChangeLabel.text = "\(percentageChange)%"
        
        if percentageChange > 0 {
            cell!.coinPercentageChangeLabel.textColor = greenColour
            colour = greenColour
        }
        else if percentageChange < 0 {
             cell!.coinPercentageChangeLabel.textColor = redColour
            colour = redColour
        }
        else {
             cell!.coinPercentageChangeLabel.textColor = UIColor.black
            colour = UIColor.black
        }
        
        let priceChange = self.coinData[coin]?["priceChange24hrs"] as! Double
        cell!.coinPriceChangeLabel.text = priceChange.asCurrency
        cell!.coinPriceChangeLabel.adjustsFontSizeToFitWidth = true
        cell!.coinPriceChangeLabel.textColor = colour
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let targetViewController = storyboard?.instantiateViewController(withIdentifier: "graphViewController") as! GraphViewController
        if isFiltering() {
            targetViewController.databaseTableTitle = self.coinSearchResults[indexPath.row]
        }
        else {
            targetViewController.databaseTableTitle = self.coins[indexPath.row]
        }
        self.navigationController?.pushViewController(targetViewController, animated: true)
    }
    
}



extension DashboardViewController: GADBannerViewDelegate {
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}

extension DashboardViewController: TableViewReorderDelegate {
    func tableView(_ tableView: UITableView, reorderRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Update data model
        let destinationCoin = coins[destinationIndexPath.row]
        coins[destinationIndexPath.row] = coins[sourceIndexPath.row]
        coins[sourceIndexPath.row] = destinationCoin
        
        defaults.set(coins, forKey: dashboardFavouritesKey)
    }
}




