`timescale 1ns/1ps
`default_nettype none

package tms34020_pkg;

    localparam int unsigned TMS34020_DATA_WIDTH = 32;
    localparam int unsigned TMS34020_WORD_BITS = 16;

    localparam int unsigned TMS34020_ST_V_BIT = 28;
    localparam int unsigned TMS34020_ST_Z_BIT = 29;
    localparam int unsigned TMS34020_ST_C_BIT = 30;
    localparam int unsigned TMS34020_ST_N_BIT = 31;
    localparam int unsigned TMS34020_ST_IE_BIT = 21;
    localparam int unsigned TMS34020_ST_SS_BIT = 22;
    localparam int unsigned TMS34020_ST_IX_BIT = 25;
    localparam int unsigned TMS34020_ST_BF_BIT = 26;
    localparam logic [31:0] TMS34020_ST_RESET = 32'h0000_0010;
    localparam logic [31:0] TMS34020_ST_RESERVED_MASK =
        32'h099F_F000;

    typedef enum logic [1:0] {
        TMS34020_UNARY_ABS  = 2'b00,
        TMS34020_UNARY_NEG  = 2'b01,
        TMS34020_UNARY_NEGB = 2'b10,
        TMS34020_UNARY_NOT  = 2'b11
    } tms34020_unary_op_t;

    typedef enum logic [2:0] {
        TMS34020_BINARY_ADD  = 3'd0,
        TMS34020_BINARY_ADDC = 3'd1,
        TMS34020_BINARY_SUB  = 3'd2,
        TMS34020_BINARY_SUBB = 3'd3,
        TMS34020_BINARY_CMP  = 3'd4
    } tms34020_binary_op_t;

    typedef enum logic {
        TMS34020_XY_ADD = 1'b0,
        TMS34020_XY_SUB = 1'b1
    } tms34020_xy_op_t;

    typedef enum logic [1:0] {
        TMS34020_LOGICAL_AND  = 2'd0,
        TMS34020_LOGICAL_ANDN = 2'd1,
        TMS34020_LOGICAL_OR   = 2'd2,
        TMS34020_LOGICAL_XOR  = 2'd3
    } tms34020_logical_op_t;

    typedef enum logic [1:0] {
        TMS34020_SHIFT_SLA = 2'd0,
        TMS34020_SHIFT_SLL = 2'd1,
        TMS34020_SHIFT_SRA = 2'd2,
        TMS34020_SHIFT_SRL = 2'd3
    } tms34020_shift_op_t;

    typedef enum logic [1:0] {
        TMS34020_CACHE_HIT             = 2'd0,
        TMS34020_CACHE_SEGMENT_MISS    = 2'd1,
        TMS34020_CACHE_SUBSEGMENT_MISS = 2'd2,
        TMS34020_CACHE_BYPASS          = 2'd3
    } tms34020_cache_result_t;

    typedef enum logic [1:0] {
        TMS34020_MEMORY_SUCCESS  = 2'd0,
        TMS34020_MEMORY_RETRY    = 2'd1,
        TMS34020_MEMORY_FAULT    = 2'd2,
        TMS34020_MEMORY_RESERVED = 2'd3
    } tms34020_memory_completion_t;

`include "generated/tms34020_isa_decode.svh"

endpackage

`default_nettype wire
