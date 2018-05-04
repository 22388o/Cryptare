//
//  PortfolioIntroViewController.swift
//  Cryptare
//
//  Created by Akshit Talwar on 02/05/2018.
//  Copyright © 2018 atalw. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class PortfolioIntroViewController: UIViewController, UIScrollViewDelegate {

  var baseController: UIViewController!
  var fromAppDelegate: Bool = false
  
  @IBOutlet weak var slideScrollView: UIScrollView!
  @IBOutlet weak var pageControl: UIPageControl!
  @IBOutlet weak var doneButton: UIButton! {
    didSet {
      doneButton.isEnabled = false
      doneButton.setBackgroundColor(color: UIColor.darkGray, forState: .disabled)
      doneButton.setTitleColor(UIColor.white, for: .normal)
      doneButton.setTitleColor(UIColor.lightGray, for: .disabled)
      doneButton.layer.cornerRadius = 5
      doneButton.clipsToBounds = true
    }
  }
  @IBOutlet weak var settingsLabel: UILabel! {
    didSet {
      settingsLabel.adjustsFontSizeToFitWidth = true
    }
  }
  @IBOutlet weak var skipButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    FirebaseService.shared.updateScreenName(screenName: "Markets Onboard", screenClass: "MarketsIntroViewController")
    
    slideScrollView.delegate = self
    let slides = createSlides()
    setupSlideScrollView(slides: slides)
    
    pageControl.numberOfPages = slides.count
    pageControl.currentPage  = 0
    
    view.bringSubview(toFront: pageControl)
    view.bringSubview(toFront: skipButton)
  }
  
  func createSlides() -> [UIView] {
    
    let SummaryView = IntroTemplateView()
    SummaryView.updateData(image: UIImage(named: "portfolioIntro")!, title: "Easy portfolio management.", description: "Track your cryptocurrency transactions with very high accuracy anytime and anywhere.")
    
    let TransactionView = IntroTemplateView()
    TransactionView.updateData(image: UIImage(named: "transactionDetailIntro")!, title: "Detailed transaction entry.", description: "Add a buy or sell transaction with details - exchange, fees, date and time.")
    
    let TransactionDetailsView = IntroTemplateView()
    TransactionDetailsView.updateData(image: UIImage(named: "transactionsIntro")!, title: "Track your transactions easily.", description: "Add crypto-fiat and crypto-crypto transactions and let Cryptare handle all the calculations for you.")
    
    let MultiplePortfoliosView = IntroTemplateView()
    MultiplePortfoliosView.updateData(image: UIImage(named: "multiplePortfoliosIntro")!, title: "Create multiple portfolios.", description: "Declutter your invesments by organizing them into multiple portfolios.")
    
    return [SummaryView, TransactionView, TransactionDetailsView, MultiplePortfoliosView]
  }
  
  func setupSlideScrollView(slides: [UIView]) {
    slideScrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
    
    slideScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height)
    
    slideScrollView.isPagingEnabled = true
    
    for index in 0..<slides.count {
      slides[index].frame = CGRect(x: view.frame.width * CGFloat(index), y: 0, width: view.frame.width, height: view.frame.height)
      slideScrollView.addSubview(slides[index])
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
    pageControl.currentPage = Int(pageIndex)
    
    if pageControl.currentPage == pageControl.numberOfPages-1 {
      doneButton.isEnabled = true
    }
  }
  
  @IBAction func skipButtonTapped(_ sender: Any) {
    Defaults[.mainPortfolioIntroComplete] = true
    self.dismiss(animated: true, completion: nil)
  }
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
}
