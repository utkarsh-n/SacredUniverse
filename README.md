# Sacred Universe App

A native iPhone learning instrument for iOS 27, written in SwiftUI with Apple's Liquid Glass controls. Inspired by [Hidden Mathematics, Randall Carlson / After Skool](https://www.youtube.com/watch?v=R7oyZGW99os).

Eight experiments connect the circle, time units, digital roots, polygons, Platonic solids, axial precession, celestial apparent size, and pyramid proportions. Every experiment follows Notice → Explore → Predict → Understand → Discovered. Incorrect predictions can be revised. Actual parameter changes unlock prediction; changing a pending experiment refreshes its question. All stops are open from the start.

Universe is the visual atlas, Journey is the guided sequence, and Notebook collects earned insights and personal reflections. They share one observable model. Each lab retains its own dials and progress across visits and app launches. Sound is optional and respects Silent Mode. Haptics mark meaningful actions. Playback pauses on navigation, sheets, and backgrounding; Reduce Motion keeps manual controls available. System sliders and adjustable accessibility actions provide alternatives to scene gestures.

The visual design draws on Ananta's navy and gold, Nano's universe-first scenes, e's state-derived readouts and pause behavior, Overtone's event-based learning progression, and Flips' native controls. Vector scenes stay matte; navigation and actions use native Liquid Glass.

## Open and build

Open `SacredUniverse.xcodeproj` and select the SacredUniverse scheme. The app target supports iPhone on iOS 27 or later. XcodeGen can regenerate the checked-in project:

```sh
xcodegen generate --spec project.yml
```

`Sources/SacredCore` is a Foundation-only math package. Run its tests with `swift test`. UI tests use `--ui-testing --reset-progress` to isolate their preference suite from normal use; a subsequent `--ui-testing` launch verifies restoration without clearing the suite.

## Verification

19 SacredCore tests and five unique physical iPhone scenarios passed across two successful runs: four Debug UI checks and one Release App Library icon-launch check, with zero failures. These cover learning, all eight calculations, independent state, relaunch persistence, sensory preferences, source sheets, and ordinary production-mode startup/navigation. See [verification notes](</path/to/developer/Documents/AI Stuff/SacredUniverse/Design/verification.md>) for durations, screenshots, and the remaining runtime accessibility and physical sensory checks.

Release captures: [homepage](</path/to/developer/Documents/AI Stuff/SacredUniverse/Design/iphone-qa/normal-homepage.png>), [circle experiment](</path/to/developer/Documents/AI Stuff/SacredUniverse/Design/iphone-qa/normal-circle-stage.png>), and [return to homepage](</path/to/developer/Documents/AI Stuff/SacredUniverse/Design/iphone-qa/normal-homepage-after-navigation.png>), with the [passing launch-test summary](</path/to/developer/Documents/AI Stuff/SacredUniverse/Design/iphone-qa/normal-launch-test-summary.json>).

## How the models are framed

The app distinguishes mathematical relationships, chosen units, approximate astronomy, and geometric comparisons. Decimal digital-root patterns depend on base 10; the units switch does not alter geometry. Solid totals sum planar face-interior angles, while actual mesh edges and vertex counts establish Euler's relation. Precession is a schematic constant-period model: the video's symbolic 25,920 years can be compared with an approximate 25,772 years; real precession varies. The Moon/Sun comparison uses representative [NASA Moon measurements](https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html) and [Sun measurements](https://nssdc.gsfc.nasa.gov/planetary/factsheet/sunfact.html). Pyramid dimensions are rounded and numerical proximity does not establish historical design intent.

Each experiment's source sheet opens the corresponding video passage and explains the model's assumptions. The film's religious and historical interpretations remain attributed to its perspective. Original explanations and geometry are bundled offline; source links open externally.

## Structure

- `App/Models/UniverseModel.swift`: shared state, learning transitions, predictions, local persistence.
- `App/Views/SacredStage.swift`: eight parameter-driven vector scenes and the atlas mandala.
- `App/Views/LaboratoryView.swift`: live readouts, controls, and the learning flow.
- `App/Sensory/UniverseFeedback.swift`: optional synthesized chimes and native feedback.
- `Sources/SacredCore`: base arithmetic, angle conversions, precession, regular polygons, and actual Platonic meshes.
- `Tests/SacredCoreTests`, `UITests`: mathematical checks and learner-facing interaction scenarios.

No third-party runtime dependencies, remote content requirement, analytics, or account setup.


## Public snapshot

See [PUBLICATION.md](PUBLICATION.md) for publication exclusions and setup requirements.
