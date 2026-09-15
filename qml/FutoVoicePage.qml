import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.DBus 2.0

Page {
    id: page
    allowedOrientations: Orientation.All
    property bool voiceContentReady: false
    property bool voiceModelInstalled: false
    property bool anyVoiceModelInstalled: false
    property bool pendingVoiceDownloads: false
    property string pendingVoicePackId: ""
    property string requestedVoiceModel: ""
    property bool enableVoiceAfterDownload: false
    property bool voiceSelectionReady: false
    property bool syncingVoiceSelection: false
    property var installedVoiceModels: ({})
    readonly property var voiceModelIds: [
        "voice-english-39", "voice-english-74", "voice-english-244",
        "voice-multilingual-39", "voice-multilingual-74", "voice-multilingual-244"
    ]

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refreshVoiceContent()
            if (pendingVoiceDownloads && !voiceDownloadNavigation.running)
                voiceDownloadNavigation.start()
        }
    }

    Timer {
        id: voiceDownloadNavigation
        interval: 1
        repeat: false
        onTriggered: {
            page.pendingVoiceDownloads = false
            pageStack.push(Qt.resolvedUrl("FutoContentListPage.qml"), {
                "packKind": "voice",
                "pageTitle": qsTr("Offline voice"),
                "requestedPackId": page.pendingVoicePackId
            })
        }
    }

    function voiceModelName(modelId) {
        if (modelId === "voice-english-39") return qsTr("English - Fastest")
        if (modelId === "voice-english-74") return qsTr("English - Slower, more accurate")
        if (modelId === "voice-english-244") return qsTr("English - Slowest, most accurate")
        if (modelId === "voice-multilingual-74") return qsTr("Multilingual - Slower, more accurate")
        if (modelId === "voice-multilingual-244") return qsTr("Multilingual - Slowest, most accurate")
        return qsTr("Multilingual - Default, fastest")
    }

    function voiceModelIndex(modelId) {
        for (var i = 0; i < voiceModelIds.length; ++i) {
            if (voiceModelIds[i] === modelId)
                return i
        }
        return 3
    }

    function selectedVoiceModelId() {
        var index = voiceModelIndex(settings.voiceModel)
        return voiceModelIds[index]
    }

    function voiceModelDescription(modelId) {
        var english = modelId.indexOf("voice-english-") === 0
        var size = modelId.slice(modelId.lastIndexOf("-") + 1)
        var speed = size === "39" ? qsTr("Fastest and smallest")
                  : size === "74" ? qsTr("More accurate, but slower")
                  : qsTr("Most accurate and slowest")
        return english
                ? qsTr("%1. English speech only.").arg(speed)
                : qsTr("%1. Supports multiple languages.").arg(speed)
    }

    function firstInstalledVoiceModel() {
        var preferred = [
            "voice-multilingual-39", "voice-multilingual-74",
            "voice-multilingual-244", "voice-english-39",
            "voice-english-74", "voice-english-244"
        ]
        for (var i = 0; i < preferred.length; ++i) {
            if (installedVoiceModels[preferred[i]])
                return preferred[i]
        }
        return ""
    }

    function syncVoiceCombo(modelId) {
        syncingVoiceSelection = true
        voiceModelCombo.currentIndex = voiceModelIndex(modelId)
        syncingVoiceSelection = false
    }

    function chooseVoiceModel(modelId) {
        if (!voiceSelectionReady || syncingVoiceSelection)
            return
        if (installedVoiceModels[modelId]) {
            settings.voiceModel = modelId
            voiceModelInstalled = true
            return
        }
        syncVoiceCombo(settings.voiceModel)
        openVoiceDownloads(modelId, false)
    }

    function refreshVoiceContent() {
        if (helper.status !== DBusInterface.Available)
            return
        helper.typedCall("ContentStatus", [], function(resultJson) {
            var result
            try {
                result = JSON.parse(String(resultJson))
            } catch (error) {
                return
            }
            var installed = {}
            var items = result.items || []
            for (var i = 0; i < items.length; ++i) {
                if (String(items[i].kind) === "voice")
                    installed[String(items[i].id)] = !!items[i].installed
            }
            page.installedVoiceModels = installed
            page.anyVoiceModelInstalled = page.firstInstalledVoiceModel() !== ""
            if (page.requestedVoiceModel !== ""
                    && installed[page.requestedVoiceModel]) {
                settings.voiceModel = page.requestedVoiceModel
                page.requestedVoiceModel = ""
            }
            var currentModel = page.selectedVoiceModelId()
            if (!installed[currentModel]) {
                var fallback = page.firstInstalledVoiceModel()
                if (fallback !== "") {
                    settings.voiceModel = fallback
                    currentModel = fallback
                }
            }
            page.voiceModelInstalled = !!installed[currentModel]
            if (page.enableVoiceAfterDownload && page.voiceModelInstalled) {
                settings.voiceTypingEnabled = true
                page.requestedVoiceModel = ""
                page.enableVoiceAfterDownload = false
            }
            page.voiceContentReady = true
            page.syncVoiceCombo(currentModel)
            page.voiceSelectionReady = true
            if (!page.voiceModelInstalled && settings.voiceTypingEnabled)
                settings.voiceTypingEnabled = false
        })
    }

    function openVoiceDownloads(modelId, enableAfterDownload) {
        var dialog = pageStack.push(Qt.resolvedUrl("FutoContentRequiredDialog.qml"), {
            "contentName": qsTr("offline voice model"),
            "explanation": enableAfterDownload
                    ? qsTr("Voice typing needs an offline voice model. "
                           + "Open the Offline voice downloader to install one?")
                    : qsTr("This voice model is not installed. "
                           + "Open the Offline voice downloader to install it?")
        })
        dialog.accepted.connect(function() {
            page.requestedVoiceModel = modelId
            page.enableVoiceAfterDownload = !!enableAfterDownload
            page.pendingVoicePackId = modelId
            page.pendingVoiceDownloads = true
        })
    }

    ConfigurationGroup {
        id: settings
        path: "/sailfish/text_input/futo_keyboard"
        property bool voiceTypingEnabled: false
        property string voiceModel: "voice-multilingual-39"
        property bool voiceKeyVisible: true
		property bool voicePushToTalkEnabled: false
        property bool voiceLiveTranscriptionEnabled: true
        property bool voiceStopAfterSilence: true
        property int voiceSilenceTimeoutMs: 1300
    }

    DBusInterface {
        id: helper
        bus: DBus.SessionBus
        service: "org.hb.FutoKeyboard1"
        path: "/org/hb/FutoKeyboard1"
        iface: "org.hb.FutoKeyboard1"
        signalsEnabled: true
        watchServiceStatus: true

        function contentChanged(packId, state) {
            if (String(packId).indexOf("voice-") === 0)
                page.refreshVoiceContent()
        }

        onStatusChanged: {
            if (status === DBusInterface.Available)
                page.refreshVoiceContent()
        }
    }

    Component.onCompleted: refreshVoiceContent()

    FutoSettingsTestPanel {
        id: testPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        pageItem: page
    }

    SilicaFlickable {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: testPanel.top
        contentHeight: content.height + Theme.paddingLarge
        clip: true
        VerticalScrollDecorator { flickable: parent }

        Column {
            id: content
            width: parent.width
            PageHeader { title: qsTr("Voice typing") }

            TextSwitch {
                width: parent.width
                enabled: page.voiceContentReady || settings.voiceTypingEnabled
                automaticCheck: false
                checked: settings.voiceTypingEnabled
                text: qsTr("Enable voice typing")
                description: qsTr("Speech recognition remains completely on this phone.")
                onClicked: {
                    if (!checked && !page.voiceModelInstalled)
                        page.openVoiceDownloads(page.selectedVoiceModelId(), true)
                    else
                        settings.voiceTypingEnabled = !checked
                }
            }

            ComboBox {
                id: voiceModelCombo
                width: parent.width
                enabled: page.voiceContentReady
                label: qsTr("Voice model")
                value: page.anyVoiceModelInstalled
                       ? page.voiceModelName(page.selectedVoiceModelId())
                       : qsTr("No models installed")
                currentIndex: page.voiceModelIndex(settings.voiceModel)
                onCurrentIndexChanged: {
                    if (page.voiceSelectionReady && !page.syncingVoiceSelection)
                        page.chooseVoiceModel(page.voiceModelIds[currentIndex])
                }
                menu: ContextMenu {
                    MenuItem { text: qsTr("English - Fastest") }
                    MenuItem { text: qsTr("English - Slower, more accurate") }
                    MenuItem { text: qsTr("English - Slowest, most accurate") }
                    MenuItem { text: qsTr("Multilingual - Default, fastest") }
                    MenuItem { text: qsTr("Multilingual - Slower, more accurate") }
                    MenuItem { text: qsTr("Multilingual - Slowest, most accurate") }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: page.anyVoiceModelInstalled
                      ? page.voiceModelDescription(page.selectedVoiceModelId())
                      : qsTr("Download a voice model to use voice typing.")
            }

            TextSwitch {
                width: parent.width
                enabled: settings.voiceTypingEnabled
                automaticCheck: false
                checked: settings.voiceKeyVisible
                text: qsTr("Show the microphone key")
				description: qsTr("The 123-menu microphone is configured separately "
				                  + "under Quick settings. When this key is hidden, "
				                  + "hold comma to use voice input instead.")
                onClicked: settings.voiceKeyVisible = !checked
            }

			TextSwitch {
				width: parent.width
				enabled: settings.voiceTypingEnabled
				automaticCheck: false
				checked: settings.voicePushToTalkEnabled
				text: qsTr("Push to talk")
				description: settings.voiceKeyVisible
						? qsTr("Hold the microphone to record and release it to stop.")
						: qsTr("Hold comma to record and release it to stop.")
				onClicked: {
					var nextEnabled = !checked
					settings.voicePushToTalkEnabled = nextEnabled
					if (nextEnabled)
						settings.voiceStopAfterSilence = false
				}
			}

            TextSwitch {
                width: parent.width
                enabled: settings.voiceTypingEnabled
                automaticCheck: false
                checked: settings.voiceLiveTranscriptionEnabled
                text: qsTr("Live transcription")
                description: qsTr("Show recognized words in the active text field while "
                                  + "you speak.")
                onClicked: settings.voiceLiveTranscriptionEnabled = !checked
            }

            TextSwitch {
                width: parent.width
                enabled: settings.voiceTypingEnabled
						 && settings.voiceLiveTranscriptionEnabled
						 && !settings.voicePushToTalkEnabled
                automaticCheck: false
				checked: !settings.voicePushToTalkEnabled
				         && settings.voiceStopAfterSilence
                text: qsTr("Stop automatically after silence")
                description: qsTr("When disabled, a tap keeps listening until you tap the "
                                  + "microphone again. Push-to-talk always stops on release.")
                onClicked: settings.voiceStopAfterSilence = !checked
            }

            Slider {
                width: parent.width
                enabled: settings.voiceTypingEnabled
                         && settings.voiceLiveTranscriptionEnabled
						 && !settings.voicePushToTalkEnabled
                         && settings.voiceStopAfterSilence
                label: qsTr("Finish after silence")
                minimumValue: 800
                maximumValue: 2500
                stepSize: 100
                value: Math.max(minimumValue, Math.min(maximumValue,
                                                       settings.voiceSilenceTimeoutMs))
                valueText: (value / 1000).toFixed(1) + qsTr(" seconds")
                onReleased: settings.voiceSilenceTimeoutMs = Math.round(value / 100) * 100
            }

            SectionHeader { text: qsTr("Private and offline") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: page.voiceModelInstalled
                      ? qsTr("Speech recognition runs entirely on this phone with the %1 model. "
                             + "Recordings are stored in a private temporary "
                             + "file and erased immediately after transcription or cancellation. "
                             + "The microphone is unavailable in password fields and stops "
                             + "after your configured pause, when released in push-to-talk, or "
                             + "when you tap it again in continuous mode.")
                             .arg(page.voiceModelName(page.selectedVoiceModelId()))
                      : qsTr("Speech recognition runs entirely on this phone after an offline "
                             + "voice model has been installed. Recordings are stored in a "
                             + "private temporary file and erased immediately after use.")
            }

            SectionHeader { text: qsTr("Languages") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Voice recognition follows the language or language group of the "
                           + "current FUTO letter layout. Change layouts from the held-123 menu "
                           + "when you want to constrain recognition to another language group.")
            }
        }
    }
}
