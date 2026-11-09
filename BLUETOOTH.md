# Bluetooth connection investigation — 2026-10-21

## Stuttering update — 2026-10-23

Stuttering was reproduced with local audio while downloading over 5 GHz Wi-Fi.
With Realtek RTL8852CE firmware 0.27.129.4 it cut; the same download test with
0.27.56.14 was smooth according to the listener. A separate firmware override
was installed at `/usr/lib/firmware/updates/rtw89/rtw8852c_fw-2.bin.zst` and
verified by reloading Wi-Fi and checking the kernel-reported version. The
normal packaged firmware files remain intact; no initramfs changes were needed.

The firmware workaround is a machine-level change, not bundled into this
dotfiles installer. Its scripts, comparison results and undo instructions are
in `/home/spaul16/Projects/sony-audio-check/README.md`. The separate
music-profile reconnection issue is not established as fixed by this test.
The older entries below retain the state known during the earlier investigation.

## Current state after returning to the previous arrangement

The custom connection implementation described below has been removed from
both the live setup and this saved configuration. The three Bluetooth panels
and service loader match the saved pre-investigation baseline; the two custom
BluetoothAudio service files are removed. Other desktop customizations remain.

Blueman now starts at login through Hyprland's `execs.lua`, as in the previous
dotfiles. Its desktop autostart override remains hidden to avoid a second
startup path. The Sony-specific generic reconnect preference added during
troubleshooting has also been removed. Headset pairing/trust remain saved.

Backups of the removed implementation and startup files are under
`~/.config/caelestia/backups/restore-blueman-20261021-164000/`.
The remaining sections record the earlier investigation and tests, not the
currently active implementation. Stuttering remains unresolved.

## Confirmed failure

Sony WH-1000XM3 remained paired, bonded, trusted and `Connected: yes`,
but PipeWire had no output for its address. Explicitly connecting the remote
Audio Sink profile (`0000110b-0000-1000-8000-00805f9b34fb`) created the output.
This is a profile connection failure, not lost pairing.

Caelestia's three connection controls previously only toggled
`BluetoothDevice.connected`. The installed Quickshell implementation in
`src/bluetooth/device.cpp` returns immediately from both `setConnected(true)`
and `connect()` when BlueZ's Connected property is already true. Its
`onConnectedChanged()` also maps that flag directly to the Connected state.
Consequently, the UI had no audio readiness check or way to request a missing
music profile on a connected device. The underlying reason BlueZ sometimes
establishes only a control connection remains unconfirmed.

## Audit of earlier changes

- Pairing and trust were repaired and survived subsequent sessions.
- Blueman startup was added on October 17 and removed on October 20. Its
  AutoConnect plugin skips devices already marked Connected, so it does not
  address this failure. Blueman remains installed but does not autostart.
- The SBC-XQ and forced 2048-frame buffer experiments did not resolve the
  reported cuts and were reverted. No permanent audio tuning was installed.
- Manually connecting A2DP restored sound but did not change Caelestia's logic.

## Local Caelestia change

`BluetoothAudio.qml` creates one `BluetoothAudioConnection.qml` controller per
device. Audio devices are matched to real PipeWire outputs by Bluetooth
address. Other device types retain Quickshell's existing connection behavior.

For a trusted, connected audio device without an output, wait 2.5 seconds for
normal negotiation, then make one bounded ConnectProfile request. This also
handles a control-only link present when the shell starts. Select the output
only after it actually appears following that request. Do not change the
user's output selection for an already-working headset.

Caelestia's connect buttons can explicitly request music, even while the
control link is connected. A missing output is labelled Audio unavailable;
the details page offers Connect audio and Disconnect. Failures produce a
message rather than an endless retry loop. Intentional Disconnect suppresses
automatic music recovery until an explicit Connect action in this shell
session, even if the headset immediately reconnects its control link.

No Bluetooth daemon restart, system BlueZ configuration changes, extra daemon,
periodic reconnection loop, package rebuild, or phone-disconnect operation is
part of this change. A phone holding the music connection may still need to
release it. Stuttering is a separate, unresolved issue.

## Live checks

Using the installed Quickshell and actual Sony in an isolated test instance:

- An already-working output was left alone; the mouse was excluded.
- DisconnectProfile reproduced Connected=true with no audio output. The new
  controller restored the stereo output and selected it automatically.
- Starting the controller with that failure already present restored output.
- Intentional Disconnect did not restart music when the control link returned.
- Explicit Connect restored output after intentional Disconnect.
- A second profile loss in the same session did not trigger repeated automatic
  attempts; explicit Connect audio restored it.
- All three modified UI components compiled through Qt.createComponent.
- A failed connection attempt exposed a bounded failure state during testing;
  its underlying BlueZ error was `br-connection-aborted-by-local`.

These checks establish behavior for the reproduced condition. Physical headset
power cycles, laptop reboot/resume, phone handoff and audible playback quality
still need longer-term verification.
