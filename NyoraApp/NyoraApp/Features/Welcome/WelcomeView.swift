import SwiftUI
import NyoraEngine

enum SignInMode {
    case merge
    case replace
}

struct WelcomeView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var viewModel = WelcomeViewModel()
    @AppStorage("onboarding_done") private var onboardingDone = false
    
    @State private var step = 1
    @State private var alertMessage: String? = nil
    @State private var pendingIdToken: String? = nil
    @State private var showConflictDialog = false
    
    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(step == 1 ? "Welcome" : "Pick your reading sources")
                        .font(.title2.weight(.bold))
                    Spacer()
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.md)
                .background(DS.Color.secondaryBackground)
                
                ZStack {
                    if step == 1 {
                        authStep
                            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                    } else {
                        sourcesStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
            }
        }
        .confirmationDialog("Existing Data Found", isPresented: $showConflictDialog, titleVisibility: .visible) {
            Button("Keep both") { confirmSignIn(mode: .merge) }
            Button("Use cloud data") { confirmSignIn(mode: .replace) }
            Button("Cancel", role: .cancel) { pendingIdToken = nil }
        } message: {
            Text("You already have data on this device. Would you like to keep both or replace with your cloud data?")
        }
        .alert("Account", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK") { }
        } message: {
            Text(alertMessage ?? "")
        }
    }
    
    private var authStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Branding
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    Image("NyoraLogo")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())

                    Text("破壊 · Manga, anywhere the night takes you")
                        .font(.caption.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.accent)

                    Text("Read like the world can wait.")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .lineLimit(3)

                    Text("Nyora pulls hundreds of sources into one quiet shelf and remembers exactly where you stopped — on your phone, your tablet, your desk. Sign in to sync and back it up, or just start reading.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                Spacer(minLength: 40)
                
                // Buttons
                Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.md) {
                        Text("Account")
                            .font(.headline)
                        
                        Text("Your data stays tied to your account. You can also continue as a guest and sync later.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack {
                                Image("GoogleG")
                                    .renderingMode(.original)
                                Spacer()
                                Text("Sign in with Google")
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal)
                            .background(DS.Color.background, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.Color.separator, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSigningIn)
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                        
                        if viewModel.isSigningIn {
                            HStack {
                                ProgressView()
                                Text("Signing in and syncing...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        Button {
                            withAnimation { step = 2 }
                        } label: {
                            Label("Continue as guest", systemImage: "person.fill")
                        }
                        .buttonStyle(.dsSecondary)
                        
                        Button {
                            // Restore logic
                        } label: {
                            Label("Restore from backup", systemImage: "arrow.counterclockwise.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .font(.body.weight(.medium))
                        .foregroundStyle(DS.Color.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xl)
        }
    }
    
    private var sourcesStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("Enable the languages and content types you want. You can change this anytime in Settings.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    Card {
                        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                            // Languages
                            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                                Text("Languages")
                                    .font(.headline)
                                
                                SimpleFlowLayout(items: viewModel.locales) { locale in
                                    let isSelected = viewModel.selectedLocales.contains(locale)
                                    return Button {
                                        viewModel.toggleLocale(locale)
                                    } label: {
                                        Pill(text: locale.getDisplayName(), isSelected: isSelected, systemImage: isSelected ? "checkmark" : nil)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            Divider()
                            
                            // Types
                            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                                Text("Type")
                                    .font(.headline)
                                
                                SimpleFlowLayout(items: [ContentType.manga, .hentai]) { type in
                                    let isSelected = viewModel.selectedTypes.contains(type)
                                    return Button {
                                        viewModel.toggleType(type)
                                    } label: {
                                        Pill(text: type.rawValue.capitalized, isSelected: isSelected, systemImage: isSelected ? "checkmark" : nil)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    NavigationLink {
                        LocalView(embedInStack: false)
                    } label: {
                        Label("Downloaded manga", systemImage: "folder.badge.plus")
                            .font(.body.weight(.medium))
                            .foregroundStyle(DS.Color.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
            
            // Bottom Button
            VStack {
                Button {
                    viewModel.finishSetup()
                    onboardingDone = true
                } label: {
                    Text("Done")
                }
                .buttonStyle(.dsPrimary)
                .padding()
            }
            .background(DS.Color.background)
        }
    }
    
    private func signInWithGoogle() {
        viewModel.errorMessage = nil
        viewModel.isSigningIn = true
        Task {
            let result = await SupabaseGoogleAuthHelper.signInVerbose()
            switch result {
            case .success(let idToken):
                if model.hasLocalData {
                    self.pendingIdToken = idToken
                    self.showConflictDialog = true
                    viewModel.isSigningIn = false
                } else {
                    let ok = await SupabaseSync.shared.signInWithGoogle(idToken: idToken)
                    if ok {
                        await model.syncWithSupabase()
                        await MainActor.run {
                            viewModel.isSigningIn = false
                            alertMessage = "Success!"
                            withAnimation { step = 2 }
                        }
                    } else {
                        await MainActor.run {
                            viewModel.isSigningIn = false
                            viewModel.errorMessage = "Sign-in failed. Please try again."
                        }
                    }
                }
            case .failure(let error):
                await MainActor.run {
                    viewModel.isSigningIn = false
                    viewModel.errorMessage = error
                    alertMessage = "Error: " + error
                }
            }
        }
    }

    private func confirmSignIn(mode: SignInMode) {
        guard let idToken = pendingIdToken else { return }
        viewModel.isSigningIn = true
        Task {
            let ok = await SupabaseSync.shared.signInWithGoogle(idToken: idToken)
            if ok {
                if mode == .replace {
                    await model.restoreFromCloud()
                } else {
                    await model.syncWithSupabase()
                }
                await MainActor.run {
                    viewModel.isSigningIn = false
                    alertMessage = "Success!"
                    withAnimation { step = 2 }
                }
            } else {
                await MainActor.run {
                    viewModel.isSigningIn = false
                    viewModel.errorMessage = "Sign-in failed. Please try again."
                }
            }
            pendingIdToken = nil
        }
    }
}

struct SimpleFlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(self.items, id: \.self) { item in
                self.content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == self.items.last! {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if item == self.items.last! {
                            height = 0
                        }
                        return result
                    })
            }
        }.background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}
