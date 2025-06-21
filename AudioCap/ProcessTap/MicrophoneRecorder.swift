import AVFoundation
import CoreAudio
import OSLog

@Observable
final class MicrophoneRecorder {

    let fileURL: URL
    let device: AudioDevice
    private let queue = DispatchQueue(label: "MicrophoneRecorder", qos: .userInitiated)
    private let logger: Logger

    @ObservationIgnored
    private var deviceID: AudioObjectID = .unknown
    @ObservationIgnored
    private var deviceProcID: AudioDeviceIOProcID?
    @ObservationIgnored
    private(set) var streamDescription: AudioStreamBasicDescription?
    @ObservationIgnored
    private var isRecording = false
    @ObservationIgnored
    private var currentFile: AVAudioFile?

    init(fileURL: URL, device: AudioDevice) {
        self.fileURL = fileURL
        self.device = device
        self.logger = Logger(subsystem: kAppSubsystem, category: "\(String(describing: MicrophoneRecorder.self))(\(fileURL.lastPathComponent))")
        self.deviceID = device.id
    }

    @MainActor
    func start() throws {
        logger.debug("Starting microphone recording")
        guard !isRecording else {
            logger.warning("Already recording")
            return
        }

        streamDescription = try deviceID.read(kAudioDevicePropertyStreamFormat, scope: kAudioObjectPropertyScopeInput, defaultValue: AudioStreamBasicDescription())

        guard var streamDescription else {
            throw "Mic stream description not available."
        }
        
        guard let format = AVAudioFormat(streamDescription: &streamDescription) else {
            throw "Failed to create AVAudioFormat for mic."
        }
        
        let file = try AVAudioFile(forWriting: fileURL, settings: format.settings, commonFormat: format.commonFormat, interleaved: format.isInterleaved)
        self.currentFile = file

        var err = AudioDeviceCreateIOProcIDWithBlock(&deviceProcID, deviceID, queue) { [weak self] _, inInputData, _, _, _ in
            guard let self, let currentFile = self.currentFile else { return }
            do {
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: inInputData, deallocator: nil) else {
                    throw "Failed to create PCM buffer for mic"
                }

                try currentFile.write(from: buffer)
            } catch {
                self.logger.error("Mic recording failed: \(error, privacy: .public)")
            }
        }

        guard err == noErr else { throw "Failed to create mic I/O proc: \(err)" }

        err = AudioDeviceStart(deviceID, deviceProcID)
        guard err == noErr else { throw "Failed to start mic device: \(err)" }

        isRecording = true
    }

    func stop() {
        guard isRecording else { return }
        
        logger.debug("Stopping microphone recording")

        if deviceID != .unknown, let deviceProcID {
            AudioDeviceStop(deviceID, deviceProcID)
            AudioDeviceDestroyIOProcID(deviceID, deviceProcID)
        }

        currentFile = nil
        isRecording = false
        deviceProcID = nil
        deviceID = .unknown
    }
} 
