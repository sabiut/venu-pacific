# Manual test checklist: Calamares install-to-disk

This is the checklist for the one piece of the release path that needs a real mouse and
therefore can't be automated in a headless/scripted VM: actually clicking through Calamares
and confirming the installed system boots. Everything above the "Partitions" step has already
been verified in an automated VM boot test (keyboard-only) on the `fix-calamares-installer`
branch — this list picks up from there.

Use real hardware (or any machine/VM where you have normal mouse+keyboard control) — not a
headless/scripted setup.

## What's already confirmed (no need to re-check)

- Boot menu shows exactly: `Live system (amd64)`, `Live system (amd64 fail-safe mode)`,
  `Utilities` — no conflicting classic-installer entries
- Live desktop boots, wallpaper renders correctly
- Welcome window appears once, dismisses correctly
- Calamares launches from the **Install Debian** desktop icon (or **Install System** in the
  applications menu) with no password prompt, and its sidebar shows all 8 steps: Welcome,
  Location, Keyboard, Partitions, Users, Summary, Install, Finish
- Welcome / Location / Keyboard pages populate with real data (keyboard layouts, timezone map,
  our virtual disk detected on the Partitions page)

**Note**: the ISO currently on the USB drive is built from the `fix-calamares-installer`
branch, not `phase-2-translation-framework` — so the welcome window will show the old button
styling (the "Get Started" button color fix is a separate, not-yet-merged PR). That's expected
and not a regression to worry about here.

## Before you start

- [ ] The live session's user account is `user` with **no password**, but if it sits idle for
      a few minutes the screensaver locks it — the unlock password is `live` (not written down
      anywhere in the product UI yet; that's a known gap to fix separately)
- [ ] Have a way to note down anything that looks wrong (screenshot, or just what step/message)

## 1. Partitions

- [ ] Select **Erase disk** (the target/only disk should be pre-selected if there's only one)
- [ ] Confirm **Next** becomes clickable once a disk is selected
- [ ] Click **Next**

## 2. Users

- [ ] Enter a full name, username, password (and confirm), and machine name
- [ ] Confirm validation catches an empty/too-short password if you deliberately test one
- [ ] Note whether "log in automatically" / "use the same password as administrator" checkboxes
      (if present) behave as labeled
- [ ] Click **Next**

## 3. Summary

- [ ] Review the summary screen — confirm it lists the disk being erased, the user being
      created, and the timezone/keyboard choices from earlier steps correctly
- [ ] Click **Install**

## 4. Install

- [ ] Confirm the progress bar/log moves (doesn't hang) — this step copies the whole system and
      will take several minutes
- [ ] Note any error dialogs, if they appear — screenshot and record the exact text
- [ ] Confirm it reaches **Finish** without needing you to close an error dialog first

## 5. Finish

- [ ] Click **Restart now** (or equivalent) — or manually reboot if it just says to
- [ ] **Remove the USB drive** when prompted / before the reboot completes, so it boots from
      the internal disk, not back into the live USB

## 6. First boot of the installed system

- [ ] Machine boots to a bootloader (GRUB) menu or straight to login — either is fine, just
      note which
- [ ] Login screen appears; log in with the username/password from step 2
- [ ] Desktop loads with the correct wallpaper (this is the thing the xfdesktop 4.20.1 bug
      originally broke — confirm it still shows correctly on a freshly installed system, not
      just the live session)
- [ ] Welcome window shows once on this first login too, and dismissing it means it doesn't
      show again on a second login/reboot
- [ ] Network, audio, and any built-in wifi work as expected for the hardware
- [ ] Synaptic launches and can search for a package (confirms apt/package management works
      post-install)

## If something fails

Note exactly which numbered step failed, the exact error text or screenshot, and the
hardware/VM you're on — same as the reporting guidance in
[install-guide.md](install-guide.md).

## After this passes

Once this checklist is clean, `docs/install-guide.md`'s "Not yet independently verified" note
about the Calamares install-to-disk flow can be removed — that's the actual gate for cutting a
first release (see the roadmap discussion: this was identified as the one blocking item).
