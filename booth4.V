`timescale 1 ns / 1 ns
//----------------------------------------------------------------------------------------------//
// multiplicador booth radix 4                        criador: Marlon Sigales                   //
// Nome do Design: booth4                             orientador: Mateus Beck Fonseca           //
// Nome do arquivo: booth4.v                                                                    //
// Funcao : multiplicador utilizando algoritmos de booth base 4                                 //
// data da ultima modificacaoo: 17-08-2015                                                      //
// Versao   date        coder    changes                                                        //
//    0.1  aug 17 2015  Marlon   file created                                                   //
//    0.2  aug 26 2015  Marlon   muxes implementation                                           //
//    0.2  aug 28 2015  Marlon   comentarios de linha                                           //
//    0.2  aug 31 2015  Marlon   comentarios de linha, revisao                                  //
//    0.2  set 02 2015  Raphael  verificacao de erro                                            //
//    0.2  set 02 2015  Marlon   revisao                                                        //
//    1.0  set 10 2015  Marlon   estado final, comentarios e revisoes                           //
//    2.a0 jan 26 2016  Marlon   retirando somador do generate for;                             //
//    2.a1 jan 29 2016  Marlon   gerando soma                                                   //
//    2.a2 feb 03 2016  Marlon   consertando erros que ficaram pra traz, versao quase full      //
//    2.a3 apr 07 2016  Mateus   debug e sugestoes                                              //
//    2.0  apr 08 2016  Marlon   correcoes versao quase full2                                   //
//    2.a5 may 04 2016  Jean     correcoes versao quase full3                                   //
//                                        //
//                                        //
//                                        //
//                                        //
//----------------------------------------------------------------------------------------------//

module booth4(
              A , // entrada multiplicando
              B , // entrada multiplcador
              S   // saida com resultado final
              ); 

//==============parametros========================================================================
parameter TAM = 4;
//-------------portas de entrada------------------------------------------------------------------
input [TAM-1:0] A;
input [TAM-1:0] B;

//-------------portas de saida--------------------------------------------------------------------
output [TAM+TAM-1:0] S;

//-------------fios-------------------------------------------------------------------------------

wire [TAM+TAM-1:0] MD;                   // auxiliar entrada A                            
wire [TAM:0] MR;                         // auxiliar entrada B 
                                         
wire [TAM+TAM-1:0] menosMD;              // auxiliar complemento de 2 de A 
wire [TAM+TAM-1:0] doisMD;               // auxiliar 2*A
wire [TAM+TAM-1:0] menos2MD;             // auxiliar complemento de 2 de 2*A
                                         
wire [TAM-1  :0]   zero;                 // auxiliar zero
wire [TAM-1  :0]   um;                   // auxiliar um   


wire [TAM-1:0]     A;
wire [TAM-1:0]     B;
wire [TAM+TAM-1:0] S;                    // saida, parciais somados 
                                            
reg  [(TAM>>1)-1:0] flag ;  // se bit em questao sao iguais saida tera 0
reg  [(TAM>>1)-1:0] xor1 ;  // selecionarah se eh +-md ou +-2md
reg [TAM+TAM-1:0] beta   [0:(TAM>>1)-1];  // MD ou menosMD
reg [TAM+TAM-1:0] beta0  [0:(TAM>>1)-1];  // doisMD ou menos2MD
reg [TAM+TAM-1:0] beta1  [0:(TAM>>1)-1];  // através de xor1 escolhe 2A ou A
reg [TAM+TAM-1:0] beta2  [0:(TAM>>1)-1];  // através da flag escolhe beta1 e 0
reg [TAM+TAM-1:0] beta3  [0:(TAM>>1)-1];  // desloca beta2
	                                        
wire [TAM+TAM-1:0] Spar   [0:(TAM>>1)];  // somas de parciais
reg  [TAM+TAM-1:0] P      [0:(TAM>>1)-1];  // auxiliar somas parciais TAM/2 numero de somas     	
               
//------------comportamento logico----------------------------------------------------------------
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH fios da operacao HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
  assign zero = {TAM{1'b0}};                     // informacao zeros largura informacao de entrada
  assign um   = {TAM{1'b1}};                     // informacao um's
  
  assign MR = {B, 1'b0};                         // multiplicador  + 'bit lsb do algoritmo booth' 
  assign MD = A[TAM-1] ? {um, A} : {zero, A};    // preenche a informacao com um ou zero
  assign menosMD = ~(MD) + 1;                    // complemento de 2 de MD
  assign doisMD = MD+MD;                         // duas vezes MD
  assign menos2MD = ~(doisMD) + 1;               // comp2 de 2MD
  
  assign S       = Spar[(TAM>>1)];             //saida eh ultima soma de parciais 
  assign Spar[0] = {TAM+TAM{1'b0}};              // informacao zeros, primeira soma   
  
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH algoritmo booth HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
genvar I;
generate        
        for (I=1; I<TAM+1 ; I=I+2) begin: booth      //radix 2, soma TAM/2 vezes; 0, 2, 4,8... 
         always @(*) begin  
				//$display("passagens pelo For I ",I);
                 flag [(I>>1)] = ~(~(MR[I] & MR[I-1] & MR[I+1])&(MR[I] | MR[I-1] | MR[I+1]));//flag de igualdade 
                 xor1 [(I>>1)] = (MR[I] ^ MR[I-1]);             //selecionara se eh +-md ou +-2md
                 beta [(I>>1)] = MR[I+1] ?  menosMD  : MD ;     //calcula paralelamente se eh +-md ou +-2md                     
                 beta0[(I>>1)] = MR[I+1] ?  menos2MD : doisMD ; //calcula paralelamente se eh +-md ou +-2md
                 beta1[(I>>1)] = xor1[I>>1] ? beta[(I>>1)] : beta0[(I>>1)]; //seleciona se eh +-md ou +-2md 
                 beta2[(I>>1)] = flag[I>>1] ? 0 : beta1[(I>>1)] ;           //se todos iguais zera a parcial
                 beta3[(I>>1)] = beta2[I>>1] << (I-1) ;                     //rotaciona i-1 vezes, segundo logica booth modificado, 
                 P  [(I>>1)] = beta3[I>>1];  // atualiza valor da soma parcial no vetor P [1->1],[3->2],[5->3],...[15->8] 

          end   //*/                            
        end
endgenerate // final da geracao de parciais                                       
            //mux <= sel     ? iftrue : iffalse
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH somas parciais HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
genvar J;
        generate //soma as parciais
          for (J=1; J<=(TAM>>1); J=J+1) begin: sums 
				
               assign Spar[J] = Spar[J-1]+P[J-1];                               
               //nomemodulo nomelocal (.parametrolah(parametroaqui)) (conexoes)     
          /*     csadd #(.TAM(TAM+TAM)) sumparciais (// .nomelah (nomeaqui)                                            //bloco no arquivo sumpar
                                       .A           (P[J])            ,
                                       .B           (Spar[J-1])  ,
                                       .S           (Spar[J])    
                                       );  */
                    
          end
        endgenerate
      
endmodule                                                










//--------------------------------------------------------------------------------------//
// somadores parametrizados, full adder half adder      criador: Marlon Sigales         //
// Nome do Design: fulladd, halfadd,csadd 			    orientador: Mateus Beck Fonseca //
// Nome do arquivo: sumpar.v                                                            //
// Funcao : somadores para atender ao multiplicador booth                               //
// data da ultima modificacaoo: 29-01-2016                                              //
// Versao   date        coder    changes                                                //
//    0.1  29 jan 2016  Marlon   file created, design fulladd, half adder               //
//--------------------------------------------------------------------------------------// 

//HHHHHHHHHHHHHHHHHHHHHHHHHH tamanho aqui = 2*tam no booth HHHHHHHHHHHHHHHHHHHHHHHHHHHHH


module csadd(     //--------riple carry adder---------
              A , // entrada somaa
              B , // entrada somab
              S , // saida 
              ); 

//----parameter--
parameter TAM = 16;         
//-------------portas de entrada----------------------
input wire [TAM-1:0]A;
input wire [TAM-1:0]B;
//-------------portas de saida------------------------
output wire [TAM:0]S;
//-------------auxiliar wire--------------------------
wire [TAM : 0] c;    // auxiliar carry
//------------comportamento logico--------------------
      assign S[TAM] = c[TAM];
 
      halfadd sum0 (           // .nomelah (nomeaqui)
                               .A           (A[0]) ,
                               .B           (B[0]) ,
                               .S           (S[0]) ,
                               .Cout        (c[0])
                           );  



       genvar I;
       generate        
        for (I=1; I<TAM ; I=I+1) begin: sums                        
                fulladd sumI (// .nomelÃ¡ (nomeaqui)
                               .A            (A[I])  ,
                               .B            (B[I])  ,
                               .Cin          (c[I-1]),
                               .S            (S[I])  ,
                               .Cout         (c[I])
                           );

                                                    
         end
        endgenerate // final da geracao
endmodule 


















module fulladd( //------full adder-------
              A , 		// entrada somaa
              B ,		// entrada somab
              Cin ,     // Cin
              S ,  		//saida 
              Cout      //carry out

              ); 

//
//-------------portas de entrada---------
input A;
input B;
input Cin;

//-------------portas de saida-----------
output S;
output Cout;

//-------------fios----------------------
wire A;
wire B;
wire S;
wire Cout;
wire Cin;
//------------comportamento logico-------
  
  assign S = (A ^ B ^ Cin) ;                     // saida recebe valor
  assign Cout = (B & Cin) | (A & Cin) | (A & B); //carry out recebe valor

endmodule 















module halfadd(    //-----half adder-----
              A ,  // entrada somaa
              B ,  // entrada somab
              S ,  //saida 
              Cout //carry out

              ); 

//
//-------------portas de entrada-----------------
input A;
input B;

//-------------portas de saida-------------------
output S;
output Cout;

//-------------fios------------------------------
wire A;
wire B;
wire S;
wire Cout;

//------------comportamento logico---------------
 
  assign S = (A ^ B) ;  // saida recebe valor
  assign Cout = (A & B);//carry out recebe valor

endmodule 
