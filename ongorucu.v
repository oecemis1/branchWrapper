`timescale 1ns / 1ps

module ongorucu (
    input clk,
    input rst,
    input [31:0] getir_ps,
    input [31:0] getir_buyruk,
    input getir_gecerli,
    input [31:0] yurut_ps,
    input [31:0] yurut_buyruk,
    input yurut_dallan,
    input [31:0] yurut_dallan_ps,
    input yurut_gecerli,
    output sonuc_dallan,
    output [31:0] sonuc_dallan_ps
    );

    assign sonuc_dallan = 1'b1;
    assign sonuc_dallan_ps = 32'd16;

endmodule
