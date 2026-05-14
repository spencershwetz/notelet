//
//  SwiftUIView.swift
//  Notelet
//
//  Created by Mykola Harmash on 05.05.26.
//

import SwiftUI

struct NoteletSheetContentView: View {
    let versionNotes: [NoteletVersionNoteItem]
    let configuration: NoteletConfiguration
    
    @State private var selectedPageID = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var currentPage: Int {
        return selectedPageID
    }
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var sheetBackgroundStyle: AnyShapeStyle {
        if #available(iOS 26, *) {
            let color: Color = colorScheme == .dark ? .black : .white
            
            return AnyShapeStyle(color.opacity(0.55))
        }

        return AnyShapeStyle(.regularMaterial)
    }
    
    var body: some View {
        let isOnLastPage = isOnLastPage(versionNotes: versionNotes, currentPage: currentPage)
        
        NavigationStack {
            TabView(selection: $selectedPageID) {
                ForEach(Array(versionNotes.enumerated()), id: \.offset) { index, item in
                    ScrollView(.vertical) {
                        NoteItemView(
                            item: item,
                            isCurrent: index == currentPage,
                            configuration: configuration
                        )
                        .padding(.bottom, 80)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .modifier(
            SafeAreaView {
                VStack(spacing: 16) {
                    if versionNotes.count > 1 {
                        let selectedIndicatorColor = colorScheme == .light ? Color.black : Color.white
                        
                        HStack(spacing: 6) {
                            ForEach(versionNotes.indices, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentPage ? selectedIndicatorColor.opacity(0.35) : Color.secondary.opacity(0.35))
                                    .frame(width: index == currentPage ? 14 : 7, height: 7)
                            }
                        }
                        .padding(.top, 14)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                    
                    if !versionNotes.isEmpty {
                        Button {
                            if isOnLastPage {
                                onDoneTap()
                            } else {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedPageID = min(currentPage + 1, versionNotes.count - 1)
                                }
                            }
                        } label: {
                            let buttonTitle: LocalizedStringResource = isOnLastPage
                            ? configuration.doneButtonLabel
                            : configuration.nextButtonLabel
                            
                            Text(buttonTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 28)
                        .tint(configuration.accentColor)
                    }
                }
                .padding(.bottom, isIPad ? 24 : 0)
            }
        )
        .presentationDetents([
            isIPad ? .large : .fraction(0.85)
        ])
        .presentationDragIndicator(.visible)
        .noteletPresentationBackground(sheetBackgroundStyle)
    }
    
    private func onDoneTap() {
        dismiss()
    }
    
    private func isOnLastPage(versionNotes: [NoteletVersionNoteItem], currentPage: Int) -> Bool {
        guard !versionNotes.isEmpty else {
            return true
        }

        return currentPage >= versionNotes.count - 1
    }
}

private extension View {
    @ViewBuilder
    func noteletPresentationBackground(_ style: AnyShapeStyle) -> some View {
        if #available(iOS 16.4, *) {
            presentationBackground(style)
        } else {
            self
        }
    }
}
