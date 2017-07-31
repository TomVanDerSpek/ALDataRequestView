//
//  ALDataRequestView.swift
//  Pods
//
//  Created by Antoine van der Lee on 28/02/16.
//
//

import UIKit
import PureLayout
import ReachabilitySwift

public typealias RetryAction = (() -> Void)

public enum RequestState {
    case possible
    case loading
    case failed
    case success
    case empty
}

public enum ReloadReason {
    case generalError
    case noInternetConnection
}

public struct ReloadType {
    public var reason: ReloadReason
    public var error: Error?
}

public protocol Emptyable {
    var isEmpty:Bool { get }
}

public protocol ALDataReloadType {
    var retryButton:UIButton? { get set }
    func setup(for reloadType:ReloadType)
}

// Make methods optional with default implementations
public extension ALDataReloadType {
    func setup(for reloadType:ReloadType){ }
}

public protocol ALDataRequestViewDataSource : class {
    func loadingView(for dataRequestView: ALDataRequestView) -> UIView?
    func reloadViewController(for dataRequestView: ALDataRequestView) -> ALDataReloadType?
    func emptyView(for dataRequestView: ALDataRequestView) -> UIView?
    func hideAnimationDuration(for dataRequestView: ALDataRequestView) -> Double
    func showAnimationDuration(for dataRequestView: ALDataRequestView) -> Double
}

// Make methods optional with default implementations
public extension ALDataRequestViewDataSource {
    func loadingView(for dataRequestView: ALDataRequestView) -> UIView? { return nil }
    func reloadViewController(for dataRequestView: ALDataRequestView) -> ALDataReloadType? { return nil }
    func emptyView(for dataRequestView: ALDataRequestView) -> UIView? { return nil }
    func hideAnimationDuration(for dataRequestView: ALDataRequestView) -> Double { return 0 }
    func showAnimationDuration(for dataRequestView: ALDataRequestView) -> Double { return 0 }
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
    
    /// Set to true for debugging purposes
    public var loggingEnabled:Bool = false
    
    // Internal properties
    internal var state:RequestState = .possible
    
    // Private properties
    private var loadingView:UIView?
    private var reloadView:UIView?
    private var emptyView:UIView?
    fileprivate var reachability:Reachability?
    
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
        // Hide by default
        isHidden = true
        
        // Background color is not needed
        backgroundColor = UIColor.clear
        
        // Setup for automatic retrying
        initOnForegroundObserver()
        initReachabilityMonitoring()
        
        debugLog(logString: "Init DataRequestView")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        debugLog(logString: "Deinit DataRequestView")
    }
    
    // MARK: Public Methods
    public func changeRequestState(state:RequestState, error: Error? = nil){
        guard state != self.state else { return }
        
        layer.removeAllAnimations()
        
        self.state = state
        resetToPossibleState(completion: { [weak self] (completed) in ()
            guard let state = self?.state else { return }
            switch state {
            case .loading:
                self?.showLoadingView()
                break
            case .failed:
                self?.showReloadView(error: error)
                break
            case .empty:
                self?.showEmptyView()
                break
            default:
                break
            }
        })
    }
    
    // MARK: Private Methods
    
    /// This will remove all views added
    private func resetToPossibleState(completion: ((Bool) -> Void)?){
        UIView.animate(withDuration: dataSource?.hideAnimationDuration(for: self) ?? 0, animations: { [weak self] in ()
            self?.loadingView?.alpha = 0
            self?.emptyView?.alpha = 0
            self?.reloadView?.alpha = 0
        }) { [weak self] (completed) in
            self?.resetViews(views: [self?.loadingView, self?.emptyView, self?.reloadView])
            self?.loadingView = nil
            self?.emptyView = nil
            self?.reloadView = nil
            self?.isHidden = true
            completion?(completed)
        }
    }
    
    private func resetViews(views: [UIView?]) {
        views.forEach { (view) in
            view?.alpha = 1
            view?.removeFromSuperview()
        }
    }
    
    /// This will show the loading view
    internal func showLoadingView(){
        guard let dataSourceLoadingView = dataSource?.loadingView(for: self) else {
            debugLog(logString: "No loading view provided!")
            return
        }
        isHidden = false
        loadingView = dataSourceLoadingView
        
        // Only add if not yet added
        if loadingView?.superview == nil {
            addSubview(loadingView!)
            loadingView?.autoPinEdgesToSuperviewEdges()
            layoutIfNeeded()
        }
        
        dataSourceLoadingView.showWithDuration(duration: dataSource?.showAnimationDuration(for: self))
    }
    
    /// This will show the reload view
    internal func showReloadView(error: Error? = nil){
        guard let dataSourceReloadType = dataSource?.reloadViewController(for: self) else {
            debugLog(logString: "No reload view provided!")
            return
        }
        
        if let dataSourceReloadView = dataSourceReloadType as? UIView {
            reloadView = dataSourceReloadView
        } else if let dataSourceReloadViewController = dataSourceReloadType as? UIViewController {
            reloadView = dataSourceReloadViewController.view
        }
        
        guard let reloadView = reloadView else {
            debugLog(logString: "Could not determine reloadView")
            return
        }
        
        var reloadReason: ReloadReason = .generalError
        if let error = error as NSError?, error.isNetworkConnectionError() || reachability?.isReachable == false {
            reloadReason = .noInternetConnection
        }
        
        isHidden = false
        addSubview(reloadView)
        reloadView.autoPinEdgesToSuperviewEdges()
        dataSourceReloadType.setup(for: ReloadType(reason: reloadReason, error: error))
        
        #if os(tvOS)
            if #available(iOS 9.0, *) {
                dataSourceReloadType.retryButton?.addTarget(self, action: #selector(ALDataRequestView.retryButtonTapped), for: UIControlEvents.primaryActionTriggered)
            }
        #else
            dataSourceReloadType.retryButton?.addTarget(self, action: #selector(ALDataRequestView.retryButtonTapped), for: UIControlEvents.touchUpInside)
        #endif
        
        reloadView.showWithDuration(duration: dataSource?.showAnimationDuration(for: self))
    }
    
    /// This will show the empty view
    internal func showEmptyView(){
        guard let dataSourceEmptyView = dataSource?.emptyView(for: self) else {
            debugLog(logString: "No empty view provided!")
            // Hide as we don't have anything to show from the empty view
            isHidden = true
            return
        }
        isHidden = false
        emptyView = dataSourceEmptyView
        addSubview(emptyView!)
        emptyView?.autoPinEdgesToSuperviewEdges()
        
        dataSourceEmptyView.showWithDuration(duration: dataSource?.showAnimationDuration(for: self))
    }
    
    /// IBAction for the retry button
    @objc private func retryButtonTapped(button:UIButton){
        retryIfRetryable()
    }
    
    /// This will trigger the retryAction if current state is failed
    fileprivate func retryIfRetryable(){
        guard state == RequestState.failed else {
            return
        }
        
        guard let retryAction = retryAction else {
            debugLog(logString: "No retry action provided")
            return
        }
        
        retryAction()
    }
}

/// On foreground Observer methods.
private extension ALDataRequestView {
    func initOnForegroundObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(ALDataRequestView.onForeground), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc private func onForeground(notification:NSNotification){
        guard automaticallyRetryOnForeground == true else {
            return
        }
        retryIfRetryable()
    }
}

/// Reachability methods
private extension ALDataRequestView {
    
    func initReachabilityMonitoring() {
        reachability = Reachability()
        
        reachability?.whenReachable = { [weak self] reachability in
            guard self?.automaticallyRetryWhenReachable == true else {
                return
            }
            
            self?.retryIfRetryable()
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            debugLog(logString: "Unable to start notifier")
        }
    }
}

/// Logging purposes
private extension ALDataRequestView {
    func debugLog(logString:String){
        guard loggingEnabled else { return }
        print("ALDataRequestView: \(logString)")
    }
}

/// NSError extension
private extension NSError {
    func isNetworkConnectionError() -> Bool {
        let networkErrors = [NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet]
        
        if domain == NSURLErrorDomain && networkErrors.contains(code) {
            return true
        }
        return false
    }
}

/// UIView extension
private extension UIView {
    
    func showWithDuration(duration: Double?) {
        guard let duration = duration else {
            alpha = 1
            return
        }
        
        alpha = 0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
        })
    }
}
