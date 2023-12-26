//
//  NotificationViewModel.swift
//  MirrorflyUIkit
//
//  Created by Ramakrishnan on 30/10/22.
//

import Foundation
import AVFoundation
import MirrorFlySDK

class NotificationViewModel : NSObject{

    func getSystemSounds() -> [[String:String]] {

        //return ["Default","None","bell","coin_drop","ding","hello","input","keys","pop_tone","popcorn","skytone","spell","tri_tone","twitters"]

        return [[NotificationSoundKeys.name.rawValue: "None", NotificationSoundKeys.file.rawValue: "None",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Default", NotificationSoundKeys.file.rawValue: "Default",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Bell", NotificationSoundKeys.file.rawValue: "bell",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Coin drop", NotificationSoundKeys.file.rawValue: "coin_drop",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Ding", NotificationSoundKeys.file.rawValue: "ding",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Hello", NotificationSoundKeys.file.rawValue: "hello",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Input", NotificationSoundKeys.file.rawValue: "input",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Keys", NotificationSoundKeys.file.rawValue: "keys",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Pop tone", NotificationSoundKeys.file.rawValue: "pop_tone",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Popcorn", NotificationSoundKeys.file.rawValue: "popcorn",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Skytone", NotificationSoundKeys.file.rawValue: "skytone",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Spell", NotificationSoundKeys.file.rawValue: "spell",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Tri tone", NotificationSoundKeys.file.rawValue: "tri_tone",NotificationSoundKeys.extensions.rawValue: "mp3"],
                [NotificationSoundKeys.name.rawValue: "Twitters", NotificationSoundKeys.file.rawValue: "twitters",NotificationSoundKeys.extensions.rawValue: "mp3"]]

    }
}
