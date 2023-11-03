#!/bin/bash
if [[ $1 = "-help" || $1 = "-h" ]];then
    echo "please add para dev, such as: ./opt_raid.sh sda, also need modify controller number"
fi
#参数数量
num_arg=$#
#所有传入的参数，和$*一样
arg=($@)
#输入传入参数，验证正确与否
#echo "Check args."
#for ((i=1;i<=$num_arg;i++))
#do
#	echo "$i, ${arg[$i-1]}"

#done
#判断是SSD还是HDD

for ((i=1;i<=$num_arg;i++))
do
	disk_media=`cat /sys/block/${arg[$i-1]}/queue/rotational`
	if [ $disk_media = 0 ];then
        	#SSD优化分支
		echo "${arg[$i-1]},SSD,Start Storage performance tuning!"
		#SSD不需要调度
		echo none > /sys/block/${arg[$i-1]}/queue/scheduler
		#关闭merge
		echo 2 > /sys/block/${arg[$i-1]}/queue/nomerges
		#disable熵池
		echo 0 > /sys/block/${arg[$i-1]}/queue/add_random
		#哪个CPU提交的IO，哪个CPU去处理
		echo 2 > /sys/block/${arg[$i-1]}/queue/rq_affinity
		#disable irqbalance, and do a ont-time set of the interrupt vectors
		service irqbalance stop
		irqbalance --oneshot
		#system性能tuning
		tuned-adm profile throughput-performance
		#开始测试前，必须进行初始化

		storcli64 /c0/vall start init full
		#raid卡配置
			#妈的，sas4xxx不支持cached IO，sas3xxx支持cached IO，但是我实际组建，两者都不支持cached IO
		storcli64 /c0/vall 

		#numa   numastat
		#对于AMD，能配置NUMA nodes per socket（NPS），NPS4能获得最好的结果
		#（妈的 矛盾啊）NPS1是用于找最大带宽，NPS4适用于找高并发的工作负载
		


	else
		#HDD优化分支
	        echo "${arg[$i-1]},HDD,Start Storage performance tuning!"
fi
done

#PCIe tuning and other
#1.use BIOS enable or disable RO, broadcom requires PCIe RO for best performance
#2.maximum payload size(broadcom support 1K)  and maximum read request size (4K)   设置较为复杂，待补充
#3.BIOS (power management para)-> advanced mode  -> CPU configuration  ->   power management control 找到C-state   禁用即可
	#3.1 intel:    power technology   disabled
	#3.2 intel:    turbo mode   		enabled
	#3.3 intel：   speedstep    		enabled
	#3.4 intel：   hardware p-state 	disabled
	#3.5 intel：   C-state  		disabled
	#3.6 intel：   T-state   		disabled

	#3.7 AMD: global C-state         	disabled
	#3.8 AMD: core performance boost        enabled

	#3.9  AMD Infinity Fabric power:    determinism control      manual
	#3.10 AMD Infinity Fabric power:    determinism slider       performance
	#3.11 AMD Infinity Fabric power:    APBDIS                   1
	#3.12 AMD Infinity Fabric power:    Fixed SOC P-state        p0(high performance)
#4.BIOS   hyper-threading
#5.BIOS   cache prefetchers
#6.BIOS   IOMMU

#7.numa
	#—interleave=nodes 
	#—membind=nodes
	#—cpunodebind=nodes
	#—physcpubind=cpus
	#—localalloc
	#—preferred=node









