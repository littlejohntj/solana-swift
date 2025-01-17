//
//  SolanaSDK+Tokens.swift
//  SolanaSwift
//
//  Created by Chung Tran on 26/01/2021.
//

import Foundation
import RxSwift

extension SolanaSDK {
    public func getTokensList() -> Single<[Token]> {
        if let cache = supportedTokensCache {
            return .just(cache)
        }
        let parser = TokensListParser()
        return parser.parse(network: endpoint.network.cluster)
            .do(onSuccess: {self.supportedTokensCache = $0})
    }
    
    public func getTokenWallets(account: String? = nil, log: Bool = true) -> Single<[Wallet]> {
        guard let account = account ?? accountStorage.account?.publicKey.base58EncodedString else {
            return .error(Error.unauthorized)
        }
        let memcmp = EncodableWrapper(
            wrapped:
                ["offset": EncodableWrapper(wrapped: 32),
                 "bytes": EncodableWrapper(wrapped: account)]
        )
        let configs = RequestConfiguration(commitment: "recent", encoding: "base64", dataSlice: nil, filters: [
            ["memcmp": memcmp],
            ["dataSize": .init(wrapped: 165)]
        ])
        
        return Single.zip(
            getProgramAccounts(
                publicKey: PublicKey.tokenProgramId.base58EncodedString,
                configs: configs,
                decodedTo: AccountInfo.self,
                log: log
            )
                .map {$0.accounts},
            getTokensList()
        )
            .flatMap { list, supportedTokens -> Single<[Wallet]> in
                var knownWallets = [Wallet]()
                var unknownAccounts = [(String, AccountInfo)]()
                
                for item in list {
                    let pubkey = item.pubkey
                    let accountInfo = item.account.data
                    
                    let mintAddress = accountInfo.mint.base58EncodedString
                    // known token
                    if let token = supportedTokens.first(where: {$0.address == mintAddress})
                    {
                        knownWallets.append(
                            Wallet(
                                pubkey: pubkey,
                                lamports: accountInfo.lamports,
                                token: token
                            )
                        )
                    }
                    
                    // unknown token
                    else {
                        unknownAccounts.append((item.pubkey, item.account.data))
                    }
                    
                }
                
                return self.getMultipleMintDatas(
                    mintAddresses: unknownAccounts.map{$0.1.mint.base58EncodedString},
                    log: log
                )
                    .map {mintDatas -> [Wallet] in
                        guard mintDatas.count == unknownAccounts.count
                        else {throw Error.unknown}
                        var wallets = [Wallet]()
                        for (index, item) in mintDatas.enumerated() {
                            wallets.append(
                                Wallet(
                                    pubkey: unknownAccounts[index].0,
                                    lamports: unknownAccounts[index].1.lamports,
                                    token: .unsupported(
                                        mint: unknownAccounts[index].1.mint.base58EncodedString,
                                        decimals: item.value.decimals
                                    )
                                )
                            )
                        }
                        return wallets
                    }
                    .catchAndReturn(unknownAccounts.map {
                        Wallet(pubkey: $0.0, lamports: $0.1.lamports, token: .unsupported(mint: $0.1.mint.base58EncodedString))
                    })
                    .map {knownWallets + $0}
            }
    }
    
    public func checkAccountValidation(account: String) -> Single<Bool> {
        getAccountInfo(account: account, decodedTo: EmptyInfo.self)
            .map {_ in true}
            .catch {error in
                if error.isEqualTo(.couldNotRetrieveAccountInfo) {
                    return .just(false)
                }
                throw error
            }
    }
}
