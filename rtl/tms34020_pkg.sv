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
    localparam int unsigned TMS34020_ST_FS0_LSB = 0;
    localparam int unsigned TMS34020_ST_FE0_BIT = 5;
    localparam int unsigned TMS34020_ST_FS1_LSB = 6;
    localparam int unsigned TMS34020_ST_FE1_BIT = 11;
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

    function automatic logic tms34020_condition_true(
        input logic [3:0]  condition_code,
        input logic [31:0] status
    );
        logic n;
        logic c;
        logic z;
        logic v;
        begin
            n = status[TMS34020_ST_N_BIT];
            c = status[TMS34020_ST_C_BIT];
            z = status[TMS34020_ST_Z_BIT];
            v = status[TMS34020_ST_V_BIT];
            case (condition_code)
                4'h0: tms34020_condition_true = 1'b1;
                4'h1: tms34020_condition_true = !n && !z;
                4'h2: tms34020_condition_true = c || z;
                4'h3: tms34020_condition_true = !c && !z;
                4'h4: tms34020_condition_true = n != v;
                4'h5: tms34020_condition_true = n == v;
                4'h6: tms34020_condition_true = (n != v) || z;
                4'h7: tms34020_condition_true = (n == v) && !z;
                4'h8: tms34020_condition_true = c;
                4'h9: tms34020_condition_true = !c;
                4'hA: tms34020_condition_true = z;
                4'hB: tms34020_condition_true = !z;
                4'hC: tms34020_condition_true = v;
                4'hD: tms34020_condition_true = !v;
                4'hE: tms34020_condition_true = n;
                4'hF: tms34020_condition_true = !n;
                default: tms34020_condition_true = 1'b0;
            endcase
        end
    endfunction

`include "generated/tms34020_isa_decode.svh"

endpackage

`default_nettype wire
