`timescale 1ns/1ps

module tb_top_packet_processor;

    localparam [2:0] CLASS_MALFORMED   = 3'd0;
    localparam [2:0] CLASS_NON_IPV4    = 3'd1;
    localparam [2:0] CLASS_MARKET_DATA = 3'd2;
    localparam [2:0] CLASS_DNS         = 3'd3;
    localparam [2:0] CLASS_WEB         = 3'd4;
    localparam [2:0] CLASS_CONTROL     = 3'd5;
    localparam [2:0] CLASS_TRUSTED     = 3'd6;
    localparam [2:0] CLASS_UNKNOWN     = 3'd7;

    logic clk;
    logic rst_n;

    logic [7:0] data_in;
    logic       valid_in;
    logic       sop_in;
    logic       eop_in;

    logic       drop_unknown;

    logic [7:0] data_out;
    logic       valid_out;
    logic       sop_out;
    logic       eop_out;

    logic [47:0] dest_mac;
    logic [47:0] src_mac;
    logic [15:0] ethertype;

    logic [3:0]  ip_version;
    logic [3:0]  ip_ihl;
    logic [15:0] ip_total_length;
    logic [7:0]  ip_protocol;
    logic [31:0] src_ip;
    logic [31:0] dst_ip;

    logic [15:0] udp_src_port;
    logic [15:0] udp_dst_port;
    logic [15:0] udp_length;
    logic [15:0] udp_checksum;

    logic        metadata_ready;
    logic        parser_error_any;

    logic        class_valid;
    logic [2:0]  packet_class;

    logic        allow_packet;
    logic        drop_packet;

    logic        malformed_packet;
    logic        non_ipv4_packet;
    logic        market_data_packet;
    logic        dns_packet;
    logic        web_packet;
    logic        control_packet;
    logic        trusted_packet;
    logic        unknown_packet;

    top_packet_processor dut (
        .clk(clk),
        .rst_n(rst_n),

        .data_in(data_in),
        .valid_in(valid_in),
        .sop_in(sop_in),
        .eop_in(eop_in),

        .drop_unknown(drop_unknown),

        .data_out(data_out),
        .valid_out(valid_out),
        .sop_out(sop_out),
        .eop_out(eop_out),

        .dest_mac(dest_mac),
        .src_mac(src_mac),
        .ethertype(ethertype),

        .ip_version(ip_version),
        .ip_ihl(ip_ihl),
        .ip_total_length(ip_total_length),
        .ip_protocol(ip_protocol),
        .src_ip(src_ip),
        .dst_ip(dst_ip),

        .udp_src_port(udp_src_port),
        .udp_dst_port(udp_dst_port),
        .udp_length(udp_length),
        .udp_checksum(udp_checksum),

        .metadata_ready(metadata_ready),
        .parser_error_any(parser_error_any),

        .class_valid(class_valid),
        .packet_class(packet_class),

        .allow_packet(allow_packet),
        .drop_packet(drop_packet),

        .malformed_packet(malformed_packet),
        .non_ipv4_packet(non_ipv4_packet),
        .market_data_packet(market_data_packet),
        .dns_packet(dns_packet),
        .web_packet(web_packet),
        .control_packet(control_packet),
        .trusted_packet(trusted_packet),
        .unknown_packet(unknown_packet)
    );

    always #5 clk = ~clk;

    task reset_dut;
        begin
            rst_n        = 1'b0;
            data_in      = 8'h00;
            valid_in     = 1'b0;
            sop_in       = 1'b0;
            eop_in       = 1'b0;
            drop_unknown = 1'b1;

            repeat (3) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

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

    task send_ethernet_header(
        input logic [15:0] ethertype_value,
        input logic        eop_on_ethertype
    );
        begin
            // Destination MAC: AA:BB:CC:DD:EE:FF
            send_byte(8'hAA, 1'b1, 1'b0);
            send_byte(8'hBB, 1'b0, 1'b0);
            send_byte(8'hCC, 1'b0, 1'b0);
            send_byte(8'hDD, 1'b0, 1'b0);
            send_byte(8'hEE, 1'b0, 1'b0);
            send_byte(8'hFF, 1'b0, 1'b0);

            // Source MAC: 11:22:33:44:55:66
            send_byte(8'h11, 1'b0, 1'b0);
            send_byte(8'h22, 1'b0, 1'b0);
            send_byte(8'h33, 1'b0, 1'b0);
            send_byte(8'h44, 1'b0, 1'b0);
            send_byte(8'h55, 1'b0, 1'b0);
            send_byte(8'h66, 1'b0, 1'b0);

            // EtherType
            send_byte(ethertype_value[15:8], 1'b0, 1'b0);
            send_byte(ethertype_value[7:0],  1'b0, eop_on_ethertype);
        end
    endtask

    task send_ipv4_header(
        input logic [7:0]  protocol_value,
        input logic [31:0] src_ip_value,
        input logic [31:0] dst_ip_value
    );
        begin
            send_byte(8'h45, 1'b0, 1'b0); // Version = 4, IHL = 5
            send_byte(8'h00, 1'b0, 1'b0); // DSCP/ECN

            send_byte(8'h00, 1'b0, 1'b0); // Total length high
            send_byte(8'h1C, 1'b0, 1'b0); // Total length low = 28 bytes

            send_byte(8'h00, 1'b0, 1'b0); // Identification high
            send_byte(8'h01, 1'b0, 1'b0); // Identification low

            send_byte(8'h40, 1'b0, 1'b0); // Flags/fragment high
            send_byte(8'h00, 1'b0, 1'b0); // Flags/fragment low

            send_byte(8'h40, 1'b0, 1'b0); // TTL
            send_byte(protocol_value, 1'b0, 1'b0);

            send_byte(8'h00, 1'b0, 1'b0); // Header checksum high, ignored for now
            send_byte(8'h00, 1'b0, 1'b0); // Header checksum low, ignored for now

            send_byte(src_ip_value[31:24], 1'b0, 1'b0);
            send_byte(src_ip_value[23:16], 1'b0, 1'b0);
            send_byte(src_ip_value[15:8],  1'b0, 1'b0);
            send_byte(src_ip_value[7:0],   1'b0, 1'b0);

            send_byte(dst_ip_value[31:24], 1'b0, 1'b0);
            send_byte(dst_ip_value[23:16], 1'b0, 1'b0);
            send_byte(dst_ip_value[15:8],  1'b0, 1'b0);
            send_byte(dst_ip_value[7:0],   1'b0, 1'b0);
        end
    endtask

    task send_udp_header(
        input logic [15:0] src_port_value,
        input logic [15:0] dst_port_value
    );
        begin
            send_byte(src_port_value[15:8], 1'b0, 1'b0);
            send_byte(src_port_value[7:0],  1'b0, 1'b0);

            send_byte(dst_port_value[15:8], 1'b0, 1'b0);
            send_byte(dst_port_value[7:0],  1'b0, 1'b0);

            send_byte(8'h00, 1'b0, 1'b0);
            send_byte(8'h08, 1'b0, 1'b0); // UDP length = 8 bytes, no payload

            send_byte(8'h00, 1'b0, 1'b0);
            send_byte(8'h00, 1'b0, 1'b1); // UDP checksum low + EOP
        end
    endtask

    task send_udp_packet(
        input logic [15:0] src_port_value,
        input logic [15:0] dst_port_value,
        input logic [31:0] src_ip_value,
        input logic [31:0] dst_ip_value
    );
        begin
            send_ethernet_header(16'h0800, 1'b0);
            send_ipv4_header(8'd17, src_ip_value, dst_ip_value);
            send_udp_header(src_port_value, dst_port_value);
        end
    endtask

    task send_non_ipv4_frame;
        begin
            // EtherType 0x0806 = ARP
            send_ethernet_header(16'h0806, 1'b1);
        end
    endtask

    task send_short_malformed_packet;
        begin
            send_byte(8'hAA, 1'b1, 1'b0);
            send_byte(8'hBB, 1'b0, 1'b0);
            send_byte(8'hCC, 1'b0, 1'b1);
        end
    endtask

    task wait_for_class(
        input string test_name
    );
        integer timeout;
        begin
            timeout = 0;

            while ((class_valid !== 1'b1) && (timeout < 80)) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (class_valid !== 1'b1) begin
                $display("%s FAILED: timed out waiting for class_valid.", test_name);
                $finish;
            end
        end
    endtask

    task check_class(
        input logic [2:0] expected_class,
        input logic       expected_allow,
        input logic       expected_drop,
        input string      test_name
    );
        begin
            wait_for_class(test_name);

            if (packet_class !== expected_class) begin
                $display("%s FAILED: expected class %0d, got %0d.", test_name, expected_class, packet_class);
                $finish;
            end

            if (allow_packet !== expected_allow) begin
                $display("%s FAILED: expected allow_packet %0d, got %0d.", test_name, expected_allow, allow_packet);
                $finish;
            end

            if (drop_packet !== expected_drop) begin
                $display("%s FAILED: expected drop_packet %0d, got %0d.", test_name, expected_drop, drop_packet);
                $finish;
            end

            $display("%s PASSED.", test_name);
        end
    endtask

    initial begin
        $dumpfile("sim/top_packet_processor.vcd");
        $dumpvars(0, tb_top_packet_processor);

        clk = 1'b0;

        reset_dut();

        $display("Starting top_packet_processor tests...");

        // ------------------------------------------------------------
        // TEST 1: Full end-to-end market-data UDP packet
        // UDP source port 5000, destination port 6000
        // ------------------------------------------------------------

        drop_unknown = 1'b1;

        send_udp_packet(
            16'd5000,
            16'd6000,
            32'h0A000001,
            32'h0A000002
        );

        check_class(CLASS_MARKET_DATA, 1'b1, 1'b0, "TEST 1");

        if (market_data_packet !== 1'b1) begin
            $display("TEST 1 FAILED: market_data_packet flag was not asserted.");
            $finish;
        end

        if (ethertype !== 16'h0800) begin
            $display("TEST 1 FAILED: expected EtherType 0x0800, got %h.", ethertype);
            $finish;
        end

        if (ip_protocol !== 8'd17) begin
            $display("TEST 1 FAILED: expected UDP protocol 17, got %0d.", ip_protocol);
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

        repeat (4) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 2: DNS UDP packet
        // UDP destination port 53
        // ------------------------------------------------------------

        send_udp_packet(
            16'd40000,
            16'd53,
            32'h0A000003,
            32'h0A000004
        );

        check_class(CLASS_DNS, 1'b1, 1'b0, "TEST 2");

        if (dns_packet !== 1'b1) begin
            $display("TEST 2 FAILED: dns_packet flag was not asserted.");
            $finish;
        end

        repeat (4) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 3: Trusted packet
        // Trusted source IP = 192.168.1.10
        // Unknown ports, but trusted endpoint
        // ------------------------------------------------------------

        send_udp_packet(
            16'd3000,
            16'd3001,
            32'hC0A8010A,
            32'h0A000005
        );

        check_class(CLASS_TRUSTED, 1'b1, 1'b0, "TEST 3");

        if (trusted_packet !== 1'b1) begin
            $display("TEST 3 FAILED: trusted_packet flag was not asserted.");
            $finish;
        end

        repeat (4) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 4: Unknown packet with drop_unknown enabled
        // ------------------------------------------------------------

        drop_unknown = 1'b1;

        send_udp_packet(
            16'd3000,
            16'd3001,
            32'h0A000006,
            32'h0A000007
        );

        check_class(CLASS_UNKNOWN, 1'b0, 1'b1, "TEST 4");

        if (unknown_packet !== 1'b1) begin
            $display("TEST 4 FAILED: unknown_packet flag was not asserted.");
            $finish;
        end

        repeat (4) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 5: Unknown packet with drop_unknown disabled
        // Same packet type, but configurable policy allows it
        // ------------------------------------------------------------

        drop_unknown = 1'b0;

        send_udp_packet(
            16'd3000,
            16'd3001,
            32'h0A000008,
            32'h0A000009
        );

        check_class(CLASS_UNKNOWN, 1'b1, 1'b0, "TEST 5");

        if (unknown_packet !== 1'b1) begin
            $display("TEST 5 FAILED: unknown_packet flag was not asserted.");
            $finish;
        end

        repeat (4) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 6: Non-IPv4 Ethernet frame should drop
        // ------------------------------------------------------------

        drop_unknown = 1'b1;

        send_non_ipv4_frame();

        check_class(CLASS_NON_IPV4, 1'b0, 1'b1, "TEST 6");

        if (non_ipv4_packet !== 1'b1) begin
            $display("TEST 6 FAILED: non_ipv4_packet flag was not asserted.");
            $finish;
        end

        repeat (4) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 7: Malformed short packet should drop
        // ------------------------------------------------------------

        send_short_malformed_packet();

        check_class(CLASS_MALFORMED, 1'b0, 1'b1, "TEST 7");

        if (malformed_packet !== 1'b1) begin
            $display("TEST 7 FAILED: malformed_packet flag was not asserted.");
            $finish;
        end

        repeat (4) @(negedge clk);

        $display("ALL TOP PACKET PROCESSOR TESTS PASSED.");
        $finish;
    end

endmodule