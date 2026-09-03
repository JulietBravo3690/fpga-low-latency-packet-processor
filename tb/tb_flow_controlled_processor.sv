`timescale 1ns/1ps
module tb_flow_controlled_processor;
    localparam [2:0] CLASS_MALFORMED=0, CLASS_NON_IPV4=1, CLASS_MARKET=2;
    localparam [2:0] CLASS_WEB=4, CLASS_CONTROL=5, CLASS_UNKNOWN=7;
    logic clk=0,rst_n=0; logic [7:0] data_in=0; logic valid_in=0,in_ready,sop_in=0,eop_in=0;
    logic drop_unknown=1,clear_counters=0,stats_rd_en=0; logic [3:0]stats_addr=0;
    logic [7:0]data_out;logic valid_out,out_ready=0,sop_out,eop_out,packet_buffer_overflow;
    logic [15:0]tcp_src_port,tcp_dst_port;logic [3:0]tcp_data_offset;logic [7:0]tcp_flags;
    logic class_valid;logic[2:0]packet_class;logic allow_packet,drop_packet;
    logic market_data_packet,market_message_valid,market_decoder_error;
    logic[7:0]market_message_type;logic[31:0]market_symbol,market_price,market_quantity,market_sequence_number;
    logic[31:0]total_packets,allowed_packets,dropped_packets,market_data_packets_count;
    logic[31:0]web_packets_count,control_packets_count,unknown_packets_count,total_ipv4_bytes;
    logic[7:0] frame[0:127];logic[7:0] expected[0:511];logic[7:0] market[0:58];
    logic[2:0]expected_class[0:7];integer expected_count=0,output_count=0,class_count=0;
    integer sop_count=0,eop_count=0,cycle=0,i,market_message_count=0;
    logic stalled=0;logic[7:0]stall_data;logic stall_sop,stall_eop;

    top_packet_processor #(.PACKET_BUFFER_DEPTH(128),.PACKET_INDEX_WIDTH(7)) dut(
      .clk,.rst_n,.data_in,.valid_in,.in_ready,.sop_in,.eop_in,.drop_unknown,
      .clear_counters,.stats_rd_en,.stats_addr,.data_out,.valid_out,.out_ready,.sop_out,.eop_out,
      .packet_buffer_overflow,.tcp_src_port,.tcp_dst_port,.tcp_data_offset,.tcp_flags,
      .class_valid,.packet_class,.allow_packet,.drop_packet,.market_data_packet,
      .market_message_valid,.market_decoder_error,.market_message_type,.market_symbol,
      .market_price,.market_quantity,.market_sequence_number,.total_packets,.allowed_packets,
      .dropped_packets,.market_data_packets_count,.web_packets_count,.control_packets_count,
      .unknown_packets_count,.total_ipv4_bytes);
    always #5 clk=~clk;
    always @(negedge clk)begin cycle=cycle+1;out_ready=((cycle%5)!=0)&&((cycle%7)!=0);end
    always @(posedge clk)begin
      if(valid_out&&!out_ready)begin
        if(stalled&&(data_out!==stall_data||sop_out!==stall_sop||eop_out!==stall_eop))$fatal(1,"egress changed while stalled");
        stalled=1;stall_data=data_out;stall_sop=sop_out;stall_eop=eop_out;
      end else stalled=0;
      if(valid_out&&out_ready)begin
        if(data_out!==expected[output_count])$fatal(1,"egress byte %0d mismatch",output_count);
        if(sop_out)sop_count=sop_count+1;if(eop_out)eop_count=eop_count+1;output_count=output_count+1;
      end
      if(class_valid)begin
        if(packet_class!==expected_class[class_count])$fatal(1,"class %0d mismatch: expected %0d got %0d",class_count,expected_class[class_count],packet_class);
        if(allow_packet==drop_packet)$fatal(1,"invalid allow/drop decision");
        class_count=class_count+1;
      end
      if(market_message_valid)market_message_count=market_message_count+1;
      if(sop_out&&!valid_out)$fatal(1,"SOP without valid");if(eop_out&&!valid_out)$fatal(1,"EOP without valid");
    end
    task send_current(input integer length,input logic forwarded,input logic gaps);
      integer n;begin
        if(forwarded)for(n=0;n<length;n=n+1)begin expected[expected_count]=frame[n];expected_count=expected_count+1;end
        for(n=0;n<length;n=n+1)begin
          if(gaps&&(n%3==1))begin @(negedge clk);valid_in=0;sop_in=0;eop_in=0;end
          @(negedge clk);while(!in_ready)@(negedge clk);
          data_in=frame[n];valid_in=1;sop_in=(n==0);eop_in=(n==length-1);
          @(posedge clk);#1;valid_in=0;sop_in=0;eop_in=0;
        end
      end endtask
    task wait_idle;integer timeout;begin timeout=0;while((output_count<expected_count||!in_ready)&&timeout<1000)begin @(negedge clk);timeout=timeout+1;end if(timeout==1000)$fatal(1,"pipeline timeout");repeat(4)@(negedge clk);end endtask
    task load_market;begin for(i=0;i<59;i=i+1)frame[i]=market[i];end endtask
    task load_unknown_udp;begin load_market();frame[16]=0;frame[17]=8'h1c;
      frame[26]=8'h0a;frame[27]=0;frame[28]=0;frame[29]=3;
      frame[30]=8'h0a;frame[31]=0;frame[32]=0;frame[33]=4;
      frame[34]=8'h0b;frame[35]=8'hb8;frame[36]=8'h0b;frame[37]=8'hb9;frame[38]=0;frame[39]=8;frame[41]=0;end endtask
    task load_tcp(input[15:0]dst);begin
      for(i=0;i<54;i=i+1)frame[i]=0;for(i=0;i<14;i=i+1)frame[i]=market[i];
      frame[14]=8'h45;frame[16]=0;frame[17]=8'h28;frame[22]=8'h40;frame[23]=6;
      frame[26]=8'h0a;frame[29]=1;frame[30]=8'h0a;frame[33]=2;
      frame[34]=8'h13;frame[35]=8'h88;frame[36]=dst[15:8];frame[37]=dst[7:0];frame[46]=8'h50;frame[47]=8'h02;
    end endtask
    initial begin
      $readmemh("sim/market_packet.hex",market);
      expected_class[0]=CLASS_MARKET;expected_class[1]=CLASS_NON_IPV4;expected_class[2]=CLASS_MALFORMED;
      expected_class[3]=CLASS_UNKNOWN;expected_class[4]=CLASS_UNKNOWN;expected_class[5]=CLASS_WEB;
      expected_class[6]=CLASS_WEB;expected_class[7]=CLASS_CONTROL;
      repeat(3)@(negedge clk);rst_n=1;
      load_market();send_current(59,1,1);wait_idle();
      if(market_message_count!=1||market_symbol!="AAPL"||market_price!=18525||
         market_quantity!=100||market_sequence_number!=42)$fatal(1,"market decode mismatch");
      load_market();frame[12]=8'h08;frame[13]=8'h06;send_current(14,0,0);wait_idle();
      frame[0]=8'haa;frame[1]=8'hbb;frame[2]=8'hcc;send_current(3,0,0);wait_idle();
      load_unknown_udp();drop_unknown=1;send_current(42,0,1);wait_idle();
      load_unknown_udp();drop_unknown=0;send_current(42,1,0);wait_idle();
      load_tcp(80);send_current(54,1,1);wait_idle();if(tcp_dst_port!=80||tcp_data_offset!=5)$fatal(1,"HTTP TCP metadata");
      load_tcp(443);send_current(54,1,0);wait_idle();if(tcp_dst_port!=443)$fatal(1,"HTTPS TCP metadata");
      load_tcp(22);send_current(54,1,1);wait_idle();if(tcp_dst_port!=22)$fatal(1,"SSH TCP metadata");
      if(output_count!=263||sop_count!=5||eop_count!=5)$fatal(1,"forwarding totals mismatch");
      if(class_count!=8||total_packets!=8||allowed_packets!=5||dropped_packets!=3)$fatal(1,"decision statistics mismatch");
      if(market_data_packets_count!=1||web_packets_count!=2||control_packets_count!=1||unknown_packets_count!=2)$fatal(1,"class statistics mismatch");
      if(total_ipv4_bytes!=221)$fatal(1,"IPv4 byte total mismatch: %0d",total_ipv4_bytes);
      if(packet_buffer_overflow||market_decoder_error)$fatal(1,"unexpected datapath error");
      $display("flow_controlled_processor tests PASSED");$finish;
    end
endmodule
