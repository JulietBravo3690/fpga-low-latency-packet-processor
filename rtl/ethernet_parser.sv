module ethernet_parser (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        sop_in,
    input  logic        eop_in,

    output logic [7:0]  data_out,
    output logic        valid_out,
    output logic        sop_out,
    output logic        eop_out,

    output logic [47:0] dest_mac,
    output logic [47:0] src_mac,
    output logic [15:0] ethertype,

    output logic        eth_header_valid,
    output logic        ipv4_frame,
    output logic        unsupported_ethertype,
    output logic        parser_error,

    output logic [4:0]  header_byte_index
);

    typedef enum logic [1:0] {
        IDLE,
        PARSE_HEADER,
        SKIP_PACKET
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state                 <= IDLE;

            data_out              <= 8'h00;
            valid_out             <= 1'b0;
            sop_out               <= 1'b0;
            eop_out               <= 1'b0;

            dest_mac              <= 48'h000000000000;
            src_mac               <= 48'h000000000000;
            ethertype             <= 16'h0000;

            eth_header_valid      <= 1'b0;
            ipv4_frame            <= 1'b0;
            unsupported_ethertype <= 1'b0;
            parser_error          <= 1'b0;

            header_byte_index     <= 5'd0;
        end else begin
            // Default one-cycle pulse outputs
            eth_header_valid      <= 1'b0;
            parser_error          <= 1'b0;
            unsupported_ethertype <= 1'b0;

            // Pass-through stream signals for later pipeline stages
            data_out  <= data_in;
            valid_out <= valid_in;
            sop_out   <= sop_in;
            eop_out   <= eop_in;

            case (state)

                IDLE: begin
                    header_byte_index <= 5'd0;

                    if (valid_in) begin
                        if (sop_in) begin
                            // Byte 0: first byte of destination MAC
                            dest_mac[47:40]  <= data_in;
                            src_mac          <= 48'h000000000000;
                            ethertype        <= 16'h0000;
                            ipv4_frame       <= 1'b0;

                            if (eop_in) begin
                                // Packet ended before Ethernet header completed
                                parser_error      <= 1'b1;
                                state             <= IDLE;
                                header_byte_index <= 5'd0;
                            end else begin
                                state             <= PARSE_HEADER;
                                header_byte_index <= 5'd1;
                            end
                        end else begin
                            // Valid data arrived without start-of-packet
                            parser_error <= 1'b1;
                            state        <= IDLE;
                        end
                    end
                end

                PARSE_HEADER: begin
                    if (valid_in) begin
                        if (sop_in) begin
                            // A new packet started before the current Ethernet header ended
                            parser_error      <= 1'b1;
                            dest_mac[47:40]   <= data_in;
                            header_byte_index <= 5'd1;
                            state             <= PARSE_HEADER;
                        end else begin
                            case (header_byte_index)
                                5'd1:  dest_mac[39:32] <= data_in;
                                5'd2:  dest_mac[31:24] <= data_in;
                                5'd3:  dest_mac[23:16] <= data_in;
                                5'd4:  dest_mac[15:8]  <= data_in;
                                5'd5:  dest_mac[7:0]   <= data_in;

                                5'd6:  src_mac[47:40]  <= data_in;
                                5'd7:  src_mac[39:32]  <= data_in;
                                5'd8:  src_mac[31:24]  <= data_in;
                                5'd9:  src_mac[23:16]  <= data_in;
                                5'd10: src_mac[15:8]   <= data_in;
                                5'd11: src_mac[7:0]    <= data_in;

                                5'd12: ethertype[15:8] <= data_in;

                                5'd13: begin
                                    ethertype[7:0]    <= data_in;
                                    eth_header_valid  <= 1'b1;

                                    if ({ethertype[15:8], data_in} == 16'h0800) begin
                                        ipv4_frame <= 1'b1;
                                    end else begin
                                        ipv4_frame            <= 1'b0;
                                        unsupported_ethertype <= 1'b1;
                                    end
                                end

                                default: begin
                                    parser_error <= 1'b1;
                                end
                            endcase

                            if (header_byte_index == 5'd13) begin
                                // Ethernet header is complete
                                header_byte_index <= 5'd0;

                                if (eop_in) begin
                                    state <= IDLE;
                                end else begin
                                    state <= SKIP_PACKET;
                                end
                            end else begin
                                if (eop_in) begin
                                    // Packet ended before 14-byte Ethernet header completed
                                    parser_error      <= 1'b1;
                                    header_byte_index <= 5'd0;
                                    state             <= IDLE;
                                end else begin
                                    header_byte_index <= header_byte_index + 5'd1;
                                    state             <= PARSE_HEADER;
                                end
                            end
                        end
                    end
                end

                SKIP_PACKET: begin
                    // Header has already been parsed.
                    // Ignore remaining payload until end-of-packet.
                    if (valid_in) begin
                        if (sop_in) begin
                            parser_error      <= 1'b1;
                            dest_mac[47:40]   <= data_in;
                            header_byte_index <= 5'd1;
                            state             <= PARSE_HEADER;
                        end else if (eop_in) begin
                            state             <= IDLE;
                            header_byte_index <= 5'd0;
                        end
                    end
                end

                default: begin
                    state             <= IDLE;
                    header_byte_index <= 5'd0;
                end

            endcase
        end
    end

endmodule