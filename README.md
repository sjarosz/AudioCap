# AudioCap

`AudioCap` is a macOS utility that demonstrates how to use the new Core Audio APIs, introduced in macOS 14.4, to capture and record the audio output of any running application. It serves as a comprehensive, modern example, wrapping the complexity of Core Audio in a clean, user-friendly SwiftUI interface.

https://github.com/insidegui/AudioCap/assets/67184/95d72d1f-a4d6-4544-9d2f-a2ab99507cfc

## How It Works

The application provides a complete, user-facing tool for recording audio from other apps.

1.  **Permission Handling**: On launch, the app first checks for audio capture permissions. If they are not granted, it presents a view to guide the user through the process.

2.  **Process Discovery and Display**:
    *   Once permission is granted, the main window lists all running applications capable of producing audio.
    *   It intelligently separates these into "Common Meeting Apps" (like Zoom, Teams, and Slack) and "Other Audio Processes" for easier navigation.
    *   It actively polls applications and displays a live indicator (a green dot) next to any process currently outputting sound.

3.  **Recording**:
    *   A "record" button appears next to any application that is actively making sound.
    *   Clicking this button instantly starts a new recording, saving a `.wav` file to `~/Library/Application Support/AudioCap/`.
    *   While recording, the button transforms into a pulsating "stop" icon. Clicking it ends the recording and finalizes the file.
    *   Users can right-click the recording button to reveal the audio file's location in Finder.

This project is a practical reference for developers looking to implement application-specific audio capture on macOS.

Thanks to [@WFT](https://github.com/WFT) for helping me with this project.
