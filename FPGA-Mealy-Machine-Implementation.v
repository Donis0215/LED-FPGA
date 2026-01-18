module FSM1 (out, clk, rst, in);

input clk, rst, in;
output out;

reg out;
reg [1:0] State, NextState;

parameter S0 = 2'b00,  S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;

always@(posedge clk or posedge rst)
begin
 if(rst)
  State <= 0;
 else
  State <= NextState;
end

always@(in or State)
begin
 case(State)
 S0: begin
  if(in == 1)
  begin
   NextState = S1;
   out = 1;
  end
  else
  begin
   NextState = S0;
   out = 0;
  end
 end
 S1: begin
  if(in == 1)
  begin
   NextState = S2;
   out = 0;
  end
  else
  begin
   NextState = S1;
   out = 1;
  end
 end
 S2: begin
  if(in == 1)
  begin
   NextState = S0;
   out = 1;
  end
  else
  begin
   NextState = S2;
   out = 0;
  end
 end
 S3: begin
  if(in == 1)
  begin
   NextState = S1;
   out = 1;
  end
  else
  begin
   NextState = S3;
   out = 0;
  end
 end
 endcase
end

endmodule