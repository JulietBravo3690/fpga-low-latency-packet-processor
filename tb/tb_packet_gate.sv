`timescale 1ns/1ps
module tb_packet_gate;
    logic clk = 0, rst_n = 0;
    logic [7:0] data_in;
    logic valid_in, in_ready, sop_in, eop_in;
    logic decision_valid, allow_packet;
    logic [7:0] data_out;
    logic valid_out, out_ready, sop_out, eop_out;
    logic overflow_error;
    integer received;

    packet_gate #(.BUFFER_DEPTH(16), .INDEX_WIDTH(4)) dut (.*);
    always #5 clk = ~clk;

    task send_byte(input logic [7:0] value, input logic sop, input logic eop);
        begin
            @(negedge clk);
            data_in = value;
            valid_in = 1;
            sop_in = sop;
            eop_in = eop;
            while (!in_ready) @(negedge clk);
            @(negedge clk);
            valid_in = 0;
            sop_in = 0;
            eop_in = 0;
        end
    endtask

    initial begin
        valid_in = 0;
        sop_in = 0;
        eop_in = 0;
        decision_valid = 0;
        allow_packet = 0;
        out_ready = 0;
        received = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;

        send_byte(8'h11, 1, 0);
        send_byte(8'h22, 0, 0);
        send_byte(8'h33, 0, 1);
        @(negedge clk);
        decision_valid = 1;
        allow_packet = 1;
        @(negedge clk);
        decision_valid = 0;
        repeat (2) @(negedge clk);
        if (!valid_out || data_out != 8'h11 || !sop_out)
            $fatal(1, "first output mismatch");

        repeat (2) begin
            @(posedge clk); #1;
            if (data_out != 8'h11) $fatal(1, "output changed under stall");
        end

        @(negedge clk);
        out_ready = 1;
        while (received < 3) begin
            @(posedge clk);
            if (valid_out) begin
                case (received)
                    0: if (data_out != 8'h11 || !sop_out) $fatal;
                    1: if (data_out != 8'h22) $fatal;
                    2: if (data_out != 8'h33 || !eop_out) $fatal;
                endcase
                received = received + 1;
            end
        end

        @(negedge clk);
        out_ready = 0;
        send_byte(8'hAA, 1, 0);
        send_byte(8'hBB, 0, 1);
        @(negedge clk);
        decision_valid = 1;
        allow_packet = 0;
        @(negedge clk);
        decision_valid = 0;
        repeat (3) @(negedge clk);
        if (valid_out) $fatal(1, "dropped bytes escaped");
        if (overflow_error) $fatal(1, "unexpected overflow");

        send_byte(8'h00, 1, 0);
        repeat (15) send_byte(8'h55, 0, 0);
        send_byte(8'hFF, 0, 1);
        repeat (3) @(negedge clk);
        if (!overflow_error || valid_out || !in_ready)
            $fatal(1, "oversize frame handling failed");

        $display("packet_gate tests PASSED");
        $finish;
    end
endmodule
