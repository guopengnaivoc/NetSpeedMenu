# Security notice

The NetSpeedMenu 1.3 app is ad-hoc signed on the developer's Mac, while the PKG installer itself is unsigned. Neither uses an Apple Developer ID signature, and the release has not been notarized by Apple. macOS can therefore warn that the developer cannot be verified or that Apple cannot check the app for malicious software.

Only download release files from this repository. Verify `SHA256SUMS` before overriding a Gatekeeper warning. Do not bypass a warning that explicitly says the app contains malware, will damage the computer, is damaged, or has been modified.

The app reads network-interface byte counters locally. It contains no telemetry, advertising, or network-upload code.

For Apple's current guidance, see [Safely open apps on your Mac](https://support.apple.com/102445).

To report a security concern, open a GitHub issue without including private or sensitive information.
