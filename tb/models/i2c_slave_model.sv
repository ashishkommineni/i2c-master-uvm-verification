`timescale 1ns / 1ps
module i2c_slave_model (
    input logic scl,
    input logic sda,
    input logic [1:0] nack_phase,
    output logic slave_sda_drive_low,
    output logic [7:0] captured_addr,
    captured_data,
    output logic capture_valid
);
  initial begin
    slave_sda_drive_low = 0;
    captured_addr = 0;
    captured_data = 0;
    capture_valid = 0;
    forever begin
      @(negedge sda);
      if (scl === 1'b1) begin
        capture_valid = 0;
        captured_addr = 0;
        captured_data = 0;
        for (int i = 7; i >= 0; i--) begin
          @(posedge scl);
          captured_addr[i] = sda;
        end
        @(negedge scl);
        slave_sda_drive_low = (nack_phase != 1);
        @(posedge scl);
        @(negedge scl);
        slave_sda_drive_low = 0;
        for (int i = 7; i >= 0; i--) begin
          @(posedge scl);
          captured_data[i] = sda;
        end
        @(negedge scl);
        slave_sda_drive_low = (nack_phase != 2);
        @(posedge scl);
        @(negedge scl);
        slave_sda_drive_low = 0;
        @(posedge sda);
        if (scl === 1'b1) capture_valid = 1;
      end
    end
  end
endmodule
