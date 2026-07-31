`timescale 1ns/1ps
`default_nettype none

module tms34020_cmpxy (
    input  logic [31:0] source_i,
    input  logic [31:0] destination_i,
    output logic [3:0]  status_nczv_o
);

    always_comb begin
        status_nczv_o[3] =
            source_i[15:0] == destination_i[15:0];
        status_nczv_o[2] =
            (
                destination_i[31:16] - source_i[31:16]
            ) >= 16'h8000;
        status_nczv_o[1] =
            source_i[31:16] == destination_i[31:16];
        status_nczv_o[0] =
            (
                destination_i[15:0] - source_i[15:0]
            ) >= 16'h8000;
    end

endmodule

`default_nettype wire
