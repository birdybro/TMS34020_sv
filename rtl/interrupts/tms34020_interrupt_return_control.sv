`default_nettype none

module tms34020_interrupt_return_control (
    input  logic [31:0] old_sp_i,
    input  logic [31:0] saved_st_i,
    input  logic [31:0] saved_pc_i,
    input  logic        monitor_return_i,
    output logic        normal_context_o,
    output logic        ix_context_o,
    output logic        bf_context_o,
    output logic [5:0]  extra_context_words_o,
    output logic [5:0]  visible_states_o,
    output logic [31:0] normal_final_sp_o,
    output logic [31:0] aligned_pc_o,
    output logic        saved_pc_misaligned_o,
    output logic        force_next_instruction_bypass_o,
    output logic        delay_interrupt_recognition_o,
    output logic [31:0] post_context_st_o
);

    import tms34020_pkg::*;

    always_comb begin
        bf_context_o = saved_st_i[TMS34020_ST_BF_BIT];
        ix_context_o = saved_st_i[TMS34020_ST_IX_BIT] &&
            !saved_st_i[TMS34020_ST_BF_BIT];
        normal_context_o = !saved_st_i[TMS34020_ST_BF_BIT] &&
            !saved_st_i[TMS34020_ST_IX_BIT];
        extra_context_words_o = 6'd0;
        visible_states_o = monitor_return_i ? 6'd10 : 6'd7;
        if (bf_context_o) begin
            extra_context_words_o = 6'd31;
            visible_states_o = 6'd52;
        end else if (ix_context_o) begin
            extra_context_words_o = 6'd24;
            visible_states_o = 6'd38;
        end

        normal_final_sp_o = old_sp_i + 32'd64;
        aligned_pc_o = {saved_pc_i[31:4], 4'd0};
        saved_pc_misaligned_o = |saved_pc_i[3:0];
        force_next_instruction_bypass_o = monitor_return_i;
        delay_interrupt_recognition_o = monitor_return_i;
        post_context_st_o = saved_st_i;
        post_context_st_o[TMS34020_ST_BF_BIT] = 1'b0;
        post_context_st_o[TMS34020_ST_IX_BIT] = 1'b0;
    end

endmodule

`default_nettype wire
