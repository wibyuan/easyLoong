// Cache hierarchy unit test: l1dcache (8KB-class 0-cycle fast-path overlay,
// pass-through + word-sector fills) in front of l2dcache (1MB, all-BRAM)
// with a model of the AXI arbiter + SRAM behind it.  Exercises:
//   1. store stream + read-back (0-cycle hits, word fills)
//   2. cold load miss: keyword forward completes the load (L2 refill)
//   3. 0-cycle load hit data correctness (WB re-extraction path)
//   4. per-word sector fills: words of one line filled independently
//   5. partial-byte store: NOT filled into the L1 (read-back via the L2)
//   6. dirty eviction: hammer one L1 set; read-backs hit the L2
//   7. cacop 0x09 flush ordering: L1 dirty -> L2 -> memory
//   8. cacop 0x01 index invalidate (no writeback)
//   9. hit-under-miss: a store miss refilling at the L2 while other lines
//      are still served 0-cycle by the L1
//  10. store-then-load same word: read-back during the L2's refill
//  11. uncacheable passthrough (no fill)
//  12. pseudorandom 2MB storm + final flush walk + full memory compare
`include "common.sv"

module test_tb;
    import la32_common::*;

    logic clk = 0;
    logic reset = 1;
    always #5 clk = ~clk;

    // ==================== Memory model (arbiter + SRAM behavior) ========
    // One transaction at a time.  Read: addr_ok for one cycle, then
    // burst+1 data beats after RD_LATENCY.  Write: addr_ok with the first
    // word, then the burst's remaining beats one per (gap,data) pair,
    // sampling the request's data per beat (the real arbiter's
    // W_BURST_DATA presents dreq.data per beat while the L2's writeback
    // counter advances per addr_ok).
    parameter int RD_LATENCY = 24;
    // Memory model covers 0x1c000000..0x1f0fffff (64MB window), indexed
    // by (addr - 0x1c000000) >> 2.
    logic [31:0] mem [0:16777215];

    logic        mm_rd_busy;
    logic [31:0] mm_rd_addr;
    logic [1:0]  mm_rd_burst;
    logic [1:0]  rd_beat;
    logic [5:0]  rd_lat;
    logic        mm_wr_busy;
    logic [31:0] mm_wr_addr;
    logic [1:0]  mm_wr_burst;
    logic [1:0]  wr_beat;
    logic        wr_gap;
    logic        m_addr_ok, m_data_ok, m_rdata_ok;
    logic [31:0] m_data;

    dbus_req_t  l2_mem_req;
    dbus_resp_t l2_mem_resp;

    // addr_ok is COMBINATIONAL (like the real arbiter's r/w_dresp_addr_ok):
    // asserted in the cycle the transaction is accepted and in each beat
    // cycle of a write burst.  A registered addr_ok would lag the L2's
    // wb_cnt by one cycle, and each burst beat would sample the previous
    // word's data (the last word of a writeback lost).
    always_comb begin
        m_addr_ok = 1'b0;
        if (mm_wr_busy) begin
            if (!wr_gap && wr_beat != mm_wr_burst)
                m_addr_ok = 1'b1;
        end else if (!mm_rd_busy && l2_mem_req.valid) begin
            m_addr_ok = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
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
                    m_data     <= mem[(mm_rd_addr + (rd_beat << 2) - 32'h1c000000) >> 2];
                    if (rd_beat == mm_rd_burst) begin
                        mm_rd_busy <= 1'b0;
                        rd_beat    <= 2'd0;
                    end else
                        rd_beat <= rd_beat + 2'd1;
                end
            end else if (mm_wr_busy) begin
                if (wr_gap) begin
                    wr_gap <= 1'b0;
                end else if (wr_beat == mm_wr_burst) begin
                    m_data_ok  <= 1'b1;
                    mm_wr_busy <= 1'b0;
                end else begin
                    wr_beat <= wr_beat + 2'd1;
                    wr_gap  <= (wr_beat + 2'd1 != mm_wr_burst);
                    // Beat k writes word k (base + k*4); the NBA writes
                    // sample wr_beat's pre-edge value, hence the +1.
                    for (int b = 0; b < 4; b++)
                        if (l2_mem_req.strobe[b])
                            mem[(mm_wr_addr + ((wr_beat + 2'd1) << 2) - 32'h1c000000) >> 2][b*8 +: 8] <=
                                l2_mem_req.data[b*8 +: 8];
                end
            end else if (l2_mem_req.valid) begin
                if (l2_mem_req.strobe == 4'd0) begin
                    mm_rd_busy  <= 1'b1;
                    mm_rd_addr  <= l2_mem_req.addr;
                    mm_rd_burst <= l2_mem_req.burst_len;
                    rd_beat     <= 2'd0;
                    rd_lat      <= RD_LATENCY[5:0];
                end else begin
                    mm_wr_busy  <= 1'b1;
                    mm_wr_addr  <= l2_mem_req.addr;
                    mm_wr_burst <= l2_mem_req.burst_len;
                    wr_beat     <= 2'd0;
                    wr_gap      <= l2_mem_req.burst_len != 2'd0;
                    for (int b = 0; b < 4; b++)
                        if (l2_mem_req.strobe[b])
                            mem[(l2_mem_req.addr - 32'h1c000000) >> 2][b*8 +: 8] <=
                                l2_mem_req.data[b*8 +: 8];
                end
            end
        end
    end

    assign l2_mem_resp.addr_ok   = m_addr_ok;
    // data_ok covers both channels (the arbiter's dresp.data_ok = read or
    // write completion); rdata_ok stays read-only for the refill/keyword
    // gating.
    assign l2_mem_resp.data_ok   = m_data_ok || m_rdata_ok;
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
    logic        f_valid_d1;

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
                        // Present the request only while no response is
                        // being sampled this cycle.  The real LSU's dreq is
                        // combinational (valid_in && mem_re|mem_we), so the
                        // completed request is never re-presented — a
                        // registered re-presentation would be re-forwarded
                        // by the L1 and its response misattributed to the
                        // next request.
                        if (!cpu_resp.addr_ok && !cpu_resp.data_ok) begin
                            cpu_req.valid   <= 1'b1;
                            cpu_req.addr    <= req_addr;
                            cpu_req.strobe  <= req_strobe;
                            cpu_req.data    <= req_data;
                            cpu_req.cacheable <= req_cacheable;
                            cpu_req.size    <= MSIZE4;
                            cpu_req.burst_len <= 2'd0;
                        end
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
            if (req_pending && cyc > req_start_cyc + 500000) begin
                $display("[FAIL] test %0d: request %08x stuck (pending %0d cycles)",
                         test_id, req_addr, cyc - req_start_cyc);
                fail <= 1'b1;
                $finish;
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
        issue_store_w(a, d, 4'hf);
    endtask
    task automatic issue_store_w(input [31:0] a, input [31:0] d, input [3:0] s);
        req_pending = 1'b1; req_addr = a; req_data = d;
        req_strobe = s; req_cacheable = 1'b1;
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
    task automatic issue_load_uncached(input [31:0] a);
        req_pending = 1'b1; req_addr = a; req_data = 32'd0;
        req_strobe = 4'h0; req_cacheable = 1'b0;
        req_start_cyc = cyc;
        while (req_pending) @(posedge clk);
        while (!got_data_ok) @(posedge clk);
        @(posedge clk);
    endtask
    task automatic issue_cacop(input [4:0] code, input [31:0] a);
        // mirror core_top: the request stays valid (cacop in EX) until the
        // L2 completes its own cacop, which is gated on the L1's done
        // (a level held until the request drops).
        logic [31:0] wait_cyc;
        cacop_req.valid = 1'b1; cacop_req.code = code; cacop_req.addr = a;
        wait_cyc = 0;
        while (!l2_cacop_done) begin
            @(posedge clk);
            wait_cyc = wait_cyc + 1;
            if (wait_cyc > 500000) begin
                $display("[FAIL] test %0d: cacop 0x%05x at %08x stuck (%0d cycles)",
                         test_id, code, a, wait_cyc);
                fail <= 1'b1;
                $finish;
            end
        end
        cacop_req.valid = 1'b0;
        @(posedge clk);
    endtask

    // --- DEBUG TRACE (kept: L2 eviction bursts + cacop writebacks) ---
    always_ff @(posedge clk) begin
        if (!reset && test_id == 12) begin
            if (l2_mem_req.valid && |l2_mem_req.strobe && l2_mem_req.burst_len != 2'd0)
                $display("[cyc%0d] L2WBURST addr=%08x data=%08x", cyc, l2_mem_req.addr, l2_mem_req.data);
            if (l2_mem_req.valid && |l2_mem_req.strobe && l2_mem_req.addr[17:8] == 10'd0)
                $display("[cyc%0d] L2WRITE addr=%08x data=%08x cway=%0d cidx=%0d wbbuf=[%08x %08x %08x %08x] dout0=%08x st=%0d",
                         cyc, l2_mem_req.addr, l2_mem_req.data,
                         u_l2.cacop_way, u_l2.cacop_idx,
                         u_l2.cacop_wb_buf[0], u_l2.cacop_wb_buf[1], u_l2.cacop_wb_buf[2], u_l2.cacop_wb_buf[3],
                         u_l2.data_rd_out[0][0], u_l2.state);
        end
    end

    always_ff @(posedge clk) begin
        f_valid_d1 <= u_l1.f_valid;
        if (!reset && (test_id == 7 || test_id == 8)) begin
            if (u_l1.f_valid && !f_valid_d1)
                $display("[cyc%0d] FILL idx=%0d wo=%0d way=%0d tag=%06x data=%08x part=%0d store=%0d",
                         cyc, u_l1.f_idx, u_l1.f_wo, u_l1.f_way, u_l1.f_tag, u_l1.f_data, u_l1.f_partial, u_l1.f_store);
            if (hit_pending)
                $display("[cyc%0d] HITREXT way=%0d word=%0d -> %08x (req=%08x)",
                         cyc, hit_way_r, (hit_addr_r >> 2) & 3,
                         data_wb[hit_way_r][(hit_addr_r >> 2) & 3], hit_addr_r);
            if (u_l1.o_complete)
                $display("[cyc%0d] OCOMPLETE idx=%0d wo=%0d tag=%06x op=%0d strb=%04b cache=%0d respdata=%08x",
                         cyc, u_l1.o_idx, u_l1.o_wo, u_l1.o_tag, u_l1.o_op, u_l1.o_strobe, u_l1.o_cacheable, l1_mem_resp.data);
            if (cpu_req.valid)
                $display("[cyc%0d] PRESENT addr=%08x wo=%0d strobe=%04b",
                         cyc, cpu_req.addr, (cpu_req.addr >> 2) & 3, cpu_req.strobe);
            if (l1_mem_resp.addr_ok || l1_mem_resp.data_ok)
                $display("[cyc%0d] L2RESP addr_ok=%0d data_ok=%0d rdata_ok=%0d data=%08x",
                         cyc, l1_mem_resp.addr_ok, l1_mem_resp.data_ok, l1_mem_resp.rdata_ok, l1_mem_resp.data);
            if (u_l1.state inside {3'd2, 3'd3, 3'd4} || u_l2.state inside {4'd10, 4'd11, 4'd12})
                $display("[cyc%0d] CACOP l1st=%0d l2st=%0d l1done=%0d l2done=%0d cacop_v=%0d",
                         cyc, u_l1.state, u_l2.state, l1_cacop_done, l2_cacop_done, cacop_req.valid);
            if (l1_mem_req.valid)
                $display("[cyc%0d] L1REQ addr=%08x strb=%04b data=%08x", cyc, l1_mem_req.addr, l1_mem_req.strobe, l1_mem_req.data);
            if (l2_mem_req.valid)
                $display("[cyc%0d] L2REQ addr=%08x strb=%04b data=%08x burst=%0d", cyc, l2_mem_req.addr, l2_mem_req.strobe, l2_mem_req.data, l2_mem_req.burst_len);
            if (u_l2.state == 4'd8)
                $display("[cyc%0d] L2REFWRITE st=%0d wr_cnt=%0d m_wo=%0d m_op=%0d merge=%0d wr_addr=%0d wr_way=%0d",
                         cyc, u_l2.state, u_l2.rf_wr_cnt, u_l2.m_wo, u_l2.m_op, u_l2.st_merge_pending,
                         u_l2.data_wr_addr, u_l2.data_wr_way);
        end
    end

    initial begin
        for (int i = 0; i < 16777216; i++)
            mem[i] = 32'h0;

        repeat (4) @(posedge clk);
        reset = 0;
        // Wait for both levels' cold-start S_INIT walks.
        while (u_l1.state !== 3'd1 || u_l2.state !== 4'd1) @(posedge clk);
        @(posedge clk);

        // --- test 1: store stream + read-back (fills + 0-cycle hits) ---
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

        // --- test 2: cold load miss keyword (word 2) ---
        test_id = 2;
        mem[(32'h1c7f0100 - 32'h1c000000) >> 2] = 32'h11223344;
        mem[(32'h1c7f0104 - 32'h1c000000) >> 2] = 32'h55667788;
        mem[(32'h1c7f0108 - 32'h1c000000) >> 2] = 32'h99aabbcc;
        mem[(32'h1c7f010c - 32'h1c000000) >> 2] = 32'hddeeff00;
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
        issue_load(32'h1c7f0108);   // still a hit (word 2 filled in test 2)
        if (got_data == 32'h99aabbcc)
            $display("[PASS] test 3b: word-2 hit ok");
        else begin
            $display("[FAIL] test 3b: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 4: per-word sector fills ---
        test_id = 4;
        issue_load(32'h1c7f0100);   // word 0: L1 miss -> L2 hit -> fill
        if (got_data == 32'h11223344)
            $display("[PASS] test 4a: word-0 fill ok");
        else begin
            $display("[FAIL] test 4a: got %08x", got_data);
            fail <= 1'b1;
        end
        issue_load(32'h1c7f010c);   // word 3: independent fill
        if (got_data == 32'hddeeff00)
            $display("[PASS] test 4b: word-3 fill ok");
        else begin
            $display("[FAIL] test 4b: got %08x", got_data);
            fail <= 1'b1;
        end
        issue_load(32'h1c7f0100);   // word 0 hit again (0-cycle)
        issue_load(32'h1c7f010c);   // word 3 hit again
        if (got_data == 32'hddeeff00)
            $display("[PASS] test 4c: both words hit ok");
        else begin
            $display("[FAIL] test 4c: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 5: partial-byte store is not filled; read-back ok ---
        test_id = 5;
        mem[(32'h1c7f0200 - 32'h1c000000) >> 2] = 32'hdeadbeef;
        issue_store_w(32'h1c7f0200, 32'h0000005a, 4'b0001);
        issue_load(32'h1c7f0200);
        if (got_data == 32'hdeadbe5a)
            $display("[PASS] test 5: partial-byte store ok");
        else begin
            $display("[FAIL] test 5: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 6: dirty eviction (hammer one L1 set) ---
        test_id = 6;
        // All map to L1 set 0 (addr[11:4] == 0), distinct tags.
        for (int i = 0; i < 6; i++)
            issue_store(32'h1c000000 + i * 32'h1000, 32'hcafe0000 + i);
        for (int i = 0; i < 6; i++) begin
            issue_load(32'h1c000000 + i * 32'h1000);
            if (got_data !== (32'hcafe0000 + i)) begin
                $display("[FAIL] test 6: line %0d got %08x want %08x",
                         i, got_data, 32'hcafe0000 + i);
                fail <= 1'b1;
            end
        end
        if (!fail)
            $display("[PASS] test 6: dirty eviction read-back ok");

        // --- test 7: cacop 0x09 flush ordering L1->L2->mem ---
        test_id = 7;
        issue_store(32'h1c7f0200, 32'hdeadcafe);
        issue_cacop(5'b01001, 32'h1c7f0200);
        repeat (10) @(posedge clk);
        if (mem[(32'h1c7f0200 - 32'h1c000000) >> 2] == 32'hdeadcafe)
            $display("[PASS] test 7: cacop flush ordering L1->L2->mem ok");
        else begin
            $display("[FAIL] test 7: mem[0x200]=%08x", mem[(32'h1c7f0200 - 32'h1c000000) >> 2]);
            fail <= 1'b1;
        end

        // --- test 8: cacop 0x01 index invalidate (no writeback) ---
        // The store's data lives only in the caches (never reached
        // memory); 0x01 invalidates the line at both levels WITHOUT
        // writeback, so the read-back must come from memory = 0.  (A
        // nonzero result would mean the invalidate did not reach one of
        // the levels.)  The writeback flavor is covered by test 7/12.
        test_id = 8;
        issue_store(32'h1c7f0300, 32'h12345678);
        issue_cacop(5'b00001, 32'h1c7f0300);
        issue_load(32'h1c7f0300);   // L1+L2 line gone: read from memory
        if (got_data == 32'h0)
            $display("[PASS] test 8: 0x01 invalidate at both levels ok");
        else begin
            $display("[FAIL] test 8: got %08x (invalidate missed a level)", got_data);
            fail <= 1'b1;
        end

        // --- test 9: hit-under-miss (L1 serves hits while L2 refills) ---
        test_id = 9;
        issue_load(32'h1c7f0400);          // fill the L1 line (word 0)
        issue_load(32'h1c7f0404);          // word 1: miss -> L2 hit -> fill
        issue_store(32'h1c7f0500, 32'h55aa55aa); // cold store: L2 refill
        // L2 now refills the store's line; the L1 must still serve hits.
        issue_load(32'h1c7f0404);
        if (got_data == 32'h0)             // mem zeroed, word 1 was stored 0
            $display("[PASS] test 9: L1 hit while L2 refills ok");
        else begin
            $display("[FAIL] test 9: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 10: store-then-load same word (read-back correctness) ---
        test_id = 10;
        issue_store(32'h1c7f0600, 32'h11112222);
        issue_load(32'h1c7f0600);
        if (got_data == 32'h11112222)
            $display("[PASS] test 10: store read-back ok");
        else begin
            $display("[FAIL] test 10: got %08x", got_data);
            fail <= 1'b1;
        end
        issue_load(32'h1c7f0600);          // second read: L1 hit expected
        if (got_data == 32'h11112222)
            $display("[PASS] test 10b: store read-back hit ok");
        else begin
            $display("[FAIL] test 10b: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 11: uncacheable passthrough ---
        test_id = 11;
        mem[(32'h1f000000 - 32'h1c000000) >> 2] = 32'h55aa55aa;
        issue_load_uncached(32'h1f000000);
        if (got_data == 32'h55aa55aa)
            $display("[PASS] test 11: uncached passthrough ok");
        else begin
            $display("[FAIL] test 11: got %08x", got_data);
            fail <= 1'b1;
        end

        // --- test 13: store to the victim line during its eviction capture ---
        // Store A/B (same L1 set, 2 ways) then C, whose fill evicts the
        // PLRU victim (A); a store to A issued right after C completes
        // lands in the vc/dr window while A is still in the L1.  Without
        // the victim-store hold the store would be written into A's line,
        // which the pending fill is about to overwrite, while the drain
        // already captured the pre-store value — the store's data would
        // vanish from both levels.
        test_id = 13;
        issue_store(32'h1c7f1000, 32'h11110000);   // line A (L1 set 0)
        issue_store(32'h1c7f2000, 32'h22220000);   // line B (L1 set 0)
        issue_store(32'h1c7f3000, 32'h33330000);   // line C: evicts A
        issue_store(32'h1c7f1000, 32'h1111aaaa);   // store A in A's eviction window
        issue_load(32'h1c7f1000);
        if (got_data == 32'h1111aaaa)
            $display("[PASS] test 13: store during victim eviction ok");
        else begin
            $display("[FAIL] test 13: got %08x (store lost in eviction)", got_data);
            fail <= 1'b1;
        end

        // --- test 12: pseudorandom 2MB storm + flush + memory compare ---
        test_id = 12;
        begin
            logic [31:0] lcg;
            // Storm window 0x1c000000..0x1c1fffff = 2^19 words: the
            // reference array must cover all of it (131072 entries would
            // wrap indices 2^17..2^19-1 onto 0..2^17-1 and alias the
            // compare — bogus diffs exactly at the wrapped positions).
            logic [31:0] lastv [0:524287];
            logic [31:0] addr;
            // Flush any residue from tests 1-11 first so the final memory
            // compare only reflects this storm's stores.
            for (int set = 0; set < 16384; set++)
                for (int way = 0; way < 4; way++) begin
                    issue_cacop(5'b01001, 32'h1c000000 | (set << 4) | way);
                    @(posedge clk);
                end
            // Cache is now empty and its residue is in memory; reset the
            // reference to a clean slate before the storm.
            for (int i = 0; i < 524288; i++)
                mem[i] = 32'h0;
            lcg = 32'h12345678;
            for (int i = 0; i < 524288; i++)
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
                        $display("[FAIL] test 12: it=%0d addr=%08x got=%08x want=%08x",
                                 i, addr, got_data, lastv[(addr - 32'h1c000000) >> 2]);
                        fail <= 1'b1;
                    end
                end
            end
            // Full flush walk (L2 geometry) and compare against the
            // reference array (memory must equal the last store per word).
            force u_l2.data_rd_addr = 0;
            repeat (2) @(posedge clk);
            $display("[DEBUG] pre-flush L2 set0 w0=[%08x %08x %08x %08x] w1=[%08x %08x %08x %08x] mem0=%08x",
                     u_l2.data_rd_out[0][0], u_l2.data_rd_out[0][1], u_l2.data_rd_out[0][2], u_l2.data_rd_out[0][3],
                     u_l2.data_rd_out[1][0], u_l2.data_rd_out[1][1], u_l2.data_rd_out[1][2], u_l2.data_rd_out[1][3],
                     mem[0]);
            release u_l2.data_rd_addr;
            @(posedge clk);
            for (int set = 0; set < 16384; set++)
                for (int way = 0; way < 4; way++) begin
                    issue_cacop(5'b01001, 32'h1c000000 | (set << 4) | way);
                    @(posedge clk);
                end
            repeat (10) @(posedge clk);
            begin
                logic [31:0] diff_cnt;
                diff_cnt = 0;
                for (int i = 0; i < 524288; i++) begin
                    if (mem[i] !== lastv[i]) begin
                        if (diff_cnt < 8)
                            $display("[FAIL12] word %05x (%08x): mem=%08x want=%08x",
                                     i, 32'h1c000000 + i*4, mem[i], lastv[i]);
                        diff_cnt = diff_cnt + 1;
                    end
                end
                if (diff_cnt == 0)
                    $display("[PASS] test 12: storm + flush memory compare ok");
                else begin
                    $display("[FAIL] test 12: %0d words differ after flush", diff_cnt);
                    fail <= 1'b1;
                end
            end
        end

        repeat (10) @(posedge clk);
        if (!fail)
            $display("[ALL PASS]");
        else
            $display("[FAILED]");
        $finish;
    end

endmodule
