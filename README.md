# SongTracker




# SongTracker

A system to track and display your currently playing songs from iOS.

Author: Balint Follinus (balintfollinus@gmail.com)

## Components

### iOS App
The iOS app monitors currently playing songs on your device and sends them to the Cloudflare Worker API.

Features:
- Detects currently playing songs
- Handles background audio monitoring
- Automatic duplicate prevention
- Efficient API communication

## Setup

### iOS App
1. Open `ios-app/SongTracker.xcodeproj` in Xcode
2. Build and run on your iOS device
3. Grant media permissions when prompted


## Development

### iOS App
The app is built with SwiftUI and uses:
- MediaPlayer framework for song detection
- AVFoundation for background operation
- URLSession for API communication


## Architecture
```
[iOS App] -----> [Cloudflare Worker] -----> [KV Storage]
     ↑                     ↓
Detects songs     Serves web interface
```

Note; you have to build the endpoint api yourself. I personally used cloudflare workers because they were easy to deploy.

Plug secret API_KEY and endpoint in config.example.swift, then rename it to config.swift.



You have to use xcode in order to install the application onto your iPhone. Furthermore, I've built this for apple music.
