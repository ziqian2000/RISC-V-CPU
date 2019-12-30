# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
create_project -in_memory -part xc7a35tcpg236-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir D:/CPU/CPU_project/CPU.cache/wt [current_project]
set_property parent.project_path D:/CPU/CPU_project/CPU.xpr [current_project]
set_property XPM_LIBRARIES XPM_CDC [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property ip_output_repo d:/CPU/CPU_project/CPU.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_verilog -library xil_defaultlib {
  D:/CPU/CPU_code/defines.v
  D:/CPU/CPU_code/block_ram.v
  D:/CPU/CPU_code/cpu.v
  D:/CPU/CPU_code/ctrl.v
  D:/CPU/CPU_code/ex.v
  D:/CPU/CPU_code/ex_mem.v
  D:/CPU/CPU_code/common/fifo.v
  D:/CPU/CPU_code/common/hci.v
  D:/CPU/CPU_code/id.v
  D:/CPU/CPU_code/id_ex.v
  D:/CPU/CPU_code/if.v
  D:/CPU/CPU_code/if_id.v
  D:/CPU/CPU_code/mem.v
  D:/CPU/CPU_code/mem_ctrl.v
  D:/CPU/CPU_code/mem_wb.v
  D:/CPU/CPU_code/common/ram.v
  D:/CPU/CPU_code/regfile.v
  D:/CPU/CPU_code/common/uart.v
  D:/CPU/CPU_code/common/uart_baud_clk.v
  D:/CPU/CPU_code/common/uart_rx.v
  D:/CPU/CPU_code/common/uart_tx.v
  D:/CPU/CPU_code/riscv_top.v
  D:/CPU/CPU_code/inst_cache.v
  D:/CPU/CPU_code/BTB.v
  D:/CPU/CPU_code/predictor.v
  D:/CPU/CPU_code/data_cache.v
}
read_ip -quiet D:/CPU/CPU_project/CPU.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci
set_property used_in_implementation false [get_files -all d:/CPU/CPU_project/CPU.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_board.xdc]
set_property used_in_implementation false [get_files -all d:/CPU/CPU_project/CPU.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc]
set_property used_in_implementation false [get_files -all d:/CPU/CPU_project/CPU.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_ooc.xdc]

# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc D:/Arch2019_Assignment/riscv/src/Basys-3-Master.xdc
set_property used_in_implementation false [get_files D:/Arch2019_Assignment/riscv/src/Basys-3-Master.xdc]

read_xdc dont_touch.xdc
set_property used_in_implementation false [get_files dont_touch.xdc]
set_param ips.enableIPCacheLiteLoad 0
close [open __synthesis_is_running__ w]

synth_design -top riscv_top -part xc7a35tcpg236-1


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef riscv_top.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file riscv_top_utilization_synth.rpt -pb riscv_top_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
