//
//  AppView+DownloadButton.swift
//  Applite
//
//  Created by Milán Várady on 2024.12.26.
//

import SwiftUI

extension AppView {
    /// Button used in the Download section, downloads the app
    struct DownloadButton: View {
        @ObservedObject var cask: Cask

        @EnvironmentObject var caskManager: CaskManager

        @State var showingBrewError = false
        @State var showCaveatsAndWarnings = false

        @State var buttonFill = false

        var body: some View {
            /// Download button
            Button {
                if cask.info.warning != nil {
                    // Show download confirmation
                    showCaveatsAndWarnings = true
                    return
                }

                caskManager.install(cask)
            } label: {
                if case .disabled(_, _) = cask.info.warning {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.red)
                        .font(.system(size: 22))
                } else {
                    Image(systemName: "arrow.down.to.line.circle\(buttonFill ? ".fill" : "")")
                        .foregroundStyle(Color.accentColor)
                        .font(.system(size: 22))
                }
            }
            .disabled(cask.info.warning?.isDisabled ?? false)
            .onHover { isHovering in
                // Hover effect
                withAnimation(.snappy) {
                    buttonFill = isHovering
                }
            }
            .alert(cask.info.warning?.title ?? "", isPresented: $showCaveatsAndWarnings) {
                Button("Download Anyway") {
                    caskManager.install(cask)
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                if let warning = cask.info.warning {
                    switch warning {
                    case .hasCaveat(let caveat):
                        Text(caveat)
                    case .deprecated(let date, let reason):
                        Text("**This app is deprecated**\n**Reason:** \(reason)\n**Date:** \(date)")
                    case .disabled(let date, let reason):
                        Text("**This app is disabled**\n**Reason:** \(reason)\n**Date:** \(date)")
                    }
                }
            }
            .alert("Broken Brew Path", isPresented: $showingBrewError) {} message: {
                Text(DependencyManager.brokenPathOrIstallMessage)
            }
        }
    }
}
