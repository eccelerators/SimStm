onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tbtop/i_tb_simstm/executing_line
add wave -noupdate -expand /tbtop/i_tb_simstm/executing_file
add wave -noupdate /tbtop/i_tb_simstm/verify_passes
add wave -noupdate /tbtop/i_tb_simstm/verify_failures
add wave -noupdate /tbtop/i_tb_simstm/bus_timeout_passes
add wave -noupdate /tbtop/i_tb_simstm/bus_timeout_failures
add wave -noupdate /tbtop/i_tb_simstm/marker
add wave -noupdate /tbtop/i_tb_simstm/signals_out
add wave -noupdate /tbtop/i_tb_simstm/signals_in
add wave -noupdate /tbtop/i_tb_simstm/bus_down
add wave -noupdate /tbtop/i_tb_simstm/bus_up
add wave -noupdate /tbtop/Clk
add wave -noupdate /tbtop/Rst
add wave -noupdate /tbtop/executing_line
add wave -noupdate /tbtop/executing_file
add wave -noupdate /tbtop/marker
add wave -noupdate /tbtop/verify_passes
add wave -noupdate /tbtop/verify_failures
add wave -noupdate /tbtop/bus_timeout_passes
add wave -noupdate /tbtop/bus_timeout_failures
add wave -noupdate /tbtop/signals_in
add wave -noupdate /tbtop/signals_out
add wave -noupdate /tbtop/bus_down
add wave -noupdate /tbtop/bus_up
add wave -noupdate /tbtop/InitDut
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1002599 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 455
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1001598 ps} {1003562 ps}
