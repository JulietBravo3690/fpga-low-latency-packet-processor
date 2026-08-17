module market_data_decoder (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        eop_in,
    input  logic        market_header_valid,
    input  logic        market_packet,
    input  logic [15:0] udp_length,

    output logic        message_valid,
    output logic        decoder_error,
    output logic [7:0]  message_type,
    output logic [31:0] symbol,
    output logic [31:0] price,
    output logic [31:0] quantity,
    output logic [31:0] sequence_number
);

    localparam logic [15:0] REQUIRED_UDP_LENGTH = 16'd25;

    logic       decoding;
    logic [4:0] payload_byte_index;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoding           <= 1'b0;
            payload_byte_index <= 5'd0;
            message_valid      <= 1'b0;
            decoder_error      <= 1'b0;
            message_type       <= 8'd0;
            symbol             <= 32'd0;
            price              <= 32'd0;
            quantity           <= 32'd0;
            sequence_number    <= 32'd0;
        end else begin
            message_valid <= 1'b0;
            decoder_error <= 1'b0;

            if (market_header_valid && market_packet) begin
                message_type       <= 8'd0;
                symbol             <= 32'd0;
                price              <= 32'd0;
                quantity           <= 32'd0;
                sequence_number    <= 32'd0;
                payload_byte_index <= 5'd0;

                if (udp_length != REQUIRED_UDP_LENGTH) begin
                    decoding      <= 1'b0;
                    decoder_error <= 1'b1;
                end else if (valid_in) begin
                    if (eop_in) begin
                        decoding      <= 1'b0;
                        decoder_error <= 1'b1;
                    end else begin
                        decoding           <= 1'b1;
                        payload_byte_index <= 5'd1;
                        message_type       <= data_in;
                    end
                end else begin
                    decoding           <= 1'b1;
                    payload_byte_index <= 5'd0;
                end
            end else if (decoding && valid_in) begin
                case (payload_byte_index)
                    5'd0:  message_type            <= data_in;
                    5'd1:  symbol[31:24]           <= data_in;
                    5'd2:  symbol[23:16]           <= data_in;
                    5'd3:  symbol[15:8]            <= data_in;
                    5'd4:  symbol[7:0]             <= data_in;
                    5'd5:  price[31:24]            <= data_in;
                    5'd6:  price[23:16]            <= data_in;
                    5'd7:  price[15:8]             <= data_in;
                    5'd8:  price[7:0]              <= data_in;
                    5'd9:  quantity[31:24]         <= data_in;
                    5'd10: quantity[23:16]         <= data_in;
                    5'd11: quantity[15:8]          <= data_in;
                    5'd12: quantity[7:0]           <= data_in;
                    5'd13: sequence_number[31:24]  <= data_in;
                    5'd14: sequence_number[23:16]  <= data_in;
                    5'd15: sequence_number[15:8]   <= data_in;
                    5'd16: begin
                        sequence_number[7:0] <= data_in;
                        message_valid         <= 1'b1;
                        decoding             <= 1'b0;
                    end
                    default: begin
                        decoding      <= 1'b0;
                        decoder_error <= 1'b1;
                    end
                endcase

                if (eop_in && (payload_byte_index != 5'd16)) begin
                    decoder_error      <= 1'b1;
                    decoding           <= 1'b0;
                    payload_byte_index <= 5'd0;
                    message_type       <= 8'd0;
                    symbol             <= 32'd0;
                    price              <= 32'd0;
                    quantity           <= 32'd0;
                    sequence_number    <= 32'd0;
                end else if (payload_byte_index != 5'd16) begin
                    payload_byte_index <= payload_byte_index + 5'd1;
                end
            end
        end
    end

endmodule
