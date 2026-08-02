`default_nettype none

module tms34020_field_offset_address (
    input  logic [31:0] base_address_i,
    input  logic [15:0] signed_offset_i,
    output logic [31:0] effective_address_o
);

    always_comb begin
        effective_address_o = base_address_i +
            {{16{signed_offset_i[15]}}, signed_offset_i};
    end

endmodule

`default_nettype wire
