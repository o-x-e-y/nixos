# Converts a Dolphin GCPadNew.ini into WiiCompiled's [controller] TOML block.
#
# WiiCompiled's own importer (runtime/src/input_bindings.cpp) only understands
# Dolphin's XInput-style button names -- "Button X", "Button Y". Dolphin's SDL3
# backend writes *positional* names instead ("Button W", "Button N"), which that
# table has no entry for, so an import silently drops them. Converting here
# sidesteps that: positional names are rewritten to WiiCompiled's own vocabulary
# ("west", "north"), which its expression evaluator accepts as a fallback.
#
# Each control is emitted one of two ways:
#
#   * bound to a digital button -> a plain key (b = "west"). Native mapping, no
#     expression needed.
#   * bound to an analog trigger -> an expression (expr_1_buttons_a =
#     "Trigger R") plus the plain key set to "unmapped", so the default button
#     does not fire the control as well; expressions are additive (Apply() ORs
#     buttons and takes std::max of analog), never subtractive.
#
# The plain key matters most for Triggers/R. aurora only synthesises the GameCube
# R button from the R2 axis when no real button is mapped to it
# (`if (!rightTriggerSet && tr > activationZone)` in aurora-main's pad.cpp), so
# binding drift to a button is what frees R2 for anything else. Without that,
# R2 keeps drifting no matter what else it is bound to.
#
# Stick bindings are dropped: WiiCompiled's kControls covers buttons and
# triggers only, and maps the sticks natively.

function positional(name) {
    if (name == "Button S" || name == "Button A" || name == "Button 1") return "south"
    if (name == "Button E" || name == "Button B" || name == "Button 2") return "east"
    if (name == "Button W" || name == "Button X" || name == "Button 0") return "west"
    if (name == "Button N" || name == "Button Y" || name == "Button 3") return "north"
    if (name == "Shoulder L" || name == "Button 4") return "left_shoulder"
    if (name == "Shoulder R" || name == "Button 5") return "right_shoulder"
    if (name == "Thumb L"    || name == "Button 10") return "left_stick"
    if (name == "Thumb R"    || name == "Button 11") return "right_stick"
    if (name == "Start"      || name == "Button 9") return "start"
    if (name == "Back"       || name == "Button 8") return "back"
    if (name == "Guide"      || name == "Button 12") return "guide"
    if (name == "Pad N" || name == "Hat 0 N") return "dpad_up"
    if (name == "Pad S" || name == "Hat 0 S") return "dpad_down"
    if (name == "Pad W" || name == "Hat 0 W") return "dpad_left"
    if (name == "Pad E" || name == "Hat 0 E") return "dpad_right"
    return ""
}

# Names WiiCompiled resolves as analog trigger axes.
function isTriggerAxis(name) {
    return name == "Trigger L" || name == "Trigger R" ||
           name == "Full Axis Xr+" || name == "Full Axis Yr+"
}

# Dolphin control -> the plain [controller] key, or "" if not one we manage.
function plainKey(control) {
    if (control == "Buttons/A")     return "a"
    if (control == "Buttons/B")     return "b"
    if (control == "Buttons/X")     return "x"
    if (control == "Buttons/Y")     return "y"
    if (control == "Buttons/Z")     return "z"
    if (control == "Buttons/Start") return "start"
    if (control == "Triggers/L")    return "l"
    if (control == "Triggers/R")    return "r"
    if (control == "D-Pad/Up")      return "up"
    if (control == "D-Pad/Down")    return "down"
    if (control == "D-Pad/Left")    return "left"
    if (control == "D-Pad/Right")   return "right"
    return ""
}

# Dolphin control -> the expression key suffix, matching ConfigKey() in
# input_bindings.cpp: lowercased, with "/" and "-" turned into "_".
function exprSuffix(control,   out, i, c) {
    out = ""
    for (i = 1; i <= length(control); i++) {
        c = substr(control, i, 1)
        out = out ((c == "/" || c == "-") ? "_" : tolower(c))
    }
    return out
}

BEGIN {
    port = 0
    print "[controller]"
}

/^[[:space:]]*\[GCPad[0-9]+\][[:space:]]*$/ {
    match($0, /[0-9]+/)
    port = substr($0, RSTART, RLENGTH) + 0
    next
}

/^[[:space:]]*[A-Za-z-]+\/[A-Za-z-]+[[:space:]]*=/ {
    if (port < 1) next

    split($0, parts, "=")
    control = parts[1]
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", control)

    value = substr($0, index($0, "=") + 1)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    gsub(/`/, "", value)            # Dolphin quotes device inputs in backticks
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)

    key = plainKey(control)
    if (key == "" || value == "") next

    if (isTriggerAxis(value)) {
        # Analog trigger: only an expression can reach it.
        printf "%s = \"unmapped\"\n", key
        printf "expr_%d_%s = \"%s\"\n", port, exprSuffix(control), value
        next
    }

    mapped = positional(value)
    if (mapped != "") {
        printf "%s = \"%s\"\n", key, mapped
        # GameCube L/R are analog. The plain key only stops the host trigger
        # axis from synthesising the button; the analog travel that games
        # actually read still follows that axis until an expression assigns
        # it, so bind one too. Positional names go in the expression as well:
        # the evaluator accepts them via its FindNativeButton fallback.
        if (key == "l" || key == "r")
            printf "expr_%d_%s = \"%s\"\n", port, exprSuffix(control), mapped
        next
    }
    # Anything else (keyboard keys left over from Dolphin's default profile,
    # stick axes, compound expressions) is not something this can express.
}
