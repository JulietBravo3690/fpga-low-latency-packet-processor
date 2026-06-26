`timescale 1ns/1ps

module tb_ipv4_parser;

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

    logic [3:0]  ip_version;
    logic [3:0]  ip_ihl;
    logic [15:0] ip_total_length;
    logic [7:0]  ip_protocol;
    logic [31:0] src_ip;
    logic [31:0] dst_ip;

    logic        ipv4_header_valid;
    logic        udp_packet;
    logic        tcp_packet;
    logic        icmp_packet;

    logic        not_ipv4;
    logic        unsupported_ihl;
    logic        invalid_version;
    logic        parser_error;

    logic [7:0]  packet_byte_index;

    ipv4_parser dut (
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

        .ip_version(ip_version),
        .ip_ihl(ip_ihl),
        .ip_total_length(ip_total_length),
        .ip_protocol(ip_protocol),
        .src_ip(src_ip),
        .dst_ip(dst_ip),

        .ipv4_header_valid(ipv4_header_valid),
        .udp_packet(udp_packet),
        .tcp_packet(tcp_packet),
        .icmp_packet(icmp_packet),

        .not_ipv4(not_ipv4),
        .unsupported_ihl(unsupported_ihl),
        .invalid_version(invalid_version),
        .parser_error(parser_error),

        .packet_byte_index(packet_byte_index)
    );

    // 100 MHz clock
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

    task send_valid_ipv4_header;
        begin
            // Ethernet header
            send_byte(8'hAA, 1'b1, 1'b0);
            send_byte(8'hBB, 1'b0, 1'b0);
            send_byte(8'hCC, 1'b0, 1'b0);
            send_byte(8'hDD, 1'b0, 1'b0);
            send_byte(8'hEE, 1'b0, 1'b0);
            send_byte(8'hFF, 1'b0, 1'b0);

            send_byte(8'h11, 1'b0, 1'b0);
            send_byte(8'h22, 1'b0, 1'b0);
            send_byte(8'h33, 1'b0, 1'b0);
            send_byte(8'h44, 1'b0, 1'b0);
            send_byte(8'h55, 1'b0, 1'b0);
            send_byte(8'h66, 1'b0, 1'b0);

            // EtherType = IPv4
            send_byte(8'h08, 1'b0, 1'b0);
            send_byte(8'h00, 1'b0, 1'b0);

            // IPv4 header
            send_byte(8'h45, 1'b0, 1'b0); // Version = 4, IHL = 5
            send_byte(8'h00, 1'b0, 1'b0); // DSCP/ECN
            send_byte(8'h00, 1'b0, 1'b0); // Total length high
            send_byte(8'h26, 1'b0, 1'b0); // Total length low = 38

            send_byte(8'h00, 1'b0, 1'b0); // Identification high
            send_byte(8'h01, 1'b0, 1'b0); // Identification low

            send_byte(8'h40, 1'b0, 1'b0); // Flags/fragment high
            send_byte(8'h00, 1'b0, 1'b0); // Flags/fragment low

            send_byte(8'h40, 1'b0, 1'b0); // TTL
            send_byte(8'h11, 1'b0, 1'b0); // Protocol = UDP

            send_byte(8'hB7, 1'b0, 1'b0); // Header checksum high
            send_byte(8'h57, 1'b0, 1'b0); // Header checksum low

            send_byte(8'hC0, 1'b0, 1'b0); // Source IP: 192
            send_byte(8'hA8, 1'b0, 1'b0); // Source IP: 168
            send_byte(8'h01, 1'b0, 1'b0); // Source IP: 1
            send_byte(8'h0A, 1'b0, 1'b0); // Source IP: 10

            send_byte(8'hC0, 1'b0, 1'b0); // Destination IP: 192
            send_byte(8'hA8, 1'b0, 1'b0); // Destination IP: 168
            send_byte(8'h01, 1'b0, 1'b0); // Destination IP: 1
            send_byte(8'h14, 1'b0, 1'b0); // Destination IP: 20
        end
    endtask

    task send_udp_tail;
        begin
            // UDP header
            send_byte(8'h13, 1'b0, 1'b0); // Source port high: 5000
            send_byte(8'h88, 1'b0, 1'b0); // Source port low

            send_byte(8'h17, 1'b0, 1'b0); // Destination port high: 6000
            send_byte(8'h70, 1'b0, 1'b0); // Destination port low

            send_byte(8'h00, 1'b0, 1'b0); // UDP length high
            send_byte(8'h12, 1'b0, 1'b0); // UDP length low = 18

            send_byte(8'h00, 1'b0, 1'b0); // UDP checksum high
            send_byte(8'h00, 1'b0, 1'b0); // UDP checksum low

            // Payload: HELLO_FPGA
            send_byte(8'h48, 1'b0, 1'b0); // H
            send_byte(8'h45, 1'b0, 1'b0); // E
            send_byte(8'h4C, 1'b0, 1'b0); // L
            send_byte(8'h4C, 1'b0, 1'b0); // L
            send_byte(8'h4F, 1'b0, 1'b0); // O
            send_byte(8'h5F, 1'b0, 1'b0); // _
            send_byte(8'h46, 1'b0, 1'b0); // F
            send_byte(8'h50, 1'b0, 1'b0); // P
            send_byte(8'h47, 1'b0, 1'b0); // G
            send_byte(8'h41, 1'b0, 1'b1); // A, end of packet
        end
    endtask

    initial begin
        $dumpfile("sim/ipv4_parser.vcd");
        $dumpvars(0, tb_ipv4_parser);

        clk = 1'b0;

        reset_dut();

        $display("Starting ipv4_parser tests...");

        // ------------------------------------------------------------
        // TEST 1: Valid Ethernet + IPv4 + UDP packet
        // ------------------------------------------------------------

        send_valid_ipv4_header();

        if (ipv4_header_valid !== 1'b1) begin
            $display("TEST 1 FAILED: ipv4_header_valid was not asserted.");
            $finish;
        end

        if (ip_version !== 4'd4) begin
            $display("TEST 1 FAILED: expected IP version 4, got %0d.", ip_version);
            $finish;
        end

        if (ip_ihl !== 4'd5) begin
            $display("TEST 1 FAILED: expected IHL 5, got %0d.", ip_ihl);
            $finish;
        end

        if (ip_total_length !== 16'h0026) begin
            $display("TEST 1 FAILED: expected total length 0x0026, got %h.", ip_total_length);
            $finish;
        end

        if (ip_protocol !== 8'd17) begin
            $display("TEST 1 FAILED: expected protocol UDP/17, got %0d.", ip_protocol);
            $finish;
        end

        if (src_ip !== 32'hC0A8010A) begin
            $display("TEST 1 FAILED: wrong source IP. Got %h.", src_ip);
            $finish;
        end

        if (dst_ip !== 32'hC0A80114) begin
            $display("TEST 1 FAILED: wrong destination IP. Got %h.", dst_ip);
            $finish;
        end

        if (udp_packet !== 1'b1) begin
            $display("TEST 1 FAILED: udp_packet was not asserted.");
            $finish;
        end

        send_udp_tail();

        $display("TEST 1 PASSED: valid IPv4/UDP packet parsed correctly.");

        repeat (3) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 2: Non-IPv4 EtherType should assert not_ipv4
        // EtherType 0x0806 = ARP
        // ------------------------------------------------------------

        send_byte(8'hAA, 1'b1, 1'b0);
        send_byte(8'hBB, 1'b0, 1'b0);
        send_byte(8'hCC, 1'b0, 1'b0);
        send_byte(8'hDD, 1'b0, 1'b0);
        send_byte(8'hEE, 1'b0, 1'b0);
        send_byte(8'hFF, 1'b0, 1'b0);

        send_byte(8'h11, 1'b0, 1'b0);
        send_byte(8'h22, 1'b0, 1'b0);
        send_byte(8'h33, 1'b0, 1'b0);
        send_byte(8'h44, 1'b0, 1'b0);
        send_byte(8'h55, 1'b0, 1'b0);
        send_byte(8'h66, 1'b0, 1'b0);

        send_byte(8'h08, 1'b0, 1'b0);
        send_byte(8'h06, 1'b0, 1'b1);

        if (not_ipv4 !== 1'b1) begin
            $display("TEST 2 FAILED: not_ipv4 was not asserted.");
            $finish;
        end

        $display("TEST 2 PASSED: non-IPv4 frame detected correctly.");

        repeat (3) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 3: Short IPv4 packet should trigger parser_error
        // ------------------------------------------------------------

        send_byte(8'hAA, 1'b1, 1'b0);
        send_byte(8'hBB, 1'b0, 1'b0);
        send_byte(8'hCC, 1'b0, 1'b0);
        send_byte(8'hDD, 1'b0, 1'b0);
        send_byte(8'hEE, 1'b0, 1'b0);
        send_byte(8'hFF, 1'b0, 1'b0);

        send_byte(8'h11, 1'b0, 1'b0);
        send_byte(8'h22, 1'b0, 1'b0);
        send_byte(8'h33, 1'b0, 1'b0);
        send_byte(8'h44, 1'b0, 1'b0);
        send_byte(8'h55, 1'b0, 1'b0);
        send_byte(8'h66, 1'b0, 1'b0);

        send_byte(8'h08, 1'b0, 1'b0);
        send_byte(8'h00, 1'b0, 1'b0);

        send_byte(8'h45, 1'b0, 1'b0);
        send_byte(8'h00, 1'b0, 1'b1);

        if (parser_error !== 1'b1) begin
            $display("TEST 3 FAILED: parser_error was not asserted for short IPv4 packet.");
            $finish;
        end

        $display("TEST 3 PASSED: short IPv4 packet detected correctly.");

        repeat (3) @(negedge clk);

        $display("ALL IPV4 PARSER TESTS PASSED.");
        $finish;
    end

endmodule