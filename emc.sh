disk=$1

echo "EMC     " > /sys/kernel/scst_tgt/devices/${disk}/vend_specific_id
echo "EMC     " > /sys/kernel/scst_tgt/devices/${disk}/t10_vend_id
echo "SYMMETRIX       " > /sys/kernel/scst_tgt/devices/${disk}/prod_id
echo "5876" > /sys/kernel/scst_tgt/devices/${disk}/prod_rev_lvl
echo "36" > /sys/kernel/scst_tgt/devices/${disk}/lun_sno_off



