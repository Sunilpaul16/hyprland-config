pragma Singleton
import QtQuick
import Quickshell


// Matugen scheme variants
Singleton {
    id: root

    readonly property var list: [
        { value: "auto", label: "Automatic", description: "Picks a variant to suit the wallpaper", icon: "\u{2728}" },
        { value: "scheme-tonal-spot", label: "Tonal spot", description: "The Material default, muted accents", icon: "\u{1F308}" },
        { value: "scheme-vibrant", label: "Vibrant", description: "Strongly saturated accents", icon: "\u{1F308}" },
        { value: "scheme-expressive", label: "Expressive", description: "Shifts hue away from the source", icon: "\u{1F308}" },
        { value: "scheme-content", label: "Content", description: "Keeps the image's own colours", icon: "\u{1F308}" },
        { value: "scheme-fidelity", label: "Fidelity", description: "Closest match to the source colour", icon: "\u{1F308}" },
        { value: "scheme-fruit-salad", label: "Fruit salad", description: "Playful spread of several hues", icon: "\u{1F308}" },
        { value: "scheme-monochrome", label: "Monochrome", description: "Greyscale, no accent hue", icon: "\u{1F308}" },
        { value: "scheme-neutral", label: "Neutral", description: "Near-grey, very low saturation", icon: "\u{1F308}" },
        { value: "scheme-rainbow", label: "Rainbow", description: "Wide hue spread across roles", icon: "\u{1F308}" }
    ]

    // Fuzzy query
    function query(search: string): var {
        const trimmed = search.trim();
        if (!trimmed)
            return root.list;
        return Fuzzy.go(trimmed, root.list, { key: "label", all: true }).map(r => r.obj);
    }
}
