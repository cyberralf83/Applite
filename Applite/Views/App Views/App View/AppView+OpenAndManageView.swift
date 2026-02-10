//
//  AppView+OpenAndManageView.swift
//  Applite
//
//  Created by Milán Várady on 2024.12.26.
//

import SwiftUI

extension AppView {
    /// Button used in the Download section, launches, uninstalls or reinstalls the app
    struct OpenAndManageView: View {
        @ObservedObject var cask: Cask
        let deleteButton: Bool

        @State var showAppNotFoundAlert = false

        var body: some View {
            // Lauch app
            AsyncButton("Open") {
                try await cask.launchApp()
            }
            .onButtonError { error in
                showAppNotFoundAlert = true
            }
            .asyncButtonStyle(.none)
            .font(.system(size: 14))
            .buttonStyle(.bordered)
            .clipShape(Capsule())
            .alert("Applite couldn't open \(cask.info.name)", isPresented: $showAppNotFoundAlert) {}

            if deleteButton {
                UninstallButton(cask: cask)
            }
        }
    }
}
