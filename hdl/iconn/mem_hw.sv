// Memory module with port width of a full cache line, is it ok?
import param_pkg::*;

module mem_hw (
    input clk,
    input rcyc,
    input wcyc,
    input [MAIN_MEM_AW-1:0] waddr,
    input [MAIN_MEM_AW-1:0] raddr,
    input [MAIN_MEM_DW-1:0] wdata,
    output logic [MAIN_MEM_DW-1:0] rdata
);

  // The DPRAM_AW parameter is hardcoded to 32 in order to allow synth as a BRAM
  dp_ram_clk #(
      .DPRAM_AW(MAIN_MEM_AW),
      .DPRAM_DW(MAIN_MEM_DW)
  ) main_memory (
      .clk(clk),

      // Always read on port A
      .cyc_a_i(rcyc),
      .we_a_i (1'b0),
      .adr_a_i(raddr),
      .dat_a_i('0),

      // Always write on port B
      .cyc_b_i(wcyc),
      .we_b_i (1'b1),
      .adr_b_i(waddr),
      .dat_b_i(wdata),

      .dat_a_o(rdata),
      .dat_b_o()
  );

  // initial begin
  //     int fd;
  //     string file_path;
  //     string line;
  //     $display("This is 2 core version!");
  //     $write("Grabbing memory file path...");
  //     fd = $fopen("/home/aguarisco/gem5-test-2/src/rtl/model_hierarchy/iconn/mem_file_path.txt", "r");
  //     if (!fd) begin
  //         $display("Error");
  //         $display("Couldn't open /home/aguarisco/gem5-test-2/src/rtl/model_hierarchy/iconn/mem_file_path.txt, continuing with no mem file");
  //     end else begin
  //         $fgets(file_path, fd);
  //         $fclose(fd);
  //         // Detect and remove trailing newline
  //         if (file_path.getc(file_path.len()-1) == "\n") begin
  //             file_path = file_path.substr(0, file_path.len()-2);
  //         end

  //         // Test if file exists
  //         fd = $fopen(file_path, "r");
  //         if (!fd) begin
  //             $display("Error");
  //             $display("File path %s is invalid, continuing with no mem file", file_path);
  //         end else begin
  //             $fclose(fd);
  //             $display("Done");
  //             $write("Reading memory from file: %s...", file_path);
  //             $fflush();
  //             $readmemh(file_path, main_memory.mem);
  //             $display("Done");
  //         end
  //     end
  // end

`ifndef SYNTHESIS
  initial begin
`ifdef MEM_INIT_FILE
    $display("Loading memory from file: %s", `MEM_INIT_FILE);
    $readmemh(`MEM_INIT_FILE, main_memory.mem);
`else
    $display(
        "No memory init file provided, using /home/dcollovigh/git/axi4_cache_coherent_iconn/mem_dump/mem_zero.hex");
    $readmemh("/home/dcollovigh/git/axi4_cache_coherent_iconn/mem_dump/mem_zero.hex",
              main_memory.mem);
`endif
  end
`endif

endmodule
