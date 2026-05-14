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
            await prepareVideo()
        }
        .onChange(of: isPlaying) { newValue in
            updatePlaybackState(shouldPlay: newValue)
        }
        .onDisappear {
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
                videoPlayer.seek(to: .zero)
                if isPlaying {
                    videoPlayer.play()
                }
            }
        }

        updatePlaybackState(shouldPlay: isPlaying)
    }

    private func updatePlaybackState(shouldPlay: Bool) {
        if shouldPlay {
            guard let player, player.currentItem != nil else {
                Task {
                    await prepareVideo()
                }
                return
            }

            if let item = player.currentItem,
               item.duration.isNumeric,
               player.currentTime() >= item.duration {
                player.seek(to: .zero)
            }

            player.play()
        } else {
            player?.pause()
        }
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
