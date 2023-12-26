//
//  ShareKitModel.swift
//  MirrorflyUIkit
//
//  Created by John on 20/02/23.
//

import Foundation

public struct Country: Codable {
    var name: String
    var dial_code: String
    var code: String
}

public enum AppLockActions : String, CaseIterable {
    case disablePin = "Disable PIN"
    case changePin = "Change PIN"
    case forgotPin = "Forgot PIN?"
}

struct VerifyToken : Codable {
    let status : Int?
    let data : [String:String]?
    let message : String?

    enum CodingKeys: String, CodingKey {

        case status = "status"
        case data = "data"
        case message = "message"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decodeIfPresent(Int.self, forKey: .status)
        data = try values.decodeIfPresent(Dictionary.self, forKey: .data)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }

}
