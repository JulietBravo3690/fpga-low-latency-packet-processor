SIM_DIR = sim
IVERILOG = iverilog
VVP = vvp
SV_FLAGS = -g2012

.PHONY: test-stream test-eth test-ipv4 test-udp test-classifier test-top test-stats test-latency test-market test-python test-all clean

test-stream:
	mkdir -p $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/packet_stream_input_tb.vvp rtl/packet_stream_input.sv tb/tb_packet_stream_input.sv
	$(VVP) $(SIM_DIR)/packet_stream_input_tb.vvp

test-eth:
	mkdir -p $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/ethernet_parser_tb.vvp rtl/ethernet_parser.sv tb/tb_ethernet_parser.sv
	$(VVP) $(SIM_DIR)/ethernet_parser_tb.vvp

test-ipv4:
	mkdir -p $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/ipv4_parser_tb.vvp rtl/ipv4_parser.sv tb/tb_ipv4_parser.sv
	$(VVP) $(SIM_DIR)/ipv4_parser_tb.vvp

test-udp:
	mkdir -p $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/udp_parser_tb.vvp rtl/udp_parser.sv tb/tb_udp_parser.sv
	$(VVP) $(SIM_DIR)/udp_parser_tb.vvp

test-classifier:
	mkdir -p $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/packet_classifier_tb.vvp rtl/packet_classifier.sv tb/tb_packet_classifier.sv
	$(VVP) $(SIM_DIR)/packet_classifier_tb.vvp

test-top:
	mkdir -p $(SIM_DIR)
	python3 scripts/generate_market_packet.py --symbol AAPL --price 18525 --quantity 100 --sequence 42 --hex-output $(SIM_DIR)/market_packet.hex
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/top_packet_processor_tb.vvp rtl/ethernet_parser.sv rtl/ipv4_parser.sv rtl/udp_parser.sv rtl/packet_classifier.sv rtl/traffic_stats.sv rtl/latency_tracker.sv rtl/market_data_decoder.sv rtl/top_packet_processor.sv tb/tb_top_packet_processor.sv
	$(VVP) $(SIM_DIR)/top_packet_processor_tb.vvp

test-stats:
	mkdir -p $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/traffic_stats_tb.vvp rtl/traffic_stats.sv tb/tb_traffic_stats.sv
	$(VVP) $(SIM_DIR)/traffic_stats_tb.vvp

test-latency:
	mkdir -p $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/latency_tracker_tb.vvp rtl/latency_tracker.sv tb/tb_latency_tracker.sv
	$(VVP) $(SIM_DIR)/latency_tracker_tb.vvp

test-market:
	mkdir -p $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/market_data_decoder_tb.vvp rtl/market_data_decoder.sv tb/tb_market_data_decoder.sv
	$(VVP) $(SIM_DIR)/market_data_decoder_tb.vvp

test-python:
	python3 -m unittest discover -s tb -p 'tb_*.py' -v

test-all: test-stream test-eth test-ipv4 test-udp test-classifier test-stats test-latency test-market test-top test-python

clean:
	rm -f $(SIM_DIR)/*.vvp
	rm -f $(SIM_DIR)/*.vcd
	rm -f $(SIM_DIR)/market_packet.hex
