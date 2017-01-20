//
//  ALRACDataRequestView.swift
//  Pods
//
//  Created by Antoine van der Lee on 28/02/16.
//
//

import UIKit
import ReactiveSwift

public extension SignalProducerProtocol {
    func attachTo(dataRequestView:ALDataRequestView) -> SignalProducer<Value, Error> {
        let newSignalProducer = producer.observe(on: UIScheduler())
            .on(value: { [weak dataRequestView](object) in
                if let emptyableObject = object as? Emptyable, emptyableObject.isEmpty == true {
                    dataRequestView?.changeRequestState(state: .empty)
                } else if let arrayObject = object as? NSArray, arrayObject.count == 0 {
                    dataRequestView?.changeRequestState(state: .empty)
                } else {
                    dataRequestView?.changeRequestState(state: .success)
                }
            })
            .on(starting: { [weak dataRequestView] () -> () in
                dataRequestView?.changeRequestState(state: .loading)
            })
            .on(failed: { [weak dataRequestView] (error) in
                dataRequestView?.changeRequestState(state: .failed, error: error)
            })
        
        dataRequestView.retryAction = { () -> Void in
            newSignalProducer.start()
        }
        
        return newSignalProducer
    }
}
