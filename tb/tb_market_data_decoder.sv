`timescale 1ns/1ps
module tb_market_data_decoder;
    logic clk = 0, rst_n = 0, valid_in = 0, eop_in = 0;
    logic [7:0] data_in = 0;
    logic market_header_valid = 0, market_packet = 0;
    logic [15:0] udp_length = 0;
    logic message_valid, decoder_error;
    logic [7:0] message_type;
    logic [31:0] symbol, price, quantity, sequence_number;

    market_data_decoder dut (.*);
    always #5 clk = ~clk;

    task drive(input logic [7:0] value, input logic last);
        @(negedge clk); market_header_valid = 0; data_in = value; valid_in = 1; eop_in = last;
    endtask

    initial begin
        repeat (2) @(negedge clk); rst_n = 1;
        @(negedge clk); market_header_valid = 1; market_packet = 1;
        udp_length = 25; data_in = 8'h01; valid_in = 1;
        drive("A", 0); drive("A", 0); drive("P", 0); drive("L", 0);
        drive(8'h00, 0); drive(8'h00, 0); drive(8'h48, 0); drive(8'h5D, 0);
        drive(8'h00, 0); drive(8'h00, 0); drive(8'h00, 0); drive(8'h64, 0);
        drive(8'h00, 0); drive(8'h00, 0); drive(8'h00, 0); drive(8'h2A, 1);
        @(posedge clk); #1;
        if (!message_valid || message_type != 1 || symbol != "AAPL" ||
            price != 18525 || quantity != 100 || sequence_number != 42)
            $fatal(1, "decoded market message did not match input");

        @(negedge clk); valid_in = 0; eop_in = 0;
        @(negedge clk); market_header_valid = 1; market_packet = 1;
        udp_length = 16; valid_in = 0;
        @(posedge clk); #1;
        if (!decoder_error) $fatal(1, "short declared payload was accepted");
        $display("market_data_decoder tests PASSED");
        $finish;
    end
endmodule
