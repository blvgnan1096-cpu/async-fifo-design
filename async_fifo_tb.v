`include "adv_fifo.v"
`timescale 1ns/1ps

module fifo1_tb;

//==================================================================
// Parameters
//==================================================================
parameter DSIZE = 8;
parameter ASIZE = 4;

//==================================================================
// DUT I/O signals
//==================================================================
reg  [DSIZE-1:0] wdata;
reg               winc, wclk, wrst_n;
reg               rinc, rclk, rrst_n;
reg               power_en;
wire [DSIZE-1:0]  rdata;
wire              wfull, rempty;

//==================================================================
// DUT Instantiation
//==================================================================
fifo1 #(DSIZE, ASIZE) DUT (
  .rdata(rdata),
  .wfull(wfull),
  .rempty(rempty),
  .wdata(wdata),
  .winc(winc), .wclk(wclk), .wrst_n(wrst_n),
  .rinc(rinc), .rclk(rclk), .rrst_n(rrst_n),
  .power_en(power_en)
);

//==================================================================
// Clock Generation
//==================================================================
initial begin
  wclk = 0;
  forever #5 wclk = ~wclk;    // 100 MHz write clock
end

initial begin
  rclk = 0;
  forever #7 rclk = ~rclk;    // ~71 MHz read clock
end

//==================================================================
// Stimulus
//==================================================================
integer i;
initial begin
  // Initialize all signals
  winc = 0; rinc = 0;
  wrst_n = 0; rrst_n = 0;
  power_en = 0;
  wdata = 0;

  // Apply reset
  #10;
  wrst_n = 1;
  rrst_n = 1;
  power_en = 1;   // Enable power
  $display("Time=%0t : Reset Released, Power Enabled", $time);

  //==================================================================
  // Write 6 data words
  //==================================================================
  $display("\n--- Writing 6 Words ---");
  for (i = 0; i < 6; i = i + 1) begin
    @(negedge wclk);
    if (!wfull) begin
      wdata = i + 8'hA0;
      winc = 1;
      $display("Time=%0t : WRITE DATA = %h", $time, wdata);
    end
    @(negedge wclk);
    winc = 0;
  end

  //==================================================================
  // Small delay before reads
  //==================================================================
  #50;

  //==================================================================
// Read 6 data words (fixed version)
//==================================================================
$display("\n--- Reading 6 Words ---");
for (i = 0; i < 6; i = i + 1) begin
  @(negedge rclk);
  if (!rempty) begin
    rinc = 1;
    $display("Time=%0t : READ Triggered (rinc=1)", $time);
  end
  @(negedge rclk);
  rinc = 0;
  @(posedge rclk);
  $display("Time=%0t : READ DATA = %h", $time, rdata);
end

  //==================================================================
  // Test Power Gating
  //==================================================================
  #40;
  power_en = 0;
  $display("\nTime=%0t : Power Disabled (Clock Gating Active)", $time);
  #50;
  power_en = 1;
  $display("Time=%0t : Power Re-enabled", $time);

//==================================================================
  // Write 6 data words
  //==================================================================
  $display("\n--- Writing 6 Words ---");
  for (i = 0; i < 20; i = i + 1) begin
    @(negedge wclk);
    if (!wfull) begin
      wdata = i + 8'hA0;
      winc = 1;
      $display("Time=%0t : WRITE DATA = %h", $time, wdata);
    end
    @(negedge wclk);
    winc = 0;
  end

  //==================================================================
  // Small delay before reads
  //==================================================================
  #50;
  //==================================================================
// Read 6 data words (fixed version)
//==================================================================
$display("\n--- Reading 6 Words ---");
for (i = 0; i < 6; i = i + 1) begin
  @(negedge rclk);
  if (!rempty) begin
    rinc = 1;
    $display("Time=%0t : READ Triggered (rinc=1)", $time);
  end
  @(negedge rclk);
  rinc = 0;
  @(posedge rclk);
  $display("Time=%0t : READ DATA = %h", $time, rdata);
end

  //==================================================================
  // End Simulation
  //==================================================================
  #100;
  $display("\nSimulation Completed at %0t", $time);
  $finish;
end

//==================================================================
// Waveform Dump
//==================================================================
initial begin
  $dumpfile("fifo_simple.vcd");
  $dumpvars(0, fifo1_tb.DUT);
end

endmodule
