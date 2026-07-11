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
    logic       clear_counters;
    logic       stats_rd_en;
    logic [3:0] stats_addr;

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

    logic        stats_rd_valid;
    logic [31:0] stats_rd_data;

    logic [31:0] total_packets;
    logic [31:0] allowed_packets;
    logic [31:0] dropped_packets;
    logic [31:0] malformed_packets;
    logic [31:0] non_ipv4_packets;
    logic [31:0] market_data_packets_count;
    logic [31:0] dns_packets_count;
    logic [31:0] web_packets_count;
    logic [31:0] control_packets_count;
    logic [31:0] trusted_packets_count;
    logic [31:0] unknown_packets_count;
    logic [31:0] total_ipv4_bytes;
    logic [15:0] last_packet_length;

    top_packet_processor dut (
        .clk(clk),
        .rst_n(rst_n),

        .data_in(data_in),
        .valid_in(valid_in),
        .sop_in(sop_in),
        .eop_in(eop_in),

        .drop_unknown(drop_unknown),
        .clear_counters(clear_counters),
        .stats_rd_en(stats_rd_en),
        .stats_addr(stats_addr),

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
        .unknown_packet(unknown_packet),

        .stats_rd_valid(stats_rd_valid),
        .stats_rd_data(stats_rd_data),

        .total_packets(total_packets),
        .allowed_packets(allowed_packets),
        .dropped_packets(dropped_packets),
        .malformed_packets(malformed_packets),
        .non_ipv4_packets(non_ipv4_packets),
        .market_data_packets_count(market_data_packets_count),
        .dns_packets_count(dns_packets_count),
        .web_packets_count(web_packets_count),
        .control_packets_count(control_packets_count),
        .trusted_packets_count(trusted_packets_count),
        .unknown_packets_count(unknown_packets_count),
        .total_ipv4_bytes(total_ipv4_bytes),
        .last_packet_length(last_packet_length)
    );

    always #5 clk = ~clk;

    task reset_dut;
        begin
            rst_n          = 1'b0;
            data_in        = 8'h00;
            valid_in       = 1'b0;
            sop_in         = 1'b0;
            eop_in         = 1'b0;
            drop_unknown   = 1'b1;
            clear_counters = 1'b0;
            stats_rd_en    = 1'b0;
            stats_addr     = 4'd0;

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
            send_byte(8'h45, 1'b0, 1'b0);
            send_byte(8'h00, 1'b0, 1'b0);

            send_byte(8'h00, 1'b0, 1'b0);
            send_byte(8'h1C, 1'b0, 1'b0);

            send_byte(8'h00, 1'b0, 1'b0);
            send_byte(8'h01, 1'b0, 1'b0);

            send_byte(8'h40, 1'b0, 1'b0);
            send_byte(8'h00, 1'b0, 1'b0);

            send_byte(8'h40, 1'b0, 1'b0);
            send_byte(protocol_value, 1'b0, 1'b0);

            send_byte(8'h00, 1'b0, 1'b0);
            send_byte(8'h00, 1'b0, 1'b0);

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
            send_byte(8'h08, 1'b0, 1'b0);

            send_byte(8'h00, 1'b0, 1'b0);
            send_byte(8'h00, 1'b0, 1'b1);
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

            while ((class_valid !== 1'b1) && (timeout < 100)) begin
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

            $display("%s classification PASSED.", test_name);
        end
    endtask

    task wait_for_stats_update;
        begin
            repeat (3) @(negedge clk);
        end
    endtask

    task check_counter(
        input logic [31:0] actual_value,
        input logic [31:0] expected_value,
        input string       counter_name
    );
        begin
            if (actual_value !== expected_value) begin
                $display("FAILED: %s expected %0d, got %0d.", counter_name, expected_value, actual_value);
                $finish;
            end

            $display("PASSED: %s = %0d.", counter_name, actual_value);
        end
    endtask

    task read_stat_register(
        input logic [3:0]  addr_value,
        input logic [31:0] expected_value,
        input string       register_name
    );
        begin
            @(negedge clk);
            stats_addr  = addr_value;
            stats_rd_en = 1'b1;

            @(negedge clk);
            stats_rd_en = 1'b0;

            if (stats_rd_valid !== 1'b1) begin
                $display("FAILED: %s did not assert stats_rd_valid.", register_name);
                $finish;
            end

            if (stats_rd_data !== expected_value) begin
                $display("FAILED: %s expected %0d, got %0d.", register_name, expected_value, stats_rd_data);
                $finish;
            end

            $display("PASSED: %s read value %0d.", register_name, stats_rd_data);
        end
    endtask

    initial begin
        $dumpfile("sim/top_packet_processor.vcd");
        $dumpvars(0, tb_top_packet_processor);

        clk = 1'b0;

        reset_dut();

        $display("Starting top_packet_processor integration tests...");

        // TEST 1: Market-data packet
        drop_unknown = 1'b1;
        send_udp_packet(16'd5000, 16'd6000, 32'h0A000001, 32'h0A000002);
        check_class(CLASS_MARKET_DATA, 1'b1, 1'b0, "TEST 1");
        wait_for_stats_update();

        // TEST 2: DNS packet
        send_udp_packet(16'd40000, 16'd53, 32'h0A000003, 32'h0A000004);
        check_class(CLASS_DNS, 1'b1, 1'b0, "TEST 2");
        wait_for_stats_update();

        // TEST 3: Trusted packet
        send_udp_packet(16'd3000, 16'd3001, 32'hC0A8010A, 32'h0A000005);
        check_class(CLASS_TRUSTED, 1'b1, 1'b0, "TEST 3");
        wait_for_stats_update();

        // TEST 4: Unknown packet, drop_unknown enabled
        drop_unknown = 1'b1;
        send_udp_packet(16'd3000, 16'd3001, 32'h0A000006, 32'h0A000007);
        check_class(CLASS_UNKNOWN, 1'b0, 1'b1, "TEST 4");
        wait_for_stats_update();

        // TEST 5: Unknown packet, drop_unknown disabled
        drop_unknown = 1'b0;
        send_udp_packet(16'd3000, 16'd3001, 32'h0A000008, 32'h0A000009);
        check_class(CLASS_UNKNOWN, 1'b1, 1'b0, "TEST 5");
        wait_for_stats_update();

        // TEST 6: Non-IPv4 frame
        drop_unknown = 1'b1;
        send_non_ipv4_frame();
        check_class(CLASS_NON_IPV4, 1'b0, 1'b1, "TEST 6");
        wait_for_stats_update();

        // TEST 7: Malformed packet
        send_short_malformed_packet();
        check_class(CLASS_MALFORMED, 1'b0, 1'b1, "TEST 7");
        wait_for_stats_update();

        $display("Checking integrated traffic counters...");

        check_counter(total_packets,              32'd7,  "total_packets");
        check_counter(allowed_packets,            32'd4,  "allowed_packets");
        check_counter(dropped_packets,            32'd3,  "dropped_packets");
        check_counter(market_data_packets_count,  32'd1,  "market_data_packets_count");
        check_counter(dns_packets_count,          32'd1,  "dns_packets_count");
        check_counter(trusted_packets_count,      32'd1,  "trusted_packets_count");
        check_counter(unknown_packets_count,      32'd2,  "unknown_packets_count");
        check_counter(non_ipv4_packets,           32'd1,  "non_ipv4_packets");
        check_counter(malformed_packets,          32'd1,  "malformed_packets");

        // Five valid IPv4 UDP packets, each with IPv4 total length 28 bytes.
        check_counter(total_ipv4_bytes,           32'd140, "total_ipv4_bytes");

        read_stat_register(4'd0, 32'd7,   "STAT_TOTAL_PACKETS");
        read_stat_register(4'd1, 32'd4,   "STAT_ALLOWED_PACKETS");
        read_stat_register(4'd2, 32'd3,   "STAT_DROPPED_PACKETS");
        read_stat_register(4'd5, 32'd1,   "STAT_MARKET_PACKETS");
        read_stat_register(4'd6, 32'd1,   "STAT_DNS_PACKETS");
        read_stat_register(4'd10, 32'd2,  "STAT_UNKNOWN_PACKETS");
        read_stat_register(4'd11, 32'd140, "STAT_TOTAL_IPV4_BYTES");

        $display("Testing clear_counters...");

        @(negedge clk);
        clear_counters = 1'b1;

        @(negedge clk);
        clear_counters = 1'b0;

        repeat (2) @(negedge clk);

        check_counter(total_packets,    32'd0, "total_packets after clear");
        check_counter(allowed_packets,  32'd0, "allowed_packets after clear");
        check_counter(dropped_packets,  32'd0, "dropped_packets after clear");
        check_counter(total_ipv4_bytes, 32'd0, "total_ipv4_bytes after clear");

        $display("ALL TOP PACKET PROCESSOR TESTS PASSED.");
        $finish;
    end

endmodule