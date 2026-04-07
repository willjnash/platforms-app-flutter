# London Platforms iOS — HIG audit checklist

Use this as a living checklist against Apple’s [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/). Revisit after each major iOS / Xcode release.

## Foundations

- [ ] **Clarity / deference / depth** — Primary task (see next train) is obvious; chrome does not overpower content.
- [ ] **Materials** — Liquid Glass / system materials used only where documented; text remains legible on all backgrounds.

## Layout and adaptivity

- [ ] **NavigationSplitView** — iPad and regular width: two columns behave correctly; compact width stacks with sensible back navigation.
- [ ] **Dynamic Type** — Largest accessibility sizes: list rows, sheets, and service detail remain readable without overlap.
- [ ] **Landscape / multitasking** — Stage Manager and split screen: no clipped titles or unreachable controls.

## Accessibility

- [ ] **VoiceOver** — Board rows, errors, empty states, and detail sections expose a single sensible label per row where combined.
- [ ] **Differentiate Without Color** — “Platform confirmed” is clear from copy, not only green fill.
- [ ] **Increase Contrast** — Confirmed departure rows and error states remain readable.
- [ ] **Reduce Motion** — No motion-only critical information (add checks if animations expand).

## Inclusion

- [ ] **Localization** — New copy added to [Localizable.xcstrings](LondonPlatforms/Localizable.xcstrings); translators can add locales.
- [ ] **RTL** — Pseudolanguage or Arabic: list alignment and platform column still make sense.

## Trust and privacy

- [ ] **Privacy manifest** — [PrivacyInfo.xcprivacy](LondonPlatforms/PrivacyInfo.xcprivacy) matches actual behavior; App Store privacy answers stay accurate.
- [ ] **Network** — Only documented endpoints; credentials not logged.

## App Store (excluding icon work tracked separately)

- [ ] **Screenshots / copy** — Reflect current UI and minimum OS (iOS 26+).
