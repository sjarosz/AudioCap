import SwiftUI

@MainActor
struct ProcessSelectionView: View {
    @State private var processController = AudioProcessController()
    @State private var tap: ProcessTap?
    @State private var recorder: ProcessTapRecorder?
    @State private var selectedProcess: AudioProcess?
    @State private var timer: Timer? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading) {
            Text("Audio Processes")
                .font(.headline)
                .padding(.bottom, 4)
            List {
                ForEach(processController.processGroups) { group in
                    Section(header: Text(group.title)) {
                        ForEach(group.processes.filter { $0.id != ProcessInfo.processInfo.processIdentifier }) { process in
                            HStack {
                                Image(nsImage: process.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                Text(process.name)
                                    .font(.body)
                                Spacer()
                                // Indicator for audio activity
                                Circle()
                                    .fill(process.audioActive ? Color.green : Color.gray)
                                    .frame(width: 12, height: 12)
                                    .padding(.trailing, 4)
                                // Record button only if process is active
                                if process.audioActive {
                                    if let recorder, recorder.isRecording, recorder.process.id == process.id {
                                        // Pulsating/animated record icon for active recording
                                        PulsatingRecordButton(action: { recorder.stop() }, showFile: {
                                            NSWorkspace.shared.activateFileViewerSelecting([recorder.fileURL])
                                        })
                                    } else {
                                        // Static record icon for ready to record
                                        Button(action: {
                                            startRecording(for: process)
                                        }) {
                                            Image(systemName: "record.circle")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minHeight: 300)
            .onAppear {
                processController.activate()
                startPolling()
            }
            .onDisappear {
                stopPolling()
            }
        }
        if let errorMessage {
            Text(errorMessage)
                .font(.headline)
                .foregroundStyle(.red)
        }
        if let recorder {
            RecordingView(recorder: recorder)
                .onChange(of: recorder.isRecording) { wasRecording, isRecording in
                    if wasRecording, !isRecording {
                        self.recorder = nil
                        self.tap = nil
                    }
                }
        }
    }

    private func startRecording(for process: AudioProcess) {
        let newTap = ProcessTap(process: process)
        self.tap = newTap
        newTap.activate()
        let filename = "\(process.name)-\(Int(Date.now.timeIntervalSinceReferenceDate))"
        let audioFileURL = URL.applicationSupport.appendingPathComponent(filename, conformingTo: .wav)
        let newRecorder = ProcessTapRecorder(fileURL: audioFileURL, tap: newTap)
        self.recorder = newRecorder
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                processController.activate() // This will refresh process list and audioActive
            }
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}

extension URL {
    static var applicationSupport: URL {
        do {
            let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let subdir = appSupport.appending(path: "AudioCap", directoryHint: .isDirectory)
            if !FileManager.default.fileExists(atPath: subdir.path) {
                try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
            }
            return subdir
        } catch {
            assertionFailure("Failed to get application support directory: \(error)")
            return FileManager.default.temporaryDirectory
        }
    }
}

struct PulsatingRecordButton: View {
    var action: () -> Void
    var showFile: (() -> Void)? = nil
    @State private var animate = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "record.circle.fill")
                .foregroundColor(.red)
                .scaleEffect(animate ? 1.2 : 1.0)
                .shadow(color: .red.opacity(0.6), radius: animate ? 12 : 4)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animate)
        }
        .buttonStyle(BorderlessButtonStyle())
        .onAppear { animate = true }
        .onDisappear { animate = false }
        .help("Recording… Click to stop.")
        .contextMenu {
            Button("Stop Recording", action: action)
            if let showFile {
                Button("Show File Location", action: showFile)
            }
        }
    }
}


