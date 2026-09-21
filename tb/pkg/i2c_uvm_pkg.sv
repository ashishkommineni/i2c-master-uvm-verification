`timescale 1ns / 1ps
package i2c_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  localparam int CLK_DIV = 4;
  class i2c_item extends uvm_sequence_item;
    rand bit [6:0] addr;
    rand bit [7:0] data;
    rand bit [1:0] nack_phase;
    bit ack_error;
    bit [7:0] observed_addr, observed_data;
    constraint c_addr {addr inside {[8 : 119]};}
    constraint c_nack {
      nack_phase dist {
        0 := 8,
        1 := 1,
        2 := 1
      };
    }
    `uvm_object_utils_begin(i2c_item)
      `uvm_field_int(addr, UVM_HEX)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(nack_phase, UVM_DEC)
      `uvm_field_int(ack_error, UVM_DEFAULT)
      `uvm_field_int(observed_addr, UVM_HEX)
      `uvm_field_int(observed_data, UVM_HEX)
    `uvm_object_utils_end
    function new(string n = "i2c_item");
      super.new(n);
    endfunction
  endclass
  class i2c_sequencer extends uvm_sequencer #(i2c_item);
    `uvm_component_utils(i2c_sequencer)
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
  endclass
  class i2c_driver extends uvm_driver #(i2c_item);
    `uvm_component_utils(i2c_driver)
    virtual i2c_if vif;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "i2c_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      vif.drv_cb.start <= 0;
      vif.drv_cb.dev_addr <= 0;
      vif.drv_cb.wr_data <= 0;
      vif.drv_cb.nack_phase <= 0;
      wait (vif.rst_n === 1);
      forever begin
        seq_item_port.get_next_item(req);
        while (vif.busy) @(vif.drv_cb);
        vif.drv_cb.dev_addr <= req.addr;
        vif.drv_cb.wr_data <= req.data;
        vif.drv_cb.nack_phase <= req.nack_phase;
        vif.drv_cb.start <= 1;
        @(vif.drv_cb);
        vif.drv_cb.start <= 0;
        wait (vif.done);
        seq_item_port.item_done();
      end
    endtask
  endclass
  class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)
    virtual i2c_if vif;
    uvm_analysis_port #(i2c_item) ap;
    function new(string n, uvm_component p);
      super.new(n, p);
      ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "i2c_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      i2c_item tr;
      wait (vif.rst_n === 1);
      forever begin
        @(posedge vif.clk iff (vif.start && !vif.busy));
        tr = i2c_item::type_id::create("tr");
        tr.addr = vif.dev_addr;
        tr.data = vif.wr_data;
        tr.nack_phase = vif.nack_phase;
        @(posedge vif.done);
        #1ps;
        tr.ack_error = vif.ack_error;
        tr.observed_addr = vif.captured_addr;
        tr.observed_data = vif.captured_data;
        ap.write(tr);
      end
    endtask
  endclass
  class i2c_agent extends uvm_agent;
    `uvm_component_utils(i2c_agent)
    i2c_sequencer sqr;
    i2c_driver drv;
    i2c_monitor mon;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      sqr = i2c_sequencer::type_id::create("sqr", this);
      drv = i2c_driver::type_id::create("drv", this);
      mon = i2c_monitor::type_id::create("mon", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass
  class i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_scoreboard)
    uvm_analysis_imp #(i2c_item, i2c_scoreboard) analysis_export;
    int checked;
    function new(string n, uvm_component p);
      super.new(n, p);
      analysis_export = new("analysis_export", this);
    endfunction
    function void write(i2c_item tr);
      checked++;
      if (tr.observed_addr !== {tr.addr, 1'b0})
        `uvm_error("ADDR", $sformatf(
                   "expected=%02h observed=%02h", {tr.addr, 1'b0}, tr.observed_addr))
      if (tr.observed_data !== tr.data)
        `uvm_error("DATA", $sformatf("expected=%02h observed=%02h", tr.data, tr.observed_data))
      if (tr.ack_error !== (tr.nack_phase != 0))
        `uvm_error("ACK", "ack_error did not match injected NACK")
    endfunction
    function void check_phase(uvm_phase phase);
      if (checked == 0) `uvm_error("NO_TRAFFIC", "No I2C transactions reached the scoreboard")
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("I2C_SUMMARY", $sformatf("Checked %0d writes", checked), UVM_LOW)
    endfunction
  endclass
  class i2c_coverage extends uvm_subscriber #(i2c_item);
    `uvm_component_utils(i2c_coverage)
    i2c_item tr;
    covergroup cg;
      cp_addr: coverpoint tr.addr {
        bins legal_low = {[8 : 31]};
        bins legal_mid = {[32 : 95]};
        bins legal_high = {[96 : 119]};
        illegal_bins reserved = {[0 : 7], [120 : 127]};
      }
      cp_data: coverpoint tr.data {
        bins zero = {0}; bins ones = {'1}; bins alt[] = {8'h55, 8'haa}; bins other = default;
      }
      cp_nack: coverpoint tr.nack_phase {bins ack = {0}; bins address = {1}; bins data = {2};}
      cx: cross cp_data, cp_nack;
    endgroup
    function new(string n, uvm_component p);
      super.new(n, p);
      cg = new();
    endfunction
    function void write(i2c_item t);
      tr = t;
      cg.sample();
    endfunction
  endclass
  class i2c_env extends uvm_env;
    `uvm_component_utils(i2c_env)
    i2c_agent agent;
    i2c_scoreboard sb;
    i2c_coverage cov;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      agent = i2c_agent::type_id::create("agent", this);
      sb = i2c_scoreboard::type_id::create("sb", this);
      cov = i2c_coverage::type_id::create("cov", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      agent.mon.ap.connect(sb.analysis_export);
      agent.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass
  class i2c_sequence extends uvm_sequence #(i2c_item);
    `uvm_object_utils(i2c_sequence)
    function new(string n = "i2c_sequence");
      super.new(n);
    endfunction
    task body();
      for (int n = 0; n < 3; n++) begin
        req = i2c_item::type_id::create("directed");
        start_item(req);
        req.addr = 7'h50 + n;
        req.data = 8'h55 ^ (n * 8'hff);
        req.nack_phase = n;
        finish_item(req);
      end
      repeat (40) begin
        req = i2c_item::type_id::create("random");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "randomization failed")
        finish_item(req);
      end
    endtask
  endclass
  class i2c_test extends uvm_test;
    `uvm_component_utils(i2c_test)
    i2c_env env;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      env = i2c_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      i2c_sequence seq;
      phase.raise_objection(this);
      seq = i2c_sequence::type_id::create("seq");
      seq.start(env.agent.sqr);
      repeat (8) @(posedge env.agent.mon.vif.clk);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
