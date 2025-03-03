// APB Environment
class apb_env extends uvm_env;
  // UVM registration
  `uvm_component_utils(apb_env)
  
  // Components
  apb_agent     agent;
  apb_scoreboard scoreboard;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create components
    agent = apb_agent::type_id::create("agent", this);
    scoreboard = apb_scoreboard::type_id::create("scoreboard", this);
  endfunction
  
  // Connect phase
  function void connect_phase(uvm_phase phase);
    // Connect agent's analysis port to scoreboard
    agent.agent_ap.connect(scoreboard.item_collected_export);
  endfunction
endclass