`timescale 1ns/1ps

module tb_ethernet_parser;

    logic clk;
    logic rst_n;

    logic [7:0] data_in;
    logic       valid_in;
    logic       sop_in;
    logic       eop_in;

    logic [7:0]  data_out;
    logic        valid_out;
    logic        sop_out;
    logic        eop_out;

    logic [47:0] dest_mac;
    logic [47:0] src_mac;
    logic [15:0] ethertype;

    logic        eth_header_valid;
    logic        ipv4_frame;
    logic        unsupported_ethertype;
    logic        parser_error;

    logic [4:0]  header_byte_index;

    ethernet_parser dut (
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

        .dest_mac(dest_mac),
        .src_mac(src_mac),
        .ethertype(ethertype),

        .eth_header_valid(eth_header_valid),
        .ipv4_frame(ipv4_frame),
        .unsupported_ethertype(unsupported_ethertype),
        .parser_error(parser_error),

        .header_byte_index(header_byte_index)
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

    initial begin
        $dumpfile("sim/ethernet_parser.vcd");
        $dumpvars(0, tb_ethernet_parser);

        clk = 1'b0;

        reset_dut();

        $display("Starting ethernet_parser tests...");

        // ------------------------------------------------------------
        // TEST 1: Valid Ethernet II frame carrying IPv4
        // Destination MAC: AA:BB:CC:DD:EE:FF
        // Source MAC:      11:22:33:44:55:66
        // EtherType:       0x0800
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
        send_byte(8'h00, 1'b0, 1'b1);

        if (eth_header_valid !== 1'b1) begin
            $display("TEST 1 FAILED: eth_header_valid was not asserted.");
            $finish;
        end

        if (dest_mac !== 48'hAABBCCDDEEFF) begin
            $display("TEST 1 FAILED: wrong dest_mac. Got %h", dest_mac);
            $finish;
        end

        if (src_mac !== 48'h112233445566) begin
            $display("TEST 1 FAILED: wrong src_mac. Got %h", src_mac);
            $finish;
        end

        if (ethertype !== 16'h0800) begin
            $display("TEST 1 FAILED: wrong ethertype. Got %h", ethertype);
            $finish;
        end

        if (ipv4_frame !== 1'b1) begin
            $display("TEST 1 FAILED: ipv4_frame was not asserted.");
            $finish;
        end

        $display("TEST 1 PASSED: valid IPv4 Ethernet frame parsed correctly.");

        repeat (3) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 2: Valid Ethernet frame with unsupported EtherType
        // EtherType: 0x0806 = ARP
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

        if (eth_header_valid !== 1'b1) begin
            $display("TEST 2 FAILED: eth_header_valid was not asserted.");
            $finish;
        end

        if (ethertype !== 16'h0806) begin
            $display("TEST 2 FAILED: wrong ethertype. Got %h", ethertype);
            $finish;
        end

        if (ipv4_frame !== 1'b0) begin
            $display("TEST 2 FAILED: ipv4_frame should be 0 for ARP.");
            $finish;
        end

        if (unsupported_ethertype !== 1'b1) begin
            $display("TEST 2 FAILED: unsupported_ethertype was not asserted.");
            $finish;
        end

        $display("TEST 2 PASSED: unsupported EtherType detected correctly.");

        repeat (3) @(negedge clk);

        // ------------------------------------------------------------
        // TEST 3: Short Ethernet frame should trigger parser_error
        // ------------------------------------------------------------

        send_byte(8'hAA, 1'b1, 1'b0);
        send_byte(8'hBB, 1'b0, 1'b0);
        send_byte(8'hCC, 1'b0, 1'b1);

        if (parser_error !== 1'b1) begin
            $display("TEST 3 FAILED: parser_error was not asserted for short frame.");
            $finish;
        end

        $display("TEST 3 PASSED: short Ethernet frame detected correctly.");

        repeat (3) @(negedge clk);

        $display("ALL ETHERNET PARSER TESTS PASSED.");
        $finish;
    end

endmodule