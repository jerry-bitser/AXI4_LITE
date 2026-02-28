module axi_4_lite #(
parameter addr_width=4,
parameter data_width=32
)

(
input clk,
input reset,   		//active low 0:reset 

//write address channel
input [addr_width-1:0] awaddr,
input awaddr_valid,
output reg awready,

//write data channel
input [data_width-1:0] wdata,
input [(data_width/8)-1:0] wstrb,
input wdata_valid,
output reg wready,

//write response
input bready,
output reg [1:0]bdata,
output reg bvalid,

//read address channel
input [addr_width-1:0] araddr,
input araddr_valid,
output reg arready,

//read data channel
input rready,
output reg rvalid,
output reg [data_width-1:0]rdata,
output reg [1:0]rresp
);

reg [data_width-1:0]register[3:0];
reg aen;										//address have arrived and waiting for data (internal flag for slave).
reg [addr_width-1:0]addr_latch;
reg clear_aen;
//during reset the signals of memory(master) will be 0 not from the user(slave).

//write address handshake
always@(posedge clk 	) begin
if(!reset) begin
awready <= 1'b0;
aen     <= 1'b0;
end else begin
if(clear_aen)
aen <= 1'b0;
if(!aen) begin
awready <= 1'b1;
if(awready && awaddr_valid)begin   //handshake 
aen <= 1'b1;
addr_latch <= awaddr;     
awready <= 1'b0;  
end 
end else begin 
awready <= 1'b0;       
end
end 
end
integer i;


//write data handshake + register write
always@(posedge clk) begin
if(!reset) begin
wready <= 1'b0;
bvalid <= 1'b0;
bdata  <= 2'b00;
clear_aen <= 1'b0;
end else begin

if (aen && !wready)
wready <= 1'b1;
if (wready && wdata_valid)begin    //handshake

for(i=0;i<=(data_width/8-1);i=i+1)begin
if(wstrb[i]) begin
case(addr_latch[3:2]) 
2'b00 : register[0][i*8+:8] <= wdata[i*8+:8];
2'b01 : register[1][i*8+:8] <= wdata[i*8+:8];
2'b10 : register[2][i*8+:8] <= wdata[i*8+:8];
2'b11 : register[3][i*8+:8] <= wdata[i*8+:8];
endcase
end
end
wready <= 1'b0;
clear_aen <= 1'b1;
bvalid <= 1'b1;
end if (bvalid && bready)
bvalid <= 1'b0;
end
end



//read address + data handshake
always@(posedge clk) begin
if(!reset)begin
arready <= 1'b0;
rresp <= 2'b00;
rvalid <= 1'b0;
end else begin

if(!rvalid)
arready <= 1'b1;
else 
arready <= 1'b0;

if(arready && araddr_valid) begin
case(araddr[3:2])
2'b00 : rdata <= register[0];
2'b01 : rdata <= register[1];
2'b10 : rdata <= register[2];
2'b11 : rdata <= register[3];
endcase
rvalid <= 1'b1;
end if (rvalid && rready) begin
rvalid <=0;
end
end
end
endmodule
