//
//  ContentView.swift
//  CurrenSee
//
//  Created by EVYATAR DAYAN on 03/06/2025.
//

import SwiftUI

enum ConverterTab: String, CaseIterable {
    case manual = "Manual"
    case camera = "Camera"

    static let defaultViewStorageKey = "defaultConverterView"

    static func fromStoredDefault(_ value: String) -> ConverterTab {
        value == "camera" ? .camera : .manual
    }

    var storedDefaultValue: String {
        self == .camera ? "camera" : "manual"
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CurrencyConverterViewModel()
    @StateObject private var cameraScanner = CameraTextScanner()
    @State private var selectedTab: ConverterTab
    @State private var showingCurrencySelection = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    init() {
        let storedDefault = UserDefaults.standard.string(forKey: ConverterTab.defaultViewStorageKey) ?? "manual"
        _selectedTab = State(initialValue: ConverterTab.fromStoredDefault(storedDefault))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    ZStack {
                        manualConverterContent
                            .opacity(selectedTab == .manual ? 1 : 0)
                            .allowsHitTesting(selectedTab == .manual)
                            .zIndex(selectedTab == .manual ? 1 : 0)

                        CameraScanView(viewModel: viewModel, scanner: cameraScanner)
                            .opacity(selectedTab == .camera ? 1 : 0)
                            .allowsHitTesting(selectedTab == .camera)
                            .zIndex(selectedTab == .camera ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, selectedTab == .camera ? 16 : 0)
                .padding(.bottom, selectedTab == .camera ? 16 : 0)
                .padding(.top, 4)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink {
                            SettingsView(viewModel: viewModel)
                        } label: {
                            Image(systemName: "gearshape.circle")
                                .foregroundColor(.appRed)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        ConverterTabPicker(selection: Binding(
                            get: { selectedTab },
                            set: { newTab in
                                if newTab != .manual {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = newTab
                                }
                                if newTab == .camera {
                                    cameraScanner.activate()
                                } else {
                                    cameraScanner.deactivate()
                                }
                            }
                        ))
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingCurrencySelection = true
                        }) {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.appRed)
                        }
                    }
                }
                .overlay {
                    if showingCurrencySelection {
                        Color.clear
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingCurrencySelection = false
                            }
                    }
                }
                .sheet(isPresented: $showingCurrencySelection) {
                    CurrencySelectionView(viewModel: viewModel)
                }
                .onAppear {
                    cameraScanner.prepare()
                    if selectedTab == .camera {
                        cameraScanner.activate()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }

    private var manualConverterContent: some View {
        ManualConverterView(viewModel: viewModel)
    }

}

struct ConverterTabPicker: View {
    @Binding var selection: ConverterTab
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ConverterTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selection == tab ? .semibold : .regular)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .background {
                            if selection == tab {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(isDarkMode ? Color(.systemGray4) : Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
        .frame(width: 220)
        .padding(.top, 35)
        .contentShape(Rectangle())
    }
}

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: Currency
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.allCurrencies
        } else {
            return Currency.allCurrencies.filter { currency in
                currency.code.localizedCaseInsensitiveContains(searchText) ||
                currency.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search Currency", text: $searchText)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)

                List(filteredCurrencies) { currency in
                    Button(action: {
                        selectedCurrency = currency
                        dismiss()
                    }) {
                        HStack {
                            Text(currency.flag)
                                .font(.title2)
                            Text(currency.code)
                                .font(.headline)
                            Text(currency.name)
                                .foregroundColor(.gray)
                            Spacer()
                            if currency.code == selectedCurrency.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appRed)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
