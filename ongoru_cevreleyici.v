`timescale 1ns / 1ps

`define DEBUG_EN
`define DUMP_EN

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
//`define ENTRY_LEN `TRG_PC_OFFSET + `PC_LEN
`define ENTRY_LEN 100

module ongoru_cevreleyici ();

   reg [`ENTRY_LEN-1:0] br_info[0:`BRANCH_COUNT-1];
   reg [`BRANCH_COUNT * `SIM_LEN - 1:0] mispred_count;

   reg read_en;
   reg [$clog2(`BRANCH_COUNT)-1:0] prog_ptr;
   wire [$clog2(`BRANCH_COUNT)-1:0] next_ptr;
   reg [`ENTRY_LEN-1:0] pipe_emul[1:`EX_STAGE_LOC-1];
   reg [`TKN_LEN-1:0] pipe_preds[1:`EX_STAGE_LOC-1];
   reg [1:`EX_STAGE_LOC-1] preds_valid;

   wire flush_en;
   wire pc_mispred;
   wire taken_mispred;

   wire [`ENTRY_LEN-1:0] curr_br_info;
   wire [`ENTRY_LEN-1:0] next_br_info;
   wire [`PC_LEN-1:0] curr_pc;
   wire [`PC_LEN-1:0] next_pc;

   reg [`PC_LEN-1:0] pc;

   reg fetch_valid;
   reg [`ENTRY_LEN-1:0] fetch_entry;

   assign pc_mispred = pipe_emul[`BR_RESOLVE_LATENCY-1][`PC] != curr_br_info[`TRG_PC] &&
   preds_valid[`BR_RESOLVE_LATENCY];

   assign taken_mispred = pipe_emul[`BR_RESOLVE_LATENCY][`TKN] != pipe_preds[`BR_RESOLVE_LATENCY] &&
   preds_valid[`BR_RESOLVE_LATENCY];

   wire ex_valid = pipe_emul[`BR_RESOLVE_LATENCY][`PC] == curr_pc && (taken_mispred || pc_mispred);

   wire bp_pred;
   wire [31:0] bp_target;

   ongorucu bp (
      .getir_ps(fetch_entry[`PC]),
      .getir_buyruk(fetch_entry[`INST]),
      .getir_gecerli(fetch_valid),
      .yurut_ps(curr_pc),
      .yurut_buyruk(curr_br_info[`INST]),
      .yurut_dallan(curr_br_info[`TKN]),
      .yurut_dallan_ps(curr_br_info[`TRG_PC]),
      .yurut_gecerli(ex_valid),
      .sonuc_dallan(bp_pred),
      .sonuc_dallan_ps(bp_target)
   );

   reg clk;
   reg rstn;

   always begin
      clk = 1;
      #5;
      clk = 0;
      #5;
   end

   integer j;
   always begin
      for (j = 0; j < `BRANCH_COUNT; j = j + 1) begin
         if (br_info[j][`PC] == pc) begin
            fetch_valid = 1;
            fetch_entry = br_info[j];
            j = `BRANCH_COUNT;
         end else begin
            fetch_valid = 0;
            fetch_entry = 0;
         end
      end
      @(posedge clk) #10;
   end

   integer i;
   initial begin
      for (i = 0; i < `BRANCH_COUNT; i = i + 1) begin
         br_info[i] = 0;
      end
      // MEM DOSYASINA DALLANMA BUYRUGU ICIN SIRASIYLA TARGET PC, TAKEN, INSTRUCTION, PC BILGISI YAZILMALIDIR
      $readmemh("br_info.mem", br_info);
      $display("Branch info dump");
      for (i = 0; i < `BRANCH_COUNT; i = i + 1) begin
         $display("br_info[%0d] PC is %0h", i, br_info[i][`PC]);
         $display("br_info[%0d] INSTRUCTION is %h", i, br_info[i][`INST]);
         $display("br_info[%0d] TAKEN is %0h", i, br_info[i][`TKN]);
         $display("br_info[%0d] TARGET PC is %h\n", i, br_info[i][`TRG_PC]);
         $display("br_info[%0d] TARGET PC is %h\n", i, br_info[0]);
      end
      $display("Starting simulation\n");
`ifdef DUMP_EN
      $dumpfile("ongoru_cevreleyici.vcd");
      $dumpvars(0, ongoru_cevreleyici);
`endif
      rstn = 0;
      repeat (10) @(posedge clk) #2;
      rstn = 1;
      repeat (`SIM_LEN * (`BRANCH_COUNT) * `EX_STAGE_LOC) @(posedge clk) #10;
      $display("Simulation finished at %0t ps", $time);
      $display("Running invalid cycle before finishing simulation");
      @(posedge clk) #10;
      $display("Prediction accuracy is %0d/%0d", `SIM_LEN * (`BRANCH_COUNT) - mispred_count, `SIM_LEN * (`BRANCH_COUNT));
      $finish;
   end

   assign next_ptr = (prog_ptr < `BRANCH_COUNT - 1) ? prog_ptr + 1 : 0;
   assign flush_en = ex_valid && preds_valid[`BR_RESOLVE_LATENCY];

   always @(posedge clk) begin
      if (!rstn) begin
         prog_ptr <= 0;
         for (i = 1; i < `EX_STAGE_LOC; i = i + 1) begin
            pipe_emul[i]   <= 0;
            pipe_preds[i]  <= 0;
            preds_valid[i] <= 0;
         end
         mispred_count <= 0;
         pc <= br_info[0][`PC];
      end else begin
         if (read_en) begin
            prog_ptr <= next_ptr;
            pc <= br_info[next_ptr][`PC];
         end else begin
            if (fetch_valid && bp_pred) begin
               pc <= bp_target;
            end else pc <= pc + 4;
         end
         pipe_emul[1]   <= 0;
         preds_valid[1] <= 0;
         for (i = 0; i < `BRANCH_COUNT; i = i + 1) begin
            if (br_info[i][`PC] == pc && fetch_valid) begin
               pipe_emul[1]   <= br_info[i];
               preds_valid[1] <= 1'b1;
            end
         end
         pipe_preds[1] <= bp_pred;
         for (i = 2; i < `EX_STAGE_LOC; i = i + 1) begin
            pipe_emul[i]   <= pipe_emul[i-1];
            pipe_preds[i]  <= pipe_preds[i-1];
            preds_valid[i] <= preds_valid[i-1];
         end
         if (flush_en) begin
            for (i = 1; i < `EX_STAGE_LOC; i = i + 1) begin
               pipe_emul[i]   <= 0;
               pipe_preds[i]  <= 0;
               preds_valid[i] <= 0;
            end
            mispred_count <= mispred_count + 1;
         end
`ifdef DEBUG_EN
         $display("Fetch PC is %0h", pc);
         $display("Last Branch Inst PC is %0h", curr_br_info[`PC]);
         $display("Read en is %0d", read_en);
         $display("Prog ptr is %0d", prog_ptr);
         for (i = 1; i < `EX_STAGE_LOC; i = i + 1) begin
            $display("Pipeline Stage %0d has data %0h", i, pipe_emul[i]);
            $display("Pipeline Stage %0d has prediction %0d", i, pipe_preds[i]);
            $display("Pipeline Stage %0d has valid %0d", i, preds_valid[i]);
         end
`endif
      end
   end

   assign curr_br_info = br_info[prog_ptr];
   assign next_br_info = br_info[next_ptr];
   assign curr_pc = curr_br_info[`PC];
   assign next_pc = next_br_info[`PC];

   always @* begin
      if (flush_en) begin
         read_en = 1;
      end else if (pipe_emul[`BR_RESOLVE_LATENCY][`PC] == curr_pc && preds_valid[`BR_RESOLVE_LATENCY]) begin
         read_en = 1;
      end else begin
         read_en = 0;
      end
   end

endmodule
