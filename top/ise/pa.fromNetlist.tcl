
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name top -dir "C:/Users/ash/Documents/18545/gbc/top/ise/planAhead_run_1" -part xc5vlx110tff1136-1
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/ash/Documents/18545/gbc/top/ise/gameboycolor_cs.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/ash/Documents/18545/gbc/top/ise} {../../gpu/GPU_IP/ipcore_dir} {../../memory/bram} }
add_files [list {../../gpu/GPU_IP/ipcore_dir/framebuffer1.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../../gpu/GPU_IP/ipcore_dir/OAM.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../../gpu/GPU_IP/ipcore_dir/VRAM.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../../gpu/GPU_IP/ipcore_dir/VRAM2.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../../memory/bram/bram_cart.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "C:/Users/ash/Documents/18545/gbc/top/gbc_top.ucf" [current_fileset -constrset]
add_files [list {C:/Users/ash/Documents/18545/gbc/top/gbc_top.ucf}] -fileset [get_property constrset [current_run]]
link_design
