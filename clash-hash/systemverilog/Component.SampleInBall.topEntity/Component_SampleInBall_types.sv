package Component_SampleInBall_types;
  typedef struct packed {
    logic [63:0] AXI4Stream_sel0;
    logic AXI4Stream_sel1;
    logic AXI4Stream_sel2;
  } AXI4Stream;
  typedef logic  array_of_64_logic [0:63];
  typedef struct packed {
    logic r_Input_sel0;
    AXI4Stream r_Input_sel1;
  } r_Input;
  typedef logic [1:0] array_of_256_logic_vector_2 [0:255];
  typedef struct packed {
    logic r_Output_sel0;
    logic r_Output_sel1;
    logic r_Output_sel2;
    logic r_Output_sel3;
    logic[0:255][1:0] r_Output_sel4;
  } r_Output;
  typedef logic [7:0] array_of_8_logic_vector_8 [0:7];
  typedef logic [0:0] array_of_64_logic_vector_1 [0:63];
  typedef struct packed {
    logic [661:0] Tuple2_sel0;
    r_Output Tuple2_sel1;
  } Tuple2;
  function automatic logic [0:63][0:0] array_of_64_logic_to_lv(array_of_64_logic i);
    for (int n = 0; n < 64; n=n+1)
      array_of_64_logic_to_lv[n] = i[n];
  endfunction
  function automatic array_of_64_logic array_of_64_logic_from_lv(logic [0:63][0:0] i);
    for (int n = 0; n < 64; n=n+1)
      array_of_64_logic_from_lv[n] = i[n];
  endfunction
  function automatic array_of_64_logic array_of_64_logic_cons(logic x,logic  xs [0:62]);
    array_of_64_logic_cons[0] = x;
    array_of_64_logic_cons[1:63] = xs;
  endfunction
  function automatic logic [0:255][1:0] array_of_256_logic_vector_2_to_lv(array_of_256_logic_vector_2 i);
    for (int n = 0; n < 256; n=n+1)
      array_of_256_logic_vector_2_to_lv[n] = i[n];
  endfunction
  function automatic array_of_256_logic_vector_2 array_of_256_logic_vector_2_from_lv(logic [0:255][1:0] i);
    for (int n = 0; n < 256; n=n+1)
      array_of_256_logic_vector_2_from_lv[n] = i[n];
  endfunction
  function automatic array_of_256_logic_vector_2 array_of_256_logic_vector_2_cons(logic [1:0] x,logic [1:0] xs [0:254]);
    array_of_256_logic_vector_2_cons[0] = x;
    array_of_256_logic_vector_2_cons[1:255] = xs;
  endfunction
  function automatic logic [0:7][7:0] array_of_8_logic_vector_8_to_lv(array_of_8_logic_vector_8 i);
    for (int n = 0; n < 8; n=n+1)
      array_of_8_logic_vector_8_to_lv[n] = i[n];
  endfunction
  function automatic array_of_8_logic_vector_8 array_of_8_logic_vector_8_from_lv(logic [0:7][7:0] i);
    for (int n = 0; n < 8; n=n+1)
      array_of_8_logic_vector_8_from_lv[n] = i[n];
  endfunction
  function automatic array_of_8_logic_vector_8 array_of_8_logic_vector_8_cons(logic [7:0] x,logic [7:0] xs [0:6]);
    array_of_8_logic_vector_8_cons[0] = x;
    array_of_8_logic_vector_8_cons[1:7] = xs;
  endfunction
  function automatic logic [0:63][0:0] array_of_64_logic_vector_1_to_lv(array_of_64_logic_vector_1 i);
    for (int n = 0; n < 64; n=n+1)
      array_of_64_logic_vector_1_to_lv[n] = i[n];
  endfunction
  function automatic array_of_64_logic_vector_1 array_of_64_logic_vector_1_from_lv(logic [0:63][0:0] i);
    for (int n = 0; n < 64; n=n+1)
      array_of_64_logic_vector_1_from_lv[n] = i[n];
  endfunction
  function automatic array_of_64_logic_vector_1 array_of_64_logic_vector_1_cons(logic [0:0] x,logic [0:0] xs [0:62]);
    array_of_64_logic_vector_1_cons[0] = x;
    array_of_64_logic_vector_1_cons[1:63] = xs;
  endfunction
endpackage : Component_SampleInBall_types

