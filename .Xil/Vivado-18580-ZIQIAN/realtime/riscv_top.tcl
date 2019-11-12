# 
# Synthesis run script generated by Vivado
# 

namespace eval rt {
    variable rc
}
set rt::rc [catch {
  uplevel #0 {
    set ::env(BUILTIN_SYNTH) true
    source $::env(HRT_TCL_PATH)/rtSynthPrep.tcl
    rt::HARTNDb_resetJobStats
    rt::HARTNDb_resetSystemStats
    rt::HARTNDb_startSystemStats
    rt::HARTNDb_startJobStats
    set rt::cmdEcho 0
    rt::set_parameter writeXmsg true
    rt::set_parameter enableParallelHelperSpawn true
    set ::env(RT_TMP) "D:/CPU/.Xil/Vivado-18580-ZIQIAN/realtime/tmp"
    if { [ info exists ::env(RT_TMP) ] } {
      file delete -force $::env(RT_TMP)
      file mkdir $::env(RT_TMP)
    }

    rt::delete_design

    set rt::partid xc7a35tcpg236-1

    set rt::multiChipSynthesisFlow false
    source $::env(SYNTH_COMMON)/common.tcl
    set rt::defaultWorkLibName xil_defaultlib

    set rt::useElabCache false
    if {$rt::useElabCache == false} {
      rt::read_verilog {
      D:/CPU/CPU.srcs/sources_1/new/defines.v
      D:/CPU/CPU.srcs/sources_1/imports/src/common/block_ram/block_ram.v
      D:/CPU/CPU.srcs/sources_1/imports/src/cpu.v
      D:/CPU/CPU.srcs/sources_1/new/ex.v
      D:/CPU/CPU.srcs/sources_1/new/ex_mem.v
      D:/CPU/CPU.srcs/sources_1/imports/src/common/fifo/fifo.v
      D:/CPU/CPU.srcs/sources_1/imports/src/hci.v
      D:/CPU/CPU.srcs/sources_1/new/id.v
      D:/CPU/CPU.srcs/sources_1/new/id_ex.v
      D:/CPU/CPU.srcs/sources_1/new/if_id.v
      D:/CPU/CPU.srcs/sources_1/new/mem.v
      D:/CPU/CPU.srcs/sources_1/new/mem_wb.v
      D:/CPU/CPU.srcs/sources_1/new/pc_reg.v
      D:/CPU/CPU.srcs/sources_1/imports/src/ram.v
      D:/CPU/CPU.srcs/sources_1/new/regfile.v
      D:/CPU/CPU.srcs/sources_1/imports/src/common/uart/uart.v
      D:/CPU/CPU.srcs/sources_1/imports/src/common/uart/uart_baud_clk.v
      D:/CPU/CPU.srcs/sources_1/imports/src/common/uart/uart_rx.v
      D:/CPU/CPU.srcs/sources_1/imports/src/common/uart/uart_tx.v
      D:/CPU/CPU.srcs/sources_1/imports/src/riscv_top.v
    }
      rt::filesetChecksum
    }
    rt::set_parameter usePostFindUniquification false
    set rt::top riscv_top
    rt::set_parameter enableIncremental true
    set rt::reportTiming false
    rt::set_parameter elaborateOnly true
    rt::set_parameter elaborateRtl true
    rt::set_parameter eliminateRedundantBitOperator false
    rt::set_parameter elaborateRtlOnlyFlow true
    rt::set_parameter writeBlackboxInterface true
    rt::set_parameter merge_flipflops true
    rt::set_parameter srlDepthThreshold 3
    rt::set_parameter rstSrlDepthThreshold 4
# MODE: 
    rt::set_parameter webTalkPath {}
    rt::set_parameter enableSplitFlowPath "D:/CPU/.Xil/Vivado-18580-ZIQIAN/"
    set ok_to_delete_rt_tmp true 
    if { [rt::get_parameter parallelDebug] } { 
       set ok_to_delete_rt_tmp false 
    } 
    if {$rt::useElabCache == false} {
        set oldMIITMVal [rt::get_parameter maxInputIncreaseToMerge]; rt::set_parameter maxInputIncreaseToMerge 1000
        set oldCDPCRL [rt::get_parameter createDfgPartConstrRecurLimit]; rt::set_parameter createDfgPartConstrRecurLimit 1
        $rt::db readXRFFile
      rt::run_rtlelab -module $rt::top
        rt::set_parameter maxInputIncreaseToMerge $oldMIITMVal
        rt::set_parameter createDfgPartConstrRecurLimit $oldCDPCRL
    }

    set rt::flowresult [ source $::env(SYNTH_COMMON)/flow.tcl ]
    rt::HARTNDb_stopJobStats
    if { $rt::flowresult == 1 } { return -code error }


  set hsKey [rt::get_parameter helper_shm_key] 
  if { $hsKey != "" && [info exists ::env(BUILTIN_SYNTH)] && [rt::get_parameter enableParallelHelperSpawn] } { 
     $rt::db killSynthHelper $hsKey
  } 
  rt::set_parameter helper_shm_key "" 
    if { [ info exists ::env(RT_TMP) ] } {
      if { [info exists ok_to_delete_rt_tmp] && $ok_to_delete_rt_tmp } { 
        file delete -force $::env(RT_TMP)
      }
    }

    source $::env(HRT_TCL_PATH)/rtSynthCleanup.tcl
  } ; #end uplevel
} rt::result]

if { $rt::rc } {
  $rt::db resetHdlParse
  set hsKey [rt::get_parameter helper_shm_key] 
  if { $hsKey != "" && [info exists ::env(BUILTIN_SYNTH)] && [rt::get_parameter enableParallelHelperSpawn] } { 
     $rt::db killSynthHelper $hsKey
  } 
  source $::env(HRT_TCL_PATH)/rtSynthCleanup.tcl
  return -code "error" $rt::result
}