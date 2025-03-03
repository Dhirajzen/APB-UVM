// APB Agent
class apb_agent extends uvm_agent;
  // UVM registration
  `uvm_component_utils(apb_agent)
  
  // Analysis port
  uvm_analysis_port #(apb_transaction) agent_ap;
  
  // Components
  apb_driver    driver;
  apb_sequencer sequencer;
  apb_monitor   monitor;
  
  // Configuration
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Always create monitor
    monitor = apb_monitor::type_id::create("monitor", this);
    
    // Create sequencer and driver if active
    if (is_active == UVM_ACTIVE) begin
      sequencer = apb_sequencer::type_id::create("sequencer", this);
      driver = apb_driver::type_id::create("driver", this);
    end
    
    // Create analysis port
    agent_ap = new("agent_ap", this);
  endfunction
  
  // Connect phase
  function void connect_phase(uvm_phase phase);
    if (is_active == UVM_ACTIVE) begin
      // Connect sequencer to driver
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
    
    // Connect monitor to agent's analysis port
    monitor.item_collected_port.connect(agent_ap);
  endfunction
endclass

// APB Sequencer
class apb_sequencer extends uvm_sequencer #(apb_transaction);
  `uvm_component_utils(apb_sequencer)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass