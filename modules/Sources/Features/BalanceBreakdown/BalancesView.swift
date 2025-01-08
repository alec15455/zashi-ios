//
//  BalancesView.swift
//  secant-testnet

import SwiftUI
import ComposableArchitecture
import ZcashLightClientKit
import Generated
import PartialProposalError
import UIComponents
import Utils
import Models
import BalanceFormatter
import SyncProgress
import WalletBalances
import Combine

public struct BalancesView: View {
    @Perception.Bindable var store: StoreOf<Balances>
    let tokenName: String
    
    @Shared(.appStorage(.sensitiveContent)) var isSensitiveContentHidden = false
    @Shared(.inMemory(.walletStatus)) public var walletStatus: WalletStatus = .none

    public init(store: StoreOf<Balances>, tokenName: String) {
        self.store = store
        self.tokenName = tokenName
    }
    
    public var body: some View {
        ScrollView {
            WithPerceptionTracking {
                VStack(spacing: 24) {
                    // Top Balance Section
                    WalletBalancesView(
                        store: store.scope(
                            state: \.walletBalancesState,
                            action: \.walletBalances
                        ),
                        tokenName: tokenName,
                        underlinedAvailableBalance: false,
                        couldBeHidden: true
                    )
                    .padding(.horizontal, 20)
                    
                    // Enhanced Divider
                    Divider()
                        .background(
                            LinearGradient(
                                colors: [
                                    Asset.Colors.primary.color.opacity(0.1),
                                    Asset.Colors.primary.color,
                                    Asset.Colors.primary.color.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 16)
                    
                    // Balance Details
                    balanceDetailsSection()
                        .padding(.horizontal, 24)
                    
                    // Transparent Balance Card
                    TransparentBalanceCard(
                        store: store,
                        isSensitiveContentHidden: isSensitiveContentHidden
                    )
                    .padding(.horizontal, 20)

                    if walletStatus == .restoring {
                        restoreWarningBanner()
                    }
                    
                    // Sync Progress
                    SyncProgressView(
                        store: store.scope(
                            state: \.syncProgressState,
                            action: \.syncProgress
                        )
                    )
                    .padding(.top, walletStatus == .restoring ? 16 : 40)
                    .padding(.bottom, 25)
                }
            }
            .walletStatusPanel()
        }
        .padding(.vertical, 1)
        .applyScreenBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: \.alert
            )
        )
        .onAppear { store.send(.onAppear) }
        .onDisappear { store.send(.onDisappear) }
        .navigationLinkEmpty(
            isActive: store.bindingFor(.partialProposalError),
            destination: {
                PartialProposalErrorView(store: store.partialProposalErrorStore())
            }
        )
    }
    
    @ViewBuilder
    private func balanceDetailsSection() -> some View {
        VStack(spacing: 20) {
            balanceRow(
                title: L10n.Balances.spendableBalance.uppercased(),
                balance: store.shieldedBalance,
                showShieldIcon: true
            )
            
            balanceRow(
                title: L10n.Balances.changePending.uppercased(),
                balance: store.changePending,
                showProgress: store.changePending.amount > 0
            )
            
            balanceRow(
                title: L10n.Balances.pendingTransactions.uppercased(),
                balance: store.pendingTransactions,
                showProgress: store.pendingTransactions.amount > 0
            )
        }
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private func balanceRow(
        title: String,
        balance: Zatoshi,
        showShieldIcon: Bool = false,
        showProgress: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.custom(FontFamily.Inter.medium.name, size: 13))
                .foregroundColor(Asset.Colors.primary.color)
            
            Spacer()
            
            HStack(spacing: 8) {
                ZatoshiRepresentationView(
                    balance: balance,
                    fontName: FontFamily.Inter.semiBold.name,
                    mostSignificantFontSize: 16,
                    leastSignificantFontSize: 8,
                    format: .expanded,
                    couldBeHidden: true
                )
                
                if showShieldIcon {
                    Asset.Assets.shield.image
                        .zImage(width: 11, height: 14, color: Asset.Colors.primary.color)
                }
                
                if showProgress {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 14, height: 14)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func restoreWarningBanner() -> some View {
        Text(L10n.Balances.restoringWalletWarning)
            .zFont(.medium, size: 10, style: Design.Utility.ErrorRed._600)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Design.Utility.ErrorRed._100.color)
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
    }
}

// MARK: - Transparent Balance Card
private struct TransparentBalanceCard: View {
    let store: StoreOf<Balances>
    let isSensitiveContentHidden: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if store.isHintBoxVisible {
                hintBoxContent()
            } else {
                balanceContent()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Design.Surfaces.strokePrimary.color)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Design.Surfaces.strokePrimary.color.opacity(0.05))
                )
        )
    }
    
    @ViewBuilder
    private func balanceContent() -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Button {
                    store.send(.updateHintBoxVisibility(true))
                } label: {
                    HStack(spacing: 4) {
                        Text(L10n.Balances.transparentBalance.uppercased())
                            .font(.custom(FontFamily.Inter.medium.name, size: 13))
                        
                        Image(systemName: "questionmark.circle.fill")
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                }
                .foregroundColor(Asset.Colors.primary.color)
                
                Spacer()
                
                ZatoshiRepresentationView(
                    balance: store.transparentBalance,
                    fontName: FontFamily.Inter.semiBold.name,
                    mostSignificantFontSize: 16,
                    leastSignificantFontSize: 8,
                    format: .expanded,
                    couldBeHidden: true
                )
            }
            
            VStack(spacing: 8) {
                if store.isShieldingFunds {
                    shieldingInProgressButton()
                } else {
                    shieldFundsButton()
                }
                
                Text("(\(ZatoshiStringRepresentation.feeFormat))")
                    .font(.custom(FontFamily.Inter.regular.name, size: 11))
                    .foregroundColor(Asset.Colors.shade55.color)
            }
        }
    }
    
    @ViewBuilder
    private func shieldingInProgressButton() -> some View {
        ZashiButton(
            L10n.Balances.shieldingInProgress,
            accessoryView: ProgressView()
        ) { }
        .disabled(true)
    }
    
    @ViewBuilder
    private func shieldFundsButton() -> some View {
        ZashiButton(L10n.Balances.shieldButtonTitle) {
            store.send(.shieldFunds)
        }
        .disabled(!store.isShieldableBalanceAvailable || store.isShieldingFunds || isSensitiveContentHidden)
    }
    
    @ViewBuilder
    private func hintBoxContent() -> some View {
        VStack(spacing: 16) {
            Text(L10n.Balances.HintBox.message)
                .font(.custom(FontFamily.Inter.regular.name, size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(Asset.Colors.primary.color)
            
            Button {
                store.send(.updateHintBoxVisibility(false))
            } label: {
                Text(L10n.Balances.HintBox.dismiss.uppercased())
                    .font(.custom(FontFamily.Inter.semiBold.name, size: 10))
                    .underline()
                    .foregroundColor(Asset.Colors.primary.color)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews
#Preview {
    NavigationView {
        BalancesView(
            store: StoreOf<Balances>(
                initialState: Balances.State(
                    autoShieldingThreshold: Zatoshi(1_000_000),
                    changePending: Zatoshi(25_234_000),
                    isShieldingFunds: true,
                    isHintBoxVisible: true,
                    partialProposalErrorState: .initial,
                    pendingTransactions: Zatoshi(25_234_000),
                    syncProgressState: .init(
                        lastKnownSyncPercentage: 0.43,
                        synchronizerStatusSnapshot: SyncStatusSnapshot(.syncing(0.41)),
                        syncStatusMessage: "Syncing"
                    ),
                    walletBalancesState: .initial
                )
            ) {
                Balances()
            },
            tokenName: "ZEC"
        )
    }
    .navigationViewStyle(.stack)
}

// MARK: - Store
extension StoreOf<Balances> {
    func partialProposalErrorStore() -> StoreOf<PartialProposalError> {
        self.scope(
            state: \.partialProposalErrorState,
            action: \.partialProposalError
        )
    }
}

// MARK: - Placeholders
extension Balances.State {
    public static let placeholder = Balances.State(
        autoShieldingThreshold: .zero,
        changePending: .zero,
        isShieldingFunds: false,
        partialProposalErrorState: .initial,
        pendingTransactions: .zero,
        syncProgressState: .initial,
        walletBalancesState: .initial
    )
    
    public static let initial = Balances.State(
        autoShieldingThreshold: .zero,
        changePending: .zero,
        isShieldingFunds: false,
        partialProposalErrorState: .initial,
        pendingTransactions: .zero,
        syncProgressState: .initial,
        walletBalancesState: .initial
    )
}

extension StoreOf<Balances> {
    public static let placeholder = StoreOf<Balances>(
        initialState: .placeholder
    ) {
        Balances()
    }
}

// MARK: - Bindings
extension StoreOf<Balances> {
    func bindingFor(_ destination: Balances.State.Destination) -> Binding<Bool> {
        Binding<Bool>(
            get: { self.destination == destination },
            set: { self.send(.updateDestination($0 ? destination : nil)) }
        )
    }
}
