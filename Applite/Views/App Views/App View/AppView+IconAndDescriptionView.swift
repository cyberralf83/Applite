//
//  AppView+IconAndDescriptionView.swift
//  Applite
//
//  Created by Milán Várady on 2024.12.26.
//

import SwiftUI

extension AppView {
    struct IconAndDescriptionView: View {
        @ObservedObject var cask: Cask
        var role: AppRole
        @AppStorage("showToken") var showToken: Bool = false

        @EnvironmentObject var caskManager: CaskManager

        @State private var showPopover = false
        @State private var showingForceInstallConfirmation = false

        var body: some View {
            HStack {
                if let iconURL = URL(string: "https://github.com/App-Fair/appcasks/releases/download/cask-\(cask.info.token)/AppIcon.png"),
                   let faviconURL = URL(string: "https://icon.horse/icon/\(cask.info.homepageURL?.host ?? "")") {
                    AppIconView(
                        iconURL: iconURL,
                        faviconURL: faviconURL,
                        cacheKey: cask.info.token
                    )
                }

                // Name and description
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Button {
                            showToken.toggle()
                        } label: {
                            Text(showToken ? cask.info.token : cask.info.name)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showPopover = true
                        } label: {
                            Text("...")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showPopover) {
                            moreActionsPopover
                        }
                        .confirmationDialog(
                            "Are you sure you want to force install \(cask.info.name)? This will override any current installation!",
                            isPresented: $showingForceInstallConfirmation
                        ) {
                            Button("Yes") {
                                caskManager.install(cask, force: true)
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                    }

                    Text(cask.info.description)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }

        @ViewBuilder
        private var moreActionsPopover: some View {
            VStack(alignment: .leading, spacing: 6) {
                // Homepage — always shown
                if let homepageLink = cask.info.homepageURL {
                    Link(destination: homepageLink) {
                        Label("Homepage", systemImage: "house")
                    }
                    .foregroundColor(.primary)
                }

                // Get Info — always shown
                GetInfoButton(cask: cask)

                if cask.isInstalled {
                    // Installed app actions
                    Button {
                        caskManager.reinstall(cask)
                    } label: {
                        Label("Reinstall", systemImage: "arrow.2.squarepath")
                    }

                    Button(role: .destructive) {
                        caskManager.uninstall(cask)
                    } label: {
                        Label("Uninstall", systemImage: "trash")
                            .foregroundStyle(.red)
                    }

                    Button(role: .destructive) {
                        caskManager.uninstall(cask, zap: true)
                    } label: {
                        Label("Uninstall & delete app data", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                } else {
                    // Not installed — force install
                    Button {
                        showingForceInstallConfirmation = true
                    } label: {
                        Label("Force Install", systemImage: "bolt.trianglebadge.exclamationmark.fill")
                    }
                }
            }
            .padding(8)
            .buttonStyle(.plain)
        }
    }
}
