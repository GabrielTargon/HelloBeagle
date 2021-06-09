//
//  BoxWidget.swift
//  HelloBeagle
//
//  Created by Gabriel Targon on 09/06/21.
//

import Foundation
import UIKit
import Beagle

struct BoxWidget: Widget, AutoInitiableAndDecodable {

    // Class parameter.
    let title: String
    var widgetProperties: WidgetProperties
    
    // toView method of interface the  widget.
    func toView(renderer: BeagleRenderer) -> UIView {
        let boxComponent = Box(title: title)
        boxComponent.translatesAutoresizingMaskIntoConstraints = false
        let beagleWrapper = AutoLayoutWrapper(view: boxComponent)
        return beagleWrapper
    }

// sourcery:inline:auto:BoxWidget.Init
    internal init(
        title: String,
        widgetProperties: WidgetProperties = WidgetProperties()
    ) {
        self.title = title
        self.widgetProperties = widgetProperties
    }
// sourcery:end
}
