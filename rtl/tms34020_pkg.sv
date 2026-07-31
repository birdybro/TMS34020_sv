`timescale 1ns/1ps
`default_nettype none

package tms34020_pkg;

    localparam int unsigned TMS34020_DATA_WIDTH = 32;
    localparam int unsigned TMS34020_WORD_BITS = 16;

    localparam int unsigned TMS34020_ST_V_BIT = 28;
    localparam int unsigned TMS34020_ST_Z_BIT = 29;
    localparam int unsigned TMS34020_ST_C_BIT = 30;
    localparam int unsigned TMS34020_ST_N_BIT = 31;
    localparam logic [31:0] TMS34020_ST_RESET = 32'h0000_0010;

`include "generated/tms34020_isa_decode.svh"

endpackage

`default_nettype wire
