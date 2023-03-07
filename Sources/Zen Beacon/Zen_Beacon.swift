import UIKit
import WebKit
import CoreLocation
import CoreBluetooth
import MapKit




/// Implement this protocol to receive notifications.
@objc public protocol ZenBeaconDelegate {
    
    /// Will be called every time the CLLocationManager receives CLBeacons.
//    @objc optional func receivedAllBeacons(_ monitor: ZenBeaconScanner, beacons: [CLBeacon])
    
    /// Will be called every time the CLLOcationManager receives CLBeacons, that matches to a set list of Beacons.
//    @objc optional func receivedMatchingBeacons(_ monitor: ZenBeaconScanner, beacons: [CLBeacon])
    
    /// Will be called when the CLLocationManager reports the "did enter region" event.
//    @objc optional func didEnterRegion(_ region: CLRegion)
    
    /// Will be called when the CLLocationManager reports the "did exit region" event.
//    @objc optional func didExitRegion(_ region: CLRegion)
    
    @objc optional func didClickedOnAdvertise(AdvertiseData: NSDictionary)
    
    
    @objc optional func didReceivedAdvertiseDetails(AdvertiseData: NSDictionary)

}


open class ZenBeaconScanner: NSObject, CLLocationManagerDelegate,UNUserNotificationCenterDelegate,CBCentralManagerDelegate
{
    open var delegate: ZenBeaconDelegate?
    fileprivate let regionIdentifier = "ZenBeaconScanner"
    
    // CLLocationManager that will listen and react to Beacons.
    var Location_Manager: CLLocationManager = CLLocationManager()
    var CentralManager:CBCentralManager!
    
    var Arr_Beacon: Array<NSDictionary> = []
    
    open var is_enable_notification = false
    
    var Str_APP_ID =  ""
    
    open func Start_Scanning(AppID:String)
    {
        Str_APP_ID = AppID
        self.Get_Beacon_List(App_ID:Str_APP_ID)
    }
    
    open func Get_Beacon_List(App_ID:String)
    {
        let headers = [
            "content-type": "application/json",
            ]
        
        let parameters = ["api_unique_key":App_ID] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        let requestURL = "https://rudder.dev.qntmnet.com/wsmp/beacon-api/get-beacon-list"
        
//        print(requestURL)
        
        let request = NSMutableURLRequest(url: NSURL(string:requestURL)! as URL,cachePolicy:.useProtocolCachePolicy,timeoutInterval:45.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                if data != nil {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    if json != nil
                    {
                        let dataDict : NSDictionary = json as! NSDictionary
                        
//                        print(dataDict)

                        if dataDict["responseCode"] as! String == "200"
                        {
                            let tmp_arr = dataDict["responseData"] as! Array<NSDictionary>
                            
                            if self.Arr_Beacon != tmp_arr
                            {
                                self.Arr_Beacon = []
                                self.Arr_Beacon = dataDict["responseData"] as! Array<NSDictionary>
                                self.Ask_For_Location_Permission()
                            }
                            else
                            {
                                
                            }
                        }
                        else
                        {
                            self.Open_Alert(Title: "Zen Beacon Alert...!!", Message: dataDict["responseMsg"] as! String)
                        }
                    }
                    else
                    {
                        
                    }
                }
                else
                {
                    
                }
            }
            else
            {
                
            }
        });dataTask.resume()
    }
    
    
    var window: UIWindow?

    
    
    
    func Open_Alert(Title:String, Message: String)
    {
        let Alert = UIAlertController(title: Title, message: Message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        {
            UIAlertAction in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)

        }

        Alert.addAction(okAction)
        
        
        if let topVC = self.getTopViewController()
        {
            DispatchQueue.main.async {
                topVC.navigationController!.present(Alert, animated: true, completion: nil)
            }

        }
    }
    
    
    func Ask_For_Location_Permission()
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
                        
                        
                        let seconds = 2.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds)
                        {
                            self.timer_Get_BeaconList.invalidate()
                            self.Start_ScanningFor_BEACON()
                        }
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
    
    
    
    
    
    
    var timer_Get_BeaconList = Timer()

    func Start_ScanningFor_BEACON()
    {
        timer_Get_BeaconList = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { _ in
            self.Get_Beacon_List(App_ID: self.Str_APP_ID)
        })
        
        Location_Manager.delegate = self
        Location_Manager.activityType = .automotiveNavigation
        Location_Manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        Location_Manager.distanceFilter = 10.0
        Location_Manager.requestAlwaysAuthorization()
        
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            
            //  Can we detect the distance of a beacon?
            if CLLocationManager.isRangingAvailable() {
                
                for i in 0..<Arr_Beacon.count
                {
                    let Beacon_UUID = String(format: "%@", Arr_Beacon[i]["uuid"] as! String)
                    let Beacon_Identifier = String(format: "%@", Arr_Beacon[i]["location"] as! String)
                    let Beacon_Name = String(format: "%@", Arr_Beacon[i]["name"] as! String)
                    startScanning(uuid: UUID(uuidString: Beacon_UUID)!, major: 1, minor: 1, identifier: Beacon_Identifier, name: Beacon_Name)
                }
            }
        }
    }
    
    
    func startScanning(uuid: UUID, major: UInt16, minor: UInt16, identifier: String, name: String)
    {
        let uuidApple = uuid
        
        if #available(iOS 13.0, *)
        {
            let constraint = CLBeaconIdentityConstraint(uuid: uuidApple)
            let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            region.notifyEntryStateOnDisplay = true
            Location_Manager.startMonitoring(for: region)
            Location_Manager.startRangingBeacons(satisfying: constraint)
        }
        else
        {
            // Fallback on earlier versions
            let beaconRegion = CLBeaconRegion(proximityUUID: uuidApple, identifier: identifier)
            beaconRegion.notifyOnEntry = true;
            beaconRegion.notifyOnExit = true;
            beaconRegion.notifyEntryStateOnDisplay = true;
            Location_Manager.startMonitoring(for: beaconRegion)
            Location_Manager.startRangingBeacons(in: beaconRegion)
        }
    }
    
    
    
    
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
    
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
//        println("didStartMonitoringForRegion");
        Location_Manager.requestState(for: region);
    }
    
    
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion)
    {
        NSLog("didDetermineState: \(state)")
//        let center = UNUserNotificationCenter.current()

        var stateString = "unknown"
        if state == .inside {
            stateString = "inside"
            let beaconRegion = region as! CLBeaconRegion
            
            let Str_Beacon_UUID = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
           
            let state: UIApplication.State = UIApplication.shared.applicationState
            
            
            
            self.Get_Beacon_Advertise_Data(Beacon_UUID: String(format: "%@", beaconRegion.proximityUUID as CVarArg))

            
            if state != .active
            {
                if is_enable_notification
                {
                    let content = UNMutableNotificationContent()
                    content.title = "New Alert from Quantam Workflow"

                    let Beacon_Title = "Click here to view more details"

                    if #available(iOS 13.0, *)
                    {
                        content.body = Beacon_Title
                        content.sound = .default
                        content.userInfo = ["Beacon_UUID": Str_Beacon_UUID]
                    }
                    else
                    {
                        // Fallback on earlier versions
                        content.body = Beacon_Title
                        content.sound = .default
                        content.userInfo = ["Beacon_UUID": Str_Beacon_UUID]
                    }

                    let request = UNNotificationRequest(identifier: Str_Beacon_UUID, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
              
            }
            else
            {
            }
        }
        if state == .outside
        {
            stateString = "outside"
        }

        print("Beacon Region: \(stateString)")
    }
    
    
    var Dict_Beacon_Advertise_Data = NSDictionary()
    
    func Get_Beacon_Advertise_Data(Beacon_UUID:String)
    {
        let headers = [
            "content-type": "application/json",
            ]
        
        let parameters = ["api_unique_key":Str_APP_ID, "uuid":Beacon_UUID] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        let requestURL = "https://rudder.dev.qntmnet.com/wsmp/beacon-api/get-campaign-detail"
        
        print(requestURL)
        
        let request = NSMutableURLRequest(url: NSURL(string:requestURL)! as URL,cachePolicy:.useProtocolCachePolicy,timeoutInterval:45.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                if data != nil {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    if json != nil
                    {
                        let dataDict : NSDictionary = json as! NSDictionary
                        
                        print(dataDict)
                        
                        self.Dict_Beacon_Advertise_Data = NSDictionary()

                        if dataDict["responseCode"] as! String == "200"
                        {
                            let Dict_Beacon_Advertise_Data = dataDict["responseData"]
                            
                            self.delegate?.didReceivedAdvertiseDetails?(AdvertiseData: Dict_Beacon_Advertise_Data as! NSDictionary)

                            
                            if self.is_enable_notification
                            {
                                let content = UNMutableNotificationContent()
                                content.title = String(format: "%@", self.Dict_Beacon_Advertise_Data["name"] as! String)
                                
                                let Str_Description = String(format: "%@", self.Dict_Beacon_Advertise_Data["description"] as! String)
                                
                                if #available(iOS 13.0, *)
                                {
                                    content.body = Str_Description
                                    content.sound = .default
                                    content.userInfo = ["Beacon_UUID": Beacon_UUID]
                                }
                                else
                                {
                                    // Fallback on earlier versions
                                    content.body = Str_Description
                                    content.sound = .default
                                    content.userInfo = ["Beacon_UUID": Beacon_UUID]
                                }
                                
                                let request = UNNotificationRequest(identifier: Beacon_UUID, content: content, trigger: nil)
                                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                            }
                        }
                        else
                        {
//                            Toast(text: self.Dict_Beacon_Data["responseMessage"].stringValue).show()
                        }
                    }
                    else
                    {
                    }
                }
                else
                {
                }
            }
            else
            {
                
            }
        });dataTask.resume()
        
    }
    
    
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        let beaconRegion = region as! CLBeaconRegion
        
        let Str_Beacon_UUID = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
        
        let state: UIApplication.State = UIApplication.shared.applicationState
        
        
        self.Get_Beacon_Advertise_Data(Beacon_UUID: Str_Beacon_UUID)

       
        if state != .active
        {
            
            
            if is_enable_notification
            {
                let content = UNMutableNotificationContent()
                content.title = "New Alert from Quantam Workflow"

                let Beacon_Title = "Click here to view more details"

                if #available(iOS 13.0, *)
                {
                    content.body = Beacon_Title
                    content.sound = .default
                    content.userInfo = ["Beacon_UUID": Str_Beacon_UUID]
                }
                else
                {
                    // Fallback on earlier versions
                    content.body = Beacon_Title
                    content.sound = .default
                    content.userInfo = ["Beacon_UUID": Str_Beacon_UUID]
                }

                let request = UNNotificationRequest(identifier: Str_Beacon_UUID, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
        }
        
//        NotificationCenter.default.post(name: Finding_Deals_ViewController.Notification_Beacon_Detected, object: nil, userInfo:["Beacon_UUID":String(format: "%@", beaconRegion.proximityUUID as CVarArg) , "isImportant": true])

    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        print("GO IN HERE")
//        completionHandler(.alert)
        if #available(iOS 14.0, *) {
            completionHandler([.list, .badge, .sound])
        } else {
            // Fallback on earlier versions
            completionHandler([.badge, .sound])
        }
        print(notification.request.content.userInfo)
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        if let userInfo = response.notification.request.content.userInfo as? [String: AnyObject]
        {
            // your logic here!
            print(userInfo)
            
//            if let Beacon_UUID = userInfo["Beacon_UUID"] as? String
//            {
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//
//                let Finding_Deals_View = storyboard.instantiateViewController(withIdentifier: "Finding_Deals_View") as! Finding_Deals_ViewController
//                Finding_Deals_View.is_From_notification = true
//                Finding_Deals_View.Str_Notification_UUID = Beacon_UUID
//
//                if let topVC = UIApplication.getTopViewController() {
////                    topVC.navigationController?.pushViewController(Finding_Deals_View, animated: false)
//
////                    topVC.present(Finding_Deals_View, animated: true)
//
//
//                    let navController = UINavigationController(rootViewController: Finding_Deals_View)
//
//                    if UIDevice.current.userInterfaceIdiom == .pad
//                    {
//                        navController.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
//                    }
//                    topVC.navigationController?.present(navController, animated: true, completion: nil)
//                }
//            }
        }
    }
    
    
    
    @available(iOS 13.0, *)
    public func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint)
    {
        print(beacons.count)
    }

    
    var is_immidiate = false
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion)
    {
        print(beacons.count)
        
        if beacons.count > 0
        {
            let nearestBeacon = beacons.first!
            switch nearestBeacon.proximity {
            case .immediate:
                // Display information about the relevant exhibit.
                
                is_immidiate = true
                
//                NotificationCenter.default.post(name: Finding_Deals_ViewController.Notification_Beacon_Detected, object: nil, userInfo:["Beacon_UUID":String(format: "%@", nearestBeacon.proximityUUID as CVarArg) , "isImportant": true]);
                
                print("Immidiate")
                
//                if String(format: "%@", nearestBeacon.proximityUUID as CVarArg) == "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
//                {
//                    print("Immidiate --->> Punch")
//                }
//                else
//                {
//                    print("Immidiate --->> WATCH")
//                }
                
                break
            case .near:
                
                if is_immidiate == false
                {
//                    NotificationCenter.default.post(name: Finding_Deals_ViewController.Notification_Beacon_Detected, object: nil, userInfo:["Beacon_UUID":String(format: "%@", nearestBeacon.proximityUUID as CVarArg) , "isImportant": true]);
                }
                break
                
            default:
               
                is_immidiate = false
                break
            }
        }
    }
    
    private func applicationWillEnterForeground(application: UIApplication)
    {
//        self.Start_ScanningFor_BEACON_Deals()
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
//        self.Start_ScanningFor_BEACON_Deals()
    }
    
    
    
    
    
    
    func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }

    
}





//extension ZenBeaconScanner: CLLocationManagerDelegate,UNUserNotificationCenterDelegate,CBCentralManagerDelegate {
//
//
//
//    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
////        println("didStartMonitoringForRegion");
//        Location_Manager.requestState(for: region);
//    }
//
//
//
//    public func centralManagerDidUpdateState(_ central: CBCentralManager)
//    {
//        if central.state == .poweredOn
//        {
//            print("Bluetooth is connected")
//        }
//        else if central.state == .poweredOff
//        {
//            print("Bluetooth is not Connected.")
//        }
//    }
//
//
//    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion)
//    {
//        NSLog("didDetermineState: \(state)")
////        let center = UNUserNotificationCenter.current()
//
//        var stateString = "unknown"
//        if state == .inside {
//            stateString = "inside"
//        }
//        if state == .outside {
//            stateString = "outside"
//        }
//
//        print("Beacon Region: \(stateString)")
//
//    }
//
//    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
//    {
//        let content = UNMutableNotificationContent()
//        content.title = "Entered"
//
//        let beaconRegion = region as! CLBeaconRegion
//
//
//
//        let state = UIApplication.shared.applicationState
//
//
//        var Str_AppState = ""
//
//        if state == .background || state == .inactive
//        {
//            Str_AppState = "background"
//        }
//        else if state == .active {
//            // foreground
//            Str_AppState = "foreground"
//        }
//
//
//        if #available(iOS 13.0, *)
//        {
//            content.body = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
//            content.userInfo = ["Beacon_UUID": String(format: "%@", beaconRegion.proximityUUID as CVarArg), "AppState":Str_AppState]
//
//        }
//        else
//        {
//            // Fallback on earlier versions
//            content.body = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
//            content.userInfo = ["Beacon_UUID": String(format: "%@", beaconRegion.proximityUUID as CVarArg), "AppState":Str_AppState]
//
//        }
//        content.sound = .default
//        let request = UNNotificationRequest(identifier: "SufalamTech", content: content, trigger: nil)
//        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
//
//
//        delegate?.didEnterRegion?(region)
//
//
////        NotificationCenter.default.post(name: ViewController.Notification_Beacon_Status_Changed, object: nil, userInfo:["Message": "You Are Back in the Office", "isImportant": true])
//
//        print("You Are Back in the Office")
//
////        let alert = UIAlertController(title: "You entered in Office", message:"Message", preferredStyle: UIAlertController.Style.alert)
////
////        // add an action (button)
////        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
////
////        // show the alert
////        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
//
////        Toast(text: "You entered in Office").show()
//    }
//
//    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
//    {
//        let content = UNMutableNotificationContent()
//        content.title = "Exit"
//        let beaconRegion = region as! CLBeaconRegion
//
//
//        let state = UIApplication.shared.applicationState
//        var Str_AppState = ""
//
//        if state == .background || state == .inactive
//        {
//            Str_AppState = "background"
//        }
//        else if state == .active {
//            // foreground
//            Str_AppState = "foreground"
//        }
//
//        if #available(iOS 13.0, *)
//        {
//            content.body = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
//            content.userInfo = ["Beacon_UUID": String(format: "%@", beaconRegion.proximityUUID as CVarArg), "AppState":Str_AppState]
//
//        }
//        else
//        {
//            // Fallback on earlier versions
//            content.body = String(format: "%@", beaconRegion.proximityUUID as CVarArg)
//            content.userInfo = ["Beacon_UUID": String(format: "%@", beaconRegion.proximityUUID as CVarArg), "AppState":Str_AppState]
//
//        }
//
//        content.sound = .default
//        let request = UNNotificationRequest(identifier: "identifier", content: content, trigger: nil)
//        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
////        Toast(text: "You Exited from Office").show()
//
//        print("You are Out of the Office")
//
//        delegate?.didExitRegion?(region)
//
//
////        NotificationCenter.default.post(name: ViewController.Notification_Beacon_Status_Changed, object: nil, userInfo:["Message": "You are Out of the Office", "isImportant": true])
////
////        let alert = UIAlertController(title: "You Exited from Office", message:"Message", preferredStyle: UIAlertController.Style.alert)
////
////        // add an action (button)
////        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
////
////        // show the alert
////        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
//    }
//
//
//    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion)
//    {
////        print(beacons)
//
////        Count = Count + 1
//
//    }
//
//
//
//
//
//    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
//    {
//        print("GO IN HERE")
////        completionHandler(.alert)
//        if #available(iOS 14.0, *)
//        {
//            completionHandler([.list, .badge, .sound])
//        }
//        else
//        {
//            // Fallback on earlier versions
//            completionHandler([.badge, .sound])
//        }
//
//
//        print(notification.request.content.userInfo)
//
//    }
//
//
//
//    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
//    {
//
////        if let userInfo = response.notification.request.content.userInfo
////        {
////            print(userInfo["url"])
////
////        }
//
//
//        if let userInfo = response.notification.request.content.userInfo as? [String: AnyObject]{
//            // your logic here!
//            print(userInfo)
//
////            let content = UNMutableNotificationContent()
////            content.title = "Naresh"
////            content.body = "Harsh"
////            content.sound = .default
////
////            content.userInfo = ["UUID": "JOY" ]
////
////            let request = UNNotificationRequest(identifier: "identifier", content: content, trigger: nil)
////            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
//
//
//            delegate?.didClickedOnAdvertise?(AdvertiseData: userInfo as NSDictionary)
//        }
//    }
//
//
//
//
//
//
//}
