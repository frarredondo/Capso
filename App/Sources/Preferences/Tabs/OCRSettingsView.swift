// App/Sources/Preferences/Tabs/OCRSettingsView.swift
import SwiftUI
import Vision

struct OCRSettingsView: View {
    @Bindable var viewModel: PreferencesViewModel
    @State private var supportedLanguages: [(code: String, name: String)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("OCR")
                .font(.system(size: 20, weight: .bold))

            SettingGroup(title: "Text Recognition") {
                SettingCard {
                    SettingRow(label: "Keep Line Breaks", sublabel: "Preserve original line structure") {
                        Toggle("", isOn: $viewModel.ocrKeepLineBreaks)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    SettingRow(label: "Detect Links", sublabel: "Auto-detect and linkify URLs", showDivider: true) {
                        Toggle("", isOn: $viewModel.ocrDetectLinks)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }
            }

            // TODO: Re-enable the "Language" group once OCRCoordinator actually
            // threads settings.ocrPrimaryLanguage into TextRecognizer. Today
            // TextRecognizer.swift:86 sets `request.recognitionLanguages` from
            // a local parameter and the setting value is never passed in —
            // selecting a language here would have no effect on recognition.
            // When wiring it back, also uncomment the `.onAppear` below.
            // SettingGroup(title: "Language") {
            //     SettingCard {
            //         SettingRow(label: "Primary Language", sublabel: "Auto-detect if unset") {
            //             Picker("", selection: Binding(
            //                 get: { viewModel.ocrPrimaryLanguage ?? "auto" },
            //                 set: { viewModel.ocrPrimaryLanguage = $0 == "auto" ? nil : $0 }
            //             )) {
            //                 Text("Auto").tag("auto")
            //                 ForEach(supportedLanguages, id: \.code) { lang in
            //                     Text(lang.name).tag(lang.code)
            //                 }
            //             }
            //             .frame(width: 160)
            //         }
            //     }
            // }
        }
        // .onAppear {
        //     loadSupportedLanguages()
        // }
    }

    private func loadSupportedLanguages() {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        let codes = (try? request.supportedRecognitionLanguages()) ?? []
        let locale = Locale.current
        supportedLanguages = codes.compactMap { code in
            let name = locale.localizedString(forLanguageCode: code) ?? code
            return (code: code, name: name)
        }
    }


}
