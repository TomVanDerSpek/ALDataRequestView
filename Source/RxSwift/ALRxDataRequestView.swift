//
//  ALRxDataRequestView.swift
//  Pods
//
//  Created by Antoine van der Lee on 28/02/16.
//
//

import RxSwift
import RxCocoa

public extension ObservableType {
    
    func attachToDataRequestView(dataRequestView:ALDataRequestView) -> Observable<E> {
        let observable = Observable.using({ () in
            return AnonymousDisposable({
                // Dispose the observer that's observing the observer
            })
            }, observableFactory: { [weak dataRequestView] (_) -> Observable<E> in
                dataRequestView?.changeRequestState(.Loading)
                return self.observeOn(MainScheduler.instance)
                    .doOn(onNext: { [weak dataRequestView] (object) in
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
            })
        
        dataRequestView.retryAction = { [weak dataRequestView] () -> Void in
            if let dataRequestView = dataRequestView {
                observable.takeUntil(dataRequestView.rx_deallocated).subscribe()
            }
        }
        
        return observable
    }
}