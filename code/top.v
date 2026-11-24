`timescale 1ns/1ps

module top #(

    parameter UART_CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       enable,
    output wire       uart_out,
    output wire [7:0] led
);

    wire [3:0] random_bits_4;
    wire [3:0] clfsr_vec;
    wire [3:0] trng_sampled_4bit;
    wire [3:0] raw_osc_out;
    wire       final_random_bit;
    wire [7:0] R_Out;
    wire       key_ready;

    trng_4channel_clfsr_top #(
        .LFSR_INIT_SEED    (16'hA3C5),
        .CHAOTIC_INIT_SEED (16'sh7EF0)
    ) u_trng_core (
        .clk               (clk),
        .rst               (rst),
        .enable            (enable),
        .random_bits_4     (random_bits_4),
        .clfsr_vec         (clfsr_vec),
        .trng_sampled_4bit (trng_sampled_4bit),
        .raw_osc_out       (raw_osc_out),
        .final_random_bit  (final_random_bit),
        .R_Out             (R_Out),
        .key_ready         (key_ready),
        .random_byte       (),
        .byte_ready        ()
    );

    reg        uart_start = 1'b0;
    reg  [7:0] uart_tx_data = 8'h00;
    wire       uart_active;
    wire       uart_done;

    reg [7:0] byte_holding_reg = 8'h00;
    always @(posedge clk) begin
        if (key_ready) begin
            byte_holding_reg <= R_Out;
        end
    end

    uart_tx #(
        .CLKS_PER_BIT(UART_CLKS_PER_BIT)
    ) u_uart_tx (
        .clk       (clk),
        .tx_start  (uart_start),
        .tx_byte   (uart_tx_data),
        .tx_active (uart_active),
        .tx_serial (uart_out),
        .tx_done   (uart_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            uart_start   <= 1'b0;
            uart_tx_data <= 8'h00;
        end else if (enable) begin
            if (!uart_start && !uart_active) begin
                uart_tx_data <= byte_holding_reg;
                uart_start   <= 1'b1;
            end else begin
                uart_start   <= 1'b0;
            end
        end else begin
            uart_start <= 1'b0;
        end
    end

    reg [5:0] led_shift = 6'd0;
    always @(posedge clk) begin
        if (enable) begin

            led_shift <= {led_shift[1:0], random_bits_4};
        end
    end

    assign led[0]   = enable;
    assign led[1]   = uart_active;
    assign led[7:2] = led_shift;

endmodule
