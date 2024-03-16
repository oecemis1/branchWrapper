`timescale 1ns / 1ps

module ongoru_cevreleyici (
   input  clk_i,
   input  rstn_i,
   output end_o
);

   parameter BRANCH_COUNT = 1;
   parameter SIM_LEN = 1;

   localparam EX_STAGE_LOC = 3;
   localparam BR_RESOLVE_LATENCY = EX_STAGE_LOC - 1;

   localparam PC_LEN = 32;
   localparam INST_LEN = 32;
   localparam TKN_LEN = 1;

   localparam PC_OFFSET = 0;
   localparam INST_OFFSET = PC_OFFSET + PC_LEN;
   localparam TKN_OFFSET = INST_OFFSET + INST_LEN;
   localparam TRG_PC_OFFSET = TKN_OFFSET + TKN_LEN;
   localparam ENTRY_LEN = TRG_PC_OFFSET + PC_LEN;

   reg [ENTRY_LEN-1:0] br_info[0:BRANCH_COUNT-1];

   reg read_en;
   reg end_en;
   reg [($clog2(BRANCH_COUNT)-1):0] prog_ptr;
   reg [ENTRY_LEN-1:0] pipe_emul[1:EX_STAGE_LOC-1];

   wire [ENTRY_LEN-1:0] curr_br_info;
   wire [ENTRY_LEN-1:0] next_br_info;
   wire [PC_LEN-1:0] curr_pc;
   wire [PC_LEN-1:0] next_pc;

   initial begin
   end

   integer i;
   always @(posedge clk_i) begin
      if (!rstn_i) begin
         prog_ptr <= 0;
         end_en   <= 0;
         for (i = 1; i < EX_STAGE_LOC; i = i + 1) begin
            pipe_emul[i] <= 0;
         end
      end else begin
         if (read_en) begin
            prog_ptr <= prog_ptr < BRANCH_COUNT ? prog_ptr + 1 : 0;
            end_en   <= (prog_ptr == SIM_LEN);
         end else begin
            pipe_emul[1] <= curr_br_info;
            for (i = 2; i < BR_RESOLVE_LATENCY; i = i + 1) begin
               pipe_emul[i] <= pipe_emul[i-1];
            end
         end
      end
   end

   assign curr_br_info = br_info[prog_ptr];
   assign next_br_info = br_info[prog_ptr];
   assign curr_pc = curr_br_info[PC_OFFSET+:PC_LEN];
   assign next_pc = next_br_info[PC_OFFSET+:PC_LEN];

   always @* begin

   end

   assign end_o = end_en;

endmodule
