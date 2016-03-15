//
//  ALRxDataRequestView.swift
//  Pods
//
//  Created by Antoine van der Lee on 28/02/16.
//
//

import UIKit
import RxSwift

public extension ObservableType {
    func attachToDataRequestView(dataRequestView:ALDataRequestView) -> Observable<E> {
        let observable = self.filter({ (_) -> Bool in
            dataRequestView.changeRequestState(.Loading)
            return true
        })
            .observeOn(MainScheduler.instance)
            .doOn(onNext: { (object) in
            if let emptyableObject = object as? Emptyable where emptyableObject.isEmpty == true {
                dataRequestView.changeRequestState(.Empty)
            } else if let arrayObject = object as? NSArray where arrayObject.count == 0 {
                dataRequestView.changeRequestState(.Empty)
            } else {
                dataRequestView.changeRequestState(.Success)
            }
        }, onError: { (_) in
            dataRequestView.changeRequestState(.Failed)
        })
        
        dataRequestView.retryAction = { () -> Void in
            observable.subscribe()
        }
        
        return observable
    }
}