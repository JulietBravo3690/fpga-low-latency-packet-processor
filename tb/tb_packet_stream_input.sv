`timescale 1ns/1ps

module tb_packet_stream_input;

    logic clk;
    logic rst_n;

    logic [7:0] data_in;
    logic       valid_in;
    logic       sop_in;
    logic       eop_in;

    logic [7:0] data_out;
    logic       valid_out;
    logic       sop_out;
    logic       eop_out;

    logic       in_packet;
    logic       packet_done;
    logic       packet_error;
    logic [15:0] byte_count;
    logic [15:0] last_packet_length;

    packet_stream_input dut (
        .clk(clk),
        .rst_n(rst_n),

        .data_in(data_in),
        .valid_in(valid_in),
        .sop_in(sop_in),
        .eop_in(eop_in),

        .data_out(data_out),
        .valid_out(valid_out),
        .sop_out(sop_out),
        .eop_out(eop_out),

        .in_packet(in_packet),
        .packet_done(packet_done),
        .packet_error(packet_error),
        .byte_count(byte_count),
        .last_packet_length(last_packet_length)
    );

    // 100 MHz clock: 10 ns period
    always #5 clk = ~clk;

    task send_byte(
        input logic [7:0] byte_value,
        input logic       sop_value,
        input logic       eop_value
    );
        begin
            @(negedge clk);
            data_in  = byte_value;
            valid_in = 1'b1;
            sop_in   = sop_value;
            eop_in   = eop_value;

            @(negedge clk);
            data_in  = 8'h00;
            valid_in = 1'b0;
            sop_in   = 1'b0;
            eop_in   = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("sim/packet_stream_input.vcd");
        $dumpvars(0, tb_packet_stream_input);

        clk      = 1'b0;
        rst_n    = 1'b0;
        data_in  = 8'h00;
        valid_in = 1'b0;
        sop_in   = 1'b0;
        eop_in   = 1'b0;

        // Reset
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        $display("Starting packet_stream_input tests...");

        // ------------------------------------------------------------
        // TEST 1: Send a valid 4-byte packet
        // ------------------------------------------------------------
        send_byte(8'hAA, 1'b1, 1'b0);
        send_byte(8'hBB, 1'b0, 1'b0);
        send_byte(8'hCC, 1'b0, 1'b0);
        send_byte(8'hDD, 1'b0, 1'b1);

        if (packet_done !== 1'b1) begin
            $display("TEST 1 FAILED: packet_done was not asserted.");
            $finish;
        end

        if (last_packet_length !== 16'd4) begin
            $display("TEST 1 FAILED: expected packet length 4, got %0d.", last_packet_length);
            $finish;
        end

        $display("TEST 1 PASSED: valid 4-byte packet received.");

        repeat (2) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 2: Send invalid data without SOP
        // ------------------------------------------------------------
        send_byte(8'h11, 1'b0, 1'b0);

        if (packet_error !== 1'b1) begin
            $display("TEST 2 FAILED: packet_error was not asserted.");
            $finish;
        end

        $display("TEST 2 PASSED: error detected for data without SOP.");

        repeat (2) @(negedge clk);

        $display("ALL TESTS PASSED.");
        $finish;
    end

endmodule