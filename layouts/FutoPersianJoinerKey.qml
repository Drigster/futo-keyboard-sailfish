/* Persian ZWNJ key with AliNa-style access to the core Arabic diacritics. */
import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0
import ".."

FutoCharacterKey {
    id: joinerKey

    property Item targetLayout
    active: targetLayout && targetLayout.usesPersianDigits
    fixedWidth: true
    // Reserve a real bottom-row key cell.  punctuationKeyWidthNarrow was not
    // part of FutoKeyboardLayout, so it evaluated to an invalid/zero width and
    // left only the caption floating between Space and Period.
    implicitWidth: active ? punctuationKeyWidth : 0
    separatedKeyCardEligible: false
    secondaryHintEligible: true

    caption: "‹|›"
    captionShifted: caption
    keyOutput: "\u200c"
    keyOutputShifted: keyOutput
    symView: "‹¦›"
    symViewOutput: "\u00a0"
    symView2: "›|‹"
    symView2Output: "\u200d"
	secondarySymbol: "\u064e"
	secondarySymbolCaption: "\u202a\u00a0\u064e\u202c"
	secondarySymbolOutput: "\u064e"
	// NBSP gives each otherwise-zero-width combining mark a private invisible
	// carrier. LTR embedding preserves the requested visual order on this RTL key.
	secondaryHintCaption: ""
	secondaryHintParts: ["\u0651", "\u064f", "\u064e"]

    exactAlternativeMode: true
    letterAlternativeChoices: [
        { "caption": "\u202a\u00a0\u064c\u202c", "output": "\u064c" },
        { "caption": "\u202a\u00a0\u064d\u202c", "output": "\u064d" },
        { "caption": "\u202a\u00a0\u064b\u202c", "output": "\u064b" },
        { "caption": "\u202a\u00a0\u0652\u202c", "output": "\u0652" },
        { "caption": "\u202a\u00a0\u064f\u202c", "output": "\u064f" },
        { "caption": "\u202a\u00a0\u0650\u202c", "output": "\u0650" },
        { "caption": "\u202a\u00a0\u064e\u202c", "output": "\u064e" },
        { "caption": "\u202a\u00a0\u0651\u202c", "output": "\u0651" }
    ]
    letterAlternativeChoicesShifted: letterAlternativeChoices
    popupAlways: !attributes.inSymView
}
