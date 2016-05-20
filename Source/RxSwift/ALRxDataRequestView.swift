//
//  ALRxDataRequestView.swift
//  Pods
//
//  Created by Antoine van der Lee on 28/02/16.
//
//

import UIKit
import RxSwift
import RxCocoa

public extension ObservableType {
    func attachToDataRequestView(dataRequestView:ALDataRequestView) -> Observable<E> {
        let observable = self.observeOn(MainScheduler.instance).doOn(onNext: { [weak dataRequestView] (object) in
            if let emptyableObject = object as? Emptyable where emptyableObject.isEmpty == true {
                dataRequestView?.changeRequestState(.Empty)
            } else if let arrayObject = object as? NSArray where arrayObject.count == 0 {
                dataRequestView?.changeRequestState(.Empty)
            } else {
                dataRequestView?.changeRequestState(.Success)
            }
        }, onError: { [weak dataRequestView] (_) in
            dataRequestView?.changeRequestState(.Failed)
        })
        
        dataRequestView.retryAction = { [weak dataRequestView] () -> Void in
            if let dataRequestView = dataRequestView {
                _ = observable.takeUntil(dataRequestView.rx_deallocated).subscribe()
            }
        }
        
        return observable
    }
}