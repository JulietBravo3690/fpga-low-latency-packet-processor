`timescale 1ns/1ps

module tb_packet_classifier;

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

    logic        metadata_valid;
    logic        parser_error;
    logic [15:0] ethertype;
    logic [7:0]  ip_protocol;
    logic [31:0] src_ip;
    logic [31:0] dst_ip;
    logic [15:0] src_port;
    logic [15:0] dst_port;
    logic        drop_unknown;

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

    packet_classifier dut (
        .clk(clk),
        .rst_n(rst_n),

        .metadata_valid(metadata_valid),
        .parser_error(parser_error),

        .ethertype(ethertype),
        .ip_protocol(ip_protocol),
        .src_ip(src_ip),
        .dst_ip(dst_ip),
        .src_port(src_port),
        .dst_port(dst_port),

        .drop_unknown(drop_unknown),

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
            rst_n          = 1'b0;
            metadata_valid = 1'b0;
            parser_error   = 1'b0;
            ethertype      = 16'h0000;
            ip_protocol    = 8'd0;
            src_ip         = 32'd0;
            dst_ip         = 32'd0;
            src_port       = 16'd0;
            dst_port       = 16'd0;
            drop_unknown   = 1'b1;

            repeat (3) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    task classify_packet(
        input logic        parser_error_value,
        input logic [15:0] ethertype_value,
        input logic [7:0]  ip_protocol_value,
        input logic [31:0] src_ip_value,
        input logic [31:0] dst_ip_value,
        input logic [15:0] src_port_value,
        input logic [15:0] dst_port_value,
        input logic        drop_unknown_value
    );
        begin
            @(negedge clk);

            parser_error   = parser_error_value;
            ethertype      = ethertype_value;
            ip_protocol    = ip_protocol_value;
            src_ip         = src_ip_value;
            dst_ip         = dst_ip_value;
            src_port       = src_port_value;
            dst_port       = dst_port_value;
            drop_unknown   = drop_unknown_value;
            metadata_valid = 1'b1;

            @(negedge clk);
            metadata_valid = 1'b0;
        end
    endtask

    task check_class(
        input logic [2:0] expected_class,
        input logic       expected_allow,
        input logic       expected_drop,
        input string      test_name
    );
        begin
            if (class_valid !== 1'b1) begin
                $display("%s FAILED: class_valid was not asserted.", test_name);
                $finish;
            end

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
        $dumpfile("sim/packet_classifier.vcd");
        $dumpvars(0, tb_packet_classifier);

        clk = 1'b0;

        reset_dut();

        $display("Starting packet_classifier tests...");

        // ------------------------------------------------------------
        // TEST 1: UDP market-data style packet
        // IPv4, UDP, destination port 6000
        // ------------------------------------------------------------
        classify_packet(
            1'b0,
            16'h0800,
            8'd17,
            32'h0A000001,
            32'h0A000002,
            16'd5000,
            16'd6000,
            1'b1
        );

        check_class(CLASS_MARKET_DATA, 1'b1, 1'b0, "TEST 1");

        if (market_data_packet !== 1'b1) begin
            $display("TEST 1 FAILED: market_data_packet was not asserted.");
            $finish;
        end

        repeat (2) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 2: DNS packet
        // UDP destination port 53
        // ------------------------------------------------------------
        classify_packet(
            1'b0,
            16'h0800,
            8'd17,
            32'h0A000003,
            32'h0A000004,
            16'd40000,
            16'd53,
            1'b1
        );

        check_class(CLASS_DNS, 1'b1, 1'b0, "TEST 2");

        if (dns_packet !== 1'b1) begin
            $display("TEST 2 FAILED: dns_packet was not asserted.");
            $finish;
        end

        repeat (2) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 3: HTTPS web traffic
        // TCP destination port 443
        // ------------------------------------------------------------
        classify_packet(
            1'b0,
            16'h0800,
            8'd6,
            32'h0A000005,
            32'h0A000006,
            16'd49152,
            16'd443,
            1'b1
        );

        check_class(CLASS_WEB, 1'b1, 1'b0, "TEST 3");

        if (web_packet !== 1'b1) begin
            $display("TEST 3 FAILED: web_packet was not asserted.");
            $finish;
        end

        repeat (2) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 4: Parser error should become malformed and drop
        // ------------------------------------------------------------
        classify_packet(
            1'b1,
            16'h0800,
            8'd17,
            32'h0A000007,
            32'h0A000008,
            16'd5000,
            16'd6000,
            1'b1
        );

        check_class(CLASS_MALFORMED, 1'b0, 1'b1, "TEST 4");

        if (malformed_packet !== 1'b1) begin
            $display("TEST 4 FAILED: malformed_packet was not asserted.");
            $finish;
        end

        repeat (2) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 5: Non-IPv4 frame should drop
        // EtherType 0x0806 = ARP
        // ------------------------------------------------------------
        classify_packet(
            1'b0,
            16'h0806,
            8'd0,
            32'h00000000,
            32'h00000000,
            16'd0,
            16'd0,
            1'b1
        );

        check_class(CLASS_NON_IPV4, 1'b0, 1'b1, "TEST 5");

        if (non_ipv4_packet !== 1'b1) begin
            $display("TEST 5 FAILED: non_ipv4_packet was not asserted.");
            $finish;
        end

        repeat (2) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 6: Unknown IPv4 packet with drop_unknown enabled
        // ------------------------------------------------------------
        classify_packet(
            1'b0,
            16'h0800,
            8'd17,
            32'h0A000009,
            32'h0A00000A,
            16'd3000,
            16'd3001,
            1'b1
        );

        check_class(CLASS_UNKNOWN, 1'b0, 1'b1, "TEST 6");

        if (unknown_packet !== 1'b1) begin
            $display("TEST 6 FAILED: unknown_packet was not asserted.");
            $finish;
        end

        repeat (2) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 7: Trusted packet should be allowed
        // Trusted source IP = 192.168.1.10
        // ------------------------------------------------------------
        classify_packet(
            1'b0,
            16'h0800,
            8'd17,
            32'hC0A8010A,
            32'h0A00000B,
            16'd3000,
            16'd3001,
            1'b1
        );

        check_class(CLASS_TRUSTED, 1'b1, 1'b0, "TEST 7");

        if (trusted_packet !== 1'b1) begin
            $display("TEST 7 FAILED: trusted_packet was not asserted.");
            $finish;
        end

        repeat (2) @(negedge clk);

        $display("ALL PACKET CLASSIFIER TESTS PASSED.");
        $finish;
    end

endmodule