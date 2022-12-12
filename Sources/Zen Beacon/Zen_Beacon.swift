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
    
    
    
    @objc optional func didClickedOnAdvertise(AdvertiseData: NSDictionary)

}


open class ZenBeaconScanner: NSObject
{
    
    
    
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
                    self.Location_Manager.requestAlwaysAuthorization()
                }
                else if status == .denied || status == .restricted
                {
                    self.Location_Manager.requestAlwaysAuthorization()
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
        
        Location_Manager.activityType = .automotiveNavigation
        Location_Manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        Location_Manager.distanceFilter = 10.0
        Location_Manager.requestAlwaysAuthorization()
        
        
        
//        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: Str_Beacon_Identifier)
//        beaconRegion.notifyOnEntry = true;
//        beaconRegion.notifyOnExit = true;
//        beaconRegion.notifyEntryStateOnDisplay = true;
//        Location_Manager.startMonitoring(for: beaconRegion)
//        Location_Manager.startRangingBeacons(in: beaconRegion)
//        
        
        
        
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
}


extension ZenBeaconScanner: CLLocationManagerDelegate,UNUserNotificationCenterDelegate,CBCentralManagerDelegate {
    
    
    
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
        
        
        
        let state = UIApplication.shared.applicationState
        
        
        var Str_AppState = ""

        if state == .background || state == .inactive
        {
            Str_AppState = "background"
        }
        else if state == .active {
            // foreground
            Str_AppState = "foreground"
        }

        
        if #available(iOS 13.0, *)
        {
            content.body = String(format: "%@", beaconRegion.uuid as CVarArg)
            content.userInfo = ["Beacon_UUID": String(format: "%@", beaconRegion.uuid as CVarArg), "AppState":Str_AppState]

        }
        else
        {
            // Fallback on earlier versions
            content.body = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
            content.userInfo = ["Beacon_UUID": String(format: "%@", beaconRegion.proximityUUID as CVarArg), "AppState":Str_AppState]

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
        
        
        let state = UIApplication.shared.applicationState
        var Str_AppState = ""
        
        if state == .background || state == .inactive
        {
            Str_AppState = "background"
        }
        else if state == .active {
            // foreground
            Str_AppState = "foreground"
        }
        
        if #available(iOS 13.0, *)
        {
            content.body = String(format: "%@", beaconRegion.uuid as CVarArg)
            content.userInfo = ["Beacon_UUID": String(format: "%@", beaconRegion.uuid as CVarArg), "AppState":Str_AppState]

        }
        else
        {
            // Fallback on earlier versions
            content.body = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
            content.userInfo = ["Beacon_UUID": String(format: "%@", beaconRegion.proximityUUID as CVarArg), "AppState":Str_AppState]

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
    
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion)
    {
//        print(beacons)
        
//        Count = Count + 1

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
        
        
        print(notification.request.content.userInfo)

    }
    
  
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        
//        if let userInfo = response.notification.request.content.userInfo
//        {
//            print(userInfo["url"])
//
//        }
        
        
        if let userInfo = response.notification.request.content.userInfo as? [String: AnyObject]{
            // your logic here!
            print(userInfo)
            
//            let content = UNMutableNotificationContent()
//            content.title = "Naresh"
//            content.body = "Harsh"
//            content.sound = .default
//
//            content.userInfo = ["UUID": "JOY" ]
//
//            let request = UNNotificationRequest(identifier: "identifier", content: content, trigger: nil)
//            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
            
            delegate?.didClickedOnAdvertise?(AdvertiseData: userInfo as NSDictionary)
        }
    }
    
    
   

    
    
}
