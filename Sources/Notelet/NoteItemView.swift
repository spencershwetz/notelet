//
//  NoteItemView.swift
//  Notelet
//
//  Created by Mykola Harmash on 05.05.26.
//

import SwiftUI

struct NoteItemView: View {
    let item: NoteletVersionNoteItem
    let isCurrent: Bool
    let configuration: NoteletConfiguration
    
    private var clipShapeRadius: Double {
        if #available(iOS 26, *) {
            24
        } else {
            12
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            itemContent(containerWidth: min(max(proxy.size.width, 300), 440))
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: 520, alignment: .top)
    }

    @ViewBuilder
    private func itemContent(containerWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch item {
            case .media(let mediaKind, let url, let title, let description):
                VStack(alignment: .center, spacing: 12) {
                    let mediaPadding = 16.0
                    
                    ZStack {
                        switch mediaKind {
                        case .image:
                            MediaNoteItemImageView(
                                imageUrl: url
                            )
                        case .video:
                            MediaNoteItemVideoView(
                                videoURL: url,
                                isPlaying: isCurrent
                            )
                        }
                    }
                    .frame(
                        width: containerWidth - mediaPadding * 2,
                        height: containerWidth - mediaPadding * 2
                    )
                    .clipShape(.rect(cornerRadius: clipShapeRadius))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 0)
                    .padding(mediaPadding)
                    
                    MediaNoteItemDetailsView(
                        title: title,
                        description: description
                    )
                    
                    Spacer()
                }
            case .list(let title, let rows):
                BulletListNoteItemView(
                    title: title,
                    rows: rows,
                    accentColor: configuration.accentColor
                )
            }
        }
    }
}
