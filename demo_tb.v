task demo_tb(preDst, EEP_rd_data, posDst); begin
  reg clk, rst_n, start;
  input [13:0] preDst, EEP_rd_data;
  output [13:0] posDst;
 
demo DUT(.EEP_rd_data(EEP_rd_data), .posDst(posDst), .preDst(preDst), .start(start), .clk(clk), .rst_n(rst_n));

	clk = 0;				//initialize all the variable.	
	rst_n = 0;
	start = 0;
	@(posedge (DUT.state == 2'b10));
end

/*
initial
begin
#2 rst_n = 1;
preDst = 14'b11110011;
EEP_rd_data = 14'b11111;
#2 start = 1;
#10 start = 0;
end

initial
begin
#200 
preDst = 14'b1111111;			    //test times positve numbers
EEP_rd_data = 14'b111;
#2 start = 1;  
#10 start = 0;

#200					   //test positve saturation  
preDst = 14'b11111111111;
EEP_rd_data = 14'b01111111111111;
#2 start = 1;  
#10 start = 0;


#200 					   //test nagetive saturation	
preDst = 14'b11000101;
EEP_rd_data = 14'b10000000001100;
#2 start = 1;  
#10 start = 0;

#200						//test when times nagetive numbers	
preDst = 14'b11000111; 				//00c7
EEP_rd_data = 14'b11111111111100;		//3ffc
#2 start = 1;  
#10 start = 0;
end
*/
endtask
