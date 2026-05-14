//
//  MediaItemVideoView.swift
//  Notelet
//
//  Created by Mykola Harmash on 05.05.26.
//

import SwiftUI
import AVKit
import UIKit

struct MediaNoteItemVideoView: View {
    let videoURL: URL
    let isPlaying: Bool
    
    @State private var player: AVPlayer?
    @State private var videoStatusObserver: NSKeyValueObservation?
    @State private var videoEndObserver: NSObjectProtocol?
    @State private var isVideoLoading: Bool = true
    
    var body: some View {
        ZStack {
            AspectFillVideoPlayer(player: player)
                .opacity(isVideoLoading ? 0 : 1)

            if isVideoLoading {
                ProgressView()
            }
        }
        .task(id: videoURL) {
            videoLog("task prepare url=\(videoURL.lastPathComponent) isPlaying=\(isPlaying)")
            await prepareVideo()
        }
        .onChange(of: isPlaying) { newValue in
            videoLog("isPlaying changed -> \(newValue) \(playerStateDescription())")
            updatePlaybackState()
        }
        .onDisappear {
            videoLog("onDisappear \(playerStateDescription())")
            videoStatusObserver?.invalidate()
            videoStatusObserver = nil
            if let videoEndObserver {
                NotificationCenter.default.removeObserver(videoEndObserver)
                self.videoEndObserver = nil
            }
            player?.pause()
        }
    }

    private func prepareVideo() async {
        videoLog("prepare begin \(playerStateDescription())")
        videoStatusObserver?.invalidate()
        videoStatusObserver = nil
        if let videoEndObserver {
            NotificationCenter.default.removeObserver(videoEndObserver)
            self.videoEndObserver = nil
        }

        isVideoLoading = true

        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)

        playerItem.preferredForwardBufferDuration = 2.0

        let videoPlayer = AVPlayer(playerItem: playerItem)
        videoPlayer.automaticallyWaitsToMinimizeStalling = true
        videoPlayer.actionAtItemEnd = .none

        videoStatusObserver = playerItem.observe(\.status, options: [.initial, .new]) { observedItem, _ in
            Task { @MainActor in
                videoLog("item status=\(observedItem.status.rawValue) isPlaying=\(isPlaying) \(playerStateDescription())")
                switch observedItem.status {
                case .readyToPlay, .failed:
                    isVideoLoading = false
                default:
                    break
                }
            }
        }

        player = videoPlayer
        videoEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            Task { @MainActor in
                videoLog("didPlayToEnd notification before seek \(playerStateDescription())")
                videoPlayer.seek(to: .zero)
                if isPlaying {
                    videoLog("didPlayToEnd replay")
                    videoPlayer.play()
                } else {
                    videoLog("didPlayToEnd paused because not visible")
                }
            }
        }

        videoLog("prepare complete \(playerStateDescription())")
        updatePlaybackState()
    }

    private func updatePlaybackState() {
        if isPlaying {
            guard let player, player.currentItem != nil else {
                videoLog("play requested without player/currentItem; preparing")
                Task {
                    await prepareVideo()
                }
                return
            }

            if let item = player.currentItem,
               item.duration.isNumeric,
               player.currentTime() >= item.duration {
                videoLog("play requested at/after end; seeking to zero \(playerStateDescription())")
                player.seek(to: .zero)
            }

            videoLog("play() \(playerStateDescription())")
            player.play()
        } else {
            videoLog("pause() \(playerStateDescription())")
            player?.pause()
        }
    }

    private func videoStateTime(_ time: CMTime) -> String {
        guard time.isNumeric else { return "nan" }
        return String(format: "%.3f", time.seconds)
    }

    private func playerStateDescription() -> String {
        guard let player else {
            return "player=nil"
        }

        let current = videoStateTime(player.currentTime())
        let duration = player.currentItem.map { videoStateTime($0.duration) } ?? "nil"
        let status = player.currentItem.map { "\($0.status.rawValue)" } ?? "nil"
        return "time=\(current) duration=\(duration) rate=\(player.rate) itemStatus=\(status)"
    }

    private func videoLog(_ message: String) {
        print("NOTELET_VIDEO \(message)")
    }
}

fileprivate struct AspectFillVideoPlayer: UIViewRepresentable {
    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }
    }
    
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.backgroundColor = UIColor.clear.cgColor
        view.playerLayer.isOpaque = false
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
    }
}
