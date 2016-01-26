//
//  DevicesViewController.swift
//  BluetoniumExample
//
//  Created by Dominggus Salampessy on 23/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import UIKit
import Bluetonium

class DevicesViewController: UITableViewController, ManagerDelegate {

    lazy var btManager: Manager = {
        let manager = Manager(background: true)
        manager.delegate = self
        return manager
    }()
    let batteryServiceModel = BatteryServiceModel()
    let heartRateServiceModel = HeartRateServiceModel()
    
    var scanButton:UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanButton = UIBarButtonItem(title: "Start", style: .Plain, target: self, action: Selector("toggleScan"))
        
        title = "Devices"
        navigationItem.rightBarButtonItem = scanButton
        tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "DeviceCell")
    }

    override func viewDidDisappear(animated: Bool) {
        scanButtonTitle("Start")
        btManager.stopScanForDevices()
    }
    
    
    // MARK: BTManagerDelegate
    
    func manager(manager: Manager, didFindDevice device: Device) {
        tableView!.reloadData()
    }
    
    func manager(manager: Manager, willConnectToDevice device: Device) {
        presentConnectedViewWithDevice(device)
    }
    
    func manager(manager: Manager, connectedToDevice device: Device) {
    }
    
    
    func manager(manager: Manager, disconnectedFromDevice device: Device, retry: Bool) {
    }
    
    // MARK: UITableViewDatasource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return btManager.foundDevices.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DeviceCell")!
        let device = btManager.foundDevices[indexPath.row]
        
        var text = "⛄️ No name"
        if let name = device.peripheral.name {
            text = name
        }
        cell.textLabel!.text = text
        cell.textLabel?.font = (device.peripheral.state == .Connected) ? UIFont.boldSystemFontOfSize(14) : UIFont.systemFontOfSize(14)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let device = btManager.foundDevices[indexPath.row]
        presentConnectedViewWithDevice(device)
        btManager.connectWithDevice(device)
    }
    
    // MARK: Private functions
    
    func toggleScan() {
        if btManager.scanning {
            btManager.stopScanForDevices()
            scanButtonTitle("Start")
        } else {
            btManager.startScanForDevices()
            scanButtonTitle("Stop")
        }
    }
    
    func scanButtonTitle(title: String) {
        scanButton?.title = title
    }
    
    func presentConnectedViewWithDevice(device: Device) {
        device.registerServiceModel(batteryServiceModel)
        device.registerServiceModel(heartRateServiceModel)
        
        let vc = ConnectedViewController(nibName: "ConnectedViewController", bundle: NSBundle.mainBundle())
        vc.btManager = btManager
        presentViewController(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
}