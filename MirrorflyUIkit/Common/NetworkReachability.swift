//
//  NetworkReachability.swift
//  TabbarTest
//
//  Created by User on 12/08/21.
//

import Foundation

import Network

public final class NetworkReachability {
    
    // MARK: - Properties
    
    public static let shared = NetworkReachability()
    
    var monitor: NWPathMonitor?
    
    var isMonitoring = false
    
    public var didStartMonitoringHandler: (() -> Void)?
    
    public var didStopMonitoringHandler: (() -> Void)?
    
    public var netStatusChangeHandler: (() -> Void)?
    
    
    public var isConnected: Bool {
        guard let monitor = monitor else { return false }
        return monitor.currentPath.status == .satisfied && monitor.currentPath.status != .unsatisfied
    }
    
    
    public var interfaceType: NWInterface.InterfaceType? {
        guard let monitor = monitor else { return nil }
        
        return monitor.currentPath.availableInterfaces.filter {
            monitor.currentPath.usesInterfaceType($0.type) }.first?.type
    }
    
    public var isCellular: Bool {
            guard let monitor = monitor else { return false }
            return monitor.currentPath.usesInterfaceType(.cellular)
        }
    public var isWifi: Bool {
            guard let monitor = monitor else { return false }
            return monitor.currentPath.usesInterfaceType(.wifi)
        }
    
    var availableInterfacesTypes: [NWInterface.InterfaceType]? {
        guard let monitor = monitor else { return nil }
        return monitor.currentPath.availableInterfaces.map { $0.type }
    }
    
    
    var isExpensive: Bool {
        return monitor?.currentPath.isExpensive ?? false
    }
    
    
    // MARK: - Init & Deinit
    
    private init() {
        
    }
    
    
    deinit {
        stopMonitoring()
    }
    
    
    // MARK: - Method Implementation
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetStatus_Monitor")
        monitor?.start(queue: queue)
        
        monitor?.pathUpdateHandler = { _ in
            executeOnMainThread {
                self.netStatusChangeHandler?()
            }
        }
        
        isMonitoring = true
        executeOnMainThread {
            self.didStartMonitoringHandler?()
        }
    }
    
    
    public func stopMonitoring() {
        guard isMonitoring, let monitor = monitor else { return }
        monitor.cancel()
        self.monitor = nil
        isMonitoring = false
        executeOnMainThread {
            self.didStopMonitoringHandler?()
        }
    }
    
}
