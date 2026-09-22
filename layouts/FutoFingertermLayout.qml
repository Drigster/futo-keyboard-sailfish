/*
 * FingerTerm-inspired FUTO layout profile.
 *
 * This keeps the normal FUTO input stack and keyboard backend, while forcing a
 * compact terminal-style presentation with a permanent number row and a single
 * non-split layout surface.
 */
import QtQuick 2.0
import Nemo.Configuration 1.0

FutoQwertyLayout {
    id: fingertermLayout
    splitSupported: false
    splitTopItemRequired: false

    ConfigurationGroup {
        id: fingertermSettings
        path: "/sailfish/text_input/futo_keyboard"
        property bool numberRowEnabled: true
        property real keyboardHeightScale: 0.9
        property int layoutVariant: 0
        property int symbolNumberLayout: 0
    }

    Component.onCompleted: {
        fingertermSettings.numberRowEnabled = true
        fingertermSettings.keyboardHeightScale = 0.90
        fingertermSettings.layoutVariant = 0
        fingertermSettings.symbolNumberLayout = 0
    }
}
