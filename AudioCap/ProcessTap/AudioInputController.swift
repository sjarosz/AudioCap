import SwiftUI
import CoreAudio
import OSLog

struct AudioDevice: Identifiable, Hashable, Sendable {
    var id: AudioObjectID
    var uid: String
    var name: String
}

@MainActor
@Observable
final class AudioInputController {
    private let logger = Logger(subsystem: kAppSubsystem, category: "AudioInputController")
    private(set) var devices = [AudioDevice]()

    func activate() {
        logger.debug("Activating audio input controller")
        do {
            let allDeviceIDs = try AudioObjectID.system.readDeviceList()
            var availableDevices = [AudioDevice]()

            for deviceID in allDeviceIDs {
                guard deviceID.isInputDevice() else { continue }

                // Also check if it's an aggregate device and skip it
  //              if (try? deviceID.read(kAudioDevicePropertyComposition, defaultValue: [:] as CFDictionary)) != nil {
  //                  if let dict = (try? deviceID.read(kAudioDevicePropertyComposition, defaultValue: [:] as //CFDictionary)) as? [String: Any], !dict.isEmpty {
        //                logger.debug("Skipping aggregate device: \(try! deviceID.readDeviceName())")
          //              continue
            //        }
              //  }
                
                do {
                    let uid = try deviceID.readDeviceUID()
                    let name = try deviceID.readDeviceName()
                    availableDevices.append(AudioDevice(id: deviceID, uid: uid, name: name))
                    logger.debug("Found available input device: \(name)")
                } catch {
                    logger.warning("Failed to get info for device \(deviceID): \(error)")
                }
            }

            self.devices = availableDevices
        } catch {
            logger.error("Failed to activate audio input controller: \(error)")
        }
    }
} 
