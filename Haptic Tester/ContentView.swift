//
//  ContentView.swift
//  Haptic Tester
//
//  Created by Paul Ruvolo on 1/30/23.
//

import SwiftUI

struct HapticDescription {
    var intensity: Float = 1.0
    var sharpness: Float = 0.1
    var attackTime: Float = 0.1
    var releaseTime: Float = 0.2
    var decayTime: Float = 0.3
}

struct HapticInfoView: View {
    @Binding var hapticDescription: HapticDescription
    var body: some View {
        VStack {
            HStack {
                Text("Intensity")
                Slider(value: $hapticDescription.intensity, in: 0...1)
            }
            HStack {
                Text("Sharpness")
                Slider(value: $hapticDescription.sharpness, in: 0...1)
            }
            HStack {
                Text("Attack Time")
                Slider(value: $hapticDescription.attackTime, in: 0...0.6)
            }
            HStack {
                Text("Release Time")
                Slider(value: $hapticDescription.releaseTime, in: 0...0.6)
            }
            HStack {
                Text("Decay Time")
                Slider(value: $hapticDescription.decayTime, in: 0...0.6)
            }
        }
    }
}

// TODO: need to refactor the view so we can have a slider per device
struct ContentView: View {
    @ObservedObject var firebase = FirebaseManager.shared
    @State var hapticDescriptions: [String: HapticDescription] = [:]
    
    let myDeviceID = UIDevice.current.identifierForVendor!.uuidString
    
    var body: some View {
        VStack {
            Text("Change Device Nickname")
            TextField("Nickname", text: $firebase.myNickname)
            Button("Submit") {
                firebase.changeNickname(deviceID: myDeviceID, newNickname: firebase.myNickname)
            }
            List(firebase.devices.sorted(by: <), id: \.key) { deviceID, name in
                VStack {
                    Text(name).onTapGesture {
                        firebase.sendHaptic(deviceID: deviceID, description: hapticDescriptions[deviceID]!)
                    }
                    HapticInfoView(hapticDescription: bindingFor(deviceID: deviceID))
                }
            }.onReceive(firebase.$devices) { value in
                for key in value.keys {
                    if hapticDescriptions[key] == nil {
                        hapticDescriptions[key] = HapticDescription()
                    }
                }
            }
        }
        .padding()
    }
    
    func bindingFor(deviceID: String) -> Binding<HapticDescription> {
        return Binding(get: {
            // we ensure that the dictionary is populated with a new HapticDescription object whenever a new device shows up in our Firebase model.  This guarantees that this lookup will not fail (hence the !).
            return hapticDescriptions[deviceID]!
        }, set: {
            self.hapticDescriptions[deviceID] = $0
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
