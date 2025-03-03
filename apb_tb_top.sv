`include "uvm_macros.svh"
import uvm_pkg::*;

// Top-level testbench module
module apb_tb_top;
  // Clock and reset signals
  logic PCLK;
  logic PRESETn;
  
  // Clock generation
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK; // 100MHz clock
  end
  
  // Reset generation
  initial begin
    PRESETn = 0;
    repeat(5) @(posedge PCLK);
    PRESETn = 1;
  end
  
  // Interface instantiation
  apb_if apb_vif(PCLK, PRESETn);
  
  // DUT instantiation
  apb_slave dut (
    .PCLK     (PCLK),
    .PRESETn  (PRESETn),
    .PADDR    (apb_vif.PADDR),
    .PSEL     (apb_vif.PSEL),
    .PENABLE  (apb_vif.PENABLE),
    .PWRITE   (apb_vif.PWRITE),
    .PWDATA   (apb_vif.PWDATA),
    .PRDATA   (apb_vif.PRDATA),
    .PREADY   (apb_vif.PREADY),
    .PSLVERR  (apb_vif.PSLVERR)
  );
  
  // Run test
  initial begin
    // Set interface in config DB
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", apb_vif);
    
    // Enable UVM timing checks
    uvm_config_db#(bit)::set(null, "*", "enable_transaction_viewing", 1);
    
    // Start test - runs the specified test or default test
    run_test();
  end
  
  // Dump waveforms (simulator dependent)
  initial begin
    $dumpfile("apb_test.vcd");
    $dumpvars(0, apb_tb_top);
  end
  
  // Simulation timeout
  initial begin
    #50000; // 50μs timeout
    `uvm_fatal("TIMEOUT", "Simulation timeout. Test did not complete in time.")
  end
endmodule