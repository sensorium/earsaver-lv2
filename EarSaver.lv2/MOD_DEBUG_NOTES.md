# EarSaver MOD Debug Postmortem

## Final State

- The LED now lights from the `muting` output as intended.
- Startup blink debug behavior was removed.
- On startup, mute LED initializes to unlit and then follows runtime `muting` updates.
- Knob animation works using a horizontal filmstrip and `mod-widget="film"` on the knob element.
- Switch/bezel and mute visuals are aligned to actual audio operation (not inverse).
- When the plugin is switched off (bypassed), mute sprites are hidden (powered-down state).

## Original Symptom

- The UI callback loaded and ran.
- Turning the threshold knob reached JavaScript.
- The LED did not react when the DSP actually muted audio.

## Important Findings

- In this project, `lv2:index` inside `modgui:port` is the GUI control slot index, not the global LV2 port index.
- `modgui:port` should list visible GUI controls only. Adding the `muting` output port there creates a phantom control instead of monitoring the output.
- MOD input-control updates and output-control updates follow different paths. If knob changes reach JavaScript but output changes do not, inspect monitored output registration before changing front-end code.
- The generated Heavy/DPF source already emits a `muting` send and maps it to an output parameter, so the main failure was on the MOD GUI metadata side, not the DSP side.
- The `modgui/earsaver.js` file is stored as a MOD callback snippet, not standalone JavaScript, so editor syntax errors at line 1 can be false positives.

## Root Cause

MOD reads monitored outputs from the modgui metadata, not from the LV2 output control port declaration alone.

The key detail is syntax: `modgui:monitoredOutputs` is parsed by MOD as one or more nodes containing `lv2:symbol`, not as a plain string literal. The string form was valid Turtle, but MOD ignored it for monitored output registration.

Because `muting` was not registered as a monitored output, MOD never sent `monitor_output` for that symbol, so no `output_set` events reached the browser and the LED callback never saw `event.symbol === "muting"` during runtime.

## Relevant Runtime Path

The relevant MOD path for output control notifications was:

- `add_plugin`
- `get_plugin_info_essentials`
- `monitoredOutputs`
- `monitor_output <instance> muting`
- mod-host `output_set`
- websocket forward to browser
- `gui.setOutputPortValue(symbol, value)`
- modgui `triggerJS({ type: 'change', symbol, value })`

The DSP side for this plugin was already wired: generated Heavy/DPF code emitted a `muting` send through the send hook, and the plugin mapped that send to the output parameter.

## Working TTL Form

```turtle
modgui:monitoredOutputs [
  lv2:symbol "muting" ;
] ;
```

## Cache And Deployment Notes

- MOD can pick up changed modgui JavaScript while still using stale plugin metadata from the loaded Lilv world.
- If monitored outputs do not take effect but JavaScript changes do, restart mod-ui or reboot the device so plugin info is rescanned.
- Keep the deployed bundle and workspace copy of `modgui.ttl` in sync.

## Wrong Turns Worth Remembering

- Using the global LV2 port index in `modgui:port` caused the threshold knob mapping bug.
- Adding `muting` as a GUI port created a phantom control instead of solving output monitoring.
- A new browser ruled out browser cache, but that alone could not rule out MOD metadata caching.

## Additional GUI Lessons Worth Reusing

- MOD film knob animation advances frames on the X axis. Vertical strips do not animate correctly; convert to horizontal strips and size CSS as `background-size: auto <frameHeight>`.
- Keep icon template binding explicit for film knobs: `mod-role="input-control-port"`, correct `mod-port-symbol`, and `mod-widget="film"`.
- In icon templates, CSS sibling selectors (`~`) only target later siblings. If footswitch state must control another layer, place that layer after `.mod-footswitch` in HTML.
- `mod-footswitch` class polarity can be counterintuitive for a given design. Verify `.on` vs `.off` by audible behavior, not by naming assumptions.
- For "powered down" UX, gate decorative state overlays with bypass state in CSS (for example default hidden, show only in active-audio state).
- Keep source and deployed modgui trees synchronized for every HTML/CSS/JS and asset change to avoid regressions between local edits and on-device behavior.

## Quick Checklist Before Testing

- Confirm metadata wiring: `modgui:monitoredOutputs` uses node form with `lv2:symbol` entries, and output symbols (for example `muting`) are not added to `modgui:port` GUI controls.

- Confirm cache/deployment state: deployed bundle and workspace files match (`modgui.ttl`, icon HTML, CSS, JS, assets), and if monitored outputs still do not fire, restart mod-ui or reboot before deeper debugging.

- Confirm knob animation prerequisites: knob film asset is horizontal strip (not vertical), knob binding includes `mod-widget="film"` and correct `mod-port-symbol`, and CSS uses the correct frame sizing pattern (for example `background-size: auto 64px`).

- Confirm runtime behavior by ear first, then visuals: toggle bypass and verify audible on/off state, check switch/bezel overlay matches audible active state, and check mute indicator matches actual muted audio condition.

- Confirm powered-down behavior: in bypass/off state, decorative runtime indicators (including mute sprites) are hidden; in active state, indicators reappear and track live output changes.
