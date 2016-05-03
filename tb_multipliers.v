/*************************************************************************
 *  Multiplier Testbench                                                 *
 *  This testbench tests multiplications with basics and randons values  *
 *                                                                       *
 *  Developer: Mateus Beck Fonseca 	               Oct, 13, 2009         *
 *             beckfonseca@gmail.com               V. 2                  *
 *  Corrector: Marlon Soares Sigales               Oct, 14, 2015         *
 *             msoaressigales928@gmail.com         V. 3                  *
 *************************************************************************/ 
`timescale 1 ns / 1 ns

module tb_multipliers;

// Defining parameters size 
 localparam integer PERIOD   = 10;   //clk period
  parameter integer 
        TAM       = 4  ,             // bits size of operators 
        NULO      =  0 ,             // zero
        UM_POS    =  1 ,             // one
        UM_NEG    =  2 ,             // minus one
        ALEATORIO =  3 ;             // random numbers
  integer   i ;                      // counter for loop

// Signal declarations
// inputs to the DUT
  reg signed [TAM-1:0] A ;
  reg signed [TAM-1:0] B ;

// outputs to the DUT
  wire [TAM*2-1:0] S;
  
// local internal signals
  reg           clk;
  reg           alow_random ;             // flag to alow or not random multiplication
  reg [45*8:1]  message ;                 // Define a vector with 8 bits for each ASCII character
  reg signed [TAM-1:0]
    value_A, value_B ;        			  // alocation for random values

  wire [TAM*2-1:0]                        //  basic values declarations need 2*TAM for tool calculations
        ZERO    = {(TAM*2-1){1'b0}},              //- zero -> 0...16'b0000 
        POS_ONE = {ZERO,1'b1},              // 1 -> one ... 16'b0001
        NEG_ONE = {(TAM*2){1'b1}};               // -1 -> minus one...16'hFFFF
  reg [TAM*2-1:0] S_test ;                // result of multiplicaton test
  
// Multiplier instantiation
/*booth4*/booth4 #(.TAM(TAM))DUT  (                   // replace "array_m2_vector" by the entity name in VHDL
//  booth4beta #(.TAM(TAM))DUT (
//booth4 DUT  (
  .A  ( A ) ,                             // .name_hear (name_instance)
  .B  ( B ) ,
  .S  ( S ) 
  );
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

// clk generation
  initial clk = 1'b0;
  always #(PERIOD/2) clk = ~clk;
  
// random value generation
  always @(negedge clk)                    // one diferent value ate each negative edge clock 
    begin
      if ( alow_random )
        begin   
         /*random comand sintax:
           min + {$random(seed)}%(max-min+1) or can use $dist_uniform(seed, min, max) */
          value_A <= 16'h1 + {$random}%(16'hFFFF) ; 
          value_B <= 0 + {$random}%(65536) ;
        end
    end
          
// messages display
  always @(message)                        // every check have message
    begin
    $display (" %s ", message);         
    //$stop;                               // this command may cause trouble in Mentor, just coment 
    end

// ------------------------  Apply stimulus  ---------------------------------------------------------------
  initial       //  sempre em um initial eh sequencial e nao acontecem ao mesmo tempo
    begin 
    @(posedge clk) alow_random = 0;	      // disable ramdom values,

    calculate (POS_ONE, POS_ONE);         // 1 x 1 = 1!
    @(negedge clk) check_out (UM_POS);
    repeat(2) @(posedge clk);	
    calculate (NEG_ONE, POS_ONE);         // -1 x 1 = -1!
    @(negedge clk) check_out (UM_NEG);
    repeat(2) @(posedge clk);		
    calculate (POS_ONE, NEG_ONE);         // 1 x -1 = -1!
    @(negedge clk) check_out (UM_NEG);
    repeat(2) @(posedge clk);		
    calculate (NEG_ONE, NEG_ONE);         // -1 x -1 = 1!
    @(negedge clk) check_out (UM_POS);
    repeat(2) @(posedge clk);	 
    calculate (ZERO, POS_ONE);            // 0 x 1 = 0!
    @(negedge clk) check_out (NULO);
    repeat(2) @(posedge clk);	
    calculate (NEG_ONE, ZERO);            // -1 x 0 = 0!
    @(negedge clk) check_out (NULO);
    
    // random values
    @(posedge clk) alow_random = 1;       // alow random values
    for (i=0; i <= 20; i=i+1)
    begin    
      repeat(2) @(posedge clk);           // wait for some clocks 
      calculate (value_A, value_B);       // random inputs
      @(negedge clk) check_out (ALEATORIO);              // compare with tool calculation
    end
  end   // --------------------end stimulus --------------------------------------------------------------------------


// tasks and functions -----------------------------------------------------------------------------------------------
  
  task calculate (input reg  [TAM*2-1:0] a, input reg  [TAM*2-1:0] b); 		// input values to calculate in the DUT
  begin
    A = a;                  // A[TAM] but a[TAM*2] so => truncate!
    B = b;
//  HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
    S_test =  a*b;          // need to improve this, tool don't use complement of two for 16 bits, only 32!!!-------------------
//  HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
  end
  endtask
  
 task check_out ( input integer expected );  // 0=ZERO; 1= ONE; 2= MINUS ONE; 3= random inputs in multiplicator, must compare.
   begin 
    case (expected)

  NULO   :  if (S !== 0 || S !== S_test )
              begin 
				message = "***** Expected zero ***** MULTIPLIER TEST FAILED ";
			   $display(S," | ",S_test);
				end
            else 
              message = " MULTIPLIER ZERO TEST PASSED ";

  UM_POS :  if ( S !== 1 || S !== S_test ) begin
              message = "***** Expected  one ****** MULTIPLIER TEST FAILED ";
			  $display(S," | ",S_test);
			  end
            else 
              message = " MULTIPLIER ONE TEST PASSED ";

  UM_NEG  : if ( S !== {(TAM*2){1'b1}} || S !== S_test ) begin
              message = "***** Expected minus one ***** MULTIPLIER TEST FAILED";
			   $display(S," | ",S_test);
			   end
            else
              message = " MULTIPLIER MINUS ONE TEST PASSED ";

  ALEATORIO : if ( S !== S_test ) begin
                message = "***** RANDOM NUMBERS ***** TEST FAILED ";
				 $display(S," | ",S_test);
				 end
              else  
                message = " MULTIPLIER RANDOM TEST PASSED ";
  
  default: message = " MULTIPLIER BASIC TEST PASSED ";

    endcase
   end
 endtask


endmodule

