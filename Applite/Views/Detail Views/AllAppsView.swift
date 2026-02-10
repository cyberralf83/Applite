//
//  AllAppsView.swift
//  Applite
//
//  Created by Claude on 2026.02.09.
//

import SwiftUI

struct AllAppsView: View {
    @ObservedObject var caskCollection: SearchableCaskCollection
    @State var searchText = ""

    private var displayedCasks: [Cask] {
        let source = caskCollection.casks
        if searchText.isEmpty {
            return source.sorted()
        }
        return source.filter {
            $0.info.name.localizedCaseInsensitiveContains(searchText) ||
            $0.info.token.localizedCaseInsensitiveContains(searchText)
        }.sorted()
    }

    var body: some View {
        VStack {
            AppGridView(casks: displayedCasks, appRole: .installAndManage)
        }
        .navigationTitle("All Apps")
        .modify { view in
            if #available(macOS 26.0, *) {
                view.searchable(text: $searchText, placement: .toolbarPrincipal)
            } else {
                view.searchable(text: $searchText, placement: .toolbar)
            }
        }
    }
}
