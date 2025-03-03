// Base Sequence
class apb_base_sequence extends uvm_sequence #(apb_transaction);
  `uvm_object_utils(apb_base_sequence)
  
  function new(string name = "apb_base_sequence");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    if (starting_phase != null)
      starting_phase.raise_objection(this);
  endtask
  
  virtual task post_body();
    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask
endclass

// Write-Read Sequence
class apb_write_read_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_write_read_sequence)
  
  rand int num_transactions;
  
  constraint num_trans_c {
    num_transactions inside {[5:20]};
  }
  
  function new(string name = "apb_write_read_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    apb_transaction write_trans, read_trans;
    
    repeat(num_transactions) begin
      // Write transaction
      `uvm_create(write_trans)
      write_trans.write = 1'b1;
      assert(write_trans.randomize());
      `uvm_info(get_type_name(), $sformatf("Generated WRITE transaction: \n%s", write_trans.convert2string()), UVM_HIGH)
      `uvm_send(write_trans)
      
      // Read back same address
      `uvm_create(read_trans)
      read_trans.write = 1'b0;
      read_trans.addr = write_trans.addr;
      assert(read_trans.randomize() with {addr == write_trans.addr; write == 1'b0;});
      `uvm_info(get_type_name(), $sformatf("Generated READ transaction: \n%s", read_trans.convert2string()), UVM_HIGH)
      `uvm_send(read_trans)
    end
  endtask
endclass

// Random Sequence
class apb_random_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_random_sequence)
  
  rand int num_transactions;
  
  constraint num_trans_c {
    num_transactions inside {[20:50]};
  }
  
  function new(string name = "apb_random_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    apb_transaction trans;
    
    repeat(num_transactions) begin
      `uvm_create(trans)
      assert(trans.randomize());
      `uvm_info(get_type_name(), $sformatf("Generated RANDOM transaction: \n%s", trans.convert2string()), UVM_HIGH)
      `uvm_send(trans)
    end
  endtask
endclass

// Invalid Address Sequence
class apb_invalid_addr_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_invalid_addr_sequence)
  
  rand int num_transactions;
  
  constraint num_trans_c {
    num_transactions inside {[5:10]};
  }
  
  function new(string name = "apb_invalid_addr_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    apb_transaction trans;
    
    repeat(num_transactions) begin
      `uvm_create(trans)
      assert(trans.randomize() with {addr[31:6] != 0;});
      `uvm_info(get_type_name(), $sformatf("Generated INVALID ADDRESS transaction: \n%s", trans.convert2string()), UVM_HIGH)
      `uvm_send(trans)
    end
  endtask
endclass

// Memory Test Sequence
class apb_memory_test_sequence extends apb_base_sequence;
  `uvm_object_utils(apb_memory_test_sequence)
  
  function new(string name = "apb_memory_test_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    apb_transaction write_trans, read_trans;
    bit [31:0] test_data[16];
    bit [3:0] addr_index;
    
    // Initialize test data
    for (int i = 0; i < 16; i++)
      test_data[i] = $urandom();
    
    // Write to all registers
    for (int i = 0; i < 16; i++) begin
      addr_index = i[3:0];
      `uvm_create(write_trans)
      write_trans.write = 1'b1;
      write_trans.addr = {26'h0, addr_index, 2'b00};
      write_trans.data = test_data[i];
      `uvm_info(get_type_name(), $sformatf("Writing to register[%0d] = 0x%0h", i, test_data[i]), UVM_MEDIUM)
      `uvm_send(write_trans)
    end
    
    // Read from all registers
    for (int i = 0; i < 16; i++) begin
      addr_index = i[3:0];
      `uvm_create(read_trans)
      read_trans.write = 1'b0;
      read_trans.addr = {26'h0, addr_index, 2'b00};
      `uvm_info(get_type_name(), $sformatf("Reading from register[%0d]", i), UVM_MEDIUM)
      `uvm_send(read_trans)
    end
  endtask
endclass