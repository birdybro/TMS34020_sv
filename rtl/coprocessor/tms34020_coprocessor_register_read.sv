`default_nettype none

module tms34020_coprocessor_register_read (
    input  logic [15:0] first_word_i,
    input  logic [15:0] extension_word1_i,
    input  logic [15:0] extension_word2_i,
    input  logic        first_extension_aligned_i,
    input  logic [31:0] inbound_word0_i,
    input  logic [31:0] inbound_word1_i,
    output logic        supported_o,
    output logic        legal_o,
    output logic        status_only_o,
    output logic [2:0]  instruction_length_words_o,
    output logic        destination1_file_b_o,
    output logic [3:0]  destination1_index_o,
    output logic        destination2_file_b_o,
    output logic [3:0]  destination2_index_o,
    output logic [2:0]  coprocessor_id_o,
    output logic [20:0] command_o,
    output logic        size_64_o,
    output logic [31:0] lad_command_o,
    output logic [31:0] lad_second_reissue_o,
    output logic        special_function_o,
    output logic [3:0]  bus_status_o,
    output logic        word_select_16_o,
    output logic [1:0]  data_word_count_o,
    output logic        register_write0_enable_o,
    output logic [31:0] register_write0_data_o,
    output logic        register_write1_enable_o,
    output logic [31:0] register_write1_data_o,
    output logic [3:0]  status_nczv_write_mask_o,
    output logic [3:0]  status_nczv_value_o,
    output logic        second_reissue_if_no_page_o,
    output logic [2:0]  visible_states_o
);

    logic packet_family;
    logic register_packet_legal;
    logic [31:0] last_inbound_word;

    always_comb begin
        packet_family =
            (first_word_i & 16'hFFE0) == 16'h0660;
        status_only_o = packet_family && first_word_i == 16'h0660 &&
            extension_word1_i[7:0] == 8'h01;
        size_64_o = !status_only_o && extension_word1_i[7];
        register_packet_legal =
            extension_word1_i[6:5] == 2'd0 &&
            (size_64_o || extension_word1_i[4:0] == 5'd0);
        supported_o = packet_family;
        legal_o = packet_family &&
            (status_only_o || register_packet_legal);
        instruction_length_words_o = packet_family ? 3'd3 : 3'd0;
        destination1_file_b_o = first_word_i[4];
        destination1_index_o = first_word_i[3:0];
        destination2_file_b_o = extension_word1_i[4];
        destination2_index_o = extension_word1_i[3:0];
        coprocessor_id_o = extension_word2_i[15:13];
        command_o = {
            extension_word2_i[12:0], extension_word1_i[15:8]
        };
        lad_command_o = {
            coprocessor_id_o, command_o, size_64_o, 7'd0
        };
        lad_second_reissue_o = lad_command_o | 32'h0000_0040;
        special_function_o = legal_o;
        bus_status_o = 4'd0;
        word_select_16_o = 1'b0;
        data_word_count_o =
            legal_o ? (size_64_o ? 2'd2 : 2'd1) : 2'd0;
        register_write0_enable_o = legal_o && !status_only_o;
        register_write0_data_o = inbound_word0_i;
        register_write1_enable_o =
            legal_o && !status_only_o && size_64_o;
        register_write1_data_o = inbound_word1_i;
        last_inbound_word = size_64_o ? inbound_word1_i : inbound_word0_i;
        status_nczv_write_mask_o = 4'd0;
        status_nczv_value_o = 4'd0;
        if (legal_o && status_only_o) begin
            status_nczv_write_mask_o = 4'b1111;
            status_nczv_value_o = inbound_word0_i[31:28];
        end else if (legal_o) begin
            status_nczv_write_mask_o = 4'b1011;
            status_nczv_value_o = {
                last_inbound_word[31], 1'b0,
                last_inbound_word == 32'd0, 1'b0
            };
        end
        second_reissue_if_no_page_o =
            legal_o && !status_only_o && size_64_o;
        visible_states_o = 3'd0;
        if (legal_o) begin
            if (size_64_o) begin
                visible_states_o =
                    first_extension_aligned_i ? 3'd5 : 3'd6;
            end else begin
                visible_states_o =
                    first_extension_aligned_i ? 3'd4 : 3'd5;
            end
        end
    end

endmodule

`default_nettype wire
