//
//  ContentView.swift
//  SongTracker
//
//  Created by Balint Follinus on 13/03/2025.
//

import SwiftUI
import MediaPlayer
import AVFoundation
import BackgroundTasks

struct ContentView: View {
    @State private var currentSong: String = "No song playing"
    @State private var currentArtist: String = ""
    @State private var isPlaying: Bool = false
    @State private var player: AVAudioPlayer?
    
    var body: some View {
        VStack {
            Text(currentSong)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
            
            if !currentArtist.isEmpty {
                Text(currentArtist)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(isPlaying ? "Playing" : "Not Playing")
                .foregroundColor(isPlaying ? .green : .red)
                .padding()
        }
        .padding()
        .onAppear {
            setupBackgroundTasks()
            setupMediaPlayer()
            setupBackgroundAudio()
        }
    }
    
    private func setupBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.songtracker.refresh", using: nil) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
        scheduleBackgroundTask()
    }
    
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.songtracker.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // Schedule for 1 minute from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled successfully")
        } catch {
            print("Failed to schedule background task: \(error)")
        }
    }
    
    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        // Create an operation that updates the now playing info
        task.expirationHandler = {
            // Handle task expiration
        }
        
        updateNowPlaying()
        scheduleBackgroundTask() // Schedule the next background refresh
        task.setTaskCompleted(success: true)
    }
    
    private func setupMediaPlayer() {
        // Request media library authorization
        MPMediaLibrary.requestAuthorization { status in
            if status == .authorized {
                // Setup notifications for music player
                let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                
                NotificationCenter.default.addObserver(
                    forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
                    object: musicPlayer,
                    queue: .main
                ) { _ in
                    updateNowPlaying()
                }
                
                NotificationCenter.default.addObserver(
                    forName: .MPMusicPlayerControllerPlaybackStateDidChange,
                    object: musicPlayer,
                    queue: .main
                ) { _ in
                    updatePlaybackState()
                }
                
                musicPlayer.beginGeneratingPlaybackNotifications()
                updateNowPlaying()
                updatePlaybackState()
            }
        }
    }
    
    private func setupBackgroundAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Load and play silent audio to keep the app running in background
            if let url = Bundle.main.url(forResource: "silence", withExtension: "mp3") {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1 // Loop indefinitely
                player?.volume = 0.0
                player?.play()
            }
        } catch {
            print("Failed to setup background audio: \(error)")
        }
    }
    
    private func updateNowPlaying() {
        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
        if let nowPlaying = musicPlayer.nowPlayingItem {
            let song = nowPlaying.title ?? "Unknown Song"
            let artist = nowPlaying.artist ?? "Unknown Artist"
            
            // Only send to API if both song and artist are not "Unknown"
            if song != "Unknown Song" && artist != "Unknown Artist" {
                currentSong = song
                currentArtist = artist
                sendToAPI(song: song, artist: artist)
            }
        } else {
            currentSong = "No song playing"
            currentArtist = ""
        }
    }
    
    private func updatePlaybackState() {
        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
        isPlaying = musicPlayer.playbackState == .playing
    }
    
    private func sendToAPI(song: String, artist: String) {
        guard let url = URL(string: Config.apiEndpoint) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.apiKey, forHTTPHeaderField: "X-API-Key")
        
        let payload = [
            "song": song,
            "artist": artist
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            print("Sending payload: \(payload)")
        } catch {
            print("Error creating JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending data to API: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("API Response Status: \(httpResponse.statusCode)")
                
                if let data = data,
                   let responseString = String(data: data, encoding: .utf8) {
                    print("API Response Body: \(responseString)")
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
