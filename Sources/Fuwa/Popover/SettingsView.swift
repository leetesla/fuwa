import FuwaCore
import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject var model: AppModel

    private var copy: FuwaCopy { model.copy }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle(copy.text(.permissions))

                PermissionSettingsRow(
                    title: copy.text(.screenRecording),
                    note: copy.text(.screenRecordingNote),
                    state: model.screenRecordingPermission,
                    copy: copy,
                    openSettings: model.openScreenRecordingSettings
                )

                Divider().padding(.horizontal, 14)

                PermissionSettingsRow(
                    title: copy.text(.accessibility),
                    note: copy.text(.accessibilityNote),
                    state: model.accessibilityPermission,
                    copy: copy,
                    openSettings: model.openAccessibilitySettings
                )

                sectionDivider
                sectionTitle(copy.text(.general))

                Picker(copy.text(.language), selection: Binding(
                    get: { model.languagePreference },
                    set: { model.setLanguage($0) }
                )) {
                    Text(copy.text(.systemLanguage)).tag(FuwaLanguagePreference.system)
                    Text("简体中文").tag(FuwaLanguagePreference.simplifiedChinese)
                    Text("English").tag(FuwaLanguagePreference.english)
                }
                .pickerStyle(.menu)
                .font(FuwaTypography.settingTitle)
                .padding(14)

                Divider().padding(.horizontal, 14)

                shortcutRow(
                    title: copy.text(.shortcut),
                    note: copy.text(.shortcutNote),
                    shortcut: model.shortcut,
                    isActive: model.shortcutIsActive,
                    isUpdating: model.isUpdatingShortcut,
                    onChange: model.proposeShortcut
                )
                .padding(14)

                Divider().padding(.horizontal, 14)

                shortcutRow(
                    title: copy.text(.layoutShortcut),
                    note: copy.text(.layoutShortcutNote),
                    shortcut: model.layoutShortcut,
                    isActive: model.layoutShortcutIsActive,
                    isUpdating: model.isUpdatingLayoutShortcut,
                    onChange: model.proposeLayoutShortcut
                )
                .padding(14)

                Divider().padding(.horizontal, 14)

                launchAtLoginControls
                .padding(14)

                sectionDivider
                sectionTitle(copy.text(.overlay))
                overlayControls
                    .padding(14)

                sectionDivider
                sectionTitle(copy.text(.softwareUpdate))
                softwareUpdateControls
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)

                sectionDivider

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        appName
                        Spacer(minLength: 8)
                        aboutButton
                        quitButton
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        appName

                        HStack(spacing: 12) {
                            Spacer()
                            aboutButton
                            quitButton
                        }
                    }
                }
                .padding(14)
            }
        }
        .scrollIndicators(.automatic)
    }

    private var appName: some View {
        Text(copy.text(.appName))
            .font(FuwaTypography.settingTitle)
    }

    @ViewBuilder
    private var softwareUpdateControls: some View {
        let state = model.softwareUpdate
        VStack(alignment: .leading, spacing: 9) {
            Text(updateStatusText(state))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(updateStatusText(state))

            if let notes = state.releaseNotes,
               state.phase == .available || state.phase == .ready {
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy.text(.releaseNotes))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ScrollView {
                        Text(notes)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 112)
                }
            }

            updateProgress(state)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    updatePrimaryAction(state)
                    updateSecondaryActions(state)
                }
                VStack(alignment: .leading, spacing: 8) {
                    updatePrimaryAction(state)
                    updateSecondaryActions(state)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func updateProgress(_ state: SoftwareUpdateState) -> some View {
        switch state.phase {
        case .checking, .installing:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel(updateStatusText(state))
        case .downloading:
            if let progress = state.downloadProgress {
                ProgressView(value: progress)
                    .accessibilityValue(Text(progress.formatted(.percent.precision(.fractionLength(0)))))
            } else {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(copy.text(.downloadingUpdate))
            }
        case .extracting:
            if let progress = state.normalizedExtractionProgress {
                ProgressView(value: progress)
                    .accessibilityValue(Text(progress.formatted(.percent.precision(.fractionLength(0)))))
            } else {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(copy.text(.extractingUpdate))
            }
        case .idle, .current, .available, .ready, .cancelled, .failed:
            EmptyView()
        }
    }

    @ViewBuilder
    private func updatePrimaryAction(_ state: SoftwareUpdateState) -> some View {
        switch state.phase {
        case .idle, .current:
            Button(copy.text(.checkForUpdates), action: model.checkForUpdates)
                .buttonStyle(FuwaQuietButtonStyle())
        case .available:
            Button(copy.text(.downloadUpdate), action: model.downloadUpdate)
                .buttonStyle(FuwaQuietButtonStyle())
        case .ready:
            Button(copy.text(.restartAndUpdate), action: model.installAndRelaunchUpdate)
                .buttonStyle(FuwaQuietButtonStyle())
                .keyboardShortcut(.defaultAction)
        case .cancelled, .failed:
            Button(copy.text(.retryUpdate), action: model.checkForUpdates)
                .buttonStyle(FuwaQuietButtonStyle())
        case .checking, .downloading, .extracting, .installing:
            EmptyView()
        }
    }

    @ViewBuilder
    private func updateSecondaryActions(_ state: SoftwareUpdateState) -> some View {
        if state.canCancel || state.phase == .available {
            Button(copy.text(.cancel), action: model.cancelUpdate)
                .buttonStyle(FuwaPlainButtonStyle())
        }
        if state.phase == .failed {
            Button(action: model.openLatestRelease) {
                Label(copy.text(.openReleasePage), systemImage: "arrow.up.right")
            }
            .buttonStyle(FuwaPlainButtonStyle())
            .fuwaLinkCursor()
            .help(copy.text(.releaseRecoveryHint))
            .accessibilityHint(copy.text(.releaseRecoveryHint))
        }
    }

    private func updateStatusText(_ state: SoftwareUpdateState) -> String {
        switch state.phase {
        case .idle:
            return "\(copy.text(.version)) \(state.currentVersion)"
        case .checking:
            return copy.text(.checkingForUpdates)
        case .current:
            return "\(copy.text(.upToDate)) \(copy.text(.version)) \(state.currentVersion)."
        case .available:
            return [copy.text(.updateAvailable), state.availableVersion]
                .compactMap { $0 }
                .joined(separator: " ")
        case .downloading:
            if let progress = state.downloadProgress {
                return "\(copy.text(.downloadingUpdate)) \(progress.formatted(.percent.precision(.fractionLength(0))))"
            }
            return copy.text(.downloadingUpdate)
        case .extracting:
            return copy.text(.extractingUpdate)
        case .ready:
            return copy.text(.readyToInstall)
        case .installing:
            return copy.text(.installingUpdate)
        case .cancelled:
            return copy.text(.updateCancelled)
        case .failed:
            return state.errorMessage ?? copy.text(.updateFailedMessage)
        }
    }

    private var aboutButton: some View {
        Button(copy.text(.about), action: model.showAbout)
            .buttonStyle(FuwaPlainButtonStyle())
    }

    private var quitButton: some View {
        Button(copy.text(.quit), action: model.quit)
            .buttonStyle(FuwaPlainButtonStyle())
            .keyboardShortcut("q", modifiers: .command)
    }

    private func shortcutRow(
        title: String,
        note: String,
        shortcut: KeyboardShortcut,
        isActive: Bool,
        isUpdating: Bool,
        onChange: @escaping (KeyboardShortcut) -> Void
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                shortcutDescription(title: title, note: note, isActive: isActive)
                Spacer(minLength: 10)
                ShortcutRecorder(
                    shortcut: shortcut,
                    isUpdating: isUpdating,
                    copy: copy,
                    onCapture: onChange
                )
                .frame(maxWidth: 170, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 10) {
                shortcutDescription(title: title, note: note, isActive: isActive)
                ShortcutRecorder(
                    shortcut: shortcut,
                    isUpdating: isUpdating,
                    copy: copy,
                    onCapture: onChange
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func shortcutDescription(
        title: String,
        note: String,
        isActive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(FuwaTypography.settingTitle)

            Text(note)
                .font(FuwaTypography.explanation)
                .foregroundStyle(FuwaAppearance.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if !isActive {
                Label(copy.text(.shortcutInactive), systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
            }
        }
    }

    private var overlayControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            if model.isLayoutModeEnabled {
                Label(copy.text(.layoutModeActive), systemImage: "move.3d")
                    .font(.caption)
                    .foregroundStyle(Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Text(copy.text(.overlayOpacity))
                    .font(FuwaTypography.settingTitle)
                Slider(
                    value: Binding(
                        get: { model.overlayOpacity },
                        set: { model.setOverlayOpacity($0) }
                    ),
                    in: 0.2...1
                )
                Text(model.overlayOpacity.formatted(.percent.precision(.fractionLength(0))))
                    .font(.callout.monospacedDigit())
                    .frame(width: 48, alignment: .trailing)
            }

            Picker(
                copy.text(.captureQuality),
                selection: Binding(
                    get: { model.captureQuality },
                    set: { model.setCaptureQuality($0) }
                )
            ) {
                Text(copy.text(.qualityEconomy)).tag(OverlayCaptureQuality.economy)
                Text(copy.text(.qualityHigh)).tag(OverlayCaptureQuality.high)
                Text(copy.text(.qualityUltra)).tag(OverlayCaptureQuality.ultra)
            }
            .pickerStyle(.menu)
            .font(FuwaTypography.settingTitle)
        }
    }

    private var launchAtLoginControls: some View {
        VStack(alignment: .leading, spacing: 7) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    launchAtLoginToggle
                    Spacer(minLength: 8)
                    if model.launchAtLoginState == .requiresApproval {
                        openLoginItemsButton
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    launchAtLoginToggle
                    if model.launchAtLoginState == .requiresApproval {
                        openLoginItemsButton
                    }
                }
            }

            if model.launchAtLoginState == .requiresApproval {
                Text(copy.text(.launchAtLoginApproval))
                    .font(.caption)
                    .foregroundStyle(Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var launchAtLoginToggle: some View {
        Toggle(
            copy.text(.launchAtLogin),
            isOn: Binding(
                get: { model.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            )
        )
        .toggleStyle(.switch)
        .font(FuwaTypography.settingTitle)
        .controlSize(.small)
        .disabled(model.isUpdatingLaunchAtLogin)
    }

    private var openLoginItemsButton: some View {
        Button(copy.text(.openLoginItems), action: model.openLoginItemsSettings)
            .buttonStyle(FuwaQuietButtonStyle())
            .help(copy.text(.openLoginItems))
            .accessibilityHint(copy.text(.launchAtLoginApproval))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(FuwaTypography.sectionTitle)
            .foregroundStyle(FuwaAppearance.secondaryText)
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 6)
            .accessibilityAddTraits(.isHeader)
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .accessibilityHidden(true)
    }
}

private struct PermissionSettingsRow: View {
    let title: String
    let note: String
    let state: FuwaPermissionState
    let copy: FuwaCopy
    let openSettings: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                permissionDescription
                Spacer(minLength: 12)
                if state == .denied {
                    openSettingsButton
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                permissionDescription
                if state == .denied {
                    openSettingsButton
                }
            }
        }
        .padding(14)
        .accessibilityElement(children: .contain)
    }

    private var permissionDescription: some View {
        VStack(alignment: .leading, spacing: 7) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    Text(title).font(FuwaTypography.settingTitle)
                    FuwaPermissionLabel(state: state, copy: copy)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(FuwaTypography.settingTitle)
                    FuwaPermissionLabel(state: state, copy: copy)
                }
            }

            Text(note)
                .font(FuwaTypography.explanation)
                .foregroundStyle(FuwaAppearance.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var openSettingsButton: some View {
        Button(copy.text(.openSettings), action: openSettings)
            .buttonStyle(FuwaQuietButtonStyle())
            .help(copy.text(.openSettings))
            .accessibilityHint(note)
    }
}
