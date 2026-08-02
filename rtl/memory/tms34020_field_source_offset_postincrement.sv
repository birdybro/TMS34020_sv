`default_nettype none

module tms34020_field_source_offset_postincrement (
    input  logic [4:0]  field_size_encoded_i,
    input  logic [31:0] source_base_i,
    input  logic [15:0] signed_source_offset_i,
    input  logic [31:0] destination_pointer_i,
    output logic [5:0]  field_size_o,
    output logic [31:0] source_effective_address_o,
    output logic [31:0] destination_effective_address_o,
    output logic [31:0] destination_final_pointer_o
);

    always_comb begin
        field_size_o = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size_o = 6'd32;
        end

        source_effective_address_o = source_base_i +
            {{16{signed_source_offset_i[15]}}, signed_source_offset_i};
        destination_effective_address_o = destination_pointer_i;
        destination_final_pointer_o =
            destination_pointer_i + {26'd0, field_size_o};
    end

endmodule

`default_nettype wire
