PYTHON ?= python3
VERILATOR ?= verilator
YOSYS ?= yosys
QUARTUS_SH ?= quartus_sh

.DEFAULT_GOAL := help

.PHONY: help doctor foundation lint reference-tests delta-tests isa-tests model-tests rtl-leaf-tests decode-tests instruction-tests
.PHONY: compatibility-tests cache-tests memory-tests graphics-tests video-tests
.PHONY: host-tests fault-tests coprocessor-tests bus-tests differential fuzz
.PHONY: formal synth-yosys synth-quartus quartus-leaf-smoke quartus-cache-smoke battletoads-tests revx-tests test clean

help:
	@$(PYTHON) scripts/run_suite.py --list

doctor:
	@$(PYTHON) scripts/run_suite.py doctor

foundation:
	@$(PYTHON) scripts/run_suite.py foundation

lint:
	@$(PYTHON) scripts/run_suite.py lint

reference-tests:
	@$(PYTHON) scripts/run_suite.py references

delta-tests:
	@$(PYTHON) scripts/run_suite.py delta

isa-tests:
	@$(PYTHON) scripts/run_suite.py isa

model-tests:
	@$(PYTHON) scripts/run_suite.py model

rtl-leaf-tests:
	@$(PYTHON) scripts/run_suite.py rtl-leaf

decode-tests:
	@$(PYTHON) scripts/run_suite.py decode

instruction-tests:
	@$(PYTHON) scripts/run_suite.py instruction

compatibility-tests:
	@$(PYTHON) scripts/run_suite.py compatibility

cache-tests:
	@$(PYTHON) scripts/run_suite.py cache

memory-tests:
	@$(PYTHON) scripts/run_suite.py memory

graphics-tests:
	@$(PYTHON) scripts/run_suite.py graphics

video-tests:
	@$(PYTHON) scripts/run_suite.py video

host-tests:
	@$(PYTHON) scripts/run_suite.py host

fault-tests:
	@$(PYTHON) scripts/run_suite.py fault

coprocessor-tests:
	@$(PYTHON) scripts/run_suite.py coprocessor

bus-tests:
	@$(PYTHON) scripts/run_suite.py bus

differential:
	@$(PYTHON) scripts/run_suite.py differential

fuzz:
	@$(PYTHON) scripts/run_suite.py fuzz

formal:
	@$(PYTHON) scripts/run_suite.py formal

synth-yosys:
	@$(PYTHON) scripts/run_suite.py synth-yosys

synth-quartus:
	@$(PYTHON) scripts/run_suite.py synth-quartus

quartus-leaf-smoke:
	@$(PYTHON) scripts/run_suite.py quartus-leaf-smoke

quartus-cache-smoke:
	@$(PYTHON) scripts/run_suite.py quartus-cache-smoke

battletoads-tests:
	@$(PYTHON) scripts/run_suite.py battletoads

revx-tests:
	@$(PYTHON) scripts/run_suite.py revx

test: foundation lint reference-tests delta-tests isa-tests model-tests rtl-leaf-tests cache-tests decode-tests
	@printf '%s\n' 'PASS: implemented regression suites'

clean:
	@$(PYTHON) scripts/run_suite.py clean
