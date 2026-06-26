`timescale 1ns/1ps

module tb_udp_parser;

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

    logic [15:0] udp_src_port;
    logic [15:0] udp_dst_port;
    logic [15:0] udp_length;
    logic [15:0] udp_checksum;

    logic        udp_header_valid;
    logic        market_data_packet;
    logic        dns_packet;

    logic        not_ipv4;
    logic        not_udp;
    logic        invalid_version;
    logic        unsupported_ihl;
    logic        parser_error;

    logic [7:0]  packet_byte_index;

    udp_parser dut (
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

        .udp_src_port(udp_src_port),
        .udp_dst_port(udp_dst_port),
        .udp_length(udp_length),
        .udp_checksum(udp_checksum),

        .udp_header_valid(udp_header_valid),
        .market_data_packet(market_data_packet),
        .dns_packet(dns_packet),

        .not_ipv4(not_ipv4),
        .not_udp(not_udp),
        .invalid_version(invalid_version),
        .unsupported_ihl(unsupported_ihl),
        .parser_error(parser_error),

        .packet_byte_index(packet_byte_index)
    );

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

    task reset_dut;
        begin
            rst_n    = 1'b0;
            data_in  = 8'h00;
            valid_in = 1'b0;
            sop_in   = 1'b0;
            eop_in   = 1'b0;

            repeat (3) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    task send_eth_ipv4_until_protocol(
        input logic [7:0] protocol_value,
        input logic       eop_on_protocol
    );
        begin
            // Ethernet destination MAC
            send_byte(8'hAA, 1'b1, 1'b0);
            send_byte(8'hBB, 1'b0, 1'b0);
            send_byte(8'hCC, 1'b0, 1'b0);
            send_byte(8'hDD, 1'b0, 1'b0);
            send_byte(8'hEE, 1'b0, 1'b0);
            send_byte(8'hFF, 1'b0, 1'b0);

            // Ethernet source MAC
            send_byte(8'h11, 1'b0, 1'b0);
            send_byte(8'h22, 1'b0, 1'b0);
            send_byte(8'h33, 1'b0, 1'b0);
            send_byte(8'h44, 1'b0, 1'b0);
            send_byte(8'h55, 1'b0, 1'b0);
            send_byte(8'h66, 1'b0, 1'b0);

            // EtherType = IPv4
            send_byte(8'h08, 1'b0, 1'b0);
            send_byte(8'h00, 1'b0, 1'b0);

            // IPv4 header through protocol byte
            send_byte(8'h45, 1'b0, 1'b0); // Version = 4, IHL = 5
            send_byte(8'h00, 1'b0, 1'b0); // DSCP/ECN
            send_byte(8'h00, 1'b0, 1'b0); // Total length high
            send_byte(8'h26, 1'b0, 1'b0); // Total length low

            send_byte(8'h00, 1'b0, 1'b0); // Identification high
            send_byte(8'h01, 1'b0, 1'b0); // Identification low

            send_byte(8'h40, 1'b0, 1'b0); // Flags/fragment high
            send_byte(8'h00, 1'b0, 1'b0); // Flags/fragment low

            send_byte(8'h40, 1'b0, 1'b0); // TTL
            send_byte(protocol_value, 1'b0, eop_on_protocol);
        end
    endtask

    task send_remaining_ipv4_header;
        begin
            // Header checksum
            send_byte(8'hB7, 1'b0, 1'b0);
            send_byte(8'h57, 1'b0, 1'b0);

            // Source IP: 192.168.1.10
            send_byte(8'hC0, 1'b0, 1'b0);
            send_byte(8'hA8, 1'b0, 1'b0);
            send_byte(8'h01, 1'b0, 1'b0);
            send_byte(8'h0A, 1'b0, 1'b0);

            // Destination IP: 192.168.1.20
            send_byte(8'hC0, 1'b0, 1'b0);
            send_byte(8'hA8, 1'b0, 1'b0);
            send_byte(8'h01, 1'b0, 1'b0);
            send_byte(8'h14, 1'b0, 1'b0);
        end
    endtask

    task send_udp_header(
        input logic eop_on_checksum_low
    );
        begin
            // Source port = 5000 = 0x1388
            send_byte(8'h13, 1'b0, 1'b0);
            send_byte(8'h88, 1'b0, 1'b0);

            // Destination port = 6000 = 0x1770
            send_byte(8'h17, 1'b0, 1'b0);
            send_byte(8'h70, 1'b0, 1'b0);

            // UDP length = 18 = 0x0012
            send_byte(8'h00, 1'b0, 1'b0);
            send_byte(8'h12, 1'b0, 1'b0);

            // UDP checksum = 0
            send_byte(8'h00, 1'b0, 1'b0);
            send_byte(8'h00, 1'b0, eop_on_checksum_low);
        end
    endtask

    initial begin
        $dumpfile("sim/udp_parser.vcd");
        $dumpvars(0, tb_udp_parser);

        clk = 1'b0;

        reset_dut();

        $display("Starting udp_parser tests...");

        // ------------------------------------------------------------
        // TEST 1: Valid Ethernet + IPv4 + UDP packet
        // ------------------------------------------------------------
        send_eth_ipv4_until_protocol(8'd17, 1'b0);
        send_remaining_ipv4_header();
        send_udp_header(1'b1);

        if (udp_header_valid !== 1'b1) begin
            $display("TEST 1 FAILED: udp_header_valid was not asserted.");
            $finish;
        end

        if (udp_src_port !== 16'd5000) begin
            $display("TEST 1 FAILED: expected source port 5000, got %0d.", udp_src_port);
            $finish;
        end

        if (udp_dst_port !== 16'd6000) begin
            $display("TEST 1 FAILED: expected destination port 6000, got %0d.", udp_dst_port);
            $finish;
        end

        if (udp_length !== 16'd18) begin
            $display("TEST 1 FAILED: expected UDP length 18, got %0d.", udp_length);
            $finish;
        end

        if (udp_checksum !== 16'h0000) begin
            $display("TEST 1 FAILED: expected UDP checksum 0, got %h.", udp_checksum);
            $finish;
        end

        if (market_data_packet !== 1'b1) begin
            $display("TEST 1 FAILED: market_data_packet was not asserted.");
            $finish;
        end

        $display("TEST 1 PASSED: valid UDP header parsed correctly.");

        repeat (3) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 2: IPv4 packet with TCP protocol should assert not_udp
        // Protocol = 6
        // ------------------------------------------------------------
        send_eth_ipv4_until_protocol(8'd6, 1'b1);

        if (not_udp !== 1'b1) begin
            $display("TEST 2 FAILED: not_udp was not asserted.");
            $finish;
        end

        $display("TEST 2 PASSED: non-UDP IPv4 packet detected correctly.");

        repeat (3) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 3: UDP packet ending before UDP header completes
        // ------------------------------------------------------------
        send_eth_ipv4_until_protocol(8'd17, 1'b0);
        send_remaining_ipv4_header();

        // Start UDP header but end too early
        send_byte(8'h13, 1'b0, 1'b0);
        send_byte(8'h88, 1'b0, 1'b0);
        send_byte(8'h17, 1'b0, 1'b1);

        if (parser_error !== 1'b1) begin
            $display("TEST 3 FAILED: parser_error was not asserted for short UDP header.");
            $finish;
        end

        $display("TEST 3 PASSED: short UDP header detected correctly.");

        repeat (3) @(negedge clk);

        $display("ALL UDP PARSER TESTS PASSED.");
        $finish;
    end

endmodule