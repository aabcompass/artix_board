open_run impl_35
cd [get_property DIRECTORY [current_project]]/[current_project].runs/impl_35
#write_cfgmem -format bin -interface serialx1 -size 32 -loadbit  "up 0 [get_property top [current_fileset]].bit"  -file single_bin -force
#write_cfgmem -format bin -interface serialx1 -size 32 -loadbit  "up 0 [get_property top [current_fileset]].bit [get_property top [current_fileset]].bit [get_property top [current_fileset]].bit"  -file artix -force
write_cfgmem -format bin -interface SPIx1 -size 32 -loadbit  "up 0 [get_property top [current_fileset]].bit [get_property top [current_fileset]].bit [get_property top [current_fileset]].bit"  -file artix -force
#write_cfgmem -format bin -interface serialx1 -size 32 -loadbit  "up 0 [get_property top [current_fileset]].bit [get_property top [current_fileset]].bit"  -file double_bin -force
