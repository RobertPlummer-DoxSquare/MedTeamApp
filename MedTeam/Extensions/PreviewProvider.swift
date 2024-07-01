//
//  PreviewProvider.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/26/24.
//

import SwiftUI
import Firebase

extension PreviewProvider {
    static var dev: DeveloperPreview {
        return DeveloperPreview.shared
    }
}


class DeveloperPreview {
    static let shared = DeveloperPreview()
    
   //* let user = User(id: NSUUID().uuidString, email: "max@gmail.com", fullname: "Max Verstappen", username: "maxverstappen1", credentials: "MD", selectedSurgeryService: ["Service1"]*/)
}

//struct SurgeryServiceSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        SurgeryServiceSelectionView(selectedServices: .constant([]), selectedHospital: .constant(nil))
//    }
//}
