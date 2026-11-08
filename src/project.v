/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none   // safety: typos in wire names become errors instead of new wires

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
module tt_um_badbyte_systolic (     // <-- change to your name
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire done;

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;
    mm_core core (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (ui_in),
        .cmd      (uio_in[1:0]),
        .strobe   (uio_in[2]),
        .data_out (uo_out),
        .done     (done)
    );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};
    assign uio_out = {done, 7'b0000000};   // only pin 7 is used as an output
    assign uio_oe  = 8'b1000_0000;         // pin 7 = output, pins 0-6 = inputs

    // tell the tools these inputs are intentionally unused (prevents warnings)
    wire _unused = &{ena, uio_in[7:3], 1'b0};
endmodule
