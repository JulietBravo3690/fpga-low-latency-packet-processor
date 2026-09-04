SIM_DIR = sim
IVERILOG = iverilog
VVP = vvp
VERILATOR = verilator
YOSYS = yosys
SV_FLAGS = -g2012

CORE_RTL = rtl/ethernet_parser.sv rtl/ipv4_parser.sv rtl/udp_parser.sv rtl/tcp_parser.sv \
	rtl/packet_classifier.sv rtl/traffic_stats.sv rtl/latency_tracker.sv \
	rtl/market_data_decoder.sv rtl/packet_gate.sv rtl/top_packet_processor.sv
DEMO_RTL = rtl/packet_rom_source.sv $(CORE_RTL) rtl/hardware_status.sv \
	rtl/hardware_demo_top.sv
MARKET_HEX = $(SIM_DIR)/market_packet.hex

.PHONY: help check-structure test-stream test-eth test-ipv4 test-udp test-tcp test-gate \
	test-flow test-classifier test-top \
	test-stats test-latency test-market test-packet-source test-hardware-demo \
	test-python test-all lint synth-check clean

help:
	@printf '%s\n' \
	  'make test-all           Run all functional RTL and Python tests' \
	  'make check-structure    Reject merge markers and duplicate targets/modules' \
	  'make test-hardware-demo Run the board-agnostic demo integration test' \
	  'make test-flow          Run flow control, enforcement, and TCP integration' \
	  'make lint               Run Verilator lint on synthesizable RTL' \
	  'make synth-check        Run generic Yosys synthesis and structural checks' \
	  'make clean              Remove generated simulation and synthesis outputs'

$(SIM_DIR):
	mkdir -p $(SIM_DIR)

$(MARKET_HEX): scripts/generate_market_packet.py | $(SIM_DIR)
	python3 scripts/generate_market_packet.py --symbol AAPL --price 18525 --quantity 100 --sequence 42 --hex-output $@

check-structure:
	python3 scripts/check_repository_structure.py

test-stream: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/packet_stream_input_tb.vvp rtl/packet_stream_input.sv tb/tb_packet_stream_input.sv
	$(VVP) $(SIM_DIR)/packet_stream_input_tb.vvp

test-eth: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/ethernet_parser_tb.vvp rtl/ethernet_parser.sv tb/tb_ethernet_parser.sv
	$(VVP) $(SIM_DIR)/ethernet_parser_tb.vvp

test-ipv4: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/ipv4_parser_tb.vvp rtl/ipv4_parser.sv tb/tb_ipv4_parser.sv
	$(VVP) $(SIM_DIR)/ipv4_parser_tb.vvp

test-udp: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/udp_parser_tb.vvp rtl/udp_parser.sv tb/tb_udp_parser.sv
	$(VVP) $(SIM_DIR)/udp_parser_tb.vvp

test-tcp: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/tcp_parser_tb.vvp rtl/tcp_parser.sv tb/tb_tcp_parser.sv
	$(VVP) $(SIM_DIR)/tcp_parser_tb.vvp

test-gate: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/packet_gate_tb.vvp rtl/packet_gate.sv tb/tb_packet_gate.sv
	$(VVP) $(SIM_DIR)/packet_gate_tb.vvp

test-flow: $(MARKET_HEX)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/flow_controlled_processor_tb.vvp $(CORE_RTL) tb/tb_flow_controlled_processor.sv
	$(VVP) $(SIM_DIR)/flow_controlled_processor_tb.vvp

test-classifier: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/packet_classifier_tb.vvp rtl/packet_classifier.sv tb/tb_packet_classifier.sv
	$(VVP) $(SIM_DIR)/packet_classifier_tb.vvp

test-top: $(MARKET_HEX)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/top_packet_processor_tb.vvp $(CORE_RTL) tb/tb_top_packet_processor.sv
	$(VVP) $(SIM_DIR)/top_packet_processor_tb.vvp

test-stats: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/traffic_stats_tb.vvp rtl/traffic_stats.sv tb/tb_traffic_stats.sv
	$(VVP) $(SIM_DIR)/traffic_stats_tb.vvp

test-latency: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/latency_tracker_tb.vvp rtl/latency_tracker.sv tb/tb_latency_tracker.sv
	$(VVP) $(SIM_DIR)/latency_tracker_tb.vvp

test-market: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/market_data_decoder_tb.vvp rtl/market_data_decoder.sv tb/tb_market_data_decoder.sv
	$(VVP) $(SIM_DIR)/market_data_decoder_tb.vvp

test-packet-source: $(MARKET_HEX)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/packet_rom_source_tb.vvp rtl/packet_rom_source.sv tb/tb_packet_rom_source.sv
	$(VVP) $(SIM_DIR)/packet_rom_source_tb.vvp

test-hardware-demo: | $(SIM_DIR)
	$(IVERILOG) $(SV_FLAGS) -o $(SIM_DIR)/hardware_demo_top_tb.vvp $(DEMO_RTL) tb/tb_hardware_demo_top.sv
	$(VVP) $(SIM_DIR)/hardware_demo_top_tb.vvp

test-python:
	python3 -m unittest discover -s tb -p 'tb_*.py' -v

test-all: check-structure test-stream test-eth test-ipv4 test-udp test-tcp test-gate test-flow \
	test-classifier test-stats test-latency test-market test-top \
	test-packet-source test-hardware-demo test-python

# PINMISSING: the demo intentionally leaves optional core observability ports open.
# UNUSEDSIGNAL: parser diagnostic/pass-through signals remain part of the public core.
lint:
	$(VERILATOR) --lint-only --Wall -Wno-PINMISSING -Wno-UNUSEDSIGNAL \
		--top-module hardware_demo_top rtl/*.sv

synth-check:
	mkdir -p build
	$(YOSYS) -q -l build/yosys.log -p 'read_verilog -sv rtl/*.sv; synth -top hardware_demo_top; check'
	@echo "Generic Yosys synthesis check PASSED (see build/yosys.log)."

clean:
	rm -f $(SIM_DIR)/*.vvp
	rm -f $(SIM_DIR)/*.vcd
	rm -f $(SIM_DIR)/market_packet.hex
	rm -rf build
