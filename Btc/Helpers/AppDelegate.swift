//
//  AppDelegate.swift
//  Btc
//
//  Created by Akshit Talwar on 02/07/2017.
//  Copyright © 2017 atalw. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import UserNotifications
import SlideMenuControllerSwift
import SwiftyStoreKit
import Armchair
import SwiftyUserDefaults
import SwiftTheme

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
  
  var window: UIWindow?
  var ref: DatabaseReference!
  let defaults = UserDefaults.standard
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    // armchair - for app review
    Armchair.appID("1266256984")
    Armchair.significantEventsUntilPrompt(5)
    
    // navigation bar
    UINavigationBar.appearance().isTranslucent = false
    UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    UINavigationBar.appearance().tintColor = UIColor.white
    
    
    UINavigationBar.appearance().theme_barTintColor = GlobalPicker.navigationBarTintColor
    
    if #available(iOS 11.0, *) {
      UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    }
    
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(changeAppearanceColours),
      name: NSNotification.Name(rawValue: ThemeUpdateNotification),
      object: nil
    )
    
    #if DEBUG
      print("DEBUG")
    #else
      fetchReceipt()
    #endif
    
    
    // google ads
//    GADMobileAds.configure(withApplicationID: "ca-app-pub-5797975753570133~4584171807")
    
    
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    // dashboard settings
    if !Defaults.hasKey(.dashboardFavourites) &&
      !Defaults.hasKey(.dashboardFavouritesFirstTab) {
      Defaults[.dashboardFavourites] = ["BTC", "ETH", "LTC", "XRB"]
      Defaults[.dashboardFavouritesFirstTab] = true
    }
    
    // chart settings
    if !Defaults.hasKey(.chartSettingsExist) {
      Defaults[.chartMode] = "smooth"
      
      Defaults[.xAxis] = ChartSettingsDefault.xAxis
      Defaults[.xAxisGridLinesEnabled] = ChartSettingsDefault.xAxisGridLinesEnabled
      
      Defaults[.yAxis] = ChartSettingsDefault.yAxis
      Defaults[.yAxisGridLinesEnabled] = ChartSettingsDefault.yAxisGridLinesEnabled
      
      Defaults[.chartSettingsExist] = true
    }
    
    // coin market settings
    if !Defaults.hasKey(.marketSettingsExist) {
      Defaults[.marketSort] = "buy"
      Defaults[.marketOrder] = "ascending"
      
      Defaults[.marketSettingsExist] = true
    }
    
    
    // market settings
    if !Defaults.hasKey(.favouritePairs) {
      Defaults[.favouritePairs] = ["BTC": ["USDT": [["name": "Binance", "databaseTitle": "binance/BTC/USDT"]], "USD": [["name": "Coinbase", "databaseTitle": "coinbase/BTC/USD"]], "GBP": [["name": "LocalBitcoins", "databaseTitle": "localbitcoins/BTC/GBP"]]], "ETH": ["USDT": [["name": "Binance", "databaseTitle": "binance/ETH/USDT"]], "INR": [["name": "Koinex", "databaseTitle": "koinex/ETH/INR"]]], "NEO": ["BTC": [["name": "Bittrex", "databaseTitle": "bittrex/NEO/BTC"]]], "LTC": ["USD": [["name": "Coinbase", "databaseTitle": "coinbase/LTC/USD"]]]]
    }
    if !Defaults.hasKey(.favouriteMarkets) {
      Defaults[.favouriteMarkets] = ["Bittrex", "Binance", "Coinbase", "Bitfinex", "Bitbns"]
    }
    
    
    // news settings
    if !Defaults.hasKey(.newsSettingsExist) {
      Defaults[.newsSort] = "popularity"
      
      Defaults[.newsSettingsExist] = true
    }
    
    let selectedCountry = Defaults[.selectedCountry]
    let introComplete = Defaults[.mainAppIntroComplete]
    
    // if country has been selected
    if selectedCountry != "" {
      
      for countryTuple in GlobalValues.countryList {
        if selectedCountry == countryTuple.0 {
          GlobalValues.currency = countryTuple.1
        }
      }
      
      self.createMenuView(storyboard: storyboard)
      
      if !introComplete {
        let introViewController = storyboard.instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
        
        self.window?.rootViewController?.present(introViewController, animated: true, completion: nil)
      }
    }
    else { // country not selected
      if introComplete {
        
        GlobalValues.currency = "USD"
        
        self.createMenuView(storyboard: storyboard)
        
        let countrySelectionViewController = storyboard.instantiateViewController(withIdentifier: "CountrySelectionViewController") as! CountrySelectionViewController
        
        self.window?.rootViewController?.present(countrySelectionViewController, animated: true, completion: nil)
      }
      else {
        GlobalValues.currency = "USD"
        
        self.createMenuView(storyboard: storyboard)
        
        let introViewController = storyboard.instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
        introViewController.baseController = self.window?.rootViewController
        introViewController.fromAppDelegate = true
        
        self.window?.rootViewController?.present(introViewController, animated: true, completion: nil)
        
      }
    }
    
    if #available(iOS 10.0, *) {
      // For iOS 10 display notification (sent via APNS)
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    UIApplication.shared.registerForRemoteNotifications()
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self

    setUpFirebase()

    
//    // notification request
//    if #available(iOS 10.0, *) {
//      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (isGranted, error) in
//        if error != nil { return }
//
//        if isGranted {
//          UNUserNotificationCenter.current().delegate = self
//        }
//      })
//      application.registerForRemoteNotifications()
//
//
//    } else {
//      // Fallback on earlier versions
//    }
    
    return true
  }
  
  func createMenuView(storyboard: UIStoryboard) {
    let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
    let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController") as! LeftViewController
    
    let nvc: UINavigationController = UINavigationController(rootViewController: mainViewController)
    
    leftViewController.mainViewController = nvc
    
    SlideMenuOptions.contentViewDrag = true
    SlideMenuOptions.contentViewScale = 1
    SlideMenuOptions.animationDuration = 0.2
    SlideMenuOptions.contentViewOpacity = 0.1
    SlideMenuOptions.leftViewWidth = 220
    
    let slideMenuController = SlideMenuController(mainViewController: nvc, leftMenuViewController: leftViewController)
    self.window?.rootViewController = slideMenuController
    slideMenuController.delegate = mainViewController as SlideMenuControllerDelegate
    self.window?.makeKeyAndVisible()
  }
  
  func setUpFirebase() {
    FirebaseApp.configure()
    ref = Database.database().reference()
    
    let fcmToken = Messaging.messaging().fcmToken
    print("FCM token: \(fcmToken ?? "")")
    
    Auth.auth().signInAnonymously() { (user, error) in
      if error != nil {
        print("Sign in error")
        return
      }
      
      guard let uid = user?.uid else { return }
      print("uid", uid)
      let usersReference = Database.database().reference()
                            .child("users").child(uid)
      
      if let token = fcmToken {
        let values: [String : Any] = ["timestamp": Date().timeIntervalSince1970,
                                      "notificationTokens": [fcmToken!: true] as [String: Any]]
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
          if err != nil {
            print(err)
            return
          }
        })
      }
    }
    Database.database().reference().child("all_exchange_info").observeSingleEvent(of: .value, with: { snapshot -> Void in
      if let dict = snapshot.value as? [String: [String: Any]] {
        marketInformation = dict
      }
    })
  }
  
  func connectToFCM() {
    Messaging.messaging().shouldEstablishDirectChannel = true
  }
  
  func disconnectFromFCM() {
    Messaging.messaging().shouldEstablishDirectChannel = false
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    disconnectFromFCM()
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //        FirstViewController.loadData(<#T##FirstViewController#>)
    connectToFCM()
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
    print("Firebase registration token: \(fcmToken)")
    connectToFCM()
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Convert token to string
    let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
    
    // Print it to console
    print("APNs device token: \(deviceTokenString)")
    
    Messaging.messaging().apnsToken = deviceToken
    print("registered")
    Messaging.messaging().subscribe(toTopic: "/topics/general")
  }
  
  func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
  }
  
  @available(iOS 10.0, *)
  // display notification even if in app
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler(.alert)
  }
  
  func fetchReceipt() {
    // return local receipt or fetch receipt if not available
    SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
      switch result {
      case .success(let receiptData):
        let encryptedReceipt = receiptData.base64EncodedString(options: [])
        print("Fetch receipt success:\n\(encryptedReceipt)")
        
        let receiptValidator = ReceiptValidator()
        let validationResult = receiptValidator.validateReceipt()
        
        switch validationResult {
        case .success(let receipt):
          // Work with parsed receipt data. Possibilities might be...
          // enable a feature of your app
          // remove ads
          // etc...
          print("here")
        case .error(let error):
          // Handle receipt validation failure. Possibilities might be...
          // use StoreKit to request a new receipt
          // enter a "grace period"
          // disable a feature of your app
          // etc...
          print("not")
        }
      case .error(let error):
        print("Fetch receipt failed: \(error)")
      }
    }
    
    //        // apple receipt validation
    //        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: "your-shared-secret")
    //        SwiftyStoreKit.verifyReceipt(using: appleValidator, forceRefresh: false) { result in
    //            switch result {
    //            case .success(let receipt):
    //                print("Verify receipt success: \(receipt)")
    //                if let originalAppVersion = receipt["receipt"]?["original_application_version"] as? String {
    //                    print(originalAppVersion, "Original")
    //                    if let versionNumber = Double(originalAppVersion) {
    //                        if versionNumber < 2.92 {
    //                            Defaults[.removeAdsPurchased] = true
    //                            Defaults[.previousPaidUser] = true
    //                        }
    //                    }
    //                }
    //            case .error(let error):
    //                print("Verify receipt failed: \(error)")
    //            }
    //        }
  }
  
  @objc func changeAppearanceColours() {
    let themeIndex = ThemeManager.currentThemeIndex
    //do something according to `themeIndex`
    if themeIndex == 0 {
      UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.black]
    }
    else {
       UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
    }
  }
  
}

