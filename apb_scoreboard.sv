// APB Scoreboard
class apb_scoreboard extends uvm_scoreboard;
  // UVM registration
  `uvm_component_utils(apb_scoreboard)
  
  // Analysis export
  uvm_analysis_imp #(apb_transaction, apb_scoreboard) item_collected_export;
  
  // Memory model
  bit [31:0] mem_model[16];
  
  // Metrics
  int num_writes;
  int num_reads;
  int num_errors;
  int num_mismatches;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_export = new("item_collected_export", this);
    
    // Initialize metrics
    num_writes = 0;
    num_reads = 0;
    num_errors = 0;
    num_mismatches = 0;
    
    // Initialize memory model
    foreach (mem_model[i])
      mem_model[i] = 32'h0;
  endfunction
  
  // Write function (called by monitor through analysis port)
  virtual function write(apb_transaction trans);
    // Extract address index (register number)
    bit [3:0] addr_index = trans.addr[5:2];
    
    // Check for invalid address
    if (trans.addr[31:6] != 0) begin
      // Expecting error response
      if (!trans.error) begin
        `uvm_error(get_type_name(), $sformatf("Invalid address access but no error response! Addr=0x%0h", trans.addr))
        num_mismatches++;
      end
      num_errors++;
      return;
    end
    
    if (trans.write) begin
      // Write transaction
      mem_model[addr_index] = trans.data;
      num_writes++;
      `uvm_info(get_type_name(), $sformatf("Write reg[%0d] = 0x%0h", addr_index, trans.data), UVM_MEDIUM)
    end else begin
      // Read transaction
      num_reads++;
      
      // Compare read data with expected value from memory model
      if (mem_model[addr_index] !== trans.read_data) begin
        `uvm_error(get_type_name(), 
          $sformatf("Read data mismatch! Addr=0x%0h, Expected=0x%0h, Actual=0x%0h", 
          trans.addr, mem_model[addr_index], trans.read_data))
        num_mismatches++;
      end else begin
        `uvm_info(get_type_name(), 
          $sformatf("Read match! Addr=0x%0h, Data=0x%0h", 
          trans.addr, trans.read_data), UVM_HIGH)
      end
    end
  endfunction
  
  // Report phase
  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("Scoreboard Report:"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Writes:     %0d", num_writes), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Reads:      %0d", num_reads), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Errors:     %0d", num_errors), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Mismatches: %0d", num_mismatches), UVM_LOW)
    
    if (num_mismatches == 0)
      `uvm_info(get_type_name(), "TEST PASSED", UVM_LOW)
    else
      `uvm_error(get_type_name(), "TEST FAILED")
  endfunction
endclass