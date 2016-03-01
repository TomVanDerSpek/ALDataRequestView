//
//  ALRACDataRequestView.swift
//  Pods
//
//  Created by Antoine van der Lee on 28/02/16.
//
//

import UIKit
import ReactiveCocoa

public extension SignalProducerType {
    func attachToDataRequestView(dataRequestView:ALDataRequestView) -> SignalProducer<Value, Error> {
        let newSignalProducer = producer.observeOn(UIScheduler()).on(started: { () -> () in
            dataRequestView.changeRequestState(.Loading)
            }, failed: { (error) in
                dataRequestView.changeRequestState(.Failed)
            }, completed: {
                
        }) { (object) in
            if let emptyableObject = object as? Emptyable where emptyableObject.isEmpty == true {
                dataRequestView.changeRequestState(.Empty)
            } else if let arrayObject = object as? NSArray where arrayObject.count == 0 {
                dataRequestView.changeRequestState(.Empty)
            } else {
                dataRequestView.changeRequestState(.Success)
            }
        }
        
        dataRequestView.retryAction = { () -> Void in
            newSignalProducer.start()
        }
        
        return newSignalProducer
    }
}