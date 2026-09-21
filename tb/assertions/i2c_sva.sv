`timescale 1ns / 1ps
module i2c_sva (
    input logic clk,
    rst_n,
    start,
    busy,
    done,
    ack_error,
    scl,
    sda,
    scl_drive_low,
    sda_drive_low
);
  default clocking cb @(posedge clk);
  endclocking
  default disable iff (!rst_n); ap_start_busy :
  assert property (start && !busy |=> busy);
  ap_done_pulse :
  assert property (done |=> !done);
  ap_lines_known :
  assert property (!$isunknown({scl, sda, scl_drive_low, sda_drive_low}));
  ap_scl_open_drain :
  assert property (scl_drive_low |-> !scl);
  ap_sda_open_drain :
  assert property (sda_drive_low |-> !sda);
  cp_ack_error :
  cover property (done && ack_error);
  cp_success :
  cover property (done && !ack_error);
endmodule
