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
Z_Beacon.delegate = self

```

Start scan
```swift
Z_Beacon.Start_Scanning(AppID: "your APP ID")
```

Receive listener calls
```swift
ZenBeaconDelegate
```
```swift
func didReceivedAdvertiseDetails(AdvertiseData: NSDictionary)
{
  print(AdvertiseData)
}

func didClickedOnAdvertise(AdvertiseData: NSDictionary)
{
  print(AdvertiseData)
}
```

Stop scan
```swift
Z_Beacon.stop_Scan()
```


Extras
```swift
//turn on Notification (false by default)
Z_Beacon.is_enable_notification = true



##Developed by
Joyharsh Christie

##License
```
Copyright 2015 ZenExim Private limited.

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

