module mm_core (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,
    input  wire [1:0] cmd,
    input  wire       strobe,
    output wire [7:0] data_out,
    output wire       done
);
    localparam CMD_WRITE = 2'b01, CMD_START = 2'b10, CMD_READ = 2'b11;
    localparam IDLE = 2'd0, RUN = 2'd1, DONE = 2'd2;

    // ---- synchronizer (2 flops) + edge detect (3rd flop) ----
    reg [2:0] stb_q;
    always @(posedge clk) begin
        if (!rst_n) stb_q <= 3'b000;
        else        stb_q <= {stb_q[1:0], strobe};
    end
    wire go = stb_q[1] & ~stb_q[2];   // high for exactly ONE clock per strobe

    // ---- storage and control registers ----
    reg signed [7:0] mem [0:7];   // 0-3: A00 A01 A10 A11   4-7: B00 B01 B10 B11
    reg [2:0] wr_ptr;             // next byte to write (0-7)
    reg [3:0] rd_ptr;             // next byte to read (0-11)
    reg [1:0] state;
    reg [1:0] step;               // which cycle of the schedule (0-3)
    integer k;

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0; rd_ptr <= 0; state <= IDLE; step <= 0;
            for (k = 0; k < 8; k = k + 1) mem[k] <= 8'sd0;
        end else begin
            if (go && state != RUN) begin
                case (cmd)
                    CMD_WRITE: begin
                        mem[wr_ptr] <= data_in;
                        wr_ptr      <= wr_ptr + 1;
                    end
                    CMD_START: begin
                        state  <= RUN;
                        step   <= 0;
                        wr_ptr <= 0;      // ready for the next load
                        rd_ptr <= 0;      // read from the first byte
                    end
                    CMD_READ:
                        rd_ptr <= (rd_ptr == 4'd11) ? 4'd0 : rd_ptr + 1;
                    default: ;
                endcase
            end
            if (state == RUN) begin
                step <= step + 1;
                if (step == 2'd3) state <= DONE;   // PE11 finishes on step 3
            end
        end
    end

    // ---- the skew schedule from Step 6, now in hardware ----
    reg signed [7:0] a0, a1, b0, b1;
    reg clr;
    always @(*) begin
        a0 = 0; a1 = 0; b0 = 0; b1 = 0; clr = 0;     // defaults: no latches (Step 2)
        if (state == RUN) begin
            case (step)
                2'd0: begin a0 = mem[0]; b0 = mem[4]; clr = 1; end              // A00, B00
                2'd1: begin a0 = mem[1]; a1 = mem[2]; b0 = mem[6]; b1 = mem[5]; end
                2'd2: begin a1 = mem[3]; b1 = mem[7]; end                       // A11, B11
                default: ;                                                       // zeros
            endcase
        end
    end

    // ---- the array (Step 7) ----
    wire signed [23:0] c00, c01, c10, c11;
    systolic2x2 array (.clk(clk), .rst_n(rst_n), .clear(clr),
                       .a0(a0), .a1(a1), .b0(b0), .b1(b1),
                       .c00(c00), .c01(c01), .c10(c10), .c11(c11));

    // ---- output: pick one byte out of 12 ----
    wire [95:0] results = {c11, c10, c01, c00};
    assign data_out = results[rd_ptr*8 +: 8];      // 8 bits starting at rd_ptr*8
    assign done     = (state == DONE);
endmodule
