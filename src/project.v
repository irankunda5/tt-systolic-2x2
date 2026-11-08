  title:        "2x2 Systolic Array Matrix Multiplier"
  author:       "Your Name"
  description:  "int8 2x2 matrix multiply on an output-stationary systolic array"
  language:     "Verilog"
  clock_hz:     10000000          # 10 MHz: a safe, conservative speed
  tiles:        "1x2"             # chip area; we'll check this in Step 12
  top_module:   "tt_um_badbyte_systolic"   # must match project.v exactly
  source_files:
    - "project.v"
    - "mm_core.v"
    - "systolic2x2.v"
    - "pe.v"
    - "pulse.v"
