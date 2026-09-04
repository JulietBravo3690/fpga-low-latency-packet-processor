`timescale 1ns/1ps
module tb_tcp_parser;
    logic clk = 0;
    logic rst_n = 0;
    logic [7:0] data_in = 0;
    logic valid_in = 0;
    logic sop_in = 0;
    logic eop_in = 0;
    logic [15:0] tcp_src_port;
    logic [15:0] tcp_dst_port;
    logic [3:0] tcp_data_offset;
    logic [7:0] tcp_flags;
    logic [7:0] packet_byte_index;
    logic tcp_header_valid, not_tcp, parser_error;
    logic not_tcp_seen, parser_error_seen;
    logic [7:0] frame [0:53];
    integer index;

    tcp_parser dut (.*);
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            not_tcp_seen <= 1'b0;
            parser_error_seen <= 1'b0;
        end else begin
            if (not_tcp) not_tcp_seen <= 1'b1;
            if (parser_error) parser_error_seen <= 1'b1;
        end
    end

    task send_frame(input integer length, input logic insert_gaps);
        begin
            for (index = 0; index < length; index = index + 1) begin
                if (insert_gaps && (index % 4 == 0)) begin
                    @(negedge clk);
                    valid_in = 0;
                    sop_in = 0;
                    eop_in = 0;
                end
                @(negedge clk);
                data_in = frame[index];
                valid_in = 1;
                sop_in = (index == 0);
                eop_in = (index == length - 1);
            end
            @(negedge clk);
            valid_in = 0;
            sop_in = 0;
            eop_in = 0;
        end
    endtask

    task init_tcp(input logic [15:0] destination_port);
        begin
            for (index = 0; index < 54; index = index + 1)
                frame[index] = 0;
            frame[12] = 8'h08;
            frame[14] = 8'h45;
            frame[17] = 8'h28;
            frame[23] = 8'h06;
            frame[34] = 8'h13;
            frame[35] = 8'h88;
            frame[36] = destination_port[15:8];
            frame[37] = destination_port[7:0];
            frame[46] = 8'h50;
            frame[47] = 8'h12;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;

        init_tcp(16'd80);
        send_frame(54, 1);
        if (!tcp_header_valid || parser_error || tcp_src_port != 5000 ||
            tcp_dst_port != 80 || tcp_data_offset != 5 || tcp_flags != 8'h12)
            $fatal(1, "valid TCP parse failed");

        repeat (2) @(negedge clk);
        init_tcp(16'd443);
        send_frame(48, 0);
        if (!parser_error || tcp_header_valid)
            $fatal(1, "short TCP header accepted");

        repeat (2) @(negedge clk);
        parser_error_seen = 0;
        init_tcp(16'd80);
        frame[46] = 8'h60;
        send_frame(54, 0);
        if (!parser_error_seen || tcp_header_valid)
            $fatal(1, "TCP options were accepted by fixed fast path");

        repeat (2) @(negedge clk);
        not_tcp_seen = 0;
        init_tcp(16'd80);
        frame[23] = 8'd17;
        send_frame(54, 0);
        if (!not_tcp_seen || tcp_header_valid)
            $fatal(1, "non-TCP protocol accepted");

        $display("tcp_parser tests PASSED");
        $finish;
    end
endmodule
