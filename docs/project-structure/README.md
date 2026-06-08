# Project Structure

```text
Mota
├── LICENSE                         # Project license.
├── README.md                       # Repository overview and structure notes.
├── assets/                         # Repository-level visual assets used by docs and branding.
└── MobileApplication/              # Flutter mobile client.
    ├── analysis_options.yaml       # Dart analyzer and lint configuration.
    ├── pubspec.yaml                # Flutter package metadata, dependencies, and asset entries.
    ├── README.md                   # Mobile app specific notes.
    ├── android/                    # Android platform project for emulator/device builds.
    ├── ios/                        # iOS platform project generated and maintained by Flutter.
    ├── assets/                     # Mobile runtime assets.
    │   ├── animations/             # Animation resources.
    │   ├── icons/                  # App and feature icons.
    │   └── images/                 # Image resources.
    ├── test/                       # Flutter widget and behavior tests.
    └── lib/                        # Dart source code.
        ├── main.dart               # Flutter entry point.
        └── app/
            ├── app.dart            # Root app state: tab routing, robot mood, connection state, settings state.
            ├── core/               # Platform and hardware-facing services.
            │   ├── BT_HardwareDrive/
            │   │   ├── bluetooth_device_info.dart       # Bluetooth device value object.
            │   │   └── bluetooth_discovery_service.dart # Bluetooth discovery boundary and mock scan data.
            │   ├── network/        # Reserved for network/API clients.
            │   └── nfc/            # Reserved for NFC integrations.
            ├── features/           # Feature modules grouped by user workflow.
            │   ├── bluetooth/      # Bluetooth scan and connection UI.
            │   │   ├── models/     # Connection state enum and display text.
            │   │   └── pages/      # Bluetooth page and scan result presentation.
            │   ├── bot_control/    # Movement command experience.
            │   │   ├── models/     # Robot movement command definitions.
            │   │   └── pages/      # Movement control page.
            │   ├── guide/          # Beginner guide content.
            │   │   └── pages/      # Guide page.
            │   ├── robot_face/     # Robot face, mood, and home interaction experience.
            │   │   ├── models/     # Mood enum and mood metadata.
            │   │   ├── pages/      # Home page and immersive robot face page.
            │   │   └── widgets/    # Face canvas, hero card, header, and mood grid.
            │   └── settings/       # Settings and preferences experience.
            │       ├── models/     # Settings state and fixed settings copy.
            │       ├── pages/      # Settings page composition.
            │       └── widgets/    # Settings header, rows, switches, status pill, and connection card.
            ├── router/             # Bottom tab route definitions.
            └── shared/             # Reusable UI primitives and app-wide styling.
                ├── theme/          # Colors and Material theme setup.
                └── widgets/        # Shared cards, titles, bottom bar, and menu components.
                    └── menu/       # Profile/privacy menu models and panels.
```
