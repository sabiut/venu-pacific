# Release test checklist (v1 candidate)

One end-to-end pass over everything a user actually touches, on a **freshly installed system**
built from `main`. Distinct from [manual-test-checklist.md](manual-test-checklist.md), which is a
completed record of the Calamares install flow specifically — this one covers the whole product,
because the pieces have only ever been tested individually as they were built.

Run it in order: install, then first boot, then the apps. Note the machine used at the top of
your results — VM and real hardware behave differently in ways that matter (CPU features,
disk speed, RAM channels), and a pass on one is not a pass on the other.

**Machine tested:** _(fill in: VM with N vCPUs / real hardware model, RAM, disk type)_

## 0. The ISO itself

- [ ] Boots on the target machine (real hardware: check UEFI **and** legacy BIOS if the pilot
      machines vary)
- [ ] Boot splash shows the Venu Pacific Plymouth theme, not Debian's
- [ ] Live desktop reaches a usable state with the correct wallpaper
- [ ] Disc/media icon on the desktop reads **Venu Pacific** (not "Pacific Linux" — that was a
      real regression twice; it comes from `LB_ISO_VOLUME` and only changes in a newly built ISO)

## 1. Install to disk

The detailed flow lives in [manual-test-checklist.md](manual-test-checklist.md) and passed on
2026-07-21. Re-confirm only that it still completes on the current build:

- [ ] Calamares launches, branding shows **Venu Pacific** (logo + wordmark, no Debian branding)
- [ ] Erase disk → Users → Summary → Install → Finish completes with no error dialogs
- [ ] Reboots into the installed system (media removed / boot order changed)

## 2. First boot of the installed system

- [ ] Login screen (LightDM) shows the Venu Pacific wallpaper and the logo as the user image
- [ ] Log in; desktop shows the **sunrise-volcano** wallpaper
      (known risk: XFCE stores wallpaper per *monitor name* and the shipped default uses generic
      names — if the wallpaper is wrong/default here, that's the open item to fix in the
      first-login script)
- [ ] Welcome app appears once, Get Started button is teal (not white-on-white), and it does
      **not** reappear on a second login
- [ ] Switching the welcome app to Bislama changes the UI text
- [ ] Window shadows/dimming visible (compositing on; needs `vblank_mode=xpresent` in a VM)
- [ ] `grep PRETTY_NAME /etc/os-release` says Venu Pacific

## 3. The AI model service (the piece with the most history)

- [ ] `journalctl --user -u venu-pacific-llama | grep -c "couldn't bind"` → **0**
      (any bind failures mean the greeter-user port war is back)
- [ ] `sudo journalctl -b _UID=$(id -u lightdm) | grep -i llama` → **empty**
      (proves `ConditionUser=!@system` is keeping the login screen out)
- [ ] `systemctl --user is-active venu-pacific-llama` → `active`
- [ ] `systemctl --user status venu-pacific-llama-prewarm` → exited **0** (prewarm completed,
      not a false success)
- [ ] Wait ~3 min after login, then open the assistant and send "hey" — first reply arrives in
      **seconds**, not minutes (this is the whole point of the login prewarm)
- [ ] Note the real numbers: `journalctl --user -u venu-pacific-llama | grep print_timing | tail -6`
      — record prompt eval and eval tok/s **from a batch of 100+ tokens** (small batches give
      meaningless throughput figures; that mistake cost a diagnostic round once already)

## 4. Venu Pacific Hub

- [ ] Launches from the applications menu; hero tile + 2x2 grid render with accent-colored icon
      chips; no stock-grey chrome
- [ ] Each tile opens the right app: Ask → assistant, Learn → Kolibri in Firefox,
      Services → services directory, Safety → disaster readiness, Translate → assistant
- [ ] Hub stays open after launching a tile (it's a home screen, not a one-shot menu)

## 5. AI assistant

Chat and formatting:

- [ ] Long replies wrap inside the window (no horizontal growth)
- [ ] Text streams in visibly while generating rather than appearing all at once
- [ ] Pulsing logo shows while thinking, stops when the reply lands
- [ ] Text cursor is visible in the input box
- [ ] Chat history sidebar: new chat, switching conversations, delete (with confirmation)
- [ ] Conversations survive closing and reopening the app

Correctness (the behaviors that matter most for a school/office):

- [ ] **Ask a factual question** ("who founded Anthropic?") → it searches rather than asserting
      from memory, and names its source. A confident unverified answer here is a **release
      blocker** — that hallucination class is exactly what the strict-facts rule exists to stop.
- [ ] Ask a maths word problem → answer is plain text, **no LaTeX** (`\text{}`, `$...$`)
- [ ] Ask about cyclone safety in Vanuatu → answers from `get_disaster_info` with real contacts
- [ ] Ask about passports in Vanuatu → answers from `get_services_info`, not invented/US info
- [ ] Ask about a country **not** covered (e.g. Samoa) → says so honestly, does not fabricate
- [ ] Ask a general-knowledge question → searches the offline encyclopedia (Vikidia)
- [ ] Long conversation → when context runs out, a clear "start a new chat" message, not a crash

Tools — approval dialogs must appear for every gated one:

- [ ] Themed dialog: dark, no duplicate title, no grey system titlebar, teal top edge, buttons
      inside the dark body
- [ ] `search_internet` — dialog mentions mobile data; declining is respected
- [ ] `read_file` on a text file, and on a **PDF** (needs `poppler-utils`; a scanned/image-only
      PDF should say it has no readable text rather than returning garbage)
- [ ] `write_file` — dialog shows the path and a content preview, and warns on overwrite
- [ ] `find_file` — refuses paths outside the home directory
- [ ] `open_application` / `close_window` — dialog names the app/window
- [ ] Printer troubleshooting: asks about a printer → checks **both** status and queue;
      `cancel_print_jobs` is gated
- [ ] Auto (no-dialog) tools work without prompting: disk space, wifi status, battery, time,
      open windows

## 6. The other apps

- [ ] **Disaster Readiness**: opens, country selector works (Vanuatu + Fiji), hazard cards
      expand, emergency contacts card has the coral accent edge, source links present
- [ ] **Services Directory**: opens, both countries, categories expand, contacts/links present
- [ ] **Learn (Kolibri)**: launches, Firefox opens the local server, setup wizard appears.
      **Expected**: no content channels — v1 ships the app only. Confirm this reads as
      intentional to a first-time user, not broken.
- [ ] **Offline Content Guide** and **Vikidia**: both open; Vikidia has real bundled content
- [ ] **Synaptic**: launches and can search a package (apt works post-install)
- [ ] Update notification timer exists (`systemctl --user list-timers | grep venu`)

## 7. Hardware reality (real machines only)

- [ ] Wi-Fi, audio, display resolution, suspend/resume
- [ ] `sudo dmidecode -t memory` — **single or dual channel?** A second RAM stick is the single
      cheapest generation-speed win available (up to ~2x). Record it.
- [ ] `grep -c avx2 /proc/cpuinfo` — 0 means llama.cpp falls back to a much slower CPU variant
- [ ] Total install footprint vs disk size; RAM headroom with the assistant running
      (`free -h` while a reply generates)

## Result

_Record: date, machine, pass/fail per section, and any numbers gathered (tok/s, RAM, boot time).
Anything failing in sections 3 or 5 (model service, assistant correctness) should block the
release; sections 6-7 findings may be acceptable known limitations if documented._
