`timescale 1ns/1ps
`default_nettype none

module tms34020_scalar_slice (
    input  logic        clk_i,
    input  logic        reset_i,

    input  logic        pc_load_valid_i,
    output logic        pc_load_ready_o,
    input  logic [31:0] pc_load_bit_address_i,

    input  logic        cache_disable_i,
    input  logic        cache_flush_i,

    output logic        packet_valid_o,
    output logic        packet_supported_o,
    output logic        packet_blocked_o,
    output tms34020_pkg::tms34020_opcode_id_t packet_opcode_id_o,
    output logic [2:0]  packet_length_words_o,
    output logic [79:0] packet_words_o,
    output logic [31:0] packet_start_pc_o,

    output logic        commit_accepted_o,
    output logic        register_write_enable_o,
    output logic        register_write_file_o,
    output logic [3:0]  register_write_index_o,
    output logic [31:0] register_write_data_o,
    output logic        status_write_enable_o,
    output logic [31:0] status_write_data_o,
    output logic [31:0] status_write_mask_o,
    output logic [31:0] status_o,
    output logic [31:0] sp_o,

    output logic        memory_request_valid_o,
    input  logic        memory_request_ready_i,
    output logic [31:0] memory_request_bit_address_o,
    output logic        memory_request_width_32_o,
    output logic        memory_request_cache_fill_o,
    output logic [1:0]  memory_request_sequence_index_o,

    input  logic        memory_response_valid_i,
    output logic        memory_response_ready_o,
    input  logic [31:0] memory_response_data_i,
    input  tms34020_pkg::tms34020_memory_completion_t
                       memory_response_completion_i,

    output logic        faulted_o,
    input  logic        fault_resume_i,
    input  logic        fault_abort_i,
    output logic        fetch_aborted_o,

    output logic [31:0] cache_present_debug_o,
    output logic [7:0]  cache_lru_debug_o,
    output logic [3:0]  cache_tag_valid_debug_o
);

    import tms34020_pkg::*;

    logic packet_decode_valid;
    logic [9:0] packet_cache_results_unused;
    logic [31:0] packet_sequential_next_pc;
    logic frontend_completion_valid;
    logic frontend_completion_ready;
    logic register_commit_supported;
    logic execution_eligible;
    logic commit_pc_redirect_enable;
    logic [31:0] commit_pc_redirect_bit_address;
    logic completion_redirect_q;
    logic [31:0] completion_redirect_bit_address_q;

    always_comb begin
        execution_eligible =
            packet_valid_o &&
            packet_decode_valid &&
            register_commit_supported;
        packet_supported_o = execution_eligible;
        packet_blocked_o = packet_valid_o && !execution_eligible;
        frontend_completion_valid = frontend_completion_ready;
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            completion_redirect_q <= 1'b0;
            completion_redirect_bit_address_q <= 32'd0;
        end else if (commit_accepted_o) begin
            completion_redirect_q <= commit_pc_redirect_enable;
            completion_redirect_bit_address_q <=
                commit_pc_redirect_bit_address;
        end else if (
            frontend_completion_valid &&
            frontend_completion_ready
        ) begin
            completion_redirect_q <= 1'b0;
            completion_redirect_bit_address_q <= 32'd0;
        end
    end

    tms34020_frontend frontend (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .pc_load_valid_i(pc_load_valid_i),
        .pc_load_ready_o(pc_load_ready_o),
        .pc_load_bit_address_i(pc_load_bit_address_i),
        .cache_disable_i(cache_disable_i),
        .cache_flush_i(cache_flush_i),
        .packet_valid_o(packet_valid_o),
        .packet_ready_i(execution_eligible),
        .packet_decode_valid_o(packet_decode_valid),
        .packet_opcode_id_o(packet_opcode_id_o),
        .packet_length_words_o(packet_length_words_o),
        .packet_words_o(packet_words_o),
        .packet_cache_results_o(packet_cache_results_unused),
        .packet_start_pc_o(packet_start_pc_o),
        .packet_sequential_next_pc_o(
            packet_sequential_next_pc
        ),
        .completion_valid_i(frontend_completion_valid),
        .completion_ready_o(frontend_completion_ready),
        .completion_redirect_i(completion_redirect_q),
        .completion_redirect_bit_address_i(
            completion_redirect_bit_address_q
        ),
        .memory_request_valid_o(memory_request_valid_o),
        .memory_request_ready_i(memory_request_ready_i),
        .memory_request_bit_address_o(
            memory_request_bit_address_o
        ),
        .memory_request_width_32_o(memory_request_width_32_o),
        .memory_request_cache_fill_o(
            memory_request_cache_fill_o
        ),
        .memory_request_sequence_index_o(
            memory_request_sequence_index_o
        ),
        .memory_response_valid_i(memory_response_valid_i),
        .memory_response_ready_o(memory_response_ready_o),
        .memory_response_data_i(memory_response_data_i),
        .memory_response_completion_i(
            memory_response_completion_i
        ),
        .faulted_o(faulted_o),
        .fault_resume_i(fault_resume_i),
        .fault_abort_i(fault_abort_i),
        .fetch_aborted_o(fetch_aborted_o),
        .cache_present_debug_o(cache_present_debug_o),
        .cache_lru_debug_o(cache_lru_debug_o),
        .cache_tag_valid_debug_o(cache_tag_valid_debug_o)
    );

    tms34020_register_commit register_commit (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .commit_i(execution_eligible),
        .packet_words_i(packet_words_o[47:0]),
        .packet_length_words_i(packet_length_words_o),
        .sequential_next_pc_i(packet_sequential_next_pc),
        .supported_o(register_commit_supported),
        .commit_accepted_o(commit_accepted_o),
        .register_write_enable_o(register_write_enable_o),
        .register_write_file_o(register_write_file_o),
        .register_write_index_o(register_write_index_o),
        .register_write_data_o(register_write_data_o),
        .status_write_enable_o(status_write_enable_o),
        .status_write_data_o(status_write_data_o),
        .status_write_mask_o(status_write_mask_o),
        .pc_redirect_enable_o(commit_pc_redirect_enable),
        .pc_redirect_bit_address_o(
            commit_pc_redirect_bit_address
        ),
        .status_o(status_o),
        .sp_o(sp_o)
    );

`ifndef SYNTHESIS
    property p_only_supported_packets_commit;
        @(posedge clk_i) disable iff (reset_i)
            commit_accepted_o
            |-> packet_valid_o &&
                packet_decode_valid &&
                register_commit_supported &&
                (
                    packet_length_words_o == 3'd1 ||
                    (
                        packet_length_words_o == 3'd2 &&
                        (
                            packet_opcode_id_o == TMS20_OP_ADDI_W ||
                            packet_opcode_id_o == TMS20_OP_CMPI_W ||
                            packet_opcode_id_o == TMS20_OP_SUBI_W ||
                            packet_opcode_id_o == TMS20_OP_MOVI_W
                        )
                    ) ||
                    (
                        packet_length_words_o == 3'd3 &&
                        (
                            packet_opcode_id_o == TMS20_OP_ANDNI ||
                            packet_opcode_id_o == TMS20_OP_ORI ||
                            packet_opcode_id_o == TMS20_OP_XORI ||
                            packet_opcode_id_o == TMS20_OP_ADDXYI ||
                            packet_opcode_id_o == TMS20_OP_ADDI_L ||
                            packet_opcode_id_o == TMS20_OP_CMPI_L ||
                            packet_opcode_id_o == TMS20_OP_SUBI_L ||
                            packet_opcode_id_o == TMS20_OP_MOVI_L
                        )
                    )
                );
    endproperty

    property p_blocked_packet_cannot_write;
        @(posedge clk_i) disable iff (reset_i)
            packet_blocked_o
            |-> !commit_accepted_o &&
                !register_write_enable_o &&
                !status_write_enable_o;
    endproperty

    property p_commit_is_single_pulse;
        @(posedge clk_i) disable iff (reset_i)
            commit_accepted_o |=> !commit_accepted_o;
    endproperty

    property p_exgpc_commit_captures_aligned_redirect;
        @(posedge clk_i) disable iff (reset_i)
            commit_pc_redirect_enable
            |-> commit_accepted_o &&
                packet_opcode_id_o == TMS20_OP_EXGPC &&
                commit_pc_redirect_bit_address[3:0] == 4'd0;
    endproperty

    property p_pending_redirect_stays_aligned;
        @(posedge clk_i) disable iff (reset_i)
            completion_redirect_q
            |-> completion_redirect_bit_address_q[3:0] == 4'd0;
    endproperty

    property p_shift_commit_has_atomic_register_and_status_writes;
        @(posedge clk_i) disable iff (reset_i)
            commit_accepted_o &&
            (
                packet_opcode_id_o == TMS20_OP_SLA_K ||
                packet_opcode_id_o == TMS20_OP_SLA_R ||
                packet_opcode_id_o == TMS20_OP_SLL_K ||
                packet_opcode_id_o == TMS20_OP_SLL_R ||
                packet_opcode_id_o == TMS20_OP_SRA_K ||
                packet_opcode_id_o == TMS20_OP_SRA_R ||
                packet_opcode_id_o == TMS20_OP_SRL_K ||
                packet_opcode_id_o == TMS20_OP_SRL_R
            )
            |-> register_write_enable_o &&
                status_write_enable_o &&
                !commit_pc_redirect_enable;
    endproperty

    assert property (p_only_supported_packets_commit);
    assert property (p_blocked_packet_cannot_write);
    assert property (p_commit_is_single_pulse);
    assert property (p_exgpc_commit_captures_aligned_redirect);
    assert property (p_pending_redirect_stays_aligned);
    assert property (
        p_shift_commit_has_atomic_register_and_status_writes
    );
`endif

endmodule

`default_nettype wire
