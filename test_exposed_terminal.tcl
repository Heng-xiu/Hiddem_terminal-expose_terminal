#channel type
#radio-propagation model
#network interface
#MAC type
#interface queue type
#link layer type
#antenna model
#max packet in interface queue
#Routing protocal
set val(chan)           Channel/WirelessChannel   
set val(prop)           Propagation/TwoRayGround   
set val(netif)           Phy/WirelessPhy            
set val(mac)           Mac/802_11                
set val(ifq)            Queue/DropTail/PriQueue    
set val(ll)             LL                         
set val(ant)            Antenna/OmniAntenna       
set val(ifqlen)          100                        
set val(rp) 		     DSDV

#開啟ns模擬器
set ns [new Simulator]

#是否選用RTS/CTS 3000為沒 0為有
#Mac/802_11 set RTSThreshold_    0
Mac/802_11 set RTSThreshold_    3000

#設置天線參數
#x=0, y=0, z=1.5, 天線接收增益=天線傳送增益=1.0
Antenna/OmniAntenna set X_ 0
Antenna/OmniAntenna set Y_ 0
Antenna/OmniAntenna set Z_ 1.5 
Antenna/OmniAntenna set Gt_ 1.0
Antenna/OmniAntenna set Gr_ 1.0

#按照門檻值所做的設定
#CP門檻值 = 10.0
#訊號偵測門檻值 = 6.88081e-9 
#接收門檻值 = 1.42681e-9
#頻寬 = 2e6
#傳送功率 = 0.281838
#傳送頻率 = 9.14e+6
#系統遺失 = 1.0
Phy/WirelessPhy set CPThresh_ 10.0       
Phy/WirelessPhy set CSThresh_ 6.88081e-9 
Phy/WirelessPhy set RXThresh_ 1.42681e-9
Phy/WirelessPhy set bandwidth_ 2e6
Phy/WirelessPhy set Pt_ 0.281838
Phy/WirelessPhy set freq_ 9.14e+6
Phy/WirelessPhy set L_ 1.0 

#設定記錄檔，把模擬過程記錄下來 名稱為f
#記錄所有過程到 $f
#Record event in trace file
#產生個nam 的檔案來記錄模擬過程 名稱為nf
#記錄所有無線網路的過程到 nf 檔案去 範圍是500x500
set f [open test.tr w]
$ns trace-all $f
$ns eventtrace-all
set nf [open test.nam w]
$ns namtrace-all-wireless $nf 500 500

#Set up topography object
#topography range 500m x 500x
#create General Operations Director
#create channel 
set topo       [new Topography]
$topo load_flatgrid 500 500
create-god 4
set chan [new $val(chan)]

#設定節點參數(這邊對應最上面的參數設定)
$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \ 
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -channel $chan \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace OFF \
                -macTrace ON \
                -movementTrace OFF 

#create node 
#disable random-motion 可以創立節點不亂跑
for {set i 0} {$i < 4} {incr i} {
        set node_($i) [$ns node]
        $node_($i) random-motion 0
}

#設置節點位置
#node(0) (30.0, 30.0, 0.0)
#node(1) (130.0, 30.0, 0.0)
#node(2) (230.0, 30.0, 0.0)
#node(3) (330.0, 30.0, 0.0)
#同時可了解節點間的距離
$node_(0) set X_ 30.0
$node_(0) set Y_ 30.0
$node_(0) set Z_ 0.0
$node_(1) set X_ 130.0
$node_(1) set Y_ 30.0
$node_(1) set Z_ 0.0
$node_(2) set X_ 230.0
$node_(2) set Y_ 30.0
$node_(2) set Z_ 0.0
$node_(3) set X_ 330.0
$node_(3) set Y_ 30.0
$node_(3) set Z_ 0.0

#設立名為udp 的 mUDP 的連線 (mUDP是柯老師自己寫的當案)
#設置紀錄檔案名稱 sd1
#node(1) 使用的通訊協定 udp
set udp [new Agent/mUDP]
$udp set_filename sd1
$ns attach-agent $node_(1) $udp
#設立NULL的資料連結
#設置檔案名稱 rd1
#node(0) 通訊協定 NULL
#連接
set null [new Agent/mUdpSink]
$null set_filename rd1
$ns attach-agent $node_(0) $null
$ns connect $udp $null
#設立建立在 udp上跑的CBR (CBR 為一種Packet Types)
#使用的通訊協定 udp
#形式 CBR
#封包大小 1000
#速率 1Mb
#隨機 關閉
#設置cbr 開始與結束的時間
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1Mb
$cbr set random_ false
$ns at 1.5 "$cbr start"
$ns at 15.0 "$cbr stop"

#設立名稱為udp2 的 mUDP連線 (mUDP是柯老師自己寫的當案)
#設置紀錄檔案名稱 sd2
#node(2) 接觸的通訊協定 udp2
set udp2 [new Agent/mUDP]
$udp2 set_filename sd2
$ns attach-agent $node_(2) $udp2
#設立名稱為null2 的資料連結
#設置檔案名稱 rd2
#node(3) 使用的通訊協定 NULL2
#連接
set null2 [new Agent/mUdpSink]
$null2 set_filename rd2
$ns attach-agent $node_(3) $null2
$ns connect $udp2 $null2
#設立建立在 udp上跑的CBR2 (CBR 為一種Packet Types)
#接觸的通訊協定 udp2
#形式 CBR
#封包大小 1000
#速率 1Mb
#隨機 關閉
#設置cbr 開始與結束的時間
set cbr2 [new Application/Traffic/CBR]
$cbr2 attach-agent $udp2
$cbr2 set type_ CBR
$cbr2 set packet_size_ 1000
$cbr2 set rate_ 1Mb
$cbr2 set random_ false
$ns at 2.0 "$cbr2 start"
$ns at 15.0 "$cbr2 stop"

# Tell nodes when the simulation ends
for {set i 0} {$i < 3} {incr i} {
        $ns initial_node_pos $node_($i) 30
        $ns at 20.0 "$node_($i) reset";
}

#在20.0s 呼叫finish 來結束模擬
#在20.1s 呼叫 $ns halt 來關閉ns 並顯示NS EXITING...
$ns at 20.0 "finish"
$ns at 20.1 "puts \"NS EXITING...\"; $ns halt"

#設立一個finish 程序
#使用全域變數 ns f nf val 不然無法使用
#flush buffers for all trace objects in simulation
#關閉 f nf 
proc finish {} {
        global ns f nf val
        $ns flush-trace
        close $f
        close $nf
}

#開始執行模擬
$ns run
