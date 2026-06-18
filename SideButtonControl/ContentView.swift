//
//  ContentView.swift
//  SideButtonControl
//
//  Created by Hamza Tüfekçi on 18.06.2026.
//

import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: DetectionViewModel

    var body: some View {
        DetectionView(viewModel: viewModel)
    }
}
