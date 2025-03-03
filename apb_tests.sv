// Base Test
class apb_base_test extends uvm_test;
  // UVM registration
  `uvm_component_utils(apb_base_test)
  
  // Components
  apb_env env;
  
  // Constructor
  function new(string name = "apb_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create environment
    env = apb_env::type_id::create("env", this);
    
    // Set verbosity
    uvm_top.set_report_verbosity_level(UVM_MEDIUM);
  endfunction
  
  // End of elaboration phase
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    // Print topology
    uvm_top.print_topology();
  endfunction
  
  // Report phase
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server server = uvm_report_server::get_server();
    
    if (server.get_severity_count(UVM_FATAL) + 
        server.get_severity_count(UVM_ERROR) > 0) begin
      `uvm_info(get_type_name(), "========================================", UVM_LOW)
      `uvm_info(get_type_name(), "========= TEST FAILED  =================", UVM_LOW)
      `uvm_info(get_type_name(), "========================================", UVM_LOW)
    end else begin
      `uvm_info(get_type_name(), "========================================", UVM_LOW)
      `uvm_info(get_type_name(), "========= TEST PASSED  =================", UVM_LOW)
      `uvm_info(get_type_name(), "========================================", UVM_LOW)
    end
  endfunction
endclass

// Write-Read Test
class apb_write_read_test extends apb_base_test;
  `uvm_component_utils(apb_write_read_test)
  
  function new(string name = "apb_write_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Set default sequence
    uvm_config_db#(uvm_object_wrapper)::set(this, 
                                         "env.agent.sequencer.run_phase", 
                                         "default_sequence", 
                                         apb_write_read_sequence::type_id::get());
  endfunction
endclass

// Random Test
class apb_random_test extends apb_base_test;
  `uvm_component_utils(apb_random_test)
  
  function new(string name = "apb_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Set default sequence
    uvm_config_db#(uvm_object_wrapper)::set(this, 
                                         "env.agent.sequencer.run_phase", 
                                         "default_sequence", 
                                         apb_random_sequence::type_id::get());
  endfunction
endclass

// Memory Test
class apb_memory_test extends apb_base_test;
  `uvm_component_utils(apb_memory_test)
  
  function new(string name = "apb_memory_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Set default sequence
    uvm_config_db#(uvm_object_wrapper)::set(this, 
                                         "env.agent.sequencer.run_phase", 
                                         "default_sequence", 
                                         apb_memory_test_sequence::type_id::get());
  endfunction
endclass

// Invalid Address Test
class apb_invalid_addr_test extends apb_base_test;
  `uvm_component_utils(apb_invalid_addr_test)
  
  function new(string name = "apb_invalid_addr_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Set default sequence
    uvm_config_db#(uvm_object_wrapper)::set(this, 
                                         "env.agent.sequencer.run_phase", 
                                         "default_sequence", 
                                         apb_invalid_addr_sequence::type_id::get());
  endfunction
endclass

// Regression Test - runs all sequences in succession
class apb_regression_test extends apb_base_test;
  `uvm_component_utils(apb_regression_test)
  
  function new(string name = "apb_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    apb_write_read_sequence write_read_seq;
    apb_random_sequence random_seq;
    apb_memory_test_sequence mem_seq;
    apb_invalid_addr_sequence invalid_seq;
    
    // Raise objection to keep test alive
    phase.raise_objection(this);
    
    // Create sequences
    write_read_seq = apb_write_read_sequence::type_id::create("write_read_seq");
    random_seq = apb_random_sequence::type_id::create("random_seq");
    mem_seq = apb_memory_test_sequence::type_id::create("mem_seq");
    invalid_seq = apb_invalid_addr_sequence::type_id::create("invalid_seq");
    
    // Run sequences - one after another
    `uvm_info(get_type_name(), "Starting Write-Read Sequence", UVM_LOW)
    write_read_seq.start(env.agent.sequencer);
    
    `uvm_info(get_type_name(), "Starting Memory Test Sequence", UVM_LOW)
    mem_seq.start(env.agent.sequencer);
    
    `uvm_info(get_type_name(), "Starting Random Sequence", UVM_LOW)
    random_seq.start(env.agent.sequencer);
    
    `uvm_info(get_type_name(), "Starting Invalid Address Sequence", UVM_LOW)
    invalid_seq.start(env.agent.sequencer);
    
    `uvm_info(get_type_name(), "All sequences completed", UVM_LOW)
    
    // Drop objection to end test
    phase.drop_objection(this);
  endtask
endclass