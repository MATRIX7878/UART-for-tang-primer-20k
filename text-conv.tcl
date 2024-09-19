if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -work work [pwd]/*.vhd

vsim toplevel

add wave -recursive *

force clk 0, 1 13.5 -r 27
force RST 1 0, 0 50
force RX 0 100, 0 6418, 1 12736, 1 19154, 0 25572, 1 31990, 1 38408, 1 44826, 0 51244, 1 57662

view structure
view signals

run 2 ms

view -undock wave
wave zoomfull
