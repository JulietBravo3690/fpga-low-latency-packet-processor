`timescale 1ns/1ps
module tb_latency_tracker;
    logic clk = 0, rst_n = 0;
    logic sop_event = 0, ethernet_event = 0, ipv4_event = 0, udp_event = 0;
    logic classification_event = 0, statistics_event = 0;
    logic active, eth_v, ip_v, udp_v, class_v, stats_v, overflow;
    logic [7:0] eth_l, ip_l, udp_l, class_l, stats_l;
    latency_tracker #(.COUNTER_WIDTH(8)) dut (
        .clk, .rst_n, .sop_event, .ethernet_event, .ipv4_event, .udp_event,
        .classification_event, .statistics_event, .measurement_active(active),
        .ethernet_latency(eth_l), .ipv4_latency(ip_l), .udp_latency(udp_l),
        .classification_latency(class_l), .statistics_latency(stats_l),
        .ethernet_latency_valid(eth_v), .ipv4_latency_valid(ip_v),
        .udp_latency_valid(udp_v), .classification_latency_valid(class_v),
        .statistics_latency_valid(stats_v), .counter_overflow(overflow));
    always #5 clk = ~clk;
    task pulse_after(input integer cycles, input integer event_id);
        repeat (cycles) @(negedge clk);
        case(event_id) 0: ethernet_event=1; 1: ipv4_event=1; 2: udp_event=1;
          3: classification_event=1; 4: statistics_event=1; endcase
        @(negedge clk); ethernet_event=0; ipv4_event=0; udp_event=0;
        classification_event=0; statistics_event=0;
    endtask
    initial begin
        repeat(2) @(negedge clk); rst_n=1;
        @(negedge clk); sop_event=1; @(negedge clk); sop_event=0;
        pulse_after(2, 0); if (!eth_v || eth_l != 2) $fatal(1, "Ethernet latency mismatch");
        pulse_after(3, 1); if (!ip_v || ip_l != 6) $fatal(1, "IPv4 latency mismatch");
        pulse_after(2, 2); if (!udp_v || udp_l != 9) $fatal(1, "UDP latency mismatch");
        pulse_after(1, 3); if (!class_v || class_l != 11) $fatal(1, "class latency mismatch");
        pulse_after(1, 4); if (!stats_v || stats_l != 13 || active) $fatal(1, "stats latency mismatch");
        if (overflow) $fatal(1, "unexpected overflow");
        $display("latency_tracker tests PASSED"); $finish;
    end
endmodule
