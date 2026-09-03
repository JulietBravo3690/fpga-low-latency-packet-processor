`timescale 1ns/1ps
module tb_packet_rom_source;
    logic clk = 0;
    logic rst_n = 0;
    logic start = 0;
    logic [7:0] data_out;
    logic valid_out, sop_out, eop_out, busy, done;
    logic [7:0] expected [0:58];
    integer byte_count, sop_count, eop_count, done_count;

    packet_rom_source dut (.*);
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (sop_out && !valid_out) $fatal(1, "SOP without valid");
        if (eop_out && !valid_out) $fatal(1, "EOP without valid");
        if (valid_out) begin
            if (data_out !== expected[byte_count])
                $fatal(1, "byte %0d mismatch: expected %02h got %02h",
                       byte_count, expected[byte_count], data_out);
            if (sop_out) sop_count = sop_count + 1;
            if (eop_out) eop_count = eop_count + 1;
            byte_count = byte_count + 1;
        end
        if (done) done_count = done_count + 1;
    end

    task pulse_start;
        begin
            @(negedge clk); start = 1'b1;
            @(negedge clk); start = 1'b0;
        end
    endtask

    task wait_for_done;
        integer timeout;
        begin
            timeout = 0;
            while (!done && timeout < 100) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!done) $fatal(1, "timed out waiting for done");
            @(negedge clk);
            if (done) $fatal(1, "done was not a one-cycle pulse");
        end
    endtask

    initial begin
        $readmemh("sim/market_packet.hex", expected);
        byte_count = 0; sop_count = 0; eop_count = 0; done_count = 0;
        repeat (3) @(negedge clk); rst_n = 1;

        pulse_start();
        if (!busy) $fatal(1, "source did not become busy");
        // Illegal start while busy must not restart or add a transaction.
        repeat (5) @(negedge clk);
        pulse_start();
        wait_for_done();
        if (byte_count != 59 || sop_count != 1 || eop_count != 1 || done_count != 1)
            $fatal(1, "first transaction framing/count mismatch");

        // A fresh rising edge after idle starts a reusable second transaction.
        byte_count = 0; sop_count = 0; eop_count = 0;
        pulse_start();
        wait_for_done();
        if (byte_count != 59 || sop_count != 1 || eop_count != 1 || done_count != 2)
            $fatal(1, "second transaction framing/count mismatch");

        // Reset during idle returns every externally visible control low.
        @(negedge clk); rst_n = 0;
        @(posedge clk); #1;
        if (busy || done || valid_out || sop_out || eop_out)
            $fatal(1, "idle reset outputs were not deterministic");
        $display("packet_rom_source tests PASSED");
        $finish;
    end
endmodule
