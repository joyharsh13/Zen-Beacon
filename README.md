# Zen Beacon
SDK created to scan Beacons

## Example
Retrieve Zen Beacon


import Zen_Beacon


```Swift
var Zen_Beacon:ZenBeaconScanner()
```

Configure beacon region to scan
```Swift
let uuidString = "2EDB7643-3B2D-488A-90D9-FC9A1F67EF6B"
let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)!

let beaconService = UAIBeaconService(name: "apple", serviceUUID: beaconUUID)

beaconManager = UAIBeaconManager()
beaconManager.delegate = self
beaconManager.BeaconServices = [beaconService]
```

Start scan
```swift
beaconManager.startScan()
```

Receive listener calls
```swift
UAIBeaconManagerDelegate
```
```swift
func BeaconManagerIBeaconsDetectedChanged(Beacons: [UAIBeacon]) 
{
  // Updated when detected beacons change
}
```

API Access Token
```swift
ApiHelper.access_token = "95ac2da6a85c8ac3914fe22366380a27"
```

Get offers
```swift
// This method needs a internet connection

// method: getOffers
// param: beacon:UAIBeacon - Beacon to get offers
ApiHelper.getOffers(beacon!, success: { (responseObject) -> Void in

  // Success
  // return: responseObject:Poin - Founded beacon object

}) { (error) -> Void in
  
  // Failure
  // return: error:NSError - Detail of error
}
```

Stop scan
```swift
beaconManager.stopScan()
```


Extras
```swift
//Debug mode (false by default)
beaconManager.debugMode = true

//Major and minor beacon range
beaconService.majorValue = 1001
beaconService.minorValue = 1024
```

##Developed by
Renan Bozzeda

##License
```
Copyright 2015 Hive Digital Media

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

