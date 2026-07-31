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

    typedef enum logic [1:0] {
        TMS34020_UNARY_ABS  = 2'b00,
        TMS34020_UNARY_NEG  = 2'b01,
        TMS34020_UNARY_NEGB = 2'b10,
        TMS34020_UNARY_NOT  = 2'b11
    } tms34020_unary_op_t;

`include "generated/tms34020_isa_decode.svh"

endpackage

`default_nettype wire
