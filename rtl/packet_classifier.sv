module packet_classifier #(
    parameter [31:0] TRUSTED_SRC_IP   = 32'hC0A8010A, // 192.168.1.10
    parameter [31:0] TRUSTED_DST_IP   = 32'hC0A80114, // 192.168.1.20

    parameter [15:0] MARKET_PORT_MIN  = 16'd5000,
    parameter [15:0] MARKET_PORT_MAX  = 16'd6000,

    parameter [15:0] DNS_PORT         = 16'd53,
    parameter [15:0] HTTP_PORT        = 16'd80,
    parameter [15:0] HTTPS_PORT       = 16'd443,
    parameter [15:0] SSH_PORT         = 16'd22,
    parameter [15:0] NTP_PORT         = 16'd123,
    parameter [15:0] CONTROL_PORT     = 16'd9000
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        metadata_valid,

    input  logic        parser_error,

    input  logic [15:0] ethertype,
    input  logic [7:0]  ip_protocol,
    input  logic [31:0] src_ip,
    input  logic [31:0] dst_ip,
    input  logic [15:0] src_port,
    input  logic [15:0] dst_port,

    input  logic        drop_unknown,

    output logic        class_valid,
    output logic [2:0]  packet_class,

    output logic        allow_packet,
    output logic        drop_packet,

    output logic        malformed_packet,
    output logic        non_ipv4_packet,
    output logic        market_data_packet,
    output logic        dns_packet,
    output logic        web_packet,
    output logic        control_packet,
    output logic        trusted_packet,
    output logic        unknown_packet
);

    localparam [2:0] CLASS_MALFORMED   = 3'd0;
    localparam [2:0] CLASS_NON_IPV4    = 3'd1;
    localparam [2:0] CLASS_MARKET_DATA = 3'd2;
    localparam [2:0] CLASS_DNS         = 3'd3;
    localparam [2:0] CLASS_WEB         = 3'd4;
    localparam [2:0] CLASS_CONTROL     = 3'd5;
    localparam [2:0] CLASS_TRUSTED     = 3'd6;
    localparam [2:0] CLASS_UNKNOWN     = 3'd7;

    logic is_ipv4;
    logic is_udp;
    logic is_tcp;

    logic is_market_data;
    logic is_dns;
    logic is_web;
    logic is_control;
    logic is_trusted;

    assign is_ipv4 = (ethertype == 16'h0800);
    assign is_udp  = (ip_protocol == 8'd17);
    assign is_tcp  = (ip_protocol == 8'd6);

    assign is_market_data =
        is_udp &&
        (
            ((dst_port >= MARKET_PORT_MIN) && (dst_port <= MARKET_PORT_MAX)) ||
            ((src_port >= MARKET_PORT_MIN) && (src_port <= MARKET_PORT_MAX))
        );

    assign is_dns =
        (src_port == DNS_PORT) ||
        (dst_port == DNS_PORT);

    assign is_web =
        is_tcp &&
        (
            (dst_port == HTTP_PORT)  ||
            (src_port == HTTP_PORT)  ||
            (dst_port == HTTPS_PORT) ||
            (src_port == HTTPS_PORT)
        );

    assign is_control =
        (src_port == SSH_PORT)     ||
        (dst_port == SSH_PORT)     ||
        (src_port == NTP_PORT)     ||
        (dst_port == NTP_PORT)     ||
        (src_port == CONTROL_PORT) ||
        (dst_port == CONTROL_PORT);

    assign is_trusted =
        (src_ip == TRUSTED_SRC_IP) ||
        (dst_ip == TRUSTED_DST_IP);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            class_valid        <= 1'b0;
            packet_class       <= CLASS_UNKNOWN;

            allow_packet       <= 1'b0;
            drop_packet        <= 1'b0;

            malformed_packet   <= 1'b0;
            non_ipv4_packet    <= 1'b0;
            market_data_packet <= 1'b0;
            dns_packet         <= 1'b0;
            web_packet         <= 1'b0;
            control_packet     <= 1'b0;
            trusted_packet     <= 1'b0;
            unknown_packet     <= 1'b0;
        end else begin
            // Default one-cycle outputs
            class_valid        <= 1'b0;

            malformed_packet   <= 1'b0;
            non_ipv4_packet    <= 1'b0;
            market_data_packet <= 1'b0;
            dns_packet         <= 1'b0;
            web_packet         <= 1'b0;
            control_packet     <= 1'b0;
            trusted_packet     <= 1'b0;
            unknown_packet     <= 1'b0;

            allow_packet       <= 1'b0;
            drop_packet        <= 1'b0;
            packet_class       <= CLASS_UNKNOWN;

            if (metadata_valid) begin
                class_valid <= 1'b1;

                if (parser_error) begin
                    packet_class     <= CLASS_MALFORMED;
                    malformed_packet <= 1'b1;
                    allow_packet     <= 1'b0;
                    drop_packet      <= 1'b1;
                end

                else if (!is_ipv4) begin
                    packet_class    <= CLASS_NON_IPV4;
                    non_ipv4_packet <= 1'b1;
                    allow_packet    <= 1'b0;
                    drop_packet     <= 1'b1;
                end

                else if (is_market_data) begin
                    packet_class       <= CLASS_MARKET_DATA;
                    market_data_packet <= 1'b1;
                    trusted_packet     <= is_trusted;
                    allow_packet       <= 1'b1;
                    drop_packet        <= 1'b0;
                end

                else if (is_dns) begin
                    packet_class   <= CLASS_DNS;
                    dns_packet     <= 1'b1;
                    trusted_packet <= is_trusted;
                    allow_packet   <= 1'b1;
                    drop_packet    <= 1'b0;
                end

                else if (is_web) begin
                    packet_class   <= CLASS_WEB;
                    web_packet     <= 1'b1;
                    trusted_packet <= is_trusted;
                    allow_packet   <= 1'b1;
                    drop_packet    <= 1'b0;
                end

                else if (is_control) begin
                    packet_class   <= CLASS_CONTROL;
                    control_packet <= 1'b1;
                    trusted_packet <= is_trusted;
                    allow_packet   <= 1'b1;
                    drop_packet    <= 1'b0;
                end

                else if (is_trusted) begin
                    packet_class   <= CLASS_TRUSTED;
                    trusted_packet <= 1'b1;
                    allow_packet   <= 1'b1;
                    drop_packet    <= 1'b0;
                end

                else begin
                    packet_class   <= CLASS_UNKNOWN;
                    unknown_packet <= 1'b1;
                    allow_packet   <= !drop_unknown;
                    drop_packet    <= drop_unknown;
                end
            end
        end
    end

endmodule