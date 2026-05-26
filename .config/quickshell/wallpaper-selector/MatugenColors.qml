import QtQuick

Item {
    property color base: colors.background
    property color mantle: colors.secondBackground
    property color crust: colors.background
    property color text: colors.foreground
    property color subtext0: colors.outline
    property color subtext1: colors.secondary
    property color surface0: colors.surfaceContainer
    property color surface1: colors.lightBackground
    property color surface2: colors.borders
    property color overlay0: colors.outlineVariant
    property color overlay1: colors.outline
    property color overlay2: colors.foreground
    property color blue: colors.primary
    property color sapphire: colors.primary
    property color peach: colors.tertiary
    property color green: colors.secondary
    property color red: colors.primary
    property color mauve: colors.tertiary
    property color pink: colors.secondary
    property color yellow: colors.tertiary
    property color maroon: colors.primary
    property color teal: colors.secondary

    Colors { id: colors }
}
