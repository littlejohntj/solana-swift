//
//  Transaction.swift
//  SolanaSwift
//
//  Created by Chung Tran on 11/6/20.
//

import Foundation
import TweetNacl

public extension SolanaSDK {
    struct ConfirmedTransaction: Decodable {
        public let message: Message
        public let signatures: [String]
    }
}

public extension SolanaSDK.ConfirmedTransaction {
    struct Message: Decodable {
        public let accountKeys: [SolanaSDK.Account.Meta]
        public let instructions: [SolanaSDK.ParsedInstruction]
        public let recentBlockhash: String
    }
}

public extension SolanaSDK {
    public struct ParsedInstruction: Decodable {
        public struct Parsed: Decodable {
            public struct Info: Decodable {
                let owner: String?
                let account: String?
                let source: String?
                let destination: String?
                
                // create account
                let lamports: UInt64?
                let newAccount: String?
                let space: UInt64?
                
                // initialize account
                let mint: String?
                let rentSysvar: String?
                
                // approve
                let amount: String?
                let delegate: String?
                
                // transfer
                let authority: String?
                let wallet: String? // spl-associated-token-account
                
                // transferChecked
                public let tokenAmount: TokenAccountBalance?
            }
            public let info: Info
            let type: String?
        }
        
        public let program: String?
        public let programId: String
        public let parsed: Parsed?
        
        // swap
        public let data: String?
        public let accounts: [String]?
    }
}
