//
//  ALDataRequestView.swift
//  Pods
//
//  Created by Antoine van der Lee on 28/02/16.
//
//

import UIKit
import PureLayout

public typealias RetryAction = (() -> Void)

public enum RequestState {
    case Possible
    case Loading
    case Failed
    case Success
    case Empty
}

public enum ReloadReason {
    case GeneralError
    case NoInternetConnection
}

public protocol Emptyable {
    var isEmpty:Bool { get }
}

public protocol ALDataReloadType {
    var retryButton:UIButton! { get set }
    func setupForReloadType(reloadType:ReloadReason)
}

public protocol ALDataRequestViewDataSource : class {
    func loadingViewForDataRequestView(dataRequestView: ALDataRequestView) -> UIView
    func reloadViewControllerForDataRequestView(dataRequestView: ALDataRequestView) -> ALDataReloadType
    func emptyViewForDataRequestView(dataRequestView: ALDataRequestView) -> UIView
}

public class ALDataRequestView: UIView {

    // Public properties
    public weak var dataSource:ALDataRequestViewDataSource?
    
    /// Action for retrying a failed situation
    /// Will be triggered by the retry button, on foreground or when reachability changed to connected
    public var retryAction:RetryAction?
    
    /// If failed earlier, the retryAction will be triggered on foreground
    public var automaticallyRetryOnForeground:Bool = true
    
    /// If failed earlier, the retryAction will be triggered when reachability changed to reachable
    public var automaticallyRetryWhenReachable:Bool = true
    
    // Internal properties
    internal var state:RequestState = .Possible
    
    // Private properties
    private var loadingView:UIView?
    private var reloadView:UIView?
    private var emptyView:UIView?
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    internal func setup(){
        
    }
    
    // MARK: Public Methods
    public func changeRequestState(state:RequestState){
        guard state != self.state else { return }
        
        self.state = state
        
        switch state {
        case .Possible:
            resetToPossibleState()
            break
        case .Loading:
            resetToPossibleState()
            showLoadingView()
            break
        case .Failed:
            resetToPossibleState()
            showReloadView()
            break
        case .Success:
            resetToPossibleState()
            break
        case .Empty:
            resetToPossibleState()
            showEmptyView()
            break
        }
    }
    
    // MARK: Private Methods
    
    /// This will remove all views added
    private func resetToPossibleState(){
        loadingView?.removeFromSuperview()
        emptyView?.removeFromSuperview()
        reloadView?.removeFromSuperview()
    }
    
    /// This will show the loading view
    internal func showLoadingView(){
        guard let dataSourceLoadingView = dataSource?.loadingViewForDataRequestView(self) else {
            print("No loading view provided!")
            return
        }
        
        loadingView = dataSourceLoadingView
        addSubview(loadingView!)
        loadingView?.autoPinEdgesToSuperviewEdges()
    }
    
    /// This will show the reload view
    internal func showReloadView(){
        guard let dataSourceReloadType = dataSource?.reloadViewControllerForDataRequestView(self) else {
            print("No reload view provided!")
            return
        }
        
        if let dataSourceReloadView = dataSourceReloadType as? UIView {
            reloadView = dataSourceReloadView
            
        } else if let dataSourceReloadViewController = dataSourceReloadType as? UIViewController {
            reloadView = dataSourceReloadViewController.view
        }
        
        guard let reloadView = reloadView else {
            print("Could not determine reloadView")
            return
        }
        
        addSubview(reloadView)
        reloadView.autoPinEdgesToSuperviewEdges()
        dataSourceReloadType.setupForReloadType(ReloadReason.GeneralError)
        dataSourceReloadType.retryButton.addTarget(self, action: "retryButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
    }
    
    /// This will show the empty view
    internal func showEmptyView(){
        guard let dataSourceEmptyView = dataSource?.emptyViewForDataRequestView(self) else {
            print("No loading view provided!")
            return
        }
        
        emptyView = dataSourceEmptyView
        addSubview(emptyView!)
        emptyView?.autoPinEdgesToSuperviewEdges()
    }
    
    @objc private func retryButtonTapped(button:UIButton){
        guard let retryAction = retryAction else {
            print("No retry action provided")
            return
        }
        retryAction()
    }
}
