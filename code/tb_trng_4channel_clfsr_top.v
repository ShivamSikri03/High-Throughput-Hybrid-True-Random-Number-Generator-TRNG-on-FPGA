`timescale 1ns/1ps

`include "RO_3.v"
`include "RO_5.v"
`include "RO.v"
`include "FIRO_main.v"
`include "D_FF.v"
`include "clfsr_trng_4bit.v"
`include "trng_4channel_clfsr_top.v"

module tb_trng_4channel_clfsr_top;

    parameter TOTAL_BYTES = 25000;
    parameter CLK_PERIOD  = 10;

    reg clk;
    reg rst;
    reg enable;

    wire [3:0] random_bits_4;
    wire [3:0] clfsr_vec;
    wire [3:0] trng_sampled_4bit;
    wire [3:0] raw_osc_out;
    wire       final_random_bit;
    wire [7:0] R_Out;
    wire       key_ready;

    integer file_id;
    integer byte_count = 0;
    integer ones_count = 0;
    integer zeros_count = 0;

    trng_4channel_clfsr_top #(
        .LFSR_INIT_SEED    (16'hA3C5),
        .CHAOTIC_INIT_SEED (16'sh7EF0)
    ) dut (
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

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $display("============================================================================");
        $display(" Starting Simulation: 4-MUX Multi-Oscillator + 4-Bit CLFSR TRNG Core");
        $display(" Target Architecture : 400 Mbps Throughput (4 bits/cycle @ 100 MHz)");
        $display(" Byte Assembly Rate  : 1 Byte every 2 clock cycles (50 MB/s)");
        $display(" Features            : 4 Independent 4:1 MUXes + Ring-Coupled Jitter Hopping");
        $display("============================================================================");

        file_id = $fopen("sim_extracted_bits.txt", "w");
        if (file_id == 0) begin
            $display("[ERROR] Could not open output file 'sim_extracted_bits.txt'.");
            $finish;
        end

        clk        = 0;
        rst        = 1;
        enable     = 1;
        byte_count = 0;

        #(CLK_PERIOD * 4);
        rst = 0;
        $display("[TB] Reset released at %0t ns. All 4 oscillators & MUXes active...", $time);
    end

    integer cycle_idx = 0;
    always @(posedge clk) begin
        if (!rst && enable && cycle_idx < 12) begin
            $display("  [%0t ns] Cycle #%02d | Raw Osc=%04b | Sync Sampled=%04b | CLFSR Vec=%04b | Random Bits=%04b | Key Ready=%0b",
                     $time, cycle_idx + 1, raw_osc_out, trng_sampled_4bit, clfsr_vec, random_bits_4, key_ready);
            cycle_idx <= cycle_idx + 1;
        end
    end

    integer i;
    always @(posedge clk) begin
        if (!rst && enable && key_ready && byte_count < TOTAL_BYTES) begin
            $fwrite(file_id, "%08b", R_Out);

            for (i = 0; i < 8; i = i + 1) begin
                if (R_Out[i])
                    ones_count = ones_count + 1;
                else
                    zeros_count = zeros_count + 1;
            end

            byte_count <= byte_count + 1;

            if ((byte_count + 1) % 5000 == 0) begin
                $display("  [%0t ns] Collected %0d / %0d bytes (%0d%% complete)...",
                         $time, byte_count + 1, TOTAL_BYTES, ((byte_count + 1) * 100) / TOTAL_BYTES);
            end

            if (byte_count + 1 == TOTAL_BYTES) begin
                $display("============================================================================");
                $display(" [SUCCESS] Simulation complete!");
                $display(" Bit Balance: Ones = %0d, Zeros = %0d (Ratio = %0.5f)",
                         ones_count, zeros_count, (ones_count * 1.0) / (ones_count + zeros_count));
                $display(" Simulation Time Taken: %0t ns", $time);
                $display("============================================================================");
                $fclose(file_id);
                $finish;
            end
        end
    end

endmodule
