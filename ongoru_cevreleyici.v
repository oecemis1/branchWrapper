`timescale 1ns / 1ps

`define BRANCH_COUNT 2
`define SIM_LEN 1

`define EX_STAGE_LOC 3
`define BR_RESOLVE_LATENCY `EX_STAGE_LOC - 1

`define PC_LEN 32
`define INST_LEN 32
`define TKN_LEN 1

`define PC_OFFSET 0
`define PC `PC_OFFSET +: `PC_LEN
`define INST_OFFSET `PC_OFFSET + `PC_LEN
`define INST `INST_OFFSET +: `INST_LEN
`define TKN_OFFSET `INST_OFFSET + `INST_LEN
`define TKN `TKN_OFFSET +: `TKN_LEN
`define TRG_PC_OFFSET `TKN_OFFSET + `TKN_LEN
`define TRG_PC `TRG_PC_OFFSET +: `PC_LEN
`define ENTRY_LEN `TRG_PC_OFFSET + `PC_LEN

module ongoru_cevreleyici ();

   reg [`ENTRY_LEN-1:0] br_info[0:`BRANCH_COUNT-1];

   reg read_en;
   reg end_en;
   reg [$clog2(`BRANCH_COUNT)-1:0] prog_ptr;
   wire [$clog2(`BRANCH_COUNT)-1:0] next_ptr;
   reg [`ENTRY_LEN-1:0] pipe_emul[1:`EX_STAGE_LOC-1];

   wire [`ENTRY_LEN-1:0] curr_br_info;
   wire [`ENTRY_LEN-1:0] next_br_info;
   wire [`PC_LEN-1:0] curr_pc;
   wire [`PC_LEN-1:0] next_pc;

   reg [`PC_LEN-1:0] pc;

   reg clk;
   reg rstn;

   always begin
      clk = 1;
      #5;
      clk = 0;
      #5;
   end

   integer i;
   initial begin
      for (i = 0; i < `BRANCH_COUNT; i = i + 1) begin
         br_info[i] = 0;
      end
      $readmemh("br_info.mem", br_info);
      for (i = 0; i < `BRANCH_COUNT; i = i + 1) begin
         $display("br_info[%0d] is %0h", i, br_info[i]);
      end
      $dumpfile("ongoru_cevreleyici.vcd");
      $dumpvars(0, ongoru_cevreleyici);
      rstn = 0;
      repeat (10) @(posedge clk) #2;
      rstn = 1;
      repeat (`SIM_LEN * (`BRANCH_COUNT) * `EX_STAGE_LOC) @(posedge clk) #10;
      if (end_en) $finish;
   end

   assign next_ptr = (prog_ptr < `BRANCH_COUNT - 1) ? prog_ptr + 1 : 0;

   always @(posedge clk) begin
      if (!rstn) begin
         prog_ptr <= 0;
         end_en   <= 0;
         for (i = 1; i < `EX_STAGE_LOC; i = i + 1) begin
            pipe_emul[i] <= 0;
         end
         pc <= br_info[0][`PC];
      end else begin
         if (read_en) begin
            prog_ptr <= next_ptr;
            end_en <= (prog_ptr == `SIM_LEN);
            pc <= br_info[next_ptr][`PC];
         end else begin
            end_en <= 0;
            pc <= pc + 4;
         end
         if (pc != curr_pc) pipe_emul[1] <= 0;
         else pipe_emul[1] <= curr_br_info;
         for (i = 2; i < `EX_STAGE_LOC; i = i + 1) begin
            pipe_emul[i] <= pipe_emul[i-1];
         end
         $display("PC is %0h", pc);
         $display("Curr BR PC is %0h", curr_br_info[`PC]);
         $display("Read en is %0d", read_en);
         $display("Prog ptr is %0d", prog_ptr);
         for (i = 1; i < `EX_STAGE_LOC; i = i + 1) begin
            $display("Pipe emul[%0d] is %0h", i, pipe_emul[i]);
         end
      end
   end

   assign curr_br_info = br_info[prog_ptr];
   assign next_br_info = br_info[next_ptr];
   assign curr_pc = curr_br_info[`PC];
   assign next_pc = next_br_info[`PC];

   always @* begin
      if (pc == next_pc) begin
         read_en = 1;
      end else if (pipe_emul[`BR_RESOLVE_LATENCY][`PC] == curr_pc) begin
         read_en = 1;
      end else begin
         read_en = 0;
      end
   end

endmodule
