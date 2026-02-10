//
//  PlaceholderAppView.swift
//  Applite
//
//  Created by Milán Várady on 2022. 12. 21..
//

import SwiftUI

/// A placeholder app view shown while the apps are being loaded in
struct PlaceholderAppView: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.gray, lineWidth: 3)
                .frame(width: 40, height: 40)
                .padding(.leading, 2)
            
            // Placeholder text lines
            VStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray)
                    .frame(width: 140, height: 10)
                    .padding(.bottom, 2)
                
                Rectangle()
                    .fill(.gray)
                    .frame(width: 180, height: 3)
                
                Rectangle()
                    .fill(.gray)
                    .frame(width: 160, height: 3)
            }
            
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(width: AppView.dimensions.width, height: AppView.dimensions.height)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
    }
}

struct PlaceholderAppView_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderAppView()
            .frame(width: AppView.dimensions.width, height: AppView.dimensions.height)
    }
}
