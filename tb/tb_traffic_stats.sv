`timescale 1ns/1ps

module tb_traffic_stats;

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

    logic        clear_counters;

    logic        event_valid;
    logic [2:0]  packet_class;
    logic        allow_packet;
    logic        drop_packet;

    logic [15:0] packet_length;
    logic        packet_length_valid;

    logic        stats_rd_en;
    logic [3:0]  stats_addr;
    logic        stats_rd_valid;
    logic [31:0] stats_rd_data;

    logic [31:0] total_packets;
    logic [31:0] allowed_packets;
    logic [31:0] dropped_packets;

    logic [31:0] malformed_packets;
    logic [31:0] non_ipv4_packets;
    logic [31:0] market_data_packets;
    logic [31:0] dns_packets;
    logic [31:0] web_packets;
    logic [31:0] control_packets;
    logic [31:0] trusted_packets;
    logic [31:0] unknown_packets;

    logic [31:0] total_ipv4_bytes;
    logic [15:0] last_packet_length;

    traffic_stats dut (
        .clk(clk),
        .rst_n(rst_n),

        .clear_counters(clear_counters),

        .event_valid(event_valid),
        .packet_class(packet_class),
        .allow_packet(allow_packet),
        .drop_packet(drop_packet),

        .packet_length(packet_length),
        .packet_length_valid(packet_length_valid),

        .stats_rd_en(stats_rd_en),
        .stats_addr(stats_addr),
        .stats_rd_valid(stats_rd_valid),
        .stats_rd_data(stats_rd_data),

        .total_packets(total_packets),
        .allowed_packets(allowed_packets),
        .dropped_packets(dropped_packets),

        .malformed_packets(malformed_packets),
        .non_ipv4_packets(non_ipv4_packets),
        .market_data_packets(market_data_packets),
        .dns_packets(dns_packets),
        .web_packets(web_packets),
        .control_packets(control_packets),
        .trusted_packets(trusted_packets),
        .unknown_packets(unknown_packets),

        .total_ipv4_bytes(total_ipv4_bytes),
        .last_packet_length(last_packet_length)
    );

    always #5 clk = ~clk;

    task reset_dut;
        begin
            rst_n               = 1'b0;
            clear_counters      = 1'b0;

            event_valid         = 1'b0;
            packet_class        = CLASS_UNKNOWN;
            allow_packet        = 1'b0;
            drop_packet         = 1'b0;

            packet_length       = 16'd0;
            packet_length_valid = 1'b0;

            stats_rd_en         = 1'b0;
            stats_addr          = 4'd0;

            repeat (3) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    task send_event(
        input logic [2:0]  class_value,
        input logic        allow_value,
        input logic        drop_value,
        input logic [15:0] length_value,
        input logic        length_valid_value
    );
        begin
            @(negedge clk);

            packet_class        = class_value;
            allow_packet        = allow_value;
            drop_packet         = drop_value;
            packet_length       = length_value;
            packet_length_valid = length_valid_value;
            event_valid         = 1'b1;

            @(negedge clk);

            event_valid         = 1'b0;
            packet_class        = CLASS_UNKNOWN;
            allow_packet        = 1'b0;
            drop_packet         = 1'b0;
            packet_length       = 16'd0;
            packet_length_valid = 1'b0;
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
            end else begin
                $display("PASSED: %s = %0d.", counter_name, actual_value);
            end
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

    task clear_all_counters;
        begin
            @(negedge clk);
            clear_counters = 1'b1;

            @(negedge clk);
            clear_counters = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("sim/traffic_stats.vcd");
        $dumpvars(0, tb_traffic_stats);

        clk = 1'b0;

        reset_dut();

        $display("Starting traffic_stats tests...");

        // ------------------------------------------------------------
        // TEST 1: Confirm reset state
        // ------------------------------------------------------------

        check_counter(total_packets,       32'd0, "total_packets after reset");
        check_counter(allowed_packets,     32'd0, "allowed_packets after reset");
        check_counter(dropped_packets,     32'd0, "dropped_packets after reset");
        check_counter(total_ipv4_bytes,    32'd0, "total_ipv4_bytes after reset");

        $display("TEST 1 PASSED: reset state verified.");

        // ------------------------------------------------------------
        // TEST 2: Send one event for each major class
        // ------------------------------------------------------------

        send_event(CLASS_MARKET_DATA, 1'b1, 1'b0, 16'd28, 1'b1);
        send_event(CLASS_DNS,         1'b1, 1'b0, 16'd60, 1'b1);
        send_event(CLASS_WEB,         1'b1, 1'b0, 16'd52, 1'b1);
        send_event(CLASS_CONTROL,     1'b1, 1'b0, 16'd48, 1'b1);
        send_event(CLASS_TRUSTED,     1'b1, 1'b0, 16'd40, 1'b1);
        send_event(CLASS_UNKNOWN,     1'b0, 1'b1, 16'd28, 1'b1);
        send_event(CLASS_MALFORMED,   1'b0, 1'b1, 16'd0,  1'b0);
        send_event(CLASS_NON_IPV4,    1'b0, 1'b1, 16'd0,  1'b0);

        check_counter(total_packets,       32'd8,   "total_packets");
        check_counter(allowed_packets,     32'd5,   "allowed_packets");
        check_counter(dropped_packets,     32'd3,   "dropped_packets");

        check_counter(malformed_packets,   32'd1,   "malformed_packets");
        check_counter(non_ipv4_packets,    32'd1,   "non_ipv4_packets");
        check_counter(market_data_packets, 32'd1,   "market_data_packets");
        check_counter(dns_packets,         32'd1,   "dns_packets");
        check_counter(web_packets,         32'd1,   "web_packets");
        check_counter(control_packets,     32'd1,   "control_packets");
        check_counter(trusted_packets,     32'd1,   "trusted_packets");
        check_counter(unknown_packets,     32'd1,   "unknown_packets");

        check_counter(total_ipv4_bytes,    32'd256, "total_ipv4_bytes");

        if (last_packet_length !== 16'd0) begin
            $display("FAILED: expected last_packet_length 0 after non-length-valid event, got %0d.", last_packet_length);
            $finish;
        end

        $display("TEST 2 PASSED: class counters and byte counter verified.");

        // ------------------------------------------------------------
        // TEST 3: Read counters through register interface
        // ------------------------------------------------------------

        read_stat_register(4'd0,  32'd8,   "STAT_TOTAL_PACKETS");
        read_stat_register(4'd1,  32'd5,   "STAT_ALLOWED_PACKETS");
        read_stat_register(4'd2,  32'd3,   "STAT_DROPPED_PACKETS");
        read_stat_register(4'd5,  32'd1,   "STAT_MARKET_PACKETS");
        read_stat_register(4'd6,  32'd1,   "STAT_DNS_PACKETS");
        read_stat_register(4'd10, 32'd1,   "STAT_UNKNOWN_PACKETS");
        read_stat_register(4'd11, 32'd256, "STAT_TOTAL_IPV4_BYTES");

        $display("TEST 3 PASSED: register read interface verified.");

        // ------------------------------------------------------------
        // TEST 4: Clear counters
        // ------------------------------------------------------------

        clear_all_counters();

        check_counter(total_packets,       32'd0, "total_packets after clear");
        check_counter(allowed_packets,     32'd0, "allowed_packets after clear");
        check_counter(dropped_packets,     32'd0, "dropped_packets after clear");
        check_counter(market_data_packets, 32'd0, "market_data_packets after clear");
        check_counter(total_ipv4_bytes,    32'd0, "total_ipv4_bytes after clear");

        $display("TEST 4 PASSED: clear_counters verified.");

        $display("ALL TRAFFIC STATS TESTS PASSED.");
        $finish;
    end

endmodule