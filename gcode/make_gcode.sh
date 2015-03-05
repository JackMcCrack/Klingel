#!/bin/bash

set -e

EAGLE="/home/jack/eagle-6.6.0/bin/eagle"
PCB2GCODE="/home/jack/Downloads/pcb2gcode/pcb2gcode"

BOARDS=../*.brd

for BRD in $BOARDS
do
    BASENAME=$(basename --suffix=".brd" "$BRD")

    # Run Eagle CAM processor
    # -X- -X+ is a workaround for a segfault in Eagle < 7.11
    $EAGLE -X- -X+ -c+ -dGERBER_RS274X -opcb2gcode.front   "$BRD" Top Pads Vias
    $EAGLE -X- -X+ -c+ -dGERBER_RS274X -opcb2gcode.back    "$BRD" Bottom Pads Vias
    $EAGLE -X- -X+ -c+ -dEXCELLON      -opcb2gcode.drill   "$BRD" Drills Holes
    $EAGLE -X- -X+ -c+ -dGERBER_RS274X -opcb2gcode.outline "$BRD" Dimension

    # Eagle does not put the files in cwd, but next to $BRD. Well...
    mv ../pcb2gcode.{front,back,drill,outline} .
    rm ../pcb2gcode.{dri,gpi}

    $PCB2GCODE --front pcb2gcode.front --back pcb2gcode.back --drill pcb2gcode.drill --basename "$BASENAME"
    $PCB2GCODE --outline pcb2gcode.outline --basename "$BASENAME"

    # Take out the one remaining tool change.
    sed -i "/^T.$/,/^M0/d" "${BASENAME}_drill.ngc"
done

# Clean up after ourselves
rm *.png
rm pcb2gcode.{front,back,drill,outline}
