//
//  ViewController.swift
//  ALDataRequestView
//
//  Created by Antoine van der Lee on 02/28/2016.
//  Copyright (c) 2016 Antoine van der Lee. All rights reserved.
//

import UIKit
import ALDataRequestView
import PureLayout

import ReactiveCocoa

class ViewController: UIViewController {

    var dataRequestView:ALDataRequestView?
    var signalProducer:SignalProducer<[String], NSError>?
    var dataSignalProducer:SignalProducer<NSData, NSError>?
    let (signal, subscriber) = Signal<[String], NSError>.pipe()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataRequestView = ALDataRequestView(forAutoLayout: ())
        view.addSubview(dataRequestView!)
        dataRequestView?.autoPinEdgesToSuperviewEdges()
        dataRequestView?.dataSource = self
        view.sendSubviewToBack(dataRequestView!)
        
        
        
//        testWithFailureCallSignalProducer()
    }
    
    deinit {
        print("Deinit vc")
    }
    
    func testWithEmptySignalProducer(){
        signalProducer = SignalProducer(signal: signal).attachToDataRequestView(dataRequestView!)
        signalProducer?.start()
        
        delay(3.0, closure: { [weak self] () -> Void in
            let emptyArray:[String] = []
            self?.subscriber.sendNext(emptyArray) // Send empty array
            self?.subscriber.sendCompleted()
        })
    }
    
    func testWithFailureCallSignalProducer(){
        let URLRequest = NSURLRequest(URL: NSURL(string: "http://httpbin.org/status/400")!)
        dataSignalProducer = NSURLSession.sharedSession()
            .rac_dataWithRequest(URLRequest)
            .flatMap(.Latest, transform: { (data, response) -> SignalProducer<NSData, NSError> in
                if let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode > 299 {
                    return SignalProducer(error: NSError(domain: "", code: httpResponse.statusCode, userInfo: nil))
                }
                return SignalProducer(value: data)
            })
            .attachToDataRequestView(dataRequestView!)
        dataSignalProducer?.start()
    }

    @IBAction func setLoadingButtonTapped(sender: UIButton) {
        dataRequestView?.changeRequestState(RequestState.Loading)
    }
    
    @IBAction func setEmptyButtonTapped(sender: UIButton) {
        dataRequestView?.changeRequestState(RequestState.Empty)
    }
    
    @IBAction func setReloadButtonTapped(sender: UIButton) {
        dataRequestView?.changeRequestState(RequestState.Failed)
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}

extension ViewController : ALDataRequestViewDataSource {
    func loadingViewForDataRequestView(dataRequestView: ALDataRequestView) -> UIView {
        let loadingView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        loadingView.startAnimating()
        return loadingView
    }
    
    func reloadViewControllerForDataRequestView(dataRequestView: ALDataRequestView) -> ALDataReloadType {
        let reloadVC = ReloadViewController()
        return reloadVC
    }
    
    func emptyViewForDataRequestView(dataRequestView: ALDataRequestView) -> UIView {
        let emptyLabel = UILabel(forAutoLayout: ())
        emptyLabel.text = "Data is empty"
        return emptyLabel
    }
}

final class ReloadViewController : UIViewController, ALDataReloadType {
    
    var retryButton:UIButton!
    var statusLabel:UILabel!
    
    init(){
        super.init(nibName: nil, bundle: nil)
        
        retryButton = UIButton(type: UIButtonType.System)
        retryButton.setTitle("Reload!", forState: UIControlState.Normal)
        view.addSubview(retryButton)
        retryButton.autoCenterInSuperview()
        
        statusLabel = UILabel(forAutoLayout: ())
        view.addSubview(statusLabel)
        statusLabel.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
        statusLabel.autoPinEdge(.Bottom, toEdge: .Top, ofView: retryButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupForReloadType(reloadType: ReloadReason) {
        switch reloadType {
        case .GeneralError:
            statusLabel.text = "General error occured"
        case .NoInternetConnection:
            statusLabel.text = "Your internet connection is lost"
        }
    }
    
}

