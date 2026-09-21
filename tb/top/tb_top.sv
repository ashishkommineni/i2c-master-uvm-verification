`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import i2c_uvm_pkg::*;
  logic clk = 0;
  always #5ns clk = ~clk;
  i2c_if vif (clk);
  logic slave_sda_drive_low;
  assign vif.scl = vif.scl_drive_low ? 1'b0 : 1'b1;
  assign vif.sda = (vif.sda_drive_low || slave_sda_drive_low) ? 1'b0 : 1'b1;
  i2c_master_write #(
      .CLK_DIV(CLK_DIV)
  ) dut (
      .clk,
      .rst_n(vif.rst_n),
      .start(vif.start),
      .dev_addr(vif.dev_addr),
      .wr_data(vif.wr_data),
      .busy(vif.busy),
      .done(vif.done),
      .ack_error(vif.ack_error),
      .scl_drive_low(vif.scl_drive_low),
      .sda_drive_low(vif.sda_drive_low),
      .scl_in(vif.scl),
      .sda_in(vif.sda)
  );
  i2c_slave_model slave (
      .scl(vif.scl),
      .sda(vif.sda),
      .nack_phase(vif.nack_phase),
      .slave_sda_drive_low,
      .captured_addr(vif.captured_addr),
      .captured_data(vif.captured_data),
      .capture_valid(vif.capture_valid)
  );
  i2c_sva sva (
      .clk,
      .rst_n(vif.rst_n),
      .start(vif.start),
      .busy(vif.busy),
      .done(vif.done),
      .ack_error(vif.ack_error),
      .scl(vif.scl),
      .sda(vif.sda),
      .scl_drive_low(vif.scl_drive_low),
      .sda_drive_low(vif.sda_drive_low)
  );
  initial begin
    vif.rst_n = 0;
    vif.start = 0;
    vif.dev_addr = 0;
    vif.wr_data = 0;
    vif.nack_phase = 0;
    repeat (4) @(posedge clk);
    vif.rst_n = 1;
  end
  initial begin
    uvm_config_db#(virtual i2c_if)::set(null, "uvm_test_top.env.agent.*", "vif", vif);
    run_test("i2c_test");
  end
endmodule
