// Cache hierarchy unit test: l1dcache (8KB, LUTRAM tags, 0-cycle hits)
// in front of l2dcache (1MB, all-BRAM) with a model of the AXI arbiter
// + SRAM behind it.  Exercises:
//   1. store stream (bss_init pattern): every store completes (misses
//      accepted in the request cycle, subsequent words hit / merge)
//   2. load misses: keyword forward completes the load
//   3. 0-cycle load hit data correctness (WB re-extraction path)
//   4. dirty eviction: L1 writeback reaches the L2 and, via the flush
//      walk, reaches the memory model
//   5. cacop 0x09 flush: L1 dirty data is merged into the L2 before the
//      L2's own writeback to memory (ordering check)
`include "common.sv"

module test_tb;
    import la32_common::*;

    logic clk = 0;
    logic reset = 1;
    always #5 clk = ~clk;

    // ==================== Memory model (arbiter + SRAM behavior) ========
    // One transaction at a time.  Read: addr_ok for one cycle, then
    // burst+1 data beats.  Write: addr_ok + data_ok on completion.
    // RD_LATENCY models the AXI/SRAM read latency (cycles from accept to
    // the first beat) — the full-sim SRAM is ~30 cycles.
    parameter int RD_LATENCY = 24;
    logic [31:0] mem [0:1048575];

    logic        mm_rd_busy;
    logic [31:0] mm_rd_addr;
    logic [1:0]  mm_rd_burst;
    logic [1:0]  rd_beat;
    logic [5:0]  rd_lat;
    logic        mm_wr_busy;
    logic        m_addr_ok, m_data_ok, m_rdata_ok;
    logic [31:0] m_data;

    dbus_req_t  l2_mem_req;
    dbus_resp_t l2_mem_resp;

    always_ff @(posedge clk) begin
        m_addr_ok  <= 1'b0;
        m_rdata_ok <= 1'b0;
        m_data_ok  <= 1'b0;
        m_data     <= 32'd0;
        if (reset) begin
            mm_rd_busy <= 1'b0;
            mm_wr_busy <= 1'b0;
        end else begin
            if (mm_rd_busy) begin
                if (rd_lat > 0)
                    rd_lat <= rd_lat - 1;
                else begin
                    m_rdata_ok <= 1'b1;
                    m_data     <= mem[(mm_rd_addr + (rd_beat << 2)) >> 2];
                    if (rd_beat == mm_rd_burst) begin
                        mm_rd_busy <= 1'b0;
                        rd_beat    <= 2'd0;
                    end else
                        rd_beat <= rd_beat + 2'd1;
                end
            end else if (mm_wr_busy) begin
                m_data_ok <= 1'b1;
                mm_wr_busy <= 1'b0;
            end else if (l2_mem_req.valid && l2_mem_req.strobe == 4'd0) begin
                mm_rd_busy  <= 1'b1;
                mm_rd_addr  <= l2_mem_req.addr;
                mm_rd_burst <= l2_mem_req.burst_len;
                rd_beat     <= 2'd0;
                rd_lat      <= RD_LATENCY[5:0];
                m_addr_ok   <= 1'b1;
            end else if (l2_mem_req.valid && |l2_mem_req.strobe) begin
                mm_wr_busy <= 1'b1;
                m_addr_ok  <= 1'b1;
                for (int b = 0; b < 4; b++)
                    if (l2_mem_req.strobe[b])
                        mem[l2_mem_req.addr >> 2][b*8 +: 8] <=
                            l2_mem_req.data[b*8 +: 8];
            end
        end
    end

    assign l2_mem_resp.addr_ok   = m_addr_ok;
    assign l2_mem_resp.data_ok   = m_data_ok;
    assign l2_mem_resp.rdata_ok  = m_rdata_ok;
    assign l2_mem_resp.data_last = 1'b0;
    assign l2_mem_resp.data      = m_data;
    assign l2_mem_resp.hit       = 1'b0;
    assign l2_mem_resp.hit_way   = 1'b0;

    // ==================== DUT ====================
    dbus_req_t  cpu_req;
    dbus_resp_t cpu_resp;
    dbus_req_t  l1_mem_req;
    dbus_resp_t l1_mem_resp;
    cacop_req_t cacop_req;
    logic       l1_cacop_done, l2_cacop_done;
    logic [31:0] data_wb [0:1][0:3];

    l1dcache #(.NR_SETS(256), .NR_WAYS(2), .NR_WORDS(4)) u_l1 (
        .clk, .reset,
        .cpu_req, .cpu_resp,
        .mem_req(l1_mem_req), .mem_resp(l1_mem_resp),
        .cacop_req, .cacop_done(l1_cacop_done),
        .perf_access(), .perf_hit(), .perf_miss(), .perf_writeback(),
        .perf_fast_load(), .perf_fast_hum(),
        .in_refill(), .data_wb
    );

    cacop_req_t l2_cacop_req;
    assign l2_cacop_req.valid = cacop_req.valid && l1_cacop_done;
    assign l2_cacop_req.code  = cacop_req.code;
    assign l2_cacop_req.addr  = cacop_req.addr;

    l2dcache #(.NR_SETS(16384), .NR_WAYS(4), .NR_WORDS(4)) u_l2 (
        .clk, .reset,
        .cpu_req(l1_mem_req), .cpu_resp(l1_mem_resp),
        .mem_req(l2_mem_req), .mem_resp(l2_mem_resp),
        .cacop_req(l2_cacop_req), .cacop_done(l2_cacop_done)
    );

    // ==================== Driver (LSU-style) ====================
    // Mirrors the real lsu: IDLE re-presents dreq.valid every cycle until
    // the cache accepts (addr_ok / data_ok); a load miss accepted with
    // addr_ok only moves to WAIT (valid dropped) and completes on the
    // keyword's data_ok.
    enum logic { D_IDLE, D_WAIT } dstate;
    logic [31:0] req_addr, req_data, req_strobe;
    logic        req_cacheable, req_pending;
    logic [31:0] got_data;
    logic        got_data_ok;
    logic [31:0] hit_way_r;
    logic [31:0] hit_addr_r;
    logic        hit_pending;

    logic [63:0] cyc;
    logic [63:0] req_start_cyc;
    logic        fail;

    always_ff @(posedge clk) begin
        if (reset) begin
            dstate <= D_IDLE;
            req_pending <= 1'b0;
            cyc <= 0;
            fail <= 1'b0;
            got_data_ok <= 1'b0;
            hit_pending <= 1'b0;
        end else begin
            cyc <= cyc + 1;
            got_data_ok <= 1'b0;
            cpu_req.valid <= 1'b0;
            case (dstate)
                D_IDLE: begin
                    if (req_pending) begin
                        cpu_req.valid   <= 1'b1;
                        cpu_req.addr    <= req_addr;
                        cpu_req.strobe  <= req_strobe;
                        cpu_req.data    <= req_data;
                        cpu_req.cacheable <= req_cacheable;
                        cpu_req.size    <= MSIZE4;
                        cpu_req.burst_len <= 2'd0;
                        if (cpu_resp.addr_ok && !cpu_resp.data_ok)
                            dstate <= D_WAIT;          // load miss accepted
                        else if (cpu_resp.data_ok) begin
                            complete_req();
                        end
                    end
                end
                D_WAIT: begin
                    if (cpu_resp.data_ok)
                        complete_req();
                end
            endcase
            if (hit_pending) begin
                got_data    <= data_wb[hit_way_r][(hit_addr_r >> 2) & 3];
                got_data_ok <= 1'b1;
                hit_pending <= 1'b0;
            end
            if (req_pending && cyc > req_start_cyc + 200000) begin
                $display("[FAIL] test %0d: request %08x stuck (pending %0d cycles)",
                         test_id, req_addr, cyc - req_start_cyc);
                fail <= 1'b1;
                $finish;
            end
            if (req_pending && cyc > 299990 && cyc <= 300000) begin
                $display("[TRACE cyc%0d] L1.st=%0d | m_req.v=%0d a=%08x | m_resp.addr=%0d rdata=%0d | L2.st=%0d pv=%0d cap=%0d p_addr=%08x",
                         cyc, u_l1.state,
                         l1_mem_req.valid, l1_mem_req.addr,
                         l1_mem_resp.addr_ok, l1_mem_resp.rdata_ok,
                         u_l2.state, u_l2.p_valid, u_l2.p_capture_ok, u_l2.p_addr);
            end
        end
    end

    task automatic complete_req();
        if (cpu_resp.hit) begin
            // 0-cycle hit: data completes on data_wb one cycle later;
            // mimic the WB-stage re-extraction
            hit_pending <= 1'b1;
            hit_way_r   <= {31'd0, cpu_resp.hit_way};
            hit_addr_r  <= req_addr;
        end else begin
            got_data    <= cpu_resp.data;
            got_data_ok <= 1'b1;
        end
        req_pending <= 1'b0;
        dstate <= D_IDLE;
    endtask

    int test_id;

    // ==================== Tests ====================
    // Sequential issue protocol: each task waits for the driver to fully
    // complete the request (response + data capture) before returning, so
    // requests never race each other.
    task automatic issue_store(input [31:0] a, input [31:0] d);
        req_pending = 1'b1; req_addr = a; req_data = d;
        req_strobe = 4'hf; req_cacheable = 1'b1;
        req_start_cyc = cyc;
        while (req_pending) @(posedge clk);
        while (!got_data_ok) @(posedge clk);
        @(posedge clk);
    endtask
    task automatic issue_load(input [31:0] a);
        req_pending = 1'b1; req_addr = a; req_data = 32'd0;
        req_strobe = 4'h0; req_cacheable = 1'b1;
        req_start_cyc = cyc;
        while (req_pending) @(posedge clk);
        while (!got_data_ok) @(posedge clk);
        @(posedge clk);
    endtask
    task automatic issue_cacop(input [4:0] code, input [31:0] a);
        // mirror core_top: the request stays valid (cacop in EX) until the
        // L2 completes its own cacop, which is gated on the L1's done.
        cacop_req.valid = 1'b1; cacop_req.code = code; cacop_req.addr = a;
        while (!l2_cacop_done) @(posedge clk);
        cacop_req.valid = 1'b0;
        @(posedge clk);
    endtask

    initial begin
        for (int i = 0; i < 1048576; i++)
            mem[i] = 32'h0;

        repeat (4) @(posedge clk);
        reset = 0;
        repeat (10) @(posedge clk);

        // --- test 1: bss_init store stream across several lines ---
        test_id = 1;
        for (int i = 0; i < 32; i++)
            issue_store(32'h1c7f0000 + i * 4, 32'h0);
        issue_load(32'h1c7f0018);
        if (got_data == 32'h0)
            $display("[PASS] test 1: store stream read-back ok");
        else begin
            $display("[FAIL] test 1: read-back %08x != 0", got_data);
            fail <= 1'b1;
        end

        // --- test 2: load miss keyword + rotated order (word 2) ---
        test_id = 2;
        mem[32'h1c7f0100 >> 2] = 32'h11223344;
        mem[32'h1c7f0104 >> 2] = 32'h55667788;
        mem[32'h1c7f0108 >> 2] = 32'h99aabbcc;
        mem[32'h1c7f010c >> 2] = 32'hddeeff00;
        issue_load(32'h1c7f0108);
        if (got_data == 32'h99aabbcc)
            $display("[PASS] test 2: load miss keyword word-2 ok");
        else begin
            $display("[FAIL] test 2: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 3: 0-cycle load hit (WB re-extraction path) ---
        test_id = 3;
        issue_load(32'h1c7f0104);
        if (got_data == 32'h55667788)
            $display("[PASS] test 3: 0-cycle load hit ok");
        else begin
            $display("[FAIL] test 3: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 4: dirty eviction -> L2 -> memory via flush walk ---
        test_id = 4;
        for (int i = 0; i < 16; i++)
            issue_store(32'h1c000000 + i * 16, 32'hcafe0000 + i);
        repeat (200) @(posedge clk);
        // cacop 0x09 walk with the L2 geometry over the L1's sets
        for (int set = 0; set < 256; set++)
            for (int way = 0; way < 4; way++) begin
                issue_cacop(5'b01001, 32'h1c000000 | (set << 4) | way);
                @(posedge clk);
            end
        repeat (10) @(posedge clk);
        if (mem[32'h1c000020 >> 2] == 32'hcafe0002)
            $display("[PASS] test 4: dirty eviction reached memory");
        else begin
            $display("[FAIL] test 4: mem[0x20]=%08x", mem[32'h1c000020 >> 2]);
            fail <= 1'b1;
        end

        // --- test 5: L1 dirty -> cacop 0x09 -> L2 -> memory ordering ---
        test_id = 5;
        issue_store(32'h1c7f0200, 32'hdeadcafe);
        issue_cacop(5'b01001, 32'h1c7f0200);
        repeat (10) @(posedge clk);
        if (mem[32'h1c7f0200 >> 2] == 32'hdeadcafe)
            $display("[PASS] test 5: cacop flush ordering L1->L2->mem ok");
        else begin
            $display("[FAIL] test 5: mem[0x200]=%08x", mem[32'h1c7f0200 >> 2]);
            fail <= 1'b1;
        end

        // --- test 6: kernel boot replay — stores, 0x01 invalidate walk,
        // then a cold word-0 load (the WELCOME WRITESERIAL pointer) ---
        test_id = 6;
        mem[32'h1c0020a0 >> 2] = 32'h1c00158c;
        for (int i = 0; i < 38; i++)
            issue_store(32'h1c7f0000 + i * 4, 32'h0);
        // 0x01 (index-invalidate) walk over the L1's sets, L2 geometry
        for (int set = 0; set < 256; set++)
            for (int way = 0; way < 4; way++) begin
                issue_cacop(5'b00001, 32'h1c002000 | (set << 4) | way);
                @(posedge clk);
            end
        issue_load(32'h1c0020a0);
        if (got_data == 32'h1c00158c)
            $display("[PASS] test 6: boot replay cold word-0 load ok");
        else begin
            $display("[FAIL] test 6: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 8: word-3 load after a refill (the GOT-entry pattern:
        // the WRITESERIAL pointer lives at word 3 of its line) ---
        test_id = 8;
        mem[32'h1c002350 >> 2] = 32'h11111111;
        mem[32'h1c002354 >> 2] = 32'h22222222;
        mem[32'h1c002358 >> 2] = 32'h33333333;
        mem[32'h1c00235c >> 2] = 32'h1c00158c;
        issue_load(32'h1c00235c);          // cold miss, m_wo = 3
        if (got_data == 32'h1c00158c)
            $display("[PASS] test 8a: word-3 miss keyword ok");
        else begin
            $display("[FAIL] test 8a: got %08x", got_data);
            fail <= 1'b1;
        end
        issue_load(32'h1c00235c);          // 0-cycle hit re-extraction
        if (got_data == 32'h1c00158c)
            $display("[PASS] test 8b: word-3 hit ok");
        else begin
            $display("[FAIL] test 8b: got %08x", got_data);
            fail <= 1'b1;
        end
        issue_load(32'h1c002350);
        if (got_data == 32'h11111111)
            $display("[PASS] test 8c: word-0 hit ok");
        else begin
            $display("[FAIL] test 8c: got %08x", got_data);
            fail <= 1'b1;
        end
        // --- test 7: WELCOME loop replay — the string char loads
        // (0x1c800000+) interleaved with the WRITESERIAL pointer load
        // (0x1c0020a0, set 0x0a) — run enough iterations to force the
        // pointer line through an L1 eviction and refill from the L2 ---
        test_id = 7;
        for (int c = 0; c < 64; c++)
            mem[(32'h1c800000 + c) >> 2] = 32'h20202020 | (c == 63 ? 32'h00000000 : 32'h0);
        issue_load(32'h1c800000);
        for (int it = 0; it < 300; it++) begin
            issue_load(32'h1c0020a0);              // WRITESERIAL pointer
            if (it == 299) begin
                if (got_data == 32'h1c00158c)
                    $display("[PASS] test 7: WELCOME loop pointer stable");
                else begin
                    $display("[FAIL] test 7: got %08x", got_data);
                    fail <= 1'b1;
                end
            end
            issue_load(32'h1c800000 + (it % 64));  // string char
        end

        // --- test 9: pseudorandom access storm over a 2MB window (the
        // cryptonight pattern): interleaved stores/loads through the L1/L2
        // with heavy eviction and writeback; every load must return the
        // last value stored at its address ---
        test_id = 9;
        begin
            logic [31:0] lcg;
            logic [31:0] lastv [0:131071];
            logic [31:0] addr;
            lcg = 32'h12345678;
            for (int i = 0; i < 131072; i++)
                lastv[i] = 32'h0;
            for (int i = 0; i < 60000; i++) begin
                lcg = lcg * 32'h19660d + 32'h3c6ef35f;
                addr = 32'h1c000000 + (lcg & 32'h1ffffc);
                if (lcg[8] == 1'b0) begin
                    issue_store(addr, i);
                    lastv[(addr - 32'h1c000000) >> 2] = i;
                end else begin
                    issue_load(addr);
                    if (got_data !== lastv[(addr - 32'h1c000000) >> 2]) begin
                        $display("[FAIL] test 9: it=%0d addr=%08x got=%08x want=%08x",
                                 i, addr, got_data, lastv[(addr - 32'h1c000000) >> 2]);
                        fail <= 1'b1;
                    end
                end
            end
            if (!fail)
                $display("[PASS] test 9: pseudorandom access storm ok");
        end

        repeat (10) @(posedge clk);
        if (!fail)
            $display("[ALL PASS]");
        else
            $display("[FAILED]");
        $finish;
    end

endmodule
