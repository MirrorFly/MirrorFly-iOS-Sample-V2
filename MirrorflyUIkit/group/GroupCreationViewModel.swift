//
//  GroupCreationViewModel.swift
//  MirrorflyUIkit
//
//  Created by John on 24/11/21.
//

import Foundation
import MirrorFlySDK

class GroupCreationViewModel : NSObject {
    
    let contactViewModel = ContactViewModel()
    
    typealias GroupCallBack = (_ result: Bool,_ message: String) -> Void
    
    func removeParticipant(participant : ProfileDetails, participantList : [ProfileDetails]) -> [ProfileDetails]{
        GroupCreationData.participants = GroupCreationData.participants.filter({$0.jid != participant.jid})
        return GroupCreationData.participants
    }
    
    func getContacts(fromServer: Bool, completionHandler:  @escaping ([ProfileDetails]?, String?)-> Void) {
        contactViewModel.getContacts(fromServer: fromServer, completionHandler: completionHandler)
    }
    
    func initializeGroupCreationData(){
        GroupCreationData.groupName = ""
        GroupCreationData.groupImageLocalPath = ""
        GroupCreationData.participants = [ProfileDetails]()
    }
    
    func checkMinimumParticipant(selectedParticipants : [ProfileDetails]) -> Bool{
        return selectedParticipants.count >= minimumGroupParticipant
    }
    
    func checkMaximumParticipant(selectedParticipant : [ProfileDetails]) -> Bool {
        return selectedParticipant.count > 250
    }
    
    func searchContacts(text : String,contacts : [ProfileDetails])  -> [ProfileDetails] {
        text.isEmpty ? contacts : contacts.filter { term in
            return getUserName(jid:term.jid,name: term.name, nickName: term.nickName, contactType: term.contactType).lowercased().contains(text.lowercased())
        }
    }
    
    func removeSelectedParticipantJid(selectedParticipants : [ProfileDetails], participant : ProfileDetails) -> [ProfileDetails] {
        return selectedParticipants.filter { $0.jid != participant.jid }
    }
    
    
    func isNameEmpty(groupName : String, groupCallBack : @escaping GroupCallBack) {
        groupCallBack(groupName.isEmpty, groupNameRequired)
    }
    
    func textLimit(existingText: String?, newText: String, limit: Int) -> Bool {
        let text = existingText ?? ""
        let isAtLimit = text.count + newText.count <= limit
        return isAtLimit
    }
    
    func calculateTextLength(startingLength : Int, lengthToAdd : Int, lengthToReplace : Int) -> Int {
        var count = startingLength + lengthToAdd - lengthToReplace
        count = count > groupNameCharLimit ? groupNameCharLimit : count
        return count
    }
    
    func createGroup(groupCallBack : @escaping GroupCallBack) {
        let groupName = GroupCreationData.groupName
        let groupImageFileUrl = GroupCreationData.groupImageLocalPath
        var participantJid = [String]()
        GroupCreationData.participants.forEach { participant in
            participantJid.append(participant.jid)
        }
        
        try? GroupManager.shared.createGroup(groupName: groupName, participantJidList: participantJid, groupImageFileUrl: groupImageFileUrl, completionHandler: { isSuccess, flyError, flyData in
            groupCallBack(isSuccess, flyError?.description as? String ?? "")
        })
    }
    
    private func getParticiapntsJID() -> [String] {
        
        var participantJid = [String]()
        GroupCreationData.participants.forEach { participant in
            participantJid.append(participant.jid)
        }
        
        return participantJid
    }
    
    func removeExistingParticipants(groupID: String, contacts: [ProfileDetails]) -> [ProfileDetails] {
        
        var contactsList = contacts
        
        let groupMembers = GroupManager.shared.getGroupMemebersFromLocal(groupJid: groupID)
        groupMembers.participantDetailArray.forEach { groupParticipantDetail in
            contactsList = contactsList.filter({$0.jid != groupParticipantDetail.memberJid})
        }
        return contactsList
    }
    
    func addNewParticipantToGroup(groupID: String,
                                  completionHandler: @escaping FlyCompletionHandler) {
        
        let contactList = getParticiapntsJID()
        
        try! GroupManager.shared.addParticipantToGroup(groupId: groupID, newUserJidList: contactList, completionHandler: completionHandler)
    }
}
