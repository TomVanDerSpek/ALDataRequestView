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
        let resourceFactory: () throws -> BooleanDisposable = { () -> BooleanDisposable in
            return BooleanDisposable()
        }
        let observableFactory:(Disposable) throws -> Observable<E> = { [weak dataRequestView] (_) throws -> Observable<E> in
            dataRequestView?.changeRequestState(state: .Loading)
            
            return self.observeOn(MainScheduler.instance)
                .do(onNext: { [weak dataRequestView] (object) in
                    if let emptyableObject = object as? Emptyable, emptyableObject.isEmpty == true {
                        dataRequestView?.changeRequestState(state: .Empty)
                    } else if let arrayObject = object as? NSArray, arrayObject.count == 0 {
                        dataRequestView?.changeRequestState(state:.Empty)
                    } else {
                        dataRequestView?.changeRequestState(state:.Success)
                    }
                }, onError: { [weak dataRequestView] (error) in
                    dataRequestView?.changeRequestState(state: .Failed, error: error)
                })
        }
        
        let observable = Observable.using(resourceFactory, observableFactory: observableFactory)

        dataRequestView.retryAction = { [weak dataRequestView] () -> Void in
            if let dataRequestView = dataRequestView {
                observable.takeUntil(dataRequestView.rx.deallocated).subscribe()
            }
        }
        
        return observable
    }
}
