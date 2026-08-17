`timescale 1ns/1ps
module tb_market_data_decoder;
    logic clk = 0;
    logic rst_n = 0;
    logic [7:0] data_in = 0;
    logic valid_in = 0;
    logic eop_in = 0;
    logic market_header_valid = 0;
    logic market_packet = 0;
    logic [15:0] udp_length = 0;
    logic message_valid, decoder_error;
    logic [7:0] message_type;
    logic [31:0] symbol, price, quantity, sequence_number;
    logic [7:0] payload [0:16];
    integer message_valid_count;

    market_data_decoder dut (.*);
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (message_valid)
            message_valid_count <= message_valid_count + 1;
    end

    task idle_cycle;
        begin
            @(negedge clk);
            valid_in = 0;
            eop_in = 0;
            market_header_valid = 0;
        end
    endtask

    task start_message(input logic [15:0] declared_length);
        begin
            @(negedge clk);
            udp_length = declared_length;
            market_header_valid = 1;
            market_packet = 1;
            data_in = payload[0];
            valid_in = 1;
            eop_in = 0;
        end
    endtask

    task drive_payload(input integer last_index, input logic insert_gaps);
        integer index;
        begin
            for (index = 1; index <= last_index; index = index + 1) begin
                if (insert_gaps)
                    idle_cycle();
                @(negedge clk);
                market_header_valid = 0;
                data_in = payload[index];
                valid_in = 1;
                eop_in = (index == last_index);
            end
            @(posedge clk);
            #1;
        end
    endtask

    task check_valid_message(input string test_name);
        begin
            if (!message_valid || decoder_error || message_type != 1 ||
                symbol != "AAPL" || price != 18525 || quantity != 100 ||
                sequence_number != 42)
                $fatal(1, "%s: decoded fields or status mismatch", test_name);
            idle_cycle();
            @(posedge clk); #1;
            if (message_valid)
                $fatal(1, "%s: message_valid was not a one-cycle pulse", test_name);
        end
    endtask

    initial begin
        payload[0] = 8'h01;
        payload[1] = "A"; payload[2] = "A"; payload[3] = "P"; payload[4] = "L";
        payload[5] = 8'h00; payload[6] = 8'h00; payload[7] = 8'h48; payload[8] = 8'h5D;
        payload[9] = 8'h00; payload[10] = 8'h00; payload[11] = 8'h00; payload[12] = 8'h64;
        payload[13] = 8'h00; payload[14] = 8'h00; payload[15] = 8'h00; payload[16] = 8'h2A;
        message_valid_count = 0;

        repeat (2) @(negedge clk);
        rst_n = 1;

        // Back-to-back stream bytes.
        start_message(16'd25);
        drive_payload(16, 1'b0);
        check_valid_message("continuous payload");

        // Idle cycles between every payload byte.
        start_message(16'd25);
        drive_payload(16, 1'b1);
        check_valid_message("gapped payload");

        // A declared length shorter than the fixed schema is rejected.
        idle_cycle();
        @(negedge clk);
        udp_length = 16'd24; market_header_valid = 1; market_packet = 1;
        valid_in = 0; eop_in = 0;
        @(posedge clk); #1;
        if (!decoder_error || message_valid)
            $fatal(1, "short declared UDP length was accepted");
        if (message_type != 0 || symbol != 0 || price != 0 ||
            quantity != 0 || sequence_number != 0)
            $fatal(1, "short length left stale decoded fields");

        // A longer declaration is also rejected: only the exact schema exists.
        idle_cycle();
        @(negedge clk);
        udp_length = 16'd26; market_header_valid = 1; market_packet = 1;
        valid_in = 0; eop_in = 0;
        @(posedge clk); #1;
        if (!decoder_error || message_valid)
            $fatal(1, "overlong declared UDP length was accepted");
        if (message_type != 0 || symbol != 0 || price != 0 ||
            quantity != 0 || sequence_number != 0)
            $fatal(1, "overlong length left stale decoded fields");

        // Early EOP clears partially decoded state and never emits valid.
        idle_cycle();
        start_message(16'd25);
        drive_payload(7, 1'b1);
        if (!decoder_error || message_valid)
            $fatal(1, "early EOP did not report a decoder error");
        if (message_type != 0 || symbol != 0 || price != 0 ||
            quantity != 0 || sequence_number != 0)
            $fatal(1, "early EOP left stale decoded fields");

        if (message_valid_count != 2)
            $fatal(1, "expected exactly two valid-message pulses, got %0d", message_valid_count);

        $display("market_data_decoder tests PASSED");
        $finish;
    end
endmodule
