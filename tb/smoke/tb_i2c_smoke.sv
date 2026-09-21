`timescale 1ns / 1ps
module tb_i2c_smoke;
  localparam int CLK_DIV = 2;
  logic clk, rst_n, start;
  logic [6:0] dev_addr;
  logic [7:0] wr_data;
  logic busy, done, ack_error, scl_drive_low, sda_drive_low, scl, sda, slave_sda_drive_low;
  logic [1:0] nack_phase;
  logic [7:0] captured_addr, captured_data;
  logic capture_valid;
  int   checks = 0;
  initial clk = 0;
  always #5 clk = ~clk;
  assign scl = scl_drive_low ? 0 : 1;
  assign sda = (sda_drive_low || slave_sda_drive_low) ? 0 : 1;
  i2c_master_write #(
      .CLK_DIV(CLK_DIV)
  ) dut (
      .clk,
      .rst_n,
      .start,
      .dev_addr,
      .wr_data,
      .busy,
      .done,
      .ack_error,
      .scl_drive_low,
      .sda_drive_low,
      .scl_in(scl),
      .sda_in(sda)
  );
  i2c_slave_model slave (
      .scl,
      .sda,
      .nack_phase,
      .slave_sda_drive_low,
      .captured_addr,
      .captured_data,
      .capture_valid
  );
  i2c_sva sva (
      .clk,
      .rst_n,
      .start,
      .busy,
      .done,
      .ack_error,
      .scl,
      .sda,
      .scl_drive_low,
      .sda_drive_low
  );
  task automatic send(input logic [6:0] addr, input logic [7:0] data, input logic [1:0] nack);
    while (busy) @(posedge clk);
    @(negedge clk);
    dev_addr = addr;
    wr_data = data;
    nack_phase = nack;
    start = 1;
    @(negedge clk);
    start = 0;
    @(posedge done);
    #1;
    if (!capture_valid || captured_addr !== {addr, 1'b0} || captured_data !== data)
      $fatal(
          1,
          "I2C capture mismatch addr=%02h/%02h data=%02h/%02h",
          {
            addr, 1'b0
          },
          captured_addr,
          data,
          captured_data
      );
    if (ack_error !== (nack != 0))
      $fatal(1, "I2C ACK mismatch nack=%0d error=%0b", nack, ack_error);
    checks++;
  endtask
  initial begin
    rst_n = 0;
    start = 0;
    dev_addr = 0;
    wr_data = 0;
    nack_phase = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    send(7'h50, 8'ha5, 0);
    send(7'h2a, 8'h3c, 1);
    send(7'h68, 8'h00, 2);
    $display("I2C_SMOKE_PASS checks=%0d", checks);
    $finish;
  end
endmodule
