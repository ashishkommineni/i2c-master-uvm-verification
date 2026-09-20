`timescale 1ns / 1ps
interface i2c_if (
    input logic clk
);
  logic rst_n, start;
  logic [6:0] dev_addr;
  logic [7:0] wr_data;
  logic busy, done, ack_error, scl_drive_low, sda_drive_low, scl, sda;
  logic [1:0] nack_phase;
  logic [7:0] captured_addr, captured_data;
  logic capture_valid;
  clocking drv_cb @(negedge clk);
    output start, dev_addr, wr_data, nack_phase;
    input busy, done, ack_error, captured_addr, captured_data, capture_valid;
  endclocking
endinterface
