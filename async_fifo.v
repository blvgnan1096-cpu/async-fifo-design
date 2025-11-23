module fifo1 #(parameter DSIZE = 8, parameter ASIZE = 4)
(
    output [DSIZE-1:0] rdata,
    output             wfull,
    output             rempty,
    input  [DSIZE-1:0] wdata,
    input              winc, wclk, wrst_n,
    input              rinc, rclk, rrst_n,
    input              power_en
);

    // Internal wires
    wire [ASIZE-1:0] waddr, raddr;
    wire [ASIZE:0]   wptr, rptr, wq2_rptr, rq2_wptr;
    wire wclk_gated, rclk_gated;

    // Clock gating (simple)
    assign wclk_gated = wclk & power_en;
    assign rclk_gated = rclk & power_en;

    // Synchronizers
    sync_r2w #(ASIZE) sync_r2w_inst (
        .wq2_rptr(wq2_rptr),
        .rptr(rptr),
        .wclk(wclk_gated),
        .wrst_n(wrst_n)
    );

    sync_w2r #(ASIZE) sync_w2r_inst (
        .rq2_wptr(rq2_wptr),
        .wptr(wptr),
        .rclk(rclk_gated),
        .rrst_n(rrst_n)
    );

    // FIFO Memory
    fifomem #(DSIZE, ASIZE) fifomem_inst (
        .rdata(rdata),
        .wdata(wdata),
        .waddr(waddr),
        .raddr(raddr),
        .wclken(winc),
        .wfull(wfull),
        .wclk(wclk_gated)
    );

    // Empty and Full logic
    rptr_empty #(ASIZE) rptr_empty_inst (
        .rempty(rempty),
        .raddr(raddr),
        .rptr(rptr),
        .rq2_wptr(rq2_wptr),
        .rinc(rinc),
        .rclk(rclk_gated),
        .rrst_n(rrst_n)
    );

    wptr_full #(ASIZE) wptr_full_inst (
        .wfull(wfull),
        .waddr(waddr),
        .wptr(wptr),
        .wq2_rptr(wq2_rptr),
        .winc(winc),
        .wclk(wclk_gated),
        .wrst_n(wrst_n)
    );

endmodule


module fifomem #(parameter DATASIZE = 8, parameter ADDRSIZE = 4)
(
    output [DATASIZE-1:0] rdata,
    input  [DATASIZE-1:0] wdata,
    input  [ADDRSIZE-1:0] waddr, raddr,
    input                 wclken, wfull, wclk
);

    localparam DEPTH = 1 << ADDRSIZE;
    reg [DATASIZE-1:0] mem [0:DEPTH-1];

    assign rdata = mem[raddr];   // Combinational read

    always @(posedge wclk) begin
        if (wclken && !wfull)
            mem[waddr] <= wdata;
    end

endmodule


module sync_r2w #(parameter ADDRSIZE = 4)
(
    output reg [ADDRSIZE:0] wq2_rptr,
    input      [ADDRSIZE:0] rptr,
    input                   wclk, wrst_n
);

    reg [ADDRSIZE:0] wq1_rptr;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            {wq2_rptr, wq1_rptr} <= 0;
        else
            {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
    end
endmodule


module sync_w2r #(parameter ADDRSIZE = 4)
(
    output reg [ADDRSIZE:0] rq2_wptr,
    input      [ADDRSIZE:0] wptr,
    input                   rclk, rrst_n
);

    reg [ADDRSIZE:0] rq1_wptr;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            {rq2_wptr, rq1_wptr} <= 0;
        else
            {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
    end
endmodule


module rptr_empty #(parameter ADDRSIZE = 4)
(
    output reg                 rempty,
    output     [ADDRSIZE-1:0]  raddr,
    output reg [ADDRSIZE:0]    rptr,
    input      [ADDRSIZE:0]    rq2_wptr,
    input                      rinc, rclk, rrst_n
);

    reg [ADDRSIZE:0] rbin;
    wire [ADDRSIZE:0] rgraynext, rbinnext;

    assign raddr    = rbin[ADDRSIZE-1:0];
    assign rbinnext = rbin + (rinc & ~rempty);
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;

    wire rempty_val = (rgraynext == rq2_wptr);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            {rbin, rptr} <= 0;
            rempty <= 1'b1;
        end else begin
            {rbin, rptr} <= {rbinnext, rgraynext};
            rempty <= rempty_val;
        end
    end
endmodule


module wptr_full #(parameter ADDRSIZE = 4)
(
    output reg                 wfull,
    output     [ADDRSIZE-1:0]  waddr,
    output reg [ADDRSIZE:0]    wptr,
    input      [ADDRSIZE:0]    wq2_rptr,
    input                      winc, wclk, wrst_n
);

    reg [ADDRSIZE:0] wbin;
    wire [ADDRSIZE:0] wgraynext, wbinnext;

    assign waddr    = wbin[ADDRSIZE-1:0];
    assign wbinnext = wbin + (winc & ~wfull);
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    wire wfull_val =
        (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],
                        wq2_rptr[ADDRSIZE-2:0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            {wbin, wptr} <= 0;
            wfull <= 1'b0;
        end else begin
            {wbin, wptr} <= {wbinnext, wgraynext};
            wfull <= wfull_val;
        end
    end

endmodule
 
