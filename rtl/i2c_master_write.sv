`timescale 1ns / 1ps

module i2c_master_write #(
    parameter  int unsigned CLK_DIV = 4,
    localparam int unsigned DIV_W   = $clog2(CLK_DIV)
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    input  logic [6:0] dev_addr,
    input  logic [7:0] wr_data,
    output logic       busy,
    output logic       done,
    output logic       ack_error,
    output logic       scl_drive_low,
    output logic       sda_drive_low,
    input  logic       scl_in,
    input  logic       sda_in
);
  initial if (CLK_DIV < 2) $fatal(1, "CLK_DIV must be at least 2");
  localparam logic [DIV_W-1:0] LAST_DIV = DIV_W'(CLK_DIV - 1);
  typedef enum logic [3:0] {
    IDLE,
    START_A,
    START_B,
    BIT_LOW,
    BIT_HIGH,
    ACK_LOW,
    ACK_HIGH,
    STOP_LOW,
    STOP_HIGH
  } state_t;
  state_t state_q;
  logic [DIV_W-1:0] div_q;
  logic [7:0] tx_byte_q;
  logic [2:0] bit_q;
  logic phase_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= IDLE;
      div_q <= '0;
      tx_byte_q <= '0;
      bit_q <= '0;
      phase_q <= 0;
      busy <= 0;
      done <= 0;
      ack_error <= 0;
      scl_drive_low <= 0;
      sda_drive_low <= 0;
    end else begin
      done <= 0;
      if (state_q == IDLE) begin
        div_q <= '0;
        busy <= 0;
        scl_drive_low <= 0;
        sda_drive_low <= 0;
        if (start) begin
          busy <= 1;
          ack_error <= 0;
          tx_byte_q <= {dev_addr, 1'b0};
          phase_q <= 0;
          state_q <= START_A;
        end
      end else if (div_q == LAST_DIV) begin
        div_q <= '0;
        case (state_q)
          START_A: begin
            sda_drive_low <= 1;
            scl_drive_low <= 0;
            state_q <= START_B;
          end
          START_B: begin
            scl_drive_low <= 1;
            bit_q <= 3'd7;
            sda_drive_low <= ~tx_byte_q[7];
            state_q <= BIT_LOW;
          end
          BIT_LOW: begin
            scl_drive_low <= 0;
            state_q <= BIT_HIGH;
          end
          BIT_HIGH:
          if (scl_in) begin
            scl_drive_low <= 1;
            if (bit_q == 0) begin
              sda_drive_low <= 0;
              state_q <= ACK_LOW;
            end else begin
              bit_q <= bit_q - 1'b1;
              sda_drive_low <= ~tx_byte_q[bit_q-1'b1];
              state_q <= BIT_LOW;
            end
          end
          ACK_LOW: begin
            scl_drive_low <= 0;
            state_q <= ACK_HIGH;
          end
          ACK_HIGH:
          if (scl_in) begin
            ack_error <= ack_error | sda_in;
            scl_drive_low <= 1;
            if (!phase_q) begin
              phase_q <= 1;
              tx_byte_q <= wr_data;
              bit_q <= 3'd7;
              sda_drive_low <= ~wr_data[7];
              state_q <= BIT_LOW;
            end else begin
              sda_drive_low <= 1;
              state_q <= STOP_LOW;
            end
          end
          STOP_LOW: begin
            scl_drive_low <= 0;
            state_q <= STOP_HIGH;
          end
          STOP_HIGH:
          if (scl_in) begin
            sda_drive_low <= 0;
            busy <= 0;
            done <= 1;
            state_q <= IDLE;
          end
          default: state_q <= IDLE;
        endcase
      end else div_q <= div_q + 1'b1;
    end
  end
endmodule
