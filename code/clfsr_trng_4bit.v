`timescale 1ns/1ps

module clfsr_trng_4bit #(
    parameter [15:0]        LFSR_INIT_SEED    = 16'hA3C5,
    parameter signed [15:0] CHAOTIC_INIT_SEED = 16'sh7EF0
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire [3:0]  trng_in,

    output wire [3:0]  lfsr_sel,
    output wire [3:0]  chaos_sel,

    output wire [3:0]  clfsr_vec,
    output wire [3:0]  random_bits_4,
    output wire        random_bit,

    output reg  [7:0]  R_Out,
    output reg         key_ready,
    output wire [7:0]  random_byte,
    output wire        byte_ready
);

    assign random_byte = R_Out;
    assign byte_ready  = key_ready;
    assign random_bit  = random_bits_4[0];

    reg [15:0] lfsr;
    wire lfsr_feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10] ^ trng_in[0] ^ trng_in[2];

    wire [3:0] lfsr_taps = {lfsr[15], lfsr[10], lfsr[5], lfsr[0]};

    assign lfsr_sel = {lfsr[14], lfsr[11], lfsr[6], lfsr[1]};

    reg signed [15:0] x;
    reg signed [31:0] x_square;
    reg signed [31:0] x_mult;
    reg signed [15:0] x_section;
    reg signed [15:0] x_sub;

    wire [3:0] chaos_taps = {x[13], x[10], x[7], x[4]};

    assign chaos_sel = {x[12], x[9], x[6], x[2]};

    assign clfsr_vec = lfsr_taps ^ chaos_taps;
    wire [3:0] raw_fused_bits = clfsr_vec ^ trng_in;

    reg [3:0] decorr_p1;
    reg [3:0] decorr_p2;
    reg [3:0] decorr_p3;
    reg [3:0] decorr_p4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            decorr_p1 <= 4'h0;
            decorr_p2 <= 4'h0;
            decorr_p3 <= 4'h0;
            decorr_p4 <= 4'h0;
        end else if (enable) begin
            decorr_p1 <= raw_fused_bits;
            decorr_p2 <= decorr_p1;
            decorr_p3 <= decorr_p2;
            decorr_p4 <= decorr_p3;
        end
    end

    assign random_bits_4 = decorr_p1 ^ decorr_p2 ^ decorr_p4;

    reg [1:0] byte_phase;
    reg [3:0] lower_nibble;
    reg [7:0] byte_reg0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr         <= LFSR_INIT_SEED;
            x            <= CHAOTIC_INIT_SEED;
            x_square     <= 32'sh0;
            x_mult       <= 32'sh0;
            x_section    <= 16'sh0;
            x_sub        <= CHAOTIC_INIT_SEED;
            byte_phase   <= 2'b00;
            lower_nibble <= 4'h0;
            byte_reg0    <= 8'h00;
            R_Out        <= 8'h00;
            key_ready    <= 1'b0;
        end else if (enable) begin

            lfsr <= {lfsr[14:9], lfsr[8] ^ trng_in[1], lfsr[7:5], lfsr[4] ^ trng_in[3], lfsr[3:0], lfsr_feedback};

            x_square  <= x * x;
            x_mult    <= x_square <<< 1;
            x_section <= x_mult[30:15];
            x_sub     <= 16'sh7FFF - x_section;
            x         <= x_sub ^ {14'h0, trng_in[1:0]};

            case (byte_phase)
                2'b00: begin

                    lower_nibble <= random_bits_4;
                    key_ready    <= 1'b0;
                    byte_phase   <= 2'b01;
                end
                2'b01: begin

                    byte_reg0    <= {random_bits_4, lower_nibble};
                    key_ready    <= 1'b0;
                    byte_phase   <= 2'b10;
                end
                2'b10: begin

                    lower_nibble <= random_bits_4;
                    key_ready    <= 1'b0;
                    byte_phase   <= 2'b11;
                end
                2'b11: begin

                    R_Out        <= {random_bits_4, lower_nibble} ^ byte_reg0;
                    key_ready    <= 1'b1;
                    byte_phase   <= 2'b00;
                end
            endcase
        end else begin
            key_ready <= 1'b0;
        end
    end

endmodule
