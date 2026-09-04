module packet_rom_source (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,

    output logic [7:0] data_out,
    output logic       valid_out,
    output logic       sop_out,
    output logic       eop_out,
    output logic       busy,
    output logic       done
);

    localparam logic [6:0] LAST_BYTE_INDEX = 7'd58;

    logic [6:0] byte_index;
    logic       start_d;

    // A case-ROM is used instead of an initialization file so the reference
    // packet remains self-contained and portable across synthesis tools.
    function automatic logic [7:0] packet_byte(input logic [6:0] index);
        begin
            case (index)
                7'd0: packet_byte = 8'hAA; 7'd1: packet_byte = 8'hBB;
                7'd2: packet_byte = 8'hCC; 7'd3: packet_byte = 8'hDD;
                7'd4: packet_byte = 8'hEE; 7'd5: packet_byte = 8'hFF;
                7'd6: packet_byte = 8'h11; 7'd7: packet_byte = 8'h22;
                7'd8: packet_byte = 8'h33; 7'd9: packet_byte = 8'h44;
                7'd10: packet_byte = 8'h55; 7'd11: packet_byte = 8'h66;
                7'd12: packet_byte = 8'h08; 7'd13: packet_byte = 8'h00;
                7'd14: packet_byte = 8'h45; 7'd15: packet_byte = 8'h00;
                7'd16: packet_byte = 8'h00; 7'd17: packet_byte = 8'h2D;
                7'd18: packet_byte = 8'h00; 7'd19: packet_byte = 8'h01;
                7'd20: packet_byte = 8'h40; 7'd21: packet_byte = 8'h00;
                7'd22: packet_byte = 8'h40; 7'd23: packet_byte = 8'h11;
                7'd24: packet_byte = 8'hB7; 7'd25: packet_byte = 8'h50;
                7'd26: packet_byte = 8'hC0; 7'd27: packet_byte = 8'hA8;
                7'd28: packet_byte = 8'h01; 7'd29: packet_byte = 8'h0A;
                7'd30: packet_byte = 8'hC0; 7'd31: packet_byte = 8'hA8;
                7'd32: packet_byte = 8'h01; 7'd33: packet_byte = 8'h14;
                7'd34: packet_byte = 8'h13; 7'd35: packet_byte = 8'h88;
                7'd36: packet_byte = 8'h17; 7'd37: packet_byte = 8'h70;
                7'd38: packet_byte = 8'h00; 7'd39: packet_byte = 8'h19;
                7'd40: packet_byte = 8'h00; 7'd41: packet_byte = 8'h00;
                7'd42: packet_byte = 8'h01; 7'd43: packet_byte = 8'h41;
                7'd44: packet_byte = 8'h41; 7'd45: packet_byte = 8'h50;
                7'd46: packet_byte = 8'h4C; 7'd47: packet_byte = 8'h00;
                7'd48: packet_byte = 8'h00; 7'd49: packet_byte = 8'h48;
                7'd50: packet_byte = 8'h5D; 7'd51: packet_byte = 8'h00;
                7'd52: packet_byte = 8'h00; 7'd53: packet_byte = 8'h00;
                7'd54: packet_byte = 8'h64; 7'd55: packet_byte = 8'h00;
                7'd56: packet_byte = 8'h00; 7'd57: packet_byte = 8'h00;
                7'd58: packet_byte = 8'h2A;
                default: packet_byte = 8'h00;
            endcase
        end
    endfunction

    always_comb begin
        data_out  = packet_byte(byte_index);
        valid_out = busy;
        sop_out   = busy && (byte_index == 7'd0);
        eop_out   = busy && (byte_index == LAST_BYTE_INDEX);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_index <= 7'd0;
            start_d    <= 1'b0;
            busy       <= 1'b0;
            done       <= 1'b0;
        end else begin
            start_d <= start;
            done    <= 1'b0;

            if (!busy) begin
                byte_index <= 7'd0;
                if (start && !start_d) begin
                    busy <= 1'b1;
                end
            end else if (byte_index == LAST_BYTE_INDEX) begin
                byte_index <= 7'd0;
                busy       <= 1'b0;
                done       <= 1'b1;
            end else begin
                byte_index <= byte_index + 7'd1;
            end
        end
    end

endmodule
