if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -work work [pwd]/*.vhd

vsim toplevel

add wave -recursive *

force clk 0, 1 13.5 -r 27
force RST 0 0
force RX 0 100, 0 334, 1 568, 1 802, 0 1036, 1 1270, 1 1504, 1 1738, 0 1972, 1 2206

view structure
view signals

run 500 us

view -undock wave
wave zoomfull