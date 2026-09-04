showconsole()
clearconsole()
mydir="./"
open(mydir .. "bldc12.fem")
mi_saveas(mydir .. "temp.fem")
mi_seteditmode("group")
mi_probdef(0, "millimeters", "planar", 1e-8, 50, 20, 0)
-- ============================================================
-- STEP 1: Assign all rotor geometry + labels to group 1
-- (rotor core, shaft, magnets) -- everything inside radius ~29
-- Adjust 29 if it grabs stator teeth or misses the magnets!
-- ============================================================
mi_clearselected()
mi_selectcircle(0,0,26.61,4)   -- 4 = select nodes+segments+arcs+labels
mi_setgroup(1)
mi_clearselected()
-- ============================================================
-- STEP 2: Open CSV file for output
-- ============================================================
csv = openfile(mydir .. "foc_results.csv", "w")
write(csv, "rotor_angle,electrical_angle,I_d,I_q,i_alpha,i_beta,i_a,i_b,i_c,torque\n")
-- ============================================================
-- STEP 3: FOC sweep
-- 20-pole motor -> 1 mechanical degree = 10 electrical degrees
-- ============================================================
step=90
rotation=0.2  -- mechanical degrees per step (=> 2 electrical degrees per step)
-- rotate rotor to "true neutral": half pole pitch on stator vs rotor
mi_selectgroup(1)
mi_moverotate(0,0, (360/20/2 - 360/18/2) + 4.95, 4)
mi_clearselected()
for n=0,step do
    rotor_angle = n*rotation
    rotor_axis_electrical_angle = rotor_angle*10  -- 10 pole pairs
    I_d = 0
    I_q = 5
    rr = (rotor_axis_electrical_angle-90)*3.141592654/180
    i_alpha = I_d * cos(rr) - I_q*sin(rr)
    i_beta  = I_d * sin(rr) + I_q*cos(rr)
    i_a = i_alpha
    i_b = -0.5*i_alpha + 0.8660*i_beta
    i_c = -0.5*i_alpha - 0.8660*i_beta
    -- NOTE: coil_V and coil_W swapped here to match the motor's actual
    -- U -> W -> V physical phase sequence (confirmed via no-load back-EMF sweep)
    mi_modifycircprop("coil_U",1,i_a)
    mi_modifycircprop("coil_V",1,i_c)
    mi_modifycircprop("coil_W",1,i_b)
    mi_analyze(1)
    mi_loadsolution()
    mo_groupselectblock(1)
    torque=mo_blockintegral(22)
    print(rotor_angle, rotor_axis_electrical_angle, I_d, I_q, i_alpha, i_beta, i_a, i_b, i_c, torque)
    -- write row to CSV
    write(csv, rotor_angle .. "," .. rotor_axis_electrical_angle .. "," .. I_d .. "," .. I_q .. "," .. i_alpha .. "," .. i_beta .. "," .. i_a .. "," .. i_b .. "," .. i_c .. "," .. torque .. "\n")
    mo_clearblock()
    mi_selectgroup(1)
    mi_moverotate(0,0,rotation,4)
    mi_clearselected()
end
closefile(csv)
mo_close()
mi_close()