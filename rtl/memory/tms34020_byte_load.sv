`default_nettype none

module tms34020_byte_load (
    input  logic [1:0]  address_mode_i,
    input  logic        first_extension_aligned_i,
    input  logic [4:0]  source_offset_i,
    input  logic [31:0] source_word0_i,
    input  logic [31:0] source_word1_i,
    output logic        mode_valid_o,
    output logic [2:0]  source_case_o,
    output logic        reads_word1_o,
    output logic [2:0]  visible_states_o,
    output logic [31:0] raw_byte_o,
    output logic [31:0] result_o,
    output logic        n_o,
    output logic        z_o,
    output logic        v_o
);

    logic [5:0] fixed_field_size;
    logic [2:0] indirect_visible_states;

    tms34020_field_load fixed_byte_load (
        .field_size_encoded_i(5'd8),
        .sign_extend_i(1'b1),
        .bit_offset_i(source_offset_i),
        .word0_i(source_word0_i),
        .word1_i(source_word1_i),
        .field_size_o(fixed_field_size),
        .alignment_case_o(source_case_o),
        .reads_word1_o(reads_word1_o),
        .visible_states_o(indirect_visible_states),
        .raw_field_o(raw_byte_o),
        .result_o(result_o),
        .n_o(n_o),
        .z_o(z_o),
        .v_o(v_o)
    );

    always_comb begin
        mode_valid_o =
            address_mode_i != 2'd3 &&
            fixed_field_size == 6'd8 &&
            reads_word1_o == (source_offset_i > 5'd24);
        unique case (address_mode_i)
            2'd0: visible_states_o = indirect_visible_states;
            2'd1: visible_states_o = indirect_visible_states + 3'd2;
            2'd2: begin
                visible_states_o =
                    indirect_visible_states +
                    (first_extension_aligned_i ? 3'd1 : 3'd2);
            end
            default: visible_states_o = 3'd0;
        endcase
    end

endmodule

`default_nettype wire
