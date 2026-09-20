/* Confirmation asked before FUTO Keyboard removes itself.
 *
 * This deliberately is a Page, not a Silica Dialog. Dialogs can be accepted
 * with Sailfish's forward navigation gesture, which is too easy to trigger
 * while reading a destructive-action warning. Removal starts only from the
 * explicit Uninstall button below.
 */
import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All
    property bool startingRemoval: false

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("Uninstall FUTO Keyboard") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.primaryColor
                text: qsTr("Uninstall FUTO Keyboard?")
                font.pixelSize: Theme.fontSizeLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("The keyboard, its settings, and everything it has "
                           + "learned are removed from this device. Downloaded "
                           + "dictionaries, voice models and emoji are removed "
                           + "as well. Sailfish switches back to its own "
                           + "keyboard. Save any open work before continuing: "
                           + "removing FUTO restarts the Sailfish home screen "
                           + "and closes running applications.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Uninstall")
                enabled: !page.startingRemoval
                onClicked: {
                    if (page.startingRemoval)
                        return
                    Remorse.popupAction(
                                page,
                                qsTr("Uninstalling FUTO Keyboard"),
                                function() {
                                    page.startingRemoval = true
                                    pageStack.replace(Qt.resolvedUrl(
                                        "FutoUninstallProgressPage.qml"))
                                })
                }
            }

        }
    }
}
