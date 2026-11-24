`timescale 1ns/1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       tx_start,
    input  wire [7:0] tx_byte,
    output reg        tx_active,
    output reg        tx_serial,
    output reg        tx_done
);

    localparam s_IDLE  = 3'b000;
    localparam s_START = 3'b001;
    localparam s_DATA  = 3'b010;
    localparam s_STOP  = 3'b011;

    reg [2:0]  state     = s_IDLE;
    reg [11:0] clk_count = 12'd0;
    reg [2:0]  bit_index = 3'd0;
    reg [7:0]  data_reg  = 8'h00;

    always @(posedge clk) begin
        case (state)
            s_IDLE: begin
                tx_serial <= 1'b1;
                tx_done   <= 1'b0;
                clk_count <= 12'd0;
                bit_index <= 3'd0;

                if (tx_start == 1'b1) begin
                    tx_active <= 1'b1;
                    data_reg  <= tx_byte;
                    state     <= s_START;
                end else begin
                    tx_active <= 1'b0;
                end
            end

            s_START: begin
                tx_serial <= 1'b0;
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                end else begin
                    clk_count <= 12'd0;
                    state     <= s_DATA;
                end
            end

            s_DATA: begin
                tx_serial <= data_reg[bit_index];
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                end else begin
                    clk_count <= 12'd0;
                    if (bit_index < 3'd7) begin
                        bit_index <= bit_index + 1'b1;
                    end else begin
                        bit_index <= 3'd0;
                        state     <= s_STOP;
                    end
                end
            end

            s_STOP: begin
                tx_serial <= 1'b1;
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                end else begin
                    tx_done   <= 1'b1;
                    clk_count <= 12'd0;
                    state     <= s_IDLE;
                end
            end

            default: state <= s_IDLE;
        endcase
    end

endmodule
