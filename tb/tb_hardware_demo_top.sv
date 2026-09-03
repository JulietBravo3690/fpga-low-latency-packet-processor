`timescale 1ns/1ps
module tb_hardware_demo_top;
    logic clk = 0;
    logic rst_n = 0;
    logic start = 0;
    logic clear_status = 0;
    logic clear_counters = 0;

    logic source_busy, source_done, start_ready;
    logic [7:0] stream_data;
    logic stream_valid, stream_sop, stream_eop;
    logic class_valid, packet_allowed, packet_dropped;
    logic market_packet_detected, market_message_valid, market_decoder_error;
    logic [7:0] market_message_type;
    logic [31:0] market_symbol, market_price, market_quantity;
    logic [31:0] market_sequence_number;
    logic [15:0] ethernet_latency, ipv4_latency, udp_latency;
    logic [15:0] classification_latency, statistics_latency;
    logic ethernet_latency_valid, ipv4_latency_valid, udp_latency_valid;
    logic classification_latency_valid, statistics_latency_valid;
    logic latency_counter_overflow;
    logic packet_buffer_overflow;
    logic [31:0] total_packets, market_data_packets_count, total_ipv4_bytes;
    logic packet_seen, allowed_seen, dropped_seen, market_seen, message_seen;
    logic decoder_error_seen, latency_overflow_seen;
    logic [7:0] last_message_type;
    logic [31:0] last_symbol, last_price, last_quantity, last_sequence_number;
    logic [15:0] last_ethernet_latency, last_ipv4_latency, last_udp_latency;
    logic [15:0] last_classification_latency, last_statistics_latency;

    integer valid_count, sop_count, eop_count, done_count;
    integer class_count, message_count;
    integer eth_latency_count, ip_latency_count, udp_latency_count;
    integer class_latency_count, stats_latency_count;

    hardware_demo_top dut (.*);
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (stream_sop && !stream_valid) $fatal(1, "SOP without valid");
        if (stream_eop && !stream_valid) $fatal(1, "EOP without valid");
        if (packet_allowed && packet_dropped)
            $fatal(1, "allow and drop asserted together");
        if (market_message_valid && market_decoder_error)
            $fatal(1, "message valid and decoder error asserted together");

        if (stream_valid) valid_count = valid_count + 1;
        if (stream_sop) sop_count = sop_count + 1;
        if (stream_eop) eop_count = eop_count + 1;
        if (source_done) done_count = done_count + 1;
        if (class_valid) begin
            class_count = class_count + 1;
            if (!market_packet_detected || !packet_allowed || packet_dropped)
                $fatal(1, "market classification decision mismatch");
        end
        if (market_message_valid) message_count = message_count + 1;
        if (ethernet_latency_valid) eth_latency_count = eth_latency_count + 1;
        if (ipv4_latency_valid) ip_latency_count = ip_latency_count + 1;
        if (udp_latency_valid) udp_latency_count = udp_latency_count + 1;
        if (classification_latency_valid) class_latency_count = class_latency_count + 1;
        if (statistics_latency_valid) stats_latency_count = stats_latency_count + 1;
    end

    task pulse_start;
        begin
            @(negedge clk); start = 1'b1;
            @(negedge clk); start = 1'b0;
        end
    endtask

    task wait_until_idle;
        integer timeout;
        begin
            timeout = 0;
            while ((!source_done) && timeout < 100) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!source_done) $fatal(1, "source completion timeout");
            while (!start_ready && timeout < 200) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!start_ready) $fatal(1, "processor did not return ingress ready");
            repeat (4) @(negedge clk);
        end
    endtask

    task check_results(input integer expected_packets);
        begin
            if (valid_count != expected_packets * 59 ||
                sop_count != expected_packets || eop_count != expected_packets ||
                done_count != expected_packets)
                $fatal(1, "source framing/count mismatch after %0d packet(s)", expected_packets);
            if (class_count != expected_packets || message_count != expected_packets)
                $fatal(1, "classification/decoder pulse count mismatch");
            if (eth_latency_count != expected_packets || ip_latency_count != expected_packets ||
                udp_latency_count != expected_packets || class_latency_count != expected_packets ||
                stats_latency_count != expected_packets)
                $fatal(1, "latency pulse count mismatch");
            if (market_message_type != 1 || market_symbol != "AAPL" ||
                market_price != 18525 || market_quantity != 100 ||
                market_sequence_number != 42)
                $fatal(1, "decoded market fields mismatch");
            if (market_decoder_error || latency_counter_overflow ||
                packet_buffer_overflow)
                $fatal(1, "unexpected decoder or latency error");
            if (total_packets != expected_packets ||
                market_data_packets_count != expected_packets ||
                total_ipv4_bytes != expected_packets * 45)
                $fatal(1, "traffic statistics mismatch");
            if (!packet_seen || !allowed_seen || dropped_seen || !market_seen ||
                !message_seen || decoder_error_seen || latency_overflow_seen)
                $fatal(1, "sticky status mismatch");
            if (last_message_type != 1 || last_symbol != "AAPL" ||
                last_price != 18525 || last_quantity != 100 ||
                last_sequence_number != 42)
                $fatal(1, "latched message snapshot mismatch");
            if (!(last_ethernet_latency < last_ipv4_latency &&
                  last_ipv4_latency < last_udp_latency &&
                  last_udp_latency <= last_classification_latency &&
                  last_classification_latency <= last_statistics_latency))
                $fatal(1, "latched latency ordering mismatch");
        end
    endtask

    initial begin
        valid_count = 0; sop_count = 0; eop_count = 0; done_count = 0;
        class_count = 0; message_count = 0;
        eth_latency_count = 0; ip_latency_count = 0; udp_latency_count = 0;
        class_latency_count = 0; stats_latency_count = 0;

        repeat (3) @(negedge clk); rst_n = 1;
        pulse_start();
        if (!source_busy) $fatal(1, "source did not become busy");
        repeat (8) @(negedge clk);
        pulse_start(); // ignored while busy
        wait_until_idle();
        check_results(1);

        // Sticky state can be cleared without clearing traffic counters.
        @(negedge clk); clear_status = 1;
        @(negedge clk); clear_status = 0;
        @(posedge clk); #1;
        if (packet_seen || allowed_seen || market_seen || message_seen ||
            last_symbol != 0 || last_statistics_latency != 0)
            $fatal(1, "status clear failed");

        pulse_start();
        wait_until_idle();
        check_results(2);

        // Reset during a third transmission aborts it and clears all state.
        pulse_start();
        repeat (10) @(negedge clk);
        rst_n = 0;
        @(posedge clk); #1;
        if (source_busy || source_done || stream_valid || total_packets != 0 ||
            packet_seen || message_seen)
            $fatal(1, "mid-packet reset did not return to deterministic state");

        $display("hardware_demo_top tests PASSED");
        $finish;
    end
endmodule
