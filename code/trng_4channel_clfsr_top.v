`timescale 1ns/1ps

module trng_4channel_clfsr_top #(
    parameter [15:0]        LFSR_INIT_SEED    = 16'hA3C5,
    parameter signed [15:0] CHAOTIC_INIT_SEED = 16'sh7EF0
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,

    output wire [3:0]  random_bits_4,
    output wire [3:0]  clfsr_vec,
    output wire [3:0]  trng_sampled_4bit,
    output wire [3:0]  raw_osc_out,
    output wire        final_random_bit,

    output wire [7:0]  R_Out,
    output wire        key_ready,
    output wire [7:0]  random_byte,
    output wire        byte_ready
);

    (* DONT_TOUCH = "TRUE" *) wire ro3_out;
    (* DONT_TOUCH = "TRUE" *) wire ro5_out;
    (* DONT_TOUCH = "TRUE" *) wire ro_out;
    (* DONT_TOUCH = "TRUE" *) wire firo_out;

    RO_3 u_ro3 (
        .enable (enable),
        .out    (ro3_out)
    );

    RO_5 u_ro5 (
        .enable (enable),
        .out    (ro5_out)
    );

    RO u_ro (
        .enable   (enable),
        .RO1_out  (ro_out)
    );

    FIRO_main u_firo (
        .enable (enable),
        .out    (firo_out)
    );

    wire [3:0] raw_osc = {firo_out, ro_out, ro5_out, ro3_out};
    assign raw_osc_out = raw_osc;

    (* DONT_TOUCH = "TRUE" *) wire [3:0] mux_dff_fb;
    (* DONT_TOUCH = "TRUE" *) reg  [3:0] mux_raw;
    (* DONT_TOUCH = "TRUE" *) wire [1:0] sel0, sel1, sel2, sel3;
    wire [3:0] lfsr_sel;
    wire [3:0] chaos_sel;

    assign sel0 = {lfsr_sel[0], mux_dff_fb[3] ^ chaos_sel[0]};
    assign sel1 = {lfsr_sel[1], mux_dff_fb[0] ^ chaos_sel[1]};
    assign sel2 = {lfsr_sel[2], mux_dff_fb[1] ^ chaos_sel[2]};
    assign sel3 = {lfsr_sel[3], mux_dff_fb[2] ^ chaos_sel[3]};

    always @(*) begin
        case (sel0)
            2'b00:   mux_raw[0] = ro3_out;
            2'b01:   mux_raw[0] = ro5_out;
            2'b10:   mux_raw[0] = ro_out;
            2'b11:   mux_raw[0] = firo_out;
            default: mux_raw[0] = 1'b0;
        endcase
    end

    always @(*) begin
        case (sel1)
            2'b00:   mux_raw[1] = ro5_out;
            2'b01:   mux_raw[1] = ro_out;
            2'b10:   mux_raw[1] = firo_out;
            2'b11:   mux_raw[1] = ro3_out;
            default: mux_raw[1] = 1'b0;
        endcase
    end

    always @(*) begin
        case (sel2)
            2'b00:   mux_raw[2] = ro_out;
            2'b01:   mux_raw[2] = firo_out;
            2'b10:   mux_raw[2] = ro3_out;
            2'b11:   mux_raw[2] = ro5_out;
            default: mux_raw[2] = 1'b0;
        endcase
    end

    always @(*) begin
        case (sel3)
            2'b00:   mux_raw[3] = firo_out;
            2'b01:   mux_raw[3] = ro3_out;
            2'b10:   mux_raw[3] = ro5_out;
            2'b11:   mux_raw[3] = ro_out;
            default: mux_raw[3] = 1'b0;
        endcase
    end

    D_FF u_dff_fb0 (.clk(clk), .in(mux_raw[0]), .out(mux_dff_fb[0]));
    D_FF u_dff_fb1 (.clk(clk), .in(mux_raw[1]), .out(mux_dff_fb[1]));
    D_FF u_dff_fb2 (.clk(clk), .in(mux_raw[2]), .out(mux_dff_fb[2]));
    D_FF u_dff_fb3 (.clk(clk), .in(mux_raw[3]), .out(mux_dff_fb[3]));

    (* DONT_TOUCH = "TRUE" *) wire [3:0] sync_stage1;
    (* DONT_TOUCH = "TRUE" *) wire [3:0] sync_stage2;

    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin : gen_dual_rank_sync

            D_FF u_sync1 (
                .clk (clk),
                .in  (mux_raw[k]),
                .out (sync_stage1[k])
            );

            D_FF u_sync2 (
                .clk (clk),
                .in  (sync_stage1[k]),
                .out (sync_stage2[k])
            );
        end
    endgenerate

    reg [3:0] tff_state = 4'b0000;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tff_state <= 4'b0000;
        end else if (enable) begin
            tff_state <= tff_state ^ sync_stage2;
        end
    end

    assign trng_sampled_4bit = tff_state;

    clfsr_trng_4bit #(
        .LFSR_INIT_SEED    (LFSR_INIT_SEED),
        .CHAOTIC_INIT_SEED (CHAOTIC_INIT_SEED)
    ) u_clfsr_4bit (
        .clk           (clk),
        .rst           (rst),
        .enable        (enable),
        .trng_in       (trng_sampled_4bit),
        .lfsr_sel      (lfsr_sel),
        .chaos_sel     (chaos_sel),
        .clfsr_vec     (clfsr_vec),
        .random_bits_4 (random_bits_4),
        .random_bit    (final_random_bit),
        .R_Out         (R_Out),
        .key_ready     (key_ready),
        .random_byte   (random_byte),
        .byte_ready    (byte_ready)
    );

endmodule
