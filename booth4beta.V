//------------------------------------------------------------------------------------------------------------------------------------------------------
// multiplicador booth radix 4                                   criador: Marlon Sigales
// Nome do Design: booth4                                        orientador: Mateus Beck Fonseca    
// Nome do arquivo: booth4.v
// Funcao : multiplicador utilizando algoritmos de booth base 4
// data da ultima modificacaoo: 17-08-2015
// Versao   date        coder    changes
//    0.1  aug 17 2015  Marlon   file created
//    0.2  aug 26 2015  Marlon   muxes implementation
//    0.2  aug 28 2015  Marlon   comentánrios de linha 
//    0.2  aug 31 2015  Marlon   comentánrios de linha, revisao
//    0.2  set 02 2015  Raphael  verificação de erro
//    0.2  set 02 2015  Marlon   revisao 
//    1.0  set 10 2015  Marlon   estado final, comentarios e revisoes
//------------------------------------------------------------------------------------------------------------------------------------------------------
`timescale 1 ns / 1 ns
module booth4beta(
              A ,                                       // entrada multiplicando
              B ,                                       // entrada multiplcador
              S                                         //saida com resultado final/parcial
              ); 

//==============parametros==================================================================================================================================
parameter TAM = 16;

//-------------portas de entrada----------------------------------------------------------------------------------------------------------------------------
input [TAM-1:0] A;
input [TAM-1:0] B;

//-------------portas de saida------------------------------------------------------------------------------------------------------------------------------
output [TAM*2-1:0] S;

//-------------fios-----------------------------------------------------------------------------------------------------------------------------------------
wire [TAM*2-1:0] MD;                             // auxiliar entrada A                            
wire [TAM:0] MR;                             // auxiliar entrada B 

wire [TAM*2-1:0] menosMD;                       // auxiliar complemento de 2 de A 
wire [TAM*2-1:0] doisMD;                        // auxiliar 2*A
wire [TAM*2-1:0] menos2MD;                      // auxiliar complemento de 2 de 2*A

wire [TAM-1  :0] zero;                                  // auxiliar zero
wire [TAM-1  :0] um;                                    // auxiliar um                                                
//wire             c;                                     //auxiliar carry

wire [TAM-1:0] A;
wire [TAM-1:0] B;
wire [TAM*2-1:0] S;
//-------------registradores--------------------------------------------------------------------------------------------------------------------------------

reg [TAM*2-1:0] P;                                      // auxiliar somas parciais        
reg [TAM-1:0]   I;                                      // variavel "for" 

reg             flag;                                   //auxiliar soma zero ou parcial
reg             xor1;                                   //auxiliar xor no mux
reg [TAM*2-1:0] parcial;                                //MD ou menosMD
reg [TAM*2-1:0] parcial0;                               //doisMD ou menos2MD
reg [TAM*2-1:0] parcial1;                               //selecionar 2A ou A
reg [TAM*2-1:0] parcial2;                               //desloca parcial1
reg [TAM*2-1:0] parcial3;                               //fim
                
//------------comportamento logico--------------------------------------------------------------------------------------------------------------------------

  assign zero = {TAM{1'b0}};                            // vetor com zeros  
  assign um   = {TAM{1'b1}};                            // vetor com um's
  
  assign MR = {B, 1'b0};                                // multiplicador  + 'bit lsb do algoritmo booth'          //erro pode estar aqui
  assign MD = A[TAM-1] ? {um, A} : {zero, A};           // preenche o vetor com um ou zero
  assign menosMD = ~(MD) + 1;                           // complemento de 2 de MD
  assign doisMD = MD+MD;                                // duas vezes MD(rotaciona esquerda com sinal(a esquerda nao faz diferença))
  assign menos2MD = ~(doisMD) + 1;                      // comp2 de 2MD

  assign S = P;                                         // saida recebe valor
     
     
  always@(*) begin: soma
        
        P={TAM{1'b0}};                                                        //inicializa P
        
        for (I=1; I<=TAM ; I=I+2)                                             //radix 2, soma 'tam' vezes; 0, 2, 4,8... são tomados como mr i-1
           
          begin: fore 
            flag = (MR[I] & MR[I-1] & MR[I+1])|(~MR[I] & ~MR[I-1] & ~MR[I+1]);//para verificar se os bits em quentão são todos iguais
            xor1 = (MR[I] ^ MR[I-1]);                                         //para verificar se deve ou não haver multiplicação por (+/-)MD
            parcial = MR[I+1] ?  menosMD : MD ;                          //se está na primeira metade é positivo, senão negativo                     
            parcial0= MR[I+1] ?  menos2MD : doisMD ;                     //se não zerou, se não é o numero simples, seleciona entre o dobro ou o complemento do dobro.                  
            parcial1= xor1    ? parcial : parcial0 ;                   //seleciona se é o numero(ou seu segativo) ou o dobro 
            parcial2= flag    ? 0 : parcial1 ;                         //se todos iguais zera a parcial
            parcial3= parcial2 << (I-1) ;                              //rotaciona i-1 vezes, segundo lógica booth modificado, já que i avança de 2 em 2                                                  // não dava pra fazer trocando fio de lugar, pq não era padrao
            P       = P + parcial3;                                    // atualiza valor da soma parcial
                                                    
                                                
                                                //logica multiplcacao booth 4
                
                                                   //MR[i+1] Mr[i] MR[i-1] p(saida)
                                                   //0       0      0      p
                                                   //0       0      1      p+(MD<<2I-1)
                                                   //0       1      0      p+(MD<<2I-1)
                                                   //0       1      1      p+(doisMD<<2I-1)
                                                   //1       0      0      p+(menos2MD<<2I-1)
                                                   //1       0      1      p+(menosMD<<2I-1)
                                                   //1       1      0      p+(menosMD<<2I-1)
                                                   //1       1      1      p 

         end // fore       
     end
     
endmodule 
            //mux <= sel? iftrue : iffalse
            