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
    func attachToDataRequestView(dataRequestView:ALDataRequestView) -> SignalProducer<Value, Error> {
        let newSignalProducer = producer.observe(on: UIScheduler())
            .on(value: { [weak dataRequestView](object) in
                if let emptyableObject = object as? Emptyable, emptyableObject.isEmpty == true {
                    dataRequestView?.changeRequestState(state: .Empty)
                } else if let arrayObject = object as? NSArray, arrayObject.count == 0 {
                    dataRequestView?.changeRequestState(state: .Empty)
                } else {
                    dataRequestView?.changeRequestState(state: .Success)
                }
            })
            .on(started: { [weak dataRequestView] () -> () in
                dataRequestView?.changeRequestState(state: .Loading)
            })
            .on(failed: { [weak dataRequestView] (error) in
                dataRequestView?.changeRequestState(state: .Failed, error: error)
            })
        
        dataRequestView.retryAction = { () -> Void in
            newSignalProducer.start()
        }
        
        return newSignalProducer
    }
}
