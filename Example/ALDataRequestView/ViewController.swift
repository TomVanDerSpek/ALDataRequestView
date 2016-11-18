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
import RxSwift
import ReactiveSwift
import RxCocoa

class ViewController: UIViewController {

    var dataRequestView:ALDataRequestView?
    var signalProducer:SignalProducer<[String], NSError>?
    var dataSignalProducer:SignalProducer<Data, NSError>?
    var rxDisposable:RxSwift.Disposable?
    let (signal, subscriber) = Signal<[String], NSError>.pipe()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataRequestView = ALDataRequestView(forAutoLayout: ())
        view.addSubview(dataRequestView!)
        dataRequestView?.autoPinEdgesToSuperviewEdges()
        dataRequestView?.dataSource = self
        view.sendSubview(toBack: dataRequestView!)
        
        
        testWithFailureCallObservable()
//        testWithFailureCallSignalProducer()
//        testWithFailureCallObservable()
    }
    
    deinit {
        print("Deinit vc")
    }
    
    func testWithEmptySignalProducer(){
        signalProducer = SignalProducer(signal: signal).attachTo(dataRequestView: dataRequestView!)
        signalProducer?.start()
        
        delay(delay: 3.0, closure: { [weak self] () -> Void in
            let emptyArray:[String] = []
            self?.subscriber.send(value: emptyArray) // Send empty array
            self?.subscriber.sendCompleted()
        })
    }
    
    func testWithFailureCallSignalProducer(){
        let request = URLRequest(url: URL(string: "http://httpbin.org/status/400")!)
        dataSignalProducer = URLSession.shared
            .reactive.data(with: request)
            .flatMap(.latest, transform: { (data, response) -> SignalProducer<Data, NSError> in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode > 299 {
                    return SignalProducer(error: NSError(domain: "", code: httpResponse.statusCode, userInfo: nil))
                }
                return SignalProducer(value: data)
            })
            .attachTo(dataRequestView: dataRequestView!)
        dataSignalProducer?.start()
    }
    
    func testWithFailureCallObservable(){
        let request = URLRequest(url: URL(string: "http://httpbin.org/status/400")!)
        rxDisposable = URLSession.shared.rx.data(request: request).attachTo(dataRequestView: dataRequestView!).subscribe()
    }

    @IBAction func setLoadingButtonTapped(sender: UIButton) {
        dataRequestView?.changeRequestState(state: RequestState.loading)
    }
    
    @IBAction func setEmptyButtonTapped(sender: UIButton) {
        dataRequestView?.changeRequestState(state: RequestState.empty)
    }
    
    @IBAction func setReloadButtonTapped(sender: UIButton) {
        dataRequestView?.changeRequestState(state: RequestState.failed)
    }
    
    func delay(delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }
}

extension ViewController : ALDataRequestViewDataSource {
    func loadingViewForDataRequestView(dataRequestView: ALDataRequestView) -> UIView? {
        let loadingView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        loadingView.startAnimating()
        return loadingView
    }
    
    func reloadViewController(for dataRequestView: ALDataRequestView) -> ALDataReloadType? {
        let reloadVC = ReloadViewController()
        return reloadVC
    }
    
    func emptyView(for dataRequestView: ALDataRequestView) -> UIView? {
        let emptyLabel = UILabel(forAutoLayout: ())
        emptyLabel.text = "Data is empty"
        return emptyLabel
    }
    
    func hideAnimationDuration(for dataRequestView: ALDataRequestView) -> Double {
        return 0.25
    }
    
    func showAnimationDuration(for dataRequestView: ALDataRequestView) -> Double {
        return 0.25
    }
}

final class ReloadViewController : UIViewController, ALDataReloadType {
    
    var retryButton:UIButton!
    var statusLabel:UILabel!
    
    init(){
        super.init(nibName: nil, bundle: nil)
        
        retryButton = UIButton(type: UIButtonType.system)
        retryButton.setTitle("Reload!", for: UIControlState.normal)
        view.addSubview(retryButton)
        retryButton.autoCenterInSuperview()
        
        statusLabel = UILabel(forAutoLayout: ())
        view.addSubview(statusLabel)
        statusLabel.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        statusLabel.autoPinEdge(.bottom, to: .top, of: retryButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup(for reloadType:ReloadType){ 
        switch reloadType.reason {
        case .generalError:
            statusLabel.text = "General error occured"
        case .noInternetConnection:
            statusLabel.text = "Your internet connection is lost"
        }
    }
    
}

