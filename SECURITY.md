# Security policy

## Supported versions

Only the latest release receives security fixes. Older versions are not patched; upgrade to the current release listed on the [releases page](https://github.com/trsdn/oft-eml-converter-mac/releases).

## Reporting a vulnerability

Report privately through [GitHub private vulnerability reporting](https://github.com/trsdn/oft-eml-converter-mac/security/advisories/new). Do not open a public issue, and do not include credentials, tokens, or real message files in a report.

Expect an acknowledgement within seven days. This is a single-maintainer project, so a fix follows as soon as one is practical rather than to a fixed schedule. You will be told either way.

## What this application does with your data

Conversion happens entirely on your Mac. The app reads the `.oft` files you drop on it and writes `.eml` files next to them. It transmits nothing, collects nothing, and has no telemetry, analytics, or crash reporting.

The only outbound connections in the product's lifetime are:

- **PyPI**, once, on first launch, to install the `extract_msg` dependency into a private virtual environment under `~/Library/Application Support/OFT-EML-Converter/`.
- **Apple's notarization check**, performed by macOS itself the first time you open the app. This is Gatekeeper, not the application.

## Verifying a download

Releases are signed with a Developer ID Application certificate and notarized by Apple. To confirm a downloaded DMG is intact and genuinely from this project:

```sh
shasum -a 256 -c OFT-EML-Converter-macos.dmg.sha256
spctl --assess --type open --context context:primary-signature -v OFT-EML-Converter-macos.dmg
codesign --verify --strict --verbose=2 /Applications/OFT-EML-Converter.app
```

The bundle identifier is `com.trsdn.oft-eml-converter`. A build presenting any other identifier did not come from this project.

## Scope

In scope: the application, its build and release scripts, and the published site.

Out of scope: vulnerabilities in `extract_msg`, Python, or macOS itself. Report those upstream. If an upstream flaw is reachable through this application in a way that is not obvious, that is in scope and worth reporting here.
