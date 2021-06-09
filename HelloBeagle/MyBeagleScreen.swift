//
//  MyBeagleScreen.swift
//  HelloBeagle
//
//  Created by Marcos Jr on 31/05/21.
//

import Foundation
import Beagle

class MyBeagleScreen {
    
    static func make() -> Screen {
        return Screen(
            child:
                BoxWidget(title: "Teste")
        )
    }
}
