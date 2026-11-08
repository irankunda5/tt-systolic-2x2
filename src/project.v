`default_nettype none   // safety: typos in wire names become errors instead of new wires

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

    mm_core core (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (ui_in),
        .cmd      (uio_in[1:0]),
        .strobe   (uio_in[2]),
        .data_out (uo_out),
        .done     (done)
    );

    assign uio_out = {done, 7'b0000000};   // only pin 7 is used as an output
    assign uio_oe  = 8'b1000_0000;         // pin 7 = output, pins 0-6 = inputs

    // tell the tools these inputs are intentionally unused (prevents warnings)
    wire _unused = &{ena, uio_in[7:3], 1'b0};
endmodule 
