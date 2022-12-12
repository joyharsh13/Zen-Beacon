import UIKit
import WebKit
import CoreLocation
import CoreBluetooth
import MapKit




/// Implement this protocol to receive notifications.
@objc public protocol ZenBeaconDelegate {
    
    /// Will be called every time the CLLocationManager receives CLBeacons.
    @objc optional func receivedAllBeacons(_ monitor: ZenBeaconScanner, beacons: [CLBeacon])
    
    /// Will be called every time the CLLOcationManager receives CLBeacons, that matches to a set list of Beacons.
    @objc optional func receivedMatchingBeacons(_ monitor: ZenBeaconScanner, beacons: [CLBeacon])
    
    /// Will be called when the CLLocationManager reports the "did enter region" event.
    @objc optional func didEnterRegion(_ region: CLRegion)
    
    /// Will be called when the CLLocationManager reports the "did exit region" event.
    @objc optional func didExitRegion(_ region: CLRegion)
}


open class ZenBeaconScanner: NSObject,CLLocationManagerDelegate, CBCentralManagerDelegate,UNUserNotificationCenterDelegate
{
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        if central.state == .poweredOn
        {
            print("Bluetooth is connected")
        }
        else if central.state == .poweredOff
        {
            print("Bluetooth is not Connected.")
        }
    }
    
    open var delegate: ZenBeaconDelegate?
    fileprivate let regionIdentifier = "ZenBeaconScanner"
    
    
    
    // CLLocationManager that will listen and react to Beacons.
    var Location_Manager: CLLocationManager = CLLocationManager()
    var CentralManager:CBCentralManager!
    
    open func Start_Scanning()
    {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound]) {(accepted, error) in
            if !accepted {
                print("Notification access denied")
            }
        }
        
        Location_Manager = CLLocationManager()
        Location_Manager.delegate = self
        
        DispatchQueue.global().async {
            if (CLLocationManager.locationServicesEnabled())
            {
                let status: CLAuthorizationStatus
                
                if #available(iOS 14, *)
                {
                    status = self.Location_Manager.authorizationStatus
                }
                else
                {
                    status = CLLocationManager.authorizationStatus()
                }
                
                if status == .notDetermined
                {
                    print("joy")
                    self.Location_Manager.requestWhenInUseAuthorization()
                }
                else if status == .denied || status == .restricted
                {
                    self.Location_Manager.requestWhenInUseAuthorization()
                }
                else if status == .authorizedAlways || status == .authorizedWhenInUse
                {
                    if (self.Location_Manager.location?.coordinate) != nil
                    {
                        // Check for Beeacon
                        self.CentralManager = CBCentralManager()
                        self.CentralManager.delegate = self
                        self.Start_ScanningFor_BEACON()
                    }
                    else
                    {
                    }
                }
            }
            else
            {
            }
        }
    }
    
    
    func Start_ScanningFor_BEACON()
    {
        
        var Str_Beacon_UUID = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
        let Str_Beacon_Identifier = "ZenBeacon"

        
        let uuid = UUID(uuidString: Str_Beacon_UUID)!
        
        
        Location_Manager.delegate = self
        if #available(iOS 13.0, *)
        {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 1, minor: 1)
            let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: Str_Beacon_Identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            region.notifyEntryStateOnDisplay = true
            Location_Manager.startMonitoring(for: region)
            Location_Manager.startRangingBeacons(satisfying: constraint)
        }
        else
        {
            // Fallback on earlier versions
            
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: Str_Beacon_Identifier)
            beaconRegion.notifyOnEntry = true;
            beaconRegion.notifyOnExit = true;
            beaconRegion.notifyEntryStateOnDisplay = true;
            Location_Manager.startMonitoring(for: beaconRegion)
            Location_Manager.startRangingBeacons(in: beaconRegion)
        }
        
        
        
        
        
        
        Str_Beacon_UUID = "bf513d02-5ce1-411f-81f2-96d270f1cb2e"
        
        
        if #available(iOS 13.0, *)
        {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 1, minor: 1)
            let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: Str_Beacon_Identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            region.notifyEntryStateOnDisplay = true
            Location_Manager.startMonitoring(for: region)
            Location_Manager.startRangingBeacons(satisfying: constraint)
        }
        else
        {
            // Fallback on earlier versions
            
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: Str_Beacon_Identifier)
            beaconRegion.notifyOnEntry = true;
            beaconRegion.notifyOnExit = true;
            beaconRegion.notifyEntryStateOnDisplay = true;
            Location_Manager.startMonitoring(for: beaconRegion)
            Location_Manager.startRangingBeacons(in: beaconRegion)
        }
        
        
        
    }
    
    
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion)
    {
        NSLog("didDetermineState: \(state)")
//        let center = UNUserNotificationCenter.current()
        
        var stateString = "unknown"
        if state == .inside {
            stateString = "inside"
        }
        if state == .outside {
            stateString = "outside"
        }
        
        print("Beacon Region: \(stateString)")

    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        let content = UNMutableNotificationContent()
        content.title = "Entered"
        
        let beaconRegion = region as! CLBeaconRegion
        
        if #available(iOS 13.0, *)
        {
            content.body = String(format: "%@", beaconRegion.uuid as CVarArg)
        }
        else
        {
            // Fallback on earlier versions
            content.body = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: "SufalamTech", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        
        delegate?.didEnterRegion?(region)

        
//        NotificationCenter.default.post(name: ViewController.Notification_Beacon_Status_Changed, object: nil, userInfo:["Message": "You Are Back in the Office", "isImportant": true])
        
        print("You Are Back in the Office")
        
//        let alert = UIAlertController(title: "You entered in Office", message:"Message", preferredStyle: UIAlertController.Style.alert)
//
//        // add an action (button)
//        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
//
//        // show the alert
//        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        
//        Toast(text: "You entered in Office").show()
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
        let content = UNMutableNotificationContent()
        content.title = "Exit"
        let beaconRegion = region as! CLBeaconRegion
        
        if #available(iOS 13.0, *)
        {
            content.body = String(format: "%@", beaconRegion.uuid as CVarArg)
        }
        else
        {
            // Fallback on earlier versions
            content.body = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
        }

        content.sound = .default
        let request = UNNotificationRequest(identifier: "identifier", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
//        Toast(text: "You Exited from Office").show()
        
        print("You are Out of the Office")
        
        delegate?.didExitRegion?(region)

        
//        NotificationCenter.default.post(name: ViewController.Notification_Beacon_Status_Changed, object: nil, userInfo:["Message": "You are Out of the Office", "isImportant": true])
//
//        let alert = UIAlertController(title: "You Exited from Office", message:"Message", preferredStyle: UIAlertController.Style.alert)
//
//        // add an action (button)
//        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
//
//        // show the alert
//        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        print("GO IN HERE")
//        completionHandler(.alert)
        if #available(iOS 14.0, *)
        {
            completionHandler([.list, .badge, .sound])
        }
        else
        {
            // Fallback on earlier versions
            completionHandler([.badge, .sound])
        }
    }
    
    
    
    
    
    
   
    
    
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
//        let userInfo = response.notification.request.content.userInfo
//        // Print message ID.
//        if let messageID = userInfo[gcmMessageIDKey] {
//            print("Message ID: \(messageID)")
//        }
//
//        // Print full message.
//        print(userInfo)
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion)
    {
//        print(beacons)
        
//        Count = Count + 1
        
//        let content = UNMutableNotificationContent()
//        content.title = String(format: "%d", Count)
//        content.body = String(format: "%d", Count)
//        content.sound = .default
//        let request = UNNotificationRequest(identifier: "identifier", content: content, trigger: nil)
//        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
//        NotificationCenter.default.post(name: ViewController.Notification_Beacon_Status_Changed, object: nil, userInfo:["Message": "...", "isImportant": true])
        
//        if beacons.count == 0
//        {
//            Start_ScanningFor_BEACON()
//        }
//        else
//        {
//            Location_Manager.stopMonitoring(for: region)
//            Location_Manager.stopRangingBeacons(in: region)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 60.0, execute: {
//                self.Start_ScanningFor_BEACON()
//            })
//        }
    }

    
    
    
    
    
    
    
    
    

    
    
    
    
    
    
    
    
    
//
//    open var reportWhenEmpty = false
//
//    // Name that is used as the prefix for the region identifier.
//
//
//
//    /* Dictionary containing the CLBeaconRegions the locationManager is listening to. Each region is assigned to it's UUID String as the key.
//        The String key in this dictionary is used as the unique key: This means, that each CLBeaconRegion will be unique by it's UUID.
//        A CLBeaconRegion is unique by it's 'identifier' and not it's UUID. When using this default unique key a dictionary would not be necessary. */
//    fileprivate var regions = [String: CLBeaconRegion]()
//
//    // List of Beacons the monitor should listen on.
//    fileprivate var beaconsListening: [Beacon]?
    
    
    // MARK: - Init methods
    
    /**
    Init the BeaconMonitor and listen only to the given UUID.
    - parameter uuid: NSUUID for the region the locationManager is listening to.
    - returns: Instance
    */
//    public init(uuid: UUID) {
//        super.init()
//
//        regions[uuid.uuidString] = self.regionForUUID(uuid)
//    }
    
    /**
    Init the BeaconMonitor and listen to multiple UUIDs.
    - parameter uuids: Array of UUIDs for the regions the locationManager should listen to.
    - returns: Instance
    */
//    public init(uuids: [UUID]) {
//        super.init()
//
//        for uuid in uuids {
//            regions[uuid.uuidString] = self.regionForUUID(uuid)
//        }
//    }
    
    /**
    Init the BeaconMonitor and listen only to the given Beacons.
    The UUID(s) for the regions will be extracted from the Beacon Array. When Beacons with different UUIDs are defined multiple regions will be created.
    - parameter beacons: Beacon instances the BeaconMonitor is listening for
    - returns: Instance
//    */
//    public init(beacons: [Beacon]) {
//        super.init()
//
//        beaconsListening = beacons
//
//        // create a CLBeaconRegion for each different UUID
//        for uuid in distinctUnionOfUUIDs(beacons) {
//
//            regions[uuid.uuidString] = self.regionForUUID(uuid)
//        }
//    }
    
    /**
     Init the BeaconMonitor and listen to the given Beacon.
     From the Beacon values (uuid, major and minor) a concrete CLBeaconRegion will be created.
     - parameter beacon: Beacon instance the BeaconMonitor is listening for and it will be used to create a concrete CLBeaconRegion.
     - returns: Instance
     */
//    public init(beacon: Beacon) {
//        super.init()
//
//        beaconsListening = [beacon]
//
//        regions[beacon.uuid.uuidString] = self.regionForBeacon(beacon)
//    }
    
    
    // MARK: - Listen/Stop
    
    /**
    Start listening for Beacons.
    The settings are used from the init mthod.
    */
//    open func startListening() {
//
//        locationManager = CLLocationManager()
//        locationManager!.delegate = self
//
//        if CLLocationManager.authorizationStatus() == .notDetermined {
//            locationManager!.requestAlwaysAuthorization()
//        }
//    }
    
    /**
    Stop listening for all regions.
    */
//    open func stopListening() {
//        for (uuid, region) in regions {
//            stopListening(region)
//            regions[uuid] = nil
//        }
//    }
//
//    /**
//    Stop listening only for the region with the given UUID.
//    - parameter uuid: UUID of the region to stop listening for
//    */
//    open func stopListening(_ uuid: UUID) {
//        if let region = regions[uuid.uuidString] {
//            stopListening(region)
//            regions[uuid.uuidString] = nil
//        }
//    }
//
//
//    // MARK: - Private Helper
//
//    fileprivate func regionForUUID(_ uuid: UUID) -> CLBeaconRegion {
//        let region = CLBeaconRegion(proximityUUID: uuid, identifier: "\(regionIdentifier)-\(uuid.uuidString)")
//        region.notifyEntryStateOnDisplay = true
//        return region
//    }
//
//    fileprivate func regionForBeacon(_ beacon: Beacon) -> CLBeaconRegion {
//        let region = CLBeaconRegion(proximityUUID: beacon.uuid as UUID,
//                                    major: CLBeaconMajorValue(beacon.major.int32Value),
//                                    minor: CLBeaconMinorValue(beacon.minor.int32Value),
//                                    identifier: "\(regionIdentifier)-\(beacon.uuid.uuidString)")
//        region.notifyEntryStateOnDisplay = true
//        return region
//    }
//
//    fileprivate func stopListening(_ region: CLBeaconRegion) {
//        locationManager?.stopRangingBeacons(in: region)
//        locationManager?.stopMonitoring(for: region)
//    }
//
//    // http://stackoverflow.com/a/26358719/470964
//    fileprivate func distinctUnionOfUUIDs(_ beacons: [Beacon]) -> [UUID] {
//        var dict = [UUID : Bool]()
//        let filtered = beacons.filter { (element: Beacon) -> Bool in
//            if dict[element.uuid as UUID] == nil {
//                dict[element.uuid as UUID] = true
//                return true
//            }
//            return false
//        }
//
//        return filtered.map { ($0.uuid as UUID)}
//    }
}
