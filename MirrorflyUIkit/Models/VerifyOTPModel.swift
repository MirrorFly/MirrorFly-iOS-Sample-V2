//
//  VerifyOTPModel.swift
//  MirrorFly
//
//  Created by User on 18/05/21.
//

import Foundation

struct VerifyUserModel : Codable {
    let status : Int?
    let verifyUserData : VerifyUserData?
    let message : String?

    enum CodingKeys: String, CodingKey {

        case status = "status"
        case verifyUserData = "data"
        case message = "message"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decodeIfPresent(Int.self, forKey: .status)
        verifyUserData = try values.decodeIfPresent(VerifyUserData.self, forKey: .verifyUserData)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }

}
struct VerifyUserData : Codable {
    let deviceToken : String?

    enum CodingKeys: String, CodingKey {

        case deviceToken = "deviceToken"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        deviceToken = try values.decodeIfPresent(String.self, forKey: .deviceToken)
    }

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
