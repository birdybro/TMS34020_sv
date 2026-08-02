`default_nettype none

module tms34020_field_load (
    input  logic [4:0]  field_size_encoded_i,
    input  logic        sign_extend_i,
    input  logic [4:0]  bit_offset_i,
    input  logic [31:0] word0_i,
    input  logic [31:0] word1_i,
    output logic [5:0]  field_size_o,
    output logic [2:0]  alignment_case_o,
    output logic        reads_word1_o,
    output logic [2:0]  visible_states_o,
    output logic [31:0] raw_field_o,
    output logic [31:0] result_o,
    output logic        n_o,
    output logic        z_o,
    output logic        v_o
);

    logic [6:0] field_end;
    logic start_byte_aligned;
    logic end_byte_aligned;
    logic [31:0] field_mask;
    logic [63:0] source_window;
    logic [4:0] sign_bit_index;
    logic [5:0] bit_offset_extended;

    always_comb begin
        field_size_o = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size_o = 6'd32;
        end
        field_end = {2'd0, bit_offset_i} + {1'd0, field_size_o};
        start_byte_aligned = bit_offset_i[2:0] == 3'd0;
        end_byte_aligned = field_end[2:0] == 3'd0;
        reads_word1_o = field_end > 7'd32;

        if (!reads_word1_o) begin
            alignment_case_o =
                (start_byte_aligned && end_byte_aligned) ? 3'd1 : 3'd2;
        end else if (start_byte_aligned && end_byte_aligned) begin
            alignment_case_o = 3'd3;
        end else if (start_byte_aligned || end_byte_aligned) begin
            alignment_case_o = 3'd4;
        end else begin
            alignment_case_o = 3'd5;
        end

        visible_states_o =
            ((alignment_case_o <= 3'd2) ? 3'd3 : 3'd4) +
            {2'd0, sign_extend_i};

        field_mask = 32'hFFFF_FFFF;
        if (field_size_o != 6'd32) begin
            field_mask = (32'd1 << field_size_o) - 32'd1;
        end
        source_window = {word1_i, word0_i};
        bit_offset_extended = {1'b0, bit_offset_i};
        raw_field_o =
            source_window[bit_offset_extended +: 32] & field_mask;
        result_o = raw_field_o;
        sign_bit_index = field_size_o[4:0] - 5'd1;
        if (
            sign_extend_i &&
            field_size_o != 6'd32 &&
            raw_field_o[sign_bit_index]
        ) begin
            result_o = raw_field_o | ~field_mask;
        end
        n_o = result_o[31];
        z_o = result_o == 32'd0;
        v_o = 1'b0;
    end

endmodule

`default_nettype wire
